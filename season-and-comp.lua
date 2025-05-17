-- Configuration
local HATCH_COUNT = 6 -- Number to send in hatch remote
local FINAL_HATCH_DELAY = 5 -- Keep hatching after 100% for this many seconds
local HATCH_INTERVAL = 0.2 -- Time between hatch attempts
local WALK_SPEED = 16 -- Normal walking speed
local DEBUG_LOGGING = true -- Set to false to reduce console spam

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

-- Logging function
local function log(message, isError)
    local timestamp = os.date("%X")
    local prefix = isError and "[ERROR]" or "[DEBUG]"
    print(string.format("%s [%s] %s", prefix, timestamp, message))
end

-- Get current quest info
local function getCurrentQuest()
    local gui = player.PlayerGui:FindFirstChild("ScreenGui")
    if not gui then return nil, nil, nil end
    
    local competitive = gui:FindFirstChild("Competitive")
    if not competitive then return nil, nil, nil end
    
    local frame = competitive:FindFirstChild("Frame")
    if not frame then return nil, nil, nil end
    
    local content = frame:FindFirstChild("Content")
    if not content then return nil, nil, nil end
    
    local tasks = content:FindFirstChild("Tasks")
    if not tasks then return nil, nil, nil end
    
    -- Check the 5th template (as per your image)
    local template = tasks:FindFirstChild("5") or tasks:GetChildren()[5]
    if not template then return nil, nil, nil end
    
    local contentFrame = template:FindFirstChild("Content")
    if not contentFrame then return nil, nil, nil end
    
    -- Get quest type
    local typeLabel = contentFrame:FindFirstChild("Type")
    local questType = typeLabel and typeLabel.Text or "Unknown"
    
    -- Get quest text and progress
    local label = contentFrame:FindFirstChild("Label")
    local barLabel = contentFrame.Bar and contentFrame.Bar:FindFirstChild("Label")
    
    return questType, label and label.Text, barLabel and barLabel.Text
end

-- Walk to position
local function walkTo(position)
    humanoid:MoveTo(position)
    
    local startTime = tick()
    while (character.HumanoidRootPart.Position - position).Magnitude > 5 do
        if tick() - startTime > 30 then
            log("Walk timeout reached", true)
            return false
        end
        wait(0.5)
    end
    return true
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

-- Special Neon Egg handling
local function handleNeonEgg()
    -- Teleport to Hyperwave Island
    RemoteEvent:FireServer("Teleport", "Workspace.Worlds.MinigameParadise.Islands.HyperwaveIsland.Island.Portal.Spawn")
    wait(5)
    
    -- Walk to Neon Egg position
    if not walkTo(EGG_DATA["Neon"]) then return false end
    
    -- Hatch until complete
    local startTime = tick()
    while tick() - startTime < 300 do -- 5 minute timeout
        local questType, questText, progress = getCurrentQuest()
        
        -- Skip if quest changed or not repeatable
        if questType ~= "Repeatable" or not string.find(questText or "", "hatch") then
            break
        end
        
        hatchEgg("Neon")
        
        if progress == "100%" then
            -- Continue hatching for extra time
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

-- Main processing function
local function processEggQuest()
    -- Get current quest info
    local questType, questText, progress = getCurrentQuest()
    
    -- Skip if not a repeatable hatch quest
    if questType ~= "Repeatable" or not string.find(questText or "", "hatch") then
        log("Skipping non-repeatable or non-egg quest", false)
        return false
    end
    
    log("Processing quest: "..questText, false)
    
    -- Find which egg we need to hatch
    local targetEgg
    for eggName in pairs(EGG_DATA) do
        if string.find(questText, eggName) then
            targetEgg = eggName
            break
        end
    end
    
    if not targetEgg then
        log("Could not determine egg type from quest", true)
        return false
    end
    
    log("Found target egg: "..targetEgg, false)
    
    -- Special handling for Neon Egg
    if targetEgg == "Neon" then
        return handleNeonEgg()
    end
    
    -- Regular egg handling
    if not walkTo(EGG_DATA[targetEgg]) then
        log("Failed to walk to egg", true)
        return false
    end
    
    -- Hatch until complete
    local startTime = tick()
    while tick() - startTime < 300 do -- 5 minute timeout
        local currentType, currentText, currentProgress = getCurrentQuest()
        
        -- Stop if quest changed or not repeatable
        if currentType ~= "Repeatable" or not string.find(currentText or "", "hatch") then
            break
        end
        
        hatchEgg(targetEgg)
        
        if currentProgress == "100%" then
            -- Continue hatching for extra time
            local finishTime = tick()
            while tick() - finishTime < FINAL_HATCH_DELAY do
                hatchEgg(targetEgg)
                wait(HATCH_INTERVAL)
            end
            break
        end
        
        wait(HATCH_INTERVAL)
    end
    
    return true
end

-- Main loop
log("Egg Hatching Script Started", false)

while true do
    local success, err = pcall(processEggQuest)
    if not success then
        log("Error: "..tostring(err), true)
    end
    
    -- Wait before checking again
    wait(1)
end
