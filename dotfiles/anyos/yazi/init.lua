-- yamb: persistent bookmarks (https://github.com/h-hg/yamb)
require("yamb"):setup {
	jump_notify = true,
	cli = "fzf",
	keys = "0123456789abcdefghijklmnopqrstuvwxyz",
	-- Bookmarks are saved here, so they survive restarts and SSH sessions.
	path = os.getenv("HOME") .. "/.config/yazi/bookmark",
}

-- zoxide: feed every dir entered in yazi into the shared zoxide database,
-- so frecency stays in sync between the shell and yazi.
require("zoxide"):setup {
	update_db = true,
}
