--!strict
-- Signal Jammer: hold the moving capture point to score while telegraphed
-- pulse waves sweep the arena; caught in an active pulse = eliminated. The
-- safe rhythm speeds up and the telegraph window shortens every round, with
-- simultaneous pulses added late. Ranked by score, alive beats eliminated.
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

type ActivePulse = {
	Position: Vector3,
	Radius: number,
	ExpiresAt: number,
}

local SignalJammer = {}
SignalJammer.__index = SignalJammer

SignalJammer.Metadata = {
	Name = "Signal Jammer",
	MinPlayers = 2,
	MaxPlayers = 20,
	SupportsTeams = false,
	RoundDurationCap = 90,
} :: Types.MinigameMetadata

export type SignalJammerInstance = typeof(setmetatable(
	{} :: {
		_context: MinigameContext,
		_cfg: Config.SignalJammerConfig,
		_alive: { [Player]: boolean },
		_score: { [Player]: number },
		_eliminatedOrder: { Player },
		_capturePoint: BasePart,
		_pulsesFolder: Folder,
		_activePulses: { [BasePart]: ActivePulse },
		_orbitAngle: number,
		_orbitRadius: number,
		_startClock: number,
		_spectatePos: CFrame,
		Completed: Signal.Signal,
	},
	SignalJammer
))

function SignalJammer.new(context: MinigameContext): SignalJammerInstance
	local cfg = Config.SignalJammer
	local arena = context.Arena

	local self = setmetatable({
		_context = context,
		_cfg = cfg,
		_alive = {},
		_score = {},
		_eliminatedOrder = {},
		_capturePoint = arena:WaitForChild("CapturePoint") :: BasePart,
		_pulsesFolder = arena:WaitForChild("Pulses") :: Folder,
		_activePulses = {},
		_orbitAngle = 0,
		_orbitRadius = cfg.ArenaRadius * 0.55,
		_startClock = os.clock(),
		_spectatePos = CFrame.new(),
		Completed = Signal.new(),
	}, SignalJammer) :: SignalJammerInstance

	for _, player in context.Participants do
		self._alive[player] = true
		self._score[player] = 0
	end

	local stand = arena:FindFirstChild("SpectatorStand") :: BasePart?
	if stand then
		self._spectatePos = stand.CFrame + Vector3.new(0, 4, 0)
	end

	context.Cleanup:Add(self.Completed)

	return self
end

function SignalJammer.ElapsedFraction(self: SignalJammerInstance): number
	local elapsed = os.clock() - self._startClock
	return Escalation.Clamp01(elapsed / SignalJammer.Metadata.RoundDurationCap)
end

function SignalJammer.BroadcastHud(self: SignalJammerInstance)
	local playersLeft = 0
	for _ in self._alive do
		playersLeft += 1
	end
	Remotes.GetEvent("GameUpdate"):FireAllClients({
		Game = SignalJammer.Metadata.Name,
		PlayersLeft = playersLeft,
		Scores = self._score,
	})
end

function SignalJammer.CheckForWinner(self: SignalJammerInstance)
	local aliveCount = 0
	for _ in self._alive do
		aliveCount += 1
	end
	if aliveCount <= 1 then
		self.Completed:Fire()
	end
end

function SignalJammer.OnPlayerEliminated(self: SignalJammerInstance, player: Player)
	if not self._alive[player] then
		return
	end
	self._alive[player] = nil
	table.insert(self._eliminatedOrder, player)

	MinigameUtils.SendToSpectate(player, self._spectatePos)
	Remotes.GetEvent("YouWereEliminated"):FireClient(player)
	self:BroadcastHud()
	self:CheckForWinner()
end

