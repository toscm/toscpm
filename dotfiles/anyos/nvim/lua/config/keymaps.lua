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
