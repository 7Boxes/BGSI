-- Configuration
local HATCH_COUNT = 6
local FINAL_HATCH_DELAY = 5
local HATCH_INTERVAL = 0.2
local HORIZONTAL_SPEED = 36
local DEBUG_LOGGING = true
local WALK_SPEED = 16
local SKIP_UNRECOGNIZED_QUESTS = true
local HOVER_HEIGHT = 0 -- Y position to maintain
local ANTI_FALL_FORCE = Vector3.new(0, 196.2, 0) -- Upward force to prevent falling

-- Teleport Settings
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
    delay = 0.05,
    timeout = 10,
    position_threshold = 5
}

-- Egg data (Y=0 for all except Neon)
local EGG_DATA = {
    ["Common"] = Vector3.new(-12.40, HOVER_HEIGHT, -81.87),
    ["Spotted"] = Vector3.new(-12.63, HOVER_HEIGHT, -70.52),
    ["Iceshard"] = Vector3.new(-12.57, HOVER_HEIGHT, -59.62),
    ["Spikey"] = Vector3.new(-127.92, HOVER_HEIGHT, 9.43),
    ["Magma"] = Vector3.new(-137.79, HOVER_HEIGHT, 3.08),
    ["Crystal"] = Vector3.new(-144.64, HOVER_HEIGHT, -5.11),
    ["Lunar"] = Vector3.new(-148.69, HOVER_HEIGHT, -15.29),
    ["Void"] = Vector3.new(-149.83, HOVER_HEIGHT, -26.63),
    ["Hell"] = Vector3.new(-149.49, HOVER_HEIGHT, -36.71),
    ["Nightmare"] = Vector3.new(-146.16, HOVER_HEIGHT, -47.57),
    ["Rainbow"] = Vector3.new(-139.45, HOVER_HEIGHT, -55.40),
    ["Showman"] = Vector3.new(-130.84, HOVER_HEIGHT, -63.48),
    ["Mining"] = Vector3.new(-121.83, HOVER_HEIGHT, -67.70),
    ["Cyber"] = Vector3.new(-92.24, HOVER_HEIGHT, -66.20),
    ["Infinity"] = Vector3.new(-104.93, HOVER_HEIGHT, -28.01),
    ["Neon"] = Vector3.new(9883.17, 20095.92, 265.26) -- Only Neon keeps Y value
}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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

-- Logging
local function log(message, isError)
    local timestamp = os.date("%H:%M:%S")
    local prefix = isError and "[ERROR]" or "[INFO]"
    print(string.format("%s [%s] %s", prefix, timestamp, tostring(message)))
end

-- Anti-fall system
local function enableAntiFall()
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = ANTI_FALL_FORCE
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    bodyVelocity.P = 10000
    bodyVelocity.Parent = rootPart
    
    RunService.Heartbeat:Connect(function()
        if rootPart.Position.Y ~= HOVER_HEIGHT then
            rootPart.CFrame = CFrame.new(
                rootPart.Position.X, 
                HOVER_HEIGHT, 
                rootPart.Position.Z
            )
        end
    end)
end

-- Smart teleport with position verification
local function smartTeleport(destination)
    local originalPos = rootPart.Position
    log("Attempting teleport to "..destination.name, false)
    
    local startTime = os.clock()
    while os.clock() - startTime < SPAM_SETTINGS.timeout do
        RemoteEvent:FireServer(unpack(destination.args))
        wait(SPAM_SETTINGS.delay)
        
        if (rootPart.Position - originalPos).Magnitude > SPAM_SETTINGS.position_threshold then
            log("Teleport successful", false)
            rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(180), 0)
            humanoid.Jump = true
            wait(0.5)
            return true
        end
    end
    log("Teleport failed", true)
    return false
end

-- Simplified movement (Y=0 only)
local function moveToPosition(targetPos)
    local groundPos = Vector3.new(targetPos.X, HOVER_HEIGHT, targetPos.Z)
    local tweenInfo = TweenInfo.new(
        (rootPart.Position - groundPos).Magnitude / HORIZONTAL_SPEED,
        Enum.EasingStyle.Linear
    )
    local tween = TweenService:Create(rootPart, tweenInfo, {Position = groundPos})
    tween:Play()
    tween.Completed:Wait()
    humanoid.Jump = true
    wait(0.2)
    return true
