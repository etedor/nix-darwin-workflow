-- adaptive tiling: detects ultrawide vs standard per-screen
--
-- ultrawide (21:9+): configurable split (default: 30/40/30)
--   l/r/u     = left/right/center column (full height)
--   down      = swap columns (configurable: left-center or center-right)
--   l+u, l+d  = top/bottom left
--   r+u, r+d  = top/bottom right
--
-- standard (16:9): configurable split (default: 50/50)
--   l/r       = left/right column (full height)
--   l+u, l+d  = top/bottom left quarter
--   r+u, r+d  = top/bottom right quarter

local settings = _G.windowManagerSettings or {}
local padding = settings.padding or 0
local ultrawideThreshold = settings.ultrawideThreshold or 2.0
local ultrawideLeftWidth = settings.ultrawideLeftWidth or 0.30
local ultrawideCenterWidth = settings.ultrawideCenterWidth or 0.40
local ultrawideRightWidth = settings.ultrawideRightWidth or 0.30
local standardLeftWidth = settings.standardLeftWidth or 0.50
local standardRightWidth = settings.standardRightWidth or 0.50
local ultrawideSwapMode = settings.ultrawideSwapMode or "left-center"

hs.window.animationDuration = 0 -- instant

local tileTimeout = 0.025 -- 25ms
local tileTimer = nil
local firstKey = nil

local function cancelTileTimer()
	if tileTimer then
		tileTimer:stop()
		tileTimer = nil
	end
	firstKey = nil
end

local function isUltrawide(screen)
	local f = screen:frame()
	return (f.w / f.h) >= ultrawideThreshold
end

-- tile to column/row on ultrawide (thirds with wider center)
local function tileThirds(win, sf, col, row)
	local usableW = sf.w - 4 * padding
	local leftW = usableW * ultrawideLeftWidth
	local centerW = usableW * ultrawideCenterWidth
	local rightW = usableW * ultrawideRightWidth

	local x, w
	if col == 0 then
		x = sf.x + padding
		w = leftW
	elseif col == 1 then
		x = sf.x + padding + leftW + padding
		w = centerW
	else
		x = sf.x + padding + leftW + padding + centerW + padding
		w = rightW
	end

	local y, h
	if row == nil then
		y = sf.y + padding
		h = sf.h - 2 * padding
	else
		local rowH = (sf.h - 3 * padding) / 2
		y = sf.y + padding + row * (rowH + padding)
		h = rowH
	end

	win:setFrame({ x = x, y = y, w = w, h = h })
end

-- tile to column/row on standard
local function tileHalves(win, sf, col, row)
	local usableW = sf.w - 3 * padding
	local leftW = usableW * standardLeftWidth
	local rightW = usableW * standardRightWidth

	local x, w
	if col == 0 then
		x = sf.x + padding
		w = leftW
	else
		x = sf.x + padding + leftW + padding
		w = rightW
	end

	local y, h
	if row == nil then
		y = sf.y + padding
		h = sf.h - 2 * padding
	else
		local rowH = (sf.h - 3 * padding) / 2
		y = sf.y + padding + row * (rowH + padding)
		h = rowH
	end

	win:setFrame({ x = x, y = y, w = w, h = h })
end

-- detect which column a window is in (ultrawide: 0/1/2, standard: 0/1)
local function getWindowColumn(win, sf, ultrawide)
	local wf = win:frame()
	local centerX = wf.x + wf.w / 2
	local relX = centerX - sf.x
	if ultrawide then
		local boundary1 = sf.w * ultrawideLeftWidth
		local boundary2 = sf.w * (ultrawideLeftWidth + ultrawideCenterWidth)
		if relX < boundary1 then
			return 0
		elseif relX < boundary2 then
			return 1
		else
			return 2
		end
	else
		return (relX < sf.w * standardLeftWidth) and 0 or 1
	end
end

-- detect row: 0=top, 1=bottom, nil=full
local function getWindowRow(win, sf)
	local wf = win:frame()
	local tolerance = 50
	if wf.h >= sf.h - 2 * padding - tolerance then
		return nil
	end
	local centerY = wf.y + wf.h / 2
	return (centerY < sf.y + sf.h / 2) and 0 or 1
end

