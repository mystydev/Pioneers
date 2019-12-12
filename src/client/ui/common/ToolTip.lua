local Client = script.Parent.Parent.Parent
local ui = Client.ui
local Roact = require(game.ReplicatedStorage.Roact)

local DefaultFrame = require(ui.common.DefaultFrame)
local Label = require(ui.Label)

local TextService = game:GetService("TextService")

local ToolTip = Roact.Component:extend("ToolTip")

local connections = {}

function ToolTip:init()
    self:setState({
        baseRef = Roact.createRef(),
    })
end

function ToolTip:render()
    
    local children = {}
   
    if self.state.display then

        local textSize = TextService:GetTextSize(self.props.Text or "?", 16, "SourceSans", Vector2.new(0,0))
        local width = textSize.x + 50

        children.info = Roact.createElement(DefaultFrame, {
            Size = self.props.Size or UDim2.new(0, width, 0, 40),
            Position = self.props.Position,
            ZIndex = 5,
            ImageTransparency = 0,
        }, {
            label = Roact.createElement(Label, {
                Size = UDim2.new(1, 0, 1, 0),
                Text = self.props.Text,
                ZIndex = 5,
            })
        })
    end

    return Roact.createElement("Frame", {
        Size = UDim2.new(1,0,1,0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        [Roact.Ref] = self.state.baseRef,
        ZIndex = 5,
    }, children)
end

function ToolTip:didMount()
    self.running = true
    
    spawn(function()
        while self.running do
            local ref = self.state.baseRef:getValue()

            if ref and not connections[ref] then
                self:setState({
                    entered = false
                })

                ref.MouseEnter:Connect(function()
                    self:setState({
                        entered = tick()
                    })
                end)

                ref.MouseLeave:Connect(function()
                    self:setState({
                        entered = false
                    })
                end)

                connections[ref] = true
            end

            local entered = self.state.entered

            if entered and tick() - entered > 0.75 then
                self:setState({
                    display = true,
                })
            else
                self:setState({
                    display = false,
                })
            end

            wait()
        end
    end)
end

function ToolTip:willUnmount()
    self.running = false
end

return ToolTip