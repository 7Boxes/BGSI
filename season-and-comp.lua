-- Auto Quest Script (Sequential Version)
local CONFIG = {
    BubbleRate = 0.1,
    HatchRate = 0.1,
    HatchQuantity = 4,
    CollectionWaitTime = 5,
    TweenDuration = 10,
    CheckInterval = 1,
    CompletionDelay = 5,
    FloatHeight = 5,
    WalkSpeed = 16
}

-- Hub Locations
local HUBS = {
    Bubble = Vector3.new(76.26, 9.20, -111.97),
    Egg = Vector3.new(-105.23, 19.22, -26.92),
    Collection = {
        teleportRemote = {"Teleport", "Workspace.Worlds.The Overworld.Islands.Zen.lsland.Portal.Spawn"},
        movementPath = {
            Vector3.new(67.74, 15971.72, 9.15),
            Vector3.new(-64.94, 15971.72, -2.92),
            Vector3.new(-35.75, 15971.72, 35.63)
        }
    },
    OverworldReturn = {"Teleport", "Workspace.Worlds.The Overworld.PortalSpawn"}
}

-- Egg Data
local EGG_DATA = {
    ["Common Egg"] = Vector3.new(-12.40, 15.66, -81.87),
    ["Infinity Egg"] = Vector3.new(-105.23, 19.22, -26.92)
    -- Add other egg types as needed
}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:WaitForChild("ScreenGui")
local Network = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network")
local RemoteEvent = Network:WaitForChild("Remote"):WaitForChild("RemoteEvent")

-- Utility Functions
local function GetCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChild("Humanoid")
end

local function FloatTo(position)
    local char, root, humanoid = GetCharacter()
    if not (char and root and humanoid) then return false end
    
    local tween = TweenService:Create(
        root,
        TweenInfo.new(CONFIG.TweenDuration, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position + Vector3.new(0, CONFIG.FloatHeight, 0))}
    )
    tween:Play()
    wait(CONFIG.TweenDuration)
    return true
end

local function TeleportToCollection()
    RemoteEvent:FireServer(unpack(HUBS.Collection.teleportRemote))
    wait(3)
end

local function ReturnToOverworld()
    RemoteEvent:FireServer(unpack(HUBS.OverworldReturn))
    wait(3)
end

-- Quest Detection
local function GetActiveQuests()
    local quests = {}
    
    -- Detect bubble/egg/collection quests
    for _, questType in ipairs({"Daily", "Hourly"}) do
        for i = 1, 3 do
            local path = string.format("Season.Frame.Content.Challenges.%s.List.%s-challenge-%d", questType, questType:lower(), i)
            local questFrame = ScreenGui:FindFirstChild(path, true)
            
            if questFrame and questFrame.Content and questFrame.Content.Bar and questFrame.Content.Bar.Label then
                local percent = tonumber(questFrame.Content.Bar.Label.Text:match("%d+")) or 0
                if percent < 100 then
                    table.insert(quests, {
                        type = questFrame.Content.Label.Text:match("Bubble") and "bubble" or 
                               questFrame.Content.Label.Text:match("Hatch") and "egg" or
                               questFrame.Content.Label.Text:match("Collect") and "collection",
                        frame = questFrame,
                        percent = percent,
                        text = questFrame.Content.Label.Text
                    })
                end
            end
        end
    end
    
    -- Detect task quests
    local tasksFolder = ScreenGui:FindFirstChild("Competitive.Frame.Content.Tasks", true)
    if tasksFolder then
        for _, template in ipairs(tasksFolder:GetChildren()) do
            if template.Name == "Template" and template.Content and template.Content.Bar and template.Content.Bar.Label then
                local percent = tonumber(template.Content.Bar.Label.Text:match("%d+")) or 0
                if percent < 100 then
                    table.insert(quests, {
                        type = "task",
                        frame = template,
                        percent = percent,
                        text = template.Content.Bar.Label.Text
                    })
                end
            end
        end
    end
    
    return quests
end

