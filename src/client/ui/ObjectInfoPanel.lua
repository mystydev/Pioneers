local ui = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact = require(game.ReplicatedStorage.Roact)

local Title          = require(ui.Title)
local OwnerLabel     = require(ui.OwnerLabel)
local CloseButton    = require(ui.CloseButton)
local DemolishButton = require(ui.DemolishButton)
local StatusBar      = require(ui.StatusBar)
local Label          = require(ui.Label)
local UnitList       = require(ui.UnitList)
local BuildButton    = require(ui.BuildButton)
local UnitActionButton = require(ui.UnitActionButton)
local UnitInfoLabel  = require(ui.UnitInfoLabel)

local Tile = require(Common.Tile)
local Unit = require(Common.Unit)
local UserStats = require(Common.UserStats)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local ObjectInfoPanel = Roact.Component:extend("ObjectInfoPanel")

local infoTable

function ObjectInfoPanel:init(props)
    infoTable = props.info
    self:setState(props.info)
end

function ObjectInfoPanel:render()

    local state = self.state

    if not state.Obj then
        return Roact.createElement("Frame")
    end

    local elements = {}

    state.Owner = state.Obj.OwnerId

    if not state.Obj.Id then --Tile
        state.Title = Tile.Localisation[state.Obj.Type]

        if state.Obj.Type == Tile.GRASS then
            elements.BuildButton = Roact.createElement(BuildButton, {Position = UDim2.new(-0.098, 0, 0.875, 0), stats = state.stats})
        end

        elements.UnitList = Roact.createElement(UnitList, {info = infoTable})
    else
        state.Title = Unit.Localisation[state.Obj.Type]

        if state.Owner == Player.userId then
            elements.UnitActionButton = Roact.createElement(UnitActionButton, {Position = UDim2.new(-0.098, 0, 0.875, 0)})
        end

        elements.UnitStatus = Roact.createElement(UnitInfoLabel, {
            Position = UDim2.new(0.5, 0, 0.38, 42),
            IsUnit = true,
            Unit = state.Obj,
            Interest = UnitInfoLabel.Interests.STATUS,
        })

        elements.UnitCarry = Roact.createElement(UnitInfoLabel, {
            Position = UDim2.new(0.5, 0, 0.38, 42 * 2),
            IsUnit = true,
            Unit = state.Obj,
            Interest = UnitInfoLabel.Interests.CARRYING,
        })


    end

    

    elements.Title = Roact.createElement(Title, state)
    elements.Owner = Roact.createElement(OwnerLabel, state)
    elements.CloseButton = Roact.createElement(CloseButton, 
                            {Position = UDim2.new(0.049, 0, 0.852, 0)})
    
    if state.Owner == Player.userId then
        elements.DemolishButton = Roact.createElement(DemolishButton, 
                            {Position = UDim2.new(0.613, 0, 0.852, 0),
                            Obj = state.Obj})
    end

    if state.Obj.Health then
        elements.HealthBar = Roact.createElement(StatusBar, 
                            {Position     = UDim2.new(0.35, 0, 0.25, 0),
                            Size          = UDim2.new(0.5, 0, 0, 8), 
                            ValPercent    = state.Obj.Health / state.Obj.MHealth,
                            Value         = state.Obj.Health,
                            StartCol      = Color3.fromRGB(84, 194, 66),
                            MidCol        = Color3.fromHSV(0.0587, 1.0000, 0.9020),
                            EndCol        = Color3.fromHSV(0.3405, 0.5812, 0.6275)})

        elements.HealthLabel = Roact.createElement(Label, {
                            Text          = "Health",
                            Position      = UDim2.new(0.15, 0, 0.23, -3),
                            TextSize      = 22,
                            Size          = UDim2.new(0, 40, 0, 32)
                            })
    end

    if state.Obj.Fatigue then
        elements.FatigueBar = Roact.createElement(StatusBar, 
                            {Position     = UDim2.new(0.35, 0, 0.31, 0),
                            Size          = UDim2.new(0.5, 0, 0, 8), 
                            ValPercent    = state.Obj.Fatigue / state.Obj.MFatigue,
                            Value         = state.Obj.Fatigue,
                            StartCol      = Color3.fromRGB(245, 164, 77),
                            MidCol        = Color3.fromHSV(0.0587, 1.0000, 0.9020),
                            EndCol        = Color3.fromHSV(0.0587, 1.0000, 0.9020)})

        elements.FatigueLabel = Roact.createElement(Label, {
                            Text          = "Fatigue",
                            Position      = UDim2.new(0.15, 0, 0.29, -3),
                            TextSize      = 22,
                            Size          = UDim2.new(0, 40, 0, 32)
                            })
    end

    if state.Obj.Training then
        elements.TrainingBar = Roact.createElement(StatusBar, 
                            {Position     = UDim2.new(0.35, 0, 0.37, 0),
                            Size          = UDim2.new(0.5, 0, 0, 8), 
                            ValPercent    = state.Obj.Training / state.Obj.MTraining,
                            Value         = state.Obj.Training,
                            StartCol      = Color3.fromRGB(100, 181, 246),
                            MidCol        = Color3.fromHSV(0.5189, 1.0000, 0.8314),
                            EndCol        = Color3.fromHSV(0.7154, 0.7321, 0.6588)})

        elements.TrainingLabel = Roact.createElement(Label, {
                            Text          = "Training",
                            Position      = UDim2.new(0.15, 0, 0.35, -3),
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

function ObjectInfoPanel:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState(infoTable)
            RunService.Stepped:Wait()
        end
    end)
end

function ObjectInfoPanel:willUnmount()
    self.running = false
end

return ObjectInfoPanel