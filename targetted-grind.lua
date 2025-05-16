getgenv().EggConfig = {
    EggName = "Infinity Egg",  -- Change to desired egg (e.g., "Common Egg", "Rainbow Egg")
    HatchQuantity = 4,         -- Number of eggs to hatch at once
    BubbleBreakInterval = 300, -- Seconds between bubble selling breaks (300 = 5 minutes)
    HatchRate = 0.1,           -- Delay between hatch attempts
    FloatHeight = 5            -- Floating height above ground
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/7Boxes/BGSI/refs/heads/main/basic-obf.lua"))()
