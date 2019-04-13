local Sync   = {}
local Server = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common

local StatsController = require(Server.StatsController)
local Tile = require(Common.Tile)
local Unit = require(Common.Unit)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local SYNC_RATE = 0.5 --2 sync request a second to backend
local CLIENT_SYNC_RATE = 2 --sync clients every 2 seconds
local API_URL = "https://api.mysty.dev/pion/"
local syncing

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
    local Replication = require(Server.Replication)

    while syncing do
        
        local tiles = HttpService:GetAsync(API_URL.."alltiles")
        --local units = HttpService:GetAsync(API_URL.."allunits")
    
        tiles = HttpService:JSONDecode(tiles)
        --units = HttpService:JSONDecode(units)
    
        for i, tile in pairs(tiles) do
            world.Tiles[i] = Tile.deserialise(i, tile)
            Replication.pushTileChange(world.Tiles[i])
        end
    
        --for i, unit in pairs(units) do
        --    world.Units[i] = Unit.deserialise(i, unit, world.Tiles)
        --end

        wait(SYNC_RATE)
    end
end

local syncTime = 0

local function tempSyncAll(world)
    local Replication = require(Server.Replication)
    while syncing do
        print("Polling...")
        local payload = HttpService:PostAsync(API_URL.."longpollunit", HttpService:JSONEncode({time = syncTime}))
        payload = HttpService:JSONDecode(payload)
        syncTime = payload.time
        units = payload.data

        for i, unit in pairs(units) do
            world.Units[i] = Unit.deserialise(i, unit, world.Tiles)
            Replication.tempSyncUnit(world.Units[i])
        end
        wait()
    end
end

function Sync.begin(world)
    syncing = true

    globalSync(world)
    delay(2, function() syncprocess(world) end)
    delay(2, function() tempSyncAll(world) end)
end

local function playerJoined(player)
    local jsonStats = HttpService:PostAsync(API_URL.."userjoin", HttpService:JSONEncode({Id=player.userId}))
    local stats = HttpService:JSONDecode(jsonStats)
    StatsController.addNewPlayer(player, stats)
end

Players.PlayerAdded:Connect(playerJoined)

return Sync