end

-- Special Neon Egg movement
local function moveToNeonEgg()
    local targetPos = EGG_DATA["Neon"]
    humanoid.WalkSpeed = WALK_SPEED
    
    -- Face target and move
    rootPart.CFrame = CFrame.new(rootPart.Position, targetPos)
    humanoid:MoveTo(targetPos)
    
    local startTime = tick()
    while (rootPart.Position - targetPos).Magnitude > 3 and tick() - startTime < 30 do
        rootPart.CFrame = CFrame.new(rootPart.Position, targetPos)
        wait(0.1)
    end
    
    rootPart.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(180), 0)
    humanoid.Jump = true
    wait(0.5)
    return true
end

-- Quest detection
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
    
    local children = tasks:GetChildren()
    local template = #children >= 5 and children[5] or nil
    if not template then return nil, nil, nil end
    
    local contentFrame = template:FindFirstChild("Content")
    if not contentFrame then return nil, nil, nil end
    
    local typeLabel = contentFrame:FindFirstChild("Type")
    if not typeLabel then return nil, nil, nil end
    
    local questLabel = contentFrame:FindFirstChild("Label")
    local barLabel = contentFrame.Bar and contentFrame.Bar:FindFirstChild("Label")
    
    return typeLabel.Text, questLabel and questLabel.Text, barLabel and barLabel.Text
end

-- Egg hatching
local function hatchEgg(eggName)
    RemoteEvent:FireServer("HatchEgg", eggName.." Egg", HATCH_COUNT)
end

-- Quest skipping
local function skipCompetitiveQuest()
    if SKIP_UNRECOGNIZED_QUESTS then
        RemoteEvent:FireServer("CompetitiveRetail", 4)
        log("Skipped unrecognized quest", false)
    end
end

-- Neon Egg handler
local function handleNeonEgg()
    log("Starting Neon Egg process", false)
    if not smartTeleport(TELEPORT.NEON) then return false end
    if not moveToNeonEgg() then return false end
    
    local startTime = tick()
    while tick() - startTime < 300 do
        local _, questText, progress = getCurrentQuest()
        if not questText or not string.find(tostring(questText), "Neon") then break end
        
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
    
    return smartTeleport(TELEPORT.OVERWORLD)
end

-- Main quest processor
local function processQuest()
    local questType, questText, progress = getCurrentQuest()
    if not questType or not questText then return false end
    
    if questType ~= "Repeatable" then
        log("Skipping non-repeatable quest", false)
        return false
    end
    
    local questTextLower = string.lower(tostring(questText))
    
    -- Pet quest
    if string.find(questTextLower, "pet") then
        log("Processing Pet quest", false)
        if not moveToPosition(EGG_DATA["Infinity"]) then return false end
        
        local startTime = tick()
        while tick() - startTime < 300 do
            local _, currentText, currentProgress = getCurrentQuest()
            if not currentText or not string.find(string.lower(tostring(currentText)), "pet") then break end
            
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
    
    -- Egg quests
    for eggName, pos in pairs(EGG_DATA) do
        if string.find(tostring(questText), eggName) then
            log("Found egg quest: "..eggName, false)
            
            if eggName == "Neon" then
                return handleNeonEgg()
            end
            
            if not moveToPosition(pos) then return false end
            
            local startTime = tick()
            while tick() - startTime < 300 do
                local _, currentText, currentProgress = getCurrentQuest()
                if not currentText or not string.find(tostring(currentText), eggName) then break end
                
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
    
    log("Unrecognized quest: "..tostring(questText), false)
    skipCompetitiveQuest()
    return false
end

-- Initialize
log("Script started - Anti-Fall System Active", false)

-- Enable anti-fall and collision handling
enableAntiFall()
for _, part in ipairs(character:GetDescendants()) do
    if part:IsA("BasePart") then 
        part.CanCollide = false
        part.Anchored = false
    end
end

character.ChildAdded:Connect(function(child)
    if child:IsA("BasePart") then 
        child.CanCollide = false
        child.Anchored = false
    end
end)

-- Main loop
while true do
    pcall(processQuest)
    wait(1)
end
