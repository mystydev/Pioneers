
local Roact = require(game.ReplicatedStorage.Roact)

local function Title(props)
    return Roact.createElement("TextLabel", {
        Name                   = "Title",
        Text                   = props.Title or "Unknown",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 50, 0, 30),
        Size                   = UDim2.new(0,200,0,32),
        Font                   = "SourceSans",
        TextSize               = 36,
        TextColor3             = Color3.fromRGB(61,61,61),
        TextXAlignment = "Left"
    })
end

return Title