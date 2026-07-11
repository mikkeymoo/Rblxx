--!strict
-- Builds the lobby (baseplate + spawn pads) procedurally at server startup. No Studio
-- authoring is required; everything here is created with Instance.new at runtime.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local LobbyBuilder = {}

local LOBBY_NAME = "Lobby"

function LobbyBuilder.Build(): Model
	local existing = Workspace:FindFirstChild(LOBBY_NAME)
	if existing then
		existing:Destroy()
	end

	local lobby = Instance.new("Model")
	lobby.Name = LOBBY_NAME

	local baseplate = Instance.new("Part")
	baseplate.Name = "Baseplate"
	baseplate.Size = Vector3.new(Config.LobbyRadius * 2, 4, Config.LobbyRadius * 2)
	baseplate.Position = Vector3.new(0, -2, 0)
	baseplate.Anchored = true
	baseplate.Material = Enum.Material.Grass
	baseplate.Color = Color3.fromRGB(74, 128, 71)
	baseplate.Parent = lobby

	local spawnFolder = Instance.new("Folder")
	spawnFolder.Name = "SpawnPads"
	spawnFolder.Parent = lobby

	local padRadius = Config.LobbyRadius * 0.6
	for i = 1, Config.SpawnPadCount do
		local angle = (i / Config.SpawnPadCount) * math.pi * 2
		local x = math.cos(angle) * padRadius
		local z = math.sin(angle) * padRadius

		local pad = Instance.new("Part")
		pad.Name = "SpawnPad" .. i
		pad.Shape = Enum.PartType.Cylinder
		pad.Size = Vector3.new(1, 6, 6)
		pad.CFrame = CFrame.new(x, 0.5, z) * CFrame.Angles(0, 0, math.rad(90))
		pad.Anchored = true
		pad.Material = Enum.Material.Neon
		pad.Color = Color3.fromRGB(85, 170, 255)
		pad.Parent = spawnFolder

		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = "Spawn" .. i
		spawnLocation.Size = Vector3.new(5, 1, 5)
		spawnLocation.CFrame = CFrame.new(x, 1.5, z)
		spawnLocation.Anchored = true
		spawnLocation.CanCollide = false
		spawnLocation.Transparency = 1
		spawnLocation.Neutral = true
		spawnLocation.Duration = 0
		spawnLocation.Parent = spawnFolder
	end

	lobby.Parent = Workspace
	return lobby
end

return LobbyBuilder
