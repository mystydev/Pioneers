
local Roact = require(game.ReplicatedStorage.Roact)
local Players = game:GetService("Players")

local nameCache = {}

function ChatMessage(props)

    local message = props.message
    local text

    if nameCache[message.user] then
        text = nameCache[message.user] .. "  " .. message.text
    else
        nameCache[message.user] = Players:GetNameFromUserIdAsync(message.user)
        text = nameCache[message.user] .. "  " .. message.text
    end

    local front = Roact.createElement("TextLabel", {
        Name                   = "ChatMessageFront",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, -1, 0, -1),
        Size                   = UDim2.new(1, 0, 0, 20),
        AnchorPoint            = Vector2.new(0, 0),
        TextSize               = "14",
        TextXAlignment         = "Left",
        Text                   = text,
        TextTransparency       = 0.1,
        TextColor3             = Color3.fromRGB(240, 240, 240)
    })

    return Roact.createElement("TextLabel", {
        Name                   = "ChatMessage",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 20, 0, 0),
        Size                   = UDim2.new(1, 0, 0, 20),
        AnchorPoint            = Vector2.new(0, 0),
        TextSize               = "14",
        TextXAlignment         = "Left",
        Text                   = text,
        TextTransparency       = 0.1,
        TextColor3             = Color3.fromRGB(55, 55, 55)
    }, front)
end

return ChatMessage