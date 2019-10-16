local Client = script.Parent.Parent.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local ui = Client.ui
local Roact = require(game.ReplicatedStorage.Roact)

local Util = require(Common.Util)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local PartitionVisualistion = Roact.Component:extend("PartitionVisualistion")

local PARTITION_SIZE = 20

local images = {}
images[0] = "rbxassetid://4124122010"
images[1] = "rbxassetid://4129665424"
images[2] = "rbxassetid://4129665523"
images[3] = "rbxassetid://4129753060"
images[4] = "rbxassetid://4129665220"
images[5] = "rbxassetid://4129753160"
images[6] = "rbxassetid://4129748839"
images[7] = "rbxassetid://4129784289"
images[8] = "rbxassetid://4129665311"
images[9] = "rbxassetid://4129752953"
images[10] = "rbxassetid://4129753256"
images[11] = "rbxassetid://4129784588"
images[12] = "rbxassetid://4129748929"
images[13] = "rbxassetid://4129784488"
images[14] = "rbxassetid://4129784397"
images[15] = "rbxassetid://4129748344"

local keepImageId = "rbxassetid://3464269762"


function PartitionVisualistion:init()
    self.frameRef = Roact.createRef()
end


function PartitionVisualistion:render()
    local partitionMap = self.props.PartitionMap
    local keepMap = self.props.KeepMap
    local occupancyMap = {}
    local elements = {}
    
    for partitionId, ownerId in pairs(partitionMap) do
        local x, y = Util.partitionIdToCoordinates(partitionId)

        if not occupancyMap[x] then 
            occupancyMap[x] = {}
        end

        if not occupancyMap[x-PARTITION_SIZE] then 
            occupancyMap[x-PARTITION_SIZE] = {}
        end

        if not occupancyMap[x+PARTITION_SIZE] then 
            occupancyMap[x+PARTITION_SIZE] = {}
        end

        occupancyMap[x][y] = ownerId
    end

    for partitionId, ownerId in pairs(partitionMap) do
        local x, y = Util.partitionIdToCoordinates(partitionId)
        
        local n0 = occupancyMap[x][y+PARTITION_SIZE] == ownerId and '1' or '0'
        local n1 = occupancyMap[x+PARTITION_SIZE][y] == ownerId and '1' or '0'
        local n2 = occupancyMap[x][y-PARTITION_SIZE] == ownerId and '1' or '0'
        local n3 = occupancyMap[x-PARTITION_SIZE][y] == ownerId and '1' or '0'
        
        local lookupIndex = tonumber(n3..n2..n1..n0, 2)
        local imageId = images[lookupIndex]

        table.insert(elements, Roact.createElement("ImageLabel", {
            Image = imageId,
            Size = UDim2.new(5, 0, 5, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(x * 0.2, 0, -y * 0.2, 0),
            AnchorPoint = Vector2.new(0.1, 0.9),
            Rotation = rotation,
        }))
    end

    for ownerId, keepPosition in pairs(keepMap) do
        local position = Util.positionStringToVector(keepPosition)
        local x = position.x - position.x % PARTITION_SIZE
        local y = position.y - position.y % PARTITION_SIZE

        table.insert(elements, Roact.createElement("ImageLabel", {
            Image = keepImageId,
            Size = UDim2.new(6, 0, 6, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(position.x * 0.2, 0, -position.y * 0.2, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
        }))

    end

    return Roact.createElement("Frame", {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 10),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        [Roact.Ref] = self.frameRef,
    }, elements)
end

function PartitionVisualistion:didMount()
    local mouse = Players.LocalPlayer:GetMouse()
    local lastPosition = UIS:GetMouseLocation()

    self.wheelForward = mouse.WheelForward:Connect(function()
        local frame = self.frameRef:getValue()
        local size = frame.Size.X.Offset
        local difference = (size+1) / size

        frame.Size = frame.Size + UDim2.new(0, 1, 0, 1)
        frame.Position = UDim2.new(0.5, frame.Position.X.Offset * difference, 0.5, frame.Position.Y.Offset * difference)
    end)

    self.wheelBackward = mouse.WheelBackward:Connect(function()
        local frame = self.frameRef:getValue()
        local size = frame.Size.X.Offset
        local difference = (size-1) / size

        if size <= 1 then
            return end

        frame.Size = frame.Size - UDim2.new(0, 1, 0, 1)
        frame.Position = UDim2.new(0.5, frame.Position.X.Offset * difference, 0.5, frame.Position.Y.Offset * difference)
    end)

    UIS.InputChanged:Connect(function(input, processed) 
        
        if processed then return end

        local movementDelta = UIS:GetMouseLocation() - lastPosition
        lastPosition = UIS:GetMouseLocation()
        
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local frame = self.frameRef:getValue()
            local size = frame.Size.X.Offset
            frame.Position = frame.Position + UDim2.new(0, movementDelta.x, 0, movementDelta.y)
        end    
    end)

    local lastClick = 0

    UIS.InputEnded:Connect(function(input, processed)

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if input.UserInputState == Enum.UserInputState.End and tick() - lastClick < 0.2 then
                local frame = self.frameRef:getValue()
                local size = frame.Size.X.Offset
                local mousePosition = UIS:GetMouseLocation() - Vector2.new(0, 30)
                local deltaPosition = ((mousePosition - frame.AbsolutePosition) / size) / 0.2
                local correctedPosition = Vector2.new(deltaPosition.x, -deltaPosition.y)
                print(correctedPosition)
            end
    
            lastClick = tick()
        end

    end)
end

function PartitionVisualistion:willUnmount()
    self.running = false
end

return PartitionVisualistion