-- punchinfo/init.lua

punchinfo = {}

local path = minetest.get_worldpath().."/punchinfo.players"

------------------------
-- LOAD CONFIGURATION --
------------------------

local hud_show_time = minetest.setting_get("punchinfo.hud_show_time") or 2
local hud_size = minetest.setting_get("punchinfo.hud_size") or 2

local disabled_players = {}
local player_file = io.open(path, "r")

if player_file then
  disabled_players = minetest.deserialize(player_file:read("*all"))
end

----------------------
-- HELPER FUNCTIONS --
----------------------

local hud_contexts = {}

-- [function] show hud
function punchinfo.show_hud(player, hud)
  local id = player:hud_add(hud)
  local name = player:get_player_name()

  if not hud_contexts[name] then
    hud_contexts[name] = {}
  end

  hud_contexts[name][#hud_contexts[name]+1] = id

  return id
end

-- [function] hide huds
function punchinfo.hide_huds(player)
  local name = player:get_player_name()
  local huds = hud_contexts[name] or {}

  for _, id in pairs(huds) do
    player:hud_remove(id)
  end

  hud_contexts[name] = nil
end

--------------------
----- [EVENTS] -----
--------------------

-- [event] on_punchnode
minetest.register_on_punchnode(function(pos, node, player, pointed_thing)
  if disabled_players[player:get_player_name()] == false then
    return
  end

  punchinfo.hide_huds(player)

  local node    = minetest.get_node(pointed_thing.under) -- get node
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
  if hud_size == "1" then
    scale = { x = -79, y = -25 }
  elseif hud_size == "2" then
    scale = { x = -45, y = -15 }
    groups_pos = { x = 0.5, y = 0.06 }
    texture_pos = { x = 0.32, y = 0.045 }
    texture_scale = { x = 2.5, y = 2.5 }
  elseif hud_size == "3" then
    scale = { x = -25, y = -7 }
    texture_pos = { x = 0.32, y = 0.045 }
    texture_scale = { x = 2.5, y = 2.5 }
    desc_text = nodedef.description
  end

  -- [hud] background image
  local image = punchinfo.show_hud(player, {
    hud_elem_type = "image",
    position = { x = 0.5, y = 0.03 },
    scale = scale or { x = -79, y = -25 },
    text = "punchinfo_hud.png",
  })

  -- [hud] desc
  local desc = punchinfo.show_hud(player, {
    hud_elem_type = "text",
    position = { x = 0.5, y = 0.03 },
    scale = { x = -26, y = -12 },
    text = desc_text or nodedef.description.." ("..node.name..")"
  })

  if hud_size == "1" then
    -- [hud] light source
    local light = punchinfo.show_hud(player, {
      hud_elem_type = "text",
      position = { x = 0.5, y = 0.06 },
      scale = { x = -26, y = -12 },
      text = "Light Emission: "..nodedef.light_source or 0,
    })

    -- [hud] drawtype
    local drawtype = punchinfo.show_hud(player, {
      hud_elem_type = "text",
      position = { x = 0.5, y = 0.09 },
      scale = { x = -26, y = -12 },
      text = "Drawtype: "..nodedef.drawtype or "normal",
    })
  end

  if hud_size == "1" or hud_size == "2" then
    -- [hud] texture
    local texture = punchinfo.show_hud(player, {
      hud_elem_type = "image",
      position = texture_pos or { x = 0.18, y = 0.06 },
      scale = texture_scale or { x = 4.5, y = 4.5 },
      text = tile,
    })

    -- [hud] groups
    local groups = punchinfo.show_hud(player, {
      hud_elem_type = "text",
      position = groups_pos or { x = 0.5, y = 0.12 },
      scale = { x = -26, y = -12 },
      text = "Groups: { "..groups.."}",
    })
  end

  -- [after] remove hud elems
  minetest.after(hud_show_time, function()
    punchinfo.hide_huds(player)
  end)
end)

-- [event] on shutdown
minetest.register_on_shutdown(function()
  local f = io.open(path, "w")
  f:write(minetest.serialize(disabled_players))
end)

------------------
-- CHATCOMMANDS --
------------------

-- [command] punchinfo
minetest.register_chatcommand("punchinfo", {
  description = "Enable or disable punchinfo HUD",
  params = "<true/false> | enable/disable",
  func = function(name, param)
    if param == "true" then
      disabled_players[name] = true
      return true, "Enabled PunchInfo HUD"
    elseif param == "false" then
      disabled_players[name] = false
      return true, "Disabled PunchInfo HUD"
    else
      return false, "Invalid parameter"
    end
  end
})
