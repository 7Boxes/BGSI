getgenv().QuestSettings = {
    BubbleRate = 0.1,          -- How often to blow bubbles (seconds)
    HatchRate = 0.1,           -- How often to hatch eggs (seconds)
    HatchQuantity = 4,         -- Number of eggs to hatch at once
    FloatHeight = 5,           -- How high to float above ground (studs)
    WalkSpeed = 16,            -- Movement speed when floating
    TweenDuration = 10,        -- Time to tween between locations (seconds)
    CheckInterval = 5,         -- How often to check quest progress (seconds)
    PostCompletionWait = 5,    -- Wait after completing a quest type (seconds)
    CollectionWaitTime = 5     -- Wait time between collection attempts (seconds)
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/autoseasonquest.lua"))()
