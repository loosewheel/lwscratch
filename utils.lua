local utils = ...



if minetest.get_translator and minetest.get_translator ("lwscratch") then
	utils.S = minetest.get_translator ("lwscratch")
elseif minetest.global_exists ("intllib") then
   if intllib.make_gettext_pair then
      utils.S = intllib.make_gettext_pair ()
   else
      utils.S = intllib.Getter ()
   end
else
   utils.S = function (s) return s end
end



utils.modpath = minetest.get_modpath ("lwscratch")
utils.worldpath = minetest.get_worldpath ()



function utils.find_item_def (name)
	local def = minetest.registered_items[name]

	if not def then
		def = minetest.registered_craftitems[name]
	end

	if not def then
		def = minetest.registered_nodes[name]
	end

	if not def then
		def = minetest.registered_tools[name]
	end

	return def
end



function utils.on_destroy (itemstack)
	local stack = ItemStack (itemstack)

	if stack and stack:get_count () > 0 then
		local def = utils.find_item_def (stack:get_name ())

		if def and def.on_destroy then
			def.on_destroy (stack)
		end
	end
end



function utils.get_far_node (pos)
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



function utils.get_on_rightclick (pos, player)
	local node = utils.get_far_node (pos)

	if node then
		local def = minetest.registered_nodes[node.name]

		if def and def.on_rightclick and
			not (player and player:is_player () and
				  player:get_player_control ().sneak) then

				return def.on_rightclick
		end
	end

	return nil
end



function utils.get_palette_index (itemstack)
	local stack = ItemStack (itemstack)
	local color = 0

	if stack then
		local tab = stack:to_table ()

		if tab and tab.meta and tab.meta.palette_index then
			color = tonumber (tab.meta.palette_index) or 240
		end
	end

	return color
end



function utils.item_drop (itemstack, dropper, pos)
	if itemstack then
		local def = utils.find_item_def (itemstack:get_name ())

		if def and def.on_drop then
			return def.on_drop (itemstack, dropper, pos)
		end
	end

	return minetest.item_drop (itemstack, dropper, pos)
end



utils.robots_list = { }

function utils.add_robot_to_list (id, pos)
	local robot = utils.robots_list[id]

	if not robot then
		utils.robots_list[id] = { }
		robot = utils.robots_list[id]
	end

	robot.pos = { x = pos.x, y = pos.y, z = pos.z }
end



function utils.remove_robot_from_list (id)
	utils.robots_list[id] = nil
end



function utils.get_robot_pos (id)
	local robot = utils.robots_list[id]

	if robot then
		return robot.pos
	end

	return nil
end



function utils.stop_robot_by_id (id)
	local robot = utils.robots_list[id]

	if robot then
		utils.robot_stop (robot.pos)

		return true
	end

	return false
end



function utils.can_interact_with_node (pos, player)
	if not player or not player:is_player () then
		return false
	end

	if minetest.check_player_privs (player, "protection_bypass") then
		return true
	end

	local meta = minetest.get_meta (pos)
	if meta then
		local owner = meta:get_string ("owner")
		local name = player:get_player_name ()

		if not owner or owner == "" or owner == name then
			return true
		end
	end

	return false
end


--[[
function utils.new_inventory ()
	local commands = ""
	for i = 1, utils.commands_inv_size do
		commands = commands..string.format ("[%d] = '', ", i)
	end

	local program = ""
	for i = 1, utils.program_inv_size do
		program = program..string.format ("[%d] = '', ", i)
	end

	local inv =
		"{ "..
		"value = { [1] = '' }, "..
		"program = { "..program.."}, "..
		"commands = { "..commands.."}, "..
		"storage = { [1] = '', [2] = '', [3] = '', [4] = '', [5] = '', [6] = '', [7] = '', [8] = '', "..
		"            [9] = '', [10] = '', [11] = '', [12] = '', [13] = '', [14] = '', [15] = '', [16] = '', "..
		"            [17] = '', [18] = '', [19] = '', [20] = '', [21] = '', [22] = '', [23] = '', [24] = '', "..
		"            [25] = '', [26] = '', [27] = '', [28] = '', [29] = '', [30] = '', [31] = '', [32] = '' } "..
		"}"

	return inv
end
]]


