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
