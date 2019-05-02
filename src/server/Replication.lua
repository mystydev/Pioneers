local Replication = {}
local Common      = game.ReplicatedStorage.Pioneers.Common

local Tile      = require(Common.Tile)
local Unit      = require(Common.Unit)
local UserStats = require(Common.UserStats)
local Util      = require(Common.Util)
local World     = require(Common.World)

local Network = game.ReplicatedStorage.Network
local Players = game:GetService("Players")
local Http    = game:GetService("HttpService")

local API_URL = "https://api.mysty.dev/pion/"
local Actions = World.Actions

local currentWorld

local function worldStateRequest(player)
    return currentWorld
end

local function statsRequest(player)
    return UserStats.Store[player.UserId]
end

local function tilePlacementRequest(player, tile, type)
    
    local stile = World.getTile(currentWorld.Tiles, tile.Position.x, tile.Position.y)

    local payload = {
        id = player.UserId,
        action = Actions.PLACE_TILE,
        type = type,
        position = Tile.getIndex(tile)
    }

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    return res.status == "Ok"
end

local function tileDeleteRequest(player, tile)
    local payload = {
        id = player.UserId,
        action = Actions.DELETE_TILE,
        position = Tile.getIndex(tile)
    }

    for i, v in pairs(payload) do print(i,v) end

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    for i, v in pairs(res) do print(i,v) end

    return res.status == "Ok"
end

local function unitWorkRequest(player, unit, tile)
    
    local payload = {
        id = player.UserId,
        action = Actions.SET_WORK,
        unitId = unit.Id,
        position = Tile.getIndex(tile)
    }

    print("WorkRequest:", Actions.SET_WORK, Tile.getIndex(tile))

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    return res.status == "Ok"
end

local function unitAttackRequest(player, unit, tile)

    local payload = {
        id = player.UserId,
        action = Actions.ATTACK,
        unitId = unit.Id,
        position = Tile.getIndex(tile)
    }

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    print("Attack:", res.status)

    return res.status == "Ok"
end

local function getCircularTiles(player, pos, radius)
    return Util.circularCollection(currentWorld.Tiles, pos.x, pos.y, 0, radius)
end

local function getTesterStatus(player)
    local res = Http:GetAsync(API_URL.."isTester?id="..player.UserId)

    if res == "\"0\"" then
        return false
    else
        return true
    end
end

function Replication.assignWorld(w)
    currentWorld = w

    Network.RequestWorldState.OnServerInvoke    = worldStateRequest
    Network.RequestStats.OnServerInvoke         = statsRequest
    Network.RequestTilePlacement.OnServerInvoke = tilePlacementRequest
    Network.RequestTileDelete.OnServerInvoke    = tileDeleteRequest
    Network.RequestUnitWork.OnServerInvoke      = unitWorkRequest
    Network.RequestUnitAttack.OnServerInvoke    = unitAttackRequest
    Network.GetCircularTiles.OnServerInvoke     = getCircularTiles
    Network.Ready.OnServerInvoke = getTesterStatus
end

function Replication.pushStatsChange(stats)
    local player = Players:GetPlayerByUserId(stats.PlayerId)
    
    if player then
        Network.StatsUpdate:FireClient(player, stats)
    end
end

function Replication.pushTileChange(tile)
    Network.TileUpdate:FireAllClients(tile)
end

function Replication.tempSyncUnit(unit)
    Network.UnitUpdate:FireAllClients(unit)
end

Network.Ready.OnServerInvoke = function() return nil end

return Replication