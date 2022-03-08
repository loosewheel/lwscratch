local utils = ...



local function get_robot_side (pos, param2, side)
	local base

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



local function get_place_dir (itemname, robot_pos, robot_param2, dir, pallet_index)
	if dir then
		local side_pos = get_robot_side (robot_pos, robot_param2, dir)

		if side_pos then
			local vdir = vector.subtract (side_pos, robot_pos)
			local def = utils.find_item_def (itemname)

			if def and def.paramtype2 then
				if def.paramtype2 == "wallmounted" or
					def.paramtype2 == "colorwallmounted" then

					return minetest.dir_to_wallmounted (vdir) + (pallet_index * 8)

				elseif def.paramtype2 == "facedir" or
						 def.paramtype2 == "colorfacedir" then

					return minetest.dir_to_facedir (vdir, false) + (pallet_index * 32)

				elseif def.paramtype2 == "color" then
					return pallet_index

				end
			end
		end
	end

	return 0
end



local function get_robot_side_vector (param2, side)
	local dir = minetest.facedir_to_dir (param2)

	if side == "up" then
		return { x = 0, y = 1, z = 0 }
	elseif side == "down" then
		return { x = 0, y = -1, z = 0 }
	elseif side == "left" then
		return vector.rotate (dir, { x = 0, y = (math.pi * 1.5), z = 0 })
	elseif side == "right" then
		return vector.rotate (dir, { x = 0, y = (math.pi * 0.5), z = 0 })
	elseif side == "front" then
		return vector.rotate (dir, { x = 0, y = math.pi, z = 0 })
	elseif side == "front up" then
		return { x = 0, y = 1, z = 0 }
	elseif side == "front down" then
		return { x = 0, y = -1, z = 0 }
	elseif side == "back" then
		return dir
	elseif side == "back up" then
		return { x = 0, y = 1, z = 0 }
	elseif side == "back down" then
		return { x = 0, y = -1, z = 0 }
	else
		return dir
	end
end



local function get_max_stack (item)
	local def = nil

	if type (item) == "string" then
		def = utils.find_item_def (item)
	elseif item and item.get_name then
		def = utils.find_item_def (item:get_name ())
	end

	if def and def.stack_max then
		return def.stack_max
	end

	return utils.settings.default_stack_max
end



local function get_max_inventory_fit (item, inv, list)
	local stack_max = get_max_stack (item)
	local stack = ItemStack ({ name = item, count = stack_max })

	while stack_max > 0 and not inv:room_for_item (list, stack) do
		stack_max = stack_max - 1
		stack:set_count (stack_max)
	end

	return stack_max
end



local function get_total_inventory_item (item, inv, list)
	local stack_count = 0
	local slots = inv:get_size (list)

	if not slots then
		return 0
	end

	for s = 1, slots do
		local stack = inv:get_stack (list, s)

		if stack and not stack:is_empty () then
			if stack:get_name () == item then
				stack_count = stack_count + stack:get_count ()
			end
		end
	end

	return stack_count
end



