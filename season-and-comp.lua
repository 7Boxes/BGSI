-- Configuration
local HATCH_COUNT = 6 -- Number to send in hatch remote
local FINAL_HATCH_DELAY = 5 -- Keep hatching for this many seconds after 100%
local HATCH_INTERVAL = 0.2 -- Time between hatch attempts
local WALK_SPEED = 16 -- Normal walking speed
local DEBUG_LOGGING = true -- Set to false to disable debug logs

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

-- Logging function with timestamp
local function log(message, isError)
    local timestamp = os.date("%X")
    local logType = isError and "ERROR" or "DEBUG"
    local output = string.format("[%s][%s] %s", timestamp, logType, message)
    
    if isError or DEBUG_LOGGING then
        print(output)
    end
end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize player character with error handling
local function initializeCharacter()
    local success, character = pcall(function()
        return Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    end)
    
    if not success then
        log("Failed to get player character: "..tostring(character), true)
        return nil
    end
    return character
end

-- Initialize remote event with error handling
local function initializeRemote()
    local success, remote = pcall(function()
        return ReplicatedStorage:WaitForChild("Shared", 10)
            :WaitForChild("Framework", 10)
            :WaitForChild("Network", 10)
            :WaitForChild("Remote", 10)
            :WaitForChild("RemoteEvent", 10)
    end)
    
    if not success then
        log("Failed to find RemoteEvent: "..tostring(remote), true)
        return nil
    end
    return remote
end

-- Main player setup
local player = Players.LocalPlayer
local character = initializeCharacter()
if not character then
    log("Script cannot continue without character", true)
    return
end

local humanoid = character:FindFirstChildOfClass("Humanoid")
if not humanoid then
    log("Humanoid not found in character", true)
    return
end
humanoid.WalkSpeed = WALK_SPEED

local RemoteEvent = initializeRemote()
if not RemoteEvent then
    log("Script cannot continue without RemoteEvent", true)
    return
end

-- Improved GUI setup with better quest detection
local function getEggQuestInfo()
    while true do
        local gui = player:FindFirstChild("PlayerGui")
        if not gui then
            log("PlayerGui not found", false)
            wait(1)
            continue
        end

        local screenGui = gui:FindFirstChild("ScreenGui")
        if not screenGui then
            log("ScreenGui not found", false)
            wait(1)
            continue
        end

        local competitive = screenGui:FindFirstChild("Competitive")
        if not competitive then
            log("Competitive frame not found", false)
            wait(1)
            continue
        end

        local frame = competitive:FindFirstChild("Frame")
        if not frame then
            log("Frame not found", false)
            wait(1)
            continue
        end

        local content = frame:FindFirstChild("Content")
        if not content then
            log("Content not found", false)
            wait(1)
            continue
        end

        local tasks = content:FindFirstChild("Tasks")
        if not tasks then
            log("Tasks folder not found", false)
            wait(1)
            continue
        end

        -- Search through all templates
        for _, template in ipairs(tasks:GetChildren()) do
            if template.Name == "Template" then
                local contentFrame = template:FindFirstChild("Content")
                if contentFrame then
                    local label = contentFrame:FindFirstChild("Label")
                    local bar = contentFrame:FindFirstChild("Bar")
                    local barLabel = bar and bar:FindFirstChild("Label")

                    if label and barLabel then
                        local questText = label.Text
                        local progress = barLabel.Text
                        
                        -- Only return if it's an egg quest
                        if string.find(string.lower(questText), "hatch") then
                            log(string.format("Found egg quest: %s (Progress: %s)", questText, progress), false)
                            return questText, progress
                        else
                            log(string.format("Ignoring non-egg quest: %s", questText), false)
                        end
                    end
                end
            end
        end
        
        log("No active egg quests found - waiting...", false)
        wait(1)
    end
end

-- Walking function with error handling
local function walkTo(position)
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        log("Cannot walk - character not valid", true)
        return false
    end

    log(string.format("Walking to position: X:%.2f Y:%.2f Z:%.2f", position.X, position.Y, position.Z), false)
    
    local startTime = tick()
    local lastPosition = character.HumanoidRootPart.Position
    local stuckCheckTime = 0
    
    humanoid:MoveTo(position)
    
    while (character.HumanoidRootPart.Position - position).Magnitude > 5 do
        -- Check if we're stuck
        if (character.HumanoidRootPart.Position - lastPosition).Magnitude < 1 then
            if tick() - stuckCheckTime > 5 then
                log("Character appears stuck - attempting jump", true)
                humanoid.Jump = true
                stuckCheckTime = tick()
            end
        else
            stuckCheckTime = tick()
        end
        lastPosition = character.HumanoidRootPart.Position
        
        -- Timeout after 30 seconds
        if tick() - startTime > 30 then
            log("Walk timeout reached", true)
            return false
        end
        
        wait(0.5)
    end
    
    log("Reached destination", false)
    return true
