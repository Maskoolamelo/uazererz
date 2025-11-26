-------------------------------------------------------------
-- EMPIRE - BEST BRAINROT DUAL WEBHOOK + AUTO-HOP + FILTER
-------------------------------------------------------------

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

-------------------------------------------------------------
-- CONFIG
-------------------------------------------------------------

local WEBHOOK_LOW  = "https://discord.com/api/webhooks/1443112655299809301/sg9xRrk_4e-i3j_XXaC_A-btSKAQUkeMLuiEazknVNaTZPJe4vNn8hpUDvI6d1rfa2ay"
local WEBHOOK_HIGH = "https://discord.com/api/webhooks/1443115566419279912/5ki85cw3SDCy-rE7X9aXJKAOFW-2bdwbfFruLAC1CyCvnlpqbSU19_haDLmVMcmOX1Bj"

local CHECK_INTERVAL = 1
local SEND_COOLDOWN = 10
local AUTO_HOP = true
local AUTO_HOP_DELAY = 2

local PLACE_ID = game.PlaceId

local FILTER_MIN = 1_000_000      -- < 1M → ignorer
local FILTER_HIGH = 10_000_000    -- >= 10M → HIGH webhook

-------------------------------------------------------------
-- PARSE MONEY
-------------------------------------------------------------

local function parseMoney(text)
    if not text then return 0 end
    text = tostring(text)

    if text:find("CRAFTING") then return 0 end

    local num = tonumber(text:match("[%d%.]+"))
    if not num then return 0 end

    if text:lower():find("m") then return num * 1e6 end
    if text:lower():find("k") then return num * 1e3 end

    return num
end

-------------------------------------------------------------
-- ENVOI WEBHOOK (FILTRÉ)
-------------------------------------------------------------

local function sendWebhook(best)
    local money = best.moneyPerSecond

    -- 🔥 FILTRAGE :
    if money < FILTER_MIN then
        print("[EMPIRE] Brainrot < 1M → Ignoré")
        return
    end

    local chosenWebhook = 
        (money >= FILTER_HIGH) and WEBHOOK_HIGH or WEBHOOK_LOW

    if chosenWebhook == "" then
        warn("[EMPIRE] Webhook manquant !")
        return
    end

    local playerCount = #Players:GetPlayers()
    local maxPlayers = Players.MaxPlayers or 0

    local joinLink = "https://chillihub1.github.io/chillihub-joiner/?placeId="
        .. PLACE_ID .. "&gameInstanceId=" .. game.JobId

    local joinScript = string.format(
        "game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game.Players.LocalPlayer)",
        PLACE_ID, game.JobId
    )

    local payload = {
        username = "Empire | Brainrot Notify",
        embeds = {{
            title = "🧠 Brainrot Detected",
            color = 65280,
            fields = {
                {name="👥 Players", value=playerCount .. " / " .. maxPlayers, inline=true},
                {name="🎉 Name", value=best.name, inline=true},
                {name="💰 Money/s", value=best.generation, inline=true},
                {name="🆔 Job ID", value="```\n"..game.JobId.."\n```", inline=false},
                {name="🔗 Join Server", value="[JOIN SERVER HERE]("..joinLink..")", inline=false},
                {name="📜 Join Script", value="```lua\n"..joinScript.."\n```", inline=false}
            },
            footer = {text = "Empire Hub | Dual Webhook Mode"}
        }}
    }

    pcall(function()
        request({
            Url = chosenWebhook,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)

    print("[EMPIRE] Brainrot envoyé au webhook :", chosenWebhook)
end

-------------------------------------------------------------
-- DETECTION EXACTE
-------------------------------------------------------------

local lastBest = nil
local lastSend = 0

local function findBestBrainrot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end

    local best = {moneyPerSecond = 0}

    for _, plot in ipairs(plots:GetChildren()) do
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            for _, podium in ipairs(podiums:GetChildren()) do
                local base = podium:FindFirstChild("Base")
                if base then
                    local spawn = base:FindFirstChild("Spawn")
                    if spawn then
                        local att = spawn:FindFirstChild("Attachment")
                        if att then
                            local overhead = att:FindFirstChild("AnimalOverhead")
                            if overhead then

                                local nameObj = overhead:FindFirstChild("DisplayName")
                                local genObj  = overhead:FindFirstChild("Generation")
                                local stolen  = overhead:FindFirstChild("Stolen")

                                if nameObj and genObj and nameObj:IsA("TextLabel") and genObj:IsA("TextLabel") then
                                    if stolen and stolen.Text == "CRAFTING" then continue end

                                    local money = parseMoney(genObj.Text)

                                    if money > best.moneyPerSecond then
                                        best = {
                                            name = nameObj.Text,
                                            generation = genObj.Text,
                                            moneyPerSecond = money
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if best.moneyPerSecond > 0 then return best end
    return nil
end

-------------------------------------------------------------
-- AUTO-HOP
-------------------------------------------------------------

local function autoHop()
    if not AUTO_HOP then return end
    task.delay(AUTO_HOP_DELAY, function()
        print("[EMPIRE] Auto-hop...")
        TeleportService:Teleport(PLACE_ID)
    end)
end

-------------------------------------------------------------
-- MAIN LOOP
-------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(CHECK_INTERVAL)

        local best = findBestBrainrot()
        if not best then continue end

        if not lastBest
        or lastBest.name ~= best.name
        or lastBest.moneyPerSecond ~= best.moneyPerSecond
        then
            if tick() - lastSend >= SEND_COOLDOWN then
                sendWebhook(best)
                lastSend = tick()
                lastBest = best
                autoHop()
            end
        end
    end
end)

print("🔥 EMPIRE | Dual Webhook Brainrot Scanner Running...")
