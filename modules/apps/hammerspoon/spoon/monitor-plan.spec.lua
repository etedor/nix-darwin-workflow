-- plain-lua unit tests for monitor-plan.planActions (no hs.* required)
local here = arg[0]:gsub("[^/]*$", "")
local M = dofile(here .. "monitor-plan.lua")

local fails = 0
local function ser(ops)
  local t = {}
  for _, o in ipairs(ops) do t[#t + 1] = o.kind .. ":" .. o.vcp .. "=" .. o.value end
  return table.concat(t, ",")
end
local function check(name, got, want)
  local g = ser(got)
  if g ~= want then
    io.stderr:write("FAIL " .. name .. "\n  got:  " .. g .. "\n  want: " .. want .. "\n")
    fails = fails + 1
  else
    io.write("ok   " .. name .. "\n")
  end
end

check("F1 in PBP exits to fullscreen",  M.planActions("F1", M.PBP, nil),    "set:0xE9=0")
check("F1 single on TB toggles to HDMI", M.planActions("F1", M.SINGLE, M.TB),  "set:0x60=17")
check("F1 single on HDMI toggles to TB", M.planActions("F1", M.SINGLE, M.HDMI), "set:0x60=25")
check("F2 in PBP toggles USB",          M.planActions("F2", M.PBP, nil),    "set:0xE7=0xFF00")
check("F2 single enters fixed PBP",     M.planActions("F2", M.SINGLE, nil),
  "set:0xE9=0x24,setVerified:0x60=25,setVerified:0xE8=17")

if fails > 0 then os.exit(1) end
io.write("all passed\n")
