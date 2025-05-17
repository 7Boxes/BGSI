-- Configuration
local HATCH_COUNT = 6 -- Number for hatch remote
local FINAL_HATCH_DELAY = 5 -- Extra seconds after 100%
local HATCH_INTERVAL = 0.2 -- Time between hatches
local MOVE_SPEED = 12 -- Studs per second (adjustable)
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

-- Player setup
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Remote setup
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework"):WaitForChild("Network")
    :WaitForChild("Remote"):WaitForChild("RemoteEvent")

-- Logging system
local function log(message, isError)
    local timestamp = os.date("%H:%M:%S")
    local prefix = isError and "[ERROR]" or "[INFO]"
    print(string.format("%s [%s] %s", prefix, timestamp, message))
end

-- Simple movement function
local function moveToPosition(targetPosition)
    local startTime = tick()
    local distance = (rootPart.Position - targetPosition).Magnitude
    local moveTime = distance / MOVE_SPEED
    
    while (rootPart.Position - targetPosition).Magnitude > 5 and tick() - startTime < moveTime + 5 do
        local direction = (targetPosition - rootPart.Position).Unit
        local moveStep = direction * MOVE_SPEED * 0.1
        
        -- Move while maintaining current Y position
        rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(moveStep.X, 0, moveStep.Z))
        
        -- Check if stuck
        if tick() - startTime > moveTime * 1.5 then
            log("Movement taking too long - jumping", true)
            humanoid.Jump = true
        end
        
        wait(0.1)
    end
    
    return (rootPart.Position - targetPosition).Magnitude <= 5
end

-- Get current quest info
local function getCurrentQuest()
    local success, gui = pcall(function() return player.PlayerGui.ScreenGui end)
    if not success then log("Failed to find ScreenGui", true) return nil, nil, nil end
    
    local competitive = gui:FindFirstChild("Competitive")
    if not competitive then log("Competitive not found", true) return nil, nil, nil end
    
    local frame = competitive:FindFirstChild("Frame")
    if not frame then log("Frame not found", true) return nil, nil, nil end
    
    local content = frame:FindFirstChild("Content")
    if not content then log("Content not found", true) return nil, nil, nil end
    
    local tasks = content:FindFirstChild("Tasks")
    if not tasks then log("Tasks not found", true) return nil, nil, nil end
    
    -- Get the 5th template (as per your image)
    local template = tasks:GetChildren()[5]
    if not template then log("Template 5 not found", true) return nil, nil, nil end
    
    local contentFrame = template:FindFirstChild("Content")
    if not contentFrame then log("Content frame not found", true) return nil, nil, nil end
    
    -- Check quest type
    local typeLabel = contentFrame:FindFirstChild("Type")
    if not typeLabel then log("Type label not found", true) return nil, nil, nil end
    
    -- Get quest details
    local questLabel = contentFrame:FindFirstChild("Label")
    local barLabel = contentFrame.Bar and contentFrame.Bar:FindFirstChild("Label")
    
    return typeLabel.Text, questLabel and questLabel.Text, barLabel and barLabel.Text
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
    
    -- Move to Neon Egg
    if not moveToPosition(EGG_DATA["Neon"]) then 
        log("Failed to reach Neon Egg", true)
        return false 
    end
    
    -- Hatch until complete
    local startTime = tick()
    while tick() - startTime < 300 do
        local questType, questText, progress = getCurrentQuest()
        
        -- Stop if quest changed
        if not questText or not string.find(questText, "Neon") then break end
        
        hatchEgg("Neon")
        
        if progress == "100%" then
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
    
    -- Skip if not repeatable
    if questType ~= "Repeatable" then
        log("Skipping non-repeatable quest", false)
        return false
    end
    
    if not questText then
        log("No quest text found", false)
        return false
    end
    
    -- Convert to lowercase for easier matching
    local questTextLower = string.lower(questText)
    
    -- Check for Pet quest (hatch Infinity Egg)
    if string.find(questTextLower, "pet") then
        log("Processing Pet quest - hatching Infinity Egg", false)
        
        -- Move to Infinity Egg
        if not moveToPosition(EGG_DATA["Infinity"]) then
            log("Failed to reach Infinity Egg", true)
            return false
        end
        
        -- Hatch until complete
        local startTime = tick()
        while tick() - startTime < 300 do
            local currentType, currentText, currentProgress = getCurrentQuest()
            
            -- Stop if quest changed or no longer contains "Pet"
            if not currentText or not string.find(string.lower(currentText), "pet") then break end
            
            hatchEgg("Infinity")
            
            if currentProgress == "100%" then
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
        if string.find(questText, eggName) then
            log("Found egg quest for: "..eggName, false)
            
            -- Special Neon handling
            if eggName == "Neon" then
                return handleNeonEgg()
            end
            
            -- Move to egg
            if not moveToPosition(EGG_DATA[eggName]) then
                log("Failed to reach "..eggName.." Egg", true)
                return false
            end
            
            -- Hatch until complete
            local startTime = tick()
            while tick() - startTime < 300 do
                local currentType, currentText, currentProgress = getCurrentQuest()
                
                -- Stop if quest changed
                if not currentText or not string.find(currentText, eggName) then break end
                
                hatchEgg(eggName)
                
                if currentProgress == "100%" then
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
    
    log("Skipping unrecognized quest: "..questText, false)
    return false
end

-- Main loop
log("Egg Hatching Script Started (Speed: "..MOVE_SPEED.." studs/sec)", false)

-- Disable character collisions to prevent wall sticking
for _, part in ipairs(character:GetDescendants()) do
    if part:IsA("BasePart") then
        part.CanCollide = false
    end
end

character.ChildAdded:Connect(function(child)
    if child:IsA("BasePart") then
        child.CanCollide = false
    end
end)

while true do
    local success, err = pcall(processQuest)
    if not success then
        log("Error in processQuest: "..tostring(err), true)
    end
    
    wait(1)
end
