
local ui           = script.Parent.Parent
local Roact        = require(game.ReplicatedStorage.Roact)
local Common       = game.ReplicatedStorage.Pioneers.Common
local Client       = ui.Parent
local RunService   = game:GetService("RunService")

local ViewWorld    = require(Client.ViewWorld)
local TileMarker  = Roact.Component:extend("TileMarker")

function TileMarker:init()
end

function TileMarker:render()

    local children = {}

    local inst = self.props.inst:getValue()

    if not inst then return end

    children.Marker = Roact.createElement("ImageLabel", {
        Name                   = "TileMarker",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(1, 0, 1, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = "rbxassetid://4486323066",
        ImageTransparency      = 0,
    })
    
    return Roact.createElement("BillboardGui", {
        Adornee = inst,
        Size = UDim2.new(10, 0, 10, 0),
        AlwaysOnTop = true,
    }, children)
end

function TileMarker:didMount()
end

function TileMarker:willUnmount()
end

return TileMarker


