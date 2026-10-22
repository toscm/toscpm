-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Command palette, as in VS Code: keymaps and ":" commands with their
-- descriptions (see lua/config/palette.lua). LazyVim's keymap picker is on
-- <leader>sk; Ctrl+Shift+P (as in VS Code), F1 (which otherwise opens :help)
-- and <leader>p open this one. Ctrl+Shift+P only reaches nvim through a
-- terminal that reports extended keys (see tmux.conf) and does not keep the
-- key for itself (Windows Terminal opens its own command palette on it by
-- default); elsewhere it arrives as Ctrl+P and opens a file instead.
local palette = require("config.palette")
vim.keymap.set({ "n", "v", "i" }, "<C-S-p>", palette, { desc = "Command Palette" })
vim.keymap.set({ "n", "v", "i" }, "<F1>", palette, { desc = "Command Palette" })
vim.keymap.set("n", "<leader>p", palette, { desc = "Command Palette" })

-- y and Ctrl+C on a Visual selection (from the mouse or Shift+arrows) copy it
-- to the system clipboard. Without a selection Ctrl+C keeps its usual meaning.
vim.keymap.set("x", "y", '"+y', { desc = "Copy selection to clipboard" })
vim.keymap.set("x", "<C-c>", '"+y', { desc = "Copy selection to clipboard" })

-- Alt+Up/Down move lines like LazyVim's Alt+j/k, in Normal, Insert and Visual
-- mode. remap so they follow whatever Alt+j/k are bound to.
vim.keymap.set({ "n", "i", "v" }, "<A-Down>", "<A-j>", { remap = true, desc = "Move Down" })
vim.keymap.set({ "n", "i", "v" }, "<A-Up>", "<A-k>", { remap = true, desc = "Move Up" })

-- Up/Down in Insert mode move by screen line through wrapped lines, like
-- LazyVim's j/k/Up/Down already do in Normal and Visual mode. blink.cmp's
-- menu mappings take precedence while the completion menu is open.
vim.keymap.set("i", "<Down>", "<C-o>gj", { desc = "Down" })
vim.keymap.set("i", "<Up>", "<C-o>gk", { desc = "Up" })

-- Editing keys work in Normal mode as in Insert mode, without leaving
-- Normal mode, as in VS Code: Backspace and Delete delete (joining lines at
-- the start or end of one), Enter splits the line and Tab indents at the
-- cursor. 'virtualedit' "onemore" (options.lua) lets the cursor sit just
-- past the last character, where Enter opens a new line and Delete joins
-- the next one. Deleted text goes to the black-hole register, so it does
-- not replace the last yank. Space is left alone: it is LazyVim's leader.
--
-- In buffers that cannot be edited (help, quickfix, terminal, plugin UIs)
-- the keys keep their built-in meaning; plugins' own buffer-local mappings
-- take precedence anyway. Tab is the same key as Ctrl+I (jump forward in the
-- jump list) in most terminals, so that is only reachable in such buffers.
local function editable()
  return vim.bo.modifiable and vim.bo.buftype == ""
end

local function edit_key(key, desc, fn)
  vim.keymap.set("n", key, function()
    if editable() then
      fn()
    else
      local count = vim.v.count > 0 and vim.v.count or ""
      vim.api.nvim_feedkeys(count .. vim.keycode(key), "n", false)
    end
  end, { desc = desc })
end

-- Types keys as in Insert mode and comes back to Normal mode with the cursor
-- on the character it was on, which an extmark follows through the edit
-- (plain Esc would leave it one column to the left of that).
local ns = vim.api.nvim_create_namespace("normal_mode_typing")
local function type_keys(keys)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local mark = vim.api.nvim_buf_set_extmark(0, ns, row - 1, col, {})
  vim.cmd("normal! i" .. keys)
  local pos = vim.api.nvim_buf_get_extmark_by_id(0, ns, mark, {})
  vim.api.nvim_buf_del_extmark(0, ns, mark)
  vim.api.nvim_win_set_cursor(0, { pos[1] + 1, pos[2] })
end

-- Joins line `row` (1-based) with the next one, like Delete at the end of a
-- line in Insert mode (no space inserted, whitespace kept).
local function join_next(row)
  local len = #vim.fn.getline(row)
  vim.api.nvim_buf_set_text(0, row - 1, len, row, 0, {})
  vim.api.nvim_win_set_cursor(0, { row, len })
end

edit_key("<BS>", "Delete Backwards", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if col > 0 then
    vim.cmd("normal! " .. vim.v.count1 .. '"_X')
  elseif row > 1 then
    join_next(row - 1)
  end
end)

edit_key("<Del>", "Delete", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if col >= #vim.fn.getline(row) then
    if row < vim.fn.line("$") then
      join_next(row)
    end
  else
    vim.cmd("normal! " .. vim.v.count1 .. '"_x')
  end
end)

