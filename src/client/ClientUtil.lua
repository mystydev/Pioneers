local ClientUtil = {}
local Common = game.ReplicatedStorage.Pioneers.Common

local Util = require(Common.Util)
local Players = game:GetService("Players")

local camera = Workspace.CurrentCamera

local viewDistance = 30

function ClientUtil.getPlayerPosition()
    local char = Players.LocalPlayer.Character

    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart.Position
    else
        return camera.CFrame.Position
    end
end

function ClientUtil.getCurrentViewDistance()
    return viewDistance
end

function ClientUtil.getTilePositionUnderPlayer()
    local char = Players.LocalPlayer.Character

    if not (char and char:FindFirstChild("HumanoidRootPart")) then
        return end
    
    local position = char.HumanoidRootPart.Position
    return Util.worldCoordToAxialCoord(position)
end

return ClientUtil