-- Command palette, as in VS Code (F1, see keymaps.lua): one searchable list
-- of keymaps and ":" commands, each shown as a description and its keys or
-- command in two columns (80% / 20% of the window). Matching only looks at
-- these two. Rows are single lines, so long descriptions are cut off; the
-- pane below the list shows the selected entry in full, wrapped.
--
-- Entries:
-- - Keymaps with a description, of the mode the palette is opened from
--   (Visual ones from Visual mode, Normal ones otherwise). Enter runs the
--   keys, after reselecting the selection when opened from Visual mode.
-- - Commands defined by plugins and this config, described by their own
--   description if they have one, by the table below otherwise.
-- - Neovim's built-in commands, described by the one-line summary in the
--   command index of Neovim's help (:help ex-cmd-index), which covers all of
--   them. Enter puts the command on the command line (with the Visual range
--   when opened from Visual mode), so arguments can be added before running
--   it with Enter. Plugin commands that take no arguments run directly
--   (except from Visual mode, as most of them reject a range).

-- Descriptions for plugin commands that have none, or only code.
local command_desc = {
  BufferLineCloseLeft = "Close all buffers to the left",
  BufferLineCloseOthers = "Close all other buffers",
  BufferLineCloseRight = "Close all buffers to the right",
  BufferLineCycleNext = "Go to the next buffer in the tab line",
  BufferLineCyclePrev = "Go to the previous buffer in the tab line",
  BufferLineGoToBuffer = "Go to the buffer at a position in the tab line",
  BufferLineGroupClose = "Close all buffers of a group",
  BufferLineGroupToggle = "Collapse or expand a buffer group",
  BufferLineMoveNext = "Move the buffer one place right in the tab line",
  BufferLineMovePrev = "Move the buffer one place left in the tab line",
  BufferLinePick = "Pick a buffer by its letter",
  BufferLinePickClose = "Pick a buffer by its letter and close it",
  BufferLineSortByDirectory = "Sort buffers by directory",
  BufferLineSortByExtension = "Sort buffers by file extension",
  BufferLineSortByRelativeDirectory = "Sort buffers by relative directory",
  BufferLineSortByTabs = "Sort buffers by tab page",
  BufferLineTabRename = "Rename the current tab page",
  BufferLineTogglePin = "Pin or unpin the buffer",
  ConformInfo = "Show formatter info and log (conform.nvim)",
  Copilot = "GitHub Copilot: auth, status, enable, disable, panel, ...",
  DoMatchParen = "Highlight matching parentheses again",
  Explore = "File explorer (netrw) in the current window",
  Gitsigns = "Git signs: blame, stage, reset, preview hunks, ...",
  GrugFar = "Search and replace across files",
  GrugFarWithin = "Search and replace within the selection",
  Hexplore = "File explorer (netrw) in a horizontal split",
  Lazy = "Plugin manager: update, sync, clean, profile, ...",
  LazyDev = "Lua development setup for Neovim config (lazydev.nvim)",
  Lexplore = "File explorer (netrw) in a sidebar on the left",
  LspInfo = "Show attached language servers (:checkhealth vim.lsp)",
  Man = "Open a man page",
  MatchDebug = "Debug matchit (% on if/else/end and similar)",
  MatchDisable = "Disable matchit (% on if/else/end and similar)",
  MatchEnable = "Enable matchit (% on if/else/end and similar)",
  NetUserPass = "Set user name and password for network files (netrw)",
  NetrwClean = "Remove the netrw plugin files",
  NetrwSettings = "Show netrw settings",
  Nexplore = "Go to the next match of a netrw file search",
  NoMatchParen = "Stop highlighting matching parentheses",
  Nread = "Read a file over the network (netrw)",
  Nsource = "Source a file over the network (netrw)",
  Ntree = "Set the top of the netrw tree view",
  Nwrite = "Write a file over the network (netrw)",
  Pexplore = "Go to the previous match of a netrw file search",
  Sexplore = "File explorer (netrw) in a split",
  Texplore = "File explorer (netrw) in a new tab page",
  TodoFzfLua = "List TODO comments with fzf-lua",
  TodoLocList = "List TODO comments in the location list",
  TodoQuickFix = "List TODO comments in the quickfix list",
  TodoTelescope = "List TODO comments with Telescope",
  TodoTrouble = "List TODO comments in Trouble",
  Trouble = "Diagnostics, references, symbols, ... in a list (Trouble)",
  UpdateRemotePlugins = "Register remote plugins (rplugin manifest)",
  Vexplore = "File explorer (netrw) in a vertical split",
  WhichKey = "Show the keymaps that follow a key prefix",
}

-- A command's definition is shown as its description unless it is code
-- (a Vimscript or Lua call, a command line) or just the command's name.
local function is_description(def, name)
  return def ~= ""
    and def ~= name
    and not def:match("^:")
    and not def:match("^call ")
    and not def:match("^lua ")
    and not def:match("^let ")
    and not def:find("<%a[%a-]*>")
