-- No HTML tag auto-closing (nvim-ts-autotag) in Markdown.
--
-- To close tags, nvim-ts-autotag maps > in Insert mode to a function that
-- inserts the character itself at the main cursor. With several cursors
-- (lua/plugins/multicursor.lua) the other cursors never got the >, so typing
-- "> " on several lines to quote them only quoted the last one. Markdown
-- rarely needs tags closed, so the mapping is left out there.
return {
  {
    "windwp/nvim-ts-autotag",
    opts = {
      per_filetype = {
        markdown = { enable_close = false },
      },
    },
  },
}
