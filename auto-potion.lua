local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

local REQUIRED_DAYS = 2    -- Target duration (will spam until this is reached)
local POTION_TIER = 6      -- Tier of potions to use
local POTION_DURATION = 10 -- Duration parameter
local SPAM_DELAY = 0.1     -- Delay between activation attempts
local UI_TIMEOUT = 5       -- Seconds to wait for UI to update
local CHECK_DELAY = 1      -- Seconds between normal checks

local RemoteEvent = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent")
local potions = {
    {
        name = "Lucky",
        displayName = "Lucky6",
        iconPath = function(buffs)
            for _, child in ipairs(buffs:GetChildren()) do
                if child:IsA("Frame") or child:IsA("ImageButton") then
                    local icon = child.Button:FindFirstChild("Icon") or child.Button:FindFirstChild("lcon")
                    if icon and icon:FindFirstChild("PotionLucky6") then
                        return child.Button.Label
                    end
                end
            end
        end
    },
    {
        name = "Mythic",
        displayName = "Mythic6", 
        iconPath = function(buffs)
            local buff = buffs:FindFirstChild("Mythic") or buffs:FindFirstChild('"Mythic"') or buffs:FindFirstChild("[Mythic]")
            if buff then return buff.Button.Label end
        end
    },
    {
        name = "Speed",
        displayName = "Speed6",
        iconPath = function(buffs)
            local buff = buffs:FindFirstChild("Speed")
            if buff then return buff.Button.Label end
        end
    },
    {
        name = "Infinity Elixir",
        displayName = "Infinity Elixir",
        iconPath = function(buffs)
            local success, buff = pcall(function() return buffs["Infinity Elixir"] end)
            if success and buff then return buff.Button.Label end
        end
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
    print("⚡ Activated "..potionType.." potion")
end

local function getDurationDays(durationText)
    if not durationText then return 0 end
    local days = durationText:match("(%d+) day")
    return tonumber(days) or 0
end

local function processPotion(potion)
    local screenGui = localPlayer.PlayerGui:FindFirstChild("ScreenGui")
    if not screenGui then
        print("ScreenGui not found")
        return false
    end
    
    local buffs = screenGui:FindFirstChild("Buffs")
    if not buffs then
        print("Buffs not found")
        return false
    end
    
    local label = potion.iconPath(buffs)
    if not label or not label.Text then
        print("⚠️ "..potion.displayName.." UI not found - poking around for "..UI_TIMEOUT.."s")
        
        local startTime = os.time()
        while os.time() - startTime < UI_TIMEOUT do
            usePotion(potion.name)
            wait(SPAM_DELAY)
            
            if os.time() - startTime > 1 then
                label = potion.iconPath(buffs)
                if label and label.Text then
                    print(potion.displayName.." appeared: "..label.Text)
                    break
                end
            end
        end
        
        if not label or not label.Text then
            print(Failed to find "..potion.displayName.." after testing")
            return false
        end
    end
    
    local currentDays = getDurationDays(label.Text)
    print(potion.displayName..": "..label.Text..(currentDays < REQUIRED_DAYS and " (needs spamming)" or ""))
    
    if currentDays < REQUIRED_DAYS then
        print("Activating "..potion.displayName.." until "..REQUIRED_DAYS.." days...")
        local attempts = 0
        
        while currentDays < REQUIRED_DAYS and attempts < 100 do
            usePotion(potion.name)
            wait(SPAM_DELAY)
            
            label = potion.iconPath(buffs)
            currentDays = getDurationDays(label and label.Text or "")
            attempts = attempts + 1
        end
        
        if currentDays >= REQUIRED_DAYS then
            print("[Complete] "..potion.displayName.." now at "..currentDays.." days")
            return true
        else
            print("⚠️ Couldn't boost "..potion.displayName.." to "..REQUIRED_DAYS.." days")
            return false
        end
    end
    
    return true
end

-- Main loop
while true do
    print("\n"..os.date("%X").." - Checking potions...")
    
    -- Process one potion at a time
    for _, potion in ipairs(potions) do
        local success = processPotion(potion)
        if not success then
            print("Waiting before next attempt...")
            wait(5)
        end
    end
    
    wait(CHECK_DELAY)
end
