local function listQuests()
    local highestReward = 0
    local nextQuest = nil
    local nextQuestType = nil
    local nextQuestIndex = 0
    
    -- Fixed reward parsing
    local function parseReward(rewardText)
        local cleaned = rewardText:gsub("[^%d]", "")  -- First get cleaned string
        return tonumber(cleaned) or 0  -- Then convert to number
    end
    
    -- Rest of the script remains the same as previous version
    -- ... (keep all other code identical from the last script)
    
    -- Only showing modified parts for brevity
end
    
    -- Helper function to check completion
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
            
            -- Format quest text
            local formattedQuest = questText
            
            -- Template matching (same as before)
            local count, rarity = string.match(questText, "^Hatch (%d+) (.+) Pets$")
            if count and rarity then
                formattedQuest = string.format("%s (%s-%s/%s)", questText, rarity:lower(), count, rewardText)
            else
                local eggCount, eggName = string.match(questText, "^Hatch (%d+) (.+)$")
                if eggCount and eggName then
                    formattedQuest = string.format("%s (%s-%s/%s)", questText, 
                        eggName:lower():gsub(" ", "-"), eggCount, rewardText)
                else
                    local currency = string.match(questText, "^Collect (.+)$")
                    if currency then
                        local cleanCurrency = currency:gsub(",", ""):gsub(" ", "-"):lower()
                        formattedQuest = string.format("%s (%s/%s)", questText, cleanCurrency, rewardText)
                    end
                end
            end

            -- Track next best quest
            if not isCompleted(questPath) then
                if rewardValue > highestReward then
                    highestReward = rewardValue
                    nextQuest = formattedQuest
                    nextQuestType = "Daily"
                    nextQuestIndex = i
                elseif rewardValue == highestReward and math.random() > 0.5 then
                    -- Randomly select if same reward value
                    nextQuest = formattedQuest
                    nextQuestType = "Daily"
                    nextQuestIndex = i
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
            
            -- Format quest text
            local formattedQuest = questText
            
            -- Template matching (same as before)
            local count, rarity = string.match(questText, "^Hatch (%d+) (.+) Pets$")
            if count and rarity then
                formattedQuest = string.format("%s (%s-%s/%s)", questText, rarity:lower(), count, rewardText)
            else
                local eggCount, eggName = string.match(questText, "^Hatch (%d+) (.+)$")
                if eggCount and eggName then
                    formattedQuest = string.format("%s (%s-%s/%s)", questText, 
                        eggName:lower():gsub(" ", "-"), eggCount, rewardText)
                else
                    local currency = string.match(questText, "^Collect (.+)$")
                    if currency then
                        local cleanCurrency = currency:gsub(",", ""):gsub(" ", "-"):lower()
                        formattedQuest = string.format("%s (%s/%s)", questText, cleanCurrency, rewardText)
                    end
                end
            end

            -- Track next best quest
            if not isCompleted(questPath) then
                if rewardValue > highestReward then
                    highestReward = rewardValue
                    nextQuest = formattedQuest
                    nextQuestType = "Hourly"
                    nextQuestIndex = i
                elseif rewardValue == highestReward and math.random() > 0.5 then
                    -- Randomly select if same reward value
                    nextQuest = formattedQuest
                    nextQuestType = "Hourly"
                    nextQuestIndex = i
                end
            end

            print(i .. ". " .. formattedQuest .. " " .. status)
        end
    end
    
    -- Print recommended next quest
    if nextQuest then
        print("\n=== Recommended Next Quest ===")
        print(string.format("%s %d: %s (Next)", nextQuestType, nextQuestIndex, nextQuest))
    else
        print("\nAll quests completed!")
    end
end

listQuests()
