local Roact = require(game.ReplicatedStorage.Roact)
local Client = script.Parent.Parent

local Replication = require(Client.Replication)

local function DeleteButton(props)
    return Roact.createElement("TextButton", {
        Name                   = "DeleteButton",
        Text                   = "Delete",
        BackgroundTransparency = 1,
        Position               = props.Position,
        Size                   = UDim2.new(0,100,0,48),
        Font                   = "SourceSansLight",
        TextSize               = 24,
        TextTransparency       = 0.4,
        TextColor3             = Color3.fromRGB(170, 0, 0),
        [Roact.Event.MouseButton1Click] = function() 
            Replication.requestTileDelete(props.Obj)
            props.UIBase.exitInfoView()
        end,
    })
end

return DeleteButton