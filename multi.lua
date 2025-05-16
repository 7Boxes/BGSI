local BGSI = {}

function BGSI:Initialize(config)
    self.Config = config or {}
    local scripts = {
        { name = "Auto Potion", url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/auto-potion.lua", enabled = self.Config.AutoPotion and self.Config.AutoPotion.Enabled },
        { name = "Auto Shiny", url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/auto-shiny.lua", enabled = self.Config.AutoShiny and self.Config.AutoShiny.Enabled },
        { name = "Claim Chests", url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-chests.lua", enabled = self.Config.ClaimChests and self.Config.ClaimChests.Enabled },
        { name = "Claim Daily Stars", url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-daily-stars.lua", enabled = self.Config.ClaimDailyStars and self.Config.ClaimDailyStars.Enabled },
        { name = "Claim Playtime", url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-playtime.lua", enabled = self.Config.ClaimPlaytime and self.Config.ClaimPlaytime.Enabled },
        { name = "Claim Season Pass", url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-season-pass.lua", enabled = self.Config.ClaimSeasonPass and self.Config.ClaimSeasonPass.Enabled },
        { name = "Stars Shop", url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/stars-shop.lua", enabled = self.Config.StarsShop and self.Config.StarsShop.Enabled }
    }

    for _, script in ipairs(scripts) do
        if script.enabled then
            print("[BGSI] Loading: " .. script.name)
            local success, err = pcall(function()
                loadstring(game:HttpGet(script.url, true))()
            end)
            
            if success then
                print("[BGSI] Success: " .. script.name)
            else
                warn("[BGSI] Failed: " .. script.name .. " | Error: " .. tostring(err))
            end
            
            wait(5) 
        else
            print("[BGSI] Skipping: " .. script.name)
        end
    end
    
    print("[BGSI] All enabled scripts processed!")
end

return BGSI