function utils.robot_detect (robot_pos, side)
	local node = minetest.get_node_or_nil (robot_pos)

	if node then
		local pos = get_robot_side (robot_pos, node.param2, side)

		if pos then
			node = utils.get_far_node (pos)

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

	local node = utils.get_far_node (pos)
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

	local node = utils.get_far_node (pos)
	if not node then
		return nil
	end

	local nodedef = minetest.registered_nodes[node.name]

	if not nodedef or not nodedef.diggable or minetest.is_protected (pos, "") or
		minetest.get_item_group (node.name, "unbreakable") > 0 then

		return nil
	end

	if nodedef.can_dig then
		local result, diggable = pcall (nodedef.can_dig, pos)

		if not result then
			if utils.settings.alert_handler_errors then
				minetest.log ("error", "can_dig handler for "..node.name.." crashed - "..diggable)
			end

			return nil
		elseif diggable == false then
			return nil
		end
	end

	local inv = meta:get_inventory ()
	if not inv then
		return nil
	end

	local items = minetest.get_node_drops (node, nil)

	if items then
		local drops = { }

		for i = 1, #items do
			drops[i] = ItemStack (items[i])
		end

		if nodedef and nodedef.preserve_metadata then
			nodedef.preserve_metadata (pos, node, minetest.get_meta (pos), drops)
		end

		for i = 1, #items do
			local over = inv:add_item ("storage", drops[i])

			if over and over:get_count () > 0 then
				utils.item_drop (over, nil, pos)
			end
		end
	end

	if nodedef and nodedef.sounds and nodedef.sounds.dug then
		pcall (minetest.sound_play, nodedef.sounds.dug, { pos = pos })
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

	local node = utils.get_far_node (pos)
	if not node then
		return false
	end

	local place_pos = { x = pos.x, y = pos.y, z = pos.z }
	local dir = side
	if dir == "front down" or dir == "back down" then
		dir = "down"
	elseif dir == "front up" or dir == "back up" then
		dir = "up"
	end

	if node.name ~= "air" then
		local nodedef = minetest.registered_nodes[node.name]

		if not nodedef or not nodedef.buildable_to or minetest.is_protected (pos, "") then
			return false
		end

		if nodedef.buildable_to then
			if dir == "up" then
				place_pos = get_robot_side (pos, cur_node.param2, "down")
			elseif dir == "down" then
				place_pos = get_robot_side (pos, cur_node.param2, "up")
			elseif dir == "front" then
				place_pos = get_robot_side (pos, cur_node.param2, "back")
			elseif dir == "back" then
				place_pos = get_robot_side (pos, cur_node.param2, "front")
			end
		end
	end

	if not inv:remove_item ("storage", stack) then
		return false
	end

	local def = utils.find_item_def (stack:get_name ())
	local placed = false
	local vec = get_robot_side_vector (cur_node.param2, side)
	local pointed_thing =
	{
		type = "node",
		under = place_pos,
		above = { x = place_pos.x - vec.x,
					 y = place_pos.y - vec.y,
					 z = place_pos.z - vec.z },
	}

	if stack:get_name ():sub (1, 8) == "farming:" then
		pointed_thing.under = { x = place_pos.x + vec.x,
										y = place_pos.y + vec.y,
										z = place_pos.z + vec.z }
		pointed_thing.above = place_pos
	end

	if utils.settings.use_mod_on_place then
		if def and def.on_place then
			local result, leftover = pcall (def.on_place, stack, nil, pointed_thing)

			placed = result

			if not placed then
				if utils.settings.alert_handler_errors then
					minetest.log ("error", "on_place handler for "..stack:get_name ().." crashed - "..leftover)
				end
			elseif not leftover then
				inv:add_item ("storage", stack)
			elseif leftover and leftover.get_count and leftover:get_count () > 0 then
				inv:add_item ("storage", leftover)
			end
		end
	end

	if not placed then
		local param2 = get_place_dir (stack:get_name (), robot_pos, cur_node.param2, dir,
												utils.get_palette_index (stack))
		local substitute = utils.get_place_substitute (stack:get_name (), dir)
		local orgstack = ItemStack (stack)

		if stack:get_name () ~= substitute then
			stack = ItemStack (substitute)
			def = utils.find_item_def (stack:get_name ())
		end

		if not minetest.registered_nodes[stack:get_name ()] then
			inv:add_item ("storage", orgstack)

			return false
		end

		minetest.set_node (pos, { name = stack:get_name (), param1 = 0, param2 = param2 })

		if stack and def and def.after_place_node then
			local result, msg = pcall (def.after_place_node, pos, nil, stack, pointed_thing)

			if not result then
				if utils.settings.alert_handler_errors then
					minetest.log ("error", "after_place_node handler for "..stack:get_name ().." crashed - "..msg)
				end
			end
		end

		if def and  def.sounds and def.sounds.place then
			pcall (minetest.sound_play, def.sounds.place, { pos = pos })
		end
	end

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

	local node = utils.get_far_node (pos)

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
		local stack = ItemStack (item)

		if not stack then
			return false
		end

		stack:set_count (1)

		if not inv:contains_item ("storage", stack, false) then
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

	local node = utils.get_far_node (pos)

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
		local stack = ItemStack (item)

		if not stack then
			return false
		end

		stack:set_count (1)

		if not iinv:contains_item ("main", stack, false) then
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



