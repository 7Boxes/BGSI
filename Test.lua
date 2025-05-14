local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local RemoteEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent")

-- Mapping of egg names to their teleport destinations and coordinates
local EggData = {
    ["Spikey Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Islands.Floating Island.Island.Portal.Spawn",
        position = Vector3.new(-6.55, 429.51, 162.53)
    },
    ["Crystal Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Islands.Outer Space.Island.Portal.Spawn",
        position = Vector3.new(-24.26, 2671.33, 18.94)
    },
    ["Magma Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Islands.Outer Space.Island.Portal.Spawn",
        position = Vector3.new(-23.27, 2670.76, 8.20)
    },
    ["Lunar Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Islands.Twilight.Island.Portal.Spawn",
        position = Vector3.new(-58.20, 6868.44, 75.15)
    },
    ["Void Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Islands.The Void.Island.Portal.Spawn",
        position = Vector3.new(9.54, 10153.89, 190.56)
    },
    ["Hell Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Islands.The Void.Island.Portal.Spawn",
        position = Vector3.new(-6.56, 10153.95, 197.27)
    },
    ["Nightmare Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Islands.The Void.Island.Portal.Spawn",
        position = Vector3.new(-21.36, 10152.93, 187.51)
    },
    ["Rainbow Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Islands.Zen.Island.Portal.Spawn",
        position = Vector3.new(-35.94, 15978.93, 50.24)
    },
    ["Showman Egg"] = {
        teleport = "Workspace.Worlds.Minigame Paradise.Portal.Spawn",
        position = Vector3.new(9945.38, 35.80, 213.75)
    },
    ["Game Egg"] = {
        teleport = "Workspace.Worlds.Minigame Paradise.Portal.Spawn",
        position = Vector3.new(9827.93, 34.46, 171.15)
    },
    ["Mining Egg"] = {
        teleport = "Workspace.Worlds.Minigame Paradise.Islands.Minecart Forest.Island.Portal.Spawn",
        position = Vector3.new(9924.43, 7688.74, 244.19)
    },
    ["Cyber Egg"] = {
        teleport = "Workspace.Worlds.Minigame Paradise.Islands.Robot Factory.Island.Portal.Spawn",
        position = Vector3.new(9919.21, 13416.94, 242.35)
    },
    ["Common Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Portal.Spawn",
        position = Vector3.new(-12.14, 15.39, -81.50)
    },
    ["Spotted Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Portal.Spawn",
        position = Vector3.new(-13.19, 15.13, -71.07)
    },
    ["Iceshard Egg"] = {
        teleport = "Workspace.Worlds.The Overworld.Portal.Spawn",
        position = Vector3.new(-12.31, 16.31, -60.13)
    }
}

-- Function to parse reward text into a numerical value
local function parseReward(rewardText)
    local cleaned = rewardText:gsub("[^%d]", "")
    return tonumber(cleaned) or 0
end

-- Function to check if a quest is completed
local function isCompleted(questPath)
    return questPath.Completed and questPath.Completed.Visible
end

-- Function to extract quest details
local function getQuestDetails(questPath)
    local questText = questPath.Content.Label.Text or ""
    local rewardText = (questPath.Content.Reward and questPath.Content.Reward.Label and questPath.Content.Reward.Label.Text) or "0"
    local rewardValue = parseReward(rewardText)
    return questText, rewardValue
end

-- Function to find the next uncompleted quest with the highest reward
local function findNextQuest()
    local highestReward = 0
    local nextQuest = nil
    local nextQuestType = nil
    local nextQuestIndex = 0
    local questPath = nil

    -- Daily Quests
    for i = 1, 3 do
        local path = LocalPlayer.PlayerGui.ScreenGui.Season.Frame.Content.Challenges.Daily.List["daily-challenge-"..i]
        if path and path.Content and path.Content.Label and not isCompleted(path) then
            local _, rewardValue = getQuestDetails(path)
            if rewardValue > highestReward then
                highestReward = rewardValue
                nextQuest = path
                nextQuestType = "Daily"
                nextQuestIndex = i
                questPath = path
            end
        end
    end

    -- Hourly Quests
    for i = 1, 3 do
        local path = LocalPlayer.PlayerGui.ScreenGui.Season.Frame.Content.Challenges.Hourly.List["hourly-challenge-"..i]
        if path and path.Content and path.Content.Label and not isCompleted(path) then
            local _, rewardValue = getQuestDetails(path)
            if rewardValue > highestReward then
                highestReward = rewardValue
                nextQuest = path
                nextQuestType = "Hourly"
                nextQuestIndex = i
                questPath = path
            end
        end
    end

    return nextQuest, nextQuestType, nextQuestIndex, questPath
end

-- Function to teleport the player
local function teleportTo(destination)
    RemoteEvent:FireServer("Teleport", destination)
    task.wait(1)
end

-- Function to move the player to a specific position
local function moveTo(position)
    HumanoidRootPart.CFrame = CFrame.new(position)
    task.wait(1)
end

-- Function to hatch an egg
local function hatchEgg(eggName, quantity)
    RemoteEvent:FireServer("HatchEgg", eggName, quantity)
    task.wait(1)
end

-- Main function to complete quests
local function completeQuests()
    while true do
        local quest, questType, questIndex, questPath = findNextQuest()
        if not quest then
            print("All quests completed!")
            break
        end

        local questText = questPath.Content.Label.Text or ""
        print(string.format("Starting %s Quest %d: %s", questType, questIndex, questText))

        -- Determine the egg name from the quest text
        local eggName = nil
        local eggCount = 1

        local count, rarity = string.match(questText, "^Hatch (%d+) (.+) Pets$")
        if count and rarity then
            eggName = rarity .. " Egg"
            eggCount = tonumber(count)
        else
            local count2, name = string.match(questText, "^Hatch (%d+) (.+)$")
            if count2 and name then
                eggName = name
                eggCount = tonumber(count2)
            end
        end

        if eggName and EggData[eggName] then
            local data = EggData[eggName]
            teleportTo(data.teleport)
            moveTo(data.position)
            hatchEgg(eggName, eggCount)
        else
            print("Unknown egg or quest type: " .. questText)
        end

        task.wait(1)
    end
end

-- Start the quest completion process
completeQuests()
