local ViewTile = {}

local Common = game.ReplicatedStorage.Pioneers.Common
local Tile = require(Common.Tile)
local Util = require(Common.Util)

local TileModel = game.ReplicatedStorage.Pioneers.Assets.Hexagon
local DisplayCol = {}
local TileToInstMap = {}

DisplayCol[Tile.GRASS]    = Color3.fromRGB(50,205,50)
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

function ViewTile.displayTile(tile)
    local model = TileModel:Clone()

    TileToInstMap[tile] = model

    model.Position = Util.axialCoordToWorldCoord(tile.Position)
    model.Parent = Workspace
    model.Color = DisplayCol[tile.Type]
    
end

function ViewTile.updateDisplay(tile)
    local model = TileToInstMap[tile]

    model.Color = DisplayCol[tile.Type]
end

return ViewTile