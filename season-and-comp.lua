-- Configuration
local HATCH_COUNT = 6 -- Number for hatch remote
local FINAL_HATCH_DELAY = 5 -- Extra seconds after 100%
local HATCH_INTERVAL = 0.2 -- Time between hatches
local HORIZONTAL_SPEED = 36 -- Studs per second for X/Z movement
local Y_TWEEN_TIME = 1 -- Fixed 1 second for Y-axis movement
local DEBUG_LOGGING = true -- Detailed logging
local WALK_SPEED = 16 -- Normal walking speed
local SKIP_UNRECOGNIZED_QUESTS = true -- Enable/disable auto-skipping unrecognized quests

-- Enhanced Teleport Settings
local TELEPORT = {
    NEON = {
        args = {"Teleport", "Workspace.Worlds.Minigame Paradise.Islands.Hyperwave Island.Island.Portal.Spawn"},
        name = "Neon Island"
    },
    OVERWORLD = {
        args = {"Teleport", "Workspace.Worlds.The Overworld.FastTravel.Spawn"},
        name = "Overworld"
    }
}

local SPAM_SETTINGS = {
    attempts = 0,
    max_attempts = 50,
    delay = 0.05, -- 50ms between attempts (~20/sec)
    timeout = 10, -- Max seconds to try
    position_threshold = 5 -- Distance change required
}

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
    ["Neon"] = Vector3.new(9883.17, 20095.92, 265.26) -- Updated precise Neon Egg position
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
humanoid.WalkSpeed = WALK_SPEED

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

-- Enhanced teleport with position monitoring and rotation fix
local function smartTeleport(destination)
    local originalPos = rootPart.Position
    if DEBUG_LOGGING then log("Attempting teleport to "..destination.name.." from position: "..tostring(originalPos), false) end
    
    local startTime = os.clock()
    SPAM_SETTINGS.attempts = 0
    
    while os.clock() - startTime < SPAM_SETTINGS.timeout and SPAM_SETTINGS.attempts < SPAM_SETTINGS.max_attempts do
        RemoteEvent:FireServer(unpack(destination.args))
        SPAM_SETTINGS.attempts += 1
        
        -- Check for position change every 5 attempts
        if SPAM_SETTINGS.attempts % 5 == 0 then
            if (rootPart.Position - originalPos).Magnitude > SPAM_SETTINGS.position_threshold then
                if DEBUG_LOGGING then log("Teleport successful after "..SPAM_SETTINGS.attempts.." attempts", false) end
                
                -- Reset character rotation after teleport
                rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(180), 0)
                humanoid.Jump = true
                wait(0.5)
                
                return true
            end
        end
        
        wait(SPAM_SETTINGS.delay)
    end
    
    if DEBUG_LOGGING then log("Teleport failed after "..SPAM_SETTINGS.attempts.." attempts", true) end
    return false
end

-- Improved tween movement function for regular eggs
local function moveToPosition(targetPosition)
    -- First, move to ground level (Y = 0) while keeping X/Z - fixed 1 second
    local groundPosition = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
    
    local tweenInfo1 = TweenInfo.new(
        Y_TWEEN_TIME,
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
        Y_TWEEN_TIME,
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

-- Special movement function for Neon Egg with rotation control
local function moveToNeonEgg()
    local targetPos = EGG_DATA["Neon"]
    humanoid.WalkSpeed = WALK_SPEED
    
    -- Face the correct direction before moving
    local lookVector = (targetPos - rootPart.Position).Unit
    rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookVector)
    
    -- Move to target
    humanoid:MoveTo(targetPos)
    
    -- Wait until arrived or timeout
    local startTime = tick()
    while (rootPart.Position - targetPos).Magnitude > 3 and tick() - startTime < 30 do
        -- Continuously ensure proper rotation
        rootPart.CFrame = CFrame.new(rootPart.Position, targetPos)
        wait(0.1)
    end
    
    -- Final position adjustment
    rootPart.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(180), 0)
    humanoid.Jump = true
    wait(0.5)
    
    return (rootPart.Position - targetPos).Magnitude <= 3
