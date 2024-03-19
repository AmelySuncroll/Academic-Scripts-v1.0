function MoveEditCursorToStartOfSelectedMIDIEvents()
    local midiEditor = reaper.MIDIEditor_GetActive()
    if not midiEditor then
        return 
    end
    
    local take = reaper.MIDIEditor_GetTake(midiEditor)
    if not take or not reaper.TakeIsMIDI(take) then
        return 
    end
    
    
    local noteSelected = false
    local _, notecnt = reaper.MIDI_CountEvts(take)
    for i = 0, notecnt - 1 do
        local _, selected = reaper.MIDI_GetNote(take, i)
        if selected then
            noteSelected = true
            break
        end
    end
    
    if noteSelected then
        local commandId = 40872
        reaper.MIDIEditor_LastFocused_OnCommand(commandId, false)
    end
end


local script_identifier = "_MyScriptToggle"

local function IsScriptToggledOn()
    return reaper.GetExtState(script_identifier, "Running") == "1"
end

local function SetScriptToggle(state)
    if state then
        reaper.SetExtState(script_identifier, "Running", "1", false)
    else
        reaper.DeleteExtState(script_identifier, "Running", false)
    end
end

local last_time = reaper.time_precise()

function Main()
    local current_time = reaper.time_precise()
    if current_time - last_time >= 0.5 then 
        MoveEditCursorToStartOfSelectedMIDIEvents()
        last_time = current_time
    end
    if IsScriptToggledOn() then
        reaper.defer(Main)
    else
        Exit()
    end
end


function Exit()
    reaper.MB("Script terminated", "Auto Aim Midi (Amely Suncroll)", 0)
    SetScriptToggle(false)
end


if not IsScriptToggledOn() then
    
    reaper.MB("Script working", "Auto Aim Midi (Amely Suncroll)", 0)
    SetScriptToggle(true)
    reaper.defer(Main)
else
    
    Exit()
end

reaper.atexit(Exit)