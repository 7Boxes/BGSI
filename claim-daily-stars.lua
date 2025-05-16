local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotePath = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework")
    :WaitForChild("Network")
    :WaitForChild("Remote")
    :WaitForChild("RemoteEvent")

local args = {"DailyRewardClaimStars"}

while true do
    remotePath:FireServer(unpack(args))
    wait(1) 
end
