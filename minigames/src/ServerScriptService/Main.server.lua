--!strict
-- Entry point: sets up leaderstats for players and starts the round loop.
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Modules = ServerScriptService:WaitForChild("Modules")
local GameManager = require(Modules:WaitForChild("GameManager"))
local PlayerData = require(Modules:WaitForChild("PlayerData"))

Players.PlayerAdded:Connect(function(player)
	PlayerData.Init(player)
end)

for _, player in Players:GetPlayers() do
	PlayerData.Init(player)
end

GameManager.Run()
