local ClientUtil = {}

local Client        = script.Parent
local ViewSelection

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player  = Players.LocalPlayer

local camera = Workspace.CurrentCamera
local floor = math.floor

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
        ViewSelection.displayTileInfo(object)
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

function ClientUtil.selectUnit(unit) --TODO: THIS IS HORRIFIC!
    selectedObject = unit
    selectedType = "Unit"
end

function ClientUtil.unSelectTile()
   -- if selectedType == "Tile" then
        ViewSelection.removeInst(lastSelected)
        lastSelected = nil
        selectedType = nil
    --end
end

function ClientUtil.unSelectUnit()
    --if selectedType == "Unit" then
        ViewSelection.removeInst(lastSelected)
        lastSelected = nil
        selectedType = nil
    --end
end

function ClientUtil.init()
    ViewWorld = require(Client.ViewWorld)
    ViewSelection = require(Client.ViewSelection)
end

--Tweens the numbers showing in a text label
local managedLabels = {}
function ClientUtil.tweenLabelValue(label, newval)

    if managedLabels[label]  then
        managedLabels[label] = newval or 0
    else
        managedLabels[label] = newval or 0

        spawn(function()
            local currentVal = tonumber(label.Text) or 0

            repeat
                currentVal = currentVal + (managedLabels[label] - currentVal)*0.1
                label.Text = tostring(floor(currentVal + 0.5))
                
                RunService.Stepped:Wait()
                
            until not managedLabels[label]
        end)
    end
end

function ClientUtil.getPlayerPosition()
    return camera.CFrame.Position
end

return ClientUtil