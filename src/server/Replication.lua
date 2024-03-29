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
local Chat          = game:GetService("Chat")

local API_URL = "https://api.mysty.dev/pion/"
local API_KEY = ServerStorage.APIKey.Value
local Actions = World.Actions

local currentWorld
--local tilesRequested = {}
--local unitReferences = {}
local playerPositions = {}
local chatBuffer = {}
local feedbackBuffer = {}
local filterCache = {}
local partitionHashes = {} --[id] = hash

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
    
    local stile = World.getTileXY(currentWorld.Tiles, tile.Position.x, tile.Position.y)

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

local function tileRequest(player, position)
    return World.getTileXY(currentWorld.Tiles, position.x, position.y)
end

local function unitRequest(player, unitList)
    local units = {}

    for _, id in pairs(unitList) do
        units[id] = currentWorld.Units[id]
    end

    return units
end

local function updatePlayerPosition(player, position)
    playerPositions[player] = position

    local axialPosition = Util.worldVectorToAxialPositionString(position)
    local partitions = Util.findOverlappedPartitions(axialPosition)

    requiredPartitions = {}

    for _, partitionId in pairs(partitions) do
        requiredPartitions[partitionId] = partitionHashes[partitionId] or "0"
    end

    return requiredPartitions
end

local function partitionRequest(player, partitionId)
    local x, y = Util.partitionIdToCoordinates(partitionId)
    local tileCollection = {}

    local waits = 0
    while not partitionHashes[partitionId] do
        wait(0.2)
        waits = waits + 1

        if waits > 50 then
            warn("Excessive wait time for partition request!")
        end
    end

    for dx = 0, Util.PARTITIONSIZE do
        for dy = 0, Util.PARTITIONSIZE do
            table.insert(tileCollection, World.getTileXY(currentWorld.Tiles, x + dx, y + dy))
        end
    end

    return tileCollection
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

local function chatRequest(player, messageText)

    if #messageText <= 1 then
        return
    end

    --print(messageText, "->", TextService:FilterStringAsync(messageText, player.UserId):GetNonChatStringForBroadcastAsync())

    local message = {
        playerId = player.UserId,
        text = messageText,
        timestamp = os.time(),
    }

    table.insert(chatBuffer, Http:JSONEncode(message))
end

local function feedbackRequest(player, react, text)
    local feedback = {
        player = player.UserId,
        playerName = player.Name,
        react = react,
        text = text,
        timestamp = os.time(),
    }
    table.insert(feedbackBuffer, Http:JSONEncode(feedback))
end

local function partitionOwnerRequest(player, x, y)
    local payload = Http:JSONEncode({apikey = API_KEY, x = 0, y = 0})
    local res = Http:PostAsync(API_URL.."getPartitionOwners", payload)
    return Http:JSONDecode(res)
end

local function playerSpawnRequest(player, position)
    local worldPosition = Util.axialCoordToWorldCoord(position)
    player:LoadCharacter()
    repeat wait() until player.Character
    player.Character:MoveTo(worldPosition + Vector3.new(0, 50, 0))
    player.Character.HumanoidRootPart.Anchored = true
end

local function playerSpawnConfirm(player)
    repeat wait() until player.Character
    wait()
    player.Character.HumanoidRootPart.Anchored = false
end

local function gameSettingsRequest(player)
    repeat wait() until gameSettings
    return gameSettings
end

local function kingdomDeletionRequest(player)
    local payload = {
        apikey = API_KEY,
        id = player.UserId,
        action = Actions.DELETE_KINGDOM,
    }

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    return res.status
end

local function guardpostRequest(player, position, set)
    print(position)
    local payload = {
        apikey = API_KEY,
        id = player.UserId,
        position = position,
        set = set,
        action = Actions.SET_GUARDPOST,
    }

    local res = Http:PostAsync(API_URL.."actionRequest", Http:JSONEncode(payload))
    res = Http:JSONDecode(res)

    return res.status
end

function Replication.assignWorld(w)
    currentWorld = w

    Network.RequestWorldState.OnServerInvoke     = worldStateRequest
    Network.RequestStats.OnServerInvoke          = statsRequest
    Network.RequestSettings.OnServerInvoke       = settingsRequest
    Network.RequestTilePlacement.OnServerInvoke  = tilePlacementRequest
    Network.RequestTileDelete.OnServerInvoke     = tileDeleteRequest
    Network.RequestTileRepair.OnServerInvoke     = tileRepairRequest
    Network.RequestUnitWork.OnServerInvoke       = unitWorkRequest
    Network.RequestUnitAttack.OnServerInvoke     = unitAttackRequest
    Network.RequestTile.OnServerInvoke           = tileRequest
    Network.RequestUnits.OnServerInvoke          = unitRequest
    Network.GetCircularTiles.OnServerInvoke      = getCircularTiles
    Network.Ready.OnServerInvoke                 = getTesterStatus
    Network.UpdatePlayerPosition.OnServerInvoke  = updatePlayerPosition
    Network.RequestPartition.OnServerInvoke      = partitionRequest
    Network.GetPartitionOwnership.OnServerInvoke = partitionOwnerRequest
    Network.RequestGameSettings.OnServerInvoke   = gameSettingsRequest
    Network.RequestKingdomDeletion.OnServerInvoke= kingdomDeletionRequest
    Network.RequestGuardpost.OnServerInvoke      = guardpostRequest
    Network.SettingsUpdate.OnServerEvent:Connect(settingsUpdate)
    Network.Chatted.OnServerEvent:Connect(chatRequest)
    Network.FeedbackRequest.OnServerEvent:Connect(feedbackRequest)
    Network.PlayerSpawnRequest.OnServerEvent:Connect(playerSpawnRequest)
    Network.PlayerSpawnConfirm.OnServerEvent:Connect(playerSpawnConfirm)
