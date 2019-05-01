local ViewTile = {}
local Client   = script.Parent
local Common   = game.ReplicatedStorage.Pioneers.Common
local Assets   = game.ReplicatedStorage.Pioneers.Assets

local ClientUtil = require(Client.ClientUtil)
local Tile = require(Common.Tile)
local Util = require(Common.Util)

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local clamp = math.clamp

local TileToInstMap = {}
local sizeTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local meshes = {}
meshes[Tile.DESTROYED] = {mesh = Assets.Ruins,  offset = Vector3.new(0,     0,    0)}
meshes[Tile.GRASS]    = {mesh = Assets.Hexagon,  offset = Vector3.new(0,     0,    0)}
meshes[Tile.KEEP]     = {mesh = Assets.Keep,     offset = Vector3.new(0, 11.007, 0)}
meshes[Tile.HOUSE]    = {mesh = Assets.House,    offset = Vector3.new(0, 5.479, 0)}
meshes[Tile.PATH]     = {mesh = Assets.Path,     offset = Vector3.new(0,     0.25,    0)}
meshes[Tile.FARM]     = {mesh = Assets.Farm,     offset = Vector3.new(-0.015, 1.594, 0.059)}
meshes[Tile.FORESTRY] = {mesh = Assets.Forestry, offset = Vector3.new(0, 7.682, 0.131)}
meshes[Tile.MINE]     = {mesh = Assets.Mine,     offset = Vector3.new(0, 1.795,    0)}
meshes[Tile.STORAGE]  = {mesh = Assets.Storage,  offset = Vector3.new(0, 16.842, -0.459)}
meshes[Tile.BARRACKS] = {mesh = Assets.Barracks, offset = Vector3.new(0, 5.407, -0)}
meshes[Tile.WALL]     = {mesh = Assets.Wall,     offset = Vector3.new(0, 12.5, 0)}

function ViewTile.displayTile(tile, displaySize)

    if TileToInstMap[tile] then
        ViewTile.updateDisplay(tile, displaySize)
        return end

    local meshInfo = meshes[tile.Type]
    local model = meshInfo.mesh:Clone()

    if displaySize ~= "SKIP" then
        model.Size = Vector3.new(0,0,0)
        tile.displaySize = 0
    else
        tile.displaySize = 1
    end

    TileToInstMap[tile] = model
    model.Position = Util.axialCoordToWorldCoord(tile.Position) + meshInfo.offset
    model.Parent = Workspace

    ViewTile.updateDisplay(tile, displaySize or 1)
end

function ViewTile.updateDisplay(tile, displaySize)
    local model = TileToInstMap[tile]

    if not model then
        return ViewTile.displayTile(tile)
    end

    if model.Name ~= meshes[tile.Type].mesh.Name then
        TileToInstMap[tile]:Destroy()
        TileToInstMap[tile] = nil
        ViewTile.displayTile(tile)
    end

    if displaySize and displaySize ~= "SKIP" and displaySize > tile.displaySize then
        TweenService:Create(model, sizeTween, {Size = meshes[tile.Type].mesh.Size * displaySize}):Play()
        tile.displaySize = displaySize
    end
end

function ViewTile.getInstFromTile(tile)
    return TileToInstMap[tile]
end

return ViewTile