function utils.get_program (inv)
	local program = { }

	program.cur_line = 0
	program.cur_cell = 0
	program.loops =  { }

	for l = 1, 50 do
		program[l] = { }

		for c = 1, 10 do
			local stack = inv:get_stack ("program", ((l - 1) * 10) + c)

			program[l][c] = { }
			local cmd = program[l][c]

			if stack then
				cmd.command = stack:get_name ()

				if utils.is_value_item (stack:get_name ()) or
					utils.is_action_value_item (stack:get_name ()) or
					utils.is_condition_value_item (stack:get_name ()) then

					local meta = stack:get_meta ()

					if meta then
						cmd.value = meta:get_string ("value")
					else
						minetest.log ("error", "lwscratch - unable to get number value.")
					end

				elseif utils.is_inventory_item (stack:get_name ()) then
					cmd.value = stack:to_string ()

				end
			end
		end
	end

	return program
end



function utils.prep_inventory (inv, program)
	local ops =
	{
		"lwscratch:cmd_act_move_front",
		"lwscratch:cmd_act_move_back",
		"lwscratch:cmd_act_move_down",
		"lwscratch:cmd_act_move_up",
		"lwscratch:cmd_act_turn_left",
		"lwscratch:cmd_act_turn_right",
		"",
		"",

		"lwscratch:cmd_act_dig_front",
		"lwscratch:cmd_act_dig_front_down",
		"lwscratch:cmd_act_dig_front_up",
		"lwscratch:cmd_act_dig_back",
		"lwscratch:cmd_act_dig_back_down",
		"lwscratch:cmd_act_dig_back_up",
		"lwscratch:cmd_act_dig_down",
		"lwscratch:cmd_act_dig_up",

		"lwscratch:cmd_act_place_front",
		"lwscratch:cmd_act_place_front_down",
		"lwscratch:cmd_act_place_front_up",
		"lwscratch:cmd_act_place_back",
		"lwscratch:cmd_act_place_back_down",
		"lwscratch:cmd_act_place_back_up",
		"lwscratch:cmd_act_place_down",
		"lwscratch:cmd_act_place_up",

		"lwscratch:cmd_act_pull",
		"lwscratch:cmd_act_put",
		"lwscratch:cmd_act_pull_stack",
		"lwscratch:cmd_act_put_stack",
		"",
		"lwscratch:cmd_act_craft",
		"",
		"",

		"lwscratch:cmd_act_drop",
		"lwscratch:cmd_act_trash",
		"lwscratch:cmd_act_drop_stack",
		"lwscratch:cmd_act_trash_stack",
		"",
		"",
		"",
		"",

		"lwscratch:cmd_act_value_assign",
		"lwscratch:cmd_act_value_plus",
		"lwscratch:cmd_act_value_minus",
		"lwscratch:cmd_act_value_multiply",
		"lwscratch:cmd_act_value_divide",
		"",
		"",
		"",

		"lwscratch:cmd_act_stop",
		"lwscratch:cmd_act_wait",
		"lwscratch:cmd_act_chat",
		"",
		"",
		"",
		"",
		"",

		"lwscratch:cmd_value_number",
		"lwscratch:cmd_value_text",
		"lwscratch:cmd_value_value",
		"",
		"",
		"",
		"",
		"",

		"lwscratch:cmd_name_front",
		"lwscratch:cmd_name_front_down",
		"lwscratch:cmd_name_front_up",
		"lwscratch:cmd_name_back",
		"lwscratch:cmd_name_back_down",
		"lwscratch:cmd_name_back_up",
		"lwscratch:cmd_name_down",
		"lwscratch:cmd_name_up",

		"lwscratch:cmd_stat_if",
		"lwscratch:cmd_stat_loop",
		"lwscratch:cmd_op_not",
		"lwscratch:cmd_op_and",
		"lwscratch:cmd_op_or",
		"",
		"",
		"",

		"lwscratch:cmd_cond_counter_equal",
		"lwscratch:cmd_cond_counter_greater",
		"lwscratch:cmd_cond_counter_less",
		"lwscratch:cmd_cond_counter_even",
		"lwscratch:cmd_cond_counter_odd",
		"",
		"",
		"",

		"lwscratch:cmd_cond_value_equal",
		"lwscratch:cmd_cond_value_greater",
		"lwscratch:cmd_cond_value_less",
		"lwscratch:cmd_cond_value_even",
		"lwscratch:cmd_cond_value_odd",
		"",
		"",
		"",

		"lwscratch:cmd_cond_contains",
		"lwscratch:cmd_cond_fits",
		"",
		"",
		"",
		"",
		"",
		"",

		"lwscratch:cmd_cond_detect_front",
		"lwscratch:cmd_cond_detect_front_down",
		"lwscratch:cmd_cond_detect_front_up",
		"lwscratch:cmd_cond_detect_back",
		"lwscratch:cmd_cond_detect_back_down",
		"lwscratch:cmd_cond_detect_back_up",
		"lwscratch:cmd_cond_detect_down",
		"lwscratch:cmd_cond_detect_up",

		"lwscratch:cmd_line_insert",
		"lwscratch:cmd_line_remove",
		"",
		"",
		"",
		"",
		"",
		"",

	}

	for i = 1, #ops do
		inv:set_stack ("commands", i, ItemStack (ops[i]))
	end

	if program then
		for l = 1, #program do
			local line = program[l]

			for c = 1, #line do
				if line[c] and line[c].command then
					local stack = ItemStack (line[c].command)

					if stack then
						if utils.is_value_item (stack:get_name ()) or
							utils.is_action_value_item (stack:get_name ()) or
							utils.is_condition_value_item (stack:get_name ()) then

							local meta = stack:get_meta ()

							if meta then
								meta:set_string ("value", tostring (line[c].value or ""))
								meta:set_string ("description", tostring (line[c].value or ""))
							else
								minetest.log ("error", "lwscratch - unable to set number value.")
							end

						elseif utils.is_inventory_item (stack:get_name ()) then
							stack = ItemStack (line[c].value or line[c].command)

						end

						inv:set_stack ("program", ((l - 1) * 10) + c, stack)

					else
						minetest.log ("error", "lwscratch - unable to set program command.")
					end
				end
			end
		end
	end
