local utils = ...



local encode_cmd =
{
	["lwscratch:cmd_act_move_front"]				= "AA",
	["lwscratch:cmd_act_move_back"]				= "AB",
	["lwscratch:cmd_act_move_down"]				= "AC",
	["lwscratch:cmd_act_move_up"]					= "AD",
	["lwscratch:cmd_act_turn_left"]				= "AE",
	["lwscratch:cmd_act_turn_right"]				= "AF",
	["lwscratch:cmd_act_dig_front"]				= "AG",
	["lwscratch:cmd_act_dig_front_down"]		= "AH",
	["lwscratch:cmd_act_dig_front_up"]			= "AI",
	["lwscratch:cmd_act_dig_back"]				= "AJ",
	["lwscratch:cmd_act_dig_back_down"]			= "AK",
	["lwscratch:cmd_act_dig_back_up"]			= "AL",
	["lwscratch:cmd_act_dig_down"]				= "AM",
	["lwscratch:cmd_act_dig_up"]					= "AN",
	["lwscratch:cmd_act_place_front"]			= "AO",
	["lwscratch:cmd_act_place_front_down"]		= "AP",
	["lwscratch:cmd_act_place_front_up"]		= "AQ",
	["lwscratch:cmd_act_place_back"]				= "AR",
	["lwscratch:cmd_act_place_back_down"]		= "AS",
	["lwscratch:cmd_act_place_back_up"]			= "AT",
	["lwscratch:cmd_act_place_down"]				= "AU",
	["lwscratch:cmd_act_place_up"]				= "AV",
	["lwscratch:cmd_act_pull"]						= "AW",
	["lwscratch:cmd_act_put"]						= "AX",
	["lwscratch:cmd_act_pull_stack"]				= "AY",
	["lwscratch:cmd_act_put_stack"]				= "AZ",
	["lwscratch:cmd_act_craft"]					= "BA",
	["lwscratch:cmd_act_drop"]						= "BB",
	["lwscratch:cmd_act_trash"]					= "BC",
	["lwscratch:cmd_act_drop_stack"]				= "BD",
	["lwscratch:cmd_act_trash_stack"]			= "BE",
	["lwscratch:cmd_act_value_assign"]			= "BF",
	["lwscratch:cmd_act_value_plus"]				= "BG",
	["lwscratch:cmd_act_value_minus"]			= "BH",
	["lwscratch:cmd_act_value_multiply"]		= "BI",
	["lwscratch:cmd_act_value_divide"]			= "BJ",
	["lwscratch:cmd_act_stop"]						= "BK",
	["lwscratch:cmd_act_wait"]						= "BL",
	["lwscratch:cmd_act_chat"]						= "BM",
	["lwscratch:cmd_value_number"]				= "BN",
	["lwscratch:cmd_value_text"]					= "BO",
	["lwscratch:cmd_value_value"]					= "BP",
	["lwscratch:cmd_name_front"]					= "BQ",
	["lwscratch:cmd_name_front_down"]			= "BR",
	["lwscratch:cmd_name_front_up"]				= "BS",
	["lwscratch:cmd_name_back"]					= "BT",
	["lwscratch:cmd_name_back_down"]				= "BU",
	["lwscratch:cmd_name_back_up"]				= "BV",
	["lwscratch:cmd_name_down"]					= "BW",
	["lwscratch:cmd_name_up"]						= "BX",
	["lwscratch:cmd_stat_if"]						= "BY",
	["lwscratch:cmd_stat_loop"]					= "BZ",
	["lwscratch:cmd_op_not"]						= "CA",
	["lwscratch:cmd_op_and"]						= "CB",
	["lwscratch:cmd_op_or"]							= "CC",
	["lwscratch:cmd_cond_counter_equal"]		= "CD",
	["lwscratch:cmd_cond_counter_greater"]		= "CE",
	["lwscratch:cmd_cond_counter_less"]			= "CF",
	["lwscratch:cmd_cond_counter_even"]			= "CG",
	["lwscratch:cmd_cond_counter_odd"]			= "CH",
	["lwscratch:cmd_cond_value_equal"]			= "CI",
	["lwscratch:cmd_cond_value_greater"]		= "CJ",
	["lwscratch:cmd_cond_value_less"]			= "CK",
	["lwscratch:cmd_cond_value_even"]			= "CL",
	["lwscratch:cmd_cond_value_odd"]				= "CM",
	["lwscratch:cmd_cond_contains"]				= "CN",
	["lwscratch:cmd_cond_fits"]					= "CO",
	["lwscratch:cmd_cond_detect_front"]			= "CP",
	["lwscratch:cmd_cond_detect_front_down"]	= "CQ",
	["lwscratch:cmd_cond_detect_front_up"]		= "CR",
	["lwscratch:cmd_cond_detect_back"]			= "CS",
	["lwscratch:cmd_cond_detect_back_down"]	= "CT",
	["lwscratch:cmd_cond_detect_back_up"]		= "CU",
	["lwscratch:cmd_cond_detect_down"]			= "CV",
	["lwscratch:cmd_cond_detect_up"]				= "CW",
	[""]													= "ZZ",
}



