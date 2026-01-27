-- cmd+tab: toggle last two | cmd+`: toggle terminal | cmd+shift+tab: disabled

local settings = _G.windowManagerSettings or {}
local terminalApp = settings.terminalApp or "Ghostty"

local terminalFilter = hs.window.filter.new(terminalApp)

cmdTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
	local flags = e:getFlags()
	local chars = e:getCharacters()

	-- cmd+shift+tab: disabled, eat the event
	if chars == string.char(25) and flags:containExactly({ "cmd", "shift" }) then
		return true
	end

	-- cmd+tab: toggle between last two
	if chars == "\t" and flags:containExactly({ "cmd" }) then
		local wins = hs.window.orderedWindows()
		if #wins > 1 then
			wins[2]:focus()
		end
		return true
	end

	-- cmd+`: toggle terminal ↔ last app
	if chars == "`" and flags:containExactly({ "cmd" }) then
		local focused = hs.window.focusedWindow()
		if focused and focused:application():name() == terminalApp then
			-- on terminal: switch to last non-terminal window
			local wins = hs.window.orderedWindows()
			for _, w in ipairs(wins) do
				if w:application():name() ~= terminalApp and w:isStandard() then
					w:focus()
					return true
				end
			end
		else
			-- not on terminal: switch to terminal
			local terminalWins = terminalFilter:getWindows(hs.window.filter.sortByFocusedLast)
			if #terminalWins > 0 then
				terminalWins[1]:focus()
			else
				hs.application.launchOrFocus(terminalApp)
			end
		end
		return true
	end

	return false
end)

cmdTap:start()
