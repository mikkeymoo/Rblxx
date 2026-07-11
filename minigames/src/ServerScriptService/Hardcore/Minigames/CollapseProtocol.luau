--!strict
-- Collapse Protocol: a hex-tile floor over a kill void. Tiles crumble on a
-- shrinking timer when stepped on, periodic quakes pre-fault clusters, and
-- regrowth is disabled in the final third of the round. Last one standing
-- wins; a forced stop (timer cap) ties all remaining survivors for first.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Hardcore:WaitForChild("Config"))
local Escalation = require(ReplicatedStorage.Hardcore:WaitForChild("Escalation"))
local HexGrid = require(ReplicatedStorage.Hardcore:WaitForChild("HexGrid"))
local Signal = require(ReplicatedStorage.Hardcore:WaitForChild("Signal"))
local Remotes = require(ReplicatedStorage.Hardcore:WaitForChild("Remotes"))
local Types = require(ReplicatedStorage.Hardcore:WaitForChild("Types"))
local MinigameUtils = require(ServerScriptService.Modules:WaitForChild("MinigameUtils"))

type PlayerResult = Types.PlayerResult
type MinigameContext = Types.MinigameContext

local INTACT_COLOR = Color3.fromRGB(110, 112, 122)
local WARNING_COLOR = Color3.fromRGB(230, 90, 40)

local CollapseProtocol = {}
CollapseProtocol.__index = CollapseProtocol

CollapseProtocol.Metadata = {
	Name = "Collapse Protocol",
	MinPlayers = 2,
	MaxPlayers = 24,
	SupportsTeams = false,
	RoundDurationCap = 90,
} :: Types.MinigameMetadata

type TileState = "Intact" | "Crumbling" | "Gone"

export type CollapseProtocolInstance = typeof(setmetatable(
	{} :: {
		_context: MinigameContext,
		_cfg: Config.CollapseProtocolConfig,
		_alive: { [Player]: boolean },
		_eliminatedSet: { [Player]: boolean },
		_eliminatedOrder: { Player },
		_tileByKey: { [string]: BasePart },
		_tileState: { [BasePart]: TileState },
		_startClock: number,
		_spectatePos: CFrame,
		Completed: Signal.Signal,
	},
	CollapseProtocol
))

local function parseKey(name: string): (number, number)
	local qStr, rStr = string.match(name, "^(%-?%d+),(%-?%d+)$")
	return tonumber(qStr) :: number, tonumber(rStr) :: number
end

function CollapseProtocol.new(context: MinigameContext): CollapseProtocolInstance
	local cfg = Config.CollapseProtocol

	local self = setmetatable({
		_context = context,
		_cfg = cfg,
		_alive = {},
		_eliminatedSet = {},
		_eliminatedOrder = {},
		_tileByKey = {},
		_tileState = {},
		_startClock = os.clock(),
		_spectatePos = CFrame.new(),
		Completed = Signal.new(),
	}, CollapseProtocol) :: CollapseProtocolInstance

	for _, player in context.Participants do
		self._alive[player] = true
	end

	local tiles = context.Arena:WaitForChild("Tiles")
	for _, tile in tiles:GetChildren() do
		local part = tile :: BasePart
		self._tileByKey[part.Name] = part
		self._tileState[part] = "Intact"
	end

	local stand = context.Arena:FindFirstChild("SpectatorStand") :: BasePart?
	if stand then
		self._spectatePos = stand.CFrame + Vector3.new(0, 4, 0)
	end

	context.Cleanup:Add(self.Completed)

	return self
end

function CollapseProtocol.ElapsedFraction(self: CollapseProtocolInstance): number
	local elapsed = os.clock() - self._startClock
	return Escalation.Clamp01(elapsed / CollapseProtocol.Metadata.RoundDurationCap)
end

function CollapseProtocol.ForceCrumble(self: CollapseProtocolInstance, part: BasePart)
	if self._tileState[part] ~= "Intact" and self._tileState[part] ~= "Crumbling" then
		return
	end
	self._tileState[part] = "Gone"
	part.CanCollide = false
	part.Transparency = 0.85

	local fraction = self:ElapsedFraction()
	if fraction < self._cfg.RegrowDisabledAfterFraction then
		local regrowThread = task.delay(self._cfg.RegrowDelaySeconds, function()
			if self._tileState[part] == "Gone" then
				self._tileState[part] = "Intact"
				part.CanCollide = true
				part.Transparency = 0
				part.Color = INTACT_COLOR
			end
		end)
		self._context.Cleanup:AddThread(regrowThread)
	end
end

function CollapseProtocol.StartCrumble(self: CollapseProtocolInstance, part: BasePart)
	if self._tileState[part] ~= "Intact" then
		return
	end
	self._tileState[part] = "Crumbling"
	part.Color = WARNING_COLOR

	local crumbleDelaySeconds = Escalation.Evaluate(self._cfg.CrumbleDelay, self:ElapsedFraction())
	local thread = task.delay(crumbleDelaySeconds, function()
		if self._tileState[part] == "Crumbling" then
			self:ForceCrumble(part)
		end
	end)
	self._context.Cleanup:AddThread(thread)
