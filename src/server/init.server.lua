

print("Pioneers server performing auto-tests")

local TestEZ = require(game.ReplicatedStorage.TestEZ)
TestEZ.TestBootstrap:run(game.ReplicatedStorage.Pioneers.Tests:GetChildren())
