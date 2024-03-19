local extStateSection = "MyCustomScript"
local extStateKey = "isCommandsActive"


local cmdSNMInputAllCh = reaper.NamedCommandLookup("_S&M_MIDI_INPUT_ALL_CH")
local cmdSNMMapInputCh1 = reaper.NamedCommandLookup("_S&M_MAP_MIDI_INPUT_CH1")


function RunCommands()

  local state
  
  state = reaper.GetToggleCommandState(40740)
  if state ~= 1 then reaper.Main_OnCommand(40740, 0) end
  
  state = reaper.GetToggleCommandState(40637)
  if state ~= 1 then reaper.Main_OnCommand(40637, 0) end
  
  state = reaper.GetToggleCommandState(40377)
  if state ~= 1 then reaper.Main_OnCommand(40377, 0) end
  
  
  reaper.Main_OnCommand(cmdSNMInputAllCh, 0)
  reaper.Main_OnCommand(cmdSNMMapInputCh1, 0)
end


function ToggleCommands()
  
  reaper.Main_OnCommand(40740, 0)
  reaper.Main_OnCommand(40637, 0)
  reaper.Main_OnCommand(40377, 0)
  reaper.Main_OnCommand(cmdSNMInputAllCh, 0)
  reaper.Main_OnCommand(cmdSNMMapInputCh1, 0)
end


function SetScriptState(state)
  reaper.SetExtState(extStateSection, extStateKey, tostring(state), false)
end


function GetScriptState()
  return reaper.GetExtState(extStateSection, extStateKey) == "true"
end

if not GetScriptState() then
  
  RunCommands()
  SetScriptState(true)
  reaper.MB("Piano mode is on", "Academic Piano", 0)
else
  
  RunCommands()
  
  ToggleCommands()
  SetScriptState(false)
  reaper.MB("Piano mode is off", "Academic Piano", 0)
end


reaper.UpdateArrange()
