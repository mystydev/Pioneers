local ViewWorld = {}

local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local ViewTile = require(Client.ViewTile)
local ViewUnit = require(Client.ViewUnit)
local World = require(Common.World)

function ViewWorld.displayWorld(world)
    
    local tiles = world.Tiles
    local units = world.Units

    for x = 0, World.SIZE do 
        for y = 0, World.SIZE do
            local tile = tiles[x][y]
            local unit = units[x][y]

            if tile then ViewTile.displayTile(tile) end
            if unit then ViewUnit.displayUnit(unit) end
        end
    end
end



return ViewWorld