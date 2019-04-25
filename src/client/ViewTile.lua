local ViewTile = {}
local Client   = script.Parent
local Common   = game.ReplicatedStorage.Pioneers.Common
local Assets   = game.ReplicatedStorage.Pioneers.Assets

local ClientUtil = require(Client.ClientUtil)
local Tile = require(Common.Tile)
local Util = require(Common.Util)

local RunService = game:GetService("RunService")

local clamp = math.clamp

local TileModel = game.ReplicatedStorage.Pioneers.Assets.Hexagon
local TileToInstMap = {}

local CUTOFF_DIST = 1500

local meshId = {}
meshId[Tile.GRASS]    = {mesh = "rbxassetid://3029151403", texture = "rbxassetid://3080817017", offset = Vector3.new(0,     0,    0)}
meshId[Tile.KEEP]     = {mesh = "rbxassetid://3051772197", texture = "rbxassetid://3051753777", offset = Vector3.new(0, 11.007, 0)}
meshId[Tile.HOUSE]    = {mesh = "rbxassetid://3051012602", texture = "rbxassetid://3051015865", offset = Vector3.new(0, 5.479, 0)}
meshId[Tile.PATH]     = {mesh = "rbxassetid://3054365062", texture = "rbxassetid://3054364701", offset = Vector3.new(0,     0,    0)}
meshId[Tile.FARM]     = {mesh = "rbxassetid://3054440853", texture = "rbxassetid://3054440951", offset = Vector3.new(-0.015, 1.594, 0.059)}
meshId[Tile.FORESTRY] = {mesh = "rbxassetid://3054515092", texture = "rbxassetid://3054515216", offset = Vector3.new(0, 7.682, 0.131)}
meshId[Tile.MINE]     = {mesh = "rbxassetid://3069462867", texture = "rbxassetid://3069463016", offset = Vector3.new(0, 1.795,    0)}
meshId[Tile.STORAGE]  = {mesh = "rbxassetid://3104986356", texture = "rbxassetid://3104986465", offset = Vector3.new(0, 16.842, -0.459)}
meshId[Tile.BARRACKS] = {mesh = "rbxassetid://3105724031", texture = "rbxassetid://3105721152", offset = Vector3.new(0, 5.407, -0)}
meshId[Tile.WALL]     = {mesh = "rbxassetid://3105142037", texture = "rbxassetid://3105142120", offset = Vector3.new(0, 12.5, 0)}

local meshes = {}
meshId[Tile.GRASS]    = {Assets.Hexagon, offset = Vector3.new(0,     0,    0)}
meshId[Tile.KEEP]     = {Assets.Keep, offset = Vector3.new(0, 11.007, 0)}
meshId[Tile.HOUSE]    = {Assets.House, offset = Vector3.new(0, 5.479, 0)}
meshId[Tile.PATH]     = {Assets.Path, offset = Vector3.new(0,     0,    0)}
meshId[Tile.FARM]     = {Assets.Farm, offset = Vector3.new(-0.015, 1.594, 0.059)}
meshId[Tile.FORESTRY] = {Assets.Forestry, offset = Vector3.new(0, 7.682, 0.131)}
meshId[Tile.MINE]     = {Assets.Mine, offset = Vector3.new(0, 1.795,    0)}
meshId[Tile.STORAGE]  = {Assets.Storage, offset = Vector3.new(0, 16.842, -0.459)}
meshId[Tile.BARRACKS] = {Assets.Barracks, offset = Vector3.new(0, 5.407, -0)}
meshId[Tile.WALL]     = {Assets.Wall, offset = Vector3.new(0, 12.5, 0)}

local function unload(tile, model) --TODO: fully unload from memory
    model:Destroy()
    TileToInstMap[tile] = nil
end

local function autoUnload() --TODO: fully unload from memory
    local getPos = ClientUtil.getPlayerPosition
    local dist
    
    repeat
        for tile, model in pairs(TileToInstMap) do
            if model and model.Parent ~= nil then

                local position = model.Position

                dist = (position - getPos()).magnitude

                local n = clamp((((model.Mesh.Scale.x)*20) + (300/(dist))^2-1)/21, 0, 1)

                model.Mesh.Scale = Vector3.new(n,n,n)

                if dist > CUTOFF_DIST then
                    unload(tile, model)
                end

            else
                TileToInstMap[tile] = nil
            end
        end

        RunService.Stepped:Wait()
    until false
end

function ViewTile.displayTile(tile)

    if TileToInstMap[tile] then
        return end

    local model = TileModel:Clone()

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

    if meshId[tile.Type] then
        model.Color = Color3.new(1,1,1)
        model.Mesh.MeshId = meshId[tile.Type].mesh
        model.Mesh.TextureId = meshId[tile.Type].texture
        model.Mesh.Offset = meshId[tile.Type].offset
    end
end

function ViewTile.getInstFromTile(tile)
    return TileToInstMap[tile]
end

spawn(autoUnload)

return ViewTile