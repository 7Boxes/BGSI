local function listQuests()
    local highestReward = 0
    local nextQuest = nil
    local nextQuestType = nil
    local nextQuestIndex = 0
    local nextQuestText = ""

    local function parseReward(rewardText)
        local cleaned = rewardText:gsub("[^%d]", "")
        return tonumber(cleaned) or 0
    end

    local function isCompleted(questPath)
        return questPath.Completed and questPath.Completed.Visible
    end

    -- Daily Quests
    print("=== Daily Quests ===")
    for i = 1, 3 do
        local questPath = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.Season.Frame.Content.Challenges.Daily.List["daily-challenge-"..i]
        if questPath and questPath.Content and questPath.Content.Label then
            local questText = questPath.Content.Label.Text or ""
            local rewardText = (questPath.Content.Reward and questPath.Content.Reward.Label and questPath.Content.Reward.Label.Text) or "0"
            local rewardValue = parseReward(rewardText)
            local status = isCompleted(questPath) and "(Completed)" or ""

            local formattedQuest = questText
            local count, rarity = string.match(questText, "^Hatch (%d+) (.+) Pets$")
            if count and rarity then
                formattedQuest = string.format("%s (%s-%s/%s)", questText, rarity:lower(), count, rewardText)
            else
                local eggCount, eggName = string.match(questText, "^Hatch (%d+) (.+)$")
                if eggCount and eggName then
                    formattedQuest = string.format("%s (%s-%s/%s)", questText, eggName:lower():gsub(" ", "-"), eggCount, rewardText)
                else
                    local currency = string.match(questText, "^Collect (.+)$")
                    if currency then
                        local cleanCurrency = currency:gsub(",", ""):gsub(" ", "-"):lower()
                        formattedQuest = string.format("%s (%s/%s)", questText, cleanCurrency, rewardText)
                    end
                end
            end

            if not isCompleted(questPath) then
                if rewardValue > highestReward then
                    highestReward = rewardValue
                    nextQuest = formattedQuest
                    nextQuestType = "Daily"
                    nextQuestIndex = i
                    nextQuestText = questText
                elseif rewardValue == highestReward and math.random() > 0.5 then
                    nextQuest = formattedQuest
                    nextQuestType = "Daily"
                    nextQuestIndex = i
                    nextQuestText = questText
                end
            end

            print(i .. ". " .. formattedQuest .. " " .. status)
        end
    end

    -- Hourly Quests
    print("\n=== Hourly Quests ===")
    for i = 1, 3 do
        local questPath = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.Season.Frame.Content.Challenges.Hourly.List["hourly-challenge-"..i]
        if questPath and questPath.Content and questPath.Content.Label then
            local questText = questPath.Content.Label.Text or ""
            local rewardText = (questPath.Content.Reward and questPath.Content.Reward.Label and questPath.Content.Reward.Label.Text) or "0"
            local rewardValue = parseReward(rewardText)
            local status = isCompleted(questPath) and "(Completed)" or ""

            local formattedQuest = questText
            local count, rarity = string.match(questText, "^Hatch (%d+) (.+) Pets$")
            if count and rarity then
                formattedQuest = string.format("%s (%s-%s/%s)", questText, rarity:lower(), count, rewardText)
            else
                local eggCount, eggName = string.match(questText, "^Hatch (%d+) (.+)$")
                if eggCount and eggName then
                    formattedQuest = string.format("%s (%s-%s/%s)", questText, eggName:lower():gsub(" ", "-"), eggCount, rewardText)
                else
                    local currency = string.match(questText, "^Collect (.+)$")
                    if currency then
                        local cleanCurrency = currency:gsub(",", ""):gsub(" ", "-"):lower()
                        formattedQuest = string.format("%s (%s/%s)", questText, cleanCurrency, rewardText)
                    end
                end
            end

            if not isCompleted(questPath) then
                if rewardValue > highestReward then
                    highestReward = rewardValue
                    nextQuest = formattedQuest
                    nextQuestType = "Hourly"
                    nextQuestIndex = i
                    nextQuestText = questText
                elseif rewardValue == highestReward and math.random() > 0.5 then
                    nextQuest = formattedQuest
                    nextQuestType = "Hourly"
                    nextQuestIndex = i
                    nextQuestText = questText
                end
            end

            print(i .. ". " .. formattedQuest .. " " .. status)
        end
    end

    if nextQuest then
        print("\n=== Recommended Next Quest ===")
        print(string.format("%s %d: %s (Next)", nextQuestType, nextQuestIndex, nextQuest))
        return nextQuestText:lower()
    else
        print("\nAll quests completed!")
        return nil
    end
end

local function runQuest()
    local quest = listQuests()
    if not quest then return end

    if quest:find("collect") and quest:find("coin") then
        print("Running coin collection quest...")
        local teleport = game:GetService("ReplicatedStorage").Shared.Remotes.Teleport

        teleport:FireServer("Rainbow") 
        task.wait(1)
        game.Players.LocalPlayer.Character:MoveTo(Vector3.new(73.35, 15971.72, 10.04))

        task.wait(2)
        teleport:FireServer("Nightmare")
        task.wait(1)
        game.Players.LocalPlayer.Character:MoveTo(Vector3.new(-22.53, 10146.00, 141.16))
        task.wait(1)
        game.Players.LocalPlayer.Character:MoveTo(Vector3.new(-57.48, 10146.00, 67.87))

        while true do
            teleport:FireServer("Rainbow")
            task.wait(3)
            game.Players.LocalPlayer.Character:MoveTo(Vector3.new(73.35, 15971.72, 10.04))
            task.wait(3)
            teleport:FireServer("Nightmare")
            task.wait(3)
            game.Players.LocalPlayer.Character:MoveTo(Vector3.new(-22.53, 10146.00, 141.16))
            task.wait(1)
            game.Players.LocalPlayer.Character:MoveTo(Vector3.new(-57.48, 10146.00, 67.87))
            task.wait(3)
        end

    elseif quest:find("bubble") then
        print("Running bubble blowing quest...")
        local args = {"BlowBubble"}
        local remote = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent")
        
        while true do
            remote:FireServer(unpack(args))
            task.wait(0.5)
        end
    else
        print("Quest type not automated.")
    end
end

-- Execute the integrated script
runQuest()
