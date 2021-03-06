local utils = ...



local function get_robot_side (pos, param2, side)
	local base = nil

	if side == "up" then
		return { x = pos.x, y = pos.y + 1, z = pos.z }
	elseif side == "down" then
		return { x = pos.x, y = pos.y - 1, z = pos.z }
	elseif side == "left" then
		base = { x = -1, y = pos.y, z = 0 }
	elseif side == "right" then
		base = { x = 1, y = pos.y, z = 0 }
	elseif side == "front" then
		base = { x = 0, y = pos.y, z = 1 }
	elseif side == "front up" then
		base = { x = 0, y = pos.y + 1, z = 1 }
	elseif side == "front down" then
		base = { x = 0, y = pos.y - 1, z = 1 }
	elseif side == "back" then
		base = { x = 0, y = pos.y, z = -1 }
	elseif side == "back up" then
		base = { x = 0, y = pos.y + 1, z = -1 }
	elseif side == "back down" then
		base = { x = 0, y = pos.y - 1, z = -1 }
	else
		return nil
	end

	if param2 == 3 then -- +x
		return { x = base.z + pos.x, y = base.y, z = (base.x * -1) + pos.z }
	elseif param2 == 0 then -- -z
		return { x = (base.x * -1) + pos.x, y = base.y, z = (base.z * -1) + pos.z }
	elseif param2 == 1 then -- -x
		return { x = (base.z * -1) + pos.x, y = base.y, z = base.x + pos.z }
	elseif param2 == 2 then -- +z
		return { x = base.x + pos.x, y = base.y, z = base.z + pos.z }
	end

	return nil
end



local function get_far_node (pos)
	local node = minetest.get_node (pos)

	if node.name == "ignore" then
		minetest.get_voxel_manip ():read_from_map (pos, pos)

		node = minetest.get_node (pos)

		if node.name == "ignore" then
			return nil
		end
	end

	return node
end



function utils.robot_detect (robot_pos, side)
	local node = minetest.get_node_or_nil (robot_pos)

	if node then
		local pos = get_robot_side (robot_pos, node.param2, side)

		if pos then
			node = get_far_node (pos)

			if node then
				return node.name
			end
		end
	end

	return nil
end



function utils.robot_move (robot_pos, side)
	local cur_node = minetest.get_node_or_nil (robot_pos)
	if not cur_node then
		return false
	end

	local pos = get_robot_side (robot_pos, cur_node.param2, side)
	if not pos then
		return false
	end

	local node = get_far_node (pos)
	if not node then
		return false
	end

	local nodedef = minetest.registered_nodes[node.name]

	if not nodedef or nodedef.walkable then
		return false
	end

	local meta = minetest.get_meta (robot_pos)
	if not meta then
		return false
	end

	local inv = meta:get_inventory ()
	if not inv then
		return false
	end

	minetest.get_node_timer (robot_pos):stop ()

	local id = meta:get_int ("lwscratch_id")
	local name = meta:get_string ("name")
	local infotext = meta:get_string ("infotext")
	local inventory = meta:get_string ("inventory")
	local owner = meta:get_string ("owner")
	local persists = meta:get_int ("persists")
	local running = meta:get_int ("running")
	local formspec = meta:get_string ("formspec")
	local program = minetest.deserialize (meta:get_string ("program"))

	local storage = { }
	local slots = inv:get_size ("storage")
	for s = 1, slots do
		storage[s] = inv:get_stack ("storage", s)
	end

	local value_slot = inv:get_stack ("value", 1)

	if persists == 1 then
		minetest.forceload_free_block (robot_pos, false)
	end

	meta:set_int ("lwscratch_id", 0)
	minetest.remove_node (robot_pos)

	minetest.add_node (pos, cur_node)

	meta = minetest.get_meta (pos)
	inv = meta:get_inventory ()

	meta:set_int ("lwscratch_id", id)
	meta:set_string ("name", name)
	meta:set_string ("infotext", infotext)
	meta:set_string ("inventory", inventory)
	meta:set_string ("owner", owner)
	meta:set_int ("persists", persists)
	meta:set_int ("running", running)
	meta:set_string ("program", minetest.serialize (program))
	meta:set_string ("formspec", formspec)

	inv:set_size ("value", 1)
	inv:set_width ("value", 1)
	inv:set_size ("program", utils.program_inv_size)
	inv:set_width ("program", 10)
	inv:set_size ("commands", utils.commands_inv_size)
	inv:set_width ("commands", 8)
	inv:set_size ("storage", 32)
	inv:set_width ("storage", 8)

	utils.prep_inventory (inv, program)

	slots = inv:get_size ("storage")
	for s = 1, slots do
		inv:set_stack ("storage", s, storage[s])
	end

	inv:set_stack ("value", 1, value_slot)

	if persists == 1 then
		minetest.forceload_block (pos, false)
	end

	minetest.get_node_timer (pos):start (utils.settings.running_tick)

	meta:set_int ("delay_counter",
		math.ceil (utils.settings.robot_move_delay / utils.settings.running_tick))

	return true, pos
