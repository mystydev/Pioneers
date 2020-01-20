local ActionHandler = {}
local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common

local Util        = require(Common.Util)
local Unit        = require(Common.Unit)
local Tile        = require(Common.Tile)
local World       = require(Common.World)
local ViewTile    = require(Client.ViewTile)
local Replication = require(Client.Replication)
local SoundManager = require(Client.SoundManager)
local ViewUnit    = require(Client.ViewUnit)
local UIBase      = require(Client.UIBase)
local Players = game:GetService("Players")

local currentWorld
local unitChangeHook = function() end

function ActionHandler.init(world)
    currentWorld = world
end

function ActionHandler.provideUnitChangeHook(hook)
    unitChangeHook = hook
end

local function tempChangeTileType(tile, type, newId)
    --Save current tile info to restore if needed later
    local oldType = tile.Type
    local oldId = tile.OwnerId
    local version = tile.CyclicVersion

    --Assign new info
    tile.Type = type
    tile.OwnerId = newId

    --Update display
    World.setTile(currentWorld.Tiles, tile, tile.Position)
    ViewTile.updateDisplay(tile)
    tile.lastChange = tick() + 2

    --Update neighbouring tiles
    for _, n in pairs(World.getNeighbours(currentWorld.Tiles, tile.Position)) do
        ViewTile.updateDisplay(n, nil, true)
    end

    --Wait to see if request failed and tile needs to be restored
    delay(5, function()

        --Version didn't change so no update happened
        if version == tile.CyclicVersion then
            tile.Type = oldType
            tile.OwnerId = oldId

            ViewTile.updateDisplay(tile)

            for _, n in pairs(World.getNeighbours(currentWorld.Tiles, tile.Position)) do
                ViewTile.updateDisplay(n)
            end
        end
    end)
end

function ActionHandler.attemptBuild(tile, type)
    local worldTile = World.getTileXY(currentWorld.Tiles, tile.Position.X, tile.Position.Y)
    --Update tile then send request to place the tile
    tempChangeTileType(tile, type, Players.LocalPlayer.UserId)

    if type ~= Tile.KEEP then
        SoundManager.initiatePlace()
    end

    coroutine.wrap(function() Replication.requestTilePlacement(tile, type, Players.LocalPlayer.UserId) end)()
    return worldTile
end

function ActionHandler.attemptDelete(tile)

    --If this is a keep then delete whole kingdom!
    if (tile.Type == Tile.KEEP) then
        return ActionHandler.attemptDeleteKingdom()
    end

    --Update tile then send request to delete the tile
    if tile.Type == Tile.HOUSE then
        for _, id in pairs(tile.UnitList) do
            local unit =  currentWorld.Units[id]
            ViewUnit.simDeath(unit)
        end
    end

    tempChangeTileType(tile, Tile.GRASS, nil)

    Replication.requestTileDelete(tile)
end

function ActionHandler.attemptDeleteKingdom()
    local yes = UIBase.yesNoPrompt(
        "Want to start again?", 
        "Deleting your keep will delete your entire kingdom!\n\n Are you sure you wish to start again?")

    if yes then
        yes = UIBase.yesNoPrompt(
            "Are you really sure?",
            "Deleting your kingdom is permanent!\n\n This cannot be undone!\n\nAre you sure you wish to start again?"
        )

        if yes then
            UIBase.blockingLoadingScreen("Deleting your kingdom...")
            Replication.requestKingdomDeletion()
            error("Pion unrecoverable - User deleted kingdom")
        end
    end
end

function ActionHandler.assignWork(unit, tile)
    Replication.requestUnitWork(unit, tile)

    --Simulate unassigned work
    if tile == nil then

        if not Unit.isMilitary(unit) then
            unit.Type = Unit.VILLAGER
        end

        unit.Work = nil
        unitChangeHook()
    end
end

function ActionHandler.chatted(message)
    Replication.sendChat(message)
end

function ActionHandler.sendFeedback(react, text)
    Replication.sendFeedback(react, text)
end

--Assign a military unit spot as a guard post
function ActionHandler.assignGuardpost(position)
    print("Action1:", position)
    local x = math.floor((math.floor(3*position.x+0.5)/3)*10000)/10000
    local y = math.floor((math.floor(3*position.y+0.5)/3)*10000)/10000
    position = x .. ":" .. y
    print("Action2:", x, y)
    Replication.requestGuardpost(position, true)
end

--Unassign a military unit spot as a guard post
function ActionHandler.unassignGuardpost(position)
    local x = math.floor((math.floor(3*position.x+0.5)/3)*10000)/10000
    local y = math.floor((math.floor(3*position.y+0.5)/3)*10000)/10000
    position = x .. ":" .. y
    Replication.requestGuardpost(position, false)
end

return ActionHandler