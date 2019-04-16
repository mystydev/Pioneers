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