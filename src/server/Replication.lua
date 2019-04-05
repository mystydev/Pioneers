local Replication = {}

local Network = game.ReplicatedStorage.Network
local Players = game:GetService("Players")

local currentWorld
local currentStats

function Replication.assignWorld(w)
    currentWorld = w
end

function Replication.tempAssignStats(s)
    currentStats = s
end

function Replication.pushUnitChange(unit)
    Network.UnitUpdate:FireAllClients(unit)
end

function Replication.pushStatsChange(stats)
    Network.StatsUpdate:FireAllClients(stats)
end

function Replication.pushTileChange(tile)
    Network.TileUpdate:FireAllClients(tile)
end

local function worldStateRequest(player)
    return currentWorld
end

local function statsRequest(player)
    return currentStats
end

local function tilePlacementRequest(player, tile, type)
    local pos = tile.Position
    local serverTile = currentWorld.Tiles[pos.x][pos.y]

    serverTile.Type = type
    Replication.pushTileChange(serverTile)

    return true
end

local function unitHomeRequest(player, unit, home)
    local serverUnit = currentWorld.Units[unit.ID]
    local pos = home.Position
    local serverHome = currentWorld.Tiles[pos.x][pos.y]

    serverUnit.Home = serverHome
    
    print("Home set!", serverHome)

    return true
end

local function unitWorkRequest(player, unit, work)
    local serverUnit = currentWorld.Units[unit.ID]
    local pos = work.Position
    local serverWork = currentWorld.Tiles[pos.x][pos.y]

    serverUnit.Work = serverWork
    
    print("Work set!", serverWork)

    return true
end

local function unitTargetRequest(player, unit, target)
    local serverUnit = currentWorld.Units[unit.ID]
    local pos = target.Position
    local serverTarget = currentWorld.Tiles[pos.x][pos.y]

    serverUnit.Target = serverTarget
    
    print("Target set!", serverTarget)

    return true
end


Network.RequestWorldState.OnServerInvoke = worldStateRequest
Network.RequestStats.OnServerInvoke = statsRequest
Network.RequestTilePlacement.OnServerInvoke = tilePlacementRequest
Network.RequestUnitHome.OnServerInvoke = unitHomeRequest
Network.RequestUnitWork.OnServerInvoke = unitWorkRequest
Network.RequestUnitTarget.OnServerInvoke = unitTargetRequest

return Replication