end

function Replication.fetchGameSettings()
    local payload = Http:JSONEncode({apikey = API_KEY})
    local res = Http:PostAsync(API_URL.."getgamesettings", payload)
    gameSettings = Http:JSONDecode(res)
end

function Replication.pushStatsChange(stats)
    if stats.PlayerId then
        local player = Players:GetPlayerByUserId(stats.PlayerId)
        
        if player then
            Network.StatsUpdate:FireClient(player, stats)
        end
    end
end

function Replication.pushTileChange(tilePos)
    local tile = currentWorld.Tiles[tilePos] or Tile.defaultGrass(tilePos)

    Network.TileUpdate:FireAllClients(tile)
    --[[for _, player in pairs(Players:GetChildren()) do
        if tilesRequested[player][tilePos] then
            Network.TileUpdate:FireClient(player, tile)
        end
    end

    if tile.UnitList then
        for _, unitId in pairs(tile.UnitList) do
            unitReferences[unitId] = true
        end
    end]]--
end

function Replication.pushUnitUpdate(oldUnit, newUnit)
    local changes = {}

    for i, v in pairs(newUnit) do
        if oldUnit and oldUnit[i] ~= newUnit[i] then
            changes[i] = v
        end
    end

    Replication.pushUnitChanges(newUnit.Id, newUnit)
end

function Replication.pushUnitChanges(unitId, changes)
    Network.UnitUpdate:FireAllClients(unitId, changes)
end

function Replication.getRequestedTiles()
    return tilesRequested
end

function Replication.getUnitReferences()
    return unitReferences
end

function Replication.getPlayerPositions()
    return playerPositions
end

function Replication.getPartitionHashes()
    return partitionHashes
end

function Replication.handlePartitionInfo(partitions)
    for _, partitionData in pairs(partitions) do
        local partitionId = partitionData[1]
        local partitionHash = partitionData[2]
        local tileupdates = partitionData[3]

        if (partitionId) then
            partitionHashes[partitionId] = partitionHash
            Replication.handleTileInfo(tileupdates)
        end
    end
end

function Replication.handleTileInfo(tileList)
    for _, tile in pairs(tileList) do
        local pos = tile.Position

        if not pos then return end

        local stile = currentWorld.Tiles[pos]
        
        currentWorld.Tiles[pos] = Tile.deserialise(pos, tile)

    end
end

function Replication.handleUnitInfo(unitList)
    for _, unit in pairs(unitList) do
        unit = Unit.sanitise(unit, currentWorld.Tiles)
        Replication.pushUnitUpdate(currentWorld.Units[unit.Id], unit)
        currentWorld.Units[unit.Id] = unit
    end
end

local function filterText(message, text, player)
    coroutine.wrap(function()
        filterCache[player][text] = Chat:FilterStringAsync(text, player, player)
    end)()
end

function Replication.handleChats(chatData)
    local chats = {}
    local playerChats = {}
    local currentTime = os.time()
    
    --Decode Chats from json form
    for i, rawChat in pairs(chatData) do
        local decoded, chat = pcall(function() return Http:JSONDecode(rawChat) end) --Conservative decode just incase the json is invalid
        if decoded and currentTime - (chat.timestamp or 0)  < 600 then
            chats[i] = chat
        end
    end

    --Filter and send them per client
    for _, player in pairs(Players:GetChildren()) do
        local filteredChats = {}
        if not filterCache[player] then filterCache[player] = {} end

        for i, chat in pairs(chats) do
            local text = filterCache[player][chats[i].text] 
            
            if not text then
                text = string.rep("_", #chats[i].text)
                filterText(filteredChats[i], chats[i].text, player)
            end

            filteredChats[i] = {
                playerId = chats[i].playerId,
                timestamp = chats[i].timestamp,
                text = text,
            }
        end

        Network.ChatsUpdate:FireClient(player, filteredChats)
    end
end

function Replication.pushUpdateAlert(updating)
    Network.UpdateAlert:FireAllClients(updating)
end

function Replication.getChats()
    local chats = chatBuffer
    chatBuffer = {}
    return chats
end

function Replication.getFeedback()
    local feedback = feedbackBuffer
    feedbackBuffer = {}
    return feedback
end

--Sets player position early based on keep location
--Assists with loading tiles faster
function Replication.earlyPlayerPositionSet(player, stats)
    if stats.Keep and not playerPositions[player] then
        playerPositions[player] = Util.axialCoordToWorldCoord(Util.positionStringToVector(stats.Keep))
    end
end

function Replication.handleGuardposts(guardposts)
    for id, posts in pairs(guardposts) do
        local player = Players:GetPlayerByUserId(id)

        if player then
            Network.GuardpostsUpdate:FireClient(player, posts)
        end
    end
end

Network.Ready.OnServerInvoke = function() return nil end

--Players.PlayerAdded:Connect(function(player) tilesRequested[player] = {} end)
--Players.PlayerRemoving:Connect(function(player) tilesRequested[player] = nil end)

return Replication