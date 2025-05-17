-- Configuration
local HATCH_COUNT = 6 -- Change this number if needed
local FINAL_HATCH_DELAY = 5 -- Seconds to continue hatching after 100%
local HATCH_INTERVAL = 0.2 -- Seconds between hatch attempts
local WALK_SPEED = 16 -- Normal walking speed

-- Egg data with coordinates
local EGG_DATA = {
    ["Common Egg"] = Vector3.new(-12.40, 15.66, -81.87),
    ["Spotted Egg"] = Vector3.new(-12.63, 15.61, -70.52),
    ["Iceshard Egg"] = Vector3.new(-12.57, 16.50, -59.62),
    ["Spikey Egg"] = Vector3.new(-127.92, 16.25, 9.43),
    ["Magma Egg"] = Vector3.new(-137.79, 15.58, 3.08),
    ["Crystal Egg"] = Vector3.new(-144.64, 15.98, -5.11),
    ["Lunar Egg"] = Vector3.new(-148.69, 15.88, -15.29),
    ["Void Egg"] = Vector3.new(-149.83, 15.75, -26.63),
    ["Hell Egg"] = Vector3.new(-149.49, 15.57, -36.71),
    ["Nightmare Egg"] = Vector3.new(-146.16, 14.51, -47.57),
    ["Rainbow Egg"] = Vector3.new(-139.45, 16.20, -55.40),
    ["Showman Egg"] = Vector3.new(-130.84, 19.16, -63.48),
    ["Mining Egg"] = Vector3.new(-121.83, 16.45, -67.70),
    ["Cyber Egg"] = Vector3.new(-92.24, 16.11, -66.20),
    ["Infinity Egg"] = Vector3.new(-104.93, 18.63, -28.01),
    ["Neon Egg"] = Vector3.new(9883.46, 20095.29, 264.75) -- Special egg location
}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote setup
local Framework = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework")
local Network = Framework:WaitForChild("Network")
local Remote = Network:WaitForChild("Remote")
local RemoteEvent = Remote:WaitForChild("RemoteEvent")

-- Player setup
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
humanoid.WalkSpeed = WALK_SPEED

-- GUI setup
local ScreenGui = player.PlayerGui:WaitForChild("ScreenGui")
local Competitive = ScreenGui:WaitForChild("Competitive")
local Frame = Competitive:WaitForChild("Frame")
local Content = Frame:WaitForChild("Content")
local Tasks = Content:WaitForChild("Tasks")

-- Function to walk to position (simple pathfinding)
local function walkTo(position)
    humanoid:MoveTo(position)
    
    -- Wait until we're close enough to the target
    while (character.HumanoidRootPart.Position - position).Magnitude > 5 do
        -- Check if we're stuck
        if humanoid:GetState() == Enum.HumanoidStateType.Seated then
            humanoid.Jump = true
        end
        wait(0.5)
    end
end

-- Function to hatch an egg
local function hatchEgg(eggName)
    local args = {
        "HatchEgg",
        eggName,
        HATCH_COUNT
    }
    RemoteEvent:FireServer(unpack(args))
end

-- Function to check quest progress
local function getQuestProgress()
    local taskChildren = Tasks:GetChildren()
    for _, task in ipairs(taskChildren) do
        if task.Name == "Template" then
            local label = task:FindFirstChild("Content") and task.Content:FindFirstChild("Label")
            local barLabel = task:FindFirstChild("Content") and task.Content:FindFirstChild("Bar") and task.Content.Bar:FindFirstChild("Label")
            
            if label and barLabel then
                local questText = label.Text
                local progressText = barLabel.Text
                local progress = tonumber(progressText:match("%d+")) or 0
                
                return questText, progress, progressText
            end
        end
    end
    return nil, 0, "0%"
end

-- Function to extract egg name from quest text
local function getEggNameFromQuest(questText)
    for eggName in pairs(EGG_DATA) do
        if string.find(questText, eggName) then
            return eggName
        end
    end
    return nil
end

-- Function to handle special Neon Egg case
local function handleNeonEgg()
    -- Use the teleport remote to get to Hyperwave Island
    local args = {
        "Teleport",
        "Workspace.Worlds.MinigameParadise.Islands.HyperwaveIsland.Island.Portal.Spawn"
    }
    RemoteEvent:FireServer(unpack(args))
    wait(3) -- Wait for teleport to complete
    
    -- Walk to Neon Egg position
    walkTo(EGG_DATA["Neon Egg"])
    
    -- Process the quest
    processEggQuest("Neon Egg")
    
    -- Use the teleport remote to return to Overworld
    local args = {
        "Teleport",
        "Workspace.Worlds.The Overworld.FastTravel.Spawn"
    }
    RemoteEvent:FireServer(unpack(args))
    wait(3) -- Wait for teleport to complete
end

-- Function to process an egg quest
local function processEggQuest(eggName)
    local startTime = tick()
    local completed = false
    
    while not completed and tick() - startTime < 300 do -- 5 minute timeout
        local questText, progress, progressText = getQuestProgress()
        
        if not questText or not string.find(questText:lower(), "hatch") then
            -- Not an egg hatching quest, skip
            return false
        end
        
        -- Hatch the egg
        hatchEgg(eggName)
        
        if progressText == "100%" then
            -- Continue hatching for FINAL_HATCH_DELAY seconds after reaching 100%
            local finishTime = tick()
            while tick() - finishTime < FINAL_HATCH_DELAY do
                hatchEgg(eggName)
                wait(HATCH_INTERVAL)
            end
            completed = true
        end
        
        wait(HATCH_INTERVAL)
    end
    
    return completed
end

-- Main loop
while true do
    local questText = getQuestProgress()
    
    if questText and string.find(questText:lower(), "hatch") then
        -- Extract egg name from quest text (e.g., "Hatch x Showman Eggs" → "Showman Egg")
        local eggName = getEggNameFromQuest(questText)
        
        if eggName then
            if eggName == "Neon Egg" then
                handleNeonEgg()
            else
                -- Regular egg handling
                walkTo(EGG_DATA[eggName])
                processEggQuest(eggName)
            end
        end
    end
    
    wait(1) -- Check for new quests every second
end
