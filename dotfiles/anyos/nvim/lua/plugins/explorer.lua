-- Left/Right in the file explorer (Snacks.explorer) work like h/l: Right
-- opens a directory or file, Left closes the directory.
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  ["<Right>"] = "confirm",
                  ["<Left>"] = "explorer_close",
                },
              },
            },
          },
        },
      },
    },
  },
}
