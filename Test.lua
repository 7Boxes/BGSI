-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Player References
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Remote Events
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent")
local TeleportRemote = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"):WaitForChild("Teleport")

-- Egg Data Map
local EggData = {
    ["Spikey Egg"] = { teleport = "Workspace.Worlds.The Overworld.Islands.Floating Island.Island.Portal.Spawn", position = Vector3.new(-6.55, 429.51, 162.53) },
    ["Crystal Egg"] = { teleport = "Workspace.Worlds.The Overworld.Islands.Outer Space.Island.Portal.Spawn", position = Vector3.new(-24.26, 2671.33, 18.94) },
    ["Magma Egg"] = { teleport = "Workspace.Worlds.The Overworld.Islands.Outer Space.Island.Portal.Spawn", position = Vector3.new(-23.27, 2670.76, 8.20) },
    ["Lunar Egg"] = { teleport = "Workspace.Worlds.The Overworld.Islands.Twilight.Island.Portal.Spawn", position = Vector3.new(-58.20, 6868.44, 75.15) },
    ["Void Egg"] = { teleport = "Workspace.Worlds.The Overworld.Islands.The Void.Island.Portal.Spawn", position = Vector3.new(9.54, 10153.89, 190.56) },
    ["Hell Egg"] = { teleport = "Workspace.Worlds.The Overworld.Islands.The Void.Island.Portal.Spawn", position = Vector3.new(-6.56, 10153.95, 197.27) },
    ["Nightmare Egg"] = { teleport = "Workspace.Worlds.The Overworld.Islands.The Void.Island.Portal.Spawn", position = Vector3.new(-21.36, 10152.93, 187.51) },
    ["Rainbow Egg"] = { teleport = "Workspace.Worlds.The Overworld.Islands.Zen.Island.Portal.Spawn", position = Vector3.new(-35.94, 15978.93, 50.24) },
    ["Showman Egg"] = { teleport = "Workspace.Worlds.Minigame Paradise.Portal.Spawn", position = Vector3.new(9945.38, 35.80, 213.75) },
    ["Game Egg"] = { teleport = "Workspace.Worlds.Minigame Paradise.Portal.Spawn", position = Vector3.new(9827.93, 34.46, 171.15) },
    ["Mining Egg"] = { teleport = "Workspace.Worlds.Minigame Paradise.Islands.Minecart Forest.Island.Portal.Spawn", position = Vector3.new(9924.43, 7688.74, 244.19) },
    ["Cyber Egg"] = { teleport = "Workspace.Worlds.Minigame Paradise.Islands.Robot Factory.Island.Portal.Spawn", position = Vector3.new(9919.21, 13416.94, 242.35) },
    ["Common Egg"] = { teleport = "Workspace.Worlds.The Overworld.Portal.Spawn", position = Vector3.new(-12.14, 15.39, -81.50) },
    ["Spotted Egg"] = { teleport = "Workspace.Worlds.The Overworld.Portal.Spawn", position = Vector3.new(-13.19, 15.13, -71.07) },
    ["Iceshard Egg"] = { teleport = "Workspace.Worlds.The Overworld.Portal.Spawn", position = Vector3.new(-12.31, 16.31, -60.13) },
    ["Infinity Egg"] = { teleport = "Workspace.Worlds.The Overworld.Portal.Spawn", position = Vector3.new(-106.37, 19.31, -26.72) }
}

-- Noclip Functionality
local Noclip = nil
local Clip = nil

function noclip()
    Clip = false
    local function Nocl()
        if Clip == false and LocalPlayer.Character ~= nil then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA('BasePart') and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
        wait(0.21)
    end
    Noclip = RunService.Stepped:Connect(Nocl)
end

function clip()
    if Noclip then Noclip:Disconnect() end
    Clip = true
end

noclip()

-- Helper Functions
local function parseReward(rewardText)
    local cleaned = rewardText:gsub("[^%d]", "")
    return tonumber(cleaned) or 0
end

local function isCompleted(questPath)
    return questPath.Completed and questPath.Completed.Visible
