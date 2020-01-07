local UnitControl = {}
local Common      = game.ReplicatedStorage.Pioneers.Common
local Client      = script.Parent

local ClientUtil = require(Client.ClientUtil)
local Replication = require(Client.Replication)
local Tile = require(Common.Tile)
local Util = require(Common.Util)

--Units can be positioned on each center of a hexagon as well as on each vertex
--This way every unit can reach each other (as they have a reach of 0.5 hexagons)
--however they are still regularly spaced so replication is easily consistent

local evalSize = 13
local nodes = {}
local links = {}

local rootPart = Instance.new("Part")
rootPart.Position = Vector3.new(0, 0, 0)
rootPart.Size = Vector3.new(0.1, 0.1, 0.1)
rootPart.Anchored = true
rootPart.Parent = workspace

local function posToIndex(p)
    return math.floor(3*p.x+0.5) .. ":" .. math.floor(3*p.y+0.5)
end

local function getNeighbours(node)
    local position = node.location
    
    return {
        nodes[posToIndex(position + Vector2.new(0.3333, 0.6666))],
        nodes[posToIndex(position + Vector2.new(0.6666, 0.3333))],
        nodes[posToIndex(position + Vector2.new(0.3333, -0.3333))],
        nodes[posToIndex(position + Vector2.new(-0.3333, -0.6666))],
        nodes[posToIndex(position + Vector2.new(-0.6666, -0.3333))],
        nodes[posToIndex(position + Vector2.new(-0.3333, 0.3333))],
    }
end

local function updateLink(links, source, target, values)
    links[source] = links[source] or {}
    local link = links[source][target] or {}

    for index, value in pairs(values) do
        link[index] = value
    end

    if link.updateDisplay then
        link.updateDisplay()
    end

    links[source][target] = link
end

function UnitControl.evalNodePosition(position)
    if not nodes[posToIndex(position)] then
        nodes[posToIndex(position)] = {
            location = position,
            walkable = true,
        }
    end

    local node = nodes[posToIndex(position)]

    node.attachment = Instance.new("Attachment", rootPart)
    node.attachment.WorldPosition = Util.axialCoordToWorldCoord(position) + Vector3.new(0, 4, 0)

    local tile1 = Replication.getTileXY(math.floor(position.x), math.floor(position.y))
    local tile2 = Replication.getTileXY(math.ceil(position.x), math.ceil(position.y))
    local tile3 = Replication.getTileXY(math.floor(position.x + .5), math.floor(position.y + .5))

    node.walkable = node.walkable and Tile.isWalkable(tile1, true)
    node.walkable = node.walkable and Tile.isWalkable(tile2, true)
    node.walkable = node.walkable and Tile.isWalkable(tile3, true)

    return node
end

function UnitControl.evalWalkableLinks()

    for _, node in pairs(nodes) do
        if node.walkable then
            local position = node.location
            local checks = getNeighbours(node)

            if math.floor(position.x) == position.x and math.floor(position.y) == position.y then
                table.insert(checks, nodes[posToIndex(position + Vector2.new(1, 0))])
                table.insert(checks, nodes[posToIndex(position + Vector2.new(0, 1))])
                table.insert(checks, nodes[posToIndex(position + Vector2.new(1, 1))])
            end

            links[node] = links[node] or {}

            for _, n in pairs(checks) do
                if n and n.walkable then
                    links[node][n] = {
                        walkable = true
                    }
                end
            end
        end
    end
end

function UnitControl.resetLinks()
    for n1, nodetab in pairs(links) do
        for n2, link in pairs(nodetab) do
            updateLink(links, n1, n2, {
                walkable = true,
                combat = false,
                movement = false,
            })
        end
    end
end

