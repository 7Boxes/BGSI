local itemNumber = 1  -- Change this to the item number you want

local remotePath = game:GetService("ReplicatedStorage")
    :WaitForChild("Shared")
    :WaitForChild("Framework")
    :WaitForChild("Network")
    :WaitForChild("Remote")
    :WaitForChild("RemoteEvent")

while true do
    remotePath:FireServer("DailyRewardsBuyItem", itemNumber)
    task.wait(0.1)  -- Adjust delay (in seconds) if needed
end
