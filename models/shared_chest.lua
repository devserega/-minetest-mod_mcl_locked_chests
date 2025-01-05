local S = minetest.get_translator("mcl_more_chests")
--local S = minetest.get_translator(minetest.get_current_modname())
local F = minetest.formspec_escape
local C = minetest.colorize
local drop_items_chest = mcl_util.drop_items_from_meta_container("main")

local string = string
local table = table
local math = math
local sf = string.format

-- Логирование действий с сундуком, если доступно в вашей версии
--if mcl_chests and mcl_chests.set_inventory_action_loggers then
--	mcl_chests.set_inventory_action_loggers(def, "chest")
--end

-- common custom chest configuration
local basename = "shared_chest"
local description = S("Shared Chest")
local tt_help = S("Shared Chest are containers which provide 27 inventory slots.")
local longdesc = S("To access its inventory, rightclick it.")
local usagehelp = S("27 inventory slots")
local small_textures = {"mcl_shared_chest.png"}
local sounds = mcl_sounds.node_sound_wood_defaults()
local base_node_name = sf("mcl_more_chests:%s", basename)
local small_node_name = sf("mcl_more_chests:%s_small", basename)
--local entity_name = sf("mcl_more_chests:%s", basename)
local entity_name = sf("mcl_more_chests:%s", "chest")
-- local entity_sound = "mcl_chests_enderchest"
local chest_entity_sound = "default_chest" -- Звук открытия/закрытия сундука
local simple_rotate

-- Chest Entity
base.register_chest_entity(entity_name)

-- Chest Node
local function open_chest_formspec(node_name, pos, desc, clicker)
	-- Генерация идентификатора формы
	local chest_formspec_id = string.format("%s_%s_%s_%s", node_name, pos.x, pos.y, pos.z)

	local meta = minetest.get_meta(pos)
	local shared_value = meta:get_string("shared") -- Получаем значение из мета-данных

	-- Проверяем, является ли игрок владельцем сундука
	local is_owner = meta:get_string("owner") == clicker:get_player_name()

	-- Формируем базовую часть формы
	local formspec_chest = {
		"formspec_version[4]",
		"size[11.75,11.425]",

		"label[0.375,0.375;" .. F(C(mcl_formspec.label_color, desc)) .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
		string.format("list[nodemeta:%s,%s,%s;main;0.375,0.75;9,3;]", pos.x, pos.y, pos.z),
		"label[0.375,4.7;Inventory]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
		"list[current_player;main;0.375,5.1;9,3;9]",

		mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
		"list[current_player;main;0.375,9.05;9,1;]",
		string.format("listring[nodemeta:%s,%s,%s;main]", pos.x, pos.y, pos.z),
		"listring[current_player;main]",
		string.format("field[0.375,10.6;9,0.5;shared;Shared with (names separated by spaces);%s]", shared_value),
	}

	-- Если игрок является владельцем, добавляем поле для ввода и кнопку
	if is_owner then
		table.insert(formspec_chest, "button[9.5,10.6;2,0.5;submit;Submit]")
	end

	-- Преобразуем таблицу в строку
	local formspec_string = table.concat(formspec_chest)

	-- Отображение формы
	minetest.show_formspec(clicker:get_player_name(), chest_formspec_id, formspec_string)
end

local function check_privs(meta, player)
	local player_name = player:get_player_name()
	local owner = meta:get_string("owner")
	local shared = meta:get_string("shared")

	-- Проверяем, если игрок является владельцем или его имя содержится в списке "shared"
	if player_name == owner then
		return true
	else
		-- Проверка на наличие имени игрока в списке shared (имена разделены пробелами)
		for name in string.gmatch(shared, "%S+") do
			if name == player_name then
				return true
			end
		end
		return false
	end
end

local function protection_check_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	if check_privs(meta, player) then
		return count
	else
		return 0
	end
end

local function protection_check_put_take(pos, listname, index, stack, player)
	local meta = minetest.get_meta(pos)
	if check_privs(meta, player) then
		return stack:get_count()
	else
		return 0
	end
end

local function on_chest_blast(pos)
-- Сундук остаётся на месте и не разрушается
end

-- Используется для регистрации узлов (nodes) в Minetest.
-- Узлы — это блоки, которые игрок видит в мире (например, сундуки, травяные блоки, кирпичи и т.д.).
-- Узел имеет фиксированное положение в мире и становится частью карты.
local base_node_def = {
	description = description,
	_tt_help = tt_help,
	_doc_items_longdesc = longdesc,
	_doc_items_usagehelp = usagehelp,
	_doc_items_hidden = false,
	drawtype = "mesh",
	mesh = "mcl_chests_chest.b3d",
	tiles = small_textures,
	use_texture_alpha = "opaque",
	paramtype = "light",
	paramtype2 = "facedir",
	sounds = sounds,
	groups = { deco_block = 1 },
	_entity_name = entity_name, -- Кастомное поле для имени сущности
	on_construct = function(pos)
		local node = minetest.get_node(pos)
		node.name = small_node_name
		minetest.set_node(pos, node)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)

		meta:set_string("name", itemstack:get_meta():get_string("name"))

		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", S("@1 (owned by @2)", description, meta:get_string("owner")))
		minetest.log("action", "after_place_node1: owner=" .. placer:get_player_name())
	end
}
minetest.register_node(base_node_name, base_node_def)

