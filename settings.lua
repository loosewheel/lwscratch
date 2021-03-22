local utils = ...


utils.settings = { }

utils.settings.running_tick =
	tonumber(minetest.settings:get("lwscratch_running_tick") or 0.1)

utils.settings.robot_move_delay =
	tonumber(minetest.settings:get("lwscratch_robot_move_delay") or 0.5)

utils.settings.robot_action_delay =
	tonumber(minetest.settings:get("lwscratch_robot_action_delay") or 0.2)

if utils.settings.robot_move_delay < 0.1 then
	utils.settings.robot_move_delay = 0.1
end

if utils.settings.robot_action_delay < 0.1 then
	utils.settings.robot_action_delay = 0.1
end

utils.settings.default_stack_max =
	tonumber(minetest.settings:get("default_stack_max")) or 99


--
