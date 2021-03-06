local Replication = {}
local Client      = script.Parent
local Common      = game.ReplicatedStorage.Pioneers.Common
local Network     = game.ReplicatedStorage.Network

local ViewUnit      = require(Client.ViewUnit)
local ViewTile      = require(Client.ViewTile)
local ClientUtil    = require(Client.ClientUtil)
local ClientPreload = require(Client.ClientPreload)
local World         = require(Common.World)
local Tile          = require(Common.Tile)
local Util          = require(Common.Util)
local UserStats     = require(Common.UserStats)
local UserSettings  = require(Common.UserSettings)

local RunService = game:GetService("RunService")

local currentWorld
local gameSettings
local currentStats = {}
local RequestedTiles = {}
local strayed = {}
local buildCostBuffer = {}
local unitReferences = {}
local unrequestedUnits = {}
local partitionOwners = {}
local guardposts = {}
local chats = {}
local syncing = 0
local UIBase = nil
local viewThrottle = 100
local partitionHashes = {}

local function handleUnitUpdate(id, changes)
    local localUnit = currentWorld.Units[id]

    if changes.Health and changes.Health <= 0 and false then --TODO: change this false override
        if localUnit then ViewUnit.removeUnit(localUnit) end
    else
        if localUnit then

            if localUnit.Type ~= changes.Type then
               ViewUnit.transitionUnitType(localUnit, changes.Type) 
            end

            for i, v in pairs(changes) do
                localUnit[i] = v
            end

            ViewUnit.updateDisplay(localUnit)
        else
            if not changes.Id then return end
            currentWorld.Units[changes.Id] = changes
            ViewUnit.displayUnit(changes)
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

    if stats.InCombat and os.time() - stats.InCombat < 30 then
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
    local localTile = World.getTileXY(currentWorld.Tiles, pos.x, pos.y)
    local t = t or tick()

    for i, v in pairs(tile) do
        --if not (localTile.lastChange and t - localTile.lastChange < 4) then
            localTile[i] = v
        --end
    end

    ViewTile.updateDisplay(localTile)
end

Replication.handleTileUpdate = handleTileUpdate

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

local function handleGuardpostsUpdate(posts)
    for i, position in pairs(posts) do
        local p = Util.positionStringToVector(position)
        local index = math.floor(3*p.x+0.5) .. ":" .. math.floor(3*p.y+0.5) --TODO: Not copy this from UnitControl
        guardposts[index] = p
    end
end

function Replication.init(world, uiBinding)
    currentWorld = world
    UIBase = uiBinding

    unitupdate = Network.UnitUpdate.OnClientEvent:Connect(handleUnitUpdate)
    statsupdate = Network.StatsUpdate.OnClientEvent:Connect(handleStatsUpdate)
    tileupdate = Network.TileUpdate.OnClientEvent:Connect(handleTileUpdate)
    updatealert = Network.UpdateAlert.OnClientEvent:Connect(handleUpdateAlert)
    chatsupdate = Network.ChatsUpdate.OnClientEvent:Connect(handleChatsUpdate)
    guardpostsupdate = Network.GuardpostsUpdate.OnClientEvent:Connect(handleGuardpostsUpdate)
end

function Replication.worldDied()
    if unitupdate then
        unitupdate:Disconnect()
        statsupdate:Disconnect()
        tileupdate:Disconnect()
        updatealert:Disconnect()
        chatsupdate:Disconnect()
    end
    syncing = syncing + 1
    wait(1)
    partitionHashes = {}
end

function Replication.getUserStats()

    if currentStats.Keep then
        return currentStats
    end

    _G.updateLoadStatus("Stats", "⭕Fetching user stats...")

    repeat
        currentStats = Network.RequestStats:InvokeServer()
        wait(0.5)
    until currentStats

    _G.updateLoadStatus("Stats", "✅Loaded user stats ")
    
    return currentStats
end

function Replication.getUserSettings()
    local settings
    
    _G.updateLoadStatus("Settings", "⭕Fetching user settings...")

    repeat
        settings = Network.RequestSettings:InvokeServer()
        wait(0.5)
    until settings

    UserSettings.defineLocalSettings(settings)

    _G.updateLoadStatus("Settings", "✅Loaded user settings ")

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
            local workTile = World.getTile(currentWorld.Tiles, unit.Work)
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
    local success = Network.RequestTileRepair:InvokeServer(tile)

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