end



function utils.robot_turn (robot_pos, side)
	local cur_node = minetest.get_node_or_nil (robot_pos)
	if not cur_node then
		return false
	end

	if side == "left" then
		cur_node.param2 = (cur_node.param2 + 3) % 4
	elseif side == "right" then
		cur_node.param2 = (cur_node.param2 + 1) % 4
	else
		return false
	end

	minetest.swap_node(robot_pos, cur_node)

	local meta = minetest.get_meta (robot_pos)
	if meta then
		meta:set_int ("delay_counter",
			math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))
	end

	return true
end



function utils.robot_dig (robot_pos, side)
	local meta = minetest.get_meta (robot_pos)
	local cur_node = minetest.get_node_or_nil (robot_pos)
	if not meta or not cur_node then
		return nil
	end

	local pos = get_robot_side (robot_pos, cur_node.param2, side)
	if not pos then
		return nil
	end

	local node = get_far_node (pos)
	if not node then
		return nil
	end

	local nodedef = minetest.registered_nodes[node.name]

	if not nodedef or not nodedef.diggable or minetest.is_protected (pos, "") then
		return nil
	end

	if nodedef.can_dig then
		if nodedef.can_dig (pos) == false then
			return nil
		end
	end

	local inv = meta:get_inventory ()
	if not inv then
		return nil
	end

	local items = minetest.get_node_drops (node, nil)
	if items then
		for i = 1, #items do
			local stack = ItemStack (items[i])
			local name = items[i]:match ("[%S]+")

			if name == node.name and stack then
				if nodedef.preserve_metadata then
					nodedef.preserve_metadata (pos, node, minetest.get_meta (pos), { stack })
				end
			end

			local over = inv:add_item ("storage", stack)

			if over and over:get_count () > 0 then
				minetest.item_drop (over, nil, pos)
			end
		end
	end

	minetest.remove_node (pos)

	meta:set_int ("delay_counter",
		math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))

	return node.name
end



function utils.robot_place (robot_pos, side, nodename)
	nodename = tostring (nodename or "")

	if nodename:len () < 1 or nodename == "air" then
		return false
	end

	local stack = ItemStack (nodename)
	local meta = minetest.get_meta (robot_pos)
	local cur_node = minetest.get_node_or_nil (robot_pos)
	if not stack or not meta or not cur_node  then
		return false
	end

	local inv = meta:get_inventory ()
	if not inv or not inv:contains_item ("storage", stack, false) then
		return false
	end

	local pos = get_robot_side (robot_pos, cur_node.param2, side)
	if not pos then
		return false
	end

	local node = get_far_node (pos)
	if not node then
		return false
	end

	if node.name ~= "air" then
		local nodedef = minetest.registered_nodes[node.name]

		if not nodedef or not nodedef.buildable_to or minetest.is_protected (pos, "") then
			return false
		end
	end

	if not inv:remove_item ("storage", stack) then
		return false
	end

	nodename = utils.get_place_substitute (nodename)

	minetest.set_node (pos, { name = nodename, param1 = 0, param2 = 0})

	meta:set_int ("delay_counter",
		math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))

	return true
end



function utils.robot_contains (robot_pos, nodename)
	local meta = minetest.get_meta (robot_pos)
	if not meta then
		return false
	end

	local inv = meta:get_inventory ()
	if not inv then
		return false
	end

	if nodename then
		local stack = ItemStack (nodename)
		if not stack then
			return false
		end

		return inv:contains_item ("storage", stack, false)
	else
		local slots = inv:get_size ("storage")

		for i = 1, slots do
			local stack = inv:get_stack ("storage", i)

			if stack and not stack:is_empty () then
				return true
			end
		end
	end

	return false
end



function utils.robot_room_for (robot_pos, nodename)
	local meta = minetest.get_meta (robot_pos)
	if not meta then
		return false
	end

	local inv = meta:get_inventory ()
	if not inv then
		return false
	end

	if nodename then
		local stack = ItemStack (nodename)
		if not stack then
			return false
		end

		return inv:room_for_item ("storage", stack)
	else
		local slots = inv:get_size ("storage")

		for i = 1, slots do
			local stack = inv:get_stack ("storage", i)

			if not stack or stack:is_empty () then
				return true
			end
		end
	end

	return false
