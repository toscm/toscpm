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

-- Copilot (the ai.copilot extra, see lua/plugins/completion.lua) shows its
-- suggestions as inline ghost text accepted with <Tab>, as in VS Code,
-- instead of as items in blink.cmp's completion menu. This also turns off
-- blink's own ghost text preview of the selected menu item.
vim.g.ai_cmp = false

-- No plugin in this config is a remote plugin written in Node, Perl, Python
-- or Ruby, so the corresponding providers are never used. Disabling them
-- stops :checkhealth from warning about the missing host packages and skips
-- probing for them at startup.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- Shift+arrows start Visual mode (not Select mode, where typing replaces the
-- selection), so a following y yanks it. Without "stopsel" an unshifted arrow
-- extends the selection like hjkl instead of ending it; Esc ends it.
vim.opt.keymodel = { "startsel" }
vim.opt.selectmode = ""

-- An underline cursor in Visual mode, so the character under it shows the
-- selection highlight (with the default block cursor it looked unselected,
-- although it is part of the selection and gets deleted with it), and it
-- sits under the last selected character rather than before it, like a bar
-- cursor did, which made Right look as if it would select that character.
vim.opt.guicursor = "n-c-sm:block,v:hor20,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon500-blinkoff500-TermCursor"

-- Only explicit copies reach the system clipboard: "+y, or y / Ctrl+C on a
-- Visual selection (see keymaps.lua). LazyVim otherwise syncs every yank and
-- delete with it outside ssh.
vim.opt.clipboard = ""

-- Over ssh or inside tmux the clipboard is the outer terminal's, reached via
-- OSC 52 (tmux forwards it with set-clipboard on). Windows Terminal ignores
-- OSC 52 read requests, so "+p returns the last copy instead of waiting for a
-- reply; pasting from Windows works with the terminal's own Ctrl+V.
if vim.env.SSH_CONNECTION or vim.env.TMUX then
  local osc52 = require("vim.ui.clipboard.osc52")
  local last = {}
  local function copy(reg)
    local send = osc52.copy(reg)
    return function(lines, regtype)
      last[reg] = { lines, regtype }
      send(lines, regtype)
    end
  end
  local function paste(reg)
    return function()
      return last[reg] or {}
    end
  end
  vim.g.clipboard = {
    name = "osc52-copy",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste("+"), ["*"] = paste("*") },
  }
end

-- Moving left past the start of a line continues at the end of the previous
-- one, and right past the end at the start of the next, as in VS Code: for
-- the arrows (<,> in Normal/Visual, [,] in Insert mode) and h/l, besides the
-- default Backspace and Space (b,s). Operators are unaffected, so dl or yl at
-- the end of a line still stay on it. Word motions (b, w, Ctrl+Left/Right)
-- cross lines anyway.
vim.opt.whichwrap = "b,s,<,>,[,],h,l"

-- The cursor can rest one column past the end of a line, as in VS Code,
-- where Enter (keymaps.lua) opens a new line and Delete joins the next one.
-- "block" is LazyVim's default (free movement in Visual block mode).
vim.opt.virtualedit = "block,onemore"
