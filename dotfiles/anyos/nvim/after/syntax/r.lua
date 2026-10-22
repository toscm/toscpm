-- Roxygen colours on top of Vim's R syntax (syntax/r.vim, used because no R
-- tree-sitter parser is installed): the tags such as @param keep their
-- colour, the title is bold in comment colour instead of blue like the tags,
-- the examples are in comment colour instead of normal text colour (which
-- made it hard to see where they end and the code starts), and the argument
-- names after @param and @field get the orange of Type, as GitHub shows
-- parameters.
--
-- The R language server (plugins/r.lua) marks every comment as a semantic
-- token of type comment, whose highlight is drawn on top of the syntax and
-- painted the whole roxygen block in comment colour; with that group empty
-- the syntax colours show through.
--
-- A colorscheme switch (see plugins/colorscheme.lua) clears these, so they
-- are set again on every ColorScheme event.
vim.cmd([[syn match rOParamName contained containedin=rOBlock,rOBlockNoTitle,rOR6Block "\(@\(param\|field\)\s\+\)\@<=\S\+"]])

local function set_hl()
  local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  local title = vim.tbl_extend("force", comment, { bold = true })
  vim.api.nvim_set_hl(0, "rOTitle", title)
  vim.api.nvim_set_hl(0, "rOTitleBlock", title)
  vim.api.nvim_set_hl(0, "rOExamples", { link = "Comment" })
  vim.api.nvim_set_hl(0, "rOParamName", { link = "Type" })
  vim.api.nvim_set_hl(0, "@lsp.type.comment.r", {})
end

set_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("roxygen_colours", { clear = true }),
  callback = set_hl,
})
