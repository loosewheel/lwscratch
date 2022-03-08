local utils = ...
local S = utils.S



local function on_construct (pos)
	local meta = minetest.get_meta (pos)

	meta:set_int ("running", 0)
end



local function on_destruct (pos)
	local meta = minetest.get_meta (pos)

	if meta then
		local id = meta:get_int ("lwscratch_id")

		if id > 0 then
			if meta:get_int ("persists") == 1 then
				minetest.forceload_free_block (pos, false)
			end

			utils.remove_robot_from_list (id)
		end
	end
end



local function on_receive_fields (pos, formname, fields, sender)
	if not utils.can_interact_with_node (pos, sender) then
		return
	end

	if fields.setname then
		local meta = minetest.get_meta (pos)

		if meta then
			meta:set_string ("name", fields.name)
			meta:set_string ("infotext", fields.name)

			if fields.name:len () > 0 then
				meta:set_string ("description", fields.name)
			else
				meta:set_string ("description", S("Scratch ")..tostring (meta:get_int ("lwscratch_id")))
			end
		end

	elseif fields.set_value then
		local meta = minetest.get_meta (pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv then
				local stack = inv:get_stack ("value", 1)

				if stack then
					local imeta = stack:get_meta ()

					if imeta then
						if utils.is_value_item (stack:get_name ()) or
							utils.is_action_value_item (stack:get_name ()) or
							utils.is_condition_value_item (stack:get_name ()) then

							imeta:set_string ("value", fields.number_value)
							imeta:set_string ("description", fields.number_value)
							inv:set_stack ("value", 1, stack)
						end
					end
				end
			end
		end

	elseif fields.persists then
		local meta = minetest.get_meta (pos)

		if meta then
			if meta:get_int ("persists") == 1 then
				minetest.forceload_free_block (pos, false)

				meta:set_int ("persists", 0)
			else
				minetest.forceload_block (pos, false)

				meta:set_int ("persists", 1)
			end

			meta:set_string ("formspec", utils.get_robot_formspec (pos))
		end

	elseif fields.power then
		local meta = minetest.get_meta (pos)

		if meta then
			if meta:get_int ("running") == 1 then
				utils.robot_stop (pos)
			else
				utils.robot_run (pos)
			end

			meta:set_string ("formspec", utils.get_robot_formspec (pos))
		end

	elseif fields.clear_program then
		local meta = minetest.get_meta (pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv then
				for s = 1, utils.program_inv_size do
					local stack = inv:get_stack ("program", s)

					if stack and not stack:is_empty () then
						utils.on_destroy (stack)
					end

					inv:set_stack ("program", s, nil)
				end
			end
		end

	end
end



local function preserve_metadata (pos, oldnode, oldmeta, drops)
	if #drops > 0 and drops[1]:get_name ():sub (1, 15) == "lwscratch:robot" then
		local meta = minetest.get_meta (pos)
		local id = meta:get_int ("lwscratch_id")

		if id > 0 then
			local imeta = drops[1]:get_meta ()
			local inv = meta:get_inventory ()

			if imeta and inv then
				local program = minetest.serialize (utils.encode_program (inv))
				local description = meta:get_string ("name")

				if description:len () < 1 then
					description = S("Scratch ")..tostring (id)
				end

				imeta:set_int ("lwscratch_id", id)
				imeta:set_string ("name", meta:get_string ("name"))
				imeta:set_string ("infotext", meta:get_string ("infotext"))
				imeta:set_string ("description", description)
				imeta:set_string ("owner", meta:get_string ("owner"))
				imeta:set_int ("persists", meta:get_int ("persists"))

				if program:len () <= 60000 then
					imeta:set_string ("program", program)
				end
			end
		end
	end
end



local function after_place_node (pos, placer, itemstack, pointed_thing)
	local id = 0
	local name = ""
	local infotext = ""
	local owner = ""
	local persists = 0
	local unique = false
	local meta = minetest.get_meta (pos)
	local program = nil

	if meta then
		local imeta = itemstack:get_meta ()

		if imeta then
			id = imeta:get_int ("lwscratch_id")

			if id > 0 then
				name = imeta:get_string ("name")
				infotext = imeta:get_string ("infotext")
				owner = imeta:get_string ("owner")
				persists = imeta:get_int ("persists")
				program = minetest.deserialize (imeta:get_string ("program"))

				if type (program) ~= "table" then
					program = nil
				end

				unique = true
			else
				id = math.random (1000000)
			end
		end

		meta:set_int ("lwscratch_id", id)
		meta:set_string ("name", name)
		meta:set_string ("infotext", infotext)
		meta:set_string ("owner", owner)
		meta:set_int ("persists", persists)
		meta:set_int ("running", 0)
		meta:set_int ("delay_counter", 0)

		meta:set_string ("formspec", utils.get_robot_formspec (pos))

		local inv = meta:get_inventory ()

		inv:set_size ("value", 1)
		inv:set_width ("value", 1)
		inv:set_size ("program", utils.program_inv_size)
		inv:set_width ("program", 10)
		inv:set_size ("commands", utils.commands_inv_size)
		inv:set_width ("commands", 8)
		inv:set_size ("storage", 32)
		inv:set_width ("storage", 8)

		utils.prep_inventory (inv, nil)
		utils.dencode_program (inv, program)
	end

	if persists == 1 then
		minetest.forceload_block (pos, false)
	end

	utils.add_robot_to_list (id, pos)

	if unique and placer and placer:is_player () and
		minetest.is_creative_enabled (placer:get_player_name ()) then

		-- no duplicates in creative mode
		itemstack:clear ()

		return true

	elseif not unique and placer and placer:is_player () then
		minetest.show_formspec (placer:get_player_name (),
										"lwscratch:robot_set_owner",
										utils.set_owner_formspec (id))
	end

	-- If return true no item is taken from itemstack
	return false
end



local function on_timer (pos, elapsed)
	local meta = minetest.get_meta (pos)

	if meta and meta:get_int ("lwscratch_id") > 0 then
		local delay = meta:get_int ("delay_counter")

		if delay > 0 then
			meta:set_int ("delay_counter", delay - 1)

		else
			local program = utils.program:new ()

			program:deserialize (pos)

			if not program:run () then
				utils.robot_stop (program.pos)
				meta:set_string ("formspec", utils.get_robot_formspec (program.pos))

				return false
			end
		end
	end

	-- return true to run the timer for another cycle with the same timeout
	return true
end



local function can_dig (pos, player)
	if not utils.can_interact_with_node (pos, player) then
		return false
	end

	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			local program = minetest.serialize (utils.encode_program (inv))

			if program:len () > 60000 then
				if player and player:is_player () then
					minetest.chat_send_player (player:get_player_name (),
														minetest.colorize ("#ff4040",
																				 "Program too large to remember!"))

					return false
				end
			end


			if not inv:is_empty ("storage") then
				return false
			end
		end

	end

	return true
end



local function allow_metadata_inventory_move (pos, from_list, from_index, to_list, to_index, count, player)
	if not utils.can_interact_with_node (pos, player) then
		return 0
	end

	if to_list == "value" then
		local meta = minetest.get_meta (pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv then
				local stack = inv:get_stack (from_list, from_index)

				if stack then
					if utils.is_value_item (stack:get_name ()) or
						utils.is_action_value_item (stack:get_name ()) or
						utils.is_condition_value_item (stack:get_name ()) then

						return 1
					end
				end
			end
		end

		return 0
	end


	if from_list == "program" then
		if to_list == "commands" or to_list == "program" then
			return 1
		end

	elseif from_list == "value" then
		if to_list == "commands" or to_list == "program" then
			return 1
		end

	elseif from_list == "commands" then
		if to_list == "program" then
			local meta = minetest.get_meta (pos)

			if meta then
				local inv = meta:get_inventory ()

				if inv then
					local stack = inv:get_stack (from_list, from_index)

					if stack and not stack:is_empty () then
						local base = (math.floor ((to_index - 1) / 10) * 10) + 1

						if stack:get_name () == "lwscratch:cmd_line_insert" then
							for s = utils.program_inv_size - 10, base, -1 do
								inv:set_stack (to_list, s + 10, inv:get_stack (to_list, s))
								inv:set_stack (to_list, s, nil)
							end

							return 0

						elseif stack:get_name () == "lwscratch:cmd_line_remove" then
							for s = base, utils.program_inv_size - 10 do
								inv:set_stack (to_list, s, inv:get_stack (to_list, s + 10))
								inv:set_stack (to_list, s + 10, nil)
							end

							return 0

						end
					end
				end
			end

			return 1
		end

	elseif from_list == "storage" then
		if to_list == "main" or to_list == "storage" then
			return utils.settings.default_stack_max

		elseif to_list == "program" then
			local meta = minetest.get_meta (pos)

			if meta then
				local inv = meta:get_inventory ()

				if inv then
					local stack = inv:get_stack (from_list, from_index)

					if stack and not stack:is_empty () then
						stack:set_count (1)

						inv:set_stack (to_list, to_index, stack)
					end
				end
			end

		end

	elseif from_list == "main" then
		if to_list == "storage" then
			return utils.settings.default_stack_max

		elseif to_list == "program" then
			local meta = minetest.get_meta (pos)

			if meta then
				local inv = meta:get_inventory ()

				if inv then
					local stack = inv:get_stack (from_list, from_index)

					if stack and not stack:is_empty () then
						stack:set_count (1)

						inv:set_stack (to_list, to_index, stack)
					end
				end
			end

		end

	end

	return 0
end



local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if not utils.can_interact_with_node (pos, player) then
		return 0
	end

	if listname == "program" then
		if stack and not stack:is_empty () then
			if utils.is_command_item (stack:get_name ()) then
				return 1

			else
				local meta = minetest.get_meta (pos)

				if meta then
					local inv = meta:get_inventory ()

					if stack and not stack:is_empty () then
						local copy = ItemStack (stack)

						if copy then
							copy:set_count (1)

							inv:set_stack (listname, index, copy)
						end
					end
				end

			end
		end

	elseif listname == "commands" then
		if stack and not stack:is_empty () and
			utils.is_command_item (stack:get_name ()) then

			return 1
		end

	elseif listname == "storage" then
		if stack and not stack:is_empty () and
			utils.is_command_item (stack:get_name ()) then

			return 0
		end

		return utils.settings.default_stack_max
	end

	return 0
end



local function allow_metadata_inventory_take (pos, listname, index, stack, player)
	if not utils.can_interact_with_node (pos, player) then
		return 0
	end

	if listname == "program" or listname == "commands" then

		return 0
	end

	return utils.settings.default_stack_max
end



local function on_metadata_inventory_put (pos, listname, index, stack, player)
end



local function on_metadata_inventory_take (pos, listname, index, stack, player)
end



local function on_metadata_inventory_move (pos, from_list, from_index, to_list, to_index, count, player)
	if (from_list == "program" and to_list == "commands") or
		(from_list == "commands" and to_list == "program") or
		(from_list == "value" and to_list == "commands") or
		(from_list == "commands" and to_list == "value") then

		local meta = minetest.get_meta (pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv then
				utils.prep_inventory (inv, nil)
			end
		end
	end
end



local function on_punch_robot (pos, node, puncher, pointed_thing)
	if not utils.can_interact_with_node (pos, puncher) then
		return
	end

	if puncher and puncher:is_player () and
		puncher:get_player_control ().sneak then

		local meta = minetest.get_meta (pos)

		if meta and meta:get_int ("running") == 1 then
			local id = meta:get_int ("lwscratch_id")

			if id > 0 then
				utils.add_robot_to_list (id, pos)

				minetest.show_formspec (puncher:get_player_name (),
												"lwscratch:robot_stop",
												utils.robot_stop_formspec (id))

			end
		end
	end
end



local function on_rightclick (pos, node, clicker, itemstack, pointed_thing)
	if not utils.can_interact_with_node (pos, clicker) then
		if clicker and clicker:is_player () then
			local owner = "<unknown>"
			local meta = minetest.get_meta (pos)

			if meta then
				owner = meta:get_string ("owner")
			end

			local spec =
			"formspec_version[3]"..
			"size[8.0,4.0,false]"..
			"label[1.0,1.0;Owned by "..minetest.formspec_escape (owner).."]"..
			"button_exit[3.0,2.0;2.0,1.0;close;Close]"

			minetest.show_formspec (clicker:get_player_name (),
											"lwscratch:robot_privately_owned",
											spec)
		end
	end

	return itemstack
end



minetest.register_node ("lwscratch:robot", {
   description = S("Itch"),
   tiles = { "lw_itch_top.png", "lw_itch_bottom.png", "lw_itch_left.png",
				 "lw_itch_right.png", "lw_itch_back.png", "lw_itch_face.png" },
   drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			 -- left_foot
			{ -0.3125, -0.5, -0.3125, -0.0625, -0.375, 0.3125 },
			-- right_foot
			{ 0.0625, -0.5, -0.3125, 0.3125, -0.375, 0.3125 },
			-- left_leg
			{ -0.25, -0.375, 0, -0.125, -0.3125, 0.125 },
			-- right_left
			{ 0.125, -0.375, 0, 0.25, -0.3125, 0.125 },
			-- body
			{ -0.375, -0.3125, -0.375, 0.375, 0.1875, 0.375 },
			-- upper_arm
			{ -0.5, -0.1875, -0.0625, 0.5, 0.1875, 0.125 },
			-- lower_arm
			{ -0.5, -0.1875, -0.25, 0.5, 0, 0.125 },
			-- neck
			{ -0.125, 0.1875, -0.0625, 0.125, 0.25, 0.1875 },
			-- head
			{ -0.3125, 0.25, -0.3125, 0.3125, 0.5, 0.3125 },
		}
	},
   selection_box = {
      type = "fixed",
      fixed = { -0.5, -0.5, -0.375, 0.5, 0.5, 0.375 }
   },
   collision_box = {
      type = "fixed",
      fixed = { -0.5, -0.5, -0.375, 0.5, 0.5, 0.375 }
   },
	groups = { cracky = 2, oddly_breakable_by_hand = 2 },
	sounds = {
		footstep = { name = "lwscratch_footstep", gain = 0.3 },
		dug = { name = "lwscratch_dug", gain = 1.0 },
		place = { name = "lwscratch_place", gain = 1.0 }
	},
	paramtype = "light",
	param1 = 0,
	paramtype2 = "facedir",
	param2 = 1,
   sunlight_propagates = true,
	drop = "lwscratch:robot",

   on_construct = on_construct,
   on_destruct = on_destruct,
	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	on_timer = on_timer,
	can_dig = can_dig,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_metadata_inventory_move = on_metadata_inventory_move,
	on_punch = on_punch_robot,
	on_rightclick = on_rightclick,
})



minetest.register_node ("lwscratch:robot_on", {
   description = S("Itch"),
   tiles = { "lw_itch_top.png", "lw_itch_bottom.png", "lw_itch_left.png",
				 "lw_itch_right.png", "lw_itch_back.png", "lw_itch_face_on.png" },
   drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			 -- left_foot
			{ -0.3125, -0.5, -0.3125, -0.0625, -0.375, 0.3125 },
			-- right_foot
			{ 0.0625, -0.5, -0.3125, 0.3125, -0.375, 0.3125 },
			-- left_leg
			{ -0.25, -0.375, 0, -0.125, -0.3125, 0.125 },
			-- right_left
			{ 0.125, -0.375, 0, 0.25, -0.3125, 0.125 },
			-- body
			{ -0.375, -0.3125, -0.375, 0.375, 0.1875, 0.375 },
			-- upper_arm
			{ -0.5, -0.1875, -0.0625, 0.5, 0.1875, 0.125 },
			-- lower_arm
			{ -0.5, -0.1875, -0.25, 0.5, 0, 0.125 },
			-- neck
			{ -0.125, 0.1875, -0.0625, 0.125, 0.25, 0.1875 },
			-- head
			{ -0.3125, 0.25, -0.3125, 0.3125, 0.5, 0.3125 },
		}
	},
   selection_box = {
      type = "fixed",
      fixed = { -0.5, -0.5, -0.375, 0.5, 0.5, 0.375 }
   },
   collision_box = {
      type = "fixed",
      fixed = { -0.5, -0.5, -0.375, 0.5, 0.5, 0.375 }
   },
	groups = { cracky = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1 },
	sounds = {
		footstep = { name = "lwscratch_footstep", gain = 0.3 },
		dug = { name = "lwscratch_dug", gain = 1.0 },
		place = { name = "lwscratch_place", gain = 1.0 }
	},
	paramtype = "light",
	param1 = 0,
	paramtype2 = "facedir",
	param2 = 1,
   sunlight_propagates = true,
	drop = "lwscratch:robot",

   on_construct = on_construct,
   on_destruct = on_destruct,
	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	on_timer = on_timer,
	can_dig = can_dig,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_metadata_inventory_move = on_metadata_inventory_move,
	on_punch = on_punch_robot,
	on_rightclick = on_rightclick,
})



minetest.register_on_player_receive_fields (function (player, formname, fields)
   if formname == "lwscratch:robot_stop" and
		player and player:is_player () then

		for k, v in pairs (fields) do
			if k:sub (1, 5) == "stop_" then
				local id = tonumber (k:sub (6, -1)) or 0

				if id > 0 then
					utils.stop_robot_by_id (id)

					return nil
				end
			end
		end

		return nil
	end
end)



minetest.register_on_player_receive_fields (function (player, formname, fields)
   if formname == "lwscratch:robot_set_owner" and
		player and player:is_player () then

		for k, v in pairs (fields) do
			if k:sub (1, 8) == "private_" then
				local id = tonumber (k:sub (9, -1)) or 0

				if id > 0 then
					local pos = utils.get_robot_pos (id)

					if pos then
						local meta = minetest.get_meta (pos)

						if meta then
							meta:set_string ("owner", player:get_player_name ())

							return nil
						end
					end
				end
			end
		end

		return nil
	end
end)



--