local dencode_cmd =
{
	["AA"] = "lwscratch:cmd_act_move_front",
	["AB"] = "lwscratch:cmd_act_move_back",
	["AC"] = "lwscratch:cmd_act_move_down",
	["AD"] = "lwscratch:cmd_act_move_up",
	["AE"] = "lwscratch:cmd_act_turn_left",
	["AF"] = "lwscratch:cmd_act_turn_right",
	["AG"] = "lwscratch:cmd_act_dig_front",
	["AH"] = "lwscratch:cmd_act_dig_front_down",
	["AI"] = "lwscratch:cmd_act_dig_front_up",
	["AJ"] = "lwscratch:cmd_act_dig_back",
	["AK"] = "lwscratch:cmd_act_dig_back_down",
	["AL"] = "lwscratch:cmd_act_dig_back_up",
	["AM"] = "lwscratch:cmd_act_dig_down",
	["AN"] = "lwscratch:cmd_act_dig_up",
	["AO"] = "lwscratch:cmd_act_place_front",
	["AP"] = "lwscratch:cmd_act_place_front_down",
	["AQ"] = "lwscratch:cmd_act_place_front_up",
	["AR"] = "lwscratch:cmd_act_place_back",
	["AS"] = "lwscratch:cmd_act_place_back_down",
	["AT"] = "lwscratch:cmd_act_place_back_up",
	["AU"] = "lwscratch:cmd_act_place_down",
	["AV"] = "lwscratch:cmd_act_place_up",
	["AW"] = "lwscratch:cmd_act_pull",
	["AX"] = "lwscratch:cmd_act_put",
	["AY"] = "lwscratch:cmd_act_pull_stack",
	["AZ"] = "lwscratch:cmd_act_put_stack",
	["BA"] = "lwscratch:cmd_act_craft",
	["BB"] = "lwscratch:cmd_act_drop",
	["BC"] = "lwscratch:cmd_act_trash",
	["BD"] = "lwscratch:cmd_act_drop_stack",
	["BE"] = "lwscratch:cmd_act_trash_stack",
	["BF"] = "lwscratch:cmd_act_value_assign",
	["BG"] = "lwscratch:cmd_act_value_plus",
	["BH"] = "lwscratch:cmd_act_value_minus",
	["BI"] = "lwscratch:cmd_act_value_multiply",
	["BJ"] = "lwscratch:cmd_act_value_divide",
	["BK"] = "lwscratch:cmd_act_stop",
	["BL"] = "lwscratch:cmd_act_wait",
	["BM"] = "lwscratch:cmd_act_chat",
	["BN"] = "lwscratch:cmd_value_number",
	["BO"] = "lwscratch:cmd_value_text",
	["BP"] = "lwscratch:cmd_value_value",
	["BQ"] = "lwscratch:cmd_name_front",
	["BR"] = "lwscratch:cmd_name_front_down",
	["BS"] = "lwscratch:cmd_name_front_up",
	["BT"] = "lwscratch:cmd_name_back",
	["BU"] = "lwscratch:cmd_name_back_down",
	["BV"] = "lwscratch:cmd_name_back_up",
	["BW"] = "lwscratch:cmd_name_down",
	["BX"] = "lwscratch:cmd_name_up",
	["BY"] = "lwscratch:cmd_stat_if",
	["BZ"] = "lwscratch:cmd_stat_loop",
	["CA"] = "lwscratch:cmd_op_not",
	["CB"] = "lwscratch:cmd_op_and",
	["CC"] = "lwscratch:cmd_op_or",
	["CD"] = "lwscratch:cmd_cond_counter_equal",
	["CE"] = "lwscratch:cmd_cond_counter_greater",
	["CF"] = "lwscratch:cmd_cond_counter_less",
	["CG"] = "lwscratch:cmd_cond_counter_even",
	["CH"] = "lwscratch:cmd_cond_counter_odd",
	["CI"] = "lwscratch:cmd_cond_value_equal",
	["CJ"] = "lwscratch:cmd_cond_value_greater",
	["CK"] = "lwscratch:cmd_cond_value_less",
	["CL"] = "lwscratch:cmd_cond_value_even",
	["CM"] = "lwscratch:cmd_cond_value_odd",
	["CN"] = "lwscratch:cmd_cond_contains",
	["CO"] = "lwscratch:cmd_cond_fits",
	["CP"] = "lwscratch:cmd_cond_detect_front",
	["CQ"] = "lwscratch:cmd_cond_detect_front_down",
	["CR"] = "lwscratch:cmd_cond_detect_front_up",
	["CS"] = "lwscratch:cmd_cond_detect_back",
	["CT"] = "lwscratch:cmd_cond_detect_back_down",
	["CU"] = "lwscratch:cmd_cond_detect_back_up",
	["CV"] = "lwscratch:cmd_cond_detect_down",
	["CW"] = "lwscratch:cmd_cond_detect_up",
	["ZX"] = "itemstack",
	["ZZ"] = "",
}



