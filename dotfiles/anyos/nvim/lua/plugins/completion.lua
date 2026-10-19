-- Completion menu behaviour: only on request in prose filetypes, and
-- selectable with the arrow keys on the command line.
--
-- blink.cmp's buffer source suggests words from the open file on nearly
-- every keystroke, which is noise when writing markdown or plain text.
-- auto_show accepts a function evaluated per completion context, so the
-- menu stays hidden in these filetypes but still opens on demand: the
-- manual "show" command (LazyVim's <C-Space>) forces the menu regardless of
-- auto_show. Code filetypes are unaffected.
--
-- On the command line LazyVim shows the menu for every ":" command, but
-- blink's "cmdline" keymap preset only binds <Tab>/<S-Tab> and <C-n>/<C-p>
-- to move through it, so the arrow keys do nothing there. <Up> and <Down>
-- are added here; "fallback" keeps their built-in meaning (recall the
-- previous or next command line starting with what is typed) whenever the
-- menu is not open. <Left> and <Right>, which the preset also binds to the
-- menu, stay disabled by LazyVim so they keep moving the cursor.
--
-- Copilot (LazyVim's ai.copilot extra, enabled in lazyvim.json) suggests
-- while typing in code but, like the menu, only on request in the prose
-- filetypes. <A-\> asks for a suggestion, as in VS Code; <Tab> accepts it,
-- <A-]>/<A-[> cycle through alternatives and <C-]> dismisses it. Sign in
-- once with :Copilot auth.
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
      cmdline = {
        keymap = {
          ["<Up>"] = { "select_prev", "fallback" },
          ["<Down>"] = { "select_next", "fallback" },
        },
      },
    },
  },

  {
    "zbirenbaum/copilot.lua",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = prose,
        callback = function()
          vim.b.copilot_suggestion_auto_trigger = false
        end,
      })
    end,
    keys = {
      {
        "<A-\\>",
        function()
          require("copilot.suggestion").next()
        end,
        mode = "i",
        desc = "Copilot suggestion",
      },
    },
  },
}
