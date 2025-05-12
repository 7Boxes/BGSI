local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotePath = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework")
    :WaitForChild("Network")
    :WaitForChild("Remote")
    :WaitForChild("RemoteEvent")

local chests = {
    {"ClaimChest", "Giant Chest", true},
    {"ClaimChest", "Ticket Chest", true},
    {"ClaimChest", "Infinity Chest", true},
    {"ClaimChest", "Void Chest", true}
}

local delayBetweenChests = 0.5 -- seconds

while true do
    for _, args in ipairs(chests) do
        remotePath:FireServer(unpack(args))
        wait(delayBetweenChests)
    end
end
