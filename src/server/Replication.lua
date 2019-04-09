local Replication = {}
local Server      = script.Parent
local Common      = game.ReplicatedStorage.Pioneers.Common

local Tile      = require(Common.Tile)
local Unit      = require(Common.Unit)
local World     = require(Common.World)
local UserStats = require(Common.UserStats)

local Network = game.ReplicatedStorage.Network
local Players = game:GetService("Players")

local currentWorld
local UnitController
local StatsController

function Replication.assignWorld(w)
    currentWorld = w

    StatsController = require(Server.StatsController)
    UnitController = require(Server.UnitController)

    UnitController.assignWorld(w)
end

function Replication.pushUnitChange(unit)
    Network.UnitUpdate:FireAllClients(unit)
end

function Replication.pushStatsChange(stats)
    local player = game.Players:GetPlayerByUserId(stats.PlayerID)
    
    if player then
        Network.StatsUpdate:FireClient(player, stats)
    end
end

function Replication.pushTileChange(tile)
    Network.TileUpdate:FireAllClients(tile)
end

local function worldStateRequest(player)
    return currentWorld
end

local function statsRequest(player)
    return UserStats.Store[player.UserId]
end

local function tilePlacementRequest(player, tile, type)
    
    if not World.tileCanBePlaced(currentWorld, tile, type, player.UserId) then
        return false end
    
    local requiredResources = Tile.ConstructionCosts[type]
    local stats = UserStats.Store[player.UserId]

    if not UserStats.hasEnoughResources(stats, requiredResources) then
        return false end

    local pos = tile.Position
    local serverTile = World.getTile(currentWorld.Tiles, pos.x, pos.y)

    StatsController.useRequirement(player.UserId, requiredResources)

    serverTile.Type = type
    serverTile.OwnerID = player.UserId
    
    Replication.pushTileChange(serverTile)

    if type == Tile.HOUSE then 
        delay(5, function()
            UnitController.spawnUnit(player.UserId, serverTile)
            while wait(20) do
                UnitController.spawnUnit(player.UserId, serverTile)
            end
        end)
    end

    return true
end

local function unitHomeRequest(player, unit, tile)
    local serverUnit = currentWorld.Units[unit.ID]
    local pos = tile.Position
    local serverTile = World.getTile(currentWorld.Tiles, pos.x, pos.y)

    local ID = player.UserId

    if ID == unit.OwnerID and ID == serverUnit.OwnerID  
        and ID == tile.OwnerID and ID == serverTile.OwnerID then

        return UnitController.setHome(serverUnit, serverTile)
    else
        return false
    end
end

local function unitWorkRequest(player, unit, tile)
    local serverUnit = currentWorld.Units[unit.ID]
    local pos = tile.Position
    local serverTile = World.getTile(currentWorld.Tiles, pos.x, pos.y)

    local ID = player.UserId

    if ID == unit.OwnerID and ID == serverUnit.OwnerID  
        and ID == tile.OwnerID and ID == serverTile.OwnerID then

        return UnitController.setWork(serverUnit, serverTile)
    else
        return false
    end
end

local function unitTargetRequest(player, unit, tile)
    local serverUnit = currentWorld.Units[unit.ID]
    local pos = tile.Position
    local serverTile = World.getTile(currentWorld.Tiles, pos.x, pos.y)

    local ID = player.UserId

    if ID == unit.OwnerID and ID == serverUnit.OwnerID 
        and ID == tile.OwnerID and ID == serverTile.OwnerID then

        return UnitController.setTarget(serverUnit, serverTile)
    else
        return false
    end
end

Network.RequestWorldState.OnServerInvoke    = worldStateRequest
Network.RequestStats.OnServerInvoke         = statsRequest
Network.RequestTilePlacement.OnServerInvoke = tilePlacementRequest
Network.RequestUnitHome.OnServerInvoke      = unitHomeRequest
Network.RequestUnitWork.OnServerInvoke      = unitWorkRequest
Network.RequestUnitTarget.OnServerInvoke    = unitTargetRequest

return Replication