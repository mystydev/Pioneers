local ViewTile = {}
local Client   = script.Parent
local Common   = game.ReplicatedStorage.Pioneers.Common

local ClientUtil = require(Client.ClientUtil)
local Tile = require(Common.Tile)
local Util = require(Common.Util)

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local clamp = math.clamp
local floor = math.floor

local tweenInfo  = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local TileModel = game.ReplicatedStorage.Pioneers.Assets.Hexagon
local DisplayCol = {}
local TileToInstMap = {}

DisplayCol[Tile.GRASS]    = Color3.fromRGB(73,156,7)
DisplayCol[Tile.KEEP]     = Color3.fromRGB(139,0,139)
DisplayCol[Tile.PATH]     = Color3.fromRGB(128,128,128)
DisplayCol[Tile.HOUSE]    = Color3.fromRGB(47,79,79)
DisplayCol[Tile.FARM]     = Color3.fromRGB(240,230,140)
DisplayCol[Tile.MINE]     = Color3.fromRGB(0,0,139)
DisplayCol[Tile.FORESTRY] = Color3.fromRGB(0,100,0)
DisplayCol[Tile.STORAGE]  = Color3.fromRGB(0,255,255)
DisplayCol[Tile.BARRACKS] = Color3.fromRGB(220,20,60)
DisplayCol[Tile.WALL]     = Color3.fromRGB(0,0,0)
DisplayCol[Tile.GATE]     = Color3.fromRGB(188,143,143)

local meshId = {}

meshId[Tile.KEEP] = {mesh = "rbxassetid://3051772197", texture = "rbxassetid://3051753777", offset = Vector3.new(0, 11, 0)}
meshId[Tile.HOUSE] = {mesh = "rbxassetid://3051012602", texture = "rbxassetid://3051015865", offset = Vector3.new(0, 5.5, 0)}
meshId[Tile.PATH] = {mesh = "rbxassetid://3054365062", texture = "rbxassetid://3054364701", offset = Vector3.new(0, 0, 0)}
meshId[Tile.FARM] = {mesh = "rbxassetid://3054440853", texture = "rbxassetid://3054440951", offset = Vector3.new(0, 1.6, 0)}
meshId[Tile.FORESTRY] = {mesh = "rbxassetid://3054515092", texture = "rbxassetid://3054515216", offset = Vector3.new(0, 7.7, 0.15)}
meshId[Tile.MINE] = {mesh = "rbxassetid://3069462867", texture = "rbxassetid://3069463016", offset = Vector3.new(0, 1.795, 0)}

local function unload(tile, model) --TODO: fully unload from memory
    model:Destroy()
    TileToInstMap[tile] = nil
end

local function autoUnload() --TODO: fully unload from memory
    local getPos = ClientUtil.getPlayerPosition
    local dist
    
    repeat
        for tile, model in pairs(TileToInstMap) do
            local position = model.Position

            dist = (position - getPos()).magnitude
            --print(dist, (dist/100)^2)
            --if dist > 300 or model.Mesh.Scale.x ~= 1 then
                local n = clamp((((model.Mesh.Scale.x)*20) + (300/(dist))^2-1)/21, 0, 1)
                model.Mesh.Scale = Vector3.new(n,n,n)
            --end
            local p = getPos()

            --if dist > 200 then
            --    model.CFrame = CFrame.new(Vector3.new(position.x, (1-model.Mesh.Scale.x)*50, position.z), Vector3.new(p.x, -(1-model.Mesh.Scale.x)*2000, p.z))
            --else
            --    model.CFrame = CFrame.new(Vector3.new(position.x, (1-model.Mesh.Scale.x)*50, position.z))
            --end

            --if dist > 1500 then
                --unload(tile, model)
            --end
        end

        RunService.Stepped:Wait()
    until false
end

function ViewTile.displayTile(tile)

    if TileToInstMap[tile] then
        return end

    local model = TileModel:Clone()
    --local tween = TweenService:Create(model, tweenInfo, {Transparency = 0})
    --tween:Play()

    TileToInstMap[tile] = model
    model.Position = Util.axialCoordToWorldCoord(tile.Position)
    model.Parent = Workspace

    ViewTile.updateDisplay(tile)
end

function ViewTile.updateDisplay(tile)
    local model = TileToInstMap[tile]

    if not model then
        return ViewTile.displayTile(tile)
    end

    model.Color = DisplayCol[tile.Type]

    if meshId[tile.Type] then
        model.Color = Color3.new(1,1,1)
        model.Mesh.MeshId = meshId[tile.Type].mesh
        model.Mesh.TextureId = meshId[tile.Type].texture
        model.Mesh.Offset = meshId[tile.Type].offset
    end
end

function ViewTile.getTileFromInst(inst)
    return TileToInstMap[inst]
end

spawn(autoUnload)

return ViewTile