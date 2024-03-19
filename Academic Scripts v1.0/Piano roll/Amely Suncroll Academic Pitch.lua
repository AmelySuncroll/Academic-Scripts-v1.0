local reaper = reaper

local pitchBendValues = {
    ["bb"] = 0,
    ["b/b"] = 2048,
    ["b"] = 4096,
    ["b nat"] = 5460,
    ["/b"] = 6144,
    ["0"] = 8192,
    ["/#"] = 10240,
    ["# nat"] = 10922,
    ["#"] = 12288,
    ["#/#"] = 14336,
    ["##"] = 16383
}

local function deletePreviousPitchBend(take, startppqpos, endppqpos)
    local _, countCC, _, _ = reaper.MIDI_CountEvts(take)
    for i = countCC - 1, 0, -1 do
        local _, _, _, ppqpos, _, _, _, _ = reaper.MIDI_GetCC(take, i)
        if ppqpos >= startppqpos and ppqpos <= endppqpos then
            reaper.MIDI_DeleteCC(take, i)
        end
    end
end

local command_id = 40153

local function shortenSelectedNotes()
    
    reaper.MIDIEditor_LastFocused_OnCommand(40445, false)
end

local function lengthenSelectedNotes()
    
    reaper.MIDIEditor_LastFocused_OnCommand(40444, false)
end


local function applyPitchBend(bendValue)
    local itemCount = reaper.CountSelectedMediaItems(0)
    if itemCount == 0 then
        reaper.ShowMessageBox("No notes are selected. Please select some notes and try again.", "Error", 0)
        return
    end
    
    
    local lastNoteEndPPQPos = nil

    for i = 0, itemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        if take and reaper.TakeIsMIDI(take) then
            local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)
            for j = 0, noteCount - 1 do
                local _, selected, _, startppqpos, endppqpos, _, _, _ = reaper.MIDI_GetNote(take, j)
                if selected then
                    deletePreviousPitchBend(take, startppqpos, endppqpos)
                    reaper.MIDI_InsertCC(take, false, false, startppqpos, 0xE0, 0, bendValue & 0x7F, (bendValue >> 7) & 0x7F)
                    lastNoteEndPPQPos = math.max(lastNoteEndPPQPos or 0, endppqpos)
                end
            end

            
            if lastNoteEndPPQPos then
                
                local nextNoteIndex, nextNoteStartPPQPos = nil, nil
                for j = 0, noteCount - 1 do
                    local _, _, _, startppqpos, _, _, _, _ = reaper.MIDI_GetNote(take, j)
                    if startppqpos > lastNoteEndPPQPos then
                        nextNoteIndex, nextNoteStartPPQPos = j, startppqpos
                        break
                    end
                end

                
            end
        end
    end
    
    reaper.UpdateArrange()
end



local function getUserInput()
    local retval, userInput = reaper.GetUserInputs("Academic Pitch", 1, "Enter pitch value or accidentals:", "")
    if not retval then
        return nil 
    end

    local bendValue = pitchBendValues[userInput] or tonumber(userInput)
    if bendValue and bendValue >= 0 and bendValue <= 16383 then
        return bendValue 
    else
        reaper.ShowMessageBox("Please enter a valid number between 0 and 16383 or next accidentals: bb, b/b, b, /b, 0, /#, #, #/#, ##;  also b or # nat.", "Invalid Input", 0)
        return false 
    end
end

local function main()
    
    shortenSelectedNotes()

    while true do
        local bendValue = getUserInput()
        if bendValue == nil then 
            lengthenSelectedNotes()
            return
        elseif bendValue ~= false then 
            applyPitchBend(bendValue)
            break
        end
    end

    lengthenSelectedNotes()
    
end


main()
