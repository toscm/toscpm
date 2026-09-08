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

-- Absolute line numbers. LazyVim defaults to relativenumber = true, which
-- shows distances from the cursor instead of the line's own number; toggle
-- back per session with <leader>uL.
vim.opt.relativenumber = false

-- The Windows build of nvim never calls setlocale(LC_CTYPE, ""), so v:ctype
-- stays "C" unless LANG/LC_ALL is set, and :checkhealth reports "Locale does
-- not support UTF-8". nvim is UTF-8 internally regardless, so this only
-- sets the C runtime's ctype to a UTF-8 locale (UCRT understands the POSIX
-- name) and silences a false alarm. Elsewhere the locale comes from the
-- environment and is left alone.
if vim.fn.has("win32") == 1 then
  vim.cmd.language("ctype", "en_US.UTF-8")
end

-- No plugin in this config is a remote plugin written in Node, Perl, Python
-- or Ruby, so the corresponding providers are never used. Disabling them
-- stops :checkhealth from warning about the missing host packages and skips
-- probing for them at startup.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
