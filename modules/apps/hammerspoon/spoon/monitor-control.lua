-- monitor-control.lua
-- These are the Dell U4025QW monitor keys. They use BetterDisplay for raw DDC.
--   Hyper+F1  fullscreen or input change  (hammerspoon://monitor-fullscreen)
--   Hyper+F2  PBP layout or USB switch    (hammerspoon://monitor-pbp)
-- The module monitor-plan.lua makes the decisions. This file does the DDC and
-- sets the keys.

local plan = dofile(hs.spoons.resourcePath("monitor-plan.lua"))

local settings = _G.windowManagerSettings or {}
local BIN = settings.betterDisplayBin or "/opt/homebrew/bin/betterdisplaycli"
local NAME = settings.monitorName or "DELL U4025QW"

local HYPER = { "ctrl", "alt", "cmd", "shift" }
local SETTLE_US = 250000 -- The delay of 250 ms before each verify read.
local RETRY = 5

-- Read a VCP register. Give the value and the raw output. Give nil for the
-- value if the read does not give a number.
local function ddcGet(vcp)
  local out = hs.execute(string.format('%s get -name="%s" -ddc -vcp=%s', BIN, NAME, vcp))
  -- betterdisplaycli gives the values in decimal. Read the digits.
  return tonumber((out or ""):match("%d+")), out
end

-- Write a VCP register. Do not read it back.
local function ddcSet(vcp, value)
  hs.execute(string.format('%s set -name="%s" -ddc -vcp=%s -value=%s', BIN, NAME, vcp, value))
end

-- Write a VCP register. Then make sure that the value holds. Read the low byte
-- two times. The two reads must agree. One read can show a wrong value during a
-- change. If the value does not hold, write it again.
local function ddcSetVerified(vcp, value)
  local want = tonumber(value) % 256
  for _ = 1, RETRY do
    ddcSet(vcp, value)
    hs.timer.usleep(SETTLE_US)
    local a = ddcGet(vcp)
    hs.timer.usleep(SETTLE_US)
    local b = ddcGet(vcp)
    if a and b and (a % 256) == want and (b % 256) == want then return true end
  end
  return false
end

local function apply(ops)
  for _, op in ipairs(ops) do
    if op.kind == "settle" then
      hs.timer.usleep(op.ms * 1000)
    elseif op.kind == "setVerified" then
      -- If a verified write does not hold, show an alert and stop.
      if not ddcSetVerified(op.vcp, op.value) then
        hs.alert.show("Monitor write not confirmed — layout may be wrong")
        return
      end
    else
      ddcSet(op.vcp, op.value)
    end
  end
end

-- Show the correct alert when a read fails. betterdisplaycli calls the
-- BetterDisplay app the "host app". If the host app is not running, tell the
-- user to start it. If not, the monitor does not answer.
local function unreachableAlert(out)
  if out and string.find(out, "Host app", 1, true) then
    hs.alert.show("BetterDisplay is not running. Start it.")
  else
    hs.alert.show("The monitor does not answer. Show this input on the screen.")
  end
end

local function runKey(key)
  local mode, out = ddcGet(plan.codes.mode)
  if mode == nil then return unreachableAlert(out) end
  mode = mode % 256

  local input = nil
  if key == "F1" and mode == plan.SINGLE then
    local inOut
    input, inOut = ddcGet(plan.codes.input)
    if input == nil then return unreachableAlert(inOut) end
    input = input % 256
  end

  apply(plan.planActions(key, mode, input))
end

hs.hotkey.bind(HYPER, "F1", function() runKey("F1") end)
hs.hotkey.bind(HYPER, "F2", function() runKey("F2") end)
hs.urlevent.bind("monitor-fullscreen", function() runKey("F1") end)
hs.urlevent.bind("monitor-pbp", function() runKey("F2") end)
