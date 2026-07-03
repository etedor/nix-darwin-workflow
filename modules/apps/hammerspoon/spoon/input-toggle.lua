-- toggle monitor input source between HDMI and Thunderbolt
-- Hyper+F1 (M1 macro slot) or hammerspoon://toggle-monitor-input
-- requires: m1ddc (brew install m1ddc)

-- configure these for your monitor (run: m1ddc get input)
local HDMI = 17
local THUNDERBOLT = 25

local function readCurrentInput()
	for _ = 1, 2 do
		local out = hs.execute("/opt/homebrew/bin/m1ddc get input")
		local n = tonumber((out or ""):match("%d+"))
		if n then return n end
	end
	return nil
end

local function toggleInput()
	local currentInput = readCurrentInput()
	if currentInput == HDMI then
		hs.execute("/opt/homebrew/bin/m1ddc set input " .. THUNDERBOLT)
		hs.alert.show("Switched to Thunderbolt")
	elseif currentInput == THUNDERBOLT then
		hs.execute("/opt/homebrew/bin/m1ddc set input " .. HDMI)
		hs.alert.show("Switched to HDMI")
	else
		hs.alert.show("m1ddc returned: " .. tostring(currentInput))
	end
end

-- hotkey binding
hs.hotkey.bind({ "ctrl", "alt", "cmd", "shift" }, "F1", toggleInput)

-- URL handler for Stream Deck: hammerspoon://toggle-monitor-input
hs.urlevent.bind("toggle-monitor-input", function()
	toggleInput()
end)
