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

-- Read a VCP register. Give the value. Give nil if the monitor does not answer.
local function ddcGet(vcp)
  local out = hs.execute(string.format('%s get -name="%s" -ddc -vcp=%s', BIN, NAME, vcp))
  -- betterdisplaycli gives the values in decimal. Read the digits.
  return tonumber((out or ""):match("%d+"))
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

local function notReachable()
  hs.alert.show("Monitor not reachable — put this input on screen first")
end

local function runKey(key)
  local mode = ddcGet(plan.codes.mode)
  if mode == nil then return notReachable() end
  mode = mode % 256

  local input = nil
  if key == "F1" and mode == plan.SINGLE then
    input = ddcGet(plan.codes.input)
    if input == nil then return notReachable() end
    input = input % 256
  end

  apply(plan.planActions(key, mode, input))
end

hs.hotkey.bind(HYPER, "F1", function() runKey("F1") end)
hs.hotkey.bind(HYPER, "F2", function() runKey("F2") end)
hs.urlevent.bind("monitor-fullscreen", function() runKey("F1") end)
hs.urlevent.bind("monitor-pbp", function() runKey("F2") end)
