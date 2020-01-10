
local ui           = script.Parent.Parent
local Roact        = require(game.ReplicatedStorage.Roact)
local Common       = game.ReplicatedStorage.Pioneers.Common
local Client       = ui.Parent
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")

local ViewWorld    = require(Client.ViewWorld)
local Replication  = require(Client.Replication)
local UnitControl  = require(Client.UnitControl)
local Util         = require(Common.Util)
local Tile         = require(Common.Tile)
local UnitSpot  = Roact.PureComponent:extend("UnitSpot")
local camera = workspace.CurrentCamera

local Player = Players.LocalPlayer

local function leftClicked(node)
    if node.type == "F" then
        node.type = false
        node.walkable = true
        node.inCombat = false
    else
        node.type = "F"
    end

    --UnitControl.evalCombatLinks()
end

local function rightClicked(node)
    if node.type == "H" then
        node.type = false
        node.walkable = true
        node.inCombat = false
    else
        node.type = "H"
    end
    
    --UnitControl.evalCombatLinks()
end

function UnitSpot:init()
    self:setState({
        displayedType = false,
        mouseDist = 100,
        billboardRef = Roact.createRef(),
        imageRef = Roact.createRef(),
    })
end

function UnitSpot:render()

    if not self.props.node.walkable then
        return 
    end

    local color = Color3.new(1, 1, 1)
    local image = "rbxassetid://4579670009"
    local size = UDim2.new(3, 0, 3, 0)

    if self.props.type == "F" then
        image = "rbxassetid://3480804296"
        size = UDim2.new(10, 0, 10, 0)
    end

    return Roact.createElement("BillboardGui", {
        Adornee = self.props.node.attachment,
        Size = size,
        AlwaysOnTop = true,
        Active = true,
        [Roact.Ref] = self.state.billboardRef,
    }, {
        button = Roact.createElement("ImageButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ImageColor3 = color,
            Image = image,
            ImageTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            [Roact.Ref] = self.state.imageRef,
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

    if self.event then return end

    local enabled = false

    self.event = RunService.Stepped:Connect(function()
        debug.profilebegin("unitspot")
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

    
        local image = self.state.imageRef:getValue()
        local billboard = self.state.billboardRef:getValue()
    
        if not image or not billboard then
            debug.profileend()
            return
        end
        
        local dist = (self.props.mousePosition:getValue() - self.props.node.worldPosition).magnitude
        local transparency = math.clamp((dist-5)/20, 0, 1)

        if self.props.node.type == "F" then
            --image.ImageColor3 = Color3.new(0.2, 0.2, 0.8)
            transparency = 0
        elseif self.props.node.type == "H" then
            --image.ImageColor3 = Color3.new(0.8, 0.2, 0.2)
            transparency = 0
        elseif transparency > 0.95 then
            if enabled then
                billboard.Enabled = false
                enabled = false
            end
            debug.profileend()
            return
        end

        if not enabled then
            billboard.Enabled = true
            enabled = true
        end

        image.ImageTransparency = transparency

        debug.profileend()
    end)
end

function UnitSpot:willUnmount()
    if self.event then
        self.event:Disconnect()
        self.event = nil
    end
end

return UnitSpot


