local ui = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact = require(game.ReplicatedStorage.Roact)

local Title          = require(ui.Title)
local OwnerLabel     = require(ui.OwnerLabel)
local CloseButton    = require(ui.CloseButton)
local DemolishButton = require(ui.DemolishButton)
local HealthBar      = require(ui.HealthBar)
local Label          = require(ui.Label)
local UnitList       = require(ui.UnitList)
local BuildButton    = require(ui.BuildButton)
local UnitActionButton = require(ui.UnitActionButton)

local Tile = require(Common.Tile)
local Unit = require(Common.Unit)
local UserStats = require(Common.UserStats)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function ObjectInfoPanel(props)

    if not props.Obj then
        return Roact.createElement("Frame")
    end

    local elements = {}

    props.Owner = props.Obj.OwnerId

    if not props.Obj.Id then --Tile
        props.Title = Tile.Localisation[props.Obj.Type]

        if props.Obj.Type == Tile.GRASS then
            print(props.stats)
            elements.BuildButton = Roact.createElement(BuildButton, {Position = UDim2.new(-0.098, 0, 0.875, 0), stats = props.stats})
        end

        elements.UnitList = Roact.createElement(UnitList, props)
    else
        props.Title = Unit.Localisation[props.Obj.Type]

        if props.Owner == Player.userId then
            elements.UnitActionButton = Roact.createElement(UnitActionButton, {Position = UDim2.new(-0.098, 0, 0.875, 0)})
        end
    end

    

    elements.Title = Roact.createElement(Title, props)
    elements.Owner = Roact.createElement(OwnerLabel, props)
    elements.CloseButton = Roact.createElement(CloseButton, 
                            {Position = UDim2.new(0.049, 0, 0.852, 0)})
    
    if props.Owner == Player.userId then
        elements.DemolishButton = Roact.createElement(DemolishButton, 
                            {Position = UDim2.new(0.613, 0, 0.852, 0)})
    end

    if props.Obj.Health then
        elements.HealthBar = Roact.createElement(HealthBar, 
                            {Position     = UDim2.new(0.35, 0, 0.82, 0),
                            Size          = UDim2.new(0.5, 0, 0, 8), 
                            HealthPercent = 1,
                            Health        = props.Obj.Health})

        elements.HealthLabel = Roact.createElement(Label, {
                            Text          = "Health",
                            Position      = UDim2.new(0.15, 0, 0.8, -3),
                            TextSize      = 22,
                            Size          = UDim2.new(0, 40, 0, 32)
                            })
    
    end


    return Roact.createElement("ImageLabel", {
        Name                   = "ObjectInfoPanel",
        Position               = UDim2.new(1,0,1,0),
        Size                   = UDim2.new(0, 328, 0, 586),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://3063744675",
        AnchorPoint            = Vector2.new(1,1)
    }, elements)
end

return ObjectInfoPanel