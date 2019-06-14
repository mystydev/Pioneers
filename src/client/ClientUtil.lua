local ClientUtil = {}

local camera = Workspace.CurrentCamera

local viewDistance = 15

function ClientUtil.getPlayerPosition()
    return camera.CFrame.Position
end

function ClientUtil.getCurrentViewDistance()
    return viewDistance
end

return ClientUtil