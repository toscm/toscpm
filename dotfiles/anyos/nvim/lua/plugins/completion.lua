-- Completion menu only on request in prose filetypes.
--
-- blink.cmp's buffer source suggests words from the open file on nearly
-- every keystroke, which is noise when writing markdown or plain text.
-- auto_show accepts a function evaluated per completion context, so the
-- menu stays hidden in these filetypes but still opens on demand: the
-- manual "show" command forces the menu regardless of auto_show. <A-\>
-- mirrors the VS Code binding; LazyVim's <C-Space> keeps working too.
-- Code filetypes are unaffected.
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
    },
  },
}
