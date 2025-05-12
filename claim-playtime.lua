local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework")
local Network = Framework:WaitForChild("Network")
local Remote = Network:WaitForChild("Remote")
local RemoteFunction = Remote:WaitForChild("RemoteFunction")

while true do
    for i = 1, 9 do
        local args = {
            "ClaimPlaytime",
            i
        }
        
        RemoteFunction:InvokeServer(unpack(args))
        wait(0.5)
    end
end
