-- One set of keys moves between Neovim windows and tmux panes: once there
-- is no window further in that direction, the move goes on to the next tmux
-- pane (smart-splits with its tmux backend; tmux.conf has the other half).
--
-- Alt+Left/Right move left/right, like Alt+arrows between tmux panes.
-- Alt+Up/Down stay Move Line Up/Down (keymaps.lua), so Ctrl+J/K move down/up
-- instead, as LazyVim's Ctrl+J/K did, now on into tmux panes too.
--
-- Not lazy loaded: the backend tells tmux that the pane runs Neovim (the
-- pane option @pane-is-vim) when it loads, and until then tmux keeps
-- Alt+Left/Right for itself.
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
      { "<A-Left>", move("left"), mode = { "n", "i", "t" }, desc = "Go to Left Window or Pane" },
      { "<A-Right>", move("right"), mode = { "n", "i", "t" }, desc = "Go to Right Window or Pane" },
      { "<C-j>", move("down"), desc = "Go to Lower Window or Pane" },
      { "<C-k>", move("up"), desc = "Go to Upper Window or Pane" },
    },
  },
}
