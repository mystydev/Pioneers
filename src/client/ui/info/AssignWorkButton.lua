local ui     = script.Parent.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact  = require(game.ReplicatedStorage.Roact)

local Tile = require(Common.Tile)

local AssignWorkButton = Roact.Component:extend("AssignWorkButton")


local infoTable = {}
infoTable[Tile.FARM] = {Image = "rbxassetid://3480804371", Position = UDim2.new(0, 60, 1, -103), Size = UDim2.new(0, 102, 0, 108)}
infoTable[Tile.FORESTRY] = {Image = "rbxassetid://3480804449", Position = UDim2.new(0, 125, 1, -100), Size = UDim2.new(0, 107, 0, 107)}
infoTable[Tile.MINE] = {Image = "rbxassetid://3480804524", Position = UDim2.new(0, 190, 1, -105), Size = UDim2.new(0, 85, 0, 85)}
infoTable[Tile.BARRACKS] = {Image = "rbxassetid://3480808137", Position = UDim2.new(0, 260, 1, -100), Size = UDim2.new(0, 73, 0, 73)}
infoTable[Tile.OTHERPLAYER] = {Image = "rbxassetid://3480804202", Position = UDim2.new(0, 60, 1, -100), Size = UDim2.new(0, 80, 0, 80)}
infoTable[Tile.GRASS] = {Image = "rbxassetid://3480804296", Position = UDim2.new(0, 170, 1, -100), Size = UDim2.new(0, 82, 0, 82)}

function AssignWorkButton:onClick()
    if self.props.Unit then
        self.props.UIBase.promptSelectWork(self.props.Type, self.props.Unit.Position)
    else
        self.props.UIBase.promptSelectWork(self.props.Type)
    end
end

function AssignWorkButton:init()
    
end

function AssignWorkButton:render()
    return Roact.createElement("ImageButton", {
        Name                   = "AssignWorkButton",
        BackgroundTransparency = 1,
        Position               = infoTable[self.props.Type].Position,
        Size                   = infoTable[self.props.Type].Size,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = infoTable[self.props.Type].Image,
        [Roact.Event.MouseButton1Click] = function() self:onClick() end,
    })
end

return AssignWorkButton