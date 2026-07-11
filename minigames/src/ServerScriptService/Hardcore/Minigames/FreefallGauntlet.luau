--!strict
-- Freefall Gauntlet: a vertical descent through rotating hazard rings.
-- Touching a ring segment (or missing a gap, which is physically the same
-- collision) eliminates you; reaching the landing pad alive scores by
-- placement/time. Rotation speed escalates with round time; gap size is
-- baked into the map by depth (see FreefallGauntletMap).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Hardcore:WaitForChild("Config"))
local Escalation = require(ReplicatedStorage.Hardcore:WaitForChild("Escalation"))
local Signal = require(ReplicatedStorage.Hardcore:WaitForChild("Signal"))
local Remotes = require(ReplicatedStorage.Hardcore:WaitForChild("Remotes"))
local Types = require(ReplicatedStorage.Hardcore:WaitForChild("Types"))
local MinigameUtils = require(ServerScriptService.Modules:WaitForChild("MinigameUtils"))

type PlayerResult = Types.PlayerResult
type MinigameContext = Types.MinigameContext

type LandedEntry = { Player: Player, Score: number }

local FreefallGauntlet = {}
FreefallGauntlet.__index = FreefallGauntlet

FreefallGauntlet.Metadata = {
	Name = "Freefall Gauntlet",
	MinPlayers = 1,
	MaxPlayers = 24,
	SupportsTeams = false,
	RoundDurationCap = 75,
} :: Types.MinigameMetadata

export type FreefallGauntletInstance = typeof(setmetatable(
	{} :: {
		_context: MinigameContext,
		_cfg: Config.FreefallGauntletConfig,
		_alive: { [Player]: boolean },
		_doneSet: { [Player]: boolean },
		_eliminatedOrder: { Player },
		_landedOrder: { LandedEntry },
		_ringModels: { [number]: Model },
		_ringCenters: { [number]: Vector3 },
		_ringAngles: { [number]: number },
		_startClock: number,
		_spectatePos: CFrame,
		Completed: Signal.Signal,
	},
	FreefallGauntlet
))

function FreefallGauntlet.new(context: MinigameContext): FreefallGauntletInstance
	local self = setmetatable({
		_context = context,
		_cfg = Config.FreefallGauntlet,
		_alive = {},
		_doneSet = {},
		_eliminatedOrder = {},
		_landedOrder = {},
		_ringModels = {},
		_ringCenters = {},
		_ringAngles = {},
		_startClock = os.clock(),
		_spectatePos = CFrame.new(),
		Completed = Signal.new(),
	}, FreefallGauntlet) :: FreefallGauntletInstance

	for _, player in context.Participants do
		self._alive[player] = true
	end

	local stand = context.Arena:FindFirstChild("SpectatorStand") :: BasePart?
	if stand then
		self._spectatePos = stand.CFrame + Vector3.new(0, 4, 0)
	end

	context.Cleanup:Add(self.Completed)

	return self
end

function FreefallGauntlet.ElapsedFraction(self: FreefallGauntletInstance): number
	local elapsed = os.clock() - self._startClock
	return Escalation.Clamp01(elapsed / FreefallGauntlet.Metadata.RoundDurationCap)
end

function FreefallGauntlet.BroadcastHud(self: FreefallGauntletInstance)
	local playersLeft = 0
	for _ in self._alive do
		playersLeft += 1
	end
	Remotes.GetEvent("GameUpdate"):FireAllClients({
		Game = FreefallGauntlet.Metadata.Name,
		PlayersLeft = playersLeft,
		Landed = #self._landedOrder,
	})
end

function FreefallGauntlet.CheckForFinish(self: FreefallGauntletInstance)
	local aliveCount = 0
	for _ in self._alive do
		aliveCount += 1
	end
	if aliveCount == 0 then
		self.Completed:Fire()
	end
end

-- Both this and OnPlayerLanded guard on _doneSet rather than _alive:
-- MinigameUtils.WatchForFalls nils the alive table itself before invoking
-- its callback, so a fall-triggered elimination would otherwise see
-- _alive[player] already gone and no-op.
function FreefallGauntlet.OnPlayerEliminated(self: FreefallGauntletInstance, player: Player)
	if self._doneSet[player] then
		return
	end
	self._doneSet[player] = true
	self._alive[player] = nil
	table.insert(self._eliminatedOrder, player)

	MinigameUtils.SendToSpectate(player, self._spectatePos)
	Remotes.GetEvent("YouWereEliminated"):FireClient(player)
	self:BroadcastHud()
	self:CheckForFinish()
end

