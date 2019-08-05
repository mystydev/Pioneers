local ui     = script.Parent.Parent
local Roact  = require(game.ReplicatedStorage.Roact)
local Common = game.ReplicatedStorage.Pioneers.Common
local Client = ui.Parent

local Tile          = require(Common.Tile)
local Replication   = require(Client.Replication)
local SmallResourceLabel = require(ui.common.SmallResourceLabel)
local RepairButton = Roact.Component:extend("RepairButton")

local costBinding, costUpdate = Roact.createBinding(nil)

function RepairButton:init()
    
end

function RepairButton:render()

    local children = {}

    local tile = self.props.tile:getValue()
    local repairAmount = 1 - (tile.Health / tile.MHealth)
    local repairCost = Tile.ConstructionCosts[tile.Type]

    costUpdate({Wood = math.floor(repairCost.Wood * repairAmount), Stone = math.floor(repairCost.Stone * repairAmount)})

    children.woodLabel = Roact.createElement(SmallResourceLabel, {
        Type = "Wood",
        Position = UDim2.new(0, 80, 0.5, 20),
        Value = costBinding,
    })


    children.stoneLabel = Roact.createElement(SmallResourceLabel, {
        Type = "Stone",
        Position = UDim2.new(0, 175, 0.5, 20),
        Value = costBinding,
    })

    return Roact.createElement("ImageButton", {
        Name                   = "RepairButton",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 60, 1, -103),
        Size                   = UDim2.new(0, 79, 0, 86),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = "rbxassetid://3571486260",
        [Roact.Event.MouseButton1Click] = function() Replication.requestTileRepair(tile) end,
    }, children)
end

return RepairButton