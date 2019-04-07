local TilePlacement = {}
local Client        = script.Parent
local Common        = game.ReplicatedStorage.Pioneers.Common

local ViewWorld     = require(Client.ViewWorld)
local ViewTile      = require(Client.ViewTile)
local ViewStats     = require(Client.ViewStats)
local Replication   = require(Client.Replication)
local ViewSelection = require(Client.ViewSelection)
local ClientUtil    = require(Client.ClientUtil)
local Tile          = require(Common.Tile)
local UserStats     = require(Common.UserStats)


local UIS = game:GetService("UserInputService")
local selectedObject

local KeyCodeMap = {}
KeyCodeMap[45] = 0
KeyCodeMap[48] = 1
KeyCodeMap[49] = 2
KeyCodeMap[50] = 3
KeyCodeMap[51] = 4
KeyCodeMap[52] = 5
KeyCodeMap[53] = 6
KeyCodeMap[54] = 7
KeyCodeMap[55] = 8
KeyCodeMap[56] = 9
KeyCodeMap[57] = 10

local function unselect()
    if selectedObject then
        selectedObject = nil
        ClientUtil.unSelectTile()
    end
end

local function placeTile(tile, type)

    local requiredResources = Tile.ConstructionCosts[type]
    local stats = ViewStats.CurrentStats

    local canMake = UserStats.hasEnoughResources(stats, requiredResources)

    if canMake then
        Replication.requestTilePlacement(tile, type)
    else
        print("Not enough resources to make a", Tile.Localisation[type])
    end
end

local function processKeyboardInput(input)

    local type = KeyCodeMap[input.KeyCode.Value]

    if type and selectedObject then
        placeTile(selectedObject, type)
    end
end

local function processInput(input, processed)

    if processed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        selectedObject = ClientUtil.selectTileAtMouse()
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        unselect()
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        processKeyboardInput(input)
    end
end

UIS.InputBegan:Connect(processInput)

return TilePlacement