edit_key("<CR>", "Split Line", function()
  type_keys("\r")
end)

edit_key("<Tab>", "Indent at Cursor", function()
  type_keys("\t")
end)

vim.keymap.set("x", "<BS>", '"_d', { desc = "Delete Selection" })
vim.keymap.set("x", "<Del>", '"_d', { desc = "Delete Selection" })

-- The first Shift+arrow only starts Visual mode on the character under the
-- cursor (the bar cursor of Visual mode, see 'guicursor' in options.lua,
-- shows it as selected); further Shift+arrows extend the selection
-- ('keymodel' "startsel"). In Insert mode the selection starts at the
-- character after the cursor and Esc returns to Insert mode.
for _, key in ipairs({ "<S-Left>", "<S-Right>", "<S-Up>", "<S-Down>" }) do
  vim.keymap.set("n", key, "v", { desc = "Start Selection" })
  vim.keymap.set("i", key, "<C-o>v", { desc = "Start Selection" })
end

-- Esc in Normal mode also dismisses all notifications (see
-- lua/plugins/notifier.lua), on top of what LazyVim's Esc does: clear the
-- search highlight and stop the active snippet. The hiding is scheduled
-- because an expr mapping may not close windows (textlock).
vim.keymap.set("n", "<esc>", function()
  vim.cmd("noh")
  LazyVim.cmp.actions.snippet_stop()
  vim.schedule(function()
    Snacks.notifier.hide()
  end)
  return "<esc>"
end, { expr = true, desc = "Escape, Clear hlsearch and Notifications" })

-- Ctrl+S saves without leaving the current mode; LazyVim's version appends
-- <esc>, which drops back to Normal mode.
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr>", { desc = "Save File" })

-- More VS Code bindings. Ctrl+Shift+letter, Ctrl+Enter, Ctrl+. and Ctrl+`
-- only reach nvim if the terminal reports them (kitty keyboard protocol or
-- Windows Terminal); elsewhere they arrive as a plainer key or not at all,
-- and the Vim/LazyVim equivalent named in the comment still works.
local map = vim.keymap.set

-- Ctrl+Backspace / Ctrl+Delete delete a word backwards / forwards, joining
-- lines at the start / end of one. Windows Terminal sends Ctrl+Backspace as
-- Ctrl+H, hence the Insert-mode <C-h> (in Normal mode Ctrl+H stays LazyVim's
-- go-to-left-window).
map("i", "<C-BS>", "<C-w>", { desc = "Delete Word Backwards" })
map("i", "<C-h>", "<C-w>", { desc = "Delete Word Backwards" })
map("i", "<C-Del>", function()
  return vim.fn.col(".") > #vim.fn.getline(".") and "<Del>" or '<C-o>"_dw'
end, { expr = true, desc = "Delete Word" })
map("n", "<C-BS>", '"_db', { desc = "Delete Word Backwards" })
map("n", "<C-Del>", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if col >= #vim.fn.getline(row) and row < vim.fn.line("$") then
    join_next(row)
  else
    vim.cmd('normal! "_dw')
  end
end, { desc = "Delete Word" })

-- Ctrl+Left/Right and Ctrl+H/L move by word (b / w), as Ctrl+Left/Right do
-- in VS Code. LazyVim had Ctrl+Left/Right resize the window and Ctrl+H/L go
-- to the window on the left/right; Ctrl+W h/l still do that. In Insert mode
-- Ctrl+Left/Right already move by word, Ctrl+L follows them and Ctrl+H stays
-- Delete Word Backwards (Ctrl+Backspace in Windows Terminal, see above).
map({ "n", "x" }, "<C-Left>", "b", { desc = "Word Backwards" })
map({ "n", "x" }, "<C-Right>", "w", { desc = "Word Forwards" })
map({ "n", "x" }, "<C-h>", "b", { desc = "Word Backwards" })
map({ "n", "x" }, "<C-l>", "w", { desc = "Word Forwards" })
map("i", "<C-l>", "<C-Right>", { desc = "Word Forwards" })

-- Ctrl+/ toggles a comment (gcc / gc); terminals send it as Ctrl+_ too.
-- LazyVim had it open the terminal, which moves to Ctrl+` (and stays on
-- <leader>ft); inside the terminal Ctrl+/ still hides it again.
for _, key in ipairs({ "<C-/>", "<C-_>" }) do
  map("n", key, "gcc", { remap = true, desc = "Toggle Comment" })
  map("x", key, "gcgv", { remap = true, desc = "Toggle Comment" })
  map("i", key, "<C-o>gcc", { remap = true, desc = "Toggle Comment" })
end
map({ "n", "t" }, "<C-`>", function()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })

