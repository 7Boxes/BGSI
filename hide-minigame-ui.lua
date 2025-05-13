local function hideMinigameHUD()
    local success, error = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        if player then
            local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("ScreenGui")
            if screenGui then
                local minigameHUD = screenGui:FindFirstChild("MinigameHUD")
                if minigameHUD then
                    minigameHUD.Visible = false
                    -- Uncomment the line below if you want to completely disable the ui
                    -- minigameHUD.Enabled = false
                end
            end
        end
    end)
    
    if not success then
        warn("[HUD Hider] Error: " .. tostring(error))
    end
end

local player = game:GetService("Players").LocalPlayer
while not player do
    wait(1)
    player = game:GetService("Players").LocalPlayer
end

hideMinigameHUD()

while true do
    hideMinigameHUD()
    wait(0.5) -- Check every 0.5 seconds (adjust as needed)
end
