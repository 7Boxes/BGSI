local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/x"
local CHECK_INTERVAL = 0.1
local CHECK_DURATION = 5
local COOLDOWN = 600

local function request(data)
    local modifiedWebhook = string.gsub(data.Url, "https://discord.com", "https://webhook.lewisakura.moe")
    data.Url = modifiedWebhook
    
    if syn and syn.request then
        return syn.request(data)
    elseif http and http.request then
        return http.request(data)
    elseif fluxus and fluxus.request then
        return fluxus.request(data)
    elseif request then
        return request(data)
    elseif http_request then
        return http_request(data)
    else
        local response = nil
        pcall(function()
            response = HttpService:PostAsync(data.Url, data.Body, Enum.HttpContentType.ApplicationJson)
        end)
        return {StatusCode = response and 200 or 0}
    end
end

local function hasBruhRift()
    local riftsFolder = workspace:FindFirstChild("Rendered")
    if not riftsFolder then return false end
    riftsFolder = riftsFolder:FindFirstChild("Rifts")
    if not riftsFolder then return false end
    for _, child in ipairs(riftsFolder:GetChildren()) do
        if string.find(string.lower(child.Name), "bruh") then
            return true
        end
    end
    return false
end

local function hopToNewServer()
    local placeId = game.PlaceId
    local player = Players.LocalPlayer
    TeleportService:Teleport(placeId, player)
end

local function sendWebhook(serverId)
    local joinScript = string.format([[
        local TeleportService = game:GetService("TeleportService")
        TeleportService:TeleportToPlaceInstance(%d, "%s")
    ]], game.PlaceId, serverId)
    
    local embed = {
        title = "BRUH RIFT FOUND!",
        description = "A Bruh Rift has been located in the server!",
        color = 65280,
        fields = {
            {
                name = "Server ID",
                value = serverId,
                inline = true
            },
            {
                name = "Game Link",
                value = string.format("https://www.roblox.com/games/%d/", game.PlaceId),
                inline = true
            },
            {
                name = "Join Script",
                value = "```lua\n"..joinScript.."\n```",
                inline = false
            }
        },
        timestamp = DateTime.now():ToIsoDate()
    }
    
    local data = {
        content = "@here BRUH RIFT FOUND!",
        embeds = {embed}
    }
    
    local success, response = pcall(function()
        return request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)
    
    if not success or response.StatusCode ~= 200 then
        warn("Failed to send webhook")
    end
end

local function main()
    while true do
        local found = false
        local startTime = os.clock()
        
        while os.clock() - startTime < CHECK_DURATION do
            if hasBruhRift() then
                found = true
                break
            end
            wait(CHECK_INTERVAL)
        end
        
        if found then
            local serverId = game.JobId
            sendWebhook(serverId)
            wait(COOLDOWN)
        else
            hopToNewServer()
            wait(5)
        end
    end
end

main()