end

local function listQuests()
    local quests = {}

    local function addQuests(challengeType)
        for i = 1, 3 do
            local questPath = LocalPlayer.PlayerGui.ScreenGui.Season.Frame.Content.Challenges[challengeType].List[challengeType:lower().."-challenge-"..i]
            if questPath and questPath.Content and questPath.Content.Label then
                local questText = questPath.Content.Label.Text or ""
                local rewardText = (questPath.Content.Reward and questPath.Content.Reward.Label and questPath.Content.Reward.Label.Text) or "0"
                local rewardValue = parseReward(rewardText)
                local completed = isCompleted(questPath)

                table.insert(quests, {
                    text = questText,
                    reward = rewardValue,
                    completed = completed
                })
            end
        end
    end

    addQuests("Daily")
    addQuests("Hourly")

    -- Filter out completed quests
    local availableQuests = {}
    for _, quest in ipairs(quests) do
        if not quest.completed then
            table.insert(availableQuests, quest)
        end
    end

    -- Sort quests by priority: bubble > collect > hatch
    table.sort(availableQuests, function(a, b)
        local function getPriority(text)
            text = text:lower()
            if text:find("bubble") then
                return 1
            elseif text:find("collect") and text:find("coin") then
                return 2
            elseif text:find("hatch") then
                return 3
            else
                return 4
            end
        end
        local priorityA = getPriority(a.text)
        local priorityB = getPriority(b.text)
        if priorityA == priorityB then
            return a.reward > b.reward
        else
            return priorityA < priorityB
        end
    end)

    return availableQuests
end

local function teleportTo(destination)
    RemoteEvent:FireServer("Teleport", destination)
    task.wait(1)
end

local function moveTo(position)
    HumanoidRootPart.CFrame = CFrame.new(position)
    task.wait(1)
end

local function hatchEgg(eggName, quantity)
    RemoteEvent:FireServer("HatchEgg", eggName, quantity)
end

local function isQuestCompleted(questText)
    local quests = listQuests()
    for _, quest in ipairs(quests) do
        if quest.text == questText then
            return false
        end
    end
    return true
end

local function handleBubbleQuest(questText)
    print("Running bubble blowing quest...")
    while not isQuestCompleted(questText) do
        RemoteEvent:FireServer("BlowBubble")
        task.wait(0.5)
    end
end

local function handleCoinQuest(questText)
    print("Running coin collection quest...")
    local locations = {
        { world = "Rainbow", position = Vector3.new(73.35, 15971.72, 10.04) },
        { world = "Nightmare", position = Vector3.new(-22.53, 10146.00, 141.16) },
        { world = "Nightmare", position = Vector3.new(-57.48, 10146.00, 67.87) }
    }

    local index = 1
    while not isQuestCompleted(questText) do
        local loc = locations[index]
        TeleportRemote:FireServer(loc.world)
        task.wait(1)
        Character:MoveTo(loc.position)
        task.wait(3)
        index = index % #locations + 1
    end
end

local function handleEggQuest(questText)
    print("Running egg hatching quest...")
    local count, rarity = string.match(questText:lower(), "^hatch (%d+) (.+) pets$")
    local eggName = nil
    if count and rarity then
        if rarity == "unique" then
            eggName = "Infinity Egg"
        else
            eggName = rarity:sub(1, 1):upper() .. rarity:sub(2) .. " Egg"
        end
    else
        local count2, name = string.match(questText:lower(), "^hatch (%d+) (.+) egg$")
        if count2 then
            eggName = name:sub(1, 1):upper() .. name:sub(2) .. " Egg"
        end
    end

    -- Handle egg hatching for the Infinity Egg
    if eggName == "Infinity Egg" then
        local eggPosition = EggData["Infinity Egg"].position
        while not isQuestCompleted(questText) do
            moveTo(eggPosition)
            hatchEgg(eggName, tonumber(count))
            task.wait(3)
        end
    else
        print("Handling egg hatching quest for " .. eggName)
    end
end
