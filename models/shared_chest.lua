local S = minetest.get_translator("mcl_more_chests")
local F = minetest.formspec_escape
local C = minetest.colorize

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
local longdesc = S("To access its inventory, rightclick it. When broken, the items will drop out.")
local usagehelp = S("27 inventory slots")
local small_textures = {"mcl_secret_chest.png"}
--[[
local small_textures = {
	"shared_top.png",
	"shared_top.png",
	"shared_side.png",
	"shared_side.png",
	"shared_side.png",
	"shared_front.png"
}

local small_textures = {
	"shared_top.png",
	"shared_side.png",
	"shared_front.png"
}

local small_textures = {
	"shared_top.png",
	"shared_top.png",
	"shared_side.png" .. "^[transformFX",
	"shared_side.png",
	"shared_side.png",
	"shared_front.png"
}
]]

local sounds = mcl_sounds.node_sound_wood_defaults()
--local entity_sounds
local base_node_name = sf("mcl_more_chests:%s", basename)
local small_node_name = sf("mcl_more_chests:%s_%s", basename, small)
local entity_name = sf("mcl_more_chests:%s", basename)
local simple_rotate
local drop_items_chest = mcl_util.drop_items_from_meta_container("main")

--base.register_chest_entity(entity_name)

-- Используется для регистрации узлов (nodes) в Minetest.
-- Узлы — это блоки, которые игрок видит в мире (например, сундуки, травяные блоки, кирпичи и т.д.).
-- Узел имеет фиксированное положение в мире и становится частью карты.
local base_node_def = {
	description = description,
	_tt_help = "",
	_doc_items_longdesc = "",
	_doc_items_usagehelp = "",
	drawtype = "mesh",
	mesh = "mcl_chests_chest.b3d",
	tiles = small_textures,
	paramtype2 = "facedir",
	visual_scale = 1.0,
	legacy_facedir_simple = true,
	groups = {
		snappy=2,
		choppy=2,
		oddly_breakable_by_hand=2
	},
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_wood_defaults(),
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", S("@1 (owned by @2)", def.description, meta:get_string("owner")))
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local formspec_str = def.formspec or generate_formspec_string(def.size, def.inventory_name or nil)
		meta:set_string("formspec", formspec_str)
		meta:set_string("infotext", def.description)
		meta:set_string("owner", "")
		if def.inventory_name == nil or def.inventory_name == "main" then
			local inv = meta:get_inventory()
			local chest_size = def.size == "big" and 14*5 or 8*4
			inv:set_size("main", chest_size)
		end
	end,
}
minetest.register_node(base_node_name, base_node_def)

--[[
local function protection_check_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	if player:get_player_name() ~= meta:get_string("owner") then
		return 0
	else
		return count
	end
end

local function protection_check_put_take(pos, listname, index, stack, player)
	local meta = minetest.get_meta(pos)
	if player:get_player_name() ~= meta:get_string("owner") then
		return 0
	else
		return stack:get_count()
	end
end

local small_node_def = {
	description = description,
	_tt_help = tt_help,
	_doc_items_longdesc = longdesc,
	_doc_items_usagehelp = usagehelp,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.4375, -0.5, -0.4375, 0.4375, 0.375, 0.4375 },
	},
	tiles = { "blank.png^[resize:16x16" },
	use_texture_alpha = "clip",
	_chest_entity_textures = small_textures,
	_chest_entity_sound = "default_chest", --mcl_chests_enderchest
	_chest_entity_mesh = "mcl_chests_chest",
	_chest_entity_animation_type = "chest",
	groups = {
		handy = 1,
		axey = 1,
		container = 2,
		deco_block = 1,
		material_wood = 1,
		flammable = -1,
		chest_entity = 1,
		not_in_creative_inventory = 1
	},
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	drop = base_node_name,
	light_source = 7,
	sounds = sounds,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local param2 = minetest.get_node(pos).param2

		--meta:set_string("workaround", "ignore_me")
		--meta:set_string("workaround", nil) -- Done to keep metadata clean

		local inv = meta:get_inventory()
		inv:set_size("main", 9 * 3)
		inv:set_size("input", 1)

		base.create_entity(pos, small_node_name, entity_name, small_textures, param2, false, "default_chest", "mcl_chests_chest", "chest")

		minetest.log("action", "serega on_construct")
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:set_string("name", itemstack:get_meta():get_string("name"))
	end,
	after_dig_node = drop_items_chest,
	on_blast = base.on_chest_blast,
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

		if minetest.registered_nodes[minetest.get_node(vector.offset(pos, 0, 1, 0)).name].groups.opaque == 1 then
			-- won't open if there is no space from the top
			return false
		end

		base.open_chest_formspec(base_node_name, pos, description, clicker)

		--if on_rightclick_addendum then
		--	on_rightclick_addendum(pos, node, clicker)
		--end

		base.player_chest_open(clicker, pos, small_node_name, entity_name, small_textures, node.param2, false, "default_chest", "mcl_chests_chest")
	end,
	on_destruct = function(pos)
		base.close_chest_formspec(base_node_name, pos)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if fields.quit then
			--minetest.log("action", "serega_close_chest")
			base.player_chest_close(sender)
		end
	end,
	_mcl_silk_touch_drop = { base_node_name }, 
	on_rotate = simple_rotate,
}
minetest.register_node(small_node_name, small_node_def)
]]

-- Рецепт крафта
minetest.register_craft({
	type = "shapeless",
	recipe = {"mcl_chests:chest", "mcl_core:iron_ingot", "mcl_core:iron_ingot"},
	output = base_node_name,
})