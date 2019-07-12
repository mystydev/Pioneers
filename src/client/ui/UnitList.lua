local ui = script.Parent
local Client = ui.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local ViewUnit = require(Client.ViewUnit)
local UnitInfoLabel = require(ui.UnitInfoLabel)

local RunService = game:GetService("RunService")

local UnitList = Roact.Component:extend("UnitInfoLabel")

local infotable

function UnitList:init()
end

function UnitList:render()
   

    local list = self.props.object and self.props.object.UnitList or {}
    local units = ViewUnit.convertIdListToUnits(list)

    local unitLabels = {}

    for i, unit in pairs(units) do
        table.insert(unitLabels, Roact.createElement(UnitInfoLabel, {
                                    Position = UDim2.new(0.5, 0, 0, 42 * i),
                                    Unit = unit,
                                    SetObject = self.props.SetObject,
        }))
    end

    return Roact.createElement("Frame", {
        Name = "UnitList",
        BackgroundTransparency = 1,
        Position = self.props.Position or UDim2.new(0.146, 0, 0.4, 0),
        Size = UDim2.new(0, 239, 0, 73),
    }, unitLabels)
end

function UnitList:didMount()
    self.running = true

    --spawn(function()
    --    while self.running do
    --        self:setState(infotable)
    --        RunService.Stepped:Wait()
    --    end
    --end)
end

function UnitList:willUnmount()
    self.running = false
end

return UnitList