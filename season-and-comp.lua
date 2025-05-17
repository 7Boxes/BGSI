-- Configuration
local HATCH_COUNT = 6 -- Number for hatch remote
local FINAL_HATCH_DELAY = 5 -- Extra seconds after 100%
local HATCH_INTERVAL = 0.2 -- Time between hatches
local HORIZONTAL_SPEED = 36 -- Studs per second for X/Z movement (configurable)
local Y_TWEEN_TIME = 1 -- Fixed 1 second for Y-axis movement
local DEBUG_LOGGING = true -- Detailed logging

-- Egg data with coordinates
local EGG_DATA = {
    ["Common"] = Vector3.new(-12.40, 15.66, -81.87),
    ["Spotted"] = Vector3.new(-12.63, 15.61, -70.52),
    ["Iceshard"] = Vector3.new(-12.57, 16.50, -59.62),
    ["Spikey"] = Vector3.new(-127.92, 16.25, 9.43),
    ["Magma"] = Vector3.new(-137.79, 15.58, 3.08),
    ["Crystal"] = Vector3.new(-144.64, 15.98, -5.11),
    ["Lunar"] = Vector3.new(-148.69, 15.88, -15.29),
    ["Void"] = Vector3.new(-149.83, 15.75, -26.63),
    ["Hell"] = Vector3.new(-149.49, 15.57, -36.71),
    ["Nightmare"] = Vector3.new(-146.16, 14.51, -47.57),
    ["Rainbow"] = Vector3.new(-139.45, 16.20, -55.40),
    ["Showman"] = Vector3.new(-130.84, 19.16, -63.48),
    ["Mining"] = Vector3.new(-121.83, 16.45, -67.70),
    ["Cyber"] = Vector3.new(-92.24, 16.11, -66.20),
    ["Infinity"] = Vector3.new(-104.93, 18.63, -28.01),
    ["Neon"] = Vector3.new(9883.46, 20095.29, 264.75) -- Special egg
}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Player setup
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
humanoid.WalkSpeed = 16 -- Normal walking speed (for non-tween movement)

-- Remote setup
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework"):WaitForChild("Network")
    :WaitForChild("Remote"):WaitForChild("RemoteEvent")

-- Logging system
local function log(message, isError)
    local timestamp = os.date("%H:%M:%S")
    local prefix = isError and "[ERROR]" or "[INFO]"
    print(string.format("%s [%s] %s", prefix, timestamp, tostring(message)))
end

-- Improved tween movement function with fixed Y-axis tween time
local function moveToPosition(targetPosition)
    -- First, move to ground level (Y = 0) while keeping X/Z - fixed 1 second
    local groundPosition = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
    
    local tweenInfo1 = TweenInfo.new(
        Y_TWEEN_TIME, -- Fixed 1 second for Y-axis movement
        Enum.EasingStyle.Linear
    )
    
    local tween1 = TweenService:Create(rootPart, tweenInfo1, {Position = groundPosition})
    tween1:Play()
    tween1.Completed:Wait()
    
    -- Next, move to target X/Z at ground level - uses configurable horizontal speed
    local midPosition = Vector3.new(targetPosition.X, 0, targetPosition.Z)
    local horizontalDistance = (groundPosition - midPosition).Magnitude
    local horizontalTime = horizontalDistance / HORIZONTAL_SPEED
    
    local tweenInfo2 = TweenInfo.new(
        horizontalTime,
        Enum.EasingStyle.Linear
    )
    
    local tween2 = TweenService:Create(rootPart, tweenInfo2, {Position = midPosition})
    tween2:Play()
    tween2.Completed:Wait()
    
    -- Finally, move up to target Y position - fixed 1 second
    local finalPosition = Vector3.new(targetPosition.X, targetPosition.Y + 3, targetPosition.Z)
    
    local tweenInfo3 = TweenInfo.new(
        Y_TWEEN_TIME, -- Fixed 1 second for Y-axis movement
        Enum.EasingStyle.Linear
    )
    
    local tween3 = TweenService:Create(rootPart, tweenInfo3, {Position = finalPosition})
    tween3:Play()
    tween3.Completed:Wait()
    
    -- Small jump to ensure we're properly positioned
    humanoid.Jump = true
    wait(0.2)
    
    return true
end

-- Modified getCurrentQuest function with better nil checks
local function getCurrentQuest()
    local success, gui = pcall(function() return player.PlayerGui.ScreenGui end)
    if not success or not gui then 
        if DEBUG_LOGGING then log("Failed to find ScreenGui", true) end
        return nil, nil, nil 
    end
    
    local competitive = gui:FindFirstChild("Competitive")
    if not competitive then 
        if DEBUG_LOGGING then log("Competitive not found", true) end
        return nil, nil, nil 
    end
    
    local frame = competitive:FindFirstChild("Frame")
    if not frame then 
        if DEBUG_LOGGING then log("Frame not found", true) end
        return nil, nil, nil 
    end
    
    local content = frame:FindFirstChild("Content")
    if not content then 
        if DEBUG_LOGGING then log("Content not found", true) end
        return nil, nil, nil 
    end
    
    local tasks = content:FindFirstChild("Tasks")
    if not tasks then 
        if DEBUG_LOGGING then log("Tasks not found", true) end
        return nil, nil, nil 
    end
    
    -- Safely get the 5th template
    local children = tasks:GetChildren()
    local template = #children >= 5 and children[5] or nil
    if not template then 
        if DEBUG_LOGGING then log("Template 5 not found", true) end
        return nil, nil, nil 
    end
    
    local contentFrame = template:FindFirstChild("Content")
    if not contentFrame then 
        if DEBUG_LOGGING then log("Content frame not found", true) end
        return nil, nil, nil 
    end
    
    -- Check quest type with nil checks
    local typeLabel = contentFrame:FindFirstChild("Type")
    if not typeLabel then 
        if DEBUG_LOGGING then log("Type label not found", true) end
        return nil, nil, nil 
    end
    
    -- Get quest details with nil checks
    local questLabel = contentFrame:FindFirstChild("Label")
    local barLabel = contentFrame.Bar and contentFrame.Bar:FindFirstChild("Label")
    
    return 
        typeLabel and typeLabel.Text or nil,
        questLabel and questLabel.Text or nil,
        barLabel and barLabel.Text or nil
