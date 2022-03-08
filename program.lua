local utils = ...



local function cmdstr (cmd)
	if not cmd or not cmd.command then
		return ""
	end

	return cmd.command
end



------------------------------------------------------------------------



local function check_condition_detect (program)
	local cmd = program:next_cell (false)

	if utils.is_inventory_item_or_blank (cmdstr (cmd)) then
		return true
	end

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	return false, "item, blank, variable or text must follow detect"
end



local function check_condition_fits (program)
	local cmd = program:next_cell (false)

	if utils.is_inventory_item_or_blank (cmdstr (cmd)) then
		return true
	end

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	return false, "item, blank, variable or text must follow item fits"
end



local function check_condition_contains (program)
	local cmd = program:next_cell (false)

	if utils.is_inventory_item_or_blank (cmdstr (cmd)) then
		return true
	end

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	return false, "item, blank, variable or text must follow contains item"
end



local function check_condition_counter (program)
	local cmd = program:next_cell (false)

	if utils.is_number_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then
		return true
	end

	return false, "number or variable must follow counter"
end



local function check_condition_counter_even (program)
	return true
end



local function check_condition_counter_odd (program)
	return true
end



local function check_condition_variable (program)
	local cmd = program:next_cell (false)

	if cmd.command == "lwscratch:cmd_cond_value_less" then
		if utils.is_number_item (cmdstr (cmd)) or
			utils.is_variable_item (cmdstr (cmd)) then

			return true
		end

		return false, "number or variable must follow variable less"

	elseif cmd.command == "lwscratch:cmd_cond_value_greater" then
		if utils.is_number_item (cmdstr (cmd)) or
			utils.is_variable_item (cmdstr (cmd)) then

			return true
		end

		return false, "number or variable must follow variable greater"

	else -- assume lwscratch:cmd_cond_value_equal
		if utils.is_value_item (cmdstr (cmd)) or
			utils.is_name_item (cmdstr (cmd)) or
			utils.is_inventory_item (cmdstr (cmd)) then

			return true
		end

		return false, "name, number, text, variable or item must follow variable equals"

	end
end




local function check_condition_variable_even (program)
	return true
end



local function check_condition_variable_odd (program)
	return true
end



local function check_condition_number (program)
	return false, "out of place number"
end



local function check_condition_text (program)
	return false, "out of place text"
end



local function check_condition_variable_value (program)
	return false, "out of place variable"
end



local function check_condition_name (program)
	return false, "out of place name"
end



local check_condition_table =
{
	["lwscratch:cmd_cond_detect_front"] = check_condition_detect,
	["lwscratch:cmd_cond_detect_front_down"] = check_condition_detect,
	["lwscratch:cmd_cond_detect_front_up"] = check_condition_detect,
	["lwscratch:cmd_cond_detect_back"] = check_condition_detect,
	["lwscratch:cmd_cond_detect_back_down"] = check_condition_detect,
	["lwscratch:cmd_cond_detect_back_up"] = check_condition_detect,
	["lwscratch:cmd_cond_detect_down"] = check_condition_detect,
	["lwscratch:cmd_cond_detect_up"] = check_condition_detect,
	["lwscratch:cmd_cond_fits"] = check_condition_fits,
	["lwscratch:cmd_cond_contains"] = check_condition_contains,
	["lwscratch:cmd_cond_counter_equal"] = check_condition_counter,
	["lwscratch:cmd_cond_counter_greater"] = check_condition_counter,
	["lwscratch:cmd_cond_counter_less"] = check_condition_counter,
	["lwscratch:cmd_cond_counter_even"] = check_condition_counter_even,
	["lwscratch:cmd_cond_counter_odd"] = check_condition_counter_odd,
	["lwscratch:cmd_cond_value_equal"] = check_condition_variable,
	["lwscratch:cmd_cond_value_greater"] = check_condition_variable,
	["lwscratch:cmd_cond_value_less"] = check_condition_variable,
	["lwscratch:cmd_cond_value_even"] = check_condition_variable_even,
	["lwscratch:cmd_cond_value_odd"] = check_condition_variable_odd,
	["lwscratch:cmd_value_number"] = check_condition_number,
	["lwscratch:cmd_value_text"] = check_condition_text,
	["lwscratch:cmd_value_variable"] = check_condition_variable_value,
	["lwscratch:cmd_name_front"] = check_condition_name,
	["lwscratch:cmd_name_front_down"] = check_condition_name,
	["lwscratch:cmd_name_front_up"] = check_condition_name,
	["lwscratch:cmd_name_back"] = check_condition_name,
	["lwscratch:cmd_name_back_down"] = check_condition_name,
	["lwscratch:cmd_name_back_up"] = check_condition_name,
	["lwscratch:cmd_name_down"] = check_condition_name,
	["lwscratch:cmd_name_up"] = check_condition_name,
}



