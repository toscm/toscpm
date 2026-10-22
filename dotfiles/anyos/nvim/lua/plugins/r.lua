-- R: the language server from the languageserver R package, started for R,
-- R Markdown and Quarto files. It gives folds (functions, braces and comment
-- blocks such as roxygen), the symbol outline (<leader>ss, <leader>cs, the
-- breadcrumb in the status line), hover, completion and diagnostics.
--
-- The workspace root is the nearest directory with a DESCRIPTION, whatever
-- nvim's working directory, so the server treats it as a package and also
-- reads the files in R/ that are not open. Without a DESCRIPTION it is the
-- git root, else the file's directory (lspconfig's own fallback is ~, which
-- would make a stray R file index the whole home directory).
--
-- languageserver is not a toscpm tool: install it with
-- install.packages("languageserver"). Without it, R exits quietly instead
-- of failing on every R file. It is installed into the R library, not by
-- Mason (mason = false).
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        r_language_server = {
          mason = false,
          cmd = {
            "R",
            "--no-echo",
            "-e",
            "if (requireNamespace('languageserver', quietly = TRUE)) languageserver::run()",
          },
          root_dir = function(bufnr, on_dir)
            on_dir(
              vim.fs.root(bufnr, "DESCRIPTION")
                or vim.fs.root(bufnr, ".git")
                or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
            )
          end,
        },
      },
    },
  },
}
