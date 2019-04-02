
local ViewTile = {}
local TileModel = game.ReplicatedStorage.Pioneers.Assets.Hexagon

local TILESPACING = 10 --Distance from center of hexagon to edge vertex
local EDGESPACING = TILESPACING * (0.5 * 3^.5)

local YOFFSET = EDGESPACING * 2 * Vector3.new(1, 0, 0)
local XOFFSET = EDGESPACING * 2 * Vector3.new(-0.5, 0, 0.866)

function ViewTile.displayTile(tile)
    local model = TileModel:Clone()

    model.Position = ViewTile.axialCoordToWorldCoord(tile.Position)
    model.Parent = Workspace

    if tile.Position.x == 0 then
        model.Color = Color3.new(1,0,0)
    end
    if tile.Position.y == 0 then
        model.Color = Color3.new(0,1,0)
    end
    if tile.Position.y == 0 and tile.Position.x == 0 then
        model.Color = Color3.new(1,1,0)
    end
end

function ViewTile.axialCoordToWorldCoord(position)

    local x = position.y * YOFFSET
    local z = position.x * XOFFSET

    return position.y * YOFFSET + position.x * XOFFSET
end

return ViewTile