end



function utils.is_command_item (name)
	return name:sub (1, 14) == "lwscratch:cmd_"
end



function utils.is_inventory_item (name)
	return name:len () > 0 and name:sub (1, 14) ~= "lwscratch:cmd_"
end



function utils.is_inventory_item_or_blank (name)
	return name:sub (1, 14) ~= "lwscratch:cmd_"
end



function utils.is_condition_item (name)
	return name:sub (1, 19) == "lwscratch:cmd_cond_"
end



function utils.is_operator_item (name)
	return name:sub (1, 17) == "lwscratch:cmd_op_"
end



function utils.is_action_item (name)
	return name:sub (1, 18) == "lwscratch:cmd_act_"
end



function utils.is_statement_item (name)
	return name:sub (1, 19) == "lwscratch:cmd_stat_"
end



function utils.is_value_item (name)
	return name:sub (1, 20) == "lwscratch:cmd_value_"
end



function utils.is_number_item (name)
	return name == "lwscratch:cmd_value_number"
end



function utils.is_text_item (name)
	return name == "lwscratch:cmd_value_text"
end



function utils.is_variable_item (name)
	return name == "lwscratch:cmd_value_value"
end



function utils.is_action_value_item (name)
	return name:sub (1, 24) == "lwscratch:cmd_act_value_"
end



function utils.is_condition_value_item (name)
	return name:sub (1, 25) == "lwscratch:cmd_cond_value_"
end



function utils.is_name_item (name)
	return name:sub (1, 19) == "lwscratch:cmd_name_"
end



function utils.set_owner_formspec (id)
	return
		"formspec_version[3]"..
		"size[8.0,3.0,false]"..
		"no_prepend[]"..
		"bgcolor[#769BE6]"..
		"style[public;bgcolor=green;textcolor=white]"..
		"style[private_"..tostring (id)..";bgcolor=red;textcolor=white]"..
		"button_exit[1.0,1.0;2.5,1.0;set_public;Public]"..
		"button_exit[4.5,1.0;2.5,1.0;private_"..tostring (id)..";Private]"
end



function utils.robot_stop_formspec (id)
	return
		"formspec_version[3]"..
		"size[4.5,3.0,false]"..
		"no_prepend[]"..
		"bgcolor[#769BE6]"..
		"style_type[button_exit;bgcolor=red;textcolor=white]"..
		"button_exit[1.0,1.0;2.5,1.0;stop_"..tostring (id)..";Stop]"
end



function utils.robot_stop (pos)
	local meta = minetest.get_meta (pos)

	if meta and meta:get_int ("lwscratch_id") > 0 then
		minetest.get_node_timer (pos):stop ()

		meta:set_int ("running", 0)
		meta:set_string ("program", "")

		local node = minetest.get_node_or_nil (pos)
		if node then
			node.name = "lwscratch:robot"

			minetest.swap_node (pos, node)
		end
	end
end



