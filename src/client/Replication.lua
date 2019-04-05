local Replication = {}

local Client = script.Parent
local ViewUnit = require(Client.ViewUnit)
local ViewStats = require(Client.ViewStats)
local ViewTile = require(Client.ViewTile)
local Network = game.ReplicatedStorage.Network

local currentWorld
local currentStats

function Replication.getWorldState()
    print("Getting world state")
    currentWorld = Network.RequestWorldState:InvokeServer()
    return currentWorld
end

function Replication.getUserStats()
    currentStats = Network.RequestStats:InvokeServer()
    return currentStats
end

function Replication.requestTilePlacement(tile, type)

    local success = Network.RequestTilePlacement:InvokeServer(tile, type)

    if not success then
        print("Tile placement request failed!")
    end
end

local function handleUnitUpdate(unit)
    local localUnit = currentWorld.Units[unit.ID]
    
    for i, v in pairs(unit) do
        localUnit[i] = v
    end

    ViewUnit.updateDisplay(localUnit)
end

local function handleStatsUpdate(stats)
    for i, v in pairs(stats) do
        currentStats[i] = v
    end

    currentStats.changed()
end

local function handleTileUpdate(tile)

    local pos = tile.Position
    local localTile = currentWorld.Tiles[pos.x][pos.y] 

    for i, v in pairs(tile) do
        print(i, v)
        localTile[i] = v 
    end

    ViewTile.updateDisplay(localTile)
end

Network.UnitUpdate.OnClientEvent:Connect(handleUnitUpdate)
Network.StatsUpdate.OnClientEvent:Connect(handleStatsUpdate)
Network.TileUpdate.OnClientEvent:Connect(handleTileUpdate)

return Replication