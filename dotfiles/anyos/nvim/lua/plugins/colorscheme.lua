-- Colorscheme: Neovim's built-in default (see :help dev_theme).
-- The github-theme plugin stays installed, so <leader>uC can still preview
-- github_dark_default and the other alternatives live.
return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    opts = {},
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "default",
    },
  },
}
