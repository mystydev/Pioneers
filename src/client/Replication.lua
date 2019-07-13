local Replication = {}
local Client      = script.Parent
local Common      = game.ReplicatedStorage.Pioneers.Common

local ClientPreload = require(Client.ClientPreload)
local ViewUnit      = require(Client.ViewUnit)
local ViewTile      = require(Client.ViewTile)
local ClientUtil    = require(Client.ClientUtil)
local World         = require(Common.World)
local Tile          = require(Common.Tile)
local Util          = require(Common.Util)
local UserStats     = require(Common.UserStats)
local UserSettings  = require(Common.UserSettings)
local Network       = game.ReplicatedStorage.Network

local currentWorld
local currentStats = {}
local syncing = true

local function tileSync()

    while syncing do
        local pos = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
        local dist = ClientUtil.getCurrentViewDistance()

        Replication.updateTiles(pos, 15)
        wait(1)
    end
end

function Replication.init(world)
    currentWorld = world

    unitupdate = Network.UnitUpdate.OnClientEvent:Connect(handleUnitUpdate)
    statsupdate = Network.StatsUpdate.OnClientEvent:Connect(handleStatsUpdate)
    tileupdate = Network.TileUpdate.OnClientEvent:Connect(handleTileUpdate)

    _G.updateLoadStatus("Fetching map data...")
    spawn(tileSync)
end

function Replication.worldDied()
    if unitupdate then
        unitupdate:Disconnect()
        statsupdate:Disconnect()
        tileupdate:Disconnect()
    end
end

function Replication.getUserStats()

    _G.updateLoadStatus("Fetching user stats...")

    repeat
        currentStats = Network.RequestStats:InvokeServer()
        wait(0.5)
    until currentStats
    
    return currentStats
end

function Replication.getUserSettings()
    local settings
    
    _G.updateLoadStatus("Fetching user settings...")

    repeat
        settings = Network.RequestSettings:InvokeServer()
        wait(0.5)
    until settings

    UserSettings.defineLocalSettings(settings)

    return settings
end

local buildCostBuffer = {}
function Replication.requestTilePlacement(tile, type)

    local success
    local reqs = Tile.ConstructionCosts[type]

    if UserStats.hasEnoughResources(currentStats, reqs) then
        for res, amount in pairs(reqs) do
            currentStats[res] = currentStats[res] - amount
        end

        success = Network.RequestTilePlacement:InvokeServer(tile, type)
    end

    if not success then
        print("Tile placement request failed!")
    end

    return success
end

function Replication.requestTileDelete(tile)
    success = Network.RequestTileDelete:InvokeServer(tile)

    if not success then
        print("Tile delete request failed!")
    end

    return success
end

function Replication.requestUnitWork(unit, tile)
    local success = Network.RequestUnitWork:InvokeServer(unit, tile)

    if not success then
        print("Work request failed!")
    end

    return success
end

function Replication.requestUnitAttack(unit, tile)
    local success = Network.RequestUnitAttack:InvokeServer(unit, tile)

    if not success then
        print("Attack request failed!")
    end

    return success
end

function handleUnitUpdate(unit)
    repeat wait() until currentWorld
    local localUnit = currentWorld.Units[unit.Id]

    if not localUnit then
        currentWorld.Units[unit.Id] = unit
        ViewUnit.displayUnit(unit)
    else

        for i, v in pairs(unit) do
            localUnit[i] = v
        end

        ViewUnit.updateDisplay(localUnit)
    end
end

local strayed = {}
function handleStatsUpdate(stats)
    for i, v in pairs(stats) do

        if i == "Wood" or i == "Stone" then

            local stat = currentStats[i] or 0
            local maintenance = currentStats['M'..i] or 0

            if math.abs(v - stat - maintenance) < 5 then
                currentStats[i] = v
                strayed[i] = 0
            else
                currentStats[i] = stat - maintenance
                strayed[i] = (strayed[i] or 0) + 1

                if strayed[i] > 2 then
                    currentStats[i] = v
                end
            end
        else
            currentStats[i] = v
        end
    end
end

function handleTileUpdate(tile, t)

    local pos = tile.Position
    local localTile = World.getTile(currentWorld.Tiles, pos.x, pos.y)
    local t = t or tick()

    for i, v in pairs(tile) do
        if not (localTile.lastChange and t - localTile.lastChange < 4) then
            localTile[i] = v
        end
    end

    ViewTile.updateDisplay(localTile)
end

function Replication.updateTiles(pos, radius)
    local tiles = Network.GetCircularTiles:InvokeServer(pos, radius)
    local t = tick()

    for _, tile in pairs(tiles) do
        handleTileUpdate(tile, t)
    end
end

function Replication.ready()
    _G.updateLoadStatus("Waiting for server to be ready...")
    local status = Network.Ready:InvokeServer()

    ClientPreload.displayTesterStatus(status)

    return status ~= nil
end

return Replication