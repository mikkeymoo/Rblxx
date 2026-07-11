--!strict
-- Lava Rise: a climbable tower of scattered platforms. Lava rises steadily after a
-- short delay; players who touch it are eliminated. Highest survivor(s) win, whether
-- that's decided by last-one-standing or by height when the round timer forces an end.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local MinigameUtils = require(script.Parent.Parent:WaitForChild("MinigameUtils"))

local LavaRise = {}

local arenaFolder: Folder? = nil
local lavaPart: Part? = nil
local alive: { [Player]: boolean } = {}
local maxHeight: { [Player]: number } = {}
local heartbeatConnection: RBXScriptConnection? = nil
local roundStartClock: number? = nil

local function buildTower(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "LavaRiseTower"

	local center = Config.LavaRise.Center
	local towerRadius = Config.LavaRise.TowerRadius
	local spacing = Config.LavaRise.PlatformSpacing
	local platformCount = math.floor(Config.LavaRise.TowerHeight / spacing)

	for level = 0, platformCount do
		local y = center.Y + level * spacing
		local angleOffset = level * 0.7
		local ringPlatforms = 4
		for i = 1, ringPlatforms do
			local angle = angleOffset + (i / ringPlatforms) * math.pi * 2
			local radius = towerRadius * (0.5 + 0.5 * ((level % 3) / 3))
			local x = center.X + math.cos(angle) * radius
			local z = center.Z + math.sin(angle) * radius

			local platform = Instance.new("Part")
			platform.Name = "Platform"
			platform.Size = Vector3.new(8, 1, 8)
			platform.Position = Vector3.new(x, y, z)
			platform.Anchored = true
			platform.Material = Enum.Material.Rock
			platform.Color = Color3.fromRGB(120, 100, 90)
			platform.Parent = folder
		end
	end

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(towerRadius * 2.4, 2, towerRadius * 2.4)
	base.Position = Vector3.new(center.X, center.Y - 1, center.Z)
	base.Anchored = true
	base.Material = Enum.Material.Rock
	base.Color = Color3.fromRGB(90, 80, 75)
	base.Parent = folder

	local lava = Instance.new("Part")
	lava.Name = "Lava"
	lava.Size = Vector3.new(towerRadius * 2.4, 2, towerRadius * 2.4)
	lava.Position = Vector3.new(center.X, center.Y + Config.LavaRise.LavaStartHeight, center.Z)
	lava.Anchored = true
	lava.CanCollide = false
	lava.Material = Enum.Material.Neon
	lava.Color = Color3.fromRGB(255, 80, 20)
	lava.Parent = folder
	lavaPart = lava

	lava.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and alive[player] then
			alive[player] = nil
			MinigameUtils.SendToSpectate(player, CFrame.new(center + Vector3.new(0, Config.LavaRise.TowerHeight + 30, 0)))
		end
	end)

	folder.Parent = Workspace
	return folder
end

local function countAlive(): number
	local n = 0
	for _ in pairs(alive) do
		n += 1
	end
	return n
end

function LavaRise.Init(players: { Player })
	alive = {}
	maxHeight = {}
	for _, player in players do
		alive[player] = true
		maxHeight[player] = 0
	end
	roundStartClock = nil
	arenaFolder = buildTower()
	MinigameUtils.TeleportPlayersInCircle(players, Config.LavaRise.Center, Config.LavaRise.TowerRadius * 0.4, 4)
end

function LavaRise.Start()
	roundStartClock = os.clock()
	heartbeatConnection = RunService.Heartbeat:Connect(function()
		local lava = lavaPart
		local startClock = roundStartClock
		if not lava or not startClock then
			return
		end
		local elapsed = os.clock() - startClock
		if elapsed >= Config.LavaRise.LavaRiseStartDelay then
			local risenTime = elapsed - Config.LavaRise.LavaRiseStartDelay
			local newY = Config.LavaRise.Center.Y + Config.LavaRise.LavaStartHeight + risenTime * Config.LavaRise.LavaRiseSpeed
			lava.Position = Vector3.new(lava.Position.X, newY, lava.Position.Z)
		end

		for player in pairs(alive) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local height = (root :: BasePart).Position.Y - Config.LavaRise.Center.Y
				if height > (maxHeight[player] or 0) then
					maxHeight[player] = height
				end
			end
		end
	end)
end

function LavaRise.Cleanup()
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
	if arenaFolder then
		arenaFolder:Destroy()
		arenaFolder = nil
	end
	lavaPart = nil
	alive = {}
	maxHeight = {}
	roundStartClock = nil
end

function LavaRise.GetWinners(final: boolean?): { Player }
	local aliveCount = countAlive()
	if aliveCount <= 1 then
		local remaining: { Player } = {}
		for player in pairs(alive) do
			table.insert(remaining, player)
		end
		if #remaining > 0 then
			return remaining
		end
		if final then
			local bestPlayer: Player? = nil
			local bestHeight = -math.huge
			for player, height in pairs(maxHeight) do
				if height > bestHeight then
					bestHeight = height
					bestPlayer = player
				end
			end
			if bestPlayer then
				return { bestPlayer }
			end
		end
		return {}
	end

	if final then
		local bestHeight = -math.huge
		for player in pairs(alive) do
			local height = maxHeight[player] or 0
			if height > bestHeight then
				bestHeight = height
			end
		end
		local topPlayers: { Player } = {}
		for player in pairs(alive) do
			if (maxHeight[player] or 0) >= bestHeight - 0.01 then
				table.insert(topPlayers, player)
			end
		end
		return topPlayers
	end

	return {}
end

return LavaRise
