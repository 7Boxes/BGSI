local BGSI = {}

function BGSI:Initialize(config)
    self.Config = config or {}
    
    -- Load all modules based on configuration
    if self.Config.AutoPotion and self.Config.AutoPotion.Enabled then
        self:LoadScript("https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/auto-potion.lua")
    end
    
    if self.Config.AutoShiny and self.Config.AutoShiny.Enabled then
        self:LoadScript("https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/auto-shiny.lua")
    end
    
    if self.Config.ClaimChests and self.Config.ClaimChests.Enabled then
        self:LoadScript("https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-chests.lua")
    end
    
    if self.Config.ClaimDailyStars and self.Config.ClaimDailyStars.Enabled then
        self:LoadScript("https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-daily-stars.lua")
    end
    
    if self.Config.ClaimPlaytime and self.Config.ClaimPlaytime.Enabled then
        self:LoadScript("https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-playtime.lua")
    end
    
    if self.Config.ClaimSeasonPass and self.Config.ClaimSeasonPass.Enabled then
        self:LoadScript("https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-season-pass.lua")
    end
    
    if self.Config.StarsShop and self.Config.StarsShop.Enabled then
        self:LoadScript("https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/stars-shop.lua")
    end
    
    print("BGSI Scripts loaded successfully!")
end

function BGSI:LoadScript(url)
    local success, err = pcall(function()
        loadstring(game:HttpGet(url, true))()
    end)
    
    if not success then
        warn("Failed to load script from " .. url .. ": " .. err)
    end
end

return BGSI
