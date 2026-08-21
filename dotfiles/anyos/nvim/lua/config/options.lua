-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable SpellCap (capitalization check) globally — keeps SpellBad (real
-- misspellings) but stops flagging lowercase words after abbreviations like
-- "incl.", "e.g.". Toggle back per-buffer with :setlocal spellcapcheck&
vim.opt.spellcapcheck = ""

-- Spell checking off by default (see also lua/config/autocmds.lua, which drops
-- LazyVim's autocmd enabling it for text filetypes). Toggle per buffer with
-- <leader>us, or :setlocal spell.
vim.opt.spell = false
