local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local AgreeButton = require(ui.AgreeButton)
local CheckBox    = require(ui.CheckBox)
local Label       = require(ui.Label)

local approved = {id = "rbxassetid://3136926314", size = UDim2.new(0, 492, 0, 534)}
local declined = {id = "rbxassetid://3136873518", size = UDim2.new(0, 492, 0, 185)}

local function TesterAlert(props)

    elements = {}

    if props.Approved then
        elements.agreeButton = Roact.createElement(AgreeButton, {
            Position = UDim2.new(1, -155, 1, -115),
            Clicked = props.Clicked,
        })
    end

    elements.checkBox = Roact.createElement(CheckBox, {
        Position = UDim2.new(0, 65, 1, -90),
        Clicked = function(checked) print(checked) end,
    })

    elements.checkLabel = Roact.createElement(Label, {
        Position = UDim2.new(0, 65, 1, -115),
        Size     = UDim2.new(0, 200, 0, 50),
        TextTransparency = 0.2,
        Text = "Don't show me this again",
    })

    return Roact.createElement("ImageLabel", {
        Name                   = "TesterAlert",
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = props.Approved and approved.size or declined.size,
        BackgroundTransparency = 1,
        ImageTransparency      = 0.1,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = props.Approved and approved.id or declined.id,
    }, elements)
end

return TesterAlert