local Replication = {}
local Server      = script.Parent
local Common      = game.ReplicatedStorage.Pioneers.Common

local Tile      = require(Common.Tile)
local Unit      = require(Common.Unit)
local UserStats = require(Common.UserStats)

local Network = game.ReplicatedStorage.Network
local Players = game:GetService("Players")
local Http    = game:GetService("HttpService")

local API_URL = "https://api.mysty.dev/pion/"
local Actions = {PLACE_TILE = 0, SET_WORK = 1}

local currentWorld

local function worldStateRequest(player)
    return currentWorld
end

local function statsRequest(player)
    return UserStats.Store[player.UserId]
end

local function tilePlacementRequest(player, tile, type)
    
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

local function unitWorkRequest(player, unit, tile)
    
    local payload = {
        id = player.UserId,
        action = Actions.SET_WORK,
        unitId = unit.Id,
        position = Tile.getIndex(tile)
    }

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    return res.status == "Ok"
end

function Replication.assignWorld(w)
    currentWorld = w

    Network.RequestWorldState.OnServerInvoke    = worldStateRequest
    Network.RequestStats.OnServerInvoke         = statsRequest
    Network.RequestTilePlacement.OnServerInvoke = tilePlacementRequest
    Network.RequestUnitHome.OnServerInvoke      = unitWorkRequest --TODO: change this
    Network.RequestUnitWork.OnServerInvoke      = unitWorkRequest
    Network.RequestUnitTarget.OnServerInvoke    = unitWorkRequest
    Network.Ready.OnServerInvoke = function() return true end
end

function Replication.pushUnitChange(unit)
    local payload = Unit.serialise(unit)
    Http:PostAsync("https://api.mysty.dev/pion/unitupdate", payload)

    Network.UnitUpdate:FireAllClients(unit)
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

Network.Ready.OnServerInvoke = function() return false end

return Replication