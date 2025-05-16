local Config = getgenv().FPSBoosterConfig or {
    Players = {
        IgnoreMe = false,
        IgnoreOthers = false,
        IgnoreTools = false
    },
    Graphics = {
        FPSCap = 120, -- set to false for no cap
        NoShadows = true,
        NoCameraEffects = true,
        NoClothes = true,
        LowWater = true,
        LowRendering = true,
        LowQualityParts = true,
        ResetMaterials = true
    },
    Optimization = {
        NoMeshes = true,
        NoTextures = true,
        NoParticles = true,
        NoExplosions = true,
        NoTextLabels = false,
        DestroyMeshes = false,
        DestroyImages = false,
        DestroyParticles = false
    }
}

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local function applyGraphicsSettings()
    -- FPS Cap
    if Config.Graphics.FPSCap then
        if type(Config.Graphics.FPSCap) == "number" then
            setfpscap(Config.Graphics.FPSCap)
        else
            setfpscap(9999)
        end
    end

    -- Lighting
    if Config.Graphics.NoShadows then
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
        Lighting.FogEnd = 9e9
        sethiddenproperty(Lighting, "Technology", "Compatibility")
    end

    -- Rendering
    if Config.Graphics.LowRendering then
        settings().Rendering.QualityLevel = 1
    end

    -- Water
    if Config.Graphics.LowWater then
        for _, v in next, getgc() do
            if typeof(v) == "table" and rawget(v, "WaterTransparency") then
                v.WaterTransparency = 1
                v.WaterReflectance = 0
                v.WaterWaveSize = 0
                v.WaterWaveSpeed = 0
            end
        end
    end

    -- Camera
    if Config.Graphics.NoCameraEffects and workspace.CurrentCamera then
        workspace.CurrentCamera:ClearAllChildren()
    end

    -- Materials
    if Config.Graphics.ResetMaterials then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            end
        end
    end

    -- Parts
    if Config.Graphics.LowQualityParts then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CastShadow = false
            end
        end
    end

    -- Player Character
    if Config.Players.IgnoreMe and localPlayer.Character then
        for _, v in ipairs(localPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.LocalTransparencyModifier = 1
            end
        end
    end

    -- Clothing
    if Config.Graphics.NoClothes and localPlayer.Character then
        for _, v in ipairs(localPlayer.Character:GetDescendants()) do
            if v:IsA("Clothing") or v:IsA("Accessory") then
                v:Destroy()
            end
        end
    end
end

local function optimizeObjects()
    for _, v in ipairs(workspace:GetDescendants()) do
        -- Meshes
        if Config.Optimization.NoMeshes then
            if v:IsA("MeshPart") then
                v.MeshId = ""
            elseif v:IsA("SpecialMesh") then
                v.MeshId = ""
            end
        end

        -- Textures
        if Config.Optimization.NoTextures then
            if v:IsA("MeshPart") then
                v.TextureID = ""
            elseif v:IsA("SpecialMesh") or v:IsA("Decal") then
                v.TextureId = ""
            end
        end

        -- Visibility
        if (v:IsA("ParticleEmitter") and Config.Optimization.NoParticles then
            v.Enabled = not Config.Optimization.NoParticles
        elseif (v:IsA("Explosion")) and Config.Optimization.NoExplosions then
            v.Enabled = not Config.Optimization.NoExplosions
        elseif (v:IsA("TextLabel")) and Config.Optimization.NoTextLabels then
            v.Enabled = not Config.Optimization.NoTextLabels
        end

        -- Destruction
        if Config.Optimization.DestroyMeshes and (v:IsA("SpecialMesh") or v:IsA("MeshPart")) then
            v:Destroy()
        elseif Config.Optimization.DestroyImages and v:IsA("Decal") then
            v:Destroy()
        elseif Config.Optimization.DestroyParticles and v:IsA("ParticleEmitter") then
            v:Destroy()
        end
    end
end

local function onDescendantAdded(descendant)
    -- Other Players
    if Config.Players.IgnoreOthers and descendant:IsA("BasePart") then
        local model = descendant:FindFirstAncestorOfClass("Model")
        if model and model:FindFirstChildOfClass("Humanoid") and model ~= localPlayer.Character then
            descendant.LocalTransparencyModifier = 1
        end
    end

    -- Tools
    if Config.Players.IgnoreTools and descendant:IsA("Tool") then
        descendant.Handle.LocalTransparencyModifier = 1
    end

    -- Optimization
    optimizeObjects()
end

-- Initialize
workspace.DescendantAdded:Connect(onDescendantAdded)

if localPlayer.Character then
    for _, v in ipairs(localPlayer.Character:GetDescendants()) do
        onDescendantAdded(v)
    end
end

localPlayer.CharacterAdded:Connect(function(character)
    for _, v in ipairs(character:GetDescendants()) do
        onDescendantAdded(v)
    end
    character.DescendantAdded:Connect(onDescendantAdded)
end)

applyGraphicsSettings()
optimizeObjects()

print("JMX FPS Booster activated successfully!")
