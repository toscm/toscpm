-- No indent guides (Snacks.indent) in Markdown.
--
-- Snacks draws a vertical guide for every indent level and highlights the
-- one of the current scope. In Markdown, indentation means list nesting and
-- continuation lines rather than code blocks, so the lines mostly add noise.
-- The filter is the Snacks default plus the filetype check; it runs on every
-- redraw, so it also covers buffers that become Markdown later.
return {
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
        filter = function(buf)
          return vim.g.snacks_indent ~= false
            and vim.b[buf].snacks_indent ~= false
            and vim.bo[buf].buftype == ""
            and vim.bo[buf].filetype ~= "markdown"
        end,
      },
    },
  },
}
