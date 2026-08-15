-- monitor-plan.lua
-- pure decision logic for the Dell U4025QW monitor binds.
-- no hs.* dependency so it can be unit-tested with a plain Lua interpreter.

local M = {}

-- VCP register semantics for the U4025QW (monitor-model constants, not user config)
M.codes = {
  input = "0x60",     -- primary / current input source
  secondary = "0xE8", -- PBP secondary input
  mode = "0xE9",      -- PBP mode
  usb = "0xE7",       -- USB-hub toggle (write-only, PBP)
}
M.PBP = 0x24    -- 0xE9 value for 50/50 PBP
M.SINGLE = 0    -- 0xE9 value for single/fullscreen
M.HDMI = 17     -- 0x60 low byte
M.TB = 25       -- 0x60 low byte

-- planActions(key, mode, input) -> list of ops
--   key   : "F1" | "F2"
--   mode  : M.SINGLE (0) or M.PBP (0x24)
--   input : M.HDMI (17) | M.TB (25); required only for F1 in single mode
-- op    : { kind = "set" | "setVerified", vcp = <string>, value = <string> }
--       | { kind = "settle", ms = <number> }  (pause between DDC writes)
function M.planActions(key, mode, input)
  if key == "F1" then
    if mode == M.PBP then
      -- exit PBP: monitor lands on primary (Thunderbolt), fullscreen
      return { { kind = "set", vcp = M.codes.mode, value = "0" } }
    else
      -- single: toggle input; the USB hub auto-follows the active input
      local target = (input == M.TB) and M.HDMI or M.TB
      return { { kind = "set", vcp = M.codes.input, value = tostring(target) } }
    end
  elseif key == "F2" then
    if mode == M.PBP then
      -- flip the USB hub to the other machine
      return { { kind = "set", vcp = M.codes.usb, value = "0xFF00" } }
    else
      -- enter the fixed layout: TB primary/left, HDMI secondary/right.
      -- entering PBP is a slow transition that ends with the active input as
      -- primary; settle before swapping or the transition reverts the swap.
      -- the swap is then a stable-verified write (single-read verify passes on
      -- a mid-transition transient, so setVerified requires the value to hold).
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
