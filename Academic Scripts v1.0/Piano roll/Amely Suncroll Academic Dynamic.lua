local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) 

if not take then 
    return reaper.MB("No active MIDI editor found", "Error", 0)
end

local function getUserInput()
    local retval, user_input = reaper.GetUserInputs("Academic Dynamic", 1, "Enter value (ppp (to) fff, 123):", "")
    if not retval then return nil end 
    return user_input
end

local function isValidInput(user_input)
    local velocityMap = {
        ppp = true,
        pp = true,
        p = true,
        mp = true,
        mf = true,
        f = true,
        ff = true,
        fff = true,
        cresc = true,
        dim = true
    }
    
    
    local exactValue = tonumber(user_input)
    if exactValue and exactValue >= 1 and exactValue <= 127 then
        return true
    end

    
    local startVel, endVel = user_input:match("^(%d+)%s+to%s+(%d+)$")
    if startVel and endVel then
        startVel, endVel = tonumber(startVel), tonumber(endVel)
        if startVel >= 1 and startVel <= 127 and endVel >= 1 and endVel <= 127 then
            return true
        end
    end

    
    if velocityMap[user_input] then
        return true
    end

    
    local fromDynamic, toDynamic = user_input:match("(%w+)%sto%s(%w+)")
    if fromDynamic and toDynamic and velocityMap[fromDynamic] and velocityMap[toDynamic] then
        return true
    end

    
    if user_input:match("^to%s+(%w+)$") then
        return true
    end

    return false
end

local user_input
repeat
    user_input = getUserInput()
    if user_input == nil then return end 
    
    if not isValidInput(user_input) then
        reaper.MB("Invalid input! \n \nYou can type: mf, to mf, mf to mp; 123, to 123, 123 to 123; cresc, dim \n \nBest, Amely Suncroll", "Error", 0)
    end
until isValidInput(user_input)



local velocityMap = {
    ppp = 16,
    pp = 32,
    p = 48,
    mp = 64,
    mf = 80,
    f = 96,
    ff = 112,
    fff = 127
}

local note_count = reaper.MIDI_CountEvts(take)
local firstSelectedIdx, lastSelectedIdx


for i = 0, note_count - 1 do
    local retval, selected = reaper.MIDI_GetNote(take, i)
    if selected then
        if not firstSelectedIdx then
            firstSelectedIdx = i
        end
        lastSelectedIdx = i
    end
end

if not (firstSelectedIdx and lastSelectedIdx) then
    return reaper.MB("No notes selected!", "Error", 0)
end

local noteBefore, noteAfter

if firstSelectedIdx > 0 then
    local retval, _, _, _, _, _, _, vel = reaper.MIDI_GetNote(take, firstSelectedIdx - 1)
    noteBefore = vel
end

if lastSelectedIdx < note_count - 1 then
    local retval, _, _, _, _, _, _, vel = reaper.MIDI_GetNote(take, lastSelectedIdx + 1)
    noteAfter = vel
end

local dynamics = {}
for dynamic in user_input:gmatch("(%w+)") do
    if velocityMap[dynamic] then
        table.insert(dynamics, velocityMap[dynamic])
    end
end

local command_id = 40153

local totalSections = #dynamics - 1
local notesPerSection = (lastSelectedIdx - firstSelectedIdx) / totalSections

local exactValue = tonumber(user_input)

if #dynamics >= 2 then
    
    for i = firstSelectedIdx, lastSelectedIdx do
        local section = math.min(math.floor((i - firstSelectedIdx) / notesPerSection) + 1, totalSections)
        local alpha = ((i - firstSelectedIdx) - (notesPerSection * (section - 1))) / notesPerSection
        local interpolated_vel = dynamics[section] + alpha * (dynamics[section + 1] - dynamics[section])
        interpolated_vel = math.floor(interpolated_vel + 0.5)

        local retval, selected, muted, startppqpos, endppqpos, chanmsg, pitch, vel = reaper.MIDI_GetNote(take, i)
        if selected then
            reaper.MIDI_SetNote(take, i, selected, muted, startppqpos, endppqpos, chanmsg, pitch, interpolated_vel, false)
        end
    end
elseif velocityMap[user_input] then
    
    for i = firstSelectedIdx, lastSelectedIdx do
        local retval, selected, muted, startppqpos, endppqpos, chanmsg, pitch, vel = reaper.MIDI_GetNote(take, i)
        if selected then
            reaper.MIDI_SetNote(take, i, selected, muted, startppqpos, endppqpos, chanmsg, pitch, velocityMap[user_input], false)
        end
    end
