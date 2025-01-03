local S = minetest.get_translator("mcl_more_chests")
local F = minetest.formspec_escape
local C = minetest.colorize

local string = string
local table = table
local math = math
local sf = string.format

--[[ Groups documenation:
	groups = {}
	
	handy=1
	Указывает, что данный объект (например, сундук) может быть разрушен (или собран) с помощью руки.
	Чем больше значение, тем быстрее объект ломается рукой.

	axey=1
	Указывает, что объект быстрее разрушается инструментом типа "топор".
	Значение определяет уровень эффективности инструмента: чем выше, тем быстрее разрушение.

	container=2
	Указывает, что данный объект является контейнером (например, сундуком).
	Значение может определять уровень "ёмкости" объекта (иногда не используется явно).

	deco_block=1
	Определяет, что объект в основном используется как декоративный блок. Например, он не имеет функционального назначения, кроме украшения.
	Значение может влиять на то, как объект отображается в интерфейсе или используется в рецептах.

	material_wood=1
	Указывает, что объект изготовлен из дерева.
	Может использоваться в рецептах крафта или для взаимодействия с объектами, связанными с деревом (например, для горения).

	material_stone=1
	Указывает, что объект сделан из материала "камень".
	Это важно для взаимодействий в игре, например:
	Для рецептов крафта, где нужны каменные материалы.
	Для разрушения блоков с инструментами, подходящими для камня.
	Для модов, которые обрабатывают каменные объекты (например, мобы, разрушение, транспортировка и т.д.).

	flammable=-1
	Указывает, что объект является негорючим (так как значение отрицательное).
	В случае положительного значения объект может гореть (например, flammable=3 указывает уровень легковоспламеняемости).

	chest_entity=1
	Специфическая группа, которая указывает, что данный объект является сундуком (или содержит сундуковую сущность).
	Может использоваться другими модами или функциями для определения сундуков.

	not_in_creative_inventory=1
	Указывает, что объект не отображается в креативном инвентаре.
	Используется для скрытия объектов, которые не должны быть доступны напрямую игрокам в креативном режиме (например, технические блоки).

	pickaxey=1
	Указывает, что данный блок или объект может быть разрушен инструментом типа "кирка" (pickaxe).
	Значение определяет эффективность разрушения: чем выше число, тем быстрее блок ломается киркой. Если значение отсутствует, кирка не ускоряет процесс разрушения.
]]

-- List of open chests.
-- Key: Player name
-- Value:
--		If player is using a chest: { pos = <chest node position> }
--		Otherwise: nil 
open_more_chests = {}
local animate_chests = (minetest.settings:get_bool("animated_chests") ~= false)

local function get_entity_pos(pos, dir, double)
	pos = vector.copy(pos)
	if double then
		local add, mul, vec, cross = vector.add, vector.multiply, vector.new, vector.cross
		pos = add(pos, mul(cross(dir, vec(0, 1, 0)), -0.5))
	end
	return pos
end

local function get_entity_info(pos, param2, double, dir, entity_pos)
	dir = dir or minetest.facedir_to_dir(param2)
	return dir, get_entity_pos(pos, dir, double)
end

local function create_entity(pos, node_name, entity_name, textures, param2, double, sound_prefix, mesh_prefix, animation_type, dir, entity_pos)
	dir, entity_pos = get_entity_info(pos, param2, double, dir, entity_pos)
	local obj = minetest.add_entity(entity_pos, entity_name)
	local luaentity = obj:get_luaentity()
	luaentity:initialize(pos, node_name, textures, dir, double, sound_prefix, mesh_prefix, animation_type)
	return luaentity
end

local function find_entity(pos, entity_name)
	for _, obj in pairs(minetest.get_objects_inside_radius(pos, 0)) do
		local luaentity = obj:get_luaentity()
		if luaentity and luaentity.name == entity_name then
			return luaentity
		end
	end
end

local function find_or_create_entity(pos, node_name, entity_name, textures, param2, double, sound_prefix, mesh_prefix, animation_type, dir, entity_pos)
	dir, entity_pos = get_entity_info(pos, param2, double, dir, entity_pos)
	return find_entity(entity_pos, entity_name) or create_entity(pos, node_name, entity_name, textures, param2, double, sound_prefix, mesh_prefix, animation_type, dir, entity_pos)
end

-- Simple protection checking functions
local function protection_check_move(pos, from_list, from_index, to_list, to_index, count, player)
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return 0
	else
		return count
	end
end

