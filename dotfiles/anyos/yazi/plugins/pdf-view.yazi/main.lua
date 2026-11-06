--- @since 26.1.22
--- @sync entry
-- PDF previewer with zoom and pan, replacing yazi's built-in `pdf` previewer.
--
-- Every view is rendered by pdftoppm at exactly the pixel size of the preview
-- pane: the built-in previewer renders at a fixed 150 dpi, so on a large or
-- high-dpi pane the page came out smaller than the pane. Zooming renders the
-- page at a higher resolution and crops the visible part (pdftoppm -x -y -W -H),
-- so text stays sharp at any zoom level.
--
--   plugin pdf-view -- zoom in|out|reset
--   plugin pdf-view -- pan left|right|up|down
--
-- The mouse wheel over the preview scrolls: while zoomed in it pans down and
-- up, and continues on the next or previous page at the bottom or top edge;
-- at fit-to-pane zoom it turns pages, like J and K. Horizontal scrolling pans
-- sideways (see Preview:touch in init.lua).
--
-- The view (zoom, centre) lives in the plugin's sync state and belongs to one
-- file; hovering another PDF starts at fit-to-pane again.

local ZOOM_STEP = 1.25
local ZOOM_MAX = 16
local PAN_STEP = 0.25 -- fraction of the visible part per key press / wheel tick

local M = {}

-- --- sync side --------------------------------------------------------------

local function hovered_pdf()
	local h = cx.active.current.hovered
	if h and h:mime() == "application/pdf" then
		return h
	end
end

-- The view of `url`, reset when the hovered file changed.
local function view(st, url)
	local key = tostring(url)
	if not st.view or st.view.key ~= key then
		st.view = { key = key, z = 1, cx = 0.5, cy = 0.5, vw = 1, vh = 1 }
	end
	return st.view
end

local function clamp_centre(v)
	v.cx = ya.clamp(v.vw / 2, v.cx, 1 - v.vw / 2)
	v.cy = ya.clamp(v.vh / 2, v.cy, 1 - v.vh / 2)
end

local function redraw(url, skip)
	ya.emit("peek", { skip or cx.active.preview.skip, force = true, only_if = url })
end

function M:entry(job)
	local h = hovered_pdf()
	if not h then
		return
	end
	local v = view(self, h.url)
	local act, arg = job.args[1], job.args[2]

	if act == "zoom" then
		local old = v.z
		if arg == "in" then
			v.z = math.min(v.z * ZOOM_STEP, ZOOM_MAX)
		elseif arg == "out" then
			v.z = math.max(v.z / ZOOM_STEP, 1)
		else
			v.z, v.cx, v.cy = 1, 0.5, 0.5
		end
		-- The visible fraction shrinks with the zoom; peek recomputes it
		-- exactly, this estimate only keeps the centre in range meanwhile.
		v.vw, v.vh = math.min(1, v.vw * old / v.z), math.min(1, v.vh * old / v.z)
	elseif act == "pan" then
		local dx = (arg == "left" and -1 or arg == "right" and 1 or 0) * v.vw * PAN_STEP
		local dy = (arg == "up" and -1 or arg == "down" and 1 or 0) * v.vh * PAN_STEP
		v.cx, v.cy = v.cx + dx, v.cy + dy
	else
		return ya.notify { title = "pdf-view", content = "unknown action: " .. tostring(act), level = "error", timeout = 5 }
	end
	clamp_centre(v)
	redraw(h.url)
end

-- Mouse wheel over the preview (and J/K, which also emit `seek`).
function M:seek(job)
	local h = hovered_pdf()
	if not h or h.url ~= job.file.url then
		return
	end
	local v, step = view(self, h.url), ya.clamp(-1, job.units, 1)
	local skip = cx.active.preview.skip

	if v.vh >= 1 then -- whole page height visible: turn the page
		return redraw(h.url, math.max(0, skip + step))
	end

	local eps = 1e-6
	if step > 0 and v.cy + v.vh / 2 >= 1 - eps then
		v.cy = v.vh / 2 -- top of the next page
		return redraw(h.url, skip + 1)
	elseif step < 0 and v.cy - v.vh / 2 <= eps then
		if skip == 0 then
			return
		end
		v.cy = 1 - v.vh / 2 -- bottom of the previous page
		return redraw(h.url, skip - 1)
	end
	v.cy = v.cy + step * v.vh * PAN_STEP
	clamp_centre(v)
	redraw(h.url)