end

-- Hatch egg function with error handling
local function hatchEgg(eggName)
    local fullEggName = eggName.." Egg"
    log("Attempting to hatch: "..fullEggName, false)
    
    local args = {
        "HatchEgg",
        fullEggName,
        HATCH_COUNT
    }
    
    local success, err = pcall(function()
        RemoteEvent:FireServer(unpack(args))
    end)
    
    if not success then
        log("Failed to hatch egg: "..tostring(err), true)
        return false
    end
    
    return true
end

-- Special Neon Egg handling with error logging
local function doNeonEgg()
    log("Starting Neon Egg special handling", false)
    
    -- First teleport to Hyperwave Island
    log("Teleporting to Hyperwave Island", false)
    local success, err = pcall(function()
        RemoteEvent:FireServer("Teleport", "Workspace.Worlds.MinigameParadise.Islands.HyperwaveIsland.Island.Portal.Spawn")
    end)
    
    if not success then
        log("Failed to teleport to Hyperwave Island: "..tostring(err), true)
        return false
    end
    
    wait(5) -- Wait for teleport
    
    -- Walk to Neon Egg position
    if not walkTo(EGG_DATA["Neon"]) then
        log("Failed to walk to Neon Egg position", true)
        return false
    end
    
    -- Hatch until done
    local done = false
    local startTime = tick()
    
    while not done and tick() - startTime < 300 do -- 5 minute timeout
        local questText, progress = getEggQuestInfo()
        
        if not string.find(questText:lower(), "hatch") then
            log("No hatch quest detected", false)
            break
        end
        
        if not hatchEgg("Neon") then
            log("Failed to hatch Neon Egg", true)
            break
        end
        
        if progress == "100%" then
            log("Quest 100% complete - continuing for "..FINAL_HATCH_DELAY.." seconds", false)
            local finishTime = tick()
            while tick() - finishTime < FINAL_HATCH_DELAY do
                hatchEgg("Neon")
                wait(HATCH_INTERVAL)
            end
            done = true
        end
        
        wait(HATCH_INTERVAL)
    end
    
    -- Return to Overworld
    log("Teleporting back to Overworld", false)
    success, err = pcall(function()
        RemoteEvent:FireServer("Teleport", "Workspace.Worlds.The Overworld.FastTravel.Spawn")
    end)
    
    if not success then
        log("Failed to teleport to Overworld: "..tostring(err), true)
        return false
    end
    
    wait(5)
    return done
end

-- Extract egg name from quest text with error handling
local function getEggName(questText)
    if not questText then return nil end
    
    for eggName in pairs(EGG_DATA) do
        if string.find(questText, eggName) then
            log("Extracted egg name: "..eggName.." from quest: "..questText, false)
            return eggName
        end
    end
    
    log("Could not extract egg name from quest: "..tostring(questText), true)
    return nil
end

-- Main function to handle egg quests
local function handleEggQuest()
    log("Checking for egg quests...", false)
    
    -- This will wait until an egg quest is found
    local questText, progress = getEggQuestInfo()
    local eggName = getEggName(questText)
    
    if not eggName then
        log("Could not determine egg name from quest", true)
        return false
    end
    
    log("Processing quest for egg: "..eggName, false)
    
    -- Special case for Neon Egg
    if eggName == "Neon" then
        return doNeonEgg()
    end
    
    -- Regular egg handling
    if not walkTo(EGG_DATA[eggName]) then
        log("Failed to walk to egg position", true)
        return false
    end
    
    local done = false
    local startTime = tick()
    
    while not done and tick() - startTime < 300 do -- 5 minute timeout
        local currentQuest, currentProgress = getEggQuestInfo()
        
        if not string.find(currentQuest:lower(), "hatch") then
            log("Quest changed or no longer available", false)
            break
        end
        
        if not hatchEgg(eggName) then
            log("Failed to hatch egg", true)
            break
        end
        
        if currentProgress == "100%" then
            log("Quest 100% complete - continuing for "..FINAL_HATCH_DELAY.." seconds", false)
            local finishTime = tick()
            while tick() - finishTime < FINAL_HATCH_DELAY do
                hatchEgg(eggName)
                wait(HATCH_INTERVAL)
            end
            done = true
        end
        
        wait(HATCH_INTERVAL)
    end
    
    return done
end

-- Main loop with comprehensive error handling
log("Egg Hatching Script Started", false)

while true do
    local success, err = pcall(handleEggQuest)
    if not success then
        log("Critical error in handleEggQuest: "..tostring(err), true)
    end
    
    -- Brief wait before checking again
    wait(0.5)
end
