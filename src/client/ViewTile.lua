local ViewTile = {}
local Client   = script.Parent
local Common   = game.ReplicatedStorage.Pioneers.Common
local Assets   = game.ReplicatedStorage.Pioneers.Assets

local ClientUtil = require(Client.ClientUtil)
local World      = require(Common.World)
local Tile       = require(Common.Tile)
local Util       = require(Common.Util)

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")

local clamp = math.clamp
local playerId = Players.LocalPlayer.UserId

local TileToInstMap = {}
local InstToTileMap = {}
local playerTiles = {}
local sizeTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local meshes = {}
meshes[Tile.DESTROYED]= {mesh = Assets.Ruins,    offset = Vector3.new(0,     0 + 0.5,    0)}
meshes[Tile.GRASS]    = {mesh = Assets.Grass,    offset = Vector3.new(0,     0 + 0.5,    0)}
meshes[Tile.KEEP]     = {mesh = Assets.Keep,     offset = Vector3.new(0, 11.007, 0)}
meshes[Tile.HOUSE]    = {mesh = Assets.House,    offset = Vector3.new(0, 5.479, 0)}
meshes[Tile.PATH]     = {mesh = Assets.Path,     offset = Vector3.new(0,     0 + 0.5,    0)}
meshes[Tile.FARM]     = {mesh = Assets.Farm,     offset = Vector3.new(-0.015, 1.594, 0.059)}
meshes[Tile.FORESTRY] = {mesh = Assets.Forestry, offset = Vector3.new(0, 7.682, 0.131)}
meshes[Tile.MINE]     = {mesh = Assets.Mine,     offset = Vector3.new(0, 1.795,    0)}
meshes[Tile.STORAGE]  = {mesh = Assets.Storage,  offset = Vector3.new(0, 16.842, -0.459)}
meshes[Tile.BARRACKS] = {mesh = Assets.Barracks, offset = Vector3.new(0, 5.407, -0)}
meshes[Tile.WALL]     = {mesh = Assets.Wall,     offset = Vector3.new(0, 12.5, 0)}
meshes[Tile.GATE]     = {mesh = Assets.Gate,     offset = Vector3.new(0, 11.009 - 0.25 + 0.5, 0)}

local ruinTexture = "rbxassetid://3522322649"

local grassPathTextures = {}
grassPathTextures[0]  = "rbxassetid://3080817017"
grassPathTextures[1]  = "rbxassetid://3237288852"
grassPathTextures[5]  = "rbxassetid://3237282190"
grassPathTextures[9]  = "rbxassetid://3237282264"
grassPathTextures[21] = "rbxassetid://3237282124"
grassPathTextures[3]  = "rbxassetid://3522375154"
grassPathTextures[11] = "rbxassetid://3237281850"
grassPathTextures[19] = "rbxassetid://3237281781"
grassPathTextures[27] = "rbxassetid://3237279828"
grassPathTextures[7]  = "rbxassetid://3237284972"
grassPathTextures[23] = "rbxassetid://3237279749"
grassPathTextures[15] = "rbxassetid://3237284892"
grassPathTextures[31] = "rbxassetid://3237284550"
grassPathTextures[63] = "rbxassetid://3237284465"

local gptLookup = {
    { 1, 0}, { 1, 1}, { 3, 0}, { 1, 2},
    { 5, 0}, { 3, 1}, { 7, 0}, { 1, 3},
    { 9, 0}, { 5, 1}, {11, 0}, { 3, 2},
    {19, 2}, { 7, 1}, {15, 0}, { 1, 4},
    { 5, 4}, { 9, 1}, {19, 0}, { 5, 2},
    {21, 0}, {11, 1}, {23, 0}, { 3, 3},
    {11, 3}, {19, 3}, {27, 0}, { 7, 2},
    {23, 2}, {15, 1}, {31, 0}, { 1, 5},
    { 3, 5}, { 5, 5}, { 7, 5}, { 9, 2},
    {11, 5}, {19, 1}, {15, 5}, { 5, 3},
    {19, 5}, {21, 1}, {23, 5}, {11, 2},
    {27, 2}, {23, 1}, {31, 5}, { 3, 4},
    { 7, 4}, {11, 4}, {15, 4}, {19, 4},
    {23, 4}, {27, 1}, {31, 4}, { 7, 3},
    {15, 3}, {23, 3}, {31, 3}, {15, 2},
    {31, 2}, {31, 1}, {63, 0}
}
gptLookup[0] = {0, 0}

local currentTiles = {}
function ViewTile.init(tiles)
    currentTiles = tiles
end

function ViewTile.displayTile(tile, displaySize)



    if TileToInstMap[tile] then
        ViewTile.updateDisplay(tile, displaySize)
        return end

    local meshInfo
    
    meshInfo = meshes[tile.Type]

    local model = meshInfo.mesh:Clone()

    if displaySize ~= "SKIP" then
        model.Size = Vector3.new(0,0,0)
        tile.displaySize = 0
    else
        tile.displaySize = 1
    end

    TileToInstMap[tile] = model
    InstToTileMap[model] = tile
    model.CFrame = CFrame.new(Util.axialCoordToWorldCoord(tile.Position) + meshInfo.offset)

    if tile.Type == Tile.GATE then
        model.Bars.PrismaticConstraint.Enabled = false
        model.Bars.CFrame = model.CFrame
        model.Bars.PrismaticConstraint.Enabled = true
    end

    model.Parent = Workspace

    ViewTile.updateDisplay(tile, displaySize or 1)
