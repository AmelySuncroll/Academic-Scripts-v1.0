local startX = 200  -- начальная координата X окна
local startY = 200  -- начальная координата Y окна
local startWidth = 500  -- начальная ширина окна
local startHeight = 400  -- начальная высота окна

gfx.init("Comments", startWidth, startHeight, 0, startX, startY)

local selectedItemIndex = -1
local textCoords = {}
local currentScenario = 1  -- 1 - первый сценарий, 2 - второй сценарий

local function getSortedTextItems()
    local textItems = {}
    local itemCount = reaper.CountMediaItems(0)
    for i = 0, itemCount - 1 do
        local item = reaper.GetMediaItem(0, i)
        local note = reaper.ULT_GetMediaItemNote(item)
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        if note and note ~= "" then
            table.insert(textItems, {item = item, index = i, startTime = itemStart})
        end
    end
    table.sort(textItems, function(a, b) return a.startTime < b.startTime end)
    return textItems
end


local function checkSelectedItem()
    local cursorPosition
    if reaper.GetPlayState() == 1 then 
        cursorPosition = reaper.GetPlayPosition() 
    else
        cursorPosition = reaper.GetCursorPosition() 
    end

    local itemCount = reaper.CountMediaItems(0)
    for i = 0, itemCount - 1 do
        local item = reaper.GetMediaItem(0, i)
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        
        if cursorPosition == itemStart then
            local note = reaper.ULT_GetMediaItemNote(item)
            if note and note ~= "" then
                selectedItemIndex = i
                return
            end
        elseif cursorPosition > itemStart and cursorPosition < itemEnd then
            local note = reaper.ULT_GetMediaItemNote(item)
            if note and note ~= "" then
                selectedItemIndex = i
                return
            end
        end
    end
    selectedItemIndex = -1 
end


local function updateSelectedItemFromProject()
    local itemCount = reaper.CountMediaItems(0)
    for i = 0, itemCount - 1 do
        local item = reaper.GetMediaItem(0, i)
        if reaper.IsMediaItemSelected(item) then
            local note = reaper.ULT_GetMediaItemNote(item)
            if note and note ~= "" then
                selectedItemIndex = i
                return
            end
        end
    end
    selectedItemIndex = -1 
end

local function breakTextToFitWidth(text, maxWidth)
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end

    local lines = {}
    local currentLine = words[1]
    for i = 2, #words do
        local testLine = currentLine .. " " .. words[i]
        local testWidth = gfx.measurestr(testLine)
        if testWidth <= maxWidth then
            currentLine = testLine
        else
            table.insert(lines, currentLine)
            currentLine = words[i]
        end
    end
    table.insert(lines, currentLine)
    return lines
end

local function drawScenarioStatus()
    gfx.setfont(1, "Arial", 16)
    gfx.set(1, 1, 1) 
    local statusText = "Current mode: " .. (currentScenario == 1 and "Cursor" or "Selected Item")
    local textWidth, textHeight = gfx.measurestr(statusText)
    gfx.x = (gfx.w - textWidth) / 2 
    gfx.y = gfx.h - textHeight - 10 
    gfx.drawstr(statusText)
end


local function drawTextItems(sortedTextItems)
    gfx.clear = 3355443
    local y = 20
    gfx.setfont(1, "Arial", 16)

    textCoords = {}

    local maxInfoWidth = 150 

    for textItemNumber, textItem in ipairs(sortedTextItems) do
        local itemStart = reaper.GetMediaItemInfo_Value(textItem.item, "D_POSITION")
        local itemLength = reaper.GetMediaItemInfo_Value(textItem.item, "D_LENGTH")
        local startTimeStr = string.format("%02d:%02d", math.floor(itemStart / 60), math.floor(itemStart % 60))
        local durationStr = string.format("%.2f sec", itemLength)
        local infoText = textItemNumber .. ". " .. startTimeStr .. " | " .. durationStr

        local note = reaper.ULT_GetMediaItemNote(textItem.item)

        if textItem.index == selectedItemIndex then
            gfx.set(0, 1, 0) 
        else
            gfx.set(1, 1, 1) 
        end

        
        gfx.x, gfx.y = 10, y
        gfx.drawstr(infoText, 0, maxInfoWidth, gfx.y + 20)

        
        local brokenLines = breakTextToFitWidth(note, gfx.w - maxInfoWidth - 20)
        for _, line in ipairs(brokenLines) do
            gfx.x, gfx.y = maxInfoWidth + 10, y
            gfx.drawstr(line)
            table.insert(textCoords, {yStart = y, yEnd = y + 20, index = textItem.index})
            y = y + 20
        end
    end
    drawScenarioStatus() 
    gfx.update()
end



local function updateSelection()
    if currentScenario == 1 then
        checkSelectedItem()
    else
        updateSelectedItemFromProject()
    end
end

function main()
    local sortedTextItems = getSortedTextItems()

    if currentScenario == 1 then
        if gfx.mouse_cap & 1 == 1 and gfx.mouse_y > 20 then
            for _, coords in ipairs(textCoords) do
                if gfx.mouse_y >= coords.yStart and gfx.mouse_y <= coords.yEnd then
                    selectedItemIndex = coords.index
                    local item = reaper.GetMediaItem(0, selectedItemIndex)
                    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    reaper.SetEditCurPos(itemStart, true, true)
                    updateSelection() 
                    break
                end
            end
        end
    elseif currentScenario == 2 then
        if gfx.mouse_cap & 1 == 1 and gfx.mouse_y > 20 then
            for _, coords in ipairs(textCoords) do
                if gfx.mouse_y >= coords.yStart and gfx.mouse_y <= coords.yEnd then
                    selectedItemIndex = coords.index
                    local item = reaper.GetMediaItem(0, selectedItemIndex)
                    reaper.SelectAllMediaItems(0, false)
                    reaper.SetMediaItemSelected(item, true)
                    reaper.UpdateArrange()
                    updateSelection()  
                    break
                end
            end
        end
    end

    drawTextItems(sortedTextItems)  

    local char = gfx.getchar()
    if char == -1 then 
        return
    elseif char == 27 then
        gfx.quit()
        return
    else
        if char == 49 then
            currentScenario = 1
        elseif char == 50 then
            currentScenario = 2
        end
        reaper.defer(main)
    end
end

main()