-- swap columns based on ultrawideSwapMode setting
local function swapColumns(screen, sf)
	local allWindows = hs.window.visibleWindows()
	for _, w in ipairs(allWindows) do
		if w:screen():id() == screen:id() and w:isStandard() then
			local col = getWindowColumn(w, sf, true)
			local row = getWindowRow(w, sf)
			if ultrawideSwapMode == "center-right" then
				if col == 1 then
					tileThirds(w, sf, 2, row)
				elseif col == 2 then
					tileThirds(w, sf, 1, row)
				end
			else -- "left-center" (default)
				if col == 0 then
					tileThirds(w, sf, 1, row)
				elseif col == 1 then
					tileThirds(w, sf, 0, row)
				end
			end
		end
	end
end

local function handleKey(key)
	local win = hs.window.focusedWindow()
	if not win then
		cancelTileTimer()
		return
	end

	local screen = win:screen()
	local sf = screen:frame()
	local ultrawide = isUltrawide(screen)

	if firstKey then
		local savedFirstKey = firstKey
		cancelTileTimer()

		-- chord: first key = column, second key = row
		local col, row

		if ultrawide then
			-- column from first key (L/R only)
			if savedFirstKey == "left" then
				col = 0
			elseif savedFirstKey == "right" then
				col = 2
			end

			-- row from second key
			if key == "up" then
				row = 0
			elseif key == "down" then
				row = 1
			end

			if col ~= nil and row ~= nil then
				tileThirds(win, sf, col, row)
			end
		else
			-- standard: L/R for column, U/D for row
			if savedFirstKey == "left" then
				col = 0
			elseif savedFirstKey == "right" then
				col = 1
			end

			if key == "up" then
				row = 0
			elseif key == "down" then
				row = 1
			end

			if col ~= nil and row ~= nil then
				tileHalves(win, sf, col, row)
			end
		end
		return
	end

	-- first key: start timer for single-key action
	firstKey = key
	tileTimer = hs.timer.doAfter(tileTimeout, function()
		local currentWin = hs.window.focusedWindow()
		if not currentWin then
			firstKey = nil
			return
		end

		local currentScreen = currentWin:screen()
		local currentSf = currentScreen:frame()
		local currentUltrawide = isUltrawide(currentScreen)

		if currentUltrawide then
			if firstKey == "left" then
				tileThirds(currentWin, currentSf, 0, nil)
			elseif firstKey == "right" then
				tileThirds(currentWin, currentSf, 2, nil)
			elseif firstKey == "up" then
				tileThirds(currentWin, currentSf, 1, nil)
			elseif firstKey == "down" then
				swapColumns(currentScreen, currentSf)
			end
		else
			if firstKey == "left" then
				tileHalves(currentWin, currentSf, 0, nil)
			elseif firstKey == "right" then
				tileHalves(currentWin, currentSf, 1, nil)
			end
			-- up/down do nothing in standard mode (free for future use)
		end

		firstKey = nil
	end)
end

hs.hotkey.bind({ "ctrl", "alt" }, "left", function()
	handleKey("left")
end)
hs.hotkey.bind({ "ctrl", "alt" }, "right", function()
	handleKey("right")
end)
hs.hotkey.bind({ "ctrl", "alt" }, "up", function()
	handleKey("up")
end)
hs.hotkey.bind({ "ctrl", "alt" }, "down", function()
	handleKey("down")
end)

-- center window on screen
hs.hotkey.bind({ "ctrl", "alt" }, "c", function()
	local win = hs.window.focusedWindow()
	if win then
		win:centerOnScreen()
	end
end)

-- fill screen (with padding)
hs.hotkey.bind({ "ctrl", "alt" }, "f", function()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end
	local sf = win:screen():frame()
	win:setFrame({
		x = sf.x + padding,
		y = sf.y + padding,
		w = sf.w - 2 * padding,
		h = sf.h - 2 * padding,
	})
end)

-- float on top (works only for apps with this menu item)
hs.hotkey.bind({ "ctrl", "alt" }, "t", function()
	local win = hs.window.focusedWindow()
	if win then
		local app = win:application()
		if app then
			app:selectMenuItem({ "Window", "Float on Top" })
		end
	end
end)
