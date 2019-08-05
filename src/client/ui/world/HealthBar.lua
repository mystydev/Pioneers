local ui           = script.Parent.Parent
local Roact        = require(game.ReplicatedStorage.Roact)
local Common       = game.ReplicatedStorage.Pioneers.Common
local Client       = ui.Parent
local RunService   = game:GetService("RunService")

local ViewWorld    = require(Client.ViewWorld)
local HealthBar  = Roact.Component:extend("HealthBar")

function HealthBar:init()
    self:setState({
        object = nil
    })
end

function HealthBar:render()

    local children = {}

    local inst = self.state.inst

    if not inst then return end

    children.health = Roact.createElement("ImageLabel", {
        Name                   = "HealthBar",
        BackgroundTransparency = 1,
        ScaleType              = "Slice",
        SliceCenter            = Rect.new(20, 20, 480, 25),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(self.props.object.Health / 100, 0, 0.2, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = "rbxassetid://3562813767",
        ImageColor3            = Color3.fromRGB(84, 194, 66),
        ImageTransparency      = 0,
    })
    
    return Roact.createElement("BillboardGui", {
        Adornee = inst,
        Size = UDim2.new(10, 0, 10, 0),
        AlwaysOnTop = true,
    }, children)
end

function HealthBar:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState(function(state)
                local obj = self.props.object
                if obj.Health <= 0 or obj.Health >= obj.MHealth then
                    return {
                        object = self.props.object,
                        inst = false,
                    }
                end

                local inst = ViewWorld.convertObjectToInst(self.props.object)
                
                if inst and inst:IsA("Model") then
                    inst = inst:FindFirstChild("HumanoidRootPart")
                end

                return {
                    object = self.props.object,
                    inst = inst,
                }
            end)

            RunService.Heartbeat:Wait()
        end
    end)
end

function HealthBar:willUnmount()
    self.running = false
end

return HealthBar