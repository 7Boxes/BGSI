-- Edit line 115 to change claw difficulty
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local network = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote")

local targetPosition = Vector3.new(9828.36, 34.59, 171.16)

local function tweenToPosition(position, duration)
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut
    )
    
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = CFrame.new(position)})
    tween:Play()
    tween.Completed:Wait()
end

local function callRemote(remoteType, remoteName, args)
    local success, result = pcall(function()
        local remote = network:WaitForChild(remoteType)
        if remoteType == "Function" then
            return remote:InvokeServer(unpack(args))
        else
            remote:FireServer(unpack(args))
            return true
        end
    end)
    
    if not success then
        warn("Failed to call", remoteName, ":", result)
        return false
    end
    return result
end

local function getCurrentClawItems()
    local clawItems = {}
    local success, screenGui = pcall(function()
        return localPlayer.PlayerGui:WaitForChild("ScreenGui", 5)
    end)
    
    if success and screenGui then
        for _, child in pairs(screenGui:GetDescendants()) do
            if child.Name:sub(1, 8) == "ClawItem" then
                table.insert(clawItems, child.Name)
            end
        end
    end
    return clawItems
end

local function collectAllItems()
    local attempts = 0
    local maxAttempts = 20  -- Prevent infinite loops
    local itemsCollected = 0
    
    repeat
        local clawItems = getCurrentClawItems()
        if #clawItems > 0 then
            print("Found", #clawItems, "items to collect")
            
            for _, itemId in ipairs(clawItems) do
                print("Grabbing:", itemId)
                callRemote("Event", "GrabMinigameItem", {"GrabMinigameItem", itemId})
                itemsCollected = itemsCollected + 1
                wait(0.2)  
            end
            
            wait(0.5)
        else
            break
        end
        
        attempts = attempts + 1
    until #getCurrentClawItems() == 0 or attempts >= maxAttempts
    
    print("Collection complete. Total items grabbed:", itemsCollected)
    return itemsCollected > 0
end

local function executeAutomation()
    tweenToPosition(targetPosition, 1)
    wait(10)
    
    coroutine.wrap(function()
        while true do
            for i = 1, 10 do
                callRemote("Function", "ClaimPlaytime", {"ClaimPlaytime", i})
                wait(1)
            end
        end
    end)()
    
    coroutine.wrap(function()
        while true do
            callRemote("Event", "HatchEgg", {"HatchEgg", "Game Egg", 4})
            wait(1)
        end
    end)()
    
    while true do
        callRemote("Event", "WorldTeleport", {"WorldTeleport", "Minigame Paradise"})
        wait(1)
        
        callRemote("Event", "SkipMinigameCooldown", {"SkipMinigameCooldown", "Robot Claw"})
        wait(1)
        
        callRemote("Event", "StartMinigame", {"StartMinigame", "Robot Claw", "Insane"})
        wait(1)
        
        collectAllItems()
        
        callRemote("Event", "FinishMinigame", {"FinishMinigame"})
        wait(5)  -- Cooldown between cycles
    end
end

localPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    executeAutomation()
end)

if character then
    executeAutomation()
end
