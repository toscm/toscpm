-- No lualine. Its six coloured sections, powerline separators and nerd-font
-- icons are more than this setup needs; the plain native statusline in
-- lua/config/statusline.lua shows the same information in one colour.
return {
  { "nvim-lualine/lualine.nvim", enabled = false },
}
