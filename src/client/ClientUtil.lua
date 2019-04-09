local ClientUtil = {}

local Client        = script.Parent
local ViewSelection = require(Client.ViewSelection)

local Players = game:GetService("Players")
local player  = Players.LocalPlayer

local camera = Workspace.CurrentCamera

local lastSelected
local selectedObject
local selectedType

function ClientUtil.selectTileAtMouse()
    if selectedType == "Unit" then 
        return end

    local mouse = player:GetMouse()

    if lastSelected then
        ViewSelection.removeInst(lastSelected)
        lastSelected = nil
    end

    local inst = mouse.Target

    if not inst then 
        selectedObject = nil
        return 
    end
    
    local object = ViewWorld.convertInstanceToTile(inst)

    if object then
        lastSelected = inst
        ViewSelection.addInst(inst)

        selectedType = "Tile"

        selectedObject = object
    else
        selectedObject = nil
    end

    return selectedObject
end

function ClientUtil.selectUnitAtMouse()

    if selectedType == "Tile" then 
        return end

    local mouse = player:GetMouse()

    if lastSelected then
        ViewSelection.removeInst(lastSelected)
        lastSelected = nil
    end

    local inst = mouse.Target

    if not inst then 
        selectedObject = nil
        return 
    end
    
    local object = ViewWorld.convertInstanceToUnit(inst)

    if object then
        lastSelected = inst
        ViewSelection.addInst(inst)

        selectedType = "Unit"

        selectedObject = object
    else
        selectedObject = nil
    end

    return selectedObject
end

function ClientUtil.unSelectTile()
    if selectedType == "Tile" then
        ViewSelection.removeInst(lastSelected)
        lastSelected = nil
        selectedType = nil
    end
end

function ClientUtil.unSelectUnit()
    if selectedType == "Unit" then
        ViewSelection.removeInst(lastSelected)
        lastSelected = nil
        selectedType = nil
    end
end

function ClientUtil.init()
    ViewWorld = require(Client.ViewWorld)
end

function ClientUtil.getPlayerPosition()
    return camera.CFrame.Position
end

return ClientUtil