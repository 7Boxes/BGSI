local BGSI = {}

function BGSI:Initialize(config)
    self.Config = config or {}
    
    print("[BGSI] Initializing...")
    wait(5) 

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
            print("[BGSI] Attempting: " .. script.name)
            
            local success, err = pcall(function()
                local scriptSrc = game:HttpGet(script.url, true)
                loadstring(scriptSrc)()
            end)
            
            if not success then
                warn("[BGSI] Error in "..script.name..": "..tostring(err))
                print("[BGSI] Continuing to next script...")
            end
            
            wait(5) 
        end
    end
    
    print("[BGSI] Done!")
end

return BGSI
