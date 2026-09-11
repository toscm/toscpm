-- Notifications (Snacks.notifier) in a box wide enough to read.
--
-- By default the box is right-aligned and at most 40% of the editor wide,
-- which on a narrow terminal leaves around 20 usable columns and cuts every
-- message short. Here it is as wide as the message needs, at least 40
-- columns and at most the full width minus a two column gutter on each side
-- (border included, so a long message spans column 3 to column n-2, where n
-- is 'columns'). Snacks always right-aligns the box, so a short one hugs the
-- right gutter and only a long one reaches column 3.
--
-- Snacks measures the longest line of the message and clamps the result
-- between width.min and width.max, and only then computes the wrapped
-- height from that width. The width is the width of the text, so the border
-- adds two columns, and Snacks places the box at
-- 'columns' - width - 2 - margin.right. width.max has to be an absolute
-- number (a value below 1 is read as a fraction of 'columns'), hence the
-- `config` hook -- Snacks.config.get calls it with the merged options -- and
-- the autocmds, which keep the numbers in step with the terminal size and
-- with the tabline.
--
-- Vertically Snacks reserves margin.top rows plus the tabline row, and the
-- border again sits outside that, so the first box starts one line below
-- what margin.top suggests.
--
-- Notification windows have 'wrap' off by default, which would cut long
-- lines instead of wrapping them into the box. A message too tall even for
-- height.max is not cut silently: the footer says how many lines are left
-- and <leader>n shows the full text. 'winblend' goes to 0 because the
-- default 5 blends the text into whatever is behind the box.
--
-- Errors stay until dismissed with <leader>un; everything else disappears
-- after five seconds, except while a command line is open (the `keep`
-- default that is kept here), so nothing vanishes mid-keystroke.
return {
  {
    "folke/snacks.nvim",
    opts = {
      notifier = {
        timeout = 5000,
        height = { min = 1, max = 0.75 },
        keep = function(notif)
          return notif.level == "error" or vim.fn.getcmdpos() > 0
        end,
        config = function(opts)
          local function fit()
            local max = math.max(1, vim.o.columns - 6)
            opts.width = { min = math.min(40, max), max = max }
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
          wo = { wrap = true, winblend = 0 },
        },
      },
    },
  },
}
