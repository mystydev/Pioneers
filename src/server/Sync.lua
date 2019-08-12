local Sync   = {}
local Server = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common

local Replication  = require(Server.Replication)
local Tile         = require(Common.Tile)
local Unit         = require(Common.Unit)
local UserStats    = require(Common.UserStats)
local UserSettings = require(Common.UserSettings)

local Players       = game:GetService("Players")
local Http          = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local SYNC_RATE = 0.5
local API_URL = "https://api.mysty.dev/pion/"
local API_KEY = ServerStorage.APIKey.Value
local syncing, currentWorld
local requestedTiles = Replication.getRequestedTiles()
local unitReferences = Replication.getUnitReferences()

local function syncStats(player, world)
    local syncTime = 0

    while syncing and player do

        local payload = Http:JSONEncode({apikey = API_KEY, time = syncTime, userId = player.UserId})
        local res = Http:JSONDecode(Http:PostAsync(API_URL.."longpolluserstats", payload))

        syncTime = res.time
        UserStats.Store[player.UserId] = Http:JSONDecode(res.data)
        Replication.pushStatsChange(UserStats.Store[player.UserId])

        wait(SYNC_RATE + math.random())
    end
end


local function syncUpdates()

    local syncTime = 0

    while syncing do 

        --Convert tile list to friendly format
        local tileList = {}
        for _, tiles in pairs(requestedTiles) do
            for tile, _ in pairs(tiles) do
                table.insert(tileList, tile)
            end
        end

        --Convert unit list to friendly format
        local unitList = {}
        for id, _ in pairs(unitReferences) do
            table.insert(unitList, id)
        end

        --Construct payload and send it to backend
        local payload = Http:JSONEncode({
            apikey = API_KEY,
            time = syncTime, 
            tiles = tileList, 
            units = unitList, 
            chats = Replication.getChats(),
            feedback = Replication.getFeedback(),
        })
        local res = Http:JSONDecode(Http:PostAsync(API_URL.."syncupdates", payload))
        syncTime = tonumber(res.lastUpdate)

        --Sync tiles/units
        Replication.handleTileInfo(res.tiles or {})
        Replication.handleUnitInfo(res.units or {})
        Replication.handleChats(res.chats or {})

        --If the lastupdate was issued earlier than the last deploy then the backend is updating
        if tonumber(res.lastUpdate) > tonumber(res.lastDeploy) then --TODO: remove these tonumbers
            Replication.pushUpdateAlert(true)
        elseif tonumber(res.lastDeploy) < res.lastProcess then
            Replication.pushUpdateAlert(false)
        end

        --Ease load on backend slightly, just in case
        wait(SYNC_RATE)
    end
end

local function protectedCall(f, ...)
    pcall(f, ...)
    wait(1)
    protectedCall(f, ...)
end

function Sync.begin(world)
    syncing = true
    currentWorld = world

    --globalSync(world)
    --delay(2, function() protectedCall(syncprocess, world) end)
    --delay(0, function() protectedCall(tempSyncAll, world) end)
    delay(0, function() protectedCall(syncUpdates, world) end)
end

local function playerJoined(player)
    local jsonStats = Http:PostAsync(API_URL.."userjoin", Http:JSONEncode({apikey = API_KEY, Id=player.userId}))
    local stats = Http:JSONDecode(jsonStats)

    if stats.status and stats.status == "NewUser" then
        UserStats.Store[player.UserId] = {Food = 0, Wood = 0, Stone = 0, 
                                        MFood = 0, MWood = 0, MStone = 0, 
                                        PFood = 0, PWood = 0, PStone = 0}
    else
        UserStats.Store[player.UserId] = stats
    end

    delay(2, function() protectedCall(syncStats, player, currentWorld) end)
end

local function loadPlayerSettings(player)
    local requestUrl = API_URL.."getusersettings"
    local payload = Http:JSONEncode({apikey = API_KEY, Id=player.userId})
    local settings = Http:PostAsync(requestUrl, payload)
    UserSettings.parseJSON(player, settings)
end 

Players.PlayerAdded:Connect(function(p) pcall(playerJoined, p) end)
Players.PlayerAdded:Connect(function(player) loadPlayerSettings(player) end)

for _, player in pairs(Players:GetChildren()) do
    pcall(playerJoined, player)
    loadPlayerSettings(player)
end


return Sync