-- Alt-Z cycles word wrap through three states, mirroring the word wrap
-- status bar item vstosc adds to VS Code: off -> on (wrap at the window
-- edge) -> bounded at a column -> off.
--
-- The bounded state is not native: Vim only soft-wraps at the window edge,
-- and 'textwidth' would hard-wrap by inserting real newlines. The wrapwidth
-- plugin fills the gap by wrapping virtually at a column via inline virtual
-- text, without touching the buffer.
--
-- Mid-word breaking is intentional: 'linebreak' stays off (its default), so
-- wrapped lines break at the last screen cell rather than at word
-- boundaries.
--
-- The current state is shown in lualine as "Wrap: off", "Wrap: on" or
-- "Wrap: <column>", like vstosc's status bar item. The lualine component and
-- the toggle share the buffer-local wrap_bounded variable, so the display
-- cannot drift from the actual state. Note the mixed scopes: 'wrap' is
-- window-local while :Wrapwidth is buffer-local, which is harmless as long
-- as a buffer is shown in one window at a time.

local wrap_col = 80

return {
  {
    "rickhowe/wrapwidth",
    keys = {
      {
        "<A-z>",
        function()
          if not vim.wo.wrap then -- off -> on
            vim.b.wrap_bounded = nil
            vim.wo.wrap = true
          elseif not vim.b.wrap_bounded then -- on -> bounded
            vim.b.wrap_bounded = wrap_col
            vim.cmd("Wrapwidth " .. wrap_col)
          else -- bounded -> off
            vim.b.wrap_bounded = nil
            vim.cmd("Wrapwidth 0")
            vim.wo.wrap = false
          end
        end,
        desc = "Cycle word wrap: off / on / bounded",
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 1, {
        function()
          if not vim.wo.wrap then
            return "Wrap: off"
          end
          return vim.b.wrap_bounded and ("Wrap: " .. vim.b.wrap_bounded) or "Wrap: on"
        end,
      })
    end,
  },
}
