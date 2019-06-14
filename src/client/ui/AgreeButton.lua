
local Roact = require(game.ReplicatedStorage.Roact)

local function AgreeButton(props)
    return Roact.createElement("ImageButton", {
        Name                   = "AgreeButton",
        Image                  = "rbxassetid://3137891616",
        BackgroundTransparency = 1,
        Position               = props.Position,
        Size                   = UDim2.new(0,145,0,39),
        [Roact.Event.MouseButton1Click] = props.Clicked,
    })
end

return AgreeButton