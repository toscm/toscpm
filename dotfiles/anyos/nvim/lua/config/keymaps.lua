-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Command palette, as in VS Code: a picker over every keymap with its
-- description, Enter runs it. LazyVim binds it to <leader>sk; F1 (which
-- otherwise opens :help) and <leader>p make it quicker to reach.
local function palette()
  Snacks.picker.keymaps()
end
vim.keymap.set({ "n", "v" }, "<F1>", palette, { desc = "Command Palette" })
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

-- Backspace deletes backwards in Normal and Visual mode too (it is only a
-- left motion there by default). In Normal mode it deletes the character
-- before the cursor ("X"), and in column 1 it joins the line onto the
-- previous one, as in Insert mode. Deleted text goes to the black-hole
-- register, so it does not replace the last yank.
vim.keymap.set("n", "<BS>", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if col > 0 then
    vim.cmd('normal! ' .. vim.v.count1 .. '"_X')
  elseif row > 1 then
    local join = #vim.fn.getline(row - 1)
    vim.cmd("normal! kgJ")
    vim.api.nvim_win_set_cursor(0, { row - 1, join })
  end
end, { desc = "Delete Backwards" })
vim.keymap.set("x", "<BS>", '"_d', { desc = "Delete Selection" })

-- Ctrl+S saves without leaving the current mode; LazyVim's version appends
-- <esc>, which drops back to Normal mode.
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr>", { desc = "Save File" })
