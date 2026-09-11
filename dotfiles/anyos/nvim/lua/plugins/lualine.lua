-- LazyVim's lualine, minus the nerd font symbols.
--
--   NORMAL  main  toscpm  E:1 W:2  lua/config/wrap.lua  off  +3 ~1  62%  19:34
--
-- Every icon is dropped or spelled out as text: the diagnostic glyphs become
-- E:/W:/I:/H:, the git diff glyphs +/~/-, the pending updates glyph the word
-- "updates", and the filetype, root directory, readonly and clock icons go
-- away entirely. The rest is LazyVim's default (lua/lazyvim/plugins/ui.lua).
--
-- The word wrap state (see lua/config/wrap.lua) is added in front of
-- lualine_x as "off", "on" or "80"; a left click on it opens the wrap menu.
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local wrap = require("config.wrap")
      local lazy_status = require("lazy.status")

      -- Drop the icons of the built-in components that have text fallbacks
      -- (filetype, fileformat, buffers); the ones LazyVim configures with an
      -- explicit `symbols` table are handled below.
      opts.options.icons_enabled = false

      -- Root directory (no icon; padding compensates for the space the icon
      -- left behind), diagnostics, file path. LazyVim also puts the filetype
      -- icon in front of the path, which goes with the other icons.
      local root_dir = LazyVim.lualine.root_dir({ icon = "" })
      root_dir.padding = { left = 0, right = 1 }
      opts.sections.lualine_c = {
        root_dir,
        {
          "diagnostics",
          symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
        },
        { LazyVim.lualine.pretty_path({ readonly_icon = " [RO] " }) },
      }

      -- The symbol path of the cursor position, as LazyVim adds it, without
      -- the per-kind icons.
      if vim.g.trouble_lualine and LazyVim.has("trouble.nvim") then
        local symbols = require("trouble").statusline({
          mode = "symbols",
          groups = {},
          title = false,
          filter = { range = true },
          format = "{symbol.name:Normal}",
          hl_group = "lualine_c_normal",
        })
        table.insert(opts.sections.lualine_c, {
          symbols and symbols.get,
          cond = function()
            return vim.b.trouble_lualine ~= false and symbols.has()
          end,
        })
      end

      -- Word wrap state, clickable, in front of LazyVim's lualine_x.
      table.insert(opts.sections.lualine_x, 1, {
        wrap.label,
        on_click = function(_, button)
          if button == "l" then
            wrap.select()
          end
        end,
      })

      for _, component in ipairs(opts.sections.lualine_x) do
        if type(component) == "table" then
          if component[1] == "diff" then
            component.symbols = { added = "+", modified = "~", removed = "-" }
          elseif component.cond == lazy_status.has_updates then
            component[1] = function()
              -- lazy.status.updates() is the glyph plus the count, or false.
              local updates = lazy_status.updates() or ""
              return "updates: " .. (updates:match("%d+") or "")
            end
          end
        end
      end

      -- The clock, without the clock icon.
      opts.sections.lualine_z = {
        function()
          return os.date("%R")
        end,
      }
    end,
  },
}
