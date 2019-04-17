local Sync   = {}
local Server = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common

local Replication = require(Server.Replication)
local Tile        = require(Common.Tile)
local Unit        = require(Common.Unit)
local UserStats   = require(Common.UserStats)

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local SYNC_RATE = 0.5 --2 sync request a second to backend
local API_URL = "https://api.mysty.dev/pion/"
local syncing, currentWorld

local function globalSync(world)
    print("Requesting world data")

    local tiles = HttpService:GetAsync(API_URL.."alltiles")
    local units = HttpService:GetAsync(API_URL.."allunits")

    tiles = HttpService:JSONDecode(tiles)
    units = HttpService:JSONDecode(units)

    local n = 0

    for i, tile in pairs(tiles) do
        world.Tiles[i] = Tile.deserialise(i, tile)
        n = n + 1
    end

    print("Loaded", n, "tiles")
    n = 0

    for i, unit in pairs(units) do
        world.Units[i] = Unit.deserialise(i, unit, world.Tiles)
        n = n + 1
    end

    print("Loaded", n, "units")
end

local function syncprocess(world)

    while syncing do
        
        local tiles = HttpService:GetAsync(API_URL.."alltiles")
        tiles = HttpService:JSONDecode(tiles)
    
        for i, tile in pairs(tiles) do
            world.Tiles[i] = Tile.deserialise(i, tile)
            Replication.pushTileChange(world.Tiles[i])
        end

        wait(SYNC_RATE)
    end
end



local function tempSyncAll(world)

    local syncTime = 0

    while syncing do
        
        local payload = HttpService:JSONEncode({time = syncTime})
        local res = HttpService:JSONDecode(HttpService:PostAsync(API_URL.."longpollunit", payload))

        syncTime = res.time

        for i, unit in pairs(res.data) do
            world.Units[i] = Unit.deserialise(i, unit, world.Tiles)
            Replication.tempSyncUnit(world.Units[i])
        end

        wait(math.random()) --Slightly spread out load on http api
    end
end

local function syncStats(player, world)

    local syncTime = 0

    while syncing and player do

        local payload = HttpService:JSONEncode({time = syncTime, userId = player.UserId})
        local res = HttpService:JSONDecode(HttpService:PostAsync(API_URL.."longpolluserstats", payload))

        syncTime = res.time
        UserStats.Store[player.UserId] = HttpService:JSONDecode(res.data)
        Replication.pushStatsChange(UserStats.Store[player.UserId])

        wait(math.random())
    end
end

function Sync.begin(world)
    syncing = true
    currentWorld = world

    globalSync(world)
    delay(2, function() syncprocess(world) end)
    delay(2, function() tempSyncAll(world) end)
end

local function playerJoined(player)
    local jsonStats = HttpService:PostAsync(API_URL.."userjoin", HttpService:JSONEncode({Id=player.userId}))
    UserStats.Store[player.UserId] = HttpService:JSONDecode(jsonStats)

    delay(2, function() syncStats(player, currentWorld) end)
end

Players.PlayerAdded:Connect(playerJoined)

return Sync