local function protection_check_put_take(pos, listname, index, stack, player)
	local name = player:get_player_name()
	if minetest.is_protected(pos, name) then
		minetest.record_protection_violation(pos, name)
		return 0
	else
		return stack:get_count()
	end
end

-- To be called when a chest is closed (only relevant for trapped chest atm)
local function chest_update_after_close(pos, entity_name)
	local node = minetest.get_node(pos)
	--[[
	if node.name == "mcl_chests:trapped_chest_on_small" then
		minetest.swap_node(pos, { name = "mcl_chests:trapped_chest_small", param2 = node.param2 })
		find_or_create_entity(pos, "mcl_chests:trapped_chest_small", entity_name, { "mcl_chests_trapped.png" }, node.param2, false, "default_chest", "mcl_chests_chest", "chest"):reinitialize("mcl_chests:trapped_chest_small")
		mesecon.receptor_off(pos, trapped_chest_mesecons_rules)
	elseif node.name == "mcl_chests:trapped_chest_on_left" then
		minetest.swap_node(pos, { name = "mcl_chests:trapped_chest_left", param2 = node.param2 })
		find_or_create_entity(pos, "mcl_chests:trapped_chest_left", entity_name, tiles_chest_trapped_double, node.param2, true, "default_chest", "mcl_chests_chest", "chest"):reinitialize("mcl_chests:trapped_chest_left")
		mesecon.receptor_off(pos, trapped_chest_mesecons_rules)

		local pos_other = mcl_util.get_double_container_neighbor_pos(pos, node.param2, "left")
		minetest.swap_node(pos_other, { name = "mcl_chests:trapped_chest_right", param2 = node.param2 })
		mesecon.receptor_off(pos_other, trapped_chest_mesecons_rules)
	elseif node.name == "mcl_chests:trapped_chest_on_right" then
		minetest.swap_node(pos, { name = "mcl_chests:trapped_chest_right", param2 = node.param2 })
		mesecon.receptor_off(pos, trapped_chest_mesecons_rules)

		local pos_other = mcl_util.get_double_container_neighbor_pos(pos, node.param2, "right")
		minetest.swap_node(pos_other, { name = "mcl_chests:trapped_chest_left", param2 = node.param2 })
		find_or_create_entity(pos_other, "mcl_chests:trapped_chest_left", entity_name, tiles_chest_trapped_double, node.param2, true, "default_chest", "mcl_chests_chest", "chest"):reinitialize("mcl_chests:trapped_chest_left")
		mesecon.receptor_off(pos_other, trapped_chest_mesecons_rules)
	end
	]]
end

-- To be called if a player opened a chest
local function player_chest_open(player, pos, node_name, entity_name, textures, param2, double, sound, mesh, shulker)
	local name = player:get_player_name()
	open_more_chests[name] = {
		pos = pos,
		node_name = node_name,
		entity_name = entity_name,
		textures = textures,
		param2 = param2,
		double = double,
		sound = sound,
		mesh = mesh,
		shulker = shulker
	}
	if animate_chests then
		local dir = minetest.facedir_to_dir(param2)
		find_or_create_entity(pos, node_name, entity_name, textures, param2, double, sound, mesh, "chest", dir):open(name)
	end
end

-- To be called if a player closed a chest
local function player_chest_close(player)
	local name = player:get_player_name()
	local open_chest = open_more_chests[name]
	if open_chest == nil then
		return
	end
	if animate_chests then
		find_or_create_entity(open_chest.pos, open_chest.node_name, open_chest.entity_name, open_chest.textures, open_chest.param2, open_chest.double, open_chest.sound, open_chest.mesh, "chest"):close(name)
	end
	--chest_update_after_close(open_chest.pos, open_chest.entity_name)

	open_more_chests[name] = nil
end

