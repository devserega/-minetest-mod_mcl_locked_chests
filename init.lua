local S = minetest.get_translator("area_locked_chests")

local def = {
	description = S("Area Protected Chest"),
	tiles = {
		"default_chest_top.png",
		"default_chest_top.png",
		"default_chest_side.png" .. "^[transformFX",
		"default_chest_side.png",
		"default_chest_side.png",
		"default_chest_lock.png"
	},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Area Protected Chest"))
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	can_dig = function(pos,player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return false
		end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		end
		return count
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		end
		return stack:get_count()
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return itemstack
		end
		minetest.show_formspec(name,"area_locked_chests:area_locked_chests",default.chest.get_chest_formspec(pos))
	end,
	on_blast = function() end,
}

default.set_inventory_action_loggers(def, "chest")

minetest.register_node("area_locked_chests:area_locked_chests", def)

minetest.register_craft({
	type = "shapeless",
	recipe = {"default:chest_locked","default:steel_ingot"},
	output = "area_locked_chests:area_locked_chests",
})
