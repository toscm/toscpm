-- Multiple cursors (multicursor.nvim), with VS Code's bindings where the
-- terminal passes them through.
--
--   Ctrl+D              select the word under the cursor; pressed again on a
--                       selection, add a cursor on its next match
--   Ctrl+Shift+L        add a cursor on every match of the word/selection
--   Ctrl+Alt+Up/Down    add a cursor on the line above/below (also in
--                       Insert mode, where you keep typing at all cursors)
--   I / A               on the selections, insert before / append after
--                       each one (like I/A in a block selection)
--   Alt+Click           add or remove a cursor
--   Esc                 back to a single cursor
--
-- With several cursors, every edit applies to all of them: c on the
-- selections types the replacement everywhere, I/A insert before/after
-- them, and Vim motions and operators work as with a single cursor.
-- On a selection, i and a stay Vim's text objects (i" grows each selection
-- to the inside of its quotes); i/a/I/A insert at each cursor only in
-- Normal mode.
--
-- Ctrl+D replaces Vim's half-page-down scroll (PageDown still scrolls).
-- Ctrl+Shift+L only arrives if the terminal reports Shift with Ctrl+letter
-- (kitty keyboard protocol, e.g. WezTerm, kitty, recent Windows Terminal);
-- elsewhere it reads as Ctrl+L.
return {
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      local set = vim.keymap.set
      set("n", "<C-d>", "viw", { desc = "Select Word" })
      set("x", "<C-d>", function()
        mc.matchAddCursor(1)
      end, { desc = "Add Cursor on Next Match" })
      -- mc.insertVisual/appendVisual insert at the start/end of the line in
      -- a charwise selection, so there each cursor goes to the start/end of
      -- its own selection instead.
      local function insertAtSelections(append)
        if vim.fn.mode() ~= "v" then
          return append and mc.appendVisual() or mc.insertVisual()
        end
        mc.action(function(ctx)
          ctx:forEachCursor(function(cursor)
            local swap = cursor:atVisualStart() == append
            cursor:feedkeys((swap and "o" or "") .. "<esc>", { keycodes = true })
          end)
        end)
        mc.feedkeys(append and "a" or "i")
      end
      set("x", "I", function()
        insertAtSelections(false)
      end, { desc = "Insert Before Selections" })
      set("x", "A", function()
        insertAtSelections(true)
      end, { desc = "Append After Selections" })
      set({ "n", "x" }, "<C-S-l>", mc.matchAllAddCursors, { desc = "Add Cursors on All Matches" })
      set({ "n", "x" }, "<C-A-Up>", function()
        mc.lineAddCursor(-1)
      end, { desc = "Add Cursor Above" })
      set({ "n", "x" }, "<C-A-Down>", function()
        mc.lineAddCursor(1)
      end, { desc = "Add Cursor Below" })
      -- multicursor.nvim actions do not run in Insert mode, so these run as
      -- a one-off Normal-mode command (Ctrl+O) and Insert mode continues.
      set("i", "<C-A-Up>", '<C-o><Cmd>lua require("multicursor-nvim").lineAddCursor(-1)<CR>', { desc = "Add Cursor Above" })
      set("i", "<C-A-Down>", '<C-o><Cmd>lua require("multicursor-nvim").lineAddCursor(1)<CR>', { desc = "Add Cursor Below" })
      set("n", "<A-LeftMouse>", mc.handleMouse, { desc = "Add/Remove Cursor" })
      set("n", "<A-LeftDrag>", mc.handleMouseDrag)
      set("n", "<A-LeftRelease>", mc.handleMouseRelease)

      -- Only while there are several cursors.
      mc.addKeymapLayer(function(layerSet)
        layerSet("n", "<esc>", function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)
    end,
  },
}
