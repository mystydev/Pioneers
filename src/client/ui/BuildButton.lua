local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local BuildList = require(ui.BuildList)

local BuildButton = Roact.Component:extend("BuildButton")

function BuildButton:init(props)
    self:setState(props)
end

function BuildButton:render()
    return Roact.createElement("ImageButton", {
        Name                   = "BuildButton",
        BackgroundTransparency = 1,
        Position               = self.state.Position,
        Size                   = UDim2.new(0,64,0,64),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = "rbxassetid://3064009593",
        HoverImage             = "rbxassetid://3064053551",
        PressedImage           = "rbxassetid://3064053551",
        [Roact.Event.MouseButton1Click] = function() self:setState({buildList = BuildList}) end,
        [Roact.Event.MouseButton2Click] = function() self:setState({buildList = nil}) end, --TODO: Fix this
    }, self.state.buildList)
end

return BuildButton