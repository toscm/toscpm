--- @sync entry
-- Enter: go into a directory, show a PDF over the full width (a second Enter
-- restores the panes, see resize-pane.yazi), or open any other file.
-- Opening a PDF would hand it to xdg-open, which needs a desktop; the
-- full-width preview works in any terminal yazi shows images in, tmux too.
return {
	entry = function()
		local h = cx.active.current.hovered
		if h and h.cha.is_dir then
			ya.emit("enter", { hovered = true })
		elseif h and h:mime() == "application/pdf" then
			ya.emit("plugin", { "resize-pane", "max" })
		else
			ya.emit("open", { hovered = true })
		end
	end,
}
