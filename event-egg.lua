local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid
while not humanoid do
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Humanoid") then
            humanoid = child
            break
        end
    end
    task.wait()
end

local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- CONFIG SECTION
local config = {
    TargetPosition = Vector3.new(16.95, 16.27, -7.35),
    RemoteValue = 4,
    MovementSpeed = 0.7,
    PlatformName = "Terrain_"..math.random(1000,9999),
    PlatformSize = Vector3.new(12, 1.2, 12),
    CheckInterval = 0.016
}

-- Sell bubbles then walk to event egg
local function stealthMoveToPosition()
    local startTime = os.clock()
    local maxDuration = 30 -- Maximum time to attempt movement
    
    local function physicsMove()
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        humanoid.WalkSpeed = 0
        
        local connection
        connection = RunService.Heartbeat:Connect(function(delta)
            if os.clock() - startTime > maxDuration then
                connection:Disconnect()
                return false
            end
            
            local currentPos = humanoidRootPart.Position
            local remaining = (config.TargetPosition - currentPos).Magnitude
            
            if remaining < 2 then
                connection:Disconnect()
                humanoid.WalkSpeed = 16
                return true
            end
            
            local moveDir = (config.TargetPosition - currentPos).Unit
            local randomizedForce = moveDir * (humanoidRootPart.AssemblyMass * 45 * config.MovementSpeed)
            humanoidRootPart:ApplyImpulse(randomizedForce * delta * 60)
        end)
    end

    local function waypointMove()
        local path = humanoid:FindFirstChildOfClass("Path") or Instance.new("Path")
        path.Waypoints = {
            Vector3.new(humanoidRootPart.Position.X, humanoidRootPart.Position.Y, humanoidRootPart.Position.Z),
            config.TargetPosition
        }
        path.Parent = humanoid
        humanoid:MoveTo(config.TargetPosition)
    end

    if physicsMove() then return true end
    
    waypointMove()
    return true
end

-- Attempt to recreate bubble selling platform below the player
local function createStealthPlatform()

    local terrain = workspace:FindFirstChildOfClass("Terrain")
    local baseplate = workspace:FindFirstChild("Baseplate")
    
    local platform = Instance.new("Part")
    platform.Name = config.PlatformName
    platform.Size = config.PlatformSize
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 0.9
    platform.Color = terrain and terrain.Color or Color3.fromRGB(80, 80, 80)
    platform.Material = terrain and terrain.Material or Enum.Material.Concrete
    
    local rootPos = humanoidRootPart.Position
    local humanoidHeight = character:GetExtentsSize().Y
    platform.Position = Vector3.new(
        rootPos.X,
        rootPos.Y - (humanoidHeight/2) - (platform.Size.Y/2) + 0.5,
        rootPos.Z
    )
    
    local surfaceGui = Instance.new("SurfaceGui", platform)
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.AlwaysOnTop = true
    
    local frame = Instance.new("Frame", surfaceGui)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.95
    
    local script = Instance.new("Script", platform)
    script.Name = "TouchHandler"
    script.Source = [[
        local debounce = false
        local remotePath = game:GetService("ReplicatedStorage")
            :WaitForChild("Shared")
            :WaitForChild("Framework")
            :WaitForChild("Network")
            :WaitForChild("Remote")
            :WaitForChild("RemoteEvent")
        
        script.Parent.Touched:Connect(function(hit)
            if debounce then return end
            debounce = true
            
            local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                task.wait(math.random(0.1, 0.5))
                remotePath:FireServer(]]..config.RemoteValue..[[)
            end
            
            debounce = false
        end)
    ]]
    
    platform.Parent = workspace
    return true
end

task.spawn(function()
    task.wait(math.random(1, 3)) -- Initial delay
    
    if stealthMoveToPosition() then
        task.wait(math.random(0.5, 1.5))
        
        if createStealthPlatform() then
            task.wait(math.random(1, 2))
            
            local success, remote = pcall(function()
                return ReplicatedStorage:WaitForChild("Shared")
                    :WaitForChild("Framework")
                    :WaitForChild("Network")
                    :WaitForChild("Remote")
                    :WaitForChild("RemoteEvent")
            end)
            
            if success and remote then
                task.wait(math.random(0.2, 0.8))
                remote:FireServer(config.RemoteValue)
            end
        end
    end
end)

local function cleanUp()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == config.PlatformName then
            obj:Destroy()
        end
    end
end

game:GetService("UserInputService").WindowFocusReleased:Connect(cleanUp)
Players.PlayerRemoving:Connect(function(p) if p == player then cleanUp() end end)
