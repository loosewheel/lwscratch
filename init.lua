local version = "0.1.5"



if not lwdrops then
	minetest.log ("error", "lwscratch could not find dependency lwdrops")

	return
end



lwscratch = { }



function lwscratch.version ()
	return version
end



local utils = { }
utils.commands_inv_size = 112
utils.program_inv_size = 500

local modpath = minetest.get_modpath ("lwscratch")
local worldpath = minetest.get_worldpath ()


loadfile (modpath.."/settings.lua") (utils)
loadfile (modpath.."/utils.lua") (utils)
loadfile (modpath.."/commands.lua") (utils)
loadfile (modpath.."/program.lua") (utils)
loadfile (modpath.."/robot_ops.lua") (utils)
loadfile (modpath.."/robot.lua") (utils)
loadfile (modpath.."/crafting.lua") (utils)



--
