-- Word wrap state, shared by the Alt-Z cycle (lua/plugins/wrap-cycle.lua),
-- the <leader>uw toggles (lua/config/keymaps.lua) and the clickable lualine
-- item (lua/plugins/lualine.lua), so the display can never drift from the
-- actual state.
--
-- The states extend the word wrap status bar item vstosc adds to VS Code:
-- "off", "on" (wrap at the window edge) and bounded at a column. Alt-Z
-- cycles through off, on and the columns in M.cols: 80, the usual code
-- width, and 66, the classic measure for comfortable reading of prose
-- (markdown, text documents).
--
-- The bounded state is not native: Vim only soft-wraps at the window edge,
-- and 'textwidth' would hard-wrap by inserting real newlines. The wrapwidth
-- plugin fills the gap by wrapping virtually at a column via inline virtual
-- text, without touching the buffer. It is lazy-loaded, so it is pulled in
-- the first time a bounded state is requested. A column wider than the
-- window is impossible with soft wrap, so the plugin falls back to the
-- window edge there; beyond the window edge there is only "off" with
-- horizontal scrolling (the extends/precedes marks in 'listchars', see
-- config/options.lua, show that a line continues off-screen).
--
-- Independently of the state, 'linebreak' decides whether wrapped lines
-- break between words (LazyVim's default) or within a word at exactly the
-- wrap column; Alt+Shift+Z and <leader>uwl toggle it. Wrapped lines keep
-- their indent ('breakindent', see config/options.lua).
--
-- Note the mixed scopes: 'wrap' and 'linebreak' are window-local while
-- :Wrapwidth is buffer-local, which is harmless as long as a buffer is
-- shown in one window at a time.

local M = {}

-- Columns of the bounded states, in the order Alt-Z cycles through them.
M.cols = { 80, 66 }

-- Current state: "off", "on" or the bound column as a number.
function M.get()
  if not vim.wo.wrap then
    return "off"
  end
  return vim.b.wrap_bounded or "on"
end

-- Current state as shown in lualine: "off", "on" or "80".
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

-- off -> on -> 80 -> 66 -> off. A custom column (set via the prompt or the
-- menu) is not in M.cols and goes to off.
function M.cycle()
  local state = M.get()
  if state == "off" then
    M.set("on")
  elseif state == "on" then
    M.set(M.cols[1])
  else
    local next = "off"
    for i, col in ipairs(M.cols) do
      if col == state then
        next = M.cols[i + 1] or "off"
      end
    end
    M.set(next)
  end
end

-- Ask for a column (prefilled with the current one) and bind at it.
function M.prompt()
  local state = M.get()
  local default = type(state) == "number" and state or M.cols[1]
  vim.ui.input({ prompt = "Wrap column: ", default = tostring(default) }, function(input)
    local col = tonumber(input)
    if col and col > 0 then
      M.set(math.floor(col))
    end
  end)
end

-- Pick the state from a menu (vim.ui.select; Snacks renders it as a picker).
function M.select()
  local items = { { "off", "off" }, { "on", "on" } }
  for _, col in ipairs(M.cols) do
    table.insert(items, { col, col .. " columns" })
  end
  table.insert(items, { "prompt", "other column..." })
  vim.ui.select(items, {
    prompt = "Word wrap",
    format_item = function(item)
      local current = M.get() == item[1] and "* " or "  "
      return current .. item[2]
    end,
  }, function(choice)
    if not choice then
      return
    elseif choice[1] == "prompt" then
      M.prompt()
    else
      M.set(choice[1])
    end
  end)
end

-- Snacks toggles, which show their state in which-key and notify when
-- toggled. Created on first use, since Snacks is not loaded when this
-- module is required from lazy's plugin specs.
local toggles

function M.toggles()
  if not toggles then
    toggles = {
      -- Replaces LazyVim's own "wrap" toggle (same id), which did not know
      -- about the bounded state.
      wrap = Snacks.toggle.new({
        id = "wrap",
        name = "Wrap",
        get = function()
          return vim.wo.wrap
        end,
        set = function(on)
          M.set(on and "on" or "off")
        end,
      }),
      -- 'linebreak': on breaks between words, off breaks within a word at
      -- exactly the wrap column. wrapwidth redraws on OptionSet by itself.
      linebreak = Snacks.toggle.new({
        id = "wrap_linebreak",
        name = "Wrap between Words",
        get = function()
          return vim.wo.linebreak
        end,
        set = function(on)
          vim.wo.linebreak = on
        end,
      }),
    }
  end
  return toggles
end

return M