end

-- --- async side (peek runs in its own Lua state) -----------------------------

local get_view = ya.sync(function(st, url)
	local v = view(st, url)
	return { z = v.z, cx = v.cx, cy = v.cy }
end)

local put_view = ya.sync(function(st, url, cx_, cy_, vw, vh)
	local v = view(st, url)
	v.cx, v.cy, v.vw, v.vh = cx_, cy_, vw, vh
end)

-- Page count and the size of one page in points (rotation applied).
local function page_info(path, page)
	local out = Command("pdfinfo"):arg({ "-f", page, "-l", page, path }):output()
	if not out or not out.status.success then
		return nil
	end
	local s = out.stdout
	local pages = tonumber(s:match("Pages:%s+(%d+)"))
	local w, h = s:match("Page%s+%d+%s+size:%s+([%d.]+)%s+x%s+([%d.]+)")
	local rot = tonumber(s:match("Page%s+%d+%s+rot:%s+(%d+)")) or 0
	w, h = tonumber(w), tonumber(h)
	if rot % 180 == 90 then
		w, h = h, w
	end
	return pages, w, h
end

function M:peek(job)
	local start = os.clock()
	local path = tostring(job.file.path)
	local page = job.skip + 1

	local pages, pw, ph = page_info(path, page)
	if not pages then
		return ya.preview_widget(job, Err("pdfinfo could not read the PDF (is poppler installed?)"))
	elseif page > pages then
		return ya.emit("peek", { math.max(0, pages - 1), only_if = job.file.url, upper_bound = true })
	end

	-- Pane size in pixels. A terminal that does not report its cell size
	-- (then usually one without image support either) gets a typical 10x20.
	local cw, ch = rt.term.cell_size()
	cw, ch = cw or 10, ch or 20
	local W = math.min(math.floor(job.area.w * cw), rt.preview.max_width)
	local H = math.min(math.floor(job.area.h * ch), rt.preview.max_height)

	local v = get_view(job.file.url)
	local scale = math.min(W / pw, H / ph) * v.z -- pixels per point
	local fw, fh = pw * scale, ph * scale -- full page at this zoom
	local cwid, chei = math.min(W, math.floor(fw)), math.min(H, math.floor(fh))
	local vw, vh = cwid / fw, chei / fh -- visible fraction of the page
	local cx_ = ya.clamp(vw / 2, v.cx, 1 - vw / 2)
	local cy_ = ya.clamp(vh / 2, v.cy, 1 - vh / 2)
	local x = math.floor(cx_ * fw - cwid / 2 + 0.5)
	local y = math.floor(cy_ * fh - chei / 2 + 0.5)
	put_view(job.file.url, cx_, cy_, vw, vh)

	local base = ya.file_cache(job)
	if not base then
		return
	end
	local out = string.format("%s-%dx%d+%d+%d@%.2f", tostring(base), cwid, chei, x, y, scale)
	if not fs.cha(Url(out .. ".jpg")) then
		-- stylua: ignore
		local res, err = Command("pdftoppm"):arg({
			"-f", page, "-l", page, "-singlefile",
			"-r", string.format("%.4f", scale * 72),
			"-x", x, "-y", y, "-W", cwid, "-H", chei,
			"-jpeg", "-jpegopt", "quality=" .. rt.preview.image_quality,
			path, out,
		}):output()
		if not res then
			return ya.preview_widget(job, Err("Failed to start `pdftoppm`, error: %s", err))
		elseif not res.status.success then
			return ya.preview_widget(job, Err("pdftoppm failed: %s", res.stderr))
		end
	end

	ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))
	local _, err = ya.image_show(Url(out .. ".jpg"), job.area)
	ya.preview_widget(job, err)
end

-- Rendering depends on the pane size and zoom, so there is nothing to preload;
-- registering this as the PDF preloader keeps the built-in one from rendering
-- a 150 dpi copy that would never be shown.
function M:preload() return true end

return M
