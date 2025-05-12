getgenv().autoPressR = true

local VirtualInputManager = game:GetService("VirtualInputManager")

task.spawn(function()
    while getgenv().autoPressR do
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        task.wait()
    end
end)
