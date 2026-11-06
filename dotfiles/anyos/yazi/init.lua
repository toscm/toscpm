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

-- Detailed view (Total Commander "Full"): name | ext | size | modified.
-- Switch with Ctrl+F2 (or m d), back to names only with Ctrl+F1 (or m n).
-- Newer yazi calls a file's metadata `stat`, 26.5 still calls it `cha`.
local function stat(file) return file.stat or file.cha end

local function details_on() return cx.active.pref.linemode == "details" end

-- Split "report.tar.gz" into "report.tar" and "gz"; dotfiles and dirs keep their full name.
local function split_ext(file)
	local name = file.name
	if stat(file).is_dir then
		return name, ""
	end
	local stem, ext = name:match("^(.+)%.([^.]+)$")
	if stem then
		return stem, ext
	end
	return name, ""
end

-- In details mode, show the name without its extension (unless find highlights are active).
local highlights = Entity.highlights
function Entity:highlights()
	local hl = self._file:highlights()
	if details_on() and self._file.in_current and (not hl or #hl == 0) then
		return ui.printable((split_ext(self._file)))
	end
	return highlights(self)
end

function Linemode:details()
	local f = self._file
	local _, ext = split_ext(f)
	if #ext > 6 then
		ext = ext:sub(1, 5) .. "…"
	end

	local size
	if stat(f).is_dir then
		size = "<DIR>"
	else
		size = f:size() and ya.readable_size(f:size()) or ""
	end

	-- mtime is a number of seconds in yazi 26.5 and a Time object in newer versions.
	local t = stat(f).mtime
	local secs = type(t) == "number" and t or (t and t.unix)
	local mod = secs and os.date("%Y-%m-%d %H:%M", math.floor(secs)) or ""

	local text = string.format("%-6s %8s  %16s", ext, size, mod)
	-- Comment grey (the terminal's bright black), except on the hovered row,
	-- where grey would be hard to read on the highlight.
	if f.is_hovered then
		return text
	end
	return ui.Span(text):fg("darkgray")
-- Horizontal scrolling (trackpad, tilt wheel) over the preview pans a
-- zoomed-in PDF sideways; see plugins/pdf-view.yazi. Elsewhere it does
-- nothing, as before.
function Preview:touch(event, step)
	ya.emit("plugin", { "pdf-view", step > 0 and "pan right" or "pan left" })
end
