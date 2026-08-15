--- WindowManager.spoon
--- adaptive window tiling and focus management for macos
---
--- license: MIT

local obj = {}
obj.__index = obj

obj.name = "WindowManager"
obj.version = "1.0.0"
obj.author = "Eric Tedor <eric@tedor.org>"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.padding = 0
obj.ultrawideThreshold = 2.0
obj.ultrawideLeftWidth = 0.30
obj.ultrawideCenterWidth = 0.40
obj.ultrawideRightWidth = 0.30
obj.standardLeftWidth = 0.50
obj.standardRightWidth = 0.50
obj.terminalApp = "Ghostty"
obj.enableMonitorControl = false
obj.monitorName = "DELL U4025QW"
obj.betterDisplayBin = "/opt/homebrew/bin/betterdisplaycli"

function obj:init()
	return self
end

function obj:start()
	-- create settings table for modules to access (after config is applied)
	_G.windowManagerSettings = {
		padding = self.padding,
		ultrawideThreshold = self.ultrawideThreshold,
		ultrawideLeftWidth = self.ultrawideLeftWidth,
		ultrawideCenterWidth = self.ultrawideCenterWidth,
		ultrawideRightWidth = self.ultrawideRightWidth,
		standardLeftWidth = self.standardLeftWidth,
		standardRightWidth = self.standardRightWidth,
		terminalApp = self.terminalApp,
		monitorName = self.monitorName,
		betterDisplayBin = self.betterDisplayBin,
	}

	-- load modules
	dofile(hs.spoons.resourcePath("reload.lua"))
	dofile(hs.spoons.resourcePath("tiling.lua"))
	dofile(hs.spoons.resourcePath("focus-spatial.lua"))
	dofile(hs.spoons.resourcePath("focus-cluster.lua"))
	dofile(hs.spoons.resourcePath("switcher.lua"))

	-- The monitor keys for input, PBP, and USB. They need BetterDisplay.
	if self.enableMonitorControl then
		dofile(hs.spoons.resourcePath("monitor-control.lua"))
	end

	-- per-host extensions: load ~/.hammerspoon/local.lua if present
	pcall(dofile, hs.configdir .. "/local.lua")

	hs.alert.show("WindowManager loaded")
	return self
end

function obj:stop()
	return self
end

return obj
