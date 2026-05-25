vim.opt.textwidth = 80

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "markdown", "markdown_inline", "latex", "r", "lua" },
        highlight = { enable = true },
      })
    end,
  },
})
vim.keymap.set({'n', 'v'}, '<A-q>', 'gqap', { desc = 'Reformat paragraph' })

-- Shift+Arrow: character/line selection
vim.keymap.set('n', '<S-Left>',    'vh',  { desc = 'Select left' })
vim.keymap.set('n', '<S-Right>',   'vl',  { desc = 'Select right' })
vim.keymap.set('n', '<S-Up>',      'vk',  { desc = 'Select up' })
vim.keymap.set('n', '<S-Down>',    'vj',  { desc = 'Select down' })
vim.keymap.set('v', '<S-Left>',    'h',   { desc = 'Extend left' })
vim.keymap.set('v', '<S-Right>',   'l',   { desc = 'Extend right' })
vim.keymap.set('v', '<S-Up>',      'k',   { desc = 'Extend up' })
vim.keymap.set('v', '<S-Down>',    'j',   { desc = 'Extend down' })

-- Ctrl+Shift+Arrow: word/paragraph selection
vim.keymap.set('n', '<C-S-Left>',  'vb',  { desc = 'Select word left' })
vim.keymap.set('n', '<C-S-Right>', 'vw',  { desc = 'Select word right' })
vim.keymap.set('n', '<C-S-Up>',    'v{',  { desc = 'Select paragraph up' })
vim.keymap.set('n', '<C-S-Down>',  'v}',  { desc = 'Select paragraph down' })
vim.keymap.set('v', '<C-S-Left>',  'b',   { desc = 'Extend word left' })
vim.keymap.set('v', '<C-S-Right>', 'w',   { desc = 'Extend word right' })
vim.keymap.set('v', '<C-S-Up>',    '{',   { desc = 'Extend paragraph up' })
vim.keymap.set('v', '<C-S-Down>',  '}',   { desc = 'Extend paragraph down' })

-- Forward delete (Fn+Delete on macOS = Windows Del key)
vim.keymap.set('n', '<Del>', 'x', { desc = 'Delete char under cursor' })
