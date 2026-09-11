-- Notifications (Snacks.notifier) in a box wide enough to read.
--
-- By default the box is right-aligned and at most 40% of the editor wide,
-- which on a narrow terminal leaves around 20 usable columns and cuts every
-- message short. Here the box, border included, spans the whole width minus
-- a two column gutter on each side: it starts on line 3, column 3 and ends
-- in column n-2, where n is 'columns'.
--
-- Snacks measures the message and then clamps the result between width.min
-- and width.max, so pinning both to the same number fixes the width. It is
-- the width of the text, so the border adds two columns, and Snacks places
-- the box at 'columns' - width - 2 - margin.right. The width has to be an
-- absolute number (a value below 1 is read as a fraction of 'columns'),
-- hence the `config` hook -- Snacks.config.get calls it with the merged
-- options -- and the autocmds, which keep the numbers in step with the
-- terminal size and with the tabline.
--
-- Vertically Snacks reserves margin.top rows plus the tabline row, and the
-- border again sits outside that, so the first box starts one line below
-- what margin.top suggests.
--
-- Notification windows have 'wrap' off by default, which would cut long
-- lines instead of wrapping them into the now much wider box.
return {
  {
    "folke/snacks.nvim",
    opts = {
      notifier = {
        config = function(opts)
          local function fit()
            local width = math.max(1, vim.o.columns - 6)
            opts.width = { min = width, max = width }
            opts.margin = { top = vim.o.tabline == "" and 3 or 2, right = 1, bottom = 0 }
          end
          fit()
          local group = vim.api.nvim_create_augroup("notifier_fit", { clear = true })
          vim.api.nvim_create_autocmd("VimResized", { group = group, callback = fit })
          vim.api.nvim_create_autocmd("OptionSet", { group = group, pattern = "tabline", callback = fit })
        end,
      },
      styles = {
        notification = {
          wo = { wrap = true },
        },
      },
    },
  },
}
