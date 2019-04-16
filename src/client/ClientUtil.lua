local ClientUtil = {}

local camera = Workspace.CurrentCamera

function ClientUtil.getPlayerPosition()
    return camera.CFrame.Position
end

return ClientUtil