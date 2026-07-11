--!strict
-- Builds a Freefall Gauntlet shaft: a vertical stack of rotating hazard
-- rings, each with one open gap arc, plus a landing pad at the bottom.
-- Ring rotation is driven every frame by the minigame module; this builder
-- only lays down the initial geometry.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Hardcore:WaitForChild("Config"))
local Escalation = require(ReplicatedStorage.Hardcore:WaitForChild("Escalation"))
local HardcoreUtils = require(ServerScriptService.Hardcore:WaitForChild("HardcoreUtils"))

local Builder = {}

local SEGMENT_ARC_DEGREES = 20 -- each ring is built from fixed-size segments; the gap eats into these

-- Builds one ring as a Model of solid segments covering (360 - gapDegrees)
-- degrees around local origin, leaving one open gap. The model's own pivot
-- is left at its construction pose so PivotTo(center * angle) each frame
-- gives an absolute, drift-free rotation.
local function newRing(ringIndex: number, cfg: Config.FreefallGauntletConfig, gapDegrees: number): Model
	local ring = Instance.new("Model")
	ring.Name = `Ring{ringIndex}`

	local coveredDegrees = 360 - gapDegrees
	local segmentCount = math.max(math.floor(coveredDegrees / SEGMENT_ARC_DEGREES), 4)
	local step = coveredDegrees / segmentCount
	local startDegrees = gapDegrees / 2 -- centers the gap on angle 0

	for i = 0, segmentCount - 1 do
		local angle = math.rad(startDegrees + (i + 0.5) * step)
		local localPos = Vector3.new(math.cos(angle) * cfg.RingRadius, 0, math.sin(angle) * cfg.RingRadius)

		local segment = Instance.new("Part")
		segment.Name = `Segment{i}`
		segment.Anchored = true
		segment.CanCollide = true
		segment.Material = Enum.Material.Metal
		segment.Color = if ringIndex % 2 == 0 then Color3.fromRGB(200, 60, 60) else Color3.fromRGB(60, 70, 200)
		local chordLength = 2 * cfg.RingRadius * math.sin(math.rad(step) / 2) * 1.15
		segment.Size = Vector3.new(chordLength, cfg.RingThickness, cfg.RingThickness)
		segment.CFrame = CFrame.new(localPos) * CFrame.Angles(0, -angle, 0)
		segment.Parent = ring
	end

	local primary = ring:FindFirstChildWhichIsA("BasePart")
	if primary then
		ring.PrimaryPart = primary :: BasePart
	end

	return ring
end

function Builder.Build(parent: Instance): Folder
	local cfg = Config.FreefallGauntlet

	local container = Instance.new("Folder")
	container.Name = "FreefallGauntletArena"

	local rings = Instance.new("Folder")
	rings.Name = "Rings"
	rings.Parent = container

	-- Gap size shrinks by depth (ring index), not clock time: a player's
	-- progress through the shaft is what should get harder, not how long
	-- the overall round has run, since players fall at different rates.
	for i = 1, cfg.RingCount do
		local ringY = cfg.TopCenter.Y - (i * cfg.RingSpacing)
		local depthFraction = if cfg.RingCount > 1 then (i - 1) / (cfg.RingCount - 1) else 1
		local gapDegrees = Escalation.Evaluate(cfg.GapSize, depthFraction)
		local ring = newRing(i, cfg, gapDegrees)
		ring:PivotTo(CFrame.new(cfg.TopCenter.X, ringY, cfg.TopCenter.Z))
		ring.Parent = rings
	end

	local landingPad = Instance.new("Part")
	landingPad.Name = "LandingPad"
	landingPad.Anchored = true
	landingPad.CanCollide = true
	landingPad.Material = Enum.Material.ForceField
	landingPad.Color = Color3.fromRGB(80, 255, 140)
	landingPad.Size = Vector3.new(cfg.RingRadius * 2.5, 2, cfg.RingRadius * 2.5)
	local padY = cfg.TopCenter.Y - ((cfg.RingCount + 1) * cfg.RingSpacing)
	landingPad.CFrame = CFrame.new(cfg.TopCenter.X, padY, cfg.TopCenter.Z)
	landingPad.Parent = container

	local startPad = Instance.new("Part")
	startPad.Name = "StartPad"
	startPad.Anchored = true
	startPad.CanCollide = true
	startPad.Material = Enum.Material.Neon
	startPad.Color = Color3.fromRGB(255, 255, 255)
	startPad.Size = Vector3.new(cfg.RingRadius * 1.5, 1, cfg.RingRadius * 1.5)
	startPad.CFrame = CFrame.new(cfg.TopCenter.X, cfg.TopCenter.Y + 4, cfg.TopCenter.Z)
	startPad.Parent = container

	HardcoreUtils.BuildSpectatorStand(container, cfg.TopCenter + Vector3.new(cfg.RingRadius + 20, 10, 0))

	container.Parent = parent
	return container
end

return Builder