local small_node_def = {
	description = description,
	_tt_help = tt_help,
	_doc_items_longdesc = longdesc,
	_doc_items_usagehelp = usagehelp,
	_doc_items_hidden = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.4375, -0.5, -0.4375, 0.4375, 0.375, 0.4375 },
	},
	tiles = { "blank.png^[resize:16x16" },
	use_texture_alpha = "clip",
	_chest_entity_textures = small_textures,
	_chest_entity_sound = chest_entity_sound,
	_chest_entity_mesh = "mcl_chests_chest",
	_chest_entity_animation_type = "chest",
	paramtype = "light",
	paramtype2 = "facedir",
	drop = base_node_name,
	groups = {
		handy = 1,
		axey = 1,
		container = 2,
		deco_block = 1,
		material_wood = 1,
		flammable = -1,
		more_chest_entity = 1,
		not_in_creative_inventory = 1
	},
	_entity_name = entity_name, -- Кастомное поле для имени сущности
	is_ground_content = false,
	sounds = sounds,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local param2 = minetest.get_node(pos).param2

		meta:set_string("workaround", "ignore_me")
		meta:set_string("workaround", nil) -- Done to keep metadata clean

		local inv = meta:get_inventory()
		inv:set_size("main", 9 * 3)
		inv:set_size("input", 1)

		minetest.swap_node(pos, { name = small_node_name, param2 = param2 })
		base.create_entity(pos, small_node_name, entity_name, small_textures, param2, false, "default_chest", "mcl_chests_chest", "chest")
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		--minetest.log("action", "serega after_place_node: owner=" .. placer:get_player_name())
		local meta = minetest.get_meta(pos)
		meta:set_string("name", itemstack:get_meta():get_string("name"))
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	after_dig_node = drop_items_chest,
	on_blast = on_chest_blast,
	allow_metadata_inventory_move = protection_check_move,
	allow_metadata_inventory_take = protection_check_put_take,
	allow_metadata_inventory_put = protection_check_put_take,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name() .. " moves stuff in chest at " .. minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() .. " moves stuff to chest at " .. minetest.pos_to_string(pos))
		if listname == "input" then
			local inv = minetest.get_inventory({ type = "node", pos = pos })
			inv:add_item("main", stack)
		end
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name() .. " takes stuff from chest at " .. minetest.pos_to_string(pos))
	end,
	_mcl_blast_resistance = 2.5,
	_mcl_hardness = 2.5,

	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)

		local topnode = minetest.get_node({ x = pos.x, y = pos.y + 1, z = pos.z })
		if topnode and topnode.name and minetest.registered_nodes[topnode.name] then
			if minetest.registered_nodes[topnode.name].groups.opaque == 1 then
				-- won't open if there is no space from the top
				return false
			end
		end

		open_chest_formspec(base_node_name, pos, description, clicker)

		--if on_rightclick_addendum then
		--	on_rightclick_addendum(pos, node, clicker)
		--end

		base.player_chest_open(clicker, pos, small_node_name, entity_name, small_textures, node.param2, false, "default_chest", "mcl_chests_chest")
	end,

	on_destruct = function(pos)
		base.close_chest_formspec(base_node_name, pos)
	end,

	on_rotate = simple_rotate,
}
minetest.register_node(small_node_name, small_node_def)

--local no_rotate, simple_rotate
--if minetest.get_modpath("screwdriver") then
--	no_rotate = screwdriver.disallow
--	simple_rotate = function(pos, node, user, mode, new_param2)
--		if screwdriver.rotate_simple(pos, node, user, mode, new_param2) ~= false then
--			local nodename = node.name
--			local nodedef = minetest.registered_nodes[nodename]
--			local dir = minetest.facedir_to_dir(new_param2)
--			find_or_create_entity(pos, nodename, nodedef._chest_entity_textures, new_param2, false,
--				nodedef._chest_entity_sound,
--				nodedef._chest_entity_mesh, nodedef._chest_entity_animation_type, dir):set_yaw(dir)
--		else
--			return false
--		end
--	end
--end

-- Рецепт крафта
minetest.register_craft({
	output = base_node_name,
	recipe = {
		{ "group:wood", "group:leaves", "group:wood" },
		{ "group:wood", "mcl_core:gold_ingot", "group:wood" },
		{ "group:wood", "group:wood", "group:wood" },
	},
})

--[[
minetest.register_craft({
	type = "shapeless",
	recipe = {"mcl_chests:chest", "mcl_core:iron_ingot", "mcl_core:iron_ingot"},
	output = base_node_name,
})
]]