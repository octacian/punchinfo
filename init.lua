-- punchinfo/init.lua

punchinfo = {}

-- [get] settings

local hud_show_time = minetest.setting_get("punchinfo.hud_show_time") or 2

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

-- [event] on_punchnode
minetest.register_on_punchnode(function(pos, node, player, pointed_thing)
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

  -- [hud] background image
  local image = punchinfo.show_hud(player, {
    hud_elem_type = "image",
    position = { x = 0.5, y = 0.03 },
    scale = { x = -79, y = -25 },
    text = "punchinfo_hud.png",
  })

  -- [hud] desc
  local desc = punchinfo.show_hud(player, {
    hud_elem_type = "text",
    position = { x = 0.5, y = 0.03 },
    scale = { x = -26, y = -12 },
    text = nodedef.description.." ("..node.name..")"
  })

  -- [hud] texture
  local texture = punchinfo.show_hud(player, {
    hud_elem_type = "image",
    position = { x = 0.18, y = 0.06 },
    scale = { x = 4.5, y = 4.5 },
    text = tile,
  })

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

  -- [hud] groups
  local groups = punchinfo.show_hud(player, {
    hud_elem_type = "text",
    position = { x = 0.5, y = 0.12 },
    scale = { x = -26, y = -12 },
    text = "Groups: { "..groups.."}",
  })

  -- [after] remove hud elems
  minetest.after(hud_show_time, function()
    punchinfo.hide_huds(player)
  end)
end)
