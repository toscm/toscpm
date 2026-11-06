--- @since 26.1.22
-- PDF previewer that fills the preview pane, replacing yazi's built-in `pdf`.
--
-- The built-in previewer renders pages at pdftoppm's fixed 150 dpi, and yazi
-- only ever shrinks images, so on a large or high-dpi pane the page came out
-- smaller than the pane. This one asks pdftoppm for exactly the pane's pixel
-- size. J/K and the mouse wheel over the preview turn one page per key press
-- or wheel tick; Enter opens the PDF in pdfv (toscpm bin/pdfv).

local M = {}

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
	local scale = math.min(W / pw, H / ph) -- pixels per point

	local base = ya.file_cache(job)
	if not base then
		return
	end
	local out = string.format("%s-%dx%d", tostring(base), W, H)
	if not fs.cha(Url(out .. ".jpg")) then
		-- stylua: ignore
		local res, err = Command("pdftoppm"):arg({
			"-f", page, "-l", page, "-singlefile",
			"-r", string.format("%.4f", scale * 72),
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

-- One page per key press or wheel tick, whatever the step size (J/K send 5).
function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		local step = ya.clamp(-1, job.units, 1)
		ya.emit("peek", { math.max(0, cx.active.preview.skip + step), only_if = job.file.url })
	end
end

-- Rendering depends on the pane size, so there is nothing to preload;
-- registering this as the PDF preloader keeps the built-in one from rendering
-- a 150 dpi copy that would never be shown.
function M:preload() return true end

return M
