-- Colorscheme: github_dark_default from the github-theme plugin, which is
-- loaded eagerly (lazy = false, high priority) so it is in place before the
-- first buffer is drawn. <leader>uC previews the other installed schemes,
-- Neovim's built-in default (see :help dev_theme) among them, but only for
-- the running session; this file is what makes a choice stick.
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
      colorscheme = "github_dark_default",
    },
  },
}
