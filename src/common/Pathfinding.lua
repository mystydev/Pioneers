local Pathfinding = {}

local Common = game.ReplicatedStorage.Pioneers.Common
local World = require(Common.World)
local Tile = require(Common.Tile)

local currentWorld
local sign = math.sign
local abs = math.abs
local max = math.max

--Manhatten distance
local function costHeuristic(startTile, endTile)
    local delt = endTile.Position - startTile.Position

    if sign(delt.x) ~= sign(delt.y) then
        return abs(delt.x) + abs(delt.y)
    else
        return max(abs(delt.x), abs(delt.y))
    end
end

local function getNeighbours(tile)
    local posx, posy = tile.Position.x, tile.Position.y
    local tiles = currentWorld.Tiles

    if posx > 0 and posx < World.SIZE and posy > 0 and posy < World.SIZE then
        return {
            tiles[posx  ][posy+1],
            tiles[posx+1][posy+1],
            tiles[posx+1][posy  ],
            tiles[posx  ][posy-1],
            tiles[posx-1][posy-1],
            tiles[posx-1][posy  ]}
    end
end

local function reversePath(path)
    local reversed = {}

    for i = #path, 1, -1 do
        table.insert(reversed, path[i])
    end

    return reversed
end

local function reconstructPath(startTile, endTile, cameFrom)
    local current = cameFrom[endTile]
    local path = {endTile}
    
    while current ~= startTile do
        table.insert(path, current)
        current = cameFrom[current]
    end

    return reversePath(path)
end

function Pathfinding.assignWorld(w)
    currentWorld = w
end

function Pathfinding.findClosestStorage(tile)
    local searchspace = {tile}
    local checked = {}
    local iterations = 0

    while iterations < 1000 and iterations < #searchspace do
        iterations = iterations + 1
        local current = searchspace[iterations]
        
        if current and not checked[current] then
            checked[current] = true
            local neighbours = getNeighbours(current)
            
            for _, neighbour in pairs(neighbours) do
                
                if neighbour.Type == Tile.STORAGE then
                    return neighbour
                end

                if neighbour.Type == Tile.PATH and not checked[neighbour] then
                    table.insert(searchspace, neighbour)
                end
            end
        end
    end
    
    print("Could not find storage!")
    return nil
end

--A* implementation based on pseudocode at https://en.wikipedia.org/wiki/A*_search_algorithm
function Pathfinding.findPath(startTile, endTile)
    local closedSet = {}
    local openSet = {}
    local cameFrom = {}
    local gScore = {}

    openSet[startTile] = costHeuristic(startTile, endTile)
    gScore[startTile] = 0

    local iterations = 0

    while iterations < 5000 do
        iterations = iterations + 1
        local lowestF = math.huge
        local currentTile

        for tile, f in pairs(openSet) do
            if f < lowestF then
                lowestF = f
                currentTile = tile
            end
        end

        if currentTile == endTile then
            return reconstructPath(startTile, endTile, cameFrom)
        end

        if lowestF == math.huge then
            return nil
        end

        openSet[currentTile] = nil
        closedSet[currentTile] = true

        local neighbours = getNeighbours(currentTile)

        if neighbours then
            for i, neighbour in pairs(neighbours) do
                if not closedSet[neighbour] 
                    and (neighbour.Type == Tile.PATH or neighbour == endTile) then
                    local g = gScore[currentTile] + 1

                    if g < (gScore[neighbour] or math.huge) then
                        cameFrom[neighbour] = currentTile
                        gScore[neighbour] = g 
                        openSet[neighbour] = g + costHeuristic(neighbour, endTile)
                    end
                end
            end
        end
    end
end

return Pathfinding