end

-- "BufferLineCloseRight" -> "Buffer line close right", for plugin commands
-- added later that neither describe themselves nor appear in the table.
local function words(name)
  local s = name:gsub("(%l)(%u)", "%1 %2"):lower()
  return s:sub(1, 1):upper() .. s:sub(2)
end

local builtin_cache

-- Built-in commands from the command index of Neovim's help:
-- "|:sort|		:sor[t]		sort lines", with long descriptions continued
-- on the following lines.
local function builtin_commands()
  if builtin_cache then
    return builtin_cache
  end
  builtin_cache = {}
  local file = vim.api.nvim_get_runtime_file("doc/index.txt", false)[1]
  if not file then
    return builtin_cache
  end
  local in_index, last = false, nil
  for line in io.lines(file) do
    if line:find("%*ex%-cmd%-index%*") then
      in_index = true
    elseif in_index then
      local cmd, desc = line:match("^|:[^|]*|%s+:(%S+)%s+(.+)$")
      if cmd then
        last = nil
        local name = cmd:gsub("[%[%]]", "")
        if name ~= "" and not name:find("{") then
          last = { name = name, desc = desc:sub(1, 1):upper() .. desc:sub(2) }
          table.insert(builtin_cache, last)
        end
      elseif last and line:match("^\t\t\t\t%S") then
        last.desc = last.desc .. " " .. vim.trim(line)
      elseif line:match("^=+$") then
        break
      end
    end
  end
  return builtin_cache
end

local function items(visual)
  local ret, seen = {}, {}
  local mode = visual and "x" or "n"
  local maps = vim.api.nvim_buf_get_keymap(0, mode)
  vim.list_extend(maps, vim.api.nvim_get_keymap(mode))
  for _, k in ipairs(maps) do
    local lhs = Snacks.util.normkey(k.lhs)
    if k.desc and k.desc ~= "" and not seen[lhs] and not lhs:match("^<Plug>") then
      seen[lhs] = true
      ret[#ret + 1] = { kind = "keymap", desc = k.desc, key = lhs, lhs = k.lhs, mode = mode }
    end
  end

  local user = {}
  for name, c in pairs(vim.api.nvim_get_commands({})) do
    local def = c.definition:gsub("\n.*", "")
    user[#user + 1] = {
      kind = "command",
      desc = is_description(def, name) and def or command_desc[name] or words(name),
      key = ":" .. name,
      name = name,
      run = c.nargs == "0",
    }
  end
  table.sort(user, function(a, b)
    return a.name < b.name
  end)
  vim.list_extend(ret, user)

  for _, c in ipairs(builtin_commands()) do
    ret[#ret + 1] = { kind = "builtin", desc = c.desc, key = ":" .. c.name, name = c.name }
  end

  for _, item in ipairs(ret) do
    item.text = item.desc .. " " .. item.key
  end
  return ret
end

local function format(item, picker)
  local win = picker.list.win.win
  local width = (win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_width(win) or 80) - 3
  local key_width = math.max(8, math.floor(width * 0.2))
  local desc_width = width - key_width - 1
  local a = Snacks.picker.util.align
  return {
    { a(item.desc, desc_width, { truncate = true }) },
    { " " },
    { a(item.key, key_width, { truncate = true }), item.kind == "keymap" and "SnacksPickerKeymapLhs" or "Function" },
  }
end

local mode_names = { n = "Normal", x = "Visual" }

local function preview(ctx)
  local item = ctx.item
  local lines = { item.desc, "" }
  if item.kind == "keymap" then
    lines[#lines + 1] = ("Keys: %s  (%s mode)"):format(item.key, mode_names[item.mode])
  else
    lines[#lines + 1] = "Command: " .. item.key
    if item.kind == "builtin" then
      lines[#lines + 1] = "Help: :help " .. item.key
    end
  end
  ctx.preview:reset()
  ctx.preview:set_lines(lines)
  ctx.preview:wo({ wrap = true, linebreak = true, number = false, relativenumber = false })
end

return function()
  local visual = vim.fn.mode():match("^[vV\22]") ~= nil
  Snacks.picker({
    title = "Command Palette",
    items = items(visual),
    format = format,
    preview = preview,
    layout = {
      layout = {
        backdrop = false,
        row = 1,
        width = 0.6,
        min_width = 80,
        height = 0.6,
        border = "none",
        box = "vertical",
        { win = "input", height = 1, border = true, title = "{title}", title_pos = "center" },
        { win = "list", border = "hpad" },
        { win = "preview", height = 5, border = true },
      },
    },
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      local keys = visual and "gv" or ""
      if item.kind == "keymap" then
        keys = keys .. item.lhs
      else
        local run = item.run and not visual -- most such commands reject a range
        keys = keys .. ":" .. item.name:gsub("<", "<lt>") .. (run and "<CR>" or " ")
      end
      vim.schedule(function()
        vim.api.nvim_input(keys)
      end)
    end,
  })
end
