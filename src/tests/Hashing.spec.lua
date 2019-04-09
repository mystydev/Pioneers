


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
        for y = 0, World.SIZE do
            World.setTile(testTiles, Tile.new(Tile.GRASS), x, y)
        end
    end

    World.setTile(testTiles, Tile.new(Tile.KEEP), 80, 70)
    World.setTile(testTiles, Tile.new(Tile.BARRACKS), 58, 37)
    World.setTile(testTiles, Tile.new(Tile.MINE), 73, 63)
    
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