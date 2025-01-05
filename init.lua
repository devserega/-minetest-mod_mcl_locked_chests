local modname = minetest.get_current_modname()
local path = minetest.get_modpath(modname)

mcl_more_chests = {}

base = dofile(path .. "/core/base.lua")
--dofile(path .. "/models/custom_chest.lua")
dofile(path .. "/models/private_chest.lua")
dofile(path .. "/models/shared_chest.lua")
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
 	-- Проверяем, что имя формы начинается с mcl_more_chests:
	if formname:find("mcl_more_chests:") == 1 then
		-- Обработка кнопки "Quit" (закрытие формы)
		if fields.quit then
			base.player_chest_close(player)
		end
		
		-- Обработка поля "shared"
		if fields.shared then
			--minetest.log("action", "chest fields: " .. dump(fields))
			
			-- Получаем позицию объекта, с которым связана форма
			local x, y, z = formname:match("shared_chest_([%-?%d]+)_([%-?%d]+)_([%-?%d]+)")
			
			if x and y and z then
				-- Координаты успешно извлечены, создаем таблицу pos
				local pos = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
				--minetest.log("action", "Chest position: " .. minetest.pos_to_string(pos))

				-- Получаем мета-данные объекта
				local meta = minetest.get_meta(pos)
				
				-- Проверяем, что игрок является владельцем объекта (если необходимо)
				if meta:get_string("owner") == player:get_player_name() then
					-- Сохраняем значение из поля "shared" в мета-данные
					meta:set_string("shared", fields.shared)

					-- Логируем для отладки
					--minetest.log("action", "Shared value set to: " .. fields.shared)

					-- Здесь можно добавить другие действия, например, обновить форму
					-- minetest.show_formspec(player:get_player_name(), "your_form_name", get_formspec(fields.shared))
				else
					-- Если игрок не является владельцем, отправляем сообщение
					minetest.chat_send_player(player:get_player_name(), "You are not the owner of this chest.")
				end
			else
				minetest.log("error", "Failed to extract position from formname: " .. formname)
			end
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	base.player_chest_close(player)
end)