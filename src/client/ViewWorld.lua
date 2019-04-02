local ViewWorld = {}

local Client = script.Parent
local Common = game.ReplicatedStorage.Pioneers.Common
local ViewTile = require(Client.ViewTile)
local World = require(Common.World)

function ViewWorld.displayWorld(world)
    
    local tiles = world.Tiles

    for x = 0, World.SIZE do 
        for y = 0, World.SIZE do
            local tile = tiles[x][y]

            if tile then
                ViewTile.displayTile(tile)
            end
        end
    end
end



return ViewWorld