-- Quest Execution
local function CompleteBubbleQuest(quest)
    print("Starting bubble quest:", quest.text)
    FloatTo(HUBS.Bubble)
    
    local startTime = os.time()
    while quest.percent < 100 do
        RemoteEvent:FireServer({"BlowBubble"})
        quest.percent = tonumber(quest.frame.Content.Bar.Label.Text:match("%d+")) or 0
        print("Progress:", quest.percent.."%")
        
        -- Anti-AFK
        if os.time() - startTime > 120 then
            FloatTo(HUBS.Bubble)
            startTime = os.time()
        end
        
        wait(CONFIG.BubbleRate)
    end
    print("Bubble quest completed!")
    wait(CONFIG.CompletionDelay)
end

local function CompleteEggQuest(quest)
    print("Starting egg quest:", quest.text)
    local eggType = quest.text:match("Hatch %d+ (.+) Eggs?")
    eggType = eggType and (eggType:gsub("s$", ""):gsub("ies$", "y").." Egg") or "Infinity Egg"
    
    local eggPos = EGG_DATA[eggType] or EGG_DATA["Infinity Egg"]
    FloatTo(eggPos)
    
    local startTime = os.time()
    while quest.percent < 100 do
        RemoteEvent:FireServer({"HatchEgg", eggType, CONFIG.HatchQuantity})
        quest.percent = tonumber(quest.frame.Content.Bar.Label.Text:match("%d+")) or 0
        print("Progress:", quest.percent.."%")
        
        -- Anti-AFK
        if os.time() - startTime > 120 then
            FloatTo(eggPos)
            startTime = os.time()
        end
        
        wait(CONFIG.HatchRate)
    end
    print("Egg quest completed!")
    wait(CONFIG.CompletionDelay)
end

local function CompleteCollectionQuest(quest)
    print("Starting collection quest:", quest.text)
    TeleportToCollection()
    
    local startTime = os.time()
    while quest.percent < 100 do
        RemoteEvent:FireServer({"Collect"})
        
        for _, point in ipairs(HUBS.Collection.movementPath) do
            FloatTo(point)
        end
        
        quest.percent = tonumber(quest.frame.Content.Bar.Label.Text:match("%d+")) or 0
        print("Progress:", quest.percent.."%")
        
        -- Anti-AFK
        if os.time() - startTime > 120 then
            FloatTo(HUBS.Collection.movementPath[1])
            startTime = os.time()
        end
        
        wait(CONFIG.CollectionWaitTime)
    end
    
    ReturnToOverworld()
    print("Collection quest completed!")
    wait(CONFIG.CompletionDelay)
end

local function CompleteTaskQuest(quest)
    print("Starting task:", quest.text)
    while quest.percent < 100 do
        quest.percent = tonumber(quest.frame.Content.Bar.Label.Text:match("%d+")) or 0
        print("Progress:", quest.percent.."%")
        wait(CONFIG.CheckInterval)
    end
    print("Task completed! Waiting", CONFIG.CompletionDelay, "seconds")
    wait(CONFIG.CompletionDelay)
end

local function HatchInfinityEgg()
    print("No active quests - hatching Infinity Egg")
    FloatTo(EGG_DATA["Infinity Egg"])
    
    local startTime = os.time()
    while #GetActiveQuests() == 0 do
        RemoteEvent:FireServer({"HatchEgg", "Infinity Egg", CONFIG.HatchQuantity})
        
        -- Anti-AFK
        if os.time() - startTime > 120 then
            FloatTo(EGG_DATA["Infinity Egg"])
            startTime = os.time()
        end
        
        wait(CONFIG.HatchRate)
    end
end

-- Main Loop
while true do
    local activeQuests = GetActiveQuests()
    
    if #activeQuests > 0 then
        -- Process each quest one at a time
        for _, quest in ipairs(activeQuests) do
            if quest.type == "bubble" then
                CompleteBubbleQuest(quest)
            elseif quest.type == "egg" then
                CompleteEggQuest(quest)
            elseif quest.type == "collection" then
                CompleteCollectionQuest(quest)
            elseif quest.type == "task" then
                CompleteTaskQuest(quest)
            end
        end
    else
        HatchInfinityEgg()
    end
    
    wait(1)
end
