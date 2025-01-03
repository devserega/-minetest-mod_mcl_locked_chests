local modname = minetest.get_current_modname()
local path = minetest.get_modpath(modname)
local drop_items_chest = mcl_util.drop_items_from_meta_container("main")

mcl_more_chests = {}

base = dofile(path .. "/core/base.lua")
dofile(path .. "/models/custom_chest.lua")
dofile(path .. "/models/private_chest.lua")
--dofile(path .. "/shared_chest.lua")

local function select_and_spawn_entity(pos, node)
	local node_name = node.name
	local node_def = minetest.registered_nodes[node_name]
	local double_chest = minetest.get_item_group(node_name, "double_chest") > 0
	--minetest.log("action", "serega: select_and_spawn_entity, entity_name=" .. minetest.serialize(node_def._entity_name))
	base.find_or_create_entity(pos, node_name, node_def._entity_name, node_def._chest_entity_textures, node.param2, double_chest, node_def._chest_entity_sound, node_def._chest_entity_mesh, node_def._chest_entity_animation_type)
end

-- Этот код выполняет автоматическое создание сущностей (entities) сундуков для соответствующих нод при загрузке карты.
minetest.register_lbm({
	label = "Spawn More Chest entities",
	name = "mcl_more_chests:spawn_more_chest_entities",
	nodenames = { "group:more_chest_entity" },
	run_at_every_load = true,
	action = select_and_spawn_entity,
})

-- Disable chest when it has been closed
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname:find("mcl_more_chests:") == 1 then
		if fields.quit then
			base.player_chest_close(player)
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	base.player_chest_close(player)
end)