-- Ctrl+P opens a file (<leader><space>), Ctrl+Shift+F searches all files
-- (<leader>/). The command palette is on Ctrl+Shift+P and F1 (see the top
-- of this file).
map("n", "<C-p>", LazyVim.pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<C-S-f>", LazyVim.pick("live_grep"), { desc = "Grep (Root Dir)" })

-- LSP: F2 renames (<leader>cr), F12 goes to the definition (gd), Shift+F12
-- lists references (gr; some terminals send it as F24), Ctrl+. shows code
-- actions (<leader>ca).
map("n", "<F2>", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<F12>", "gd", { remap = true, desc = "Goto Definition" })
map("n", "<S-F12>", "gr", { remap = true, desc = "References" })
map("n", "<F24>", "gr", { remap = true, desc = "References" })
map({ "n", "x" }, "<C-.>", vim.lsp.buf.code_action, { desc = "Code Action" })

-- Shift+Alt+Up/Down duplicate the line or the selected lines; the cursor or
-- selection goes to the copy, as in VS Code.
map({ "n", "i" }, "<M-S-Down>", "<cmd>t.<cr>", { desc = "Duplicate Line Down" })
map({ "n", "i" }, "<M-S-Up>", "<cmd>t-1<cr>", { desc = "Duplicate Line Up" })
map("x", "<M-S-Down>", ":<C-u>'<,'>t'><cr>'[V']", { silent = true, desc = "Duplicate Lines Down" })
map("x", "<M-S-Up>", ":<C-u>'<,'>t'<-1<cr>'[V']", { silent = true, desc = "Duplicate Lines Up" })

-- Ctrl+Shift+K deletes the line or the selected lines (dd).
map("n", "<C-S-k>", '"_dd', { desc = "Delete Line" })
map("i", "<C-S-k>", '<cmd>normal! "_dd<cr>', { desc = "Delete Line" })
map("x", "<C-S-k>", ":<C-u>'<,'>d _<cr>", { silent = true, desc = "Delete Lines" })

-- Ctrl+Enter / Ctrl+Shift+Enter open a line below / above without
-- splitting the current one; Normal mode stays Normal mode.
map("n", "<C-CR>", "<cmd>call append(line('.'), '')<cr>j", { desc = "New Line Below" })
map("n", "<C-S-CR>", "<cmd>call append(line('.') - 1, '')<cr>k", { desc = "New Line Above" })
map("i", "<C-CR>", "<C-o>o", { desc = "New Line Below" })
map("i", "<C-S-CR>", "<C-o>O", { desc = "New Line Above" })

-- Tab / Shift+Tab indent / unindent the selection (keeping it); Shift+Tab
-- unindents the line in Normal and Insert mode (in Insert mode blink.cmp's
-- snippet jumps come first while a snippet is active).
map("x", "<Tab>", ">gv", { desc = "Indent" })
map("x", "<S-Tab>", "<gv", { desc = "Unindent" })
map("n", "<S-Tab>", "<<", { desc = "Unindent" })
map("i", "<S-Tab>", "<C-d>", { desc = "Unindent" })

-- Ctrl+Z undoes, Ctrl+Y and Ctrl+Shift+Z redo, Ctrl+A selects everything.
-- They replace Vim's Ctrl+Z (suspend), Ctrl+Y (scroll a line) and Ctrl+A
-- (increment; Ctrl+X still decrements, g Ctrl+A increments a selection).
map("n", "<C-z>", "u", { desc = "Undo" })
map("n", "<C-y>", "<C-r>", { desc = "Redo" })
map("n", "<C-S-z>", "<C-r>", { desc = "Redo" })
map("i", "<C-z>", "<C-o>u", { desc = "Undo" })
map("i", "<C-y>", "<C-o><C-r>", { desc = "Redo" })
map("i", "<C-S-z>", "<C-o><C-r>", { desc = "Redo" })
map("x", "<C-z>", "<Esc>u", { desc = "Undo" })
map("n", "<C-a>", "ggVG", { desc = "Select All" })
map({ "i", "x" }, "<C-a>", "<Esc>ggVG", { desc = "Select All" })

-- :KeyTest shows each key the way Neovim receives it, e.g. <C-S-P>, without
-- running any mapping; q quits. Whether Ctrl+Shift+P arrives as <C-S-P> or
-- only as <C-P> shows whether extended keys work through every layer
-- (terminal, ssh, tmux), see the extended keys in tmux.conf.
vim.api.nvim_create_user_command("KeyTest", function()
  local seen = {}
  while true do
    vim.api.nvim_echo({ { "KeyTest (q quits): " .. table.concat(seen, " ") } }, false, {})
    vim.cmd.redraw()
    local key = vim.fn.keytrans(vim.fn.getcharstr())
    if key == "q" then
      break
    end
    table.insert(seen, key)
    if #seen > 12 then
      table.remove(seen, 1)
    end
  end
  vim.api.nvim_echo({ { "" } }, false, {})
end, { desc = "Show the keys Neovim receives (q quits)" })
