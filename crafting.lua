
if minetest.global_exists ("default") then


minetest.register_craft({
	output = "lwscratch:robot 1",
	recipe = {
		{ "default:stone", "default:tin_ingot", "default:glass" },
		{ "default:steel_ingot", "default:coal_lump", "default:steel_ingot" },
		{ "default:stick", "default:copper_ingot", "default:clay_lump" }
	}
})


minetest.register_craft({
	output = "lwscratch:cassette 1",
	recipe = {
		{ "default:clay_lump", "default:coal_lump" },
		{ "default:stick", "default:book" }
	}
})


else


local game_id = Settings (minetest.get_worldpath ()..DIR_DELIM..'world.mt'):get ('gameid')

if game_id == "mineclone2" then

minetest.register_craft({
	output = "lwscratch:robot 1",
	recipe = {
		{ "mcl_core:stone", "mcl_core:iron_ingot", "mcl_core:glass" },
		{ "mcl_core:iron_ingot", "mcl_core:coal_lump", "mcl_core:iron_ingot" },
		{ "mcl_core:stick", "mcl_core:iron_ingot", "mcl_core:clay_lump" }
	}
})


minetest.register_craft({
	output = "lwscratch:cassette 1",
	recipe = {
		{ "mcl_core:clay_lump", "mcl_core:coal_lump" },
		{ "mcl_core:stick", "mcl_books:book" }
	}
})

end


end



--
