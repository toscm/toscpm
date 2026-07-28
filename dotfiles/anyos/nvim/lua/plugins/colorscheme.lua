-- Colorscheme: GitHub Dark Default (background #0d1117), the same theme I
-- use in VS Code. Browse the alternatives with <leader>uC (live preview).
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
