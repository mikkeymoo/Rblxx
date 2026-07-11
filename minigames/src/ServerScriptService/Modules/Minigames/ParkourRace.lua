--!strict
-- Parkour Race: a zig-zagging chain of platforms, some of which tween back and forth.
-- Touching a platform sets it as your checkpoint; falling respawns you there instead of
-- eliminating you. First to touch the finish platform wins outright. If the round timer
-- forces an end, whoever reached the furthest checkpoint wins (ties share the win).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local MinigameUtils = require(script.Parent.Parent:WaitForChild("MinigameUtils"))

local ParkourRace = {}

local arenaFolder: Folder? = nil
local fallConnection: RBXScriptConnection? = nil
local participants: { Player } = {}
local roster: { [Player]: boolean } = {}
local checkpointIndex: { [Player]: number } = {}
local checkpointCFrame: { [Player]: CFrame } = {}
local finished: { [Player]: boolean } = {}
local winners: { Player } = {}
local running = false

local function buildCourse(): (Folder, CFrame)
	local folder = Instance.new("Folder")
	folder.Name = "ParkourCourse"

	local center = Config.ParkourRace.Center
	local spacing = Config.ParkourRace.SegmentSpacing
	local count = Config.ParkourRace.SegmentCount
	local size = Config.ParkourRace.PlatformSize

	local startCFrame: CFrame = CFrame.new(center + Vector3.new(0, 4, 0))

	for i = 0, count do
		local isStart = i == 0
		local isFinish = i == count
		local isMoving = not isStart and not isFinish and (i % Config.ParkourRace.MovingEvery == 0)

		local x = center.X + i * spacing
		local zOffset = 0
		if not isStart and not isFinish then
			zOffset = (i % 2 == 0) and 4 or -4
		end
		local z = center.Z + zOffset
		local y = center.Y

		local platform = Instance.new("Part")
		platform.Name = if isFinish then "Finish" elseif isStart then "Start" else `Segment{i}`
		platform.Size = if isFinish or isStart then Config.ParkourRace.FinishPlatformSize else size
		platform.Position = Vector3.new(x, y, z)
		platform.Anchored = true
		platform.Material = if isFinish then Enum.Material.Neon elseif isMoving then Enum.Material.Metal else Enum.Material.WoodPlanks
		platform.Color = if isFinish
			then Color3.fromRGB(80, 220, 120)
			elseif isMoving then Color3.fromRGB(200, 200, 210)
			else Color3.fromRGB(150, 110, 70)
		platform.Parent = folder

		if isStart then
			startCFrame = CFrame.new(x, y + 4, z)
		end

		local segmentIndex = i
		local checkpointCF = CFrame.new(x, y + 4, z)

		platform.Touched:Connect(function(hit: BasePart)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player or not roster[player] then
				return
			end
			if isFinish then
				if not finished[player] then
					finished[player] = true
					if #winners == 0 then
						table.insert(winners, player)
					end
				end
				return
			end
			if (checkpointIndex[player] or 0) < segmentIndex then
				checkpointIndex[player] = segmentIndex
				checkpointCFrame[player] = checkpointCF
			end
		end)

		if isMoving then
			local goalCFrame = platform.CFrame * CFrame.new(0, 0, Config.ParkourRace.MovingTravel)
			local tween = TweenService:Create(
				platform,
				TweenInfo.new(Config.ParkourRace.MovingDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ CFrame = goalCFrame }
			)
			tween:Play()
		end
	end

	folder.Parent = Workspace
	return folder, startCFrame
end

local function startFallWatch(): RBXScriptConnection
	return RunService.Heartbeat:Connect(function()
		for _, player in participants do
			if finished[player] then
				continue
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then
				continue
			end
			local cframe = checkpointCFrame[player]
			if not cframe then
				continue
			end
			if (root :: BasePart).Position.Y < cframe.Position.Y - Config.ParkourRace.FallMargin then
				(character :: Model):PivotTo(cframe)
				local rootPart = root :: BasePart
				rootPart.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end)
end

function ParkourRace.Init(players: { Player })
	participants = players
	roster = {}
	checkpointIndex = {}
	checkpointCFrame = {}
	finished = {}
	winners = {}

	for _, player in players do
		roster[player] = true
		checkpointIndex[player] = 0
	end

	local folder, startCFrame = buildCourse()
	arenaFolder = folder
	for _, player in players do
		checkpointCFrame[player] = startCFrame
	end

	MinigameUtils.TeleportPlayersInCircle(players, Config.ParkourRace.Center, 4, 4)
end

function ParkourRace.Start()
	running = true
	fallConnection = startFallWatch()
end

function ParkourRace.Cleanup()
	running = false
	if fallConnection then
		fallConnection:Disconnect()
		fallConnection = nil
	end
	if arenaFolder then
		arenaFolder:Destroy()
		arenaFolder = nil
	end
	participants = {}
	roster = {}
	checkpointIndex = {}
	checkpointCFrame = {}
	finished = {}
end

function ParkourRace.GetWinners(final: boolean?): { Player }
	if #winners > 0 then
		return winners
	end
	if not final then
		return {}
	end

	local best = -1
	for _, player in participants do
		local cp = checkpointIndex[player] or 0
		if cp > best then
			best = cp
		end
	end
	if best < 0 then
		return {}
	end

	local top: { Player } = {}
	for _, player in participants do
		if (checkpointIndex[player] or 0) >= best then
			table.insert(top, player)
		end
	end
	return top
end

return ParkourRace
