-- multi.lua (Complete Error-Handling Version)
local BGSI = {}

function BGSI:Initialize(config)
    self.Config = config or {}
    
    print("[BGSI] Initializing - scripts will begin in 5 seconds")
    wait(10) -- Initial delay

    local scripts = {
        {
            name = "Auto Potion", 
            url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/auto-potion.lua",
            enabled = self.Config.AutoPotion and self.Config.AutoPotion.Enabled
        },
        {
            name = "Auto Shiny", 
            url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/auto-shiny.lua",
            enabled = self.Config.AutoShiny and self.Config.AutoShiny.Enabled
        },
        {
            name = "Claim Chests", 
            url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-chests.lua",
            enabled = self.Config.ClaimChests and self.Config.ClaimChests.Enabled
        },
        {
            name = "Claim Daily Stars", 
            url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-daily-stars.lua",
            enabled = self.Config.ClaimDailyStars and self.Config.ClaimDailyStars.Enabled
        },
        {
            name = "Claim Playtime", 
            url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-playtime.lua",
            enabled = self.Config.ClaimPlaytime and self.Config.ClaimPlaytime.Enabled
        },
        {
            name = "Claim Season Pass", 
            url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/claim-season-pass.lua",
            enabled = self.Config.ClaimSeasonPass and self.Config.ClaimSeasonPass.Enabled
        },
        {
            name = "Stars Shop", 
            url = "https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/stars-shop.lua",
            enabled = self.Config.StarsShop and self.Config.StarsShop.Enabled
        }
    }

    for _, script in ipairs(scripts) do
        if script.enabled then
            print("\n=== [BGSI] Attempting: " .. script.name .. " ===")
            
            local success, err = pcall(function()
                -- Stage 1: Download
                local scriptSrc
                local downloadSuccess, downloadErr = pcall(function()
                    scriptSrc = game:HttpGet(script.url, true)
                end)
                
                if not downloadSuccess then
                    error("DOWNLOAD FAILED: "..tostring(downloadErr))
                end
                
                -- Stage 2: Load
                local loadedFunction
                local loadSuccess, loadErr = pcall(function()
                    loadedFunction = loadstring(scriptSrc)
                end)
                
                if not loadSuccess then
                    error("LOAD FAILED: "..tostring(loadErr))
                end
                
                if not loadedFunction then
                    error("LOAD FAILED: No function returned")
                end
                
                -- Stage 3: Execute
                local executeSuccess, executeErr = pcall(function()
                    loadedFunction()
                end)
                
                if not executeSuccess then
                    error("EXECUTION FAILED: "..tostring(executeErr))
                end
            end)
            
            if not success then
                warn("[BGSI] ERROR DETAILS:")
                warn(err)
                warn("Continuing to next script...")
            else
                print("[BGSI] SUCCESS: "..script.name.." ran without errors")
            end
            
            wait(5) -- Delay between scripts
        else
            print("[BGSI] Skipping disabled script: "..script.name)
        end
    end
    
    print("\n[BGSI] All scripts processed!")
end

return BGSI
