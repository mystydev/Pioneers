local Roact = require(game.ReplicatedStorage.Roact)

function DefaultFrame(props)
    return Roact.createElement("ImageLabel", {
        BackgroundTransparency = 1,
        Position               = props.Position or UDim2.new(0, 0, 0, 0),
        Size                   = props.Size or UDim2.new(1, 0, 1, 0),
        AnchorPoint            = props.AnchorPoint or Vector2.new(0, 0),
        ImageColor3            = props.ImageColor3 or Color3.new(1,1,1),
        ImageTransparency      = props.ImageTransparency or 0.8,
        ScaleType              = "Slice",
        SliceCenter            = Rect.new(30, 30, 50, 50),
    })
end

return DefaultFrame