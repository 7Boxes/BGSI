--// Configuration
local HATCH_COUNT = 4 -- Number of pets to hatch per quest

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Player References
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

--// Remote Events (Safe Load)
local function safeWaitForChild(parent, childName, timeout)
    local result = parent:WaitForChild(childName, timeout)
    if not result then
        warn("Failed to find child:", childName)
    end
    return result
end

local Shared = safeWaitForChild(ReplicatedStorage, "Shared", 10)
local Framework = safeWaitForChild(Shared, "Framework", 10)
local Network = safeWaitForChild(Framework, "Network", 10)
local Remote = safeWaitForChild(Network, "Remote", 10)
local RemoteEvent = safeWaitForChild(Remote, "RemoteEvent", 10)

local RemotesFolder = safeWaitForChild(Shared, "Remotes", 10)
local TeleportRemote = safeWaitForChild(RemotesFolder, "Teleport", 10)

if not RemoteEvent or not TeleportRemote then
    error("❌ Missing required RemoteEvents. Script stopped.")
end

--// Egg Data
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

--// Noclip Setup
local Clip = nil
local Noclip = nil
function noclip()
    Clip = false
    local function disableCollision()
        if not Clip and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
    Noclip = RunService.Stepped:Connect(disableCollision)
end

function clip()
    if Noclip then Noclip:Disconnect() end
    Clip = true
end

noclip()

--// Helpers
local function parseReward(text)
    local cleaned = text:gsub("%D", "")
    return tonumber(cleaned) or 0
end

local function isCompleted(questPath)
    return questPath.Completed and questPath.Completed.Visible
end

local function listQuests()
    local quests = {}
    local function scanType(typeName)
        for i = 1, 3 do
            local path = LocalPlayer.PlayerGui.ScreenGui.Season.Frame.Content.Challenges[typeName].List[typeName:lower().."-challenge-"..i]
            if path and path.Content and path.Content.Label then
                table.insert(quests, {
                    text = path.Content.Label.Text or "",
                    reward = parseReward(path.Content.Reward and path.Content.Reward.Label.Text or "0"),
                    completed = isCompleted(path)
                })
            end
        end
    end

    scanType("Daily")
    scanType("Hourly")

    local active = {}
    for _, quest in ipairs(quests) do
        if not quest.completed then
            table.insert(active, quest)
        end
    end

    table.sort(active, function(a, b)
        local function priority(text)
            text = text:lower()
            if text:find("bubble") then return 1
            elseif text:find("collect") and text:find("coin") then return 2
            elseif text:find("hatch") then return 3
            else return 4 end
        end
        return priority(a.text) < priority(b.text) or (priority(a.text) == priority(b.text) and a.reward > b.reward)
    end)

    return active
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
    for _, quest in ipairs(listQuests()) do
        if quest.text == questText then return false end
    end
    return true
end

--// Quest Handlers
local function handleBubbleQuest(questText)
    print("➡️ Bubble quest started")
    while not isQuestCompleted(questText) do
        RemoteEvent:FireServer("BlowBubble")
        task.wait(0.5)
    end
end

local function handleCoinQuest(questText)
    print("➡️ Coin quest started")
    local locations = {
        { world = "Rainbow", position = Vector3.new(73.35, 15971.72, 10.04) },
        { world = "Nightmare", position = Vector3.new(-22.53, 10146.00, 141.16) },
        { world = "Nightmare", position = Vector3.new(-57.48, 10146.00, 67.87) }
    }

    local i = 1
    while not isQuestCompleted(questText) do
        local loc = locations[i]
        TeleportRemote:FireServer(loc.world)
        task.wait(1)
        Character:MoveTo(loc.position)
        task.wait(3)
        i = i % #locations + 1
    end
end

local function handleEggQuest(questText)
    print("➡️ Egg quest started")
    local count, rarity = string.match(questText:lower(), "^hatch (%d+) (.+) pets$")
    local eggName

    if count and rarity then
        eggName = (rarity == "unique") and "Infinity Egg" or rarity:sub(1, 1):upper() .. rarity:sub(2) .. " Egg"
    else
        local count2, name = string.match(questText:lower(), "^hatch (%d+) (.+) egg$")
        if count2 then eggName = name:sub(1, 1):upper() .. name:sub(2) .. " Egg" end
    end

    if eggName and EggData[eggName] then
        local egg = EggData[eggName]
        teleportTo(egg.teleport)
        moveTo(egg.position)

        while not isQuestCompleted(questText) do
            hatchEgg(eggName, HATCH_COUNT)
            task.wait(3)
        end
    else
        warn("⚠️ Unknown egg:", questText)
    end
end

--// Start Main Loop
for _, quest in ipairs(listQuests()) do
    local text = quest.text:lower()
    if text:find("bubble") then
        handleBubbleQuest(quest.text)
    elseif text:find("collect") and text:find("coin") then
        handleCoinQuest(quest.text)
    elseif text:find("hatch") then
        handleEggQuest(quest.text)
    end
end
