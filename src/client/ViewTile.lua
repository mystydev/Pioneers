local ViewTile = {}

local Common = game.ReplicatedStorage.Pioneers.Common
local Tile = require(Common.Tile)

local TileModel = game.ReplicatedStorage.Pioneers.Assets.Hexagon

local TILESPACING = 10 --Distance from center of hexagon to edge vertex
local EDGESPACING = TILESPACING * (0.5 * 3^.5)

local YOFFSET = EDGESPACING * 2 * Vector3.new(1, 0, 0)
local XOFFSET = EDGESPACING * 2 * Vector3.new(-0.5, 0, 0.866)


local DisplayCol = {}

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

    model.Position = ViewTile.axialCoordToWorldCoord(tile.Position)
    model.Parent = Workspace
    model.Color = DisplayCol[tile.Type]
    
end

function ViewTile.axialCoordToWorldCoord(position)

    local x = position.y * YOFFSET
    local z = position.x * XOFFSET

    return position.y * YOFFSET + position.x * XOFFSET
end

return ViewTile