function SignalJammer.SpawnPulse(self: SignalJammerInstance, fraction: number)
	local cfg = self._cfg
	local angle = math.random() * math.pi * 2
	local dist = math.random() * cfg.ArenaRadius
	local pos = cfg.Center + Vector3.new(math.cos(angle) * dist, 2, math.sin(angle) * dist)

	local warnPart = Instance.new("Part")
	warnPart.Name = "PulseWarning"
	warnPart.Anchored = true
	warnPart.CanCollide = false
	warnPart.Shape = Enum.PartType.Cylinder
	warnPart.Material = Enum.Material.Neon
	warnPart.Color = Color3.fromRGB(255, 70, 70)
	warnPart.Transparency = 0.55
	warnPart.Size = Vector3.new(0.2, cfg.PulseRadius * 2, cfg.PulseRadius * 2)
	warnPart.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	warnPart.Parent = self._pulsesFolder
	self._context.Cleanup:Add(warnPart)

	local telegraphTime = Escalation.Evaluate(cfg.PulseTelegraphTime, fraction)
	task.wait(telegraphTime)

	if warnPart.Parent == nil then
		return -- round ended mid-telegraph
	end

	warnPart.Color = Color3.fromRGB(255, 255, 255)
	warnPart.Transparency = 0.1

	self._activePulses[warnPart] = {
		Position = pos,
		Radius = cfg.PulseRadius,
		ExpiresAt = os.clock() + cfg.PulseActiveTime,
	}
end

function SignalJammer.Start(self: SignalJammerInstance)
	self._startClock = os.clock()
	local cfg = self._cfg

	MinigameUtils.TeleportPlayersInCircle(self._context.Participants, cfg.Center, cfg.ArenaRadius * 0.8, 6)

	self._context.Cleanup:Connect(RunService.Heartbeat, function(dt: number)
		self._orbitAngle += (cfg.CapturePointSpeed / self._orbitRadius) * dt
		local pos = cfg.Center
			+ Vector3.new(math.cos(self._orbitAngle) * self._orbitRadius, 3, math.sin(self._orbitAngle) * self._orbitRadius)
		self._capturePoint.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))

		local holders: { Player } = {}
		for player in self._alive do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local flat = Vector3.new((root :: BasePart).Position.X, 0, (root :: BasePart).Position.Z)
					- Vector3.new(pos.X, 0, pos.Z)
				if flat.Magnitude <= cfg.CapturePointRadius then
					table.insert(holders, player)
				end
			end
		end
		if #holders == 1 then
			local holder = holders[1]
			self._score[holder] = (self._score[holder] or 0) + cfg.CaptureScorePerSecond * dt
		elseif #holders >= 2 then
			for _, player in holders do
				self._score[player] = math.max(0, (self._score[player] or 0) - cfg.CaptureScorePerSecond * 0.5 * dt)
			end
		end

		for part, pulse in self._activePulses do
			if os.clock() >= pulse.ExpiresAt then
				part:Destroy()
				self._activePulses[part] = nil
			else
				for player in self._alive do
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if root then
						local flat = Vector3.new((root :: BasePart).Position.X, 0, (root :: BasePart).Position.Z)
							- Vector3.new(pulse.Position.X, 0, pulse.Position.Z)
						if flat.Magnitude <= pulse.Radius then
							self:OnPlayerEliminated(player)
						end
					end
				end
			end
		end
	end)

	local pulseThread = task.spawn(function()
		while true do
			local fraction = self:ElapsedFraction()
			local interval = Escalation.Evaluate(cfg.PulseInterval, fraction)
			task.wait(interval)
			local pulseCount = if fraction >= cfg.MultiPulseAfterFraction then 2 else 1
			for _ = 1, pulseCount do
				task.spawn(function()
					self:SpawnPulse(fraction)
				end)
			end
		end
	end)
	self._context.Cleanup:AddThread(pulseThread)

	local hudThread = task.spawn(function()
		while true do
			task.wait(0.5)
			self:BroadcastHud()
		end
	end)
	self._context.Cleanup:AddThread(hudThread)

	self:BroadcastHud()
end

function SignalJammer.Stop(self: SignalJammerInstance)
	-- All connections/threads/parts were registered on context.Cleanup;
	-- RoundManager cleans that Trove right after Stop() returns.
end

function SignalJammer.GetResults(self: SignalJammerInstance): { PlayerResult }
	local entries = {}
	for _, player in self._context.Participants do
		table.insert(entries, {
			Player = player,
			Score = self._score[player] or 0,
			Alive = self._alive[player] == true,
		})
	end

	table.sort(entries, function(a, b)
		if a.Alive ~= b.Alive then
			return a.Alive
		end
		return a.Score > b.Score
	end)

	local results: { PlayerResult } = {}
	for i, entry in entries do
		table.insert(results, { Player = entry.Player, Placement = i, Score = math.floor(entry.Score) })
	end
	return results
end

return SignalJammer
