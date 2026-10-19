-- Colorscheme: github_light_default on a light terminal background,
-- github_dark_default otherwise, from the github-theme plugin, which is
-- loaded eagerly (lazy = false, high priority) so it is in place before the
-- first buffer is drawn. <leader>uC previews the other installed schemes,
-- Neovim's built-in default (see :help dev_theme) among them, but only for
-- the running session; this file is what makes a choice stick.
--
-- Neovim asks the terminal for its background colour (OSC 11) at startup,
-- but ignores the answer once a colorscheme has set 'background', which the
-- dark scheme does before the answer arrives. So the answer is read here and
-- the scheme switched directly. It asks again whenever nvim regains focus,
-- so a light/dark toggle of the terminal is picked up on return, and
-- :ThemeSync asks on demand.
--
-- Under tmux the answer comes from tmux's copy of the terminal colours, which
-- tmux.conf refreshes on the same focus-in, so the second ask, half a second
-- later, is the one that sees a fresh toggle; the first covers switching
-- between panes, where the copy is already current.
local function on_answer(args)
  local r, g, b = args.data.sequence:match("^\27%]11;rgb:(%x+)/(%x+)/(%x+)")
  if not r then
    return
  end
  local function channel(hex)
    return tonumber(hex, 16) / (16 ^ #hex - 1)
  end
  local light = 0.299 * channel(r) + 0.587 * channel(g) + 0.114 * channel(b) >= 0.5
  local scheme = light and "github_light_default" or "github_dark_default"
  if vim.g.colors_name ~= scheme then
    vim.cmd.colorscheme(scheme)
  end
end

return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    -- The compiled themes default to stdpath("cache"), which on Windows is
    -- under %TEMP% and gets cleaned. The cleanup can leave the hash file
    -- behind, so the plugin skips recompiling and :colorscheme fails with
    -- "attempt to call local 'compiled_theme' (a nil value)".
    --
    -- The themes' Visual highlight is a faint blue tint that is barely
    -- visible, so the selection gets a solid blue background with white text
    -- instead, as clear as a selection in tmux's copy mode or the terminal's
    -- mark mode.
    opts = {
      options = { compile_path = vim.fn.stdpath("data") .. "/github-theme" },
      groups = {
        github_dark_default = {
          Visual = { bg = "#1f6feb", fg = "#ffffff" },
          VisualNOS = { link = "Visual" },
        },
        github_light_default = {
          Visual = { bg = "#0969da", fg = "#ffffff" },
          VisualNOS = { link = "Visual" },
        },
      },
    },
    init = function()
      local function ask()
        io.stdout:write("\27]11;?\7")
      end
      vim.api.nvim_create_autocmd("TermResponse", { callback = on_answer })
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function()
          ask()
          vim.defer_fn(ask, 500)
        end,
      })
      vim.api.nvim_create_user_command("ThemeSync", ask, {
        desc = "Match the colorscheme to the terminal background",
      })
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_dark_default",
    },
  },
}
