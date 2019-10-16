local Client = script.Parent.Parent.Parent
local ui     = Client.ui
local Roact  = require(game.ReplicatedStorage.Roact)

local Replication           = require(Client.Replication)
local DefaultFrame          = require(ui.common.DefaultFrame)
local Title                 = require(ui.Title)
local PartitionVisualistion = require(ui.partitionOverview.PartitionVisualistion)

local PartitionView = Roact.Component:extend("PartitionView")


function PartitionView:init()

end


function PartitionView:render()


    local partitionOverview = Replication.getPartitionOwnership(x, y)
    local ownershipMap = partitionOverview.owner
    local keepMap = partitionOverview.keep

    return Roact.createElement("Frame", {
        Name = "PartitionView",
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(85, 139, 47),
        ZIndex = 0,
    }, {

        titleBox = Roact.createElement(DefaultFrame, {
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(0, 450, 0, 120),
            Position = UDim2.new(0.5, 0, 0, -50),
            ImageTransparency = 0.2,

            }, {

            titleText = Roact.createElement(Title, {
                Title = "World Overview",
                Position = UDim2.new(0.5, 0, 0.5, 15),
                AnchorPoint = Vector2.new(0.5, 0.5),
                TextXAlignment = "Center",
                TextSize = 48,
            })

        }),
        
        visualisation = Roact.createElement(PartitionVisualistion, {
            PartitionMap = ownershipMap,
            KeepMap = keepMap,
        })
    })
end



return PartitionView