-- Multiple cursors (multicursor.nvim), with VS Code's bindings where the
-- terminal passes them through.
--
--   Ctrl+D              select the word under the cursor; pressed again on a
--                       selection, add a cursor on its next match
--   Ctrl+Shift+L        add a cursor on every match of the word/selection
--   Ctrl+Alt+Up/Down    add a cursor on the line above/below (also in
--                       Insert mode, where you keep typing at all cursors)
--   Alt+Click           add or remove a cursor
--   Esc                 back to a single cursor
--
-- With several cursors, every edit applies to all of them: c on the
-- selections types the replacement everywhere, i/a/A/I insert at each
-- cursor, and Vim motions and operators work as with a single cursor.
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