local function register_chest_entity(chest_entity_name)
	-- Chest Entity
	local entity_animations = {
		chest = {
			speed = 25,
			open = { x = 0, y = 7 },
			close = { x = 13, y = 20 },
		},
	}

	local chest_entity_def = {
		initial_properties = {
			visual = "mesh",
			pointable = false,
			physical = false,
			static_save = false,
		},

		set_animation = function(self, animname)
			local anim_table = entity_animations[self.animation_type]
			local anim = anim_table[animname]
			if not anim then return end
			self.object:set_animation(anim, anim_table.speed, 0, false)
		end,

		open = function(self, playername)
			self.players[playername] = true
			if not self.is_open then
				self:set_animation("open")
				minetest.sound_play(self.sound_prefix .. "_open", { pos = self.node_pos, gain = 0.5, max_hear_distance = 16 }, true)
				self.is_open = true
			end
		end,

		close = function(self, playername)
			local playerlist = self.players
			playerlist[playername] = nil
			if self.is_open then
				if next(playerlist) then
					return
				end
				self:set_animation("close")
				minetest.sound_play(self.sound_prefix .. "_close", { pos = self.node_pos, gain = 0.3, max_hear_distance = 16 }, true)
				self.is_open = false
			end
		end,

		initialize = function(self, node_pos, node_name, textures, dir, double, sound_prefix, mesh_prefix, animation_type)
			self.node_pos = node_pos
			self.node_name = node_name
			self.sound_prefix = sound_prefix
			self.animation_type = animation_type
			local obj = self.object
			obj:set_properties({ textures = textures, mesh = mesh_prefix .. (double and "_double" or "") .. ".b3d" })
			self:set_yaw(dir)
		end,

		reinitialize = function(self, node_name)
			self.node_name = node_name
		end,

		set_yaw = function(self, dir)
			self.object:set_yaw(minetest.dir_to_yaw(dir))
		end,

		check = function(self)
			local node_pos, node_name = self.node_pos, self.node_name
			if not node_pos or not node_name then
				return false
			end
			local node = minetest.get_node(node_pos)
			if node.name ~= node_name then
				return false
			end
			return true
		end,

		on_activate = function(self)
			self.object:set_armor_groups({ immortal = 1 })
			self.players = {}
		end,

		on_step = function(self, dtime)
			if not self:check() then
				self.object:remove()
			end
		end
	}

	-- Используется для регистрации сущностей (entities).
	-- Сущности динамичны — это объекты, которые могут перемещаться, анимационно изменяться или взаимодействовать с игроками. 
	-- Примеры: выпадающие предметы, мобов, стрелы, а также сундуки с анимацией крышки.
	minetest.register_entity(chest_entity_name, chest_entity_def)
end

local function close_chest_formspec(node_name, pos)
	minetest.log("action", "serega: close_chest_formspec, node_name=" .. minetest.serialize(node_name))
	local players = minetest.get_connected_players()
	for p = 1, #players do
		if vector.distance(players[p]:get_pos(), pos) <= 30 then
			local chest_formspec_id = sf("%s_%s_%s_%s", node_name, pos.x, pos.y, pos.z)
			minetest.close_formspec(players[p]:get_player_name(), chest_formspec_id)
		end
	end
end

local function open_chest_formspec(node_name, pos, desc, clicker)
	-- Генерация идентификатора формы
	local chest_formspec_id = sf("%s_%s_%s_%s", node_name, pos.x, pos.y, pos.z)

	-- Формирование формы
	local formspec_chest = table.concat({
		"formspec_version[4]",
		"size[11.75,10.425]",

		"label[0.375,0.375;" .. F(C(mcl_formspec.label_color, desc)) .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
		sf("list[nodemeta:%s,%s,%s;main;0.375,0.75;9,3;]", pos.x, pos.y, pos.z),
		"label[0.375,4.7;" .. F(C(mcl_formspec.label_color, S("Inventory"))) .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
		"list[current_player;main;0.375,5.1;9,3;9]",

		mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
		"list[current_player;main;0.375,9.05;9,1;]",
		sf("listring[nodemeta:%s,%s,%s;main]", pos.x, pos.y, pos.z),
		"listring[current_player;main]",
	})

	-- Отображение формы
	minetest.show_formspec(clicker:get_player_name(), chest_formspec_id, formspec_chest)
end

local function on_chest_blast(pos)
	local drop_items_chest = mcl_util.drop_items_from_meta_container("main")
	local node = minetest.get_node(pos)
	drop_items_chest(pos, node)
	minetest.remove_node(pos)
end

-- Возвращаем таблицу с функциями
return {
	get_entity_pos = get_entity_pos,
	get_entity_info = get_entity_info,
	create_entity = create_entity,
	find_entity = find_entity,
	find_or_create_entity = find_or_create_entity,
	protection_check_move = protection_check_move,
	protection_check_put_take = protection_check_put_take,
	chest_update_after_close = chest_update_after_close,
	player_chest_open = player_chest_open, 
	player_chest_close = player_chest_close,
	register_chest_entity = register_chest_entity,
	on_chest_blast = on_chest_blast,
	open_chest_formspec = open_chest_formspec,
	close_chest_formspec = close_chest_formspec
}