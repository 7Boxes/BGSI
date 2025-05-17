-- Configuration
local HATCH_COUNT = 6 -- Number to send in hatch remote
local FINAL_HATCH_DELAY = 5 -- Keep hatching for this many seconds after 100%
local HATCH_INTERVAL = 0.2 -- Time between hatch attempts
local WALK_SPEED = 16 -- Normal walking speed

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
humanoid.WalkSpeed = WALK_SPEED

-- Remote setup
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework"):WaitForChild("Network")
    :WaitForChild("Remote"):WaitForChild("RemoteEvent")

-- GUI setup
local function getQuestInfo()
    local gui = player.PlayerGui:FindFirstChild("ScreenGui")
    if not gui then return nil, "0%" end
    
    local competitive = gui:FindFirstChild("Competitive")
    if not competitive then return nil, "0%" end
    
    local frame = competitive:FindFirstChild("Frame")
    if not frame then return nil, "0%" end
    
    local content = frame:FindFirstChild("Content")
    if not content then return nil, "0%" end
    
    local tasks = content:FindFirstChild("Tasks")
    if not tasks then return nil, "0%" end
    
    for _, task in ipairs(tasks:GetChildren()) do
        if task.Name == "Template" then
            local contentFrame = task:FindFirstChild("Content")
            if contentFrame then
                local label = contentFrame:FindFirstChild("Label")
                local barLabel = contentFrame:FindFirstChild("Bar") and contentFrame.Bar:FindFirstChild("Label")
                
                if label and barLabel then
                    return label.Text, barLabel.Text
                end
            end
        end
    end
    return nil, "0%"
end

-- Simple walking function
local function walkTo(position)
    humanoid:MoveTo(position)
    
    -- Wait until close to target or 30 seconds max
    local startTime = tick()
    while (character.HumanoidRootPart.Position - position).Magnitude > 5 do
        if tick() - startTime > 30 then break end -- Timeout after 30 seconds
        wait(0.5)
    end
end

-- Hatch egg function
local function hatchEgg(eggName)
    local args = {
        "HatchEgg",
        eggName.." Egg", -- Add " Egg" to match remote format
        HATCH_COUNT
    }
    RemoteEvent:FireServer(unpack(args))
end

-- Special Neon Egg handling
local function doNeonEgg()
    -- First teleport to Hyperwave Island
    RemoteEvent:FireServer("Teleport", "Workspace.Worlds.MinigameParadise.Islands.HyperwaveIsland.Island.Portal.Spawn")
    wait(5) -- Wait for teleport
    
    -- Walk to Neon Egg position
    walkTo(EGG_DATA["Neon"])
    
    -- Hatch until done
    local done = false
    while not done do
        local questText, progress = getQuestInfo()
        
        if not questText or not string.find(questText:lower(), "hatch") then
            break -- Not a hatch quest anymore
        end
        
        hatchEgg("Neon")
        
        if progress == "100%" then
            -- Continue hatching for extra time
            local startTime = tick()
            while tick() - startTime < FINAL_HATCH_DELAY do
                hatchEgg("Neon")
                wait(HATCH_INTERVAL)
            end
            done = true
        end
        
        wait(HATCH_INTERVAL)
    end
    
    -- Return to Overworld
    RemoteEvent:FireServer("Teleport", "Workspace.Worlds.The Overworld.FastTravel.Spawn")
    wait(5)
end

-- Main function to handle egg quests
local function handleEggQuest()
    local questText, progress = getQuestInfo()
    if not questText or not string.find(questText:lower(), "hatch") then
        return -- Not an egg quest
    end
    
    -- Extract egg name from quest text (e.g., "Hatch 5 Showman Eggs" → "Showman")
    local eggName
    for name in pairs(EGG_DATA) do
        if string.find(questText, name) then
            eggName = name
            break
        end
    end
    
    if not eggName then return end
    
    -- Special case for Neon Egg
    if eggName == "Neon" then
        doNeonEgg()
        return
    end
    
    -- Regular egg handling
    walkTo(EGG_DATA[eggName])
    
    local done = false
    while not done do
        local currentQuest, currentProgress = getQuestInfo()
        
        if not currentQuest or not string.find(currentQuest:lower(), "hatch") then
            break -- Quest changed
        end
        
        hatchEgg(eggName)
        
        if currentProgress == "100%" then
            -- Extra hatching after completion
            local startTime = tick()
            while tick() - startTime < FINAL_HATCH_DELAY do
                hatchEgg(eggName)
                wait(HATCH_INTERVAL)
            end
            done = true
        end
        
        wait(HATCH_INTERVAL)
    end
end

-- Main loop
while true do
    handleEggQuest()
    wait(1) -- Check for new quests every second
end
