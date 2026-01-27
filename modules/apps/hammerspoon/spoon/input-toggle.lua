-- toggle monitor input source between HDMI and Thunderbolt
-- ctrl+alt+cmd+i or hammerspoon://toggle-monitor-input
-- requires: m1ddc (brew install m1ddc)

-- configure these for your monitor (run: m1ddc get input)
local HDMI = 17
local THUNDERBOLT = 25

local function toggleInput()
	local result = hs.execute("/opt/homebrew/bin/m1ddc get input")
	local currentInput = tonumber(result:match("%d+"))

	if currentInput == HDMI then
		hs.execute("/opt/homebrew/bin/m1ddc set input " .. THUNDERBOLT)
		hs.alert.show("Switched to Thunderbolt")
	else
		hs.execute("/opt/homebrew/bin/m1ddc set input " .. HDMI)
		hs.alert.show("Switched to HDMI")
	end
end

-- hotkey binding
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "i", toggleInput)

-- URL handler for Stream Deck: hammerspoon://toggle-monitor-input
hs.urlevent.bind("toggle-monitor-input", function()
	toggleInput()
end)