function utils.robot_run (pos)
	local meta = minetest.get_meta (pos)

	if meta then
		if meta:get_int ("running") == 1 then
			return false
		end

		local inv = meta:get_inventory ()
		if not inv then
			return false
		end

		local program = utils.program:new (utils.get_program (inv), pos)

		-- check program for errors
		local result, msg = program:check ()
		if not result then
			meta:set_string ("error", string.format ("%d, %d: %s",
																  program:line (),
																  program:cell (),
																  msg))

			return false
		else
			meta:set_string ("error", "")
		end

		-- store program and set to running, start node timer
		program:serialize ()

		meta:set_int ("running", 1)

		local node = minetest.get_node_or_nil (pos)
		if node then
			node.name = "lwscratch:robot_on"

			minetest.swap_node (pos, node)
		end

		minetest.get_node_timer (pos):start (utils.settings.running_tick)
	end

	return true
end



utils.place_substitute = dofile (utils.modpath.."/place_substitute.lua")
utils.crafting_mods = dofile (utils.modpath.."/crafting_mods.lua")



function utils.get_place_substitute (item, dir)
	local subst = utils.place_substitute[item]

	if subst then
		if type (subst) == "table" then
			if dir and type (subst[dir]) == "string" then
				return subst[dir]
			elseif type (subst[1]) == "string" then
				return subst[1]
			end
		elseif type (subst) == "string" then
			return subst
		end
	end

	return item
end



function utils.get_crafting_mods (item)
	return utils.crafting_mods[item]
end



function utils.get_robot_formspec (pos)
	local persists =
		"image_button[21.05,3.0;0.7,0.7;lw_itch_persist_button_off.png;persists;;false;false;lw_itch_persist_button_off.png]"
	local power =
		"image_button[20.7,1.0;1.4,1.4;lw_itch_power_button_off.png;power;;false;false;lw_itch_power_button_off.png]"
	local error_msg = ""

	local meta = minetest.get_meta (pos)

	if meta then
		if meta:get_int ("persists") == 1 then
			persists =
				"image_button[21.05,3.0;0.7,0.7;lw_itch_persist_button_on.png;persists;;false;false;lw_itch_persist_button_on.png]"
		end

		if meta:get_int ("running") == 1 then
			power =
				"image_button[20.7,1.0;1.4,1.4;lw_itch_power_button_on.png;power;;false;false;lw_itch_power_button_on.png]"
		end

		local msg = meta:get_string ("error")

		if msg:len () > 0 then
			error_msg =
				"style_type[label;textcolor=red]"..
				"label[1.0,17.4;"..minetest.formspec_escape (msg).."]"..
				"style_type[label;textcolor=white]"
		end
	end

	local spec =
		"formspec_version[3]"..
		"size[22.8,18.0,false]"..
		"no_prepend[]"..
		"bgcolor[#769BE6]"..

		"button[1.0,1.0;1.4,0.8;clear_program;Clear]"..
		"field[2.5,1.0;2.5,0.8;name;Robot;${name}]"..
		"button[5.0,1.0;1.0,0.8;setname;Set]"..

		"style_type[list;noclip=false;size=1.0,1.0;spacing=0.0,0.0]"..
		-- value
		"list[context;value;6.1,0.9;1,1;]\n"..
		"field[7.2,1.0;3.3,0.8;number_value;Value;]"..
		"button[10.5,1.0;1.0,0.8;set_value;Set]"..

		-- program
		"scrollbaroptions[min=0;max=350;smallstep=30;largestep=70;thumbsize=105;arrows=default]"..
		"scrollbar[11.0,2.0;0.5,15.0;vertical;program_scroll;0-350]"..
		"scroll_container[1.0,2.0;10.0,15.0;program_scroll;vertical;0.1]"..
		"list[context;program;0.0,0.0;10,50;]\n"..
		"scroll_container_end[]"..

		-- commands
		"scrollbaroptions[min=0;max=100;smallstep=10;largestep=10;thumbsize=25;arrows=default]"..
		"scrollbar[20.0,1.0;0.5,5.0;vertical;commands_scroll;0-100]"..
		"scroll_container[12.0,1.0;8.0,5.0;commands_scroll;vertical;0.1]"..
		"list[context;commands;0.0,0.0;8,15;]\n"..
		"scroll_container_end[]"..

		power..
		persists..
		error_msg..

		-- inventories
		"style_type[list;noclip=false;size=1.0,1.0;spacing=0.25,0.25]"..
		"list[context;storage;12.0,6.7;8,4;]"..
		"list[current_player;main;12.0,12.2;8,4;]"..
		"listring[]"..
		"listcolors[#545454;#6E6E6E;#6281BF]"

	return spec
end



--
