-- Word wrap state, shared by the Alt-Z cycle (lua/plugins/wrap-cycle.lua)
-- and the clickable statusline item (lua/config/statusline.lua), so the
-- display can never drift from the actual state.
--
-- Three states, mirroring the word wrap status bar item vstosc adds to
-- VS Code: "off", "on" (wrap at the window edge) and bounded at a column.
--
-- The bounded state is not native: Vim only soft-wraps at the window edge,
-- and 'textwidth' would hard-wrap by inserting real newlines. The wrapwidth
-- plugin fills the gap by wrapping virtually at a column via inline virtual
-- text, without touching the buffer. It is lazy-loaded, so it is pulled in
-- the first time a bounded state is requested.
--
-- Mid-word breaking is intentional: 'linebreak' stays off (its default), so
-- wrapped lines break at the last screen cell rather than at word boundaries.
--
-- Note the mixed scopes: 'wrap' is window-local while :Wrapwidth is
-- buffer-local, which is harmless as long as a buffer is shown in one window
-- at a time.

local M = {}

-- Column used by the bounded state.
M.col = 80

-- Current state: "off", "on" or the bound column as a number.
function M.get()
  if not vim.wo.wrap then
    return "off"
  end
  return vim.b.wrap_bounded or "on"
end

-- Current state as shown in the statusline: "off", "on" or "80".
function M.label()
  return tostring(M.get())
end

-- Set the state: "off", "on" or a column number.
function M.set(state)
  if vim.b.wrap_bounded then
    vim.cmd("Wrapwidth 0")
    vim.b.wrap_bounded = nil
  end
  if state == "off" then
    vim.wo.wrap = false
  elseif state == "on" then
    vim.wo.wrap = true
  else
    require("lazy").load({ plugins = { "wrapwidth" } })
    vim.wo.wrap = true
    vim.b.wrap_bounded = state
    vim.cmd("Wrapwidth " .. state)
  end
  vim.cmd.redrawstatus()
end

-- off -> on -> bounded -> off
function M.cycle()
  local state = M.get()
  if state == "off" then
    M.set("on")
  elseif state == "on" then
    M.set(M.col)
  else
    M.set("off")
  end
end

-- Pick the state from a menu (vim.ui.select; Snacks renders it as a picker).
function M.select()
  local items = { "off", "on", M.col .. " columns" }
  vim.ui.select(items, {
    prompt = "Word wrap",
    format_item = function(item)
      local current = M.label() == item:match("^%S+") and "* " or "  "
      return current .. item
    end,
  }, function(choice)
    if choice == "off" or choice == "on" then
      M.set(choice)
    elseif choice then
      M.set(M.col)
    end
  end)
end

return M
