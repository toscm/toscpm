-- No inlay hints (the grey parameter names and types the language server
-- puts into the code). LazyVim turns them on for each buffer when a server
-- attaches, so vim.lsp.inlay_hint.enable(false) at startup would not stick;
-- this option keeps it from doing so. <leader>uh still shows them for the
-- current buffer.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
    },
  },
}
