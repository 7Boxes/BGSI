local args = {"ClaimSeason"}
local remote = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
    :WaitForChild("Framework"):WaitForChild("Network")
    :WaitForChild("Remote"):WaitForChild("RemoteEvent")

while true do
    remote:FireServer(unpack(args))
    wait(0.5)
end
