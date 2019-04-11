local Sync   = {}
local Server = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common

local Tile = require(Common.Tile)
local Unit = require(Common.Unit)

local HttpService = game:GetService("HttpService")

local SYNC_RATE = 1 --1 sync request a second to backend
local API_URL = "http://0.0.0.0:3000/pion/"
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
        local units = HttpService:GetAsync(API_URL.."allunits")
    
        tiles = HttpService:JSONDecode(tiles)
        units = HttpService:JSONDecode(units)
    
        for i, tile in pairs(tiles) do
            world.Tiles[i] = Tile.deserialise(i, tile)
            Replication.pushTileChange(world.Tiles[i])
        end
    
        for i, unit in pairs(units) do
            world.Units[i] = Unit.deserialise(i, unit, world.Tiles)
            Replication.tempSyncUnit(world.Units[i])
        end

        wait(SYNC_RATE)
    end
end

function Sync.begin(world)
    syncing = true

    globalSync(world)
    delay(2, function() syncprocess(world) end)
end

return Sync