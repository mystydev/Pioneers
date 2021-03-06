local ui = script.Parent
local Client = ui.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local SoundManager = require(Client.SoundManager)
local AgreeButton = require(ui.AgreeButton)
local CheckBox    = require(ui.CheckBox)
local Label       = require(ui.Label)

local approved = {id = "rbxassetid://3137922987", size = UDim2.new(0, 492, 0, 540)}
local declined = {id = "rbxassetid://3137923052", size = UDim2.new(0, 492, 0, 191)}

local showWarning = true

local function TesterAlert(props)
    SoundManager.urgentAlert()
    elements = {}

    if props.Approved then
        elements.agreeButton = Roact.createElement(AgreeButton, {
            Position = UDim2.new(1, -210, 1, -110),
            Clicked = function() props.Clicked(showWarning) end,
        })

        elements.checkBox = Roact.createElement(CheckBox, {
            Position = UDim2.new(0, 65, 1, -90),
            Clicked = function(checked) showWarning = not checked end,
        })

        elements.checkLabel = Roact.createElement(Label, {
            Position = UDim2.new(0, 65, 1, -115),
            Size     = UDim2.new(0, 200, 0, 50),
            TextTransparency = 0.2,
            Text = "Don't show me this again",
            AnchorPoint = Vector2.new(0, 0),
        })
    end


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
