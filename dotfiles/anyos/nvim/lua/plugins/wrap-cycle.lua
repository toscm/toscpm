-- Alt-Z cycles word wrap, extending the word wrap status bar item vstosc
-- adds to VS Code: off -> on (wrap at the window edge) -> bounded at 80
-- columns -> bounded at 66 columns -> off. Alt+Shift+Z toggles whether
-- wrapped lines break between words or within a word at exactly the wrap
-- column ('linebreak'). Neovim receives Alt+Shift+Z as <M-Z>, which is what
-- <A-S-z> maps.
--
-- The state logic lives in lua/config/wrap.lua, shared with the <leader>uw
-- toggles (lua/config/keymaps.lua) and the clickable lualine item, and the
-- wrapwidth plugin provides the bounded states (see that file for the
-- details). The which-key spec names the <leader>uw group.
return {
  {
    "rickhowe/wrapwidth",
    keys = {
      {
        "<A-z>",
        function()
          require("config.wrap").cycle()
        end,
        desc = "Cycle word wrap: off / on / 80 / 66",
      },
      {
        "<A-S-z>",
        function()
          require("config.wrap").toggles().linebreak:toggle()
        end,
        desc = "Toggle wrap between / within words",
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>uw", group = "wrap" },
      },
    },
  },
}
