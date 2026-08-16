-- monitor-plan.lua
-- This module makes the decisions for the Dell U4025QW monitor keys.
-- The module does not use hs.*. A plain Lua interpreter can test it.

local M = {}

-- These are the VCP registers of the U4025QW. They are constants of the
-- monitor. They are not user settings.
M.codes = {
  input = "0x60",     -- The primary input.
  secondary = "0xE8", -- The secondary input in PBP mode.
  mode = "0xE9",      -- The PBP mode.
  usb = "0xE7",       -- The USB switch. You can write it only. It works in PBP mode.
}
M.PBP = 0x24    -- The value of register 0xE9 for 50/50 PBP mode.
M.SINGLE = 0    -- The value of register 0xE9 for single mode.
M.HDMI = 17     -- The low byte of register 0x60 for HDMI.
M.TB = 25       -- The low byte of register 0x60 for Thunderbolt.

-- planActions(key, mode, input) gives a list of operations.
--   key   : "F1" or "F2".
--   mode  : M.SINGLE (0) or M.PBP (0x24).
--   input : M.HDMI (17) or M.TB (25). F1 needs the input in single mode only.
-- An operation is one of these:
--   { kind = "set" or "setVerified", vcp = <string>, value = <string> }
--   { kind = "settle", ms = <number> }   -- The delay in milliseconds.
function M.planActions(key, mode, input)
  if key == "F1" then
    if mode == M.PBP then
      -- Change the primary input to HDMI, then stop PBP mode. The monitor shows
      -- HDMI fullscreen. Change the input first, while both inputs still show in
      -- PBP mode. Then the monitor does not show Thunderbolt, and no settle
      -- delay is necessary. The verified write holds on the first try in stable
      -- PBP mode.
      return {
        { kind = "setVerified", vcp = M.codes.input, value = tostring(M.HDMI) },
        { kind = "set", vcp = M.codes.mode, value = "0" },
      }
    else
      -- Single mode. Change the input. The USB hub goes to the active input.
      local target = (input == M.TB) and M.HDMI or M.TB
      return { { kind = "set", vcp = M.codes.input, value = tostring(target) } }
    end
  elseif key == "F2" then
    if mode == M.PBP then
      -- Move the USB hub to the other machine.
      return { { kind = "set", vcp = M.codes.usb, value = "0xFF00" } }
    else
      -- Make the fixed layout: Thunderbolt on the left, HDMI on the right.
      -- PBP mode starts slowly. It ends with the active input as the primary.
      -- Wait before you change the primary input. If you change it too soon,
      -- PBP mode changes it back. Then change the primary input with a verified
      -- write. setVerified reads the value two times, because one read can show
      -- a wrong value during the change.
      return {
        { kind = "set", vcp = M.codes.mode, value = "0x24" },
        { kind = "settle", ms = 2000 },
        { kind = "setVerified", vcp = M.codes.input, value = tostring(M.TB) },
        { kind = "setVerified", vcp = M.codes.secondary, value = tostring(M.HDMI) },
      }
    end
  end
  error("planActions: unknown key " .. tostring(key))
end

return M
