if not minetest.get_modpath("default") then return end
local utils = ...
local S = utils.S



minetest.register_craft({
	output = "lwscratch:robot 1",
	recipe = {
		{ "default:stone", "default:tin_ingot", "default:glass" },
		{ "default:steel_ingot", "default:coal_lump", "default:steel_ingot" },
		{ "default:stick", "default:copper_ingot", "default:clay_lump" }
	}
})



--
