-- R Markdown and Quarto files are parsed with the markdown parser. Neovim
-- gives them the filetypes rmd and quarto, and neither maps to a parser by
-- default, so LazyVim's FileType hook found none and left them to Vim's
-- regex syntax (no treesitter highlighting, folds or textobjects).
--
-- The markdown grammar reads the language of a ```{r setup, echo=FALSE}
-- chunk header as plain "r" (braces and options are dropped), so the stock
-- markdown injection query already hands each chunk to the parser of its
-- language; it only needs the r parser to be installed. markdown_inline
-- (prose) and yaml (front matter) come with LazyVim.
--
-- The registration happens in init, before any file is opened, since the
-- FileType event for the first buffer fires before the plugin loads.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "r" } },
    init = function()
      vim.treesitter.language.register("markdown", { "rmd", "quarto" })
    end,
  },
}
