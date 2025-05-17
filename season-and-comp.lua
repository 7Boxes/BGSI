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

-- Initialize player character
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
humanoid.WalkSpeed = WALK_SPEED

-- Remote setup
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework"):WaitForChild("Network")
    :WaitForChild("Remote"):WaitForChild("RemoteEvent")

-- Improved quest type checking
local function checkQuestType()
    local gui = player.PlayerGui:FindFirstChild("ScreenGui")
    if not gui then return "NotFound" end

    local competitive = gui:FindFirstChild("Competitive")
    if not competitive then return "NotFound" end

    local frame = competitive:FindFirstChild("Frame")
    if not frame then return "NotFound" end

    local content = frame:FindFirstChild("Content")
    if not content then return "NotFound" end

    local tasks = content:FindFirstChild("Tasks")
    if not tasks then return "NotFound" end

    local children = tasks:GetChildren()
    if #children < 5 then return "NotFound" end

    local template = children[5]
    local contentFrame = template:FindFirstChild("Content")
    if not contentFrame then return "NotFound" end

    local typeLabel = contentFrame:FindFirstChild("Type")
    if not typeLabel then return "NotFound" end

    log("Found quest type: "..typeLabel.Text, false)
    return typeLabel.Text
end

-- Get valid egg quest info
local function getValidEggQuest()
    while true do
        local questType = checkQuestType()
        
        if questType == "Repeatable" then
            local gui = player.PlayerGui.ScreenGui
            local tasks = gui.Competitive.Frame.Content.Tasks
            
            for _, template in ipairs(tasks:GetChildren()) do
                if template.Name == "Template" then
                    local content = template:FindFirstChild("Content")
                    if content then
                        local label = content:FindFirstChild("Label")
                        local barLabel = content.Bar:FindFirstChild("Label")
                        
                        if label and barLabel and string.find(label.Text:lower(), "hatch") then
                            return label.Text, barLabel.Text
                        end
                    end
                end
            end
        elseif questType == "Permanent" then
            log("Skipping permanent quest", false)
        else
            log("No valid quest found", false)
        end
        
        wait(1)
    end
end

-- Movement functions
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

-- Egg handling functions
local function hatchEgg(eggName)
    local args = {
        "HatchEgg",
        eggName.." Egg",
        HATCH_COUNT
    }
    RemoteEvent:FireServer(unpack(args))
end

local function processEgg(eggName)
    walkTo(EGG_DATA[eggName])
    
    local startTime = tick()
    while tick() - startTime < 300 do
        local _, progress = getValidEggQuest()
        
        hatchEgg(eggName)
        
        if progress == "100%" then
            local finishTime = tick()
            while tick() - finishTime < FINAL_HATCH_DELAY do
                hatchEgg(eggName)
                wait(HATCH_INTERVAL)
            end
            return true
        end
        wait(HATCH_INTERVAL)
    end
    return false
end

-- Special Neon Egg handling
local function handleNeonEgg()
    RemoteEvent:FireServer("Teleport", "Workspace.Worlds.MinigameParadise.Islands.HyperwaveIsland.Island.Portal.Spawn")
    wait(5)
    walkTo(EGG_DATA.Neon)
    
    local success = processEgg("Neon")
    
    RemoteEvent:FireServer("Teleport", "Workspace.Worlds.The Overworld.FastTravel.Spawn")
    wait(5)
    return success
end

-- Main loop
while true do
    local questText = getValidEggQuest()
    
    for eggName in pairs(EGG_DATA) do
        if string.find(questText, eggName) then
            if eggName == "Neon" then
                handleNeonEgg()
            else
                processEgg(eggName)
            end
            break
        end
    end
    wait(0.5)
end
