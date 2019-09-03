local Replication = {}
local Client      = script.Parent
local Common      = game.ReplicatedStorage.Pioneers.Common

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
local RequestedTiles = {}
local strayed = {}
local buildCostBuffer = {}
local unitReferences = {}
local unrequestedUnits = {}
local chats = {}
local syncing = true
local UIBase = nil

local function handleUnitUpdate(id, changes)
    if not unitReferences[id] then
        table.insert(unrequestedUnits, id)
        unitReferences[id] = true
        return
    end

    local localUnit = currentWorld.Units[id]

    if changes.Health and changes.Health <= 0 then
        if localUnit then ViewUnit.removeUnit(localUnit) end
    else
        if localUnit then

            for i, v in pairs(changes) do
                localUnit[i] = v
            end

            ViewUnit.updateDisplay(localUnit)
        end
    end
end

local requesting = false
local function handleUnrequestedUnits()
    if requesting then
        return
    end

    requesting = true

    local units = Replication.requestUnits(unrequestedUnits)

    for _, unit in pairs(units) do
        for i, id in pairs(unrequestedUnits) do
            if unit.Id == id then
                table.remove(unrequestedUnits, i)
                break
            end
        end

        currentWorld.Units[unit.Id] = unit
        ViewUnit.displayUnit(unit)
    end

    wait(1)
    requesting = false
end

local function handleStatsUpdate(stats)

    if stats.InCombat and os.time() - stats.InCombat < 10 then
        UIBase.combatAlert()
    else
        UIBase.endCombatAlert()
    end

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

local function handleTileUpdate(tile, t)
    local pos = tile.Position
    local localTile = World.getTile(currentWorld.Tiles, pos.x, pos.y)
    local t = t or tick()

    for i, v in pairs(tile) do
        if not (localTile.lastChange and t - localTile.lastChange < 4) then
            localTile[i] = v
        end
    end

    if localTile.UnitList then
        for _, id in pairs(localTile.UnitList) do
            if not unitReferences[id] then
                table.insert(unrequestedUnits, id)
                unitReferences[id] = true
            end
        end
    end
    
    ViewTile.updateDisplay(localTile)
end

local function handleUpdateAlert(updating)
    if updating then
        UIBase.updateAlert()
    else
        UIBase.endUpdateAlert()
    end
end

local function handleChatsUpdate(inChats)
    chats = inChats
end

function Replication.init(world, uiBinding)
    currentWorld = world
    UIBase = uiBinding

    unitupdate = Network.UnitUpdate.OnClientEvent:Connect(handleUnitUpdate)
    statsupdate = Network.StatsUpdate.OnClientEvent:Connect(handleStatsUpdate)
    tileupdate = Network.TileUpdate.OnClientEvent:Connect(handleTileUpdate)
    updatealert = Network.UpdateAlert.OnClientEvent:Connect(handleUpdateAlert)
    chatsupdate = Network.ChatsUpdate.OnClientEvent:Connect(handleChatsUpdate)

    _G.updateLoadStatus("Fetching map data...")
end

function Replication.worldDied()
    if unitupdate then
        unitupdate:Disconnect()
        statsupdate:Disconnect()
        tileupdate:Disconnect()
        updatealert:Disconnect()
        chatsupdate:Disconnect()
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
    coroutine.wrap(ViewTile.simulateDeletion)(tile)
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
    else
        if unit.Work then
            local workTile = World.getTileFromString(currentWorld.Tiles, unit.Work)
            if workTile.UnitList then
                workTile.UnitList = nil
            end
        end
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

function Replication.requestTileRepair(tile)
    coroutine.wrap(ViewTile.simulateRepair)(tile)
    success = Network.RequestTileRepair:InvokeServer(tile)

    if not success then
        print("Tile repair request failed!")
    end

    return success
end

function Replication.updateTiles(pos, radius)
    local tiles = Network.GetCircularTiles:InvokeServer(pos, radius)
    local t = tick()

    for _, tile in pairs(tiles) do
        handleTileUpdate(tile, t)
    end
end

function Replication.keepViewAreaLoaded()
    debug.profilebegin("keepViewAreaLoaded")
    local pos  = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
    local area = Util.circularPosCollection(pos.x, pos.y, 0, ClientUtil.getCurrentViewDistance())
    local unloaded = {}

    debug.profilebegin("detectUnrequestedTiles")
    for _, tilePos in pairs(area) do
        if not RequestedTiles[tilePos] then
            table.insert(unloaded, tilePos)
            RequestedTiles[tilePos] = true
        end
    end

    local tiles = Replication.requestTiles(unloaded)
    local t = tick()

    for _, tile in pairs(tiles) do
        handleTileUpdate(tile, t)
    end

    handleUnrequestedUnits()
end

function Replication.requestTiles(tilePosList)
    return Network.RequestTiles:InvokeServer(tilePosList)
end

function Replication.requestUnits(unitIdList)
    return Network.RequestUnits:InvokeServer(unitIdList)
end

function Replication.sendChat(message)
    Network.Chatted:FireServer(message)
end

function Replication.getChats()
    return chats
end

function Replication.sendFeedback(react, text)
    Network.FeedbackRequest:FireServer(react, text)
end

function Replication.ready()
    _G.updateLoadStatus("Waiting for server to be ready...")
    local status = Network.Ready:InvokeServer()

    return status
end

return Replication