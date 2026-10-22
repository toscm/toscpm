-- Ctrl+J/K go to the window below/above, as LazyVim's Ctrl+J/K did, and
-- past the last window on to the tmux pane below/above (smart-splits with
-- its tmux backend, which asks tmux to switch the pane itself, so tmux.conf
-- needs no bindings for it). Left/right: Ctrl+W h/l, or Ctrl+W p back and
-- forth between the explorer and the file; Alt+Left/Right go back/forward
-- (keymaps.lua).
--
-- Not lazy loaded: the backend tells tmux that the pane runs Neovim (the
-- pane option @pane-is-vim) when it loads.
local function move(dir)
  return function()
    require("smart-splits")["move_cursor_" .. dir]()
  end
end

return {
  {
    "smart-splits-nvim/smart-splits.nvim",
    version = "^3.0.0",
    lazy = false,
    dependencies = {
      { "smart-splits-nvim/backend-tmux", main = "smart-splits-backend-tmux", opts = {} },
    },
    opts = {
      mux = { backend = "smart-splits-backend-tmux", warn_if_unusable = false },
    },
    keys = {
      { "<C-j>", move("down"), desc = "Go to Lower Window or Pane" },
      { "<C-k>", move("up"), desc = "Go to Upper Window or Pane" },
    },
  },
}