end

function ViewTile.updateDisplay(tile, displaySize)
    local model = TileToInstMap[tile]

    if not model then
        return ViewTile.displayTile(tile)
    else
        if tile.OwnerId == playerId then
            playerTiles[model] = tile
        else
            playerTiles[model] = nil
        end
    end

    local displayInfo = meshes[tile.Type]

    if model.Name ~= displayInfo.mesh.Name then
        model:Destroy()
        TileToInstMap[tile] = nil
        InstToTileMap[model] = nil
        playerTiles[model] = nil
        return ViewTile.displayTile(tile, displaySize)
    end

    if displaySize and displaySize ~= "SKIP" and displaySize > tile.displaySize then
        TweenService:Create(model, sizeTween, {Size = displayInfo.mesh.Size * displaySize}):Play()
        tile.displaySize = displaySize
    elseif displaySize == "SKIP" then
        tile.displaySize = 1
        model.Size = displayInfo.mesh.Size
    end

    if tile.Type == Tile.GATE then
        local orientation
        local pos = tile.Position

        local n1 = World.getTile(currentTiles, pos.x + 1, pos.y)
        local n2 = World.getTile(currentTiles, pos.x - 1, pos.y)
        local n3 = World.getTile(currentTiles, pos.x + 1, pos.y + 1)
        local n4 = World.getTile(currentTiles, pos.x - 1, pos.y - 1)
        local n5 = World.getTile(currentTiles, pos.x    , pos.y + 1)
        local n6 = World.getTile(currentTiles, pos.x    , pos.y - 1)

        if (n1 and n1.Type == Tile.WALL and n2 and n2.Type == Tile.WALL) then
            orientation = 3
        elseif (n3 and n3.Type == Tile.WALL and n4 and n4.Type == Tile.WALL) then
            orientation = 1
        elseif (n5 and n5.Type == Tile.WALL and n6 and n6.Type == Tile.WALL) then
            orientation = 2
        end

        local cf = model.CFrame

        if orientation == 1 then
            model.CFrame = CFrame.new(model.Position) * CFrame.Angles(0, math.rad(60), 0)
        elseif orientation == 2 then
            model.CFrame = CFrame.new(model.Position) * CFrame.Angles(0, math.rad(120), 0)
        elseif orientation == 3 then
            model.CFrame = CFrame.new(model.Position) * CFrame.Angles(0, 0, 0)
        end
        
        if model.CFrame ~= cf then
            model.Bars.PrismaticConstraint.Enabled = false
            model.Bars.CFrame = model.CFrame
            model.Bars.PrismaticConstraint.Enabled = true
        end
    end

    if tile.Type == Tile.GRASS then
        local pos = tile.Position

        local n1 = World.getTile(currentTiles, pos.x    , pos.y + 1)
        local n2 = World.getTile(currentTiles, pos.x + 1, pos.y + 1)
        local n3 = World.getTile(currentTiles, pos.x + 1, pos.y    )
        local n4 = World.getTile(currentTiles, pos.x    , pos.y - 1)
        local n5 = World.getTile(currentTiles, pos.x - 1, pos.y - 1)
        local n6 = World.getTile(currentTiles, pos.x - 1, pos.y    )

        local encodedString = 
           (n6 and n6.Type == Tile.PATH and "1" or "0")
        .. (n5 and n5.Type == Tile.PATH and "1" or "0")
        .. (n4 and n4.Type == Tile.PATH and "1" or "0")
        .. (n3 and n3.Type == Tile.PATH and "1" or "0")
        .. (n2 and n2.Type == Tile.PATH and "1" or "0")
        .. (n1 and n1.Type == Tile.PATH and "1" or "0")

        local info = gptLookup[tonumber(encodedString, 2)]
        local texture = grassPathTextures[info[1]]
        local rotation = (info[2] + 1)%6

        model.CFrame = CFrame.new(model.Position) * CFrame.Angles(0, -(math.pi/3) * rotation, 0)
        model.TextureID = texture
    end

    if tile.Health and tile.Health <= 0 then
        model.TextureID = ruinTexture
    end
end

function ViewTile.getInstFromTile(tile)
    return TileToInstMap[tile]
end

function ViewTile.getTileFromInst(inst)
    return InstToTileMap[inst]
end

function ViewTile.getPlayerTiles()
    return playerTiles
end

function ViewTile.getOtherPlayerTiles(userId)
    local tiles = {}

    for pos, tile in pairs(currentTiles) do
        if tile.OwnerId and tile.OwnerId ~= userId then
            table.insert(tiles, tile)
        end
    end

    return tiles
end

function ViewTile.getPlayerTilesOfType(type)
    local tiles = {}
    
    for _, tile in pairs(playerTiles) do
        if tile.Type == type then
            table.insert(tiles, tile)
        end
    end

    return tiles
end

return ViewTile