local args = {
    "UseGift",
    "Mystery Box",
    10
}

local function clickAtCenter(times, interval)
    for i = 1, times do
        local screenCenter = Vector2.new(game:GetService("GuiService"):GetScreenResolution().X / 2, 
                              game:GetService("GuiService"):GetScreenResolution().Y / 2)
        
        mousemoverel(screenCenter.X, screenCenter.Y)
        
        mouse1click()
        
        wait(interval)
    end
end

while true do
    game:GetService("ReplicatedStorage"):WaitForChild("Shared")
        :WaitForChild("Framework"):WaitForChild("Network")
        :WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
    
    wait(5)
    
    clickAtCenter(10, 0.2)
    
    wait(1)
    
end
