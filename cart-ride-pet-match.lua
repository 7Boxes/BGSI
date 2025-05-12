print("[DEBUG] Waiting 5 seconds before starting the loop...")
wait(5)

while true do
    print("[DEBUG] Starting Cart Escape minigame...")
    local startArgs = {
        "StartMinigame",
        "Cart Escape",
        "Insane"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Shared")
        :WaitForChild("Framework"):WaitForChild("Network")
        :WaitForChild("Remote"):WaitForChild("Event"):FireServer(unpack(startArgs))
    
    wait(1)
    
    print("[DEBUG] Finishing Cart Escape minigame...")
    local finishArgs = {
        "FinishMinigame"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Shared")
        :WaitForChild("Framework"):WaitForChild("Network")
        :WaitForChild("Remote"):WaitForChild("Event"):FireServer(unpack(finishArgs))
    
    print("[DEBUG] Waiting 2 seconds before next minigame...")
    wait(2)
    
    print("[DEBUG] Starting Pet Match minigame...")
    local startArgs2 = {
        "StartMinigame",
        "Pet Match",
        "Insane"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Shared")
        :WaitForChild("Framework"):WaitForChild("Network")
        :WaitForChild("Remote"):WaitForChild("Event"):FireServer(unpack(startArgs2))
    
    wait(1)
    
    print("[DEBUG] Finishing Pet Match minigame...")
    local finishArgs2 = {
        "FinishMinigame"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Shared")
        :WaitForChild("Framework"):WaitForChild("Network")
        :WaitForChild("Remote"):WaitForChild("Event"):FireServer(unpack(finishArgs2))
    
    print("[DEBUG] Waiting 2 seconds before restarting loop...")
    wait(2)
end