function FreefallGauntlet.OnPlayerLanded(self: FreefallGauntletInstance, player: Player)
	if self._doneSet[player] then
		return
	end
	self._doneSet[player] = true
	self._alive[player] = nil

	local elapsed = os.clock() - self._startClock
	local score = math.max(0, 1000 - math.floor(elapsed * 5))
	table.insert(self._landedOrder, { Player = player, Score = score })

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end

	self:BroadcastHud()
	self:CheckForFinish()
end

function FreefallGauntlet.ApplyWindGust(self: FreefallGauntletInstance)
	local angle = math.random() * math.pi * 2
	local direction = Vector3.new(math.cos(angle), 0, math.sin(angle)) * self._cfg.WindGustForce
	for player in self._alive do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			(root :: BasePart).AssemblyLinearVelocity += direction
		end
	end
end

function FreefallGauntlet.CurrentHeight(self: FreefallGauntletInstance, player: Player): number
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		return (root :: BasePart).Position.Y
	end
	return -math.huge
end

function FreefallGauntlet.Start(self: FreefallGauntletInstance)
	self._startClock = os.clock()
	local cfg = self._cfg
	local arena = self._context.Arena

	MinigameUtils.TeleportPlayersInCircle(self._context.Participants, cfg.TopCenter, cfg.RingRadius * 0.4, 5)

	local ringsFolder = arena:WaitForChild("Rings")
	for _, ringInstance in ringsFolder:GetChildren() do
		local ringModel = ringInstance :: Model
		local index = tonumber(string.match(ringModel.Name, "%d+"))
		if index then
			self._ringModels[index] = ringModel
			self._ringCenters[index] = ringModel:GetPivot().Position
			self._ringAngles[index] = 0
		end
		for _, descendant in ringModel:GetDescendants() do
			if descendant:IsA("BasePart") then
				self._context.Cleanup:Connect(descendant.Touched, function(hit: BasePart)
					local character = hit.Parent
					local player = character and Players:GetPlayerFromCharacter(character)
					if player and self._alive[player] then
						self:OnPlayerEliminated(player)
					end
				end)
			end
		end
	end

	local landingPad = arena:WaitForChild("LandingPad") :: BasePart
	self._context.Cleanup:Connect(landingPad.Touched, function(hit: BasePart)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and self._alive[player] then
			self:OnPlayerLanded(player)
		end
	end)

	local fallConnection = MinigameUtils.WatchForFalls(function()
		return cfg.KillY
	end, self._alive, function(player: Player)
		self:OnPlayerEliminated(player)
	end)
	self._context.Cleanup:Add(fallConnection)

	self._context.Cleanup:Connect(RunService.Heartbeat, function(dt: number)
		local speed = Escalation.Evaluate(cfg.RotationSpeed, self:ElapsedFraction())
		for index, ringModel in self._ringModels do
			local direction = if index % 2 == 0 then 1 else -1
			self._ringAngles[index] = (self._ringAngles[index] or 0) + direction * speed * dt
			local center = self._ringCenters[index]
			if center then
				ringModel:PivotTo(CFrame.new(center) * CFrame.Angles(0, math.rad(self._ringAngles[index]), 0))
			end
		end
	end)

	local windThread = task.spawn(function()
		while true do
			if self:ElapsedFraction() < cfg.WindGustAfterFraction then
				task.wait(1)
			else
				task.wait(cfg.WindGustInterval)
				self:ApplyWindGust()
			end
		end
	end)
	self._context.Cleanup:AddThread(windThread)

	local hudThread = task.spawn(function()
		while true do
			task.wait(0.5)
			self:BroadcastHud()
		end
	end)
	self._context.Cleanup:AddThread(hudThread)

	self:BroadcastHud()
end

function FreefallGauntlet.Stop(self: FreefallGauntletInstance)
	-- All connections/threads were registered on context.Cleanup; RoundManager
	-- cleans that Trove right after Stop() returns.
end

function FreefallGauntlet.GetResults(self: FreefallGauntletInstance): { PlayerResult }
	local results: { PlayerResult } = {}
	local placement = 1

	for _, entry in self._landedOrder do
		table.insert(results, { Player = entry.Player, Placement = placement, Score = entry.Score })
		placement += 1
	end

	local stillFalling: { Player } = {}
	for player in self._alive do
		table.insert(stillFalling, player)
	end
	table.sort(stillFalling, function(a, b)
		return self:CurrentHeight(a) < self:CurrentHeight(b)
	end)
	for _, player in stillFalling do
		table.insert(results, { Player = player, Placement = placement, Score = math.max(0, 500 - placement * 20) })
		placement += 1
	end

	for i = #self._eliminatedOrder, 1, -1 do
		local player = self._eliminatedOrder[i]
		table.insert(results, { Player = player, Placement = placement, Score = math.max(0, 200 - placement * 10) })
		placement += 1
	end

	return results
end

return FreefallGauntlet