end

-- Get current quest info with nil checks
local function getCurrentQuest()
    local success, gui = pcall(function() return player.PlayerGui.ScreenGui end)
    if not success or not gui then return nil, nil, nil end
    
    local competitive = gui:FindFirstChild("Competitive")
    if not competitive then return nil, nil, nil end
    
    local frame = competitive:FindFirstChild("Frame")
    if not frame then return nil, nil, nil end
    
    local content = frame:FindFirstChild("Content")
    if not content then return nil, nil, nil end
    
    local tasks = content:FindFirstChild("Tasks")
    if not tasks then return nil, nil, nil end
    
    local children = tasks:GetChildren()
    local template = #children >= 5 and children[5] or nil
    if not template then return nil, nil, nil end
    
    local contentFrame = template:FindFirstChild("Content")
    if not contentFrame then return nil, nil, nil end
    
    local typeLabel = contentFrame:FindFirstChild("Type")
    if not typeLabel then return nil, nil, nil end
    
    local questLabel = contentFrame:FindFirstChild("Label")
    local barLabel = contentFrame.Bar and contentFrame.Bar:FindFirstChild("Label")
    
    return 
        typeLabel.Text,
        questLabel and questLabel.Text,
        barLabel and barLabel.Text
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

-- Function to skip competitive quests
local function skipCompetitiveQuest()
    if not SKIP_UNRECOGNIZED_QUESTS then return end
    
    local args = {
        "CompetitiveRetail",
        4
    }
    
    RemoteEvent:FireServer(unpack(args))
    if DEBUG_LOGGING then log("Attempted to skip unrecognized quest", false) end
end

-- Special Neon Egg handler with improved movement
local function handleNeonEgg()
    log("Starting Neon Egg process", false)
    
    -- Teleport to Hyperwave Island with smart teleport
    if not smartTeleport(TELEPORT.NEON) then
        log("Failed to teleport to Neon Island", true)
        return false
    end
    
    -- Walk to Neon Egg with rotation fixes
    if not moveToNeonEgg() then
        log("Failed to reach Neon Egg position", true)
        return false
    end
    
    -- Hatch until complete
    local startTime = tick()
    while tick() - startTime < 300 do
        local questType, questText, progress = getCurrentQuest()
        
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
    
    -- Return to Overworld with smart teleport
    if not smartTeleport(TELEPORT.OVERWORLD) then
        log("Failed to teleport back to Overworld", true)
        return false
    end
    
    return true
end

-- Main quest processor
local function processQuest()
    local questType, questText, progress = getCurrentQuest()
    
    if not questType or not questText then
        if DEBUG_LOGGING then log("Failed to get quest information", false) end
        return false
    end
    
    if questType ~= "Repeatable" then
        if DEBUG_LOGGING then log("Skipping non-repeatable quest: "..tostring(questType), false) end
        return false
    end
    
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
            
            if not currentText or not string.find(string.lower(tostring(currentText)), "pet") then break end
            
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
        if string.find(tostring(questText), eggName) then
            if DEBUG_LOGGING then log("Found egg quest for: "..eggName, false) end
            
            if eggName == "Neon" then
                return handleNeonEgg()
            end
            
            if not moveToPosition(EGG_DATA[eggName]) then
                if DEBUG_LOGGING then log("Failed to reach "..eggName.." Egg", true) end
                return false
            end
            
            local startTime = tick()
            while tick() - startTime < 300 do
                local currentType, currentText, currentProgress = getCurrentQuest()
                
                if not currentText or not string.find(tostring(currentText), eggName) then break end
                
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
    
    -- Handle unrecognized quests
    if DEBUG_LOGGING then log("Skipping unrecognized quest: "..tostring(questText), false) end
    skipCompetitiveQuest()
    return false
end

-- Main loop
log("Egg Hatching Script Started (Enhanced Teleport System)", false)

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