end

function CollapseProtocol.SelectCluster(
	self: CollapseProtocolInstance,
	startQ: number,
	startR: number,
	size: number
): { BasePart }
	local visited = { [HexGrid.Key(startQ, startR)] = true }
	local queue = { { startQ, startR } }
	local result = {}
	local head = 1
	while head <= #queue and #result < size do
		local cur = queue[head]
		head += 1
		local part = self._tileByKey[HexGrid.Key(cur[1], cur[2])]
		if part and self._tileState[part] == "Intact" then
			table.insert(result, part)
		end
		for _, neighbor in HexGrid.Neighbors(cur[1], cur[2]) do
			local key = HexGrid.Key(neighbor.Q, neighbor.R)
			if not visited[key] then
				visited[key] = true
				table.insert(queue, { neighbor.Q, neighbor.R })
			end
		end
	end
	return result
end

function CollapseProtocol.TriggerQuake(self: CollapseProtocolInstance)
	local intact = {}
	for _, part in self._tileByKey do
		if self._tileState[part] == "Intact" then
			table.insert(intact, part)
		end
	end
	if #intact == 0 then
		return
	end

	local epicenter = intact[math.random(1, #intact)]
	local q, r = parseKey(epicenter.Name)
	local cluster = self:SelectCluster(q, r, self._cfg.QuakeClusterSize)
	if #cluster == 0 then
		return
	end

	for _, part in cluster do
		part.Color = WARNING_COLOR
	end
	task.wait(self._cfg.QuakeWarningTime)
	for _, part in cluster do
		self:ForceCrumble(part)
	end
end

function CollapseProtocol.BroadcastHud(self: CollapseProtocolInstance)
	local playersLeft = 0
	for _ in self._alive do
		playersLeft += 1
	end
	Remotes.GetEvent("GameUpdate"):FireAllClients({
		Game = CollapseProtocol.Metadata.Name,
		PlayersLeft = playersLeft,
	})
end

function CollapseProtocol.CheckForWinner(self: CollapseProtocolInstance)
	local aliveCount = 0
	for _ in self._alive do
		aliveCount += 1
	end
	if aliveCount <= 1 then
		self.Completed:Fire()
	end
end

-- Guards on _eliminatedSet rather than _alive: MinigameUtils.WatchForFalls
-- nils the alive table itself before invoking this callback, so by the time
-- a fall-triggered elimination gets here _alive[player] is already gone.
function CollapseProtocol.OnPlayerEliminated(self: CollapseProtocolInstance, player: Player)
	if self._eliminatedSet[player] then
		return
	end
	self._eliminatedSet[player] = true
	self._alive[player] = nil
	table.insert(self._eliminatedOrder, player)

	MinigameUtils.SendToSpectate(player, self._spectatePos)
	Remotes.GetEvent("YouWereEliminated"):FireClient(player)
	self:BroadcastHud()
	self:CheckForWinner()
end

function CollapseProtocol.Start(self: CollapseProtocolInstance)
	self._startClock = os.clock()

	local spawnRadius = (self._cfg.RingCount - 1) * (self._cfg.HexSize + self._cfg.HexGap) * 0.5
	MinigameUtils.TeleportPlayersInCircle(self._context.Participants, self._cfg.Center, spawnRadius, 6)

	for _, part in self._tileByKey do
		self._context.Cleanup:Connect(part.Touched, function(hit: BasePart)
			local character = hit.Parent
			if not character then
				return
			end
			local player = Players:GetPlayerFromCharacter(character)
			if not player or not self._alive[player] then
				return
			end
			self:StartCrumble(part)
		end)
	end

	local fallConnection = MinigameUtils.WatchForFalls(function()
		return self._cfg.KillY
	end, self._alive, function(player: Player)
		self:OnPlayerEliminated(player)
	end)
	self._context.Cleanup:Add(fallConnection)

	local quakeThread = task.spawn(function()
		while true do
			local interval = Escalation.Evaluate(self._cfg.QuakeInterval, self:ElapsedFraction())
			task.wait(interval)
			self:TriggerQuake()
		end
	end)
	self._context.Cleanup:AddThread(quakeThread)

	self:BroadcastHud()
end

function CollapseProtocol.Stop(self: CollapseProtocolInstance)
	-- Nothing to do here directly: every connection/thread this instance
	-- created was registered on context.Cleanup, and RoundManager cleans
	-- that Trove immediately after Stop() returns.
end

function CollapseProtocol.GetResults(self: CollapseProtocolInstance): { PlayerResult }
	local results: { PlayerResult } = {}

	local survivors: { Player } = {}
	for player in self._alive do
		table.insert(survivors, player)
	end
	for _, player in survivors do
		table.insert(results, { Player = player, Placement = 1, Score = 1000 })
	end

	local placement = #survivors + 1
	for i = #self._eliminatedOrder, 1, -1 do
		local player = self._eliminatedOrder[i]
		table.insert(results, { Player = player, Placement = placement, Score = math.max(0, 1000 - placement * 50) })
		placement += 1
	end

	return results
end

return CollapseProtocol
