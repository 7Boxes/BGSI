local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- Configurations
_G.Ignore = {}
_G.Settings = {
    Players = {
        ["Ignore Me"] = false,
        ["Ignore Others"] = false,
        ["Ignore Tools"] = false
    },
    Meshes = {
        NoMesh = true,
        NoTexture = true,
        Destroy = false
    },
    Images = {
        Invisible = true,
        Destroy = false
    },
    Explosions = {
        Smaller = true,
        Invisible = true, 
        Destroy = false
    },
    Particles = {
        Invisible = true,
        Destroy = false
    },
    TextLabels = {
        LowerQuality = true,
        Invisible = false,
        Destroy = false
    },
    MeshParts = {
        LowerQuality = true,
        Invisible = false,
        NoTexture = false,
        NoMesh = true,
        Destroy = false
    },
    Other = {
        ["FPS Cap"] = 120, -- false to uncap
        ["No Camera Effects"] = true,
        ["No Clothes"] = true,
        ["Low Water Graphics"] = true,
        ["No Shadows"] = true,
        ["Low Rendering"] = true,
        ["Low Quality Parts"] = true,
        ["Low Quality Models"] = true,
        ["Reset Materials"] = true,
    }
}

local function applyFPSBooster()
    if _G.Settings.Other["FPS Cap"] then
        if type(_G.Settings.Other["FPS Cap"]) == "number" then
            setfpscap(_G.Settings.Other["FPS Cap"])
        else
            setfpscap(9999)
        end
    end

    if _G.Settings.Other["No Shadows"] then
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
        Lighting.FogEnd = 9e9
        sethiddenproperty(Lighting, "Technology", "Compatibility")
    end

    if _G.Settings.Other["Low Rendering"] then
        settings().Rendering.QualityLevel = 1
    end

    if _G.Settings.Other["Low Water Graphics"] then
        for _, v in next, getgc() do
            if typeof(v) == "table" and rawget(v, "WaterTransparency") then
                v.WaterTransparency = 1
                v.WaterReflectance = 0
                v.WaterWaveSize = 0
                v.WaterWaveSpeed = 0
            end
        end
    end

    if _G.Settings.Other["No Camera Effects"] then
        local camera = workspace.CurrentCamera
        camera:ClearAllChildren()
    end

    if _G.Settings.Other["Reset Materials"] then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            end
        end
    end

    if _G.Settings.Other["Low Quality Parts"] then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CastShadow = false
            end
        end
    end

    if _G.Settings.Players["Ignore Me"] and localPlayer.Character then
        for _, v in ipairs(localPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.LocalTransparencyModifier = 1
            end
        end
    end

    if _G.Settings.Other["No Clothes"] then
        if localPlayer.Character then
            for _, v in ipairs(localPlayer.Character:GetDescendants()) do
                if v:IsA("Clothing") or v:IsA("Accessory") then
                    v:Destroy()
                end
            end
        end
    end
end

local function optimizeMeshes()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("MeshPart") and _G.Settings.MeshParts.NoMesh then
            v.MeshId = ""
        elseif v:IsA("SpecialMesh") and _G.Settings.Meshes.NoMesh then
            v.MeshId = ""
        end
        
        if v:IsA("MeshPart") and _G.Settings.MeshParts.NoTexture then
            v.TextureID = ""
        elseif (v:IsA("SpecialMesh") and _G.Settings.Meshes.NoTexture) or (v:IsA("Decal") and _G.Settings.Images.Invisible) then
            v.TextureId = ""
        end
        
        if (v:IsA("ParticleEmitter") and _G.Settings.Particles.Invisible) or 
           (v:IsA("Explosion") and _G.Settings.Explosions.Invisible) or
           (v:IsA("TextLabel") and _G.Settings.TextLabels.Invisible) then
            v.Enabled = false
        end
    end
end

local function onDescendantAdded(descendant)
    if _G.Settings.Players["Ignore Others"] and descendant:IsA("BasePart") and descendant:FindFirstAncestorOfClass("Model") then
        local model = descendant:FindFirstAncestorOfClass("Model")
        if model and model:FindFirstChildOfClass("Humanoid") and model ~= localPlayer.Character then
            descendant.LocalTransparencyModifier = 1
        end
    end

    if _G.Settings.Players["Ignore Tools"] and descendant:IsA("Tool") then
        descendant.Handle.LocalTransparencyModifier = 1
    end

    if _G.Settings.Meshes.Destroy and (descendant:IsA("SpecialMesh") then
        descendant:Destroy()
    end

    if _G.Settings.Images.Destroy and (descendant:IsA("Decal")) then
        descendant:Destroy()
    end

    if _G.Settings.Particles.Destroy and (descendant:IsA("ParticleEmitter")) then
        descendant:Destroy()
    end

    if _G.Settings.TextLabels.Destroy and (descendant:IsA("TextLabel")) then
        descendant:Destroy()
    end

    if _G.Settings.MeshParts.Destroy and (descendant:IsA("MeshPart")) then
        descendant:Destroy()
    end
end

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

applyFPSBooster()
optimizeMeshes()

for _, v in ipairs(workspace:GetDescendants()) do
    onDescendantAdded(v)
end

print("FPS Booster loaded successfully!")
