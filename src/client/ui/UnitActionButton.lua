local Client = script.Parent.Parent
local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)
local Common = game.ReplicatedStorage.Pioneers.Common

local SoundManager = require(Client.SoundManager)
local World = require(Common.World)
local ActionList = require(ui.ActionList)

local UnitActionButton = Roact.Component:extend("UnitActionButton")

function UnitActionButton:init(props)
    self:setState({
        clicked = false
    })
end

function UnitActionButton:render()

    local children = {}

    if self.state.clicked then
        for index, action in pairs(World.UnitActions) do 
            table.insert(children, Roact.createElement(ActionList, {
                Type = action, 
                index = index,
                UIBase = self.props.UIBase,
            }))
        end
    end

    return Roact.createElement("ImageButton", {
        Name                   = "UnitActionButton",
        BackgroundTransparency = 1,
        Position               = self.props.Position,
        Size                   = UDim2.new(0,64,0,64),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = "rbxassetid://3077218297",
        HoverImage             = "rbxassetid://3077212059",
        PressedImage           = "rbxassetid://3077212059",
        [Roact.Event.MouseButton1Click] = function() SoundManager.menuClick() self:setState({clicked = true}) end,
        [Roact.Event.MouseEnter] = SoundManager.rollover
    }, children)
end

return UnitActionButton