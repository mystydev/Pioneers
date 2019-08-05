local Replication = {}
local Common      = game.ReplicatedStorage.Pioneers.Common

local Tile         = require(Common.Tile)
local Unit         = require(Common.Unit)
local UserStats    = require(Common.UserStats)
local UserSettings = require(Common.UserSettings)
local Util         = require(Common.Util)
local World        = require(Common.World)

local Network       = game.ReplicatedStorage.Network
local Players       = game:GetService("Players")
local Http          = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local API_URL = "https://api.mysty.dev/pion/"
local API_KEY = ServerStorage.APIKey.Value
local Actions = World.Actions

local currentWorld
local tilesRequested = {}

local function worldStateRequest(player)
    return currentWorld
end

local function statsRequest(player)
    return UserStats.Store[player.UserId]
end

local function settingsRequest(player)
    return UserSettings.getUserSettings(player)
end

local function settingsUpdate(player, settings)
    local url = API_URL .. "updateusersettings"
    local payload = Http:JSONEncode({
        apikey = API_KEY,
        Id = player.userId,
        Settings = settings,
    })
    Http:PostAsync(url, payload)
end

local function tilePlacementRequest(player, tile, type)
    
    local stile = World.getTile(currentWorld.Tiles, tile.Position.x, tile.Position.y)

    local payload = {
        apikey = API_KEY,
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
        apikey = API_KEY,
        id = player.UserId,
        action = Actions.DELETE_TILE,
        position = Tile.getIndex(tile)
    }

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    return res.status == "Ok"
end

local function tileRepairRequest(player, tile)
    local payload = {
        apikey = API_KEY,
        id = player.UserId,
        action = Actions.REPAIR_TILE,
        position = Tile.getIndex(tile)
    }

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    return res.status == "Ok"
end

local function unitWorkRequest(player, unit, tile)
    
    local payload = {
        apikey = API_KEY,
        id = player.UserId,
        action = Actions.SET_WORK,
        unitId = unit.Id,
        position = Tile.getIndex(tile)
    }

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    return res.status == "Ok"
end

local function unitAttackRequest(player, unit, tile)

    local payload = {
        apikey = API_KEY,
        id = player.UserId,
        action = Actions.ATTACK,
        unitId = unit.Id,
        position = Tile.getIndex(tile)
    }

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    return res.status == "Ok"
end

local function getCircularTiles(player, pos, radius)
    return Util.circularCollection(currentWorld.Tiles, pos.x, pos.y, 0, radius)
end

local function tileRequest(player, posList)
    local tiles = {}

    for _, pos in pairs(posList) do
        tilesRequested[player][pos] = true
        table.insert(tiles, World.getTileFromString(currentWorld.Tiles, pos))
    end

    return tiles
end

local function unitRequest(player, unitList)
    local units = {}

    for _, id in pairs(unitList) do
        units[id] = currentWorld.Units[id]
    end

    return units
end

local function getTesterStatus(player)
    local payload = {
        apikey = API_KEY,
        id = player.UserId,
    }
    local res = Http:PostAsync(API_URL.."isTester", Http:JSONEncode(payload))

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
    Network.RequestSettings.OnServerInvoke      = settingsRequest
    Network.SettingsUpdate.OnServerEvent:Connect(settingsUpdate)
    Network.RequestTilePlacement.OnServerInvoke = tilePlacementRequest
    Network.RequestTileDelete.OnServerInvoke    = tileDeleteRequest
    Network.RequestTileRepair.OnServerInvoke    = tileRepairRequest
    Network.RequestUnitWork.OnServerInvoke      = unitWorkRequest
    Network.RequestUnitAttack.OnServerInvoke    = unitAttackRequest
    Network.RequestTiles.OnServerInvoke         = tileRequest
    Network.RequestUnits.OnServerInvoke         = unitRequest
    Network.GetCircularTiles.OnServerInvoke     = getCircularTiles
    Network.Ready.OnServerInvoke = getTesterStatus
end

function Replication.pushStatsChange(stats)
    local player = Players:GetPlayerByUserId(stats.PlayerId)
    
    if player then
        Network.StatsUpdate:FireClient(player, stats)
    end
end

function Replication.pushTileChange(tilePos)
    local tile = currentWorld.Tiles[tilePos] or Tile.defaultGrass(tilePos)

    for _, player in pairs(Players:GetChildren()) do
        if tilesRequested[player][tilePos] then
            Network.TileUpdate:FireClient(player, tile)
        end
    end
end

function Replication.pushUnitUpdate(oldUnit, newUnit)
    local changes = {}

    for i, v in pairs(newUnit) do
        if oldUnit[i] ~= newUnit[i] then
            changes[i] = v
        end
    end

    Replication.pushUnitChanges(newUnit.Id, changes)
end

function Replication.pushUnitChanges(unitId, changes)
    Network.UnitUpdate:FireAllClients(unitId, changes)
end

Network.Ready.OnServerInvoke = function() return nil end

Players.PlayerAdded:Connect(function(player) tilesRequested[player] = {} end)
Players.PlayerRemoving:Connect(function(player) tilesRequested[player] = nil end)

return Replication