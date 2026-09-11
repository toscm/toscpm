-- Alt-Z cycles word wrap through three states, mirroring the word wrap
-- status bar item vstosc adds to VS Code: off -> on (wrap at the window
-- edge) -> bounded at a column -> off.
--
-- The state logic lives in lua/config/wrap.lua, shared with the clickable
-- statusline item, and the wrapwidth plugin provides the bounded state (see
-- that file for the details).
return {
  {
    "rickhowe/wrapwidth",
    keys = {
      {
        "<A-z>",
        function()
          require("config.wrap").cycle()
        end,
        desc = "Cycle word wrap: off / on / bounded",
      },
    },
  },
}
