![Screenshot](screenshot.png)

Node Information on_punch [punchinfo]
=======================================
* Licence: Code: MIT (see LICENSE), Media: CC-BY-SA 3.0
* [GitHub Repository](https://github.com/octacian/punchinfo)
* [Issue Tracker](https://github.com/octacian/punchinfo/issues)
* Dependencies: None.

This is another fairly simple utility mod, but it can serve a very useful purpose. PunchInfo was originally inspired by [azekill_DIABLO's NodeExploror mod](https://forum.minetest.net/viewtopic.php?f=9&t=15565). However, NodeExplorer was missing several features, and since it wasn't on GitHub, I decided to start over from scratch.

The concept of PunchInfo is very simple, whenever a player left-clicks (i.e. punches) a node, information about that node is shown. This information includes the description, itemstring, top texture, light emission level, drawtype, and groups. The HUD is removed after 2 seconds (configurable in `minetest.conf` with `punchnode.hud_show_time`, integer).

If you find the HUD to be too big, it can be configured to one of three sizes in `minetest.conf` with `punchnode.hud_size`. The HUD size can be set to one of three integer, `1`, `2`, or `3` (`2` is default).

### Chatcommand
The HUD can be managed and customized per-player with the `/punchinfo` command. This single command accepts several parameters, as seen below.

| Parameter | Function |
| --------- | -------- |
| `clear` | Clears all information about the player (show time, size, etc...) |
| `get <key>` | Gets HUD information (e.g. size) |
| `enable` | Enables the PunchInfo HUD |
| `disable` | Disables the PunchInfo HUD |
| `time <integer>` | Sets the time before the HUD is hidden |
| `size <integer>` | Sets the HUD size to 1, 2, or 3 |