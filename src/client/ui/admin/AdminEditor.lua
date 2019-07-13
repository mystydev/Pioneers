local ui           = script.Parent.Parent
local Roact        = require(game.ReplicatedStorage.Roact)
local Common       = game.ReplicatedStorage.Pioneers.Common
local Client       = ui.Parent
local RunService   = game:GetService("RunService")

local ViewWorld    = require(Client.ViewWorld)
local Title        = require(ui.Title)
local PropEdit     = require(ui.admin.PropEdit)
local AdminEditor  = Roact.Component:extend("AdminEditor")

function AdminEditor:init()
    self:setState({
        object = nil
    })
end

function AdminEditor:render()

    local children = {}

    children.Title = Roact.createElement(Title, {
        Title = "Admin Object Editor",
        TextTransparency = 0.1, 
        Position = UDim2.new(0.5, 0, 0.05, 0),
        Size = UDim2.new(1, 0, 0, 32),
        AnchorPoint = Vector2.new(0.5, 0),
        TextXAlignment = "Center",
        Color = Color3.fromRGB(200, 200, 200),
    })

    local props = {}
    
    if self.state.object then
        for i, v in pairs(self.state.object) do
            if type(v) == "table" then
                table.insert(props, Roact.createElement(PropEdit, {Index = i, Value = ""}))

                for i, v in pairs(v) do
                    table.insert(props, Roact.createElement(PropEdit, {Index = "   - " .. i, Value = tostring(v)}))
                end
            else
                table.insert(props, Roact.createElement(PropEdit, {Index = i, Value = tostring(v)}))
            end
        end
    end

    props.layout = Roact.createElement("UIListLayout")

    children.ScrollFrame = Roact.createElement("ScrollingFrame", {
        Size = UDim2.new(0.8, 0, 0.6, 0),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0.8, 0),
        BackgroundTransparency = 1,
    }, props)

    local pos
    if self.state.inst then
        local screenpos = workspace.CurrentCamera:WorldToScreenPoint(self.state.inst.Position)
        pos = UDim2.new(0, screenpos.x, 0, screenpos.y - 30)
    end

    return Roact.createElement("ImageLabel", {
        Name                   = "AdminEditor",
        BackgroundTransparency = 1,
        Position               = pos or UDim2.new(-10, 0, 0, 0),
        Size                   = UDim2.new(0, 326, 0, 304),
        AnchorPoint            = Vector2.new(0.5, 0.9),
        Image                  = "rbxassetid://3437122618",
        ImageColor3            = Color3.new(0.1, 0.1, 0.1),
        ImageTransparency      = 0,
    }, children)
end

function AdminEditor:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState(function(state)
                local inst = ViewWorld.convertObjectToInst(self.props.object:getValue())
                
                if inst and inst:IsA("Model") then
                    inst = inst:FindFirstChild("HumanoidRootPart")
                end

                return {
                    object = self.props.object:getValue(),
                    inst = inst,
                }   
            end)

            RunService.Heartbeat:Wait()
        end
    end)
end

function AdminEditor:willUnmount()
    self.running = false
end

return AdminEditor