local function check_condition (program, last_condition)
	local must_follow = true
	local can_and_or = false

	while true do
		local cmd = program:next_cell (false)

		if not utils.is_condition_item (cmdstr (cmd)) and
			not utils.is_operator_item (cmdstr (cmd)) then

			if must_follow then
				return false, "condition must follow "..last_condition
			end

			while cmd do
				if cmdstr (cmd) ~= "" then
					return false, "out of place command/item"
				end

				cmd = program:next_cell (false)
			end


			return true
		end

		if cmd.command == "lwscratch:cmd_op_not" then
			must_follow = true
			can_and_or = false
			last_condition = "not"

		elseif cmd.command == "lwscratch:cmd_op_and" then
			if not can_and_or then
				return false, "out of place and"
			end

			must_follow = true
			can_and_or = false
			last_condition = "and"

		elseif cmd.command == "lwscratch:cmd_op_or" then
			if not can_and_or then
				return false, "out of place or"
			end

			must_follow = true
			can_and_or = false
			last_condition = "or"

		else
			local result, msg = check_condition_table[cmd.command] (program)

			if not result then
				return result, msg
			end

			must_follow = false
			can_and_or = true
		end
	end
end



local function check_dig (program)
	return true
end



local function check_move (program)
	return true
end



local function check_turn (program)
	return true
end



