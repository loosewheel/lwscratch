local version = "0.2.3"



lwscratch = { }



function lwscratch.version ()
	return version
end



local utils = { }
utils.commands_inv_size = 120
utils.program_inv_size = 500

local modpath = minetest.get_modpath ("lwscratch")


loadfile (modpath.."/settings.lua") (utils)
loadfile (modpath.."/utils.lua") (utils)
loadfile (modpath.."/encoder.lua") (utils)
loadfile (modpath.."/commands.lua") (utils)
loadfile (modpath.."/program.lua") (utils)
loadfile (modpath.."/robot_ops.lua") (utils)
loadfile (modpath.."/robot.lua") (utils)
loadfile (modpath.."/cassette.lua") (utils)
loadfile (modpath.."/crafting.lua") ()



--
