local Sync   = {}
local Server = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common

local Replication = require(Server.Replication)
local Tile        = require(Common.Tile)
local Unit        = require(Common.Unit)
local UserStats   = require(Common.UserStats)

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local SYNC_RATE = 1
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
        local index = tostring(i)
        world.Units[index] = Unit.deserialise(index, unit, world.Tiles)
        n = n + 1
    end

    print("Loaded", n, "units")
end

local function syncprocess(world)

    while syncing do
        
        local tiles = HttpService:GetAsync(API_URL.."alltiles")
        tiles = HttpService:JSONDecode(tiles)
        
        local t = tick()

        for i, tile in pairs(tiles) do
            local stile = world.Tiles[i]

            world.Tiles[i] = Tile.deserialise(i, tile)
            Replication.pushTileChange(world.Tiles[i])
        end

        for i, tile in pairs(world.Tiles) do
            if not tiles[i] and tile.Type ~= Tile.GRASS then
                print("Removing deleted tile")
                world.Tiles[i] = nil
                Replication.pushTileChange(Tile.defaultGrass(i))
            end
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
            local index = tostring(i)

            world.Units[index] = Unit.deserialise(index, unit, world.Tiles)
            Replication.tempSyncUnit(world.Units[index])
        end

        wait(SYNC_RATE + math.random()) --Slightly spread out load on http api
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

        wait(SYNC_RATE + math.random())
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

    globalSync(world)
    delay(2, function() protectedCall(syncprocess, world) end)
    delay(0, function() protectedCall(tempSyncAll, world) end)
end

local function playerJoined(player)
    local jsonStats = HttpService:PostAsync(API_URL.."userjoin", HttpService:JSONEncode({Id=player.userId}))
    local stats = HttpService:JSONDecode(jsonStats)

    if stats.status and stats.status == "NewUser" then
        UserStats.Store[player.UserId] = {Food = 0, Wood = 0, Stone = 0, 
                                        MFood = 0, MWood = 0, MStone = 0, 
                                        PFood = 0, PWood = 0, PStone = 0}
    else
        UserStats.Store[player.UserId] = stats
    end

    delay(2, function() protectedCall(syncStats, player, currentWorld) end)
end

Players.PlayerAdded:Connect(function(p) pcall(playerJoined, p) end)

for _, player in pairs(Players:GetChildren()) do
    pcall(playerJoined, player)
end


return Sync