function UnitControl.evalCombatLinks()
    UnitControl.resetLinks()

    for _, node in pairs(nodes) do
        if node.type == "F" then
            for _, neighbour in pairs(getNeighbours(node)) do
                if neighbour.type == "H" then
                    updateLink(links, node, neighbour, {
                        walkable = false,
                        combat = true,
                    })
                    node.inCombat = true
                elseif neighbour.type == "F" then
                    updateLink(links, node, neighbour, {
                        walkable = false,
                        combat = false,
                    })
                end
            end
        elseif node.type == "H" then
            for _, neighbour in pairs(getNeighbours(node)) do
                if neighbour.type == "H" then
                    updateLink(links, node, neighbour, {
                        walkable = false,
                        combat = false,
                    })
                end
            end
        end
    end

    UnitControl.floodFillDepth()
    UnitControl.performRouting()
end

function UnitControl.floodFillDepth()

    local nodePool = {}

    for _, node in pairs(nodes) do
        node.depth = nil

        if node.type == "H" then
            node.depth = 0
            table.insert(nodePool, node)
        end
    end

    local maxDepth = 9

    while #nodePool > 0 do
        local newNodes = {}

        for _, node in pairs(nodePool) do
            for _, neighbour in pairs(getNeighbours(node)) do
                local walkable = neighbour.walkable or node.Type == "F"
                local noCombat = not neighbour.inCombat
                local lessDepth = (not neighbour.depth) or (neighbour.depth > node.depth + 1)

                if walkable and noCombat and lessDepth then
                    neighbour.depth = node.depth + 1

                    if neighbour.depth < maxDepth then
                        table.insert(newNodes, neighbour)
                    end
                end
            end
        end

        nodePool = newNodes
    end
end

function UnitControl.performRouting()

    for _, node in pairs(nodes) do
        node.moving = nil
        node.inbound = nil
    end
    
    --For each depth level
        --Propose movement
        --Evaluate and confirm all non-conflicting movements
        --Reevaluate movements until none left or all remaining are conflicting

    for d = 1, 9 do
        local movements = {}
        local possibilities = {}

        --Propose movements
        for _, node in pairs(nodes) do
            if node.type == "F" and node.depth == d then
                possibilities[node] = {}

                for _, neighbour in pairs(getNeighbours(node)) do
                    local canWalk = neighbour.walkable or neighbour.moving
                    local lessDepth = neighbour.depth and neighbour.depth < node.depth

                    if canWalk and lessDepth then
                        movements[neighbour] = movements[neighbour] or {}
                        table.insert(movements[neighbour], node)
                        table.insert(possibilities[node], neighbour)
                    end
                end
            end
        end

        local wasConflict, updated

        --Evaluate conflicts
        repeat
            wasConflict = false
            updated = false

            for destination, inbound in pairs(movements) do
                local requests = 0
                local from
                local lowestPossibilities = 100
                
                for _, node in pairs(inbound) do
                    if not node.moving then
                        requests = requests + 1

                        if #possibilities[node] < lowestPossibilities then
                            from = node
                            lowestPossibilities = #possibilities[node]
                        end
                    end
                end

                if (from and not destination.inbound) then --and (requests == 1 or #possibilities[from] == 1) then
                    updated = true
                    from.moving = true
                    destination.inbound = true

                    updateLink(links, from, destination, {
                        walkable = false,
                        combat = false,
                        movement = true,
                    })

                elseif requests > 1 then
                    wasConflict = true
                end
            end

            if wasConflict and not update then
                
            end

        until (not wasConflict) or (not updated)
    end
end

function UnitControl.evalLocalArea()
    local playerPosition = ClientUtil.getTilePositionUnderPlayer()

    for x = -evalSize, evalSize do
        for y = -evalSize, evalSize do
            UnitControl.evalNodePosition(playerPosition + Vector2.new(x, y))
            UnitControl.evalNodePosition(playerPosition + Vector2.new(x + 0.3333, y + 0.6666))
            UnitControl.evalNodePosition(playerPosition + Vector2.new(x + 0.6666, y + 0.3333))
        end
    end

    UnitControl.evalWalkableLinks()
end

function UnitControl.getNodes()
    return nodes
end

function UnitControl.getLinks()
    return links
end

return UnitControl
