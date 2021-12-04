local utils = ...
local S = utils.S



local function good_msg (player, msg)
	if player and player:is_player () then
		minetest.chat_send_player (player:get_player_name (),
											minetest.colorize ("#5555ff", tostring (msg)))
	end
end



local function bad_msg (player, msg)
	if player and player:is_player () then
		minetest.chat_send_player (player:get_player_name (),
											minetest.colorize ("#ff4040", tostring (msg)))
	end
end



local function on_secondary_use (itemstack, user, pointed_thing)
	if user and user:is_player () and itemstack then
		local meta = itemstack:get_meta ()

		if meta then
			if meta:get_string ("has_program") == "true" then
				local label = meta:get_string ("label")
				local locked = (meta:get_int ("locked") == 0 and "false") or "true"
				local spec =
				"formspec_version[3]"..
				"size[8.0,4.25,false]"..
				"field[1.0,1.5;5.0,0.8;label;Label;"..minetest.formspec_escape (label).."]"..
				"button[6.0,1.5;1.0,0.8;setlabel;Set]"..
				"checkbox[1.0,2.75;locked;Read Only;"..locked.."]"..
				"button_exit[5.5,2.75;1.5,0.8;close;Close]"

				minetest.show_formspec (user:get_player_name (),
												"lwscratch:cassette_form",
												spec)
			else
				meta:set_string ("program", "")
				meta:set_string ("label", "")
				meta:set_string ("description", "Cassette")
				meta:set_int ("locked", 0)

				local spec =
				"formspec_version[3]"..
				"size[8.0,4.0,false]"..
				"label[1.0,1.25;Cassette is blank.]"..
				"button_exit[3.0,2.0;2.0,0.8;close;Close]"

				minetest.show_formspec (user:get_player_name (),
												"lwscratch:cassette_no_program",
												spec)
			end
		end
	end

	return itemstack
end



local function on_place (itemstack, placer, pointed_thing)
	local on_rightclick = utils.get_on_rightclick (pointed_thing.under, placer)
	if on_rightclick then
		return on_rightclick (pointed_thing.under, utils.get_far_node (pointed_thing.under),
									 placer, itemstack, pointed_thing)
	end

	local rmeta = minetest.get_meta (pointed_thing.under)

	if rmeta and rmeta:get_int ("lwscratch_id") > 0 then
		if not utils.can_interact_with_node (pointed_thing.under, placer) then
			if placer and placer:is_player () then
				local owner = rmeta:get_string ("owner")

				local spec =
				"formspec_version[3]"..
				"size[8.0,4.0,false]"..
				"label[1.0,1.0;Owned by "..minetest.formspec_escape (owner).."]"..
				"button_exit[3.0,2.0;2.0,1.0;close;Close]"

				minetest.show_formspec (placer:get_player_name (),
												"lwscratch:robot_privately_owned",
												spec)
			end

		elseif itemstack then
			local imeta = itemstack:get_meta ()
			local inv = rmeta:get_inventory ()

			if imeta and inv then
				if imeta:get_string ("has_program") == "true" then
					local program = minetest.deserialize (imeta:get_string ("program"))

					utils.dencode_program (inv, program)

					rmeta:set_string ("formspec", utils.get_robot_formspec (pointed_thing.under))

					good_msg (placer, "Robot "..rmeta:get_string ("name").." program was set.")
				else
					bad_msg (placer, "Cassette is blank.")
				end
			end
		end
	end


	return itemstack
end



local function on_use (itemstack, user, pointed_thing)
	if pointed_thing and pointed_thing.type == "node" and pointed_thing.under then
		local rmeta = minetest.get_meta (pointed_thing.under)

		if rmeta and rmeta:get_int ("lwscratch_id") > 0 then
			if not utils.can_interact_with_node (pointed_thing.under, user) then
				if user and user:is_player () then
					local owner = rmeta:get_string ("owner")

					local spec =
					"formspec_version[3]"..
					"size[8.0,4.0,false]"..
					"label[1.0,1.0;Owned by "..minetest.formspec_escape (owner).."]"..
					"button_exit[3.0,2.0;2.0,1.0;close;Close]"

					minetest.show_formspec (user:get_player_name (),
													"lwscratch:robot_privately_owned",
													spec)
				end

			elseif itemstack then
				local imeta = itemstack:get_meta ()

				if imeta then
					if imeta:get_int ("locked") == 0 then
						local inv = rmeta:get_inventory ()

						if inv then
							local program = minetest.serialize (utils.encode_program (inv))

							if program:len () <= 60000 then
								local label = rmeta:get_string ("name")

								if label:len () < 1 then
									label = "program"
								end

								imeta:set_string ("program", program)
								imeta:set_string ("label", label)
								imeta:set_string ("description", label)
								imeta:set_string ("has_program", "true")

								good_msg (user, "Robot "..rmeta:get_string ("name").." program was copied.")
							else
								bad_msg (user, "Program too large for cassette.")
							end
						end
					else
						bad_msg (user, "Cassette locked.")
					end
				end
			end
		end
	end

	return itemstack
end



minetest.register_craftitem ("lwscratch:cassette", {
	description = S("Cassette"),
	short_description = S("Cassette"),
	groups = { },
	inventory_image = "lwscratch_cassette.png",
	wield_image = "lwscratch_cassette.png",
	wield_scale = { x = 1, y = 1, z = 1 },
	stack_max = 1,
	range = 4.0,
	on_place = on_place,
	on_secondary_use = on_secondary_use,
	on_use = on_use,
})



minetest.register_on_player_receive_fields (function (player, formname, fields)
   if formname == "lwscratch:cassette_form" and
		player and player:is_player () then

		local itemstack = player:get_wielded_item ()

		if itemstack then
			local meta = itemstack:get_meta ()

			if meta then
				if fields.setlabel then
					local label = fields.label

					meta:set_string ("label", label)

					if meta:get_int ("locked") ~= 0 then
						label = label.." (locked)"
					end

					meta:set_string ("description", label)

					player:set_wielded_item (itemstack)
				end

				if fields.locked then
					local label = meta:get_string ("label")

					if fields.locked == "true" then
						label = label.." (locked)"
					end

					meta:set_int ("locked", (fields.locked == "true" and 1) or 0)
					meta:set_string ("description", label)

					player:set_wielded_item (itemstack)
				end
			end
		end
	end

	return nil
end)



--