end



function utils.robot_cur_pos (robot_pos, nodename)
	return { x = robot_pos.x, y = robot_pos.y, z = robot_pos.z }
end



function utils.robot_slots (robot_pos)
	local meta = minetest.get_meta (robot_pos)
	if not meta then
		return nil
	end

	local inv = meta:get_inventory ()
	if not inv then
		return nil
	end

	return inv:get_size ("storage")
end



function utils.robot_slot (robot_pos, slot)
	local meta = minetest.get_meta (robot_pos)
	if not meta then
		return nil
	end

	local inv = meta:get_inventory ()
	if not inv then
		return nil
	end

	local slots = inv:get_size ("storage")
	if slot < 1 or slot > slots then
		return nil
	end

	local stack = inv:get_stack ("storage", slot)
	if not stack or stack:is_empty () then
		return nil
	end

	if stack:is_empty () then
		return { name = nil, count = 0 }
	end

	return { name = stack:get_name(), count = stack:get_count() }
end



function utils.robot_put (robot_pos, side, item)
	local meta = minetest.get_meta (robot_pos)
	local cur_node = minetest.get_node_or_nil (robot_pos)

	if not meta or not cur_node then
		return false
	end

	local inv = meta:get_inventory ()

	if not inv then
		return false
	end

	local pos = get_robot_side (robot_pos, cur_node.param2, side)

	if not pos then
		return false
	end

	local node = get_far_node (pos)

	if not node then
		return false
	end

	if node.name == "air" then
		return false
	end

	local imeta =  minetest.get_meta (pos)

	if not imeta then
		return false
	end

	local iinv = imeta:get_inventory ()

	if not iinv then
		return false
	end

	if item then
		local stack = ItemStack ({ name = item, count = 1 })

		if not stack or not inv:contains_item ("storage", stack, false) then
			return false
		end

		if not iinv:room_for_item ("main", stack) then
			return false
		end

		iinv:add_item("main", stack)
		inv:remove_item ("storage", stack)

	else
		local slots = inv:get_size ("storage")

		if not slots then
			return false
		end

		for s = 1, slots do
			local stack = inv:get_stack ("storage", s)

			if stack and not stack:is_empty () then
				if iinv:room_for_item ("main", stack) then
					iinv:add_item ("main", stack)
					inv:set_stack ("storage", s, nil)
				end
			end
		end

	end

	meta:set_int ("delay_counter",
		math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))

	return true
end



function utils.robot_pull (robot_pos, side, item)
	local meta = minetest.get_meta (robot_pos)
	local cur_node = minetest.get_node_or_nil (robot_pos)

	if not meta or not cur_node then
		return false
	end

	local inv = meta:get_inventory ()

	if not inv then
		return false
	end

	local pos = get_robot_side (robot_pos, cur_node.param2, side)

	if not pos then
		return false
	end

	local node = get_far_node (pos)

	if not node then
		return false
	end

	if node.name == "air" then
		return false
	end

	local imeta =  minetest.get_meta (pos)

	if not imeta then
		return false
	end

	local iinv = imeta:get_inventory ()

	if not iinv then
		return false
	end

	if item then
		local stack = ItemStack ({ name = item, count = 1 })

		if not stack or not iinv:contains_item ("main", stack, false) then
			return false
		end

		if not inv:room_for_item ("storage", stack) then
			return false
		end

		inv:add_item("storage", stack)
		iinv:remove_item ("main", stack)

	else
		local slots = iinv:get_size ("main")

		if not slots then
			return false
		end

		for s = 1, slots do
			local stack = iinv:get_stack ("main", s)

			if stack and not stack:is_empty () then

				if inv:room_for_item ("storage", stack) then
					inv:add_item ("storage", stack)
					iinv:set_stack ("main", s, nil)
				end
			end
		end

	end

	meta:set_int ("delay_counter",
		math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))

	return true
end



local function substitute_group (item, inv)
	local source = ItemStack (item)

	if item:sub (1, 6) ~= "group:" then
		return source
	end

	local group = item:sub (7)

	local slots = inv:get_size ("storage")
	for s = 1, slots do
		local stack = inv:get_stack ("storage", s)

		if stack and stack:get_count () > 0 then
			if minetest.get_item_group (stack:get_name (), group) > 0 then
				local replace = ItemStack (stack:get_name ())

				if replace then
					replace:set_count (source:get_count ())

					return replace
				end
			end
		end
	end

	return source