function utils.encode_program (inv)
	local code = ""
	local rdata = { }

	for i = 1, utils.program_inv_size do
		local stack = inv:get_stack ("program", i)

		if stack and not stack:is_empty () then
			local c = encode_cmd[stack:get_name ()]

			if not c then
				-- itemstack
				c = "ZX"
			end

			if utils.is_value_item (stack:get_name ()) or
				utils.is_action_value_item (stack:get_name ()) or
				utils.is_condition_value_item (stack:get_name ()) then

				rdata[#rdata + 1] = stack:get_meta ():get_string ("value")

			elseif utils.is_inventory_item (stack:get_name ()) then
				rdata[#rdata + 1] = stack:to_string ()

			end

			code = code..c
		else
			code = code.."ZZ"
		end
	end

	return { code = code, rdata = rdata }
end



function utils.dencode_program (inv, encoded)
	if encoded then
		local code = encoded.code
		local rdata = encoded.rdata
		local rdata_idx = 1

		for i = 1, utils.program_inv_size do
			local c = code:sub (((i - 1) * 2) + 1, ((i - 1) * 2) + 2)
			local name = dencode_cmd[c]
			local stack

			if name == "itemstack" then
				stack = ItemStack (rdata[rdata_idx])
				rdata_idx = rdata_idx + 1

			else
				stack = ItemStack (name)

				if utils.is_value_item (stack:get_name ()) or
					utils.is_action_value_item (stack:get_name ()) or
					utils.is_condition_value_item (stack:get_name ()) then

					stack:get_meta ():set_string ("value", rdata[rdata_idx])
					stack:get_meta ():set_string ("description", rdata[rdata_idx])
					rdata_idx = rdata_idx + 1
				end
			end

			inv:set_stack ("program", i, stack)
		end
	end
end



--
