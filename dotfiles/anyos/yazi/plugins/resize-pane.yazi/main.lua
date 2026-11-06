--- @since 26.1.22
--- @sync entry
-- Move the divider between the file list and the preview, in tenths.
--
--   plugin resize-pane -- left    divider one step left (preview grows)
--   plugin resize-pane -- right   divider one step right (file list grows)
--   plugin resize-pane -- reset   back to the ratio from yazi.toml
--
-- The parent pane keeps its share. rt.mgr.ratio is { parent=, current=,
-- preview= } on yazi 26.x stable and { [1], [2], [3] } on nightly; both are
-- read, and it is always written as a list, as toggle-pane does.

local STEPS = 10

local function get()
	local r = rt.mgr.ratio
	if r[1] then
		return { r[1], r[2], r[3] }
	end
	return { r.parent, r.current, r.preview }
end

local function set(r)
	rt.mgr.ratio = { r[1], r[2], r[3] }
	ya.emit("app:resize", {})
end

local function entry(st, job)
	local act = job.args[1]
	st.orig = st.orig or get()

	if act == "reset" then
		return set(st.orig)
	end

	-- Rescale current + preview to STEPS units, so one step is a tenth of
	-- their width whatever numbers the config uses.
	local r = get()
	local side = r[2] + r[3]
	if side == 0 then
		return
	end
	local parent = math.floor(r[1] * STEPS / side + 0.5)
	local preview = math.floor(r[3] * STEPS / side + 0.5)

	if act == "left" then
		preview = math.min(preview + 1, STEPS)
	elseif act == "right" then
		preview = math.max(preview - 1, 0)
	else
		return ya.notify { title = "resize-pane", content = "unknown action: " .. tostring(act), level = "error", timeout = 5 }
	end
	set { parent, STEPS - preview, preview }
end

return { entry = entry }