local function check_pull (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	if utils.is_inventory_item_or_blank (cmdstr (cmd)) then
		return true
	end

	return false, "item, blank, variable or text must follow pull"
end



local function check_put (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	if utils.is_inventory_item_or_blank (cmdstr (cmd)) then

		return true
	end

	return false, "item, blank, variable or text must follow put"
end



local function check_pull_stack (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) or
		utils.is_inventory_item (cmdstr (cmd)) then

		return true
	end

	return false, "item, variable or text must follow pull stack"
end



local function check_put_stack (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) or
		utils.is_inventory_item (cmdstr (cmd)) then

		return true
	end

	return false, "item, variable or text must follow put stack"
end



local function check_drop (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	if utils.is_inventory_item_or_blank (cmdstr (cmd)) then

		return true
	end

	return false, "item, blank, variable or text must follow drop"
end



local function check_trash (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	if utils.is_inventory_item_or_blank (cmdstr (cmd)) then

		return true
	end

	return false, "item, blank, variable or text must follow trash"
end



local function check_drop_stack (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) or
		utils.is_inventory_item (cmdstr (cmd)) then

		return true
	end

	return false, "item, variable or text must follow drop stack"
end



local function check_trash_stack (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) or
		utils.is_inventory_item (cmdstr (cmd)) then

		return true
	end

	return false, "item, variable or text must follow trash stack"
end



local function check_place (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	if utils.is_inventory_item (cmd.command) then
		return true
	end

	return false, "item, variable or text must follow place"
end



local function check_chat (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	return false, "variable or text must follow chat"
end



local function check_craft (program)
	local cmd = program:next_cell (false)

	if utils.is_text_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	if utils.is_inventory_item (cmdstr (cmd)) then
		return true
	end

	return false, "item, variable or text must follow craft"
end



--local function check_detect (program)
	--return false, "out of place detect"
--end



--local function check_fits (program)
	--return false, "out of place item fits"
--end



--local function check_contains (program)
	--return false, "out of place contain item"
--end



--local function check_counter (program)
	--return false, "out of place counter"
--end



local function check_number (program)
	return false, "out of place number"
end



local function check_text (program)
	return false, "out of place text"
end



local function check_variable (program)
	return false, "out of place variable"
end



local function check_name (program)
	return false, "out of place name"
end



local function check_or (program)
	return false, "out of place or"
end



local function check_not (program)
	return false, "out of place not"
end



local function check_and (program)
	return false, "out of place and"
end



local function check_stop (program)
	return true
end



local function check_wait (program)
	local cmd = program:next_cell (false)

	if utils.is_number_item (cmdstr (cmd)) or
		utils.is_variable_item (cmdstr (cmd)) then

		return true
	end

	return false, "number or variable must follow wait"
end



local function check_action_value_assign (program)
	local cmd = program:next_cell (false)

	if utils.is_value_item (cmdstr (cmd)) or
		utils.is_name_item (cmdstr (cmd)) or
		utils.is_inventory_item (cmdstr (cmd)) then

		return true
	end

	return false, "name, number, text, variable or item must follow variable action assign"
end



local function check_action_value_plus (program)
	local cmd = program:next_cell (false)

	if utils.is_value_item (cmdstr (cmd)) or
		utils.is_name_item (cmdstr (cmd)) then

		return true
	end

	return false, "name, number, text or variable must follow variable action plus"
end



local function check_action_value_no_text (program)
	local cmd = program:next_cell (false)

	if utils.is_value_item (cmdstr (cmd)) and
		not utils.is_text_item (cmdstr (cmd)) then

		return true
	end

	return false, "number or variable must follow variable action"
end



local function check_if (program)
	return check_condition (program, "if")
end



local function check_loop (program)
	return check_condition (program, "loop")
end



local check_table =
{
	["lwscratch:cmd_act_dig_front"] = check_dig,
	["lwscratch:cmd_act_dig_front_down"] = check_dig,
	["lwscratch:cmd_act_dig_front_up"] = check_dig,
	["lwscratch:cmd_act_dig_back"] = check_dig,
	["lwscratch:cmd_act_dig_back_down"] = check_dig,
	["lwscratch:cmd_act_dig_back_up"] = check_dig,
	["lwscratch:cmd_act_dig_down"] = check_dig,
	["lwscratch:cmd_act_dig_up"] = check_dig,
	["lwscratch:cmd_act_move_back"] = check_move,
	["lwscratch:cmd_act_move_down"] = check_move,
	["lwscratch:cmd_act_move_front"] = check_move,
	["lwscratch:cmd_act_move_up"] = check_move,
	["lwscratch:cmd_act_turn_left"] = check_turn,
	["lwscratch:cmd_act_turn_right"] = check_turn,
	["lwscratch:cmd_act_pull"] = check_pull,
	["lwscratch:cmd_act_put"] = check_put,
	["lwscratch:cmd_act_pull_stack"] = check_pull_stack,
	["lwscratch:cmd_act_put_stack"] = check_put_stack,
	["lwscratch:cmd_act_drop"] = check_drop,
	["lwscratch:cmd_act_trash"] = check_trash,
	["lwscratch:cmd_act_drop_stack"] = check_drop_stack,
	["lwscratch:cmd_act_trash_stack"] = check_trash_stack,
	["lwscratch:cmd_act_place_front"] = check_place,
	["lwscratch:cmd_act_place_front_down"] = check_place,
	["lwscratch:cmd_act_place_front_up"] = check_place,
	["lwscratch:cmd_act_place_back"] = check_place,
	["lwscratch:cmd_act_place_back_down"] = check_place,
	["lwscratch:cmd_act_place_back_up"] = check_place,
	["lwscratch:cmd_act_place_down"] = check_place,
	["lwscratch:cmd_act_place_up"] = check_place,
	["lwscratch:cmd_act_craft"] = check_craft,
	["lwscratch:cmd_value_number"] = check_number,
	["lwscratch:cmd_value_text"] = check_text,
	["lwscratch:cmd_value_variable"] = check_variable,
	["lwscratch:cmd_name_front"] = check_name,
	["lwscratch:cmd_name_front_down"] = check_name,
	["lwscratch:cmd_name_front_up"] = check_name,
	["lwscratch:cmd_name_back"] = check_name,
	["lwscratch:cmd_name_back_down"] = check_name,
	["lwscratch:cmd_name_back_up"] = check_name,
	["lwscratch:cmd_name_down"] = check_name,
	["lwscratch:cmd_name_up"] = check_name,
	["lwscratch:cmd_act_stop"] = check_stop,
	["lwscratch:cmd_act_wait"] = check_wait,
	["lwscratch:cmd_act_chat"] = check_chat,
	["lwscratch:cmd_act_value_assign"] = check_action_value_assign,
	["lwscratch:cmd_act_value_plus"] = check_action_value_plus,
	["lwscratch:cmd_act_value_minus"] = check_action_value_no_text,
	["lwscratch:cmd_act_value_multiply"] = check_action_value_no_text,
	["lwscratch:cmd_act_value_divide"] = check_action_value_no_text,
	["lwscratch:cmd_stat_if"] = check_if,
	["lwscratch:cmd_stat_loop"] = check_loop,
	["lwscratch:cmd_op_or"] = check_or,
	["lwscratch:cmd_op_not"] = check_not,
	["lwscratch:cmd_op_and"] = check_and,

}



------------------------------------------------------------------------



local function run_condition_detect (program, robot_pos)
	local cmd = program:cur_command ()
	local item = program:next_cell ()
	local side = "front" -- assume lwscratch:cmd_cond_detect_front

	if cmd.command == "lwscratch:cmd_cond_detect_back" then
		side = "back"
	elseif cmd.command == "lwscratch:cmd_cond_detect_back_down" then
		side = "back down"
	elseif cmd.command == "lwscratch:cmd_cond_detect_back_up" then
		side = "back up"
	elseif cmd.command == "lwscratch:cmd_cond_detect_down" then
		side = "down"
	elseif cmd.command == "lwscratch:cmd_cond_detect_up" then
		side = "up"
	elseif cmd.command == "lwscratch:cmd_cond_detect_front_down" then
		side = "front down"
	elseif cmd.command == "lwscratch:cmd_cond_detect_front_up" then
		side = "front up"
	end

	if cmdstr (item) == "" then
		item = nil
	elseif utils.is_value_item (item.command) then
		item = program:get_value (item)
	else
		item = item.command
	end

	local node = utils.robot_detect (robot_pos, side)

	if not item then
		return node ~= nil and node ~= "air"
	end

	return node == item
end



local function run_condition_fits (program, robot_pos)
	local item = program:next_cell ()

	if cmdstr (item) == "" then
		item = nil
	elseif utils.is_value_item (item.command) then
		item = program:get_value (item)
	else
		item = item.command
	end

	return utils.robot_room_for (robot_pos, item)
end



local function run_condition_contains (program, robot_pos)
	local item = program:next_cell ()

	if cmdstr (item) == "" then
		item = nil
	elseif utils.is_value_item (item.command) then
		item = program:get_value (item)
	else
		item = item.command
	end

	return utils.robot_contains (robot_pos, item)
end



local function run_condition_counter (program, robot_pos)
	local cmd = program:cur_command ()
	local value = tonumber (program:get_value (program:next_cell ()) or 0) or 0

	if cmd.command == "lwscratch:cmd_cond_counter_less" then
		return program:loop_counter () < value

	elseif cmd.command == "lwscratch:cmd_cond_counter_greater" then
		return program:loop_counter () > value

	else -- assume lwscratch:cmd_cond_counter_equal
		return program:loop_counter () == value

	end
end



local function run_condition_counter_even (program, robot_pos)
	return (program:loop_counter () % 2) == 0
end



local function run_condition_counter_odd (program, robot_pos)
	return (program:loop_counter () % 2) == 1
end



local function run_condition_variable (program, robot_pos)
	local cmd = program:cur_command ()
	local value = program:next_cell ()
	local var = program:get_value (cmd)
	local val

	if utils.is_inventory_item (cmdstr (value)) then
		val = value.command
	else
		val = program:get_value (value)
	end

	if cmd.command == "lwscratch:cmd_cond_value_less" then
		val = tonumber (val or 0) or 0
		var = tonumber (var or 0) or 0

		return var < val

	elseif cmd.command == "lwscratch:cmd_cond_value_greater" then
		val = tonumber (val or 0) or 0
		var = tonumber (var or 0) or 0

		return var > val

	else -- assume lwscratch:cmd_cond_value_equal
		if utils.is_number_item (value) then
			var = tonumber (var or 0) or 0

			return var == value
		end

		return var == val
	end
end



local function run_condition_variable_even (program, robot_pos)
	local var = tonumber (program:get_value (program:cur_command ()) or 0) or 0

	return math.floor (var % 2) == 0
end



local function run_condition_variable_odd (program, robot_pos)
	local var = tonumber (program:get_value (program:cur_command ()) or 0) or 0

	return math.floor (var () % 2) == 1
end



local run_condition_table =
{
	["lwscratch:cmd_cond_detect_front"] = run_condition_detect,
	["lwscratch:cmd_cond_detect_front_down"] = run_condition_detect,
	["lwscratch:cmd_cond_detect_front_up"] = run_condition_detect,
	["lwscratch:cmd_cond_detect_back"] = run_condition_detect,
	["lwscratch:cmd_cond_detect_back_down"] = run_condition_detect,
	["lwscratch:cmd_cond_detect_back_up"] = run_condition_detect,
	["lwscratch:cmd_cond_detect_down"] = run_condition_detect,
	["lwscratch:cmd_cond_detect_up"] = run_condition_detect,
	["lwscratch:cmd_cond_fits"] = run_condition_fits,
	["lwscratch:cmd_cond_contains"] = run_condition_contains,
	["lwscratch:cmd_cond_counter_equal"] = run_condition_counter,
	["lwscratch:cmd_cond_counter_greater"] = run_condition_counter,
	["lwscratch:cmd_cond_counter_less"] = run_condition_counter,
	["lwscratch:cmd_cond_counter_even"] = run_condition_counter_even,
	["lwscratch:cmd_cond_counter_odd"] = run_condition_counter_odd,
	["lwscratch:cmd_cond_value_equal"] = run_condition_variable,
	["lwscratch:cmd_cond_value_greater"] = run_condition_variable,
	["lwscratch:cmd_cond_value_less"] = run_condition_variable,
	["lwscratch:cmd_cond_value_even"] = run_condition_variable_even,
	["lwscratch:cmd_cond_value_odd"] = run_condition_variable_odd,
}



local function run_condition (program, robot_pos)
	local result = false
	local not_next = false
	local or_next = false
	local and_next = false

	while true do
		local cmd = program:next_cell (true)

		if not utils.is_condition_item (cmdstr (cmd)) and
			not utils.is_operator_item (cmdstr (cmd)) then

			return result
		end

		program:next_cell (false)

		if cmd.command == "lwscratch:cmd_op_not" then
			not_next = true

		elseif cmd.command == "lwscratch:cmd_op_and" then
			and_next = true

		elseif cmd.command == "lwscratch:cmd_op_or" then
			or_next = true

		else
			local op_result = run_condition_table[cmd.command] (program, robot_pos)

			if not_next then
				op_result = not op_result
			end

			if or_next then
				result = result or op_result
			elseif and_next then
				result = result and op_result
			else
				result = op_result
			end

			not_next = false
			or_next = false
			and_next = false
		end
	end
end



local function get_node_name (command, robot_pos)
	local side = "front" -- assume lwscratch:cmd_name_front

	if command == "lwscratch:cmd_name_back" then
		side = "back"
	elseif command == "lwscratch:cmd_name_back_down" then
		side = "back down"
	elseif command == "lwscratch:cmd_name_back_up" then
		side = "back up"
	elseif command == "lwscratch:cmd_name_down" then
		side = "down"
	elseif command == "lwscratch:cmd_name_up" then
		side = "up"
	elseif command == "lwscratch:cmd_name_front_down" then
		side = "front down"
	elseif command == "lwscratch:cmd_name_front_up" then
		side = "front up"
	end

	return utils.robot_detect (robot_pos, side) or ""
end



local function run_dig (program, robot_pos)
	local cmd = program:cur_command ()
	local side = "front" -- assume lwscratch:cmd_act_dig_front

	if cmd.command == "lwscratch:cmd_act_dig_back" then
		side = "back"
	elseif cmd.command == "lwscratch:cmd_act_dig_back_down" then
		side = "back down"
	elseif cmd.command == "lwscratch:cmd_act_dig_back_up" then
		side = "back up"
	elseif cmd.command == "lwscratch:cmd_act_dig_down" then
		side = "down"
	elseif cmd.command == "lwscratch:cmd_act_dig_up" then
		side = "up"
	elseif cmd.command == "lwscratch:cmd_act_dig_front_down" then
		side = "front down"
	elseif cmd.command == "lwscratch:cmd_act_dig_front_up" then
		side = "front up"
	end

	utils.robot_dig (robot_pos, side)

	return true
end



local function run_move (program, robot_pos)
	local cmd = program:cur_command ()
	local side = "front" -- assume lwscratch:cmd_act_move_front

	if cmd.command == "lwscratch:cmd_act_move_back" then
		side = "back"
	elseif cmd.command == "lwscratch:cmd_act_move_down" then
		side = "down"
	elseif cmd.command == "lwscratch:cmd_act_move_up" then
		side = "up"
	end

	local result, pos = utils.robot_move (robot_pos, side)

	if result then
		program.pos = pos
		utils.add_robot_to_list (program.id, program.pos)
	end

	return true
end



local function run_turn (program, robot_pos)
	local cmd = program:cur_command ()
	local side = "left" -- assume lwscratch:cmd_act_turn_left

	if cmd.command == "lwscratch:cmd_act_turn_right" then
		side = "right"
	end

	utils.robot_turn (robot_pos, side)

	return true
end




local function run_pull (program, robot_pos)
	local item = program:next_cell ()

	if cmdstr (item) == "" then
		item = nil
	elseif utils.is_value_item (item.command) then
		item = tostring (program:get_value (item))
	elseif utils.is_inventory_item (item.command) then
		item = tostring (item.value)
	else
		item = item.command
	end

	utils.robot_pull (robot_pos, "front", item)

	return true
end



local function run_put (program, robot_pos)
	local item = program:next_cell ()

	if cmdstr (item) == "" then
		item = nil
	elseif utils.is_value_item (item.command) then
		item = tostring (program:get_value (item))
	elseif utils.is_inventory_item (item.command) then
		item = tostring (item.value)
	else
		item = item.command
	end

	utils.robot_put (robot_pos, "front", item)

	return true
end




local function run_pull_stack (program, robot_pos)
	local item = program:next_cell ()

	if utils.is_value_item (item.command) then
		item = tostring (program:get_value (item))
	elseif utils.is_inventory_item (item.command) then
		item = tostring (item.value)
	else
		item = item.command
	end

	utils.robot_pull_stack (robot_pos, "front", item)

	return true
end



local function run_put_stack (program, robot_pos)
	local item = program:next_cell ()

	if utils.is_value_item (item.command) then
		item = tostring (program:get_value (item))
	elseif utils.is_inventory_item (item.command) then
		item = tostring (item.value)
	else
		item = item.command
	end

	utils.robot_put_stack (robot_pos, "front", item)

	return true
end



local function run_drop (program, robot_pos)
	local item = program:next_cell ()

	if cmdstr (item) == "" then
		item = nil
	elseif utils.is_value_item (item.command) then
		item = tostring (program:get_value (item))
	elseif utils.is_inventory_item (item.command) then
		item = tostring (item.value)
	else
		item = item.command
	end

	utils.robot_remove_item (robot_pos, item, true)

	return true
end



local function run_trash (program, robot_pos)
	local item = program:next_cell ()

	if cmdstr (item) == "" then
		item = nil
	elseif utils.is_value_item (item.command) then
		item = tostring (program:get_value (item))
	elseif utils.is_inventory_item (item.command) then
		item = tostring (item.value)
	else
		item = item.command
	end

	utils.robot_remove_item (robot_pos, item, false)

	return true
end



local function run_drop_stack (program, robot_pos)
	local item = program:next_cell ()

	if utils.is_value_item (item.command) then
		item = tostring (program:get_value (item))
	elseif utils.is_inventory_item (item.command) then
		item = tostring (item.value)
	else
		item = item.command
	end

	utils.robot_remove_stack (robot_pos, item, true)

	return true
end



local function run_trash_stack (program, robot_pos)
	local item = program:next_cell ()

	if utils.is_value_item (item.command) then
		item = tostring (program:get_value (item))
	elseif utils.is_inventory_item (item.command) then
		item = tostring (item.value)
	else
		item = item.command
	end

	utils.robot_remove_stack (robot_pos, item, false)

	return true
end



local function run_place (program, robot_pos)
	local cmd = program:cur_command ()
	local item = program:next_cell ()
	local side = "front" -- assume lwscratch:cmd_act_place_front

	if cmd.command == "lwscratch:cmd_act_place_back" then
		side = "back"
	elseif cmd.command == "lwscratch:cmd_act_place_back_down" then
		side = "back down"
	elseif cmd.command == "lwscratch:cmd_act_place_back_up" then
		side = "back up"
	elseif cmd.command == "lwscratch:cmd_act_place_down" then
		side = "down"
	elseif cmd.command == "lwscratch:cmd_act_place_up" then
		side = "up"
	elseif cmd.command == "lwscratch:cmd_act_place_front_down" then
		side = "front down"
	elseif cmd.command == "lwscratch:cmd_act_place_front_up" then
		side = "front up"
	end

	if utils.is_value_item (item.command) then
		item = tostring (program:get_value (item))
	elseif utils.is_inventory_item (item.command) then
		item = tostring (item.value)
	else
		item = item.command
	end

	utils.robot_place (robot_pos, side, item)

	return true
end



local function run_chat (program, robot_pos)
	local item = program:next_cell ()
	local message = ""

	if utils.is_value_item (item.command) then
		message = tostring (program:get_value (item))
	end

	utils.robot_chat (robot_pos, message)

	return true
end



local function run_craft (program, robot_pos)
	local item = program:next_cell ()

	if utils.is_value_item (item.command) then
		item = tostring (program:get_value (item))
	else
		item = item.command
	end

	utils.robot_craft (robot_pos, item)

	return true
end



local function run_stop (program, robot_pos)
	program.stopped = true

	return true
end



local function run_wait (program, robot_pos)
	local value = tonumber (program:get_value (program:next_cell ()) or 0) or 0
	local meta = minetest.get_meta (robot_pos)

	if meta then
		meta:set_int ("delay_counter",
			math.ceil ((value / 10) / utils.settings.running_tick))
	end

	return true
end



local function run_action_value_assign (program, robot_pos)
	local cmd = program:cur_command ()
	local value = program:next_cell (false)
	local name = cmd.value

	if name and name:len () > 0 then
		local val

		if utils.is_inventory_item (cmdstr (value)) then
			val = value.command
		elseif utils.is_name_item (cmdstr (value)) then
			val = get_node_name (value.command, robot_pos)
		else
			val = program:get_value (value)
		end

		program:set_variable (name, val)
	end

	return false
end



local function run_action_value_plus (program, robot_pos)
	local cmd = program:cur_command ()
	local value = program:next_cell (false)
	local name = cmd.value

	if name and name:len () > 0 then
		local val
		local var = program:get_variable (name)

		if utils.is_name_item (cmdstr (value)) then
			val = get_node_name (value.command, robot_pos)
		else
			val = program:get_value (value)
		end

		if type (var) == "text" or type (val) == "text" then
			program:set_variable (name, tostring (var)..tostring (val))
		else
			program:set_variable (name, (tonumber (var or 0) or 0) + (tonumber (val or 0) or 0))
		end
	end

	return false
end



local function run_action_value_minus (program, robot_pos)
	local cmd = program:cur_command ()
	local value = program:next_cell (false)
	local name = cmd.value

	if name and name:len () > 0 then
		local val
		local var = program:get_variable (name)

		if utils.is_name_item (cmdstr (value)) then
			val = get_node_name (value.command, robot_pos)
		else
			val = program:get_value (value)
		end

		program:set_variable (name, (tonumber (var or 0) or 0) - (tonumber (val or 0) or 0))
	end

	return false
end



local function run_action_value_multiply (program, robot_pos)
	local cmd = program:cur_command ()
	local value = program:next_cell (false)
	local name = cmd.value

	if name and name:len () > 0 then
		local val
		local var = program:get_variable (name)

		if utils.is_name_item (cmdstr (value)) then
			val = get_node_name (value.command, robot_pos)
		else
			val = program:get_value (value)
		end

		program:set_variable (name, (tonumber (var or 0) or 0) * (tonumber (val or 0) or 0))
	end

	return false
end



local function run_action_value_divide (program, robot_pos)
	local cmd = program:cur_command ()
	local value = program:next_cell (false)
	local name = cmd.value

	if name and name:len () > 0 then
		local val
		local var = program:get_variable (name)

		if utils.is_name_item (cmdstr (value)) then
			val = get_node_name (value.command, robot_pos)
		else
			val = program:get_value (value)
		end

		program:set_variable (name, (tonumber (var or 0) or 0) / (tonumber (val or 0) or 0))
	end

	return false
end



local function run_if (program, robot_pos)
	local indent = program:line_indent ()
	local result = run_condition (program, robot_pos)

	if not result then
		program:advance_to_indent (indent)
	end

	return false
end



local function run_loop (program, robot_pos)
	local indent = program:line_indent ()
	local line = program:line ()

	program:push_loop (line, indent)

	local result = run_condition (program, robot_pos)

	if not result then
		program:pop_loop (line)
		program:advance_to_indent (indent)
	end

	return false
end



local run_table =
{
	["lwscratch:cmd_act_dig_front"] = run_dig,
	["lwscratch:cmd_act_dig_front_down"] = run_dig,
	["lwscratch:cmd_act_dig_front_up"] = run_dig,
	["lwscratch:cmd_act_dig_back"] = run_dig,
	["lwscratch:cmd_act_dig_back_down"] = run_dig,
	["lwscratch:cmd_act_dig_back_up"] = run_dig,
	["lwscratch:cmd_act_dig_down"] = run_dig,
	["lwscratch:cmd_act_dig_up"] = run_dig,
	["lwscratch:cmd_act_move_back"] = run_move,
	["lwscratch:cmd_act_move_down"] = run_move,
	["lwscratch:cmd_act_move_front"] = run_move,
	["lwscratch:cmd_act_move_up"] = run_move,
	["lwscratch:cmd_act_turn_left"] = run_turn,
	["lwscratch:cmd_act_turn_right"] = run_turn,
	["lwscratch:cmd_act_pull"] = run_pull,
	["lwscratch:cmd_act_put"] = run_put,
	["lwscratch:cmd_act_pull_stack"] = run_pull_stack,
	["lwscratch:cmd_act_put_stack"] = run_put_stack,
	["lwscratch:cmd_act_drop"] = run_drop,
	["lwscratch:cmd_act_trash"] = run_trash,
	["lwscratch:cmd_act_drop_stack"] = run_drop_stack,
	["lwscratch:cmd_act_trash_stack"] = run_trash_stack,
	["lwscratch:cmd_act_place_front"] = run_place,
	["lwscratch:cmd_act_place_front_down"] = run_place,
	["lwscratch:cmd_act_place_front_up"] = run_place,
	["lwscratch:cmd_act_place_back"] = run_place,
	["lwscratch:cmd_act_place_back_down"] = run_place,
	["lwscratch:cmd_act_place_back_up"] = run_place,
	["lwscratch:cmd_act_place_down"] = run_place,
	["lwscratch:cmd_act_place_up"] = run_place,
	["lwscratch:cmd_act_craft"] = run_craft,
	["lwscratch:cmd_act_stop"] = run_stop,
	["lwscratch:cmd_act_wait"] = run_wait,
	["lwscratch:cmd_act_chat"] = run_chat,
	["lwscratch:cmd_act_value_assign"] = run_action_value_assign,
	["lwscratch:cmd_act_value_plus"] = run_action_value_plus,
	["lwscratch:cmd_act_value_minus"] = run_action_value_minus,
	["lwscratch:cmd_act_value_multiply"] = run_action_value_multiply,
	["lwscratch:cmd_act_value_divide"] = run_action_value_divide,
	["lwscratch:cmd_stat_if"] = run_if,
	["lwscratch:cmd_stat_loop"] = run_loop,

}



------------------------------------------------------------------------



local program_obj = { }



function program_obj:new (program, pos)
	local obj = { }

   setmetatable(obj, self)
   self.__index = self

	obj.program = program
	obj.stopped = false
	obj.pos = { x = (pos and pos.x) or 0, y = (pos and pos.y) or 0, z = (pos and pos.z) or 0 }
	obj.loops_executed = 0

	if program then
		program_obj.init (obj)
	end

	if pos then
		local meta = minetest.get_meta (pos)

		if meta then
			obj.id = meta:get_int ("lwscratch_id")

			utils.add_robot_to_list (obj.id, obj.pos)
		end
	end

	return obj
end



function program_obj:serialize ()
	if not self.program then
		return false
	end

	local meta = minetest.get_meta (self.pos)

	if not meta then
		return false
	end

	meta:set_string ("program", minetest.serialize (self.program))

	return true
end



function program_obj:deserialize (pos)
	local meta = minetest.get_meta (pos)

	if not meta then
		return false
	end

	self.id = meta:get_int ("lwscratch_id")
	self.pos = { x = pos.x, y = pos.y, z = pos.z }
	self.program = minetest.deserialize (meta:get_string ("program"))

	utils.add_robot_to_list (self.id, self.pos)

	return true
end



function program_obj:init ()
	if not self.program then
		return nil
	end

	self.program.cur_line = 1
	self.program.cur_cell = 0
	self.program.loops = { }

	return true
end



function program_obj:cur_command ()
	if not self.program then
		return nil
	end

	local line = self.program.cur_line
	local cell = self.program.cur_cell

	if line > 0 and line <= 50 and cell > 0 and cell <= 10 then
		return self.program[line][cell]
	end

	return nil
end



function program_obj:line ()
	if not self.program then
		return nil
	end

	return self.program.cur_line
end



function program_obj:cell ()
	if not self.program then
		return nil
	end

	return self.program.cur_cell
end



function program_obj:lines ()
	if not self.program then
		return nil
	end

	return #self.program
end



function program_obj:cells ()
	if not self.program then
		return nil
	end

	return #self.program[1]
end



function program_obj:line_indent ()
	if not self.program then
		return nil
	end

	local line = self.program[self.program.cur_line]

	for c = 1, #line do
		if cmdstr (line[c]):len () > 0 then
			return c
		end
	end

	return self:cells ()
end



function program_obj:next_line ()
	if not self.program then
		return false
	end

	if self.program.cur_line < 50 then
		self.program.cur_line = self.program.cur_line + 1
		self.program.cur_cell = 0

		return true
	end

	self.program.cur_cell = self:cells ()

	return false
end



function program_obj:next_cell (query)
	if not self.program then
		return nil
	end

	local cell = self.program.cur_cell

	if cell < 10 then
		cell = cell + 1

		if not query then
			self.program.cur_cell = cell
		end

		return self.program[self.program.cur_line][cell]
	end

	return nil
end



function program_obj:advance_to_indent (indent)
	while self:next_line () do
		if self:line_indent () <= indent then

			return true
		end
	end

	return false
end



function program_obj:jump_to_line (line)
	self.program.cur_line = line
	self.program.cur_cell = 0
end



function program_obj:next_command ()
	if not self.program then
		return nil
	end

	local cmd = self:next_cell (false)

	while not cmd or not cmd.command do
		if not self:next_line () then
			return nil
		end

		cmd = self:next_cell (false)
	end

	return cmd
end



function program_obj:push_loop (line, indent)
	if #self.program.loops < 1 or
		self.program.loops[#self.program.loops].line ~= line then

		self.program.loops[#self.program.loops + 1] =
		{
			line = line,
			indent = indent,
			counter = 0
		}

	else
		self.program.loops[#self.program.loops].counter =
			self.program.loops[#self.program.loops].counter + 1

	end

	self.loops_executed = self.loops_executed + 1
end



function program_obj:pop_loop (line)
	if #self.program.loops > 0 and
		self.program.loops[#self.program.loops].line == line then

		table.remove (self.program.loops, #self.program.loops)
	end
end



function program_obj:loop_counter ()
	if not self.program then
		return nil
	end

	if #self.program.loops > 0 then
		return self.program.loops[#self.program.loops].counter
	end

	return 0
end



function program_obj:get_variable (name)
	if not self.program then
		return 0
	end

	if self.program.variables then
		return self.program.variables[name]
	end

	return nil
end



function program_obj:set_variable (name, value)
	if not self.program then
		return 0
	end

	if not self.program.variables then
		self.program.variables = { }
	end

	self.program.variables[name] = value
end



function program_obj:get_value (cmd)
	if utils.is_number_item (cmdstr (cmd)) then

		return tonumber (cmd.value or 0) or 0
	end

	if utils.is_text_item (cmdstr (cmd)) then

		return cmd.value
	end

	if utils.is_variable_item (cmdstr (cmd)) or
		utils.is_action_value_item (cmdstr (cmd)) or
		utils.is_condition_value_item (cmdstr (cmd)) then

		return self:get_variable (cmd.value)
	end

	return nil
end



function program_obj:loop_indent ()
	if not self.program then
		return 0
	end

	if #self.program.loops > 0 then
		return self.program.loops[#self.program.loops].indent
	end

	return 0
end



function program_obj:loop_line ()
	if not self.program then
		return 0
	end

	if #self.program.loops > 0 then
		return self.program.loops[#self.program.loops].line
	end

	return self:lines ()
end



function program_obj:yield ()
	local meta = minetest.get_meta (self.pos)

	if meta then
		meta:set_int ("delay_counter",
			math.ceil (utils.settings.robot_action_delay / utils.settings.running_tick))
	end
end



function program_obj:check ()
	if not self.program then
		return false
	end

	self:init ()

	for l = 1, self:lines () do
		local indent = self:line_indent ()

		if indent then
			for c = indent, self:cells () do
				local cmd = self:next_cell ()

				if cmdstr (cmd):len () > 0 then
					if not check_table[cmd.command] then
						return false, "out of place item"
					end

					local result, msg = check_table[cmd.command] (self)

					if not result then
						return result, msg
					end
				end
			end
		end

		self:next_line ()
	end

	self:init ()

	return true
end



function program_obj:run ()
	local cmd = self:next_command ()

	if not cmd and self:loop_indent () > 0 then
		self:jump_to_line (self:loop_line ())
		cmd = self:next_command ()
	end

	while cmd do
		local indent = self:line_indent ()

		if indent <= self:loop_indent () and
			self:line () > self:loop_line () then

			self:jump_to_line (self:loop_line ())

			if self.loops_executed > 50 then
				self:yield ()
				self:serialize ()

				return true
			end
		else
			if run_table[cmd.command] then
				if run_table[cmd.command] (self, self.pos) then
					self:serialize ()

					return not self.stopped
				end
			end
		end

		cmd = self:next_command ()

		if not cmd and self:loop_indent () > 0 then
			self:jump_to_line (self:loop_line ())
			cmd = self:next_command ()
		end
	end

	self:serialize ()

	return false
end



utils.program = program_obj



--