local function fetchPartitionData(partitionId)
    local partition = Network.RequestPartition:InvokeServer(partitionId)

    for _, tile in pairs(partition) do
        local pos = tile.Position
        local localTile = World.getTileXY(currentWorld.Tiles, pos.x, pos.y)
        
        if localTile.CyclicVersion ~= tile.CyclicVersion then
            for i, v in pairs(tile) do
                localTile[i] = v
            end
        end
    end

end

Replication.keepViewAreaLoaded = coroutine.wrap(function()
    local syncStart = syncing
    while syncing == syncStart do

        --Check tile data has been fetched from server
        local position = Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
        local stringPosition = Util.vectorToPositionString(position)
        local requiredPartitions = Util.findOverlappedPartitions(stringPosition)

        --Send server position update and get partition hashes
        local partitionInfo = Network.UpdatePlayerPosition:InvokeServer(ClientUtil.getPlayerPosition())
        
        --Check partition hashes are correct (equal and therefore synchronised)
        for partitionId, partitionHash in pairs(partitionInfo) do
            if partitionHashes[partitionId] ~= partitionHash and partitionHash ~= "0" then
                partitionHashes[partitionId] = partitionHash
                fetchPartitionData(partitionId)

                if not ClientPreload.Loaded and tonumber(partitionHash) ~= 0 then
                    coroutine.wrap(function()
                        wait(2)
                        _G.updateLoadStatus("Map", "✅Map info loaded ")
                        ClientPreload.tellReady()
                    end)()
                end
            end
        end

        --Find view area
        local area = Util.circularPosCollection(position.x, position.y, 0, ClientUtil.getCurrentViewDistance())

        --Update tiles in the view area
        for iteration, tilePos in pairs(area) do
            local tile = World.getTile(currentWorld.Tiles, tilePos)
            ViewTile.updateDisplay(tile)

            if iteration % viewThrottle == 0 then
                RunService.Stepped:Wait()
            end
        end
    end
end)

function Replication.requestTile(position)
    return Network.RequestTile:InvokeServer(position)
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
    _G.updateLoadStatus("ServerReady", "⭕Waiting for server to be ready...")
    local status = Network.Ready:InvokeServer()
    _G.updateLoadStatus("ServerReady", "✅Server is ready ")

    return status
end

function Replication.getPartitionOwnership(x, y)
    return Network.GetPartitionOwnership:InvokeServer(x, y)
end

function Replication.requestSpawn(axialPosition)
    Network.PlayerSpawnRequest:FireServer(axialPosition)
end

function Replication.spawnConfirm()
    Network.PlayerSpawnConfirm:FireServer()
end

function Replication.requestGameSettings()
    gameSettings = Network.RequestGameSettings:InvokeServer()
end

function Replication.getGameSettings()
    return gameSettings
end

function Replication.getTiles()
    return currentWorld.Tiles
end

function Replication.getTileXY(x, y)
    return World.getTileXY(currentWorld.Tiles, x, y)
end

function Replication.getUnits()
    return currentWorld.Units
end

function Replication.requestKingdomDeletion()
    Network.RequestKingdomDeletion:InvokeServer()
    wait(2)
    Network.PlayerRejoined:InvokeServer()
end

spawn(function()

    repeat
        wait(1)
    until currentWorld

    repeat
        local pos =  Util.worldCoordToAxialCoord(ClientUtil.getPlayerPosition())
        local partitionOwnership = Replication.getPartitionOwnership(pos.x, pos.y)

        for partitionId, ownerId in pairs(partitionOwnership.owner) do
            partitionOwners[partitionId] = ownerId
        end

        wait(10)
    until currentWorld.Dead
end)

function Replication.getCachedPartitionOwner(x, y)
    local partitionId = Util.findPartitionId(x, y)
    return partitionOwners[partitionId]
end

function Replication.requestGuardpost(position, set)
    Network.RequestGuardpost:InvokeServer(position, set)
end

function Replication.getGuardposts()
    return guardposts
end

return Replication