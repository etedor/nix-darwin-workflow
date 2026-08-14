-- monitor-control.lua
-- state-aware Dell U4025QW binds over BetterDisplay raw DDC.
--   Hyper+F1  fullscreen / input toggle   (hammerspoon://monitor-fullscreen)
--   Hyper+F2  PBP layout / USB swap        (hammerspoon://monitor-pbp)
-- pure decision logic lives in monitor-plan.lua; this file is DDC I/O + bindings.

local plan = dofile(hs.spoons.resourcePath("monitor-plan.lua"))

local settings = _G.windowManagerSettings or {}
local BIN = settings.betterDisplayBin or "/opt/homebrew/bin/betterdisplaycli"
local NAME = settings.monitorName or "DELL U4025QW"

local HYPER = { "ctrl", "alt", "cmd", "shift" }
local SETTLE_US = 150000 -- 150 ms between a write and its verify read
local RETRY = 5

-- read a VCP register; returns the integer value, or nil if DDC is unreachable
local function ddcGet(vcp)
  local out = hs.execute(string.format('%s get -name="%s" -ddc -vcp=%s', BIN, NAME, vcp))
  return tonumber((out or ""):match("%d+"))
end

-- write a VCP register (fire-and-forget)
local function ddcSet(vcp, value)
  hs.execute(string.format('%s set -name="%s" -ddc -vcp=%s -value=%s', BIN, NAME, vcp, value))
end

-- write then confirm via read-back (low byte), retrying through transient NAKs
local function ddcSetVerified(vcp, value)
  local want = tonumber(value) % 256
  for _ = 1, RETRY do
    ddcSet(vcp, value)
    hs.timer.usleep(SETTLE_US)
    local got = ddcGet(vcp)
    if got and (got % 256) == want then return true end
    hs.timer.usleep(SETTLE_US)
  end
  return false
end

local function apply(ops)
  for _, op in ipairs(ops) do
    if op.kind == "setVerified" then
      ddcSetVerified(op.vcp, op.value)
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
