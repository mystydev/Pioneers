local ui = script.Parent.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact = require(game.ReplicatedStorage.Roact)

local Title            = require(ui.Title)
local OwnerLabel       = require(ui.OwnerLabel)
local CloseButton      = require(ui.CloseButton)
local DemolishButton   = require(ui.DemolishButton)
local StatusBar        = require(ui.StatusBar)
local Label            = require(ui.Label)
local UnitList         = require(ui.UnitList)
local BuildButton      = require(ui.BuildButton)
local UnitInfoLabel    = require(ui.UnitInfoLabel)
local AssignWorkButton = require(ui.info.AssignWorkButton)

local Tile = require(Common.Tile)
local Unit = require(Common.Unit)
local UserStats = require(Common.UserStats)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local ObjectInfoPanel = Roact.Component:extend("ObjectInfoPanel")

local infoTable

function ObjectInfoPanel:init()
    self:setState({
        object = nil,
    })
end

function ObjectInfoPanel:render()

    local state = self.state

    if not state.object then
        return Roact.createElement("Frame")
    end

    local elements = {}

    state.Owner = state.object.OwnerId

    if not state.object.Id then --Tile
        state.Title = Tile.Localisation[state.object.Type]
        elements.UnitList = Roact.createElement(UnitList, {object = state.object, SetObject = self.props.SetObject})
    else
        state.Title = Unit.Localisation[state.object.Type]
        
        if state.Owner == Player.userId then
            if not Unit.isMilitary(state.object) then
                elements.FarmWork = Roact.createElement(AssignWorkButton, {Type = Tile.FARM, UIBase = self.props.UIBase})
                elements.ForestryWork = Roact.createElement(AssignWorkButton, {Type = Tile.FORESTRY, UIBase = self.props.UIBase})
                elements.MineWork = Roact.createElement(AssignWorkButton, {Type = Tile.MINE, UIBase = self.props.UIBase})
            else
                elements.AttackWork = Roact.createElement(AssignWorkButton, {Type = Tile.OTHERPLAYER, UIBase = self.props.UIBase})
                elements.GuardWork = Roact.createElement(AssignWorkButton, {Type = Tile.GRASS, UIBase = self.props.UIBase})
            end

            elements.TrainingWork = Roact.createElement(AssignWorkButton, {Type = Tile.BARRACKS, UIBase = self.props.UIBase})
        end

        elements.UnitStatus = Roact.createElement(UnitInfoLabel, {
            Position = UDim2.new(0.5, 0, 0.38, 42),
            IsUnit = true,
            Unit = state.object,
            Interest = UnitInfoLabel.Interests.STATUS,
        })

        elements.UnitCarry = Roact.createElement(UnitInfoLabel, {
            Position = UDim2.new(0.5, 0, 0.38, 42 * 2),
            IsUnit = true,
            Unit = state.object,
            Interest = UnitInfoLabel.Interests.CARRYING,
        })
    end

    elements.Title = Roact.createElement(Title, state)
    elements.Owner = Roact.createElement(OwnerLabel, state)
    elements.CloseButton = Roact.createElement(CloseButton, 
                            {Position = UDim2.new(0.04, 0, 0.865, 0)})
    
    if state.Owner == Player.userId then
        elements.DemolishButton = Roact.createElement(DemolishButton, 
                            {Position = UDim2.new(0.65, 0, 0.865, 0),
                            Obj = state.object,
                            UIBase = self.props.UIBase})
    end

    if state.object.Health then
        elements.HealthBar = Roact.createElement(StatusBar, 
                            {Position     = UDim2.new(0.35, 0, 0.25, 0),
                            Size          = UDim2.new(0.5, 0, 0, 8), 
                            ValPercent    = state.object.Health / state.object.MHealth,
                            Value         = state.object.Health,
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

    if state.object.Fatigue then
        elements.FatigueBar = Roact.createElement(StatusBar, 
                            {Position     = UDim2.new(0.35, 0, 0.31, 0),
                            Size          = UDim2.new(0.5, 0, 0, 8), 
                            ValPercent    = state.object.Fatigue / state.object.MFatigue,
                            Value         = state.object.Fatigue,
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

    if state.object.Training then
        elements.TrainingBar = Roact.createElement(StatusBar, 
                            {Position     = UDim2.new(0.35, 0, 0.37, 0),
                            Size          = UDim2.new(0.5, 0, 0, 8), 
                            ValPercent    = state.object.Training / state.object.MTraining,
                            Value         = state.object.Training,
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
        Position               = UDim2.new(1,-10,1,-10),
        Size                   = UDim2.new(0, 326, 0, 521),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://3480808269",
        AnchorPoint            = Vector2.new(1,1)
    }, elements)
end

function ObjectInfoPanel:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState({
                object = self.props.InfoObject:getValue()
            })

            RunService.Heartbeat:Wait()
        end
    end)
end

function ObjectInfoPanel:willUnmount()
    self.running = false
end

return ObjectInfoPanel