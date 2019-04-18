local ClientUtil = {}

local camera = Workspace.CurrentCamera

local viewDistance = 25

function ClientUtil.getPlayerPosition()
    return camera.CFrame.Position
end

function ClientUtil.getCurrentViewDistance()
    return viewDistance
end

return ClientUtil