end



function utils.robot_craft (robot_pos, item)
	item = tostring (item or "")

	if item:len () < 1 then
		return false
	end

	local meta = minetest.get_meta (robot_pos)
	local inv = meta:get_inventory ()
	if not meta or not inv then
		return false
	end

	local recipes = minetest.get_all_craft_recipes(item)

	if not recipes then
		return false
	end

	for r = 1, #recipes do
		if (recipes[r].type and recipes[r].type == "normal") or
			(recipes[r].method and recipes[r].method == "normal") then

			local match = true

			local items = { }
			for i = 1, #recipes[r].items do
				local stack = substitute_group (recipes[r].items[i], inv)

				if stack then
					if items[stack:get_name ()] then
						items[stack:get_name ()] = items[stack:get_name ()] + stack:get_count ()
					else
						items[stack:get_name ()] = stack:get_count ()
					end
				end
			end

			for k, v in pairs (items) do
				local stack = ItemStack (k)

				if stack then
					stack:set_count (v)

					if not inv:contains_item ("storage", stack, false) then
						match = false
						break
					end
				end
			end

			if match then
				for k, v in pairs (items) do
					local stack = ItemStack (k)

					if stack then
						stack:set_count (v)

						inv:remove_item ("storage", stack)
					end
				end

				inv:add_item ("storage", ItemStack (recipes[r].output))

				local output, leftover = minetest.get_craft_result (recipes[r])

				if output and output.replacements and #output.replacements > 0 then
					for i = 1, #output.replacements do
						if output.replacements[i]:get_count () > 0 then
							inv:add_item ("storage", output.replacements[i])
						end
					end
				end

				if leftover and leftover.items then
					for i = 1, #leftover.items do
						if leftover.items[i]:get_count () > 0 then
							inv:add_item ("storage", leftover.items[i])
						end
					end
				end

				local mods = utils.get_crafting_mods (item)
				if mods then
					if mods.add then
						for i = 1, #mods.add do
							local stack = ItemStack (mods.add[i])

							if stack and stack:get_count () > 0 then
								inv:add_item ("storage", stack)
							end
						end
					end


					if mods.remove then
						for i = 1, #mods.remove do
							local stack = ItemStack (mods.remove[i])

							if stack and stack:get_count () > 0 then
								inv:remove_item ("storage", stack)
							end
						end
					end
				end

				meta:set_int ("delay_counter",
					math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))

				return true
			end
		end
	end

	return false
end



function utils.robot_find_inventory (robot_pos, listname)
	local result = { }
	local sides = { "up", "down", "front", "back", "left", "right" }
	local cur_node = minetest.get_node_or_nil (robot_pos)
	if not cur_node  then
		return false
	end

	if listname then
		listname = tostring (listname)
	end

	for s = 1, #sides do
		local pos = get_robot_side (robot_pos, cur_node.param2, sides[s])

		if pos then
			local node = get_far_node (pos)

			if node and node.name ~= "air" then
				local meta =  minetest.get_meta (pos)

				if meta then
					local inv = meta:get_inventory ()

					if inv then
						if listname then
							local slots = inv:get_size (listname)

							if slots and slots > 0 then
								result[#result + 1] = sides[s]
								result[sides[s]] = slots
							end
						else
							result[#result + 1] = sides[s]
							result[sides[s]] = true
						end
					end
				end
			end
		end
	end

	if #result > 0 then
		return result
	end

	return nil
end



function utils.robot_remove_item (robot_pos, item, drop)
	local count = 1
	local name = nil

	local meta = minetest.get_meta (robot_pos)
	if not meta then
		return false
	end

	local inv = meta:get_inventory ()
	if not inv then
		return false
	end

	if item then
		local stack = ItemStack ({ name = item, count = 1 })
		if not stack or not inv:contains_item ("storage", stack, false) then
			return false
		end

		inv:remove_item ("storage", stack)

		if drop then
			minetest.item_drop (stack, nil, robot_pos)
		else
			lwdrops.on_destroy (stack)
		end

	else
		local slots = inv:get_size ("storage")

		if not slots then
			return false
		end

		for s = 1, slots do
			local stack = inv:get_stack ("storage", s)

			if stack and not stack:is_empty () then

				inv:set_stack ("storage", s, nil)

				if drop then
					minetest.item_drop (stack, nil, robot_pos)
				else
					lwdrops.on_destroy (stack)
				end
			end
		end

	end

	meta:set_int ("delay_counter",
		math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))

	return true
end







--
