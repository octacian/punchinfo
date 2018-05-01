-- punchinfo/init.lua

punchinfo = {}

-- Configuration ---

local global_hud_show_time = tonumber(minetest.settings:get("punchinfo.hud_show_time")) or 2
local global_hud_size = tonumber(minetest.settings:get("punchinfo.hud_size")) or 2

----------------------
-- HELPER FUNCTIONS --
----------------------

local hud_contexts = {}

-- [function] show hud
function punchinfo.show_hud(player, set_id, hud)
	local id = player:hud_add(hud)
	local name = player:get_player_name()

	if not hud_contexts[name] then
		hud_contexts[name] = {}
	end

	if not hud_contexts[name][set_id] then
		hud_contexts[name][set_id] = {}
	end

	hud_contexts[name][set_id][#hud_contexts[name][set_id]+1] = id
	hud_contexts[name].current_id = set_id

	return id
end

-- [function] hide huds
function punchinfo.hide_huds(player, set_id)
	local name = player:get_player_name()
	local huds = hud_contexts[name] or {}

	if huds.current_id ~= set_id or not huds[set_id] then
		return
	end

	for _, id in pairs(huds[set_id]) do
		player:hud_remove(id)
	end

	hud_contexts[name][set_id] = nil
end

-- [local function] check if valid
local function is_valid(value, list)
	for _, v in pairs(list) do
		if value == v then
			return true
		end
	end
end

--------------------
----- [EVENTS] -----
--------------------

-- [event] on_punchnode
minetest.register_on_punchnode(function(pos, node, player)
	local name        = player:get_player_name()
	local meta        = player:get_meta()
	local huds        = hud_contexts[name]
	local hud_id      = 1
	local hud_show_time = meta:get_int("punchinfo.time")
	local hud_size    = meta:get_int("punchinfo.size")

	if hud_show_time == 0 then hud_show_time = global_hud_show_time end
	if hud_size == 0 then hud_size = global_hud_size end

	if meta:get_string("punchinfo.enabled") == "false" then
		return
	end

	if huds then
		if huds.current_id then
			hud_id = huds.current_id + 1
			punchinfo.hide_huds(player, huds.current_id)
		end
	end

	local nodedef = minetest.registered_nodes[node.name]   -- get nodedef

	local groups = ""
	for _, v in pairs(nodedef.groups) do
		groups = groups.._.."="..v..", "
	end

	local tile = nodedef.tiles[1]
	if type(tile) ~= "string" then
		tile = nodedef.inventory_image or ""
	else
		tile = tile.."^[resize:16x16"
	end

	local scale, groups_pos, texture_scale, texture_pos, desc_text
	if hud_size == 1 then
		scale = { x = -79, y = -25 }
	elseif hud_size == 2 then
		scale = { x = -45, y = -15 }
		groups_pos = { x = 0.5, y = 0.06 }
		texture_pos = { x = 0.32, y = 0.045 }
		texture_scale = { x = 2.5, y = 2.5 }
	elseif hud_size == 3 then
		scale = { x = -25, y = -7 }
		texture_pos = { x = 0.32, y = 0.045 }
		texture_scale = { x = 2.5, y = 2.5 }
		desc_text = nodedef.description
	end

	-- [hud] background image
	punchinfo.show_hud(player, hud_id, {
		hud_elem_type = "image",
		position = { x = 0.5, y = 0.03 },
		scale = scale or { x = -79, y = -25 },
		text = "punchinfo_hud.png",
	})

	-- [hud] desc
	punchinfo.show_hud(player, hud_id, {
		hud_elem_type = "text",
		position = { x = 0.5, y = 0.03 },
		scale = { x = -26, y = -12 },
		text = desc_text or nodedef.description.." ("..node.name..")"
	})

	if hud_size == 1 then
		-- [hud] light source
		punchinfo.show_hud(player, hud_id, {
			hud_elem_type = "text",
			position = { x = 0.5, y = 0.06 },
			scale = { x = -26, y = -12 },
			text = "Light Emission: "..nodedef.light_source or 0,
		})

		-- [hud] drawtype
		punchinfo.show_hud(player, hud_id, {
			hud_elem_type = "text",
			position = { x = 0.5, y = 0.09 },
			scale = { x = -26, y = -12 },
			text = "Drawtype: "..nodedef.drawtype or "normal",
		})
	end

	if hud_size == 1 or hud_size == 2 then
		-- [hud] texture
		punchinfo.show_hud(player, hud_id, {
			hud_elem_type = "image",
			position = texture_pos or { x = 0.18, y = 0.06 },
			scale = texture_scale or { x = 4.5, y = 4.5 },
			text = tile,
		})

		-- [hud] groups
		punchinfo.show_hud(player, hud_id, {
			hud_elem_type = "text",
			position = groups_pos or { x = 0.5, y = 0.12 },
			scale = { x = -26, y = -12 },
			text = "Groups: { "..groups.."}",
		})
	end

	-- [after] remove hud elems
	minetest.after(hud_show_time, function()
		punchinfo.hide_huds(player, hud_id)
	end)
end)

------------------
-- CHATCOMMANDS --
------------------

-- [command] punchinfo
minetest.register_chatcommand("punchinfo", {
	description = "Manage and customize PunchInfo settings",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local meta   = player:get_meta()
		param        = param:split(" ")

		if param[1] == "clear" then
			meta:set_string("punchinfo.enabled", nil)
			meta:set_int("punchinfo.time", 0)
			meta:set_int("punchinfo.size", 0)
			return true, "Cleared PunchInfo data (size, show time, etc...)"
		else
			if param[1] == "get" then
				if not param[2] then
					return false, "Missing Key Parameter"
				end

				local val = meta:to_table()["punchinfo."..param[2]] or "nil"
				return true, "PunchInfo: "..param[2].." = "..val
			elseif param[1] == "enable" then
				meta:set_string("punchinfo.enabled", "true")
				return true, "Enabled PunchInfo HUD"
			elseif param[1] == "disable" then
				meta:set_string("punchinfo.enabled", "false")
				return true, "Disabled PunchInfo HUD"
			elseif param[1] == "time" then
				local newtime = tonumber(param[2])

				if not newtime then
					return false, "Invalid time value (must be an integer)"
				elseif newtime <= 0 then
					return false, "Time value cannot be less than 1"
				end

				meta:set_int("punchinfo.time", newtime)
				return true, "Set HUD show time to "..param[2]
			elseif param[1] == "size" then
				local valid_sizes = { "1", "2", "3", }

				if is_valid(param[2], valid_sizes) then
					meta:set_int("punchinfo.size", param[2])
					return true, "Set PunchInfo HUD size to "..param[2]
				else
					return false, "Invalid Size (valid sizes: 1, 2, 3)"
				end
			else
				return false, "Invalid parameter"
			end
		end
	end
})