end

-- Hatch egg function
local function hatchEgg(eggName)
    local args = {
        "HatchEgg",
        eggName.." Egg",
        HATCH_COUNT
    }
    RemoteEvent:FireServer(unpack(args))
end

-- Special Neon Egg handler
local function handleNeonEgg()
    log("Starting Neon Egg process", false)
    
    -- Teleport to Hyperwave Island
    RemoteEvent:FireServer("Teleport", "Workspace.Worlds.MinigameParadise.Islands.HyperwaveIsland.Island.Portal.Spawn")
    wait(5)
    
    -- Move to Neon Egg using tween
    if not moveToPosition(EGG_DATA["Neon"]) then 
        log("Failed to reach Neon Egg", true)
        return false 
    end
    
    -- Hatch until complete
    local startTime = tick()
    while tick() - startTime < 300 do
        local questType, questText, progress = getCurrentQuest()
        
        -- Stop if quest changed
        if not questText or not string.find(tostring(questText), "Neon") then break end
        
        hatchEgg("Neon")
        
        if progress and progress == "100%" then
            local finishTime = tick()
            while tick() - finishTime < FINAL_HATCH_DELAY do
                hatchEgg("Neon")
                wait(HATCH_INTERVAL)
            end
            break
        end
        
        wait(HATCH_INTERVAL)
    end
    
    -- Return to Overworld
    RemoteEvent:FireServer("Teleport", "Workspace.Worlds.The Overworld.FastTravel.Spawn")
    wait(5)
    return true
end

-- Main quest processor
local function processQuest()
    local questType, questText, progress = getCurrentQuest()
    
    -- Skip if we couldn't get quest info
    if not questType or not questText then
        if DEBUG_LOGGING then log("Failed to get quest information", false) end
        return false
    end
    
    -- Skip if not repeatable
    if questType ~= "Repeatable" then
        if DEBUG_LOGGING then log("Skipping non-repeatable quest: "..tostring(questType), false) end
        return false
    end
    
    -- Safely convert to lowercase for matching
    local questTextLower = string.lower(tostring(questText))
    
    -- Check for Pet quest (hatch Infinity Egg)
    if string.find(questTextLower, "pet") then
        if DEBUG_LOGGING then log("Processing Pet quest - hatching Infinity Egg", false) end
        
        if not moveToPosition(EGG_DATA["Infinity"]) then
            if DEBUG_LOGGING then log("Failed to reach Infinity Egg", true) end
            return false
        end
        
        local startTime = tick()
        while tick() - startTime < 300 do
            local currentType, currentText, currentProgress = getCurrentQuest()
            
            -- Stop if quest changed or invalid
            if not currentText or not string.find(string.lower(tostring(currentText)), "pet") then 
                break 
            end
            
            hatchEgg("Infinity")
            
            if currentProgress and currentProgress == "100%" then
                local finishTime = tick()
                while tick() - finishTime < FINAL_HATCH_DELAY do
                    hatchEgg("Infinity")
                    wait(HATCH_INTERVAL)
                end
                break
            end
            
            wait(HATCH_INTERVAL)
        end
        return true
    end
    
    -- Check for specific egg quests
    for eggName, _ in pairs(EGG_DATA) do
        if questText and string.find(tostring(questText), eggName) then
            if DEBUG_LOGGING then log("Found egg quest for: "..tostring(eggName), false) end
            
            if eggName == "Neon" then
                return handleNeonEgg()
            end
            
            if not moveToPosition(EGG_DATA[eggName]) then
                if DEBUG_LOGGING then log("Failed to reach "..tostring(eggName).." Egg", true) end
                return false
            end
            
            local startTime = tick()
            while tick() - startTime < 300 do
                local currentType, currentText, currentProgress = getCurrentQuest()
                
                if not currentText or not string.find(tostring(currentText), eggName) then 
                    break 
                end
                
                hatchEgg(eggName)
                
                if currentProgress and currentProgress == "100%" then
                    local finishTime = tick()
                    while tick() - finishTime < FINAL_HATCH_DELAY do
                        hatchEgg(eggName)
                        wait(HATCH_INTERVAL)
                    end
                    break
                end
                
                wait(HATCH_INTERVAL)
            end
            return true
        end
    end
    
    if DEBUG_LOGGING then log("Skipping unrecognized quest: "..tostring(questText), false) end
    return false
end

-- Main loop
log("Egg Hatching Script Started (Horizontal Speed: "..HORIZONTAL_SPEED.." studs/sec, Y-Tween: "..Y_TWEEN_TIME.." sec)", false)

-- Disable collisions for character
for _, part in ipairs(character:GetDescendants()) do
    if part:IsA("BasePart") then
        part.CanCollide = false
    end
end

-- Keep disabling collision for new parts
character.ChildAdded:Connect(function(child)
    if child:IsA("BasePart") then
        child.CanCollide = false
    end
end)

-- Main execution loop
while true do
    local success, err = pcall(processQuest)
    if not success then
        log("Error in processQuest: "..tostring(err), true)
    end
    
    wait(1)
end
