--!strict
-- Infection Tag: one random player starts infected and is faster than everyone else.
-- Getting within tag range of a survivor infects them too, so the infected side grows
-- by chain reaction. Survivors win if any of them are still clean when the round timer
-- expires; the infected side wins outright the moment everyone has been turned.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local MinigameUtils = require(script.Parent.Parent:WaitForChild("MinigameUtils"))

local InfectionTag = {}

local arenaFolder: Folder? = nil
local heartbeatConnection: RBXScriptConnection? = nil
local roster: { Player } = {}
local infected: { [Player]: boolean } = {}
local highlights: { [Player]: Highlight } = {}
local running = false

local function buildArena(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "InfectionArena"

	local center = Config.InfectionTag.Center
	local radius = Config.InfectionTag.ArenaRadius

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(radius * 2, 2, radius * 2)
	floor.Position = Vector3.new(center.X, center.Y - 1, center.Z)
	floor.Anchored = true
	floor.Material = Enum.Material.Concrete
	floor.Color = Color3.fromRGB(110, 110, 120)
	floor.Parent = folder

	local wallSegments = 16
	for i = 1, wallSegments do
		local angle1 = (i / wallSegments) * math.pi * 2
		local angle2 = ((i + 1) / wallSegments) * math.pi * 2
		local p1 = Vector3.new(center.X + math.cos(angle1) * radius, center.Y, center.Z + math.sin(angle1) * radius)
		local p2 = Vector3.new(center.X + math.cos(angle2) * radius, center.Y, center.Z + math.sin(angle2) * radius)
		local mid = (p1 + p2) / 2
		local length = (p2 - p1).Magnitude

		local wall = Instance.new("Part")
		wall.Name = "Wall"
		wall.Size = Vector3.new(1, Config.InfectionTag.WallHeight, length + 0.5)
		wall.CFrame = CFrame.new(mid, p2) * CFrame.new(0, Config.InfectionTag.WallHeight / 2, 0)
		wall.Anchored = true
		wall.Transparency = 0.6
		wall.Material = Enum.Material.ForceField
		wall.Color = Color3.fromRGB(200, 60, 60)
		wall.Parent = folder
	end

	for i = 1, Config.InfectionTag.PillarCount do
		local angle = (i / Config.InfectionTag.PillarCount) * math.pi * 2 + 0.3
		local pillarRadius = radius * (0.3 + 0.4 * ((i % 3) / 3))
		local x = center.X + math.cos(angle) * pillarRadius
		local z = center.Z + math.sin(angle) * pillarRadius

		local pillar = Instance.new("Part")
		pillar.Name = "Pillar"
		pillar.Shape = Enum.PartType.Cylinder
		pillar.Size = Vector3.new(Config.InfectionTag.PillarHeight, Config.InfectionTag.PillarRadius * 2, Config.InfectionTag.PillarRadius * 2)
		pillar.CFrame = CFrame.new(x, center.Y + Config.InfectionTag.PillarHeight / 2, z) * CFrame.Angles(0, 0, math.rad(90))
		pillar.Anchored = true
		pillar.Material = Enum.Material.Rock
		pillar.Color = Color3.fromRGB(130, 120, 110)
		pillar.Parent = folder
	end

	folder.Parent = Workspace
	return folder
end

local function applyRole(player: Player, isInfected: boolean)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if isInfected then Config.InfectionTag.InfectedSpeed else Config.InfectionTag.SurvivorSpeed
	end

	local existing = highlights[player]
	if existing then
		existing:Destroy()
	end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = if isInfected then Color3.fromRGB(220, 40, 40) else Color3.fromRGB(60, 220, 120)
	highlight.FillTransparency = 0.4
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.Parent = character
	highlights[player] = highlight
end

local function survivorsList(): { Player }
	local survivors: { Player } = {}
	for _, player in roster do
		if not infected[player] then
			table.insert(survivors, player)
		end
	end
	return survivors
end

function InfectionTag.Init(players: { Player })
	roster = players
	infected = {}
	highlights = {}

	arenaFolder = buildArena()
	MinigameUtils.TeleportPlayersInCircle(players, Config.InfectionTag.Center, Config.InfectionTag.ArenaRadius * 0.5, 4)

	if #players > 0 then
		local firstInfected = players[math.random(1, #players)]
		infected[firstInfected] = true
	end
end

function InfectionTag.Start()
	running = true
	for _, player in roster do
		applyRole(player, infected[player] == true)
	end

	heartbeatConnection = RunService.Heartbeat:Connect(function()
		for _, chaser in roster do
			if not infected[chaser] then
				continue
			end
			local chaserCharacter = chaser.Character
			local chaserRoot = chaserCharacter and chaserCharacter:FindFirstChild("HumanoidRootPart")
			if not chaserRoot then
				continue
			end
			for _, target in roster do
				if infected[target] then
					continue
				end
				local targetCharacter = target.Character
				local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
				if not targetRoot then
					continue
				end
				local distance = ((chaserRoot :: BasePart).Position - (targetRoot :: BasePart).Position).Magnitude
				if distance <= Config.InfectionTag.TagRadius then
					infected[target] = true
					applyRole(target, true)
				end
			end
		end
	end)
end

function InfectionTag.Cleanup()
	running = false
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	for _, highlight in pairs(highlights) do
		if highlight.Parent then
			highlight:Destroy()
		end
	end
	highlights = {}
	if arenaFolder then
		arenaFolder:Destroy()
		arenaFolder = nil
	end
	infected = {}
	roster = {}
end

function InfectionTag.GetWinners(final: boolean?): { Player }
	local survivors = survivorsList()
	if #survivors == 0 then
		local infectedList: { Player } = {}
		for player in pairs(infected) do
			table.insert(infectedList, player)
		end
		return infectedList
	end
	if final then
		return survivors
	end
	return {}
end

return InfectionTag
