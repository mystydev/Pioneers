
local ui           = script.Parent.Parent
local Roact        = require(game.ReplicatedStorage.Roact)
local Common       = game.ReplicatedStorage.Pioneers.Common
local Client       = ui.Parent
local RunService   = game:GetService("RunService")

local ViewWorld    = require(Client.ViewWorld)
local Replication  = require(Client.Replication)
local UnitControl  = require(Client.UnitControl)
local Util         = require(Common.Util)
local Tile         = require(Common.Tile)
local UnitSpot  = Roact.Component:extend("UnitSpot")
local camera = workspace.CurrentCamera

local function leftClicked(node)
    if node.type == "F" then
        node.type = false
        node.walkable = true
        node.inCombat = false
    else
        node.type = "F"
    end

    UnitControl.evalCombatLinks()
end

local function rightClicked(node)
    if node.type == "H" then
        node.type = false
        node.walkable = true
        node.inCombat = false
    else
        node.type = "H"
    end
    
    UnitControl.evalCombatLinks()
end

function UnitSpot:init()
    self:setState({
        displayedType = false,
    })
end

function UnitSpot:render()

    if not self.props.node.walkable then
        return end

    local color = Color3.new(1, 1, 1)
    local transparency = 0.8

    if self.props.node.type == "F" then
        color = Color3.new(0.2, 0.2, 0.8)
        transparency = 0
    elseif self.props.node.type == "H" then
        color = Color3.new(0.8, 0.2, 0.2)
        transparency = 0
    end

    return Roact.createElement("BillboardGui", {
        Adornee = self.props.node.attachment,
        Size = UDim2.new(2, 0, 2, 0),
        AlwaysOnTop = true,
        Active = true,
    }, {
        button = Roact.createElement("ImageButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ImageColor3 = color,
            Image = "rbxassetid://4579670009",
            ImageTransparency = transparency,
            [Roact.Event.MouseButton1Click] = function() leftClicked(self.props.node) end,
            [Roact.Event.MouseButton2Click] = function() rightClicked(self.props.node) end,
        }, {
            depthLabel = Roact.createElement("TextLabel", {
                BackgroundTransparency = 1,
                Text = "",--self.state.depth or "",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(1, 0, 1, 0),
                TextScaled = true,
            })
        })
    })
end

function UnitSpot:didMount()
    self.running = true

    spawn(function()
        while self.running do
            if self.state.displayedType ~= (self.props.node.type or false) then
                self:setState({
                    displayedType = self.props.node.type
                })
            end

            if self.state.depth ~= (self.props.node.depth or false) then
                self:setState({
                    depth = self.props.node.depth or false
                })
            end

            wait(0.1)
        end
    end)
end

function UnitSpot:willUnmount()
    --[[if self.event then
        self.event:Disconnect()
        self.event = nil
    end]]--
    self.running = false
end

return UnitSpot