elseif exactValue and exactValue >= 1 and exactValue <= 127 then
    
    for i = firstSelectedIdx, lastSelectedIdx do
        local retval, selected, muted, startppqpos, endppqpos, chanmsg, pitch, vel = reaper.MIDI_GetNote(take, i)
        if selected then
            reaper.MIDI_SetNote(take, i, selected, muted, startppqpos, endppqpos, chanmsg, pitch, exactValue, false)
        end
    end
elseif user_input:match("^%d+%s+to%s+%d+$") then
    
    local startVel, endVel = user_input:match("^(%d+)%s+to%s+(%d+)$")
    startVel, endVel = tonumber(startVel), tonumber(endVel)
    local totalNotes = lastSelectedIdx - firstSelectedIdx
    for i = firstSelectedIdx, lastSelectedIdx do
        local alpha = (i - firstSelectedIdx) / totalNotes
        local interpolated_vel = startVel + alpha * (endVel - startVel)
        interpolated_vel = math.floor(interpolated_vel + 0.5)
        interpolated_vel = math.max(1, math.min(interpolated_vel, 127)) 

        local retval, selected, muted, startppqpos, endppqpos, chanmsg, pitch = reaper.MIDI_GetNote(take, i)
        if selected then
            reaper.MIDI_SetNote(take, i, selected, muted, startppqpos, endppqpos, chanmsg, pitch, interpolated_vel, false)
        end
    end
    reaper.MIDI_Sort(take)
elseif user_input:match("^to%s+(%w+)$") then
    local targetDynamic = user_input:match("^to%s+(%w+)$")
    local targetVelocity = velocityMap[targetDynamic] or tonumber(targetDynamic)
    if not targetVelocity or targetVelocity < 1 or targetVelocity > 127 then
        return reaper.MB("Invalid target dynamic!", "Error", 0)
    end

    
    local _, _, _, _, _, _, _, firstNoteVel = reaper.MIDI_GetNote(take, firstSelectedIdx)
    local velocityDifference = firstNoteVel - targetVelocity

    
    for i = firstSelectedIdx, lastSelectedIdx do
        local retval, selected, muted, startppqpos, endppqpos, chanmsg, pitch, vel = reaper.MIDI_GetNote(take, i)
        if selected then
            
            local newVel = math.max(1, math.min(127, vel - velocityDifference))
            reaper.MIDI_SetNote(take, i, selected, muted, startppqpos, endppqpos, chanmsg, pitch, newVel, false)
        end
    end
elseif user_input == "cresc" and noteBefore and noteAfter then
    local totalNotes = lastSelectedIdx - firstSelectedIdx + 1
    for i = firstSelectedIdx, lastSelectedIdx do
        local alpha = (i - firstSelectedIdx) / totalNotes
        local interpolated_vel = noteBefore + alpha * (noteAfter - noteBefore)
        interpolated_vel = math.floor(interpolated_vel + 0.5)
        
        local retval, selected, muted, startppqpos, endppqpos, chanmsg, pitch, vel = reaper.MIDI_GetNote(take, i)
        if selected then
            reaper.MIDI_SetNote(take, i, selected, muted, startppqpos, endppqpos, chanmsg, pitch, interpolated_vel, false)
        end
    end
elseif user_input == "dim" and noteBefore and noteAfter then
    local totalNotes = lastSelectedIdx - firstSelectedIdx + 1
    for i = firstSelectedIdx, lastSelectedIdx do
        local alpha = 1 - ((i - firstSelectedIdx) / totalNotes)
        local interpolated_vel = noteAfter + alpha * (noteBefore - noteAfter)
        interpolated_vel = math.floor(interpolated_vel + 0.5)
        
        local retval, selected, muted, startppqpos, endppqpos, chanmsg, pitch, vel = reaper.MIDI_GetNote(take, i)
        if selected then
            reaper.MIDI_SetNote(take, i, selected, muted, startppqpos, endppqpos, chanmsg, pitch, interpolated_vel, false)
        end
    end
else
    reaper.MB("Invalid input! \n \nYou can type: mf, to mf, mf to mp (etc), cresc, dim \n \nBest, Amely Suncroll", "Error", 0)
    return false
    
end



reaper.MIDI_Sort(take)


    