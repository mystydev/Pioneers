
local ui           = script.Parent.Parent
local Roact        = require(game.ReplicatedStorage.Roact)
local Common       = game.ReplicatedStorage.Pioneers.Common
local Client       = ui.Parent

local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")

local ClientUtil   = require(Client.ClientUtil)
local ViewWorld    = require(Client.ViewWorld)
local UnitControl  = require(Client.UnitControl)
local Util         = require(Common.Util)
local UnitSpot     = require(ui.unitControl.UnitSpot)

local UnitSpots  = Roact.Component:extend("UnitSpots")
local Player = Players.LocalPlayer
local displayedLinks = {}
local displayedMap = {}
local mousePosition, updateMousePosition = Roact.createBinding(Vector3.new(0,0,0))

local function linkDisplayed(n1, n2)
    return (displayedMap[n1] and displayedMap[n1][n2]) or (displayedMap[n2] and displayedMap[n2][n1])
end

local function updateLink(link, beam)
    if link.combat then
        beam.Width0 = 0.5
        beam.Width1 = 2
        beam.Color = ColorSequence.new(Color3.new(0.8, 0.2, 0.2))
        beam.Transparency = NumberSequence.new(0)
        beam.ZOffset = 0.01
        beam.Texture = "rbxassetid://4579670009"
        beam.TextureLength = 15
    elseif link.movement then
        beam.Width0 = 0.5
        beam.Width1 = 1.5
        beam.Color = ColorSequence.new(Color3.new(0.2, 0.2, 0.8))
        beam.Transparency = NumberSequence.new(0)
        beam.ZOffset = 0.01
        beam.Texture = "rbxassetid://4579670009"
        beam.TextureLength = 15
    else
        beam.Width0 = 0.1
        beam.Width1 = 0.1
        beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
        beam.Transparency = NumberSequence.new(0.95)
        beam.ZOffset = 0.02
        beam.Texture = ""
    end
end

function UnitSpots:init()
    self:setState({
        nodes = {}
    })
end

function UnitSpots:render()
    local spots = {}

    local links = UnitControl.getLinks()

    for i, node in pairs(self.state.nodes) do
        spots[i] = Roact.createElement(UnitSpot, {
            node = node,
            links = links,
            mousePosition = mousePosition,
            type = node.type,
        })
    end

    for i, node in pairs(UnitControl.getNodes()) do
        if node.type == "F" and not spots[i] then
            spots[i] = Roact.createElement(UnitSpot, {
                node = node,
                links = links,
                mousePosition = mousePosition,
                type = node.type,
            })
        end
    end

    for n1, linktab in pairs(links) do
        for n2, link in pairs(linktab) do
            if not link.displayed then
                local beam = Instance.new("Beam", workspace)
                beam.Attachment0 = n1.attachment
                beam.Attachment1 = n2.attachment
                beam.FaceCamera = true
                beam.Width0 = 0.1
                beam.Width1 = 0.1
                beam.Segments = 1
                beam.Transparency = NumberSequence.new(0.95)

                link.displayed = beam
                link.updateDisplay = function() updateLink(link, beam) end
                displayedLinks[link] = beam
                displayedMap[n1] = displayedMap[n1] or {}
                displayedMap[n2] = displayedMap[n2] or {}
                displayedMap[n1][n2] = link
                displayedMap[n2][n1] = link
            end
        end
    end

    return Roact.createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    }, spots)
end

function UnitSpots:didMount()
    if self.event then return end
    local mouse = Player:GetMouse()

    self.running = true
    local lastupdate = tick()

    self.event = RunService.Stepped:Connect(function()
        updateMousePosition(mouse.hit.p)

        --if tick() - lastupdate > 0.5 then
            lastupdate = tick()
        
            self:setState({
                nodes = UnitControl.evalLocalArea(mouse.hit.p),
            })
        --end
    end)
end

function UnitSpots:willUnmount()
    if self.event then
        self.event:Disconnect()
        self.event = nil
    end

    for link, beam in pairs(displayedLinks) do
        beam:Destroy()
        link.updateDisplay = nil
        link.displayed = nil
        displayedMap = {}
    end
end

return UnitSpots


