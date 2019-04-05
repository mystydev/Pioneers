local UnitController = {}


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

local function selectObjectAtMouse()
    local mouse = game.Players.LocalPlayer:GetMouse()

    if lastSelected then
        lastSelected.Material = lastMaterial
    end

    local inst = mouse.Target

    if not inst then 
        selectedObject = nil
        return 
    end

    local object = ViewWorld.convertInstanceToUnit(inst)

    if object then
        lastSelected = inst
        lastMaterial = inst.Material  
        inst.Material = HIGHLIGHT_MATERIAL

        selectedObject = object
    else
        selectedObject = nil
    end
end

local function findTileAtMouse()
    local mouse = game.Players.LocalPlayer:GetMouse()

    local inst = mouse.Target

    if not inst then 
        return 
    end

    local object = ViewWorld.convertInstanceToTile(inst)

    if object then
        return object
    end
end

local function processKeyboardInput(input)

    if not selectedObject then
        return end

    if (input.KeyCode == Enum.KeyCode.H) then
        Replication.requestUnitHome(selectedObject, findTileAtMouse())
    elseif (input.KeyCode == Enum.KeyCode.J) then
        Replication.requestUnitWork(selectedObject, findTileAtMouse())
    elseif (input.KeyCode == Enum.KeyCode.K) then
        Replication.requestUnitTarget(selectedObject, findTileAtMouse())
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


return UnitController