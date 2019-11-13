local ui = script.Parent.Parent
local Client = ui.Parent

local ActionHandler = require(Client.ActionHandler)
local Replication   = require(Client.Replication)
local ChatMessage   = require(ui.chat.ChatMessage)
local Roact         = require(game.ReplicatedStorage.Roact)
local ChatBox       = Roact.Component:extend("ChatBox")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")

local fade = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local lastInteraction = 0
local interacting = false
local istyping = false

local function mouseEntered()
    lastInteraction = tick()
    interacting = true
end

local function mouseLeft()
    lastInteraction = tick()
    interacting = false 
end

function ChatBox:init()
    self:setState({
        transparency = 1,
        chatHeight = 0,
        stayBottom = 1000000,
    })

    self.frameRef = Roact.createRef()
    self.chatRef = Roact.createRef()
end

function ChatBox:startedTyping()
    istyping = true
    self.props.UIBase.chatFocused()
end

function ChatBox:stoppedTyping(textbox, enterPressed)
    lastInteraction = tick()
    istyping = false
    self.props.UIBase.chatUnfocused()

    if enterPressed then
        ActionHandler.chatted(self.chatRef.current.Text)
        self.chatRef.current.Text = ""
    end
end

function ChatBox:render()

    local messages = {}

    for i, chat in pairs(Replication.getChats()) do
        messages[1000 - i] = Roact.createElement(ChatMessage, {
            message = {user = chat.playerId, text = chat.text},
        })
    end

    messages.uiLayout = Roact.createElement("UIListLayout", {
        Padding = UDim.new(0, 10),
        VerticalAlignment = "Bottom",
    })

    local children = {}

    children.frame = Roact.createElement("ScrollingFrame", {
        Size     = UDim2.new(1, -40, 1, -80),
        Position = UDim2.new(0, 25, 0, 15),
        BackgroundTransparency = 1,
        MidImage = "rbxassetid://3613102979",
        TopImage = "rbxassetid://3610988520",
        BottomImage = "rbxassetid://3610988438",
        BorderSizePixel = 0,
        ScrollBarThickness = 36,
        ScrollBarImageTransparency = self.state.transparency,
        CanvasPosition = Vector2.new(0, self.state.stayBottom),
        CanvasSize = UDim2.new(1, -40, 0, self.state.chatHeight),
        [Roact.Ref] = self.frameRef,
    }, messages)

    children.enterChat = Roact.createElement("TextBox", {
        PlaceholderText = "Type here to chat...",
        Text = "",
        TextColor3 = Color3.fromRGB(240, 240, 240),
        Size = UDim2.new(1, -40, 0, 40),
        Position = UDim2.new(0, 30, 1, -20),
        AnchorPoint = Vector2.new(0, 1),
        TextSize = "18",
        TextTransparency = self.state.transparency + 0.2,
        BackgroundTransparency = 1,
        TextXAlignment = "Left",
        ClearTextOnFocus = false,
        [Roact.Event.Focused] = function() self:startedTyping() end,
        [Roact.Event.FocusLost] = function(textbox, enterPressed) self:stoppedTyping(textbox, enterPressed) end,
        [Roact.Ref] = self.chatRef,
    })

    return Roact.createElement("ImageLabel", {
        Name                   = "ChatBox",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 10, 1, -70),
        Size                   = UDim2.new(0, 560, 0, 430),
        AnchorPoint            = Vector2.new(0, 1),
        Image                  = "rbxassetid://3606976807",
        ImageTransparency      = self.state.transparency,
        ImageColor3            = Color3.fromRGB(55,55,55),
        [Roact.Event.MouseEnter] = mouseEntered,
        [Roact.Event.MouseLeave] = mouseLeft,
    }, children)
end

function ChatBox:didMount()
    self.running = true

    spawn(function()
        while self.running do
            self:setState(function(state)
                local ysize = 0
                local frame = self.frameRef.current

                for _, child in pairs(frame:GetChildren()) do
                    if child:IsA("TextLabel") then
                        ysize = ysize + child.Size.Y.Offset + 10 --10 is padding
                    end
                end

                local transparency

                if istyping then
                    transparency = 0.2
                elseif interacting then
                    transparency = 0.8
                else
                    transparency = math.clamp((tick() - lastInteraction), state.transparency, 1)
                end 

                
                local heightDelta = frame.CanvasSize.Y.Offset - frame.AbsoluteSize.Y
                local stayBottom = state.stayBottom
                if frame.CanvasPosition.Y == heightDelta then
                    stayBottom = ysize
                end

                return {
                    chatHeight = ysize,
                    transparency = transparency,
                    stayBottom = stayBottom,
                }
            end)

            RunService.Stepped:Wait()
        end
    end)
end

function ChatBox:willUnmount()
    self.running = false
end

function ChatBox:enterPressed()

end

return ChatBox