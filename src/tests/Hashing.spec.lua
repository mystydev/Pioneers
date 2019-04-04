


return (function()


    local Common = game.ReplicatedStorage.Pioneers.Common

    local World = require(Common.World)
    local UserStats = require(Common.UserStats)
    local Tile = require(Common.Tile)
    local Unit = require(Common.Unit)
    local Resource = require(Common.Resource)

    local origSize = World.SIZE
    World.SIZE = 100

    local testTiles = {}

    for x = 0, World.SIZE do
        testTiles[x] = {}
        for y = 0, World.SIZE do
            testTiles[x][y] = Tile.new(Tile.GRASS)
        end
    end

    testTiles[80][70] = Tile.new(Tile.KEEP)
    testTiles[58][37] = Tile.new(Tile.BARRACKS)
    testTiles[73][63] = Tile.new(Tile.MINE)
    
    local testUnits = {}

    testUnits["63561632:0"] = Unit.new(Unit.VILLAGER, "63561632:0", 63561632, Vector3.new(50, 40, 0), 0, 0, nil, nil, nil, nil)
    testUnits["63561632:1"] = Unit.new(Unit.VILLAGER, "63561632:1", 63561632, Vector3.new(70, 22, 0), 0, 0, nil, nil, nil, nil)

    local testWorld = World.new(testTiles, testUnits)

    describe("worldHash", function()
        it("should correctly hash", function()
            World.SIZE = 100
            local hash = World.computeHash(testWorld)
            print("Found hash:", hash)
            expect(hash).to.be.equal("00080bf0000b6080")
            World.SIZE = origSize
        end)
    end)

    World.SIZE = origSize
end)