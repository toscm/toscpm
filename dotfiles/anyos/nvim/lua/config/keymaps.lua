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