function utils.robot_put_stack (robot_pos, side, item)
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

	local node = utils.get_far_node (pos)

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
		local stack = ItemStack (item)

		if not stack then
			return false
		end

		local stack_count = get_total_inventory_item (stack:get_name (), inv, "storage")
		local stack_max = get_max_inventory_fit (stack:get_name (), iinv, "main")
		local slots = inv:get_size ("storage")

		if not slots or stack_max < 1 or stack_count < 1 then
			return false
		end

		if stack_count > stack_max then
			stack_count = stack_max
		end

		stack:set_count (stack_count)

		iinv:add_item("main", stack)
		inv:remove_item ("storage", stack)
	end

	meta:set_int ("delay_counter",
		math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))

	return true
end



function utils.robot_pull_stack (robot_pos, side, item)
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

	local node = utils.get_far_node (pos)

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
		local stack = ItemStack (item)

		if not stack then
			return false
		end

		local stack_count = get_total_inventory_item (stack:get_name (), iinv, "main")
		local stack_max = get_max_inventory_fit (stack:get_name (), inv, "storage")
		local slots = iinv:get_size ("main")

		if not slots or stack_max < 1 or stack_count < 1 then
			return false
		end

		if stack_count > stack_max then
			stack_count = stack_max
		end

		stack:set_count (stack_count)

		inv:add_item("storage", stack)
		iinv:remove_item ("main", stack)
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
				if type (recipes[r].items[i]) == "string" then
					local stack = substitute_group (recipes[r].items[i], inv)

					if stack then
						if items[stack:get_name ()] then
							items[stack:get_name ()] = items[stack:get_name ()] + stack:get_count ()
						else
							items[stack:get_name ()] = stack:get_count ()
						end
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
			local node = utils.get_far_node (pos)

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
	local meta = minetest.get_meta (robot_pos)
	if not meta then
		return false
	end

	local inv = meta:get_inventory ()
	if not inv then
		return false
	end

	if item then
		local stack = ItemStack (item)

		if not stack then
			return false
		end

		stack:set_count (1)

		if not inv:contains_item ("storage", stack, false) then
			return false
		end

		inv:remove_item ("storage", stack)

		if drop then
			utils.item_drop (stack, nil, robot_pos)
		else
			utils.on_destroy (stack)
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
					utils.item_drop (stack, nil, robot_pos)
				else
					utils.on_destroy (stack)
				end
			end
		end

	end

	meta:set_int ("delay_counter",
		math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))

	return true
end



function utils.robot_remove_stack (robot_pos, item, drop)
	local meta = minetest.get_meta (robot_pos)
	if not meta then
		return false
	end

	local inv = meta:get_inventory ()
	if not inv then
		return false
	end

	if item then
		local stack = ItemStack (item)
		if not stack then
			return false
		end

		local max_stack = get_max_stack (stack:get_name ())
		local stack_count = get_total_inventory_item (stack:get_name (), inv, "storage")

		if stack_count < 1 or max_stack < 1 then
			return false
		end

		if stack_count > max_stack then
			stack_count = max_stack
		end

		stack:set_count (stack_count)

		inv:remove_item ("storage", stack)

		if drop then
			utils.item_drop (stack, nil, robot_pos)
		else
			utils.on_destroy (stack)
		end
	end

	meta:set_int ("delay_counter",
		math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))

	return true
end



function utils.robot_chat (robot_pos, message)
	local meta = minetest.get_meta (robot_pos)

	if meta then
		local owner = meta:get_string ("owner")

		if not owner or owner == "" then
			if utils.settings.public_chat then
				minetest.chat_send_all (tostring (message or ""))
			end
		else
			minetest.chat_send_player (owner, tostring (message or ""))
		end

		meta:set_int ("delay_counter",
			math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))

		return true
	end

	return false
end



--
