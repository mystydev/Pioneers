local ClientUtil = {}

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

return ClientUtil