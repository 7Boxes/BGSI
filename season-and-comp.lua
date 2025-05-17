-- Auto Quest Script Configuration
local CONFIG = {
    BubbleRate = 0.1,          -- How often to blow bubbles (seconds)
    HatchRate = 0.1,           -- How often to hatch eggs (seconds)
    HatchQuantity = 4,         -- Number of eggs to hatch at once (configurable)
    CollectionWaitTime = 5,    -- Wait time between collection attempts (seconds)
    TweenDuration = 10,        -- Time to tween between locations (seconds)
    CheckInterval = 5,         -- How often to check quest progress (seconds)
    PostCompletionWait = 5,    -- Wait after completing a quest type (seconds)
    FloatHeight = 5,           -- How high to float above ground (studs)
    WalkSpeed = 16             -- Movement speed when floating
}

-- Hub Locations
local HUBS = {
    Bubble = Vector3.new(76.26, 9.20, -111.97),
    Egg = Vector3.new(-105.23, 19.22, -26.92),
    Collection = {
        teleportRemote = {
            "Teleport",
            "Workspace.Worlds.The Overworld.Islands.Zen.lsland.Portal.Spawn"
        },
        movementPath = {
            Vector3.new(67.74, 15971.72, 9.15),
            Vector3.new(-64.94, 15971.72, -2.92),
            Vector3.new(-35.75, 15971.72, 35.63)
        }
    },
    OverworldReturn = {
        "Teleport",
        "Workspace.Worlds.The Overworld.PortalSpawn"
    }
}

-- Egg Locations
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
    ["Infinity Egg"] = HUBS.Egg  -- Infinity Egg is at the hub
}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:WaitForChild("ScreenGui")

-- Network Setup
local Network = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network")
local RemoteEvent = Network:WaitForChild("Remote"):WaitForChild("RemoteEvent")

-- Utility Functions
local function GetCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    return char, root, humanoid
end

local function FloatTo(position)
    local char, root, humanoid = GetCharacter()
    if not (char and root and humanoid) then return false end
    
    -- Adjust position to float height
    local floatPosition = Vector3.new(position.X, position.Y + CONFIG.FloatHeight, position.Z)
    
    -- Set movement speed
    humanoid.WalkSpeed = CONFIG.WalkSpeed
    
    -- Create and play tween
    local tween = TweenService:Create(
        root,
        TweenInfo.new(CONFIG.TweenDuration, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(floatPosition)}
    )
    tween:Play()
    return tween
end

local function TeleportToCollection()
    RemoteEvent:FireServer(unpack(HUBS.Collection.teleportRemote))
    wait(3) -- Wait for teleport to complete
end

local function ReturnToOverworld()
    RemoteEvent:FireServer(unpack(HUBS.OverworldReturn))
    wait(3) -- Wait for teleport to complete
end

-- Quest Detection Functions
local function GetQuests()
    local quests = {
        bubbles = {},
        eggs = {},
        collections = {}
    }
    
    -- Check all 4 Template frames
    for i = 1, 4 do
        local template = ScreenGui.Competitive.Frame.Content.Tasks:FindFirstChild("Template"..i)
        if template then
            local content = template:FindFirstChild("Content")
            if content then
                local label = content:FindFirstChild("Label")
                local bar = content:FindFirstChild("Bar")
                local barLabel = bar and bar:FindFirstChild("Label")
                
                if label and barLabel then
                    local questText = label.Text
                    local percentText = barLabel.Text
                    local percent = tonumber(percentText:match("%d+")) or 0
                    
                    if percent < 100 then
                        -- Bubble quest detection
                        if questText:lower():find("bubble") then
                            table.insert(quests.bubbles, {
                                path = content,
                                text = questText,
                                percent = percent
                            })
                        -- Egg quest detection
                        elseif questText:find("Hatch") then
                            local eggType = questText:match("Hatch %d+ (.+) Eggs?")
                            if eggType then
                                -- Handle plural/singular egg names
                                eggType = eggType:gsub("s$", ""):gsub("ies$", "y")
                                eggType = eggType .. " Egg"
                                
                                -- Check if we have this egg type
                                if EGG_DATA[eggType] then
                                    table.insert(quests.eggs, {
                                        path = content,
                                        text = questText,
                                        percent = percent,
                                        eggType = eggType
                                    })
                                end
                            end
                        -- Collection quest detection
                        elseif questText:find("Collect") or questText:find("collection") then
                            table.insert(quests.collections, {
                                path = content,
                                text = questText,
                                percent = percent
                            })
                        end
                    end
                end
            end
        end
    end
    
    return quests
end

