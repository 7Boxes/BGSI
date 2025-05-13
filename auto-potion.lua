local enabledPotions = {
    ["Lucky"] = true,
    ["Mythic"] = true,
    ["Infinity Elixir"] = false, -- don't need this with auto board game
    ["Speed"] = true
}

local function usePotion(potionName, duration, amount)
    local args = {
        "UsePotion",
        potionName,
        duration,
        amount
    }

    game:GetService("ReplicatedStorage")
        :WaitForChild("Shared")
        :WaitForChild("Framework")
        :WaitForChild("Network")
        :WaitForChild("Remote")
        :WaitForChild("RemoteEvent")
        :FireServer(unpack(args))
end

while true do
    if enabledPotions["Lucky"] then
        usePotion("Lucky", 6, 10)
    end
    if enabledPotions["Mythic"] then
        usePotion("Mythic", 6, 10)
    end
    if enabledPotions["Infinity Elixir"] then
        usePotion("Infinity Elixir", 1, 10)
    end
    if enabledPotions["Speed"] then
        usePotion("Speed", 6, 10)
    end

    wait(3600)
end
