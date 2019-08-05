local ClientUtil = {}

local camera = Workspace.CurrentCamera

local viewDistance = 30

function ClientUtil.getPlayerPosition()
    return camera.CFrame.Position
end

function ClientUtil.getCurrentViewDistance()
    return viewDistance
end

return ClientUtil