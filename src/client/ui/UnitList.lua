local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local UnitInfoLabel = require(ui.UnitInfoLabel)

local RunService = game:GetService("RunService")

local UnitList = Roact.Component:extend("UnitInfoLabel")

local infotable

function UnitList:init(props)
    infotable = props.info
    self:setState(props.info)
end

function UnitList:render()
    local units = {}
    local state = self.state

    local unitlist = state.Obj and state.Obj.unitlist or {}

    for _, unit in pairs(unitlist) do
        table.insert(units, state.World.Units[unit])
    end

    local unitLabels = {}

    for i, unit in pairs(units) do
        table.insert(unitLabels, Roact.createElement(UnitInfoLabel, {
                                    Position = UDim2.new(0.5, 0, 0, 42 * i),
                                    Unit = unit,
        }))
    end

    return Roact.createElement("Frame", {
        Name = "UnitList",
        BackgroundTransparency = 1,
        Position = state.Position or UDim2.new(0.146, 0, 0.4, 0),
        Size = UDim2.new(0, 239, 0, 73),
    }, unitLabels)
end

function UnitList:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState(infotable)
            RunService.Stepped:Wait()
        end
    end)
end

function UnitList.getDerivedStateFromProps(nextProps, lastState)
    return nextProps
end

function UnitList:willUnmount()
    self.running = false
end

return UnitList