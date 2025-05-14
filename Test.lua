local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local RemoteEvent = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

-- Egg data map
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
    ["Iceshard Egg"] = { teleport = "Workspace.Worlds.The Overworld.Portal.Spawn", position = Vector3.new(-12.31, 16.31, -60.13) }
}

local function parseReward(rewardText)
    local cleaned = rewardText:gsub("[^%d]", "")
    return tonumber(cleaned) or 0
end

local function isCompleted(questPath)
    return questPath.Completed and questPath.Completed.Visible
end

local function listQuests()
    local highestReward = 0
    local nextQuestText = ""
    local nextQuestRaw = ""

    print("=== Daily Quests ===")
    for i = 1, 3 do
        local questPath = LocalPlayer.PlayerGui.ScreenGui.Season.Frame.Content.Challenges.Daily.List["daily-challenge-"..i]
        if questPath and questPath.Content and questPath.Content.Label then
            local questText = questPath.Content.Label.Text or ""
            local rewardText = (questPath.Content.Reward and questPath.Content.Reward.Label and questPath.Content.Reward.Label.Text) or "0"
            local rewardValue = parseReward(rewardText)
            local status = isCompleted(questPath) and "(Completed)" or ""

            if not isCompleted(questPath) then
                if rewardValue > highestReward or (rewardValue == highestReward and math.random() > 0.5) then
                    highestReward = rewardValue
                    nextQuestText = questText:lower()
                    nextQuestRaw = questText
                end
            end
            print(i .. ". " .. questText .. " " .. status)
        end
    end

    print("\n=== Hourly Quests ===")
    for i = 1, 3 do
        local questPath = LocalPlayer.PlayerGui.ScreenGui.Season.Frame.Content.Challenges.Hourly.List["hourly-challenge-"..i]
        if questPath and questPath.Content and questPath.Content.Label then
            local questText = questPath.Content.Label.Text or ""
            local rewardText = (questPath.Content.Reward and questPath.Content.Reward.Label and questPath.Content.Reward.Label.Text) or "0"
            local rewardValue = parseReward(rewardText)
            local status = isCompleted(questPath) and "(Completed)" or ""

            if not isCompleted(questPath) then
                if rewardValue > highestReward or (rewardValue == highestReward and math.random() > 0.5) then
                    highestReward = rewardValue
                    nextQuestText = questText:lower()
                    nextQuestRaw = questText
                end
            end
            print(i .. ". " .. questText .. " " .. status)
        end
    end

    return nextQuestText, nextQuestRaw
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
    task.wait(1)
end

local function handleEggQuest(questText)
    local count, name = string.match(questText:lower(), "^hatch (%d+) (.+)")
    if not count or not name then return false end

    -- Clean name: remove "pets", "eggs", or "egg" and trim whitespace
    name = name:gsub("pets", ""):gsub("eggs", ""):gsub("egg", ""):gsub("^%s*(.-)%s*$", "%1")

    -- Try to match against known EggData keys
    local matchedEggName = nil
    for egg in pairs(EggData) do
        if egg:lower():find(name) then
            matchedEggName = egg
            break
        end
    end

    if matchedEggName then
        local data = EggData[matchedEggName]
        teleportTo(data.teleport)
        moveTo(data.position)
        hatchEgg(matchedEggName, tonumber(count))
        return true
    else
        return false
    end
end

local function runQuest()
    local quest, rawText = listQuests()
    if not quest then return end

    if quest:find("collect") and quest:find("coin") then
        print("Running coin collection quest...")
        local teleport = ReplicatedStorage.Shared.Remotes.Teleport

        teleport:FireServer("Rainbow") 
        task.wait(1)
        Character:MoveTo(Vector3.new(73.35, 15971.72, 10.04))

        task.wait(2)
        teleport:FireServer("Nightmare")
        task.wait(1)
        Character:MoveTo(Vector3.new(-22.53, 10146.00, 141.16))
        task.wait(1)
        Character:MoveTo(Vector3.new(-57.48, 10146.00, 67.87))

        while true do
            teleport:FireServer("Rainbow")
            task.wait(3)
            Character:MoveTo(Vector3.new(73.35, 15971.72, 10.04))
            task.wait(3)
            teleport:FireServer("Nightmare")
            task.wait(3)
            Character:MoveTo(Vector3.new(-22.53, 10146.00, 141.16))
            task.wait(1)
            Character:MoveTo(Vector3.new(-57.48, 10146.00, 67.87))
            task.wait(3)
        end

    elseif quest:find("bubble") then
        print("Running bubble blowing quest...")
        while true do
            RemoteEvent:FireServer("BlowBubble")
            task.wait(0.5)
        end

    elseif quest:find("hatch") then
        print("Running egg hatching quest...")
        local success = handleEggQuest(quest)
        if success then
            print("Egg hatching in progress...")
        else
            print("Unsupported egg type: " .. rawText)
        end
    else
        print("Quest type not automated: " .. rawText)
    end
end

-- Start script
runQuest()
