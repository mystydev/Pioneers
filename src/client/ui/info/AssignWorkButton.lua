local ui     = script.Parent.Parent
local Client = ui.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local Roact  = require(game.ReplicatedStorage.Roact)

local Util          = require(Common.Util)
local Tile          = require(Common.Tile)
local ActionHandler = require(Client.ActionHandler)
local SoundManager  = require(Client.SoundManager)

local TweenService = game:GetService("TweenService")
local AssignWorkButton = Roact.Component:extend("AssignWorkButton")

local quick = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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

function AssignWorkButton:onEnter()
    SoundManager.rollover()
    TweenService:Create(self.state.ref:getValue(), quick, {ImageTransparency = 0}):Play()
end

function AssignWorkButton:onLeave()
    TweenService:Create(self.state.ref:getValue(), quick, {ImageTransparency = 0.5}):Play()
end

function AssignWorkButton:init()
    self:setState({
        ref = Roact.createRef(),
    })
end

function AssignWorkButton:render()

    local children = {}
    local isWorking = self.props.Unit and Util.worksOnTileType(self.props.Unit.Type, self.props.Type)

    if isWorking then
        children.dismiss = Roact.createElement("ImageButton", {
            Name                   = "DismissWork",
            BackgroundTransparency = 1,
            Position               = UDim2.new(0.5, 0, 0.5, 0),
            Size                   = UDim2.new(0, 60, 0, 60),
            AnchorPoint            = Vector2.new(0.5, 0.5),
            Image                  = "rbxassetid://3616348293",
            ImageTransparency      = 0.5,
            [Roact.Event.MouseButton1Click] = function() ActionHandler.assignWork(self.props.Unit, nil) end,
            [Roact.Ref] = self.state.ref,
        })
    end

    return Roact.createElement("ImageButton", {
        Name                   = "AssignWorkButton",
        BackgroundTransparency = 1,
        Position               = infoTable[self.props.Type].Position,
        Size                   = infoTable[self.props.Type].Size,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = infoTable[self.props.Type].Image,
        ImageTransparency      = isWorking and 0 or 0.5,
        [Roact.Event.MouseButton1Click] = function() self:onClick() end,
        [Roact.Event.MouseEnter] = function() self:onEnter() end,
        [Roact.Event.MouseLeave] = function() self:onLeave() end,
        [Roact.Ref] = not isWorking and self.state.ref or nil,
    }, children)
end

return AssignWorkButton