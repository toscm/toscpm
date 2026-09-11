-- A plain statusline built on the native 'statusline' option, replacing
-- lualine (disabled in lua/plugins/lualine.lua). One colour, no icons, no
-- separators:
--
--   NORMAL  TODOS.md  on  main  10                            70%  19:34
--
-- Left to right: mode, file name, word wrap state (click it for a menu,
-- see lua/config/wrap.lua), git branch (from gitsigns; empty outside a
-- repository), number of plugins with pending updates (from the lazy.nvim
-- checker; empty when up to date), then right-aligned the position in the
-- file as a percentage and line:column.
--
-- The %{...} items are evaluated with the window being drawn as the current
-- window, which is always the active one since 'laststatus' is 3 (one global
-- statusline). The functions are exposed as the global `Stl` because the
-- option can only reach Lua through v:lua.

local M = {}

local modes = {
  n = "NORMAL",
  no = "O-PENDING",
  nt = "NORMAL",
  i = "INSERT",
  v = "VISUAL",
  V = "V-LINE",
  ["\22"] = "V-BLOCK",
  s = "SELECT",
  S = "S-LINE",
  ["\19"] = "S-BLOCK",
  c = "COMMAND",
  R = "REPLACE",
  Rv = "V-REPLACE",
  t = "TERMINAL",
}

function M.mode()
  local m = vim.fn.mode()
  return modes[m] or modes[m:sub(1, 1)] or m
end

function M.wrap()
  return require("config.wrap").label()
end

-- Click handler for the wrap item: opens the wrap menu on a left click.
-- Arguments: minwid, click count, button ("l", "m", "r"), modifiers.
function M.wrap_click(_, _, button)
  if button == "l" then
    require("config.wrap").select()
  end
end

function M.branch()
  return vim.b.gitsigns_head or ""
end

function M.updates()
  local ok, status = pcall(require, "lazy.status")
  if ok and status.has_updates() then
    return status.updates():match("%d+") or ""
  end
  return ""
end

_G.Stl = M

vim.o.statusline = table.concat({
  " %{v:lua.Stl.mode()}",
  "%t",
  "%@v:lua.Stl.wrap_click@%{v:lua.Stl.wrap()}%X",
  "%{v:lua.Stl.branch()}",
  "%{v:lua.Stl.updates()}",
  "%=",
  "%p%%",
  "%l:%c ",
}, "  ")

return M
