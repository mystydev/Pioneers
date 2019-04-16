local ui = script.Parent
local Roact = require(game.ReplicatedStorage.Roact)

local Label = require(ui.Label)

local Players = game:GetService("Players")

local nameCache = {}

local function OwnerLabel(props)
    local name = "Unknown Owner"

    if props.Owner then
        if nameCache[props.Owner] then
            name = nameCache[props.Owner]
        else
            name = Players:GetNameFromUserIdAsync(props.Owner)
            nameCache[props.Owner] = name
        end
    end

    return Roact.createElement("ImageLabel", {
        Name = "OwnerLabel",
        BackgroundTransparency = 1,
        Position = UDim2.new(0.146, 0, 0.147, 0),
        Size = UDim2.new(0, 232, 0, 32),
        Image = "rbxassetid://3063768294"
    }, {
        Label = Roact.createElement(Label, {Text = name})
    })
end

return OwnerLabel