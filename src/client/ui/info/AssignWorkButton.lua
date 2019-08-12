local ui     = script.Parent.Parent
local Client = ui.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact  = require(game.ReplicatedStorage.Roact)

local Util          = require(Common.Util)
local Tile          = require(Common.Tile)
local ActionHandler = require(Client.ActionHandler)

local AssignWorkButton = Roact.Component:extend("AssignWorkButton")


local infoTable = {}
infoTable[Tile.FARM]        = {Image = "rbxassetid://3480804371", Position = UDim2.new(0, 60, 1, -103), Size = UDim2.new(0, 102, 0, 108)}
infoTable[Tile.FORESTRY]    = {Image = "rbxassetid://3480804449", Position = UDim2.new(0, 125, 1, -100), Size = UDim2.new(0, 107, 0, 107)}
infoTable[Tile.MINE]        = {Image = "rbxassetid://3480804524", Position = UDim2.new(0, 190, 1, -105), Size = UDim2.new(0, 85, 0, 85)}
infoTable[Tile.BARRACKS]    = {Image = "rbxassetid://3480808137", Position = UDim2.new(0, 260, 1, -100), Size = UDim2.new(0, 73, 0, 73)}
infoTable[Tile.OTHERPLAYER] = {Image = "rbxassetid://3480804202", Position = UDim2.new(0, 60, 1, -100), Size = UDim2.new(0, 80, 0, 80)}
infoTable[Tile.GRASS]       = {Image = "rbxassetid://3480804296", Position = UDim2.new(0, 170, 1, -100), Size = UDim2.new(0, 82, 0, 82)}

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

    local children = {}
    if self.props.Unit and Util.worksOnTileType(self.props.Unit.Type, self.props.Type) then
        children.dismiss = Roact.createElement("ImageButton", {
            Name                   = "DismissWork",
            BackgroundTransparency = 1,
            Position               = UDim2.new(0.5, 0, 0.5, 0),
            Size                   = UDim2.new(0, 60, 0, 60),
            AnchorPoint            = Vector2.new(0.5, 0.5),
            Image                  = "rbxassetid://3616348293",
            [Roact.Event.MouseButton1Click] = function() ActionHandler.assignWork(self.props.Unit, nil) end,
        })
    end

    return Roact.createElement("ImageButton", {
        Name                   = "AssignWorkButton",
        BackgroundTransparency = 1,
        Position               = infoTable[self.props.Type].Position,
        Size                   = infoTable[self.props.Type].Size,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = infoTable[self.props.Type].Image,
        [Roact.Event.MouseButton1Click] = function() self:onClick() end,
    }, children)
end

return AssignWorkButton