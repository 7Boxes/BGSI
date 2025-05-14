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
    local availableQuests = {}

    for _, type in ipairs({"Daily", "Hourly"}) do
        for i = 1, 3 do
            local questPath = LocalPlayer.PlayerGui.ScreenGui.Season.Frame.Content.Challenges[type].List[type:lower().."-challenge-"..i]
            if questPath and questPath.Content and questPath.Content.Label then
                local questText = questPath.Content.Label.Text or ""
                local rewardText = (questPath.Content.Reward and questPath.Content.Reward.Label and questPath.Content.Reward.Label.Text) or "0"
                if not isCompleted(questPath) then
                    table.insert(availableQuests, {
                        rawText = questText,
                        lowerText = questText:lower(),
                        reward = parseReward(rewardText),
                        gui = questPath
                    })
                end
            end
        end
    end

    table.sort(availableQuests, function(a, b)
        return a.reward > b.reward
    end)

    return availableQuests
end

local function teleportTo(destination)
    RemoteEvent:FireServer("Teleport", destination)
    task.wait(1)
end

local function moveTo(position)
    Character:MoveTo(position)
    task.wait(1)
end

local function handleBubbleQuest()
    print("Running bubble blowing quest...")
    for i = 1, 1000 do
        RemoteEvent:FireServer("BlowBubble")
        task.wait(0.5)
    end
end

local function handleCoinQuest()
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
    task.wait(1)

    teleport:FireServer("Rainbow")
    task.wait(1)
    Character:MoveTo(Vector3.new(73.35, 15971.72, 10.04))
    task.wait(1)
end

local function handleEggQuest(questText, rawText, questGui)
    local count, name = string.match(questText:lower(), "^hatch (%d+) (.+)")
    if not count or not name then return false end

    name = name:gsub("pets", ""):gsub("eggs", ""):gsub("egg", ""):gsub("^%s*(.-)%s*$", "%1")

    local matchedEggName = nil
    for egg in pairs(EggData) do
        if egg:lower():find(name) then
            matchedEggName = egg
            break
        end
    end

    if not matchedEggName then
        warn("Could not match egg for quest: " .. rawText)
        return false
    end

    local data = EggData[matchedEggName]
    teleportTo(data.teleport)
    moveTo(data.position)

    print("Hatching " .. matchedEggName .. " until quest is completed...")
    while not isCompleted(questGui) do
        RemoteEvent:FireServer("HatchEgg", matchedEggName, tonumber(count))
        task.wait(0.1)
    end

    print("Completed quest: " .. rawText)
    return true
end

local function runQuest()
    local quests = listQuests()
    local completed = {}

    while #quests > 0 do
        local picked = nil
        for _, quest in ipairs(quests) do
            local text = quest.lowerText

            if text:find("bubble") then
                picked = quest
                break
            end
        end

        if not picked then
            for _, quest in ipairs(quests) do
                if quest.lowerText:find("collect") and quest.lowerText:find("coin") then
                    picked = quest
                    break
                end
            end
        end

        if not picked then
            for _, quest in ipairs(quests) do
                if quest.lowerText:find("hatch") then
                    picked = quest
                    break
                end
            end
        end

        if not picked then
            break
        end

        print("Running quest: " .. picked.rawText)

        if picked.lowerText:find("bubble") then
            handleBubbleQuest()
        elseif picked.lowerText:find("collect") and picked.lowerText:find("coin") then
            handleCoinQuest()
        elseif picked.lowerText:find("hatch") then
            local success = handleEggQuest(picked.lowerText, picked.rawText, picked.gui)
            if not success then
                print("Failed to run hatch quest: " .. picked.rawText)
            end
        end

        task.wait(2)
        quests = listQuests()
    end

    print("All quests completed. Running board script...")

    getgenv().boardSettings = {
        UseGoldenDice = true,
        GoldenDiceDistance = 1,
        DiceDistance = 6,
        GiantDiceDistance = 10,
    }

    getgenv().remainingItems = {}

    loadstring(game:HttpGet("https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/BGSI/main.lua"))()
end

-- Start the script
runQuest()
