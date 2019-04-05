local TilePlacement = {}

local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local ViewWorld = require(Client.ViewWorld)
local ViewTile  = require(Client.ViewTile)
local ViewStats = require(Client.ViewStats)
local Tile      = require(Common.Tile)
local UserStats = require(Common.UserStats)
local Replication = require(Client.Replication)

local HIGHLIGHT_MATERIAL = "Neon"
local lastSelected
local lastMaterial

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

local function selectObjectAtMouse()
    local mouse = game.Players.LocalPlayer:GetMouse()

    if lastSelected then
        lastSelected.Material = lastMaterial
    end

    local inst = mouse.Target

    if not inst then return end

    local object = ViewWorld.convertInstanceToObject(inst)

    if object then
        lastSelected = inst
        lastMaterial = inst.Material  
        inst.Material = HIGHLIGHT_MATERIAL

        selectedObject = object
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
        selectObjectAtMouse()
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        processKeyboardInput(input)
    end
end


local UIS = game:GetService("UserInputService")

UIS.InputBegan:Connect(processInput)


return TilePlacement