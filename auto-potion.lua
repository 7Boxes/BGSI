local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

local MINIMUM_DURATION = 1 -- Days threshold (will activate potions when duration is below this)
local CHECK_INTERVAL = 60  -- Seconds between checks
local POTION_TIER = 6      -- Tier of potions to use 
local POTION_DURATION = 10 -- Duration in days to apply

local RemoteEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent")

local potions = {
    {
        name = "Lucky",
        displayName = "Lucky6",
        buffName = "Lucky",
        iconName = "PotionLucky6"
    },
    {
        name = "Mythic",
        displayName = "Mythic6",
        buffName = "Mythic", 
        iconName = "PotionMythic6"
    },
    {
        name = "Speed",
        displayName = "Speed6",
        buffName = "Speed",
        iconName = "PotionSpeed6"
    },
    {
        name = "Infinity Elixir",
        displayName = "Infinity Elixir",
        buffName = "Infinity Elixir",
        iconName = "PotionInfinity Elixir1"
    }
}

local function usePotion(potionType)
    local args = {
        "UsePotion",
        potionType,
        POTION_TIER,
        POTION_DURATION
    }
    RemoteEvent:FireServer(unpack(args))
    print("Activated "..potionType.." potion at", os.date("%X"))
end

local function parseDuration(durationText)
    if durationText:find("day") then
        local days = tonumber(durationText:match("(%d+) day"))
        return days, "days"
    else
        local h, m, s = durationText:match("(%d+):(%d+):?(%d*)")
        return {h = tonumber(h), m = tonumber(m), s = tonumber(s)}, "hms"
    end
end

local function shouldActivate(duration)
    if type(duration) == "number" then 
        return duration < MINIMUM_DURATION
    else 
        return true 
    end
end

local function checkPotionDurations()
    local screenGui = localPlayer.PlayerGui:WaitForChild("ScreenGui")
    local buffs = screenGui:WaitForChild("Buffs")
    
    for _, potion in ipairs(potions) do
        local success, buff = pcall(function()
            return buffs[potion.buffName] or buffs['"'..potion.buffName..'"'] or buffs["["..potion.buffName.."]"]
        end)
        
        if success and buff then
            local button = buff:FindFirstChild("Button")
            if button then
                local icon = button:FindFirstChild("Icon") or button:FindFirstChild("lcon")
                local label = button:FindFirstChild("Label")
                
                if icon and icon:FindFirstChild(potion.iconName) and label then
                    local duration, format = parseDuration(label.Text)
                    
                    print(potion.displayName..": "..label.Text)
                    
                    if shouldActivate(duration) then
                        usePotion(potion.name)
                    end
                end
            end
        end
    end
    print("------------------")
end

while wait(CHECK_INTERVAL) do
    pcall(checkPotionDurations) 
end
