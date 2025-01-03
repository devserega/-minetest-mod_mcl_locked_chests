local gen_def = dofile(minetest.get_modpath("more_chests") .. "/utils/base.lua")
local actions = dofile(minetest.get_modpath("more_chests") .. "/utils/actions.lua")
local S = minetest.get_translator("more_chests")
local F = minetest.formspec_escape
local C = minetest.colorize

local string = string
local table = table
local math = math
local sf = string.format

local function get_open_formspec(pos)
	return table.concat({
		"formspec_version[4]", -- Версия формы
		"size[11.75,12.425]", -- Размер интерфейса

		"label[0.375,0.375;" .. minetest.formspec_escape("Secret Chest") .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
		string.format("list[nodemeta:%d,%d,%d;main;0.375,0.75;9,3;]", pos.x, pos.y, pos.z),

		"label[0.375,4.7;" .. minetest.formspec_escape("Inventory") .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
		"list[current_player;main;0.375,5.1;9,3;9]",

		mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
		"list[current_player;main;0.375,9.05;9,1;]",
		string.format("listring[nodemeta:%d,%d,%d;main]", pos.x, pos.y, pos.z),
		"listring[current_player;main]",
	})
end

local function get_closed_formspec()
	return "size[2,1]" ..
	       "button[0,0;2,1;open;Text_Open]"
end

local secret = gen_def({
	description = S("Secret Chest"),
	type = "secret chest",
	size = "small",
	tiles = {
		top = "secret_top.png",
		side = "secret_side.png",
		front = "secret_front.png"
	},
	formspec = get_closed_formspec(),
	pipeworks_enabled = true,
})

--secret.on_receive_fields = function(pos, formname, fields, sender)
--	local meta = minetest.get_meta(pos)
	--if actions.has_locked_chest_privilege(meta, sender) then
	--	if fields.open == "open" then
	--		meta:set_string("formspec", get_open_formspec(pos))
	--	else
	--		meta:set_string("formspec", get_closed_formspec())
	--	end
	--end
--end

secret.on_rightclick = function(pos, node, clicker)
	local meta = minetest.get_meta(pos)

	if minetest.registered_nodes[minetest.get_node(vector.offset(pos, 0, 1, 0)).name].groups.opaque == 1 then
		-- won't open if there is no space from the top
		return false
	end

	--if not actions.has_locked_chest_privilege(meta, clicker) then
	--	return false
	--end

	local chest_formspec_id = sf("more_chests:%s_%s_%s_%s", "secret", pos.x, pos.y, pos.z)

	local formspec_chest = table.concat({
		"formspec_version[4]", -- Версия формы
		"size[11.75,12.425]", -- Размер интерфейса

		"label[0.375,0.375;" .. minetest.formspec_escape("Secret Chest") .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
		string.format("list[nodemeta:%d,%d,%d;main;0.375,0.75;9,3;]", pos.x, pos.y, pos.z),

		"label[0.375,4.7;" .. minetest.formspec_escape("Inventory") .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
		"list[current_player;main;0.375,5.1;9,3;9]",

		mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
		"list[current_player;main;0.375,9.05;9,1;]",
		string.format("listring[nodemeta:%d,%d,%d;main]", pos.x, pos.y, pos.z),
		"listring[current_player;main]",
	})

	minetest.show_formspec(clicker:get_player_name(), chest_formspec_id, formspec_chest)
end

minetest.register_node("more_chests:secret", secret)


minetest.register_craft({
	output = "more_chests:secret",
	recipe = {
		{"group:wood", "default:cobble", "group:wood"},
		{"group:wood", "default:steel_ingot", "group:wood"},
		{"group:wood", "group:wood", "group:wood"}
	}
})
