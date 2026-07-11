--!strict
-- Builds a Signal Jammer arena: a circular floor with a moving capture point.
-- Pulse waves are spawned/despawned at runtime by the minigame module itself
-- (their position changes every telegraph, so they aren't part of the static
-- map); this builder only lays down the floor, boundary, and capture point.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Hardcore:WaitForChild("Config"))
local HardcoreUtils = require(ServerScriptService.Hardcore:WaitForChild("HardcoreUtils"))

local Builder = {}

function Builder.Build(parent: Instance): Folder
	local cfg = Config.SignalJammer

	local container = Instance.new("Folder")
	container.Name = "SignalJammerArena"

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.CanCollide = true
	floor.Shape = Enum.PartType.Cylinder
	floor.Material = Enum.Material.Basalt
	floor.Color = Color3.fromRGB(45, 48, 58)
	floor.Size = Vector3.new(4, cfg.ArenaRadius * 2, cfg.ArenaRadius * 2)
	floor.CFrame = CFrame.new(cfg.Center) * CFrame.Angles(0, 0, math.rad(90))
	floor.Parent = container

	-- Low glowing rim so players can see the arena edge against the void.
	local rim = Instance.new("Part")
	rim.Name = "Rim"
	rim.Anchored = true
	rim.CanCollide = false
	rim.Shape = Enum.PartType.Cylinder
	rim.Material = Enum.Material.Neon
	rim.Color = Color3.fromRGB(80, 160, 255)
	rim.Size = Vector3.new(1, cfg.ArenaRadius * 2 + 2, cfg.ArenaRadius * 2 + 2)
	rim.CFrame = CFrame.new(cfg.Center - Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	rim.Parent = container

	local capturePoint = Instance.new("Part")
	capturePoint.Name = "CapturePoint"
	capturePoint.Anchored = true
	capturePoint.CanCollide = false
	capturePoint.Shape = Enum.PartType.Cylinder
	capturePoint.Material = Enum.Material.Neon
	capturePoint.Color = Color3.fromRGB(255, 210, 60)
	capturePoint.Size = Vector3.new(0.5, cfg.CapturePointRadius * 2, cfg.CapturePointRadius * 2)
	capturePoint.CFrame = CFrame.new(cfg.Center + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	capturePoint.Parent = container

	local pulses = Instance.new("Folder")
	pulses.Name = "Pulses"
	pulses.Parent = container

	HardcoreUtils.BuildSpectatorStand(container, cfg.Center + Vector3.new(cfg.ArenaRadius + 20, 6, 0))

	container.Parent = parent
	return container
end

return Builder