-- Quest Execution Functions
local function RunBubbleQuests()
    local quests = GetQuests().bubbles
    if #quests == 0 then return false end
    
    -- Only process the first bubble quest
    local quest = quests[1]
    print("Starting bubble quest:", quest.text)
    
    -- Move to bubble hub
    FloatTo(HUBS.Bubble)
    wait(CONFIG.TweenDuration)
    
    -- Start bubble blowing coroutine
    local bubbleCoroutine = coroutine.create(function()
        while true do
            RemoteEvent:FireServer({"BlowBubble"})
            wait(CONFIG.BubbleRate)
        end
    end)
    coroutine.resume(bubbleCoroutine)
    
    -- Monitor progress
    local startTime = os.time()
    while true do
        local currentPercent = tonumber(quest.path.Bar.Label.Text:match("%d+")) or 0
        print("[Bubble] "..quest.text..": "..currentPercent.."%")
        
        if currentPercent >= 100 then
            break
        end
        
        -- Occasionally re-position to prevent AFK
        if os.time() - startTime > 120 then
            FloatTo(HUBS.Bubble)
            startTime = os.time()
        end
        
        wait(CONFIG.CheckInterval)
    end
    
    -- Clean up
    coroutine.close(bubbleCoroutine)
    print("Bubble quest completed!")
    wait(CONFIG.PostCompletionWait)
    return true
end

local function RunEggQuests()
    local quests = GetQuests().eggs
    if #quests == 0 then return false end
    
    -- Only process the first egg quest
    local quest = quests[1]
    print("Starting egg quest:", quest.text)
    
    -- Move to egg location
    FloatTo(EGG_DATA[quest.eggType])
    wait(CONFIG.TweenDuration)
    
    -- Start hatching coroutine
    local eggCoroutine = coroutine.create(function()
        local args = {"HatchEgg", quest.eggType, CONFIG.HatchQuantity}
        while true do
            RemoteEvent:FireServer(unpack(args))
            wait(CONFIG.HatchRate)
        end
    end)
    coroutine.resume(eggCoroutine)
    
    -- Monitor progress
    local startTime = os.time()
    while true do
        local currentPercent = tonumber(quest.path.Bar.Label.Text:match("%d+")) or 0
        print("[Egg] "..quest.text..": "..currentPercent.."%")
        
        if currentPercent >= 100 then
            break
        end
        
        -- Occasionally re-position to prevent AFK
        if os.time() - startTime > 120 then
            FloatTo(EGG_DATA[quest.eggType])
            startTime = os.time()
        end
        
        wait(CONFIG.CheckInterval)
    end
    
    -- Clean up
    coroutine.close(eggCoroutine)
    print("Egg quest completed!")
    wait(CONFIG.PostCompletionWait)
    return true
end

local function RunCollectionQuests()
    local quests = GetQuests().collections
    if #quests == 0 then return false end
    
    -- Only process the first collection quest
    local quest = quests[1]
    print("Starting collection quest:", quest.text)
    
    -- Teleport to collection area
    TeleportToCollection()
    wait(3)
    
    -- Collection loop
    while true do
        -- Trigger collection remote
        RemoteEvent:FireServer({"Collect"})
        
        -- Move through collection path
        for _, point in ipairs(HUBS.Collection.movementPath) do
            FloatTo(point)
            wait(CONFIG.TweenDuration)
        end
        
        -- Check progress
        local currentPercent = tonumber(quest.path.Bar.Label.Text:match("%d+")) or 0
        print("[Collection] "..quest.text..": "..currentPercent.."%")
        
        if currentPercent >= 100 then
            break
        end
        
        wait(CONFIG.CollectionWaitTime)
    end
    
    print("Collection quest completed!")
    
    -- Return to egg hub
    ReturnToOverworld()
    wait(3)
    FloatTo(HUBS.Egg)
    wait(CONFIG.TweenDuration)
    
    wait(CONFIG.PostCompletionWait)
    return true
end

local function HatchInfinityEgg()
    -- Move to egg hub if not already there
    local char, root = GetCharacter()
    if char and root then
        local currentPos = root.Position
        local distance = (currentPos - HUBS.Egg).Magnitude
        if distance > 10 then
            FloatTo(HUBS.Egg)
            wait(CONFIG.TweenDuration)
        end
    end
    
    print("No active quests detected. Hatching Infinity Egg...")
    
    -- Start hatching coroutine
    local infinityCoroutine = coroutine.create(function()
        local args = {"HatchEgg", "Infinity Egg", CONFIG.HatchQuantity}
        while true do
            RemoteEvent:FireServer(unpack(args))
            wait(CONFIG.HatchRate)
        end
    end)
    coroutine.resume(infinityCoroutine)
    
    -- Monitor for new quests
    local startTime = os.time()
    while #GetQuests().bubbles == 0 and #GetQuests().eggs == 0 and #GetQuests().collections == 0 do
        -- Occasionally re-position to prevent AFK
        if os.time() - startTime > 120 then
            FloatTo(HUBS.Egg)
            startTime = os.time()
        end
        
        wait(CONFIG.CheckInterval)
    end
    
    -- Clean up
    coroutine.close(infinityCoroutine)
    print("Stopping Infinity Egg hatching - quests detected")
    return true
end

-- Main Loop
while true do
    -- Check for quests in priority order
    if RunBubbleQuests() then
        -- If we completed a bubble quest, check for more quests immediately
        continue
    elseif RunEggQuests() then
        -- If we completed an egg quest, check for more quests immediately
        continue
    elseif RunCollectionQuests() then
        -- If we completed a collection quest, check for more quests immediately
        continue
    else
        -- If no quests were found, hatch Infinity Egg
        HatchInfinityEgg()
    end
end
