-- Completion menu behaviour: only on request in prose filetypes, and
-- selectable with the arrow keys on the command line.
--
-- blink.cmp's buffer source suggests words from the open file on nearly
-- every keystroke, which is noise when writing markdown or plain text.
-- auto_show accepts a function evaluated per completion context, so the
-- menu stays hidden in these filetypes but still opens on demand: the
-- manual "show" command forces the menu regardless of auto_show. <A-\>
-- mirrors the VS Code binding; LazyVim's <C-Space> keeps working too.
-- Code filetypes are unaffected.
--
-- On the command line LazyVim shows the menu for every ":" command, but
-- blink's "cmdline" keymap preset only binds <Tab>/<S-Tab> and <C-n>/<C-p>
-- to move through it, so the arrow keys do nothing there. <Up> and <Down>
-- are added here; "fallback" keeps their built-in meaning (recall the
-- previous or next command line starting with what is typed) whenever the
-- menu is not open. <Left> and <Right>, which the preset also binds to the
-- menu, stay disabled by LazyVim so they keep moving the cursor.
local prose = { "markdown", "text", "gitcommit" }

return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = {
          auto_show = function(ctx)
            return not vim.tbl_contains(prose, vim.bo[ctx.bufnr].filetype)
          end,
        },
      },
      keymap = {
        ["<A-\\>"] = { "show", "fallback" },
      },
      cmdline = {
        keymap = {
          ["<Up>"] = { "select_prev", "fallback" },
          ["<Down>"] = { "select_next", "fallback" },
        },
      },
    },
  },
}
