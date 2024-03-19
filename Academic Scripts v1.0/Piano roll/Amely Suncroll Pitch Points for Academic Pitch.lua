local reaper = reaper


function insertPitchBendOnSelectedNotesIfNotExist(take)
    local _, noteCount = reaper.MIDI_CountEvts(take)
    for i = 0, noteCount - 1 do
        local _, selected, _, startppqpos, endppqpos, _, _, _ = reaper.MIDI_GetNote(take, i)
        if selected and not pitchBendExists(take, startppqpos, endppqpos) then
            reaper.MIDI_InsertCC(take, false, false, startppqpos, 0xE0, 0, 64, 64) 
        end
    end
end

function pitchBendExists(take, startppqpos, endppqpos)
    local _, ccCount = reaper.MIDI_CountEvts(take)
    for i = 0, ccCount - 1 do
        local _, _, _, ppqpos, chanmsg, _, _, _ = reaper.MIDI_GetCC(take, i)
        if chanmsg == 224 and ppqpos >= startppqpos and ppqpos <= endppqpos then
            return true 
        end
    end
    return false 
end


function selectAllNotes(take)
    local _, noteCount = reaper.MIDI_CountEvts(take)
    for i = 0, noteCount - 1 do
        reaper.MIDI_SetNote(take, i, true, nil, nil, nil, nil, nil, nil, true) 
    end
end

function insertPitchBendOnSelectedNotes(take)
    local _, noteCount = reaper.MIDI_CountEvts(take)
    for i = 0, noteCount - 1 do
        local _, selected, _, startppqpos, _, _, _, _ = reaper.MIDI_GetNote(take, i)
        if selected then
            reaper.MIDI_InsertCC(take, false, false, startppqpos, 0xE0, 0, 64, 64) 
        end
    end
end

function unselectAllNotes(take)
    local _, noteCount = reaper.MIDI_CountEvts(take)
    for i = 0, noteCount - 1 do
        reaper.MIDI_SetNote(take, i, false, nil, nil, nil, nil, nil, nil, true) 
    end
end

function main()
    local editor = reaper.MIDIEditor_GetActive() 
    if editor == nil then return end
    local take = reaper.MIDIEditor_GetTake(editor) 
    if take == nil then return end

    reaper.Undo_BeginBlock() 
    reaper.MIDI_DisableSort(take) 

    selectAllNotes(take)
    insertPitchBendOnSelectedNotesIfNotExist(take)
    unselectAllNotes(take)

    reaper.MIDI_Sort(take) 
    reaper.Undo_EndBlock("Select All Notes, Insert Pitch Bend, Unselect All Notes", -1) 
end

main()
