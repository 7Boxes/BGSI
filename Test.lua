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
    
    for _, questType in ipairs({"Daily", "Hourly"}) do
        for i = 1, 3 do
            local questFrame = ScreenGui.Season.Frame.Content.Challenges[questType].List[questType:lower().."-challenge-"..i]
            if questFrame then
                local quest = questFrame.Content
                if quest and quest.Label and quest.Bar and quest.Bar.Label then
                    local text = quest.Label.Text
                    local percent = tonumber(quest.Bar.Label.Text:match("%d+")) or 0
                    
                    if percent < 100 then
                        -- Bubble quest detection
                        if text:lower():find("bubble") then
                            table.insert(quests.bubbles, {
                                path = quest,
                                text = text,
                                percent = percent
                            })
                        -- Egg quest detection
                        elseif text:find("Hatch") then
                            local eggType = text:match("Hatch %d+ (.+) Eggs?")
                            if eggType then
                                -- Handle plural/singular egg names
                                eggType = eggType:gsub("s$", ""):gsub("ies$", "y")
                                eggType = eggType .. " Egg"
                                
                                -- Check if we have this egg type
                                if EGG_DATA[eggType] then
                                    table.insert(quests.eggs, {
                                        path = quest,
                                        text = text,
                                        percent = percent,
                                        eggType = eggType
                                    })
                                end
                            end
                        -- Collection quest detection
                        elseif text:find("Collect") or text:find("collection") then
                            table.insert(quests.collections, {
                                path = quest,
                                text = text,
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
    
    print("Starting", #quests, "bubble quest(s)")
    
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
    while #GetQuests().bubbles > 0 do
        for _, q in ipairs(GetQuests().bubbles) do
            print("[Bubble] "..q.text..": "..q.percent.."%")
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
    print("Bubble quests completed!")
    wait(CONFIG.PostCompletionWait)
    return true
end

local function RunEggQuests()
    local quests = GetQuests().eggs
    if #quests == 0 then return false end
    
    -- Group by egg type
    local eggGroups = {}
    for _, q in ipairs(quests) do
        eggGroups[q.eggType] = eggGroups[q.eggType] or {}
        table.insert(eggGroups[q.eggType], q)
    end
    
    -- Process each egg type
    for eggType, typeQuests in pairs(eggGroups) do
        print("\nStarting", #typeQuests, eggType, "quest(s)")
        
        -- Move to egg location
        FloatTo(EGG_DATA[eggType])
        wait(CONFIG.TweenDuration)
        
        -- Start hatching coroutine
        local eggCoroutine = coroutine.create(function()
            local args = {"HatchEgg", eggType, CONFIG.HatchQuantity}
            while true do
                RemoteEvent:FireServer(unpack(args))
                wait(CONFIG.HatchRate)
            end
        end)
        coroutine.resume(eggCoroutine)
        
        -- Monitor progress
        local startTime = os.time()
        while true do
            local allComplete = true
            for _, q in ipairs(typeQuests) do
                q.percent = tonumber(q.path.Bar.Label.Text:match("%d+")) or 0
                if q.percent < 100 then
                    allComplete = false
                    print("[Egg] "..q.text..": "..q.percent.."%")
                end
            end
            
            if allComplete then break end
            
            -- Occasionally re-position to prevent AFK
            if os.time() - startTime > 120 then
                FloatTo(EGG_DATA[eggType])
                startTime = os.time()
            end
            
            wait(CONFIG.CheckInterval)
        end
        
        -- Clean up
        coroutine.close(eggCoroutine)
        print(eggType, "quests completed!")
        wait(CONFIG.PostCompletionWait)
    end
    
    return true
end

local function RunCollectionQuests()
    local quests = GetQuests().collections
    if #quests == 0 then return false end
    
    print("Starting", #quests, "collection quest(s)")
    
    -- Teleport to collection area
    TeleportToCollection()
    wait(3)
    
    -- Collection loop
    while #GetQuests().collections > 0 do
        -- Trigger collection remote
        RemoteEvent:FireServer({"Collect"})
        
        -- Move through collection path
        for _, point in ipairs(HUBS.Collection.movementPath) do
            FloatTo(point)
            wait(CONFIG.TweenDuration)
        end
        
        -- Check progress
        for _, q in ipairs(GetQuests().collections) do
            print("[Collection] "..q.text..": "..q.percent.."%")
        end
        
        wait(CONFIG.CollectionWaitTime)
    end
    
    print("Collection quests completed!")
    
    -- Return to egg hub
    ReturnToOverworld()
    wait(3)
    FloatTo(HUBS.Egg)
    wait(CONFIG.TweenDuration)
    
    -- Check for Infinity Egg quests
    local infinityQuests = {}
    for _, q in ipairs(GetQuests().eggs) do
        if q.eggType == "Infinity Egg" then
            table.insert(infinityQuests, q)
        end
    end
    
    if #infinityQuests > 0 then
        print("Starting Infinity Egg quests")
        
        -- Start hatching coroutine
        local infinityCoroutine = coroutine.create(function()
            local args = {"HatchEgg", "Infinity Egg", CONFIG.HatchQuantity}
            while true do
                RemoteEvent:FireServer(unpack(args))
                wait(CONFIG.HatchRate)
            end
        end)
        coroutine.resume(infinityCoroutine)
        
        -- Monitor progress
        local startTime = os.time()
        while #infinityQuests > 0 do
            for _, q in ipairs(infinityQuests) do
                q.percent = tonumber(q.path.Bar.Label.Text:match("%d+")) or 0
                print("[Infinity Egg] "..q.text..": "..q.percent.."%")
            end
            
            -- Occasionally re-position to prevent AFK
            if os.time() - startTime > 120 then
                FloatTo(HUBS.Egg)
                startTime = os.time()
            end
            
            wait(CONFIG.CheckInterval)
            infinityQuests = {}
            for _, q in ipairs(GetQuests().eggs) do
                if q.eggType == "Infinity Egg" then
                    table.insert(infinityQuests, q)
                end
            end
        end
        
        -- Clean up
        coroutine.close(infinityCoroutine)
        print("Infinity Egg quests completed!")
    end
    
    wait(CONFIG.PostCompletionWait)
    return true
end

-- Main Loop
while true do
    -- Check for quests in priority order
    if RunBubbleQuests() then
        -- If we completed bubble quests, check for more quests immediately
        continue
    elseif RunEggQuests() then
        -- If we completed egg quests, check for more quests immediately
        continue
    elseif RunCollectionQuests() then
        -- If we completed collection quests, check for more quests immediately
        continue
    end
    
    -- If no quests were completed, wait before checking again
    print("No active quests detected. Waiting...")
    wait(CONFIG.CheckInterval)
end
