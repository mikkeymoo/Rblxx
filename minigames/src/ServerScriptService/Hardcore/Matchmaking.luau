--!strict
-- Matchmaking / teleport topology: single-place, in-place cycling behind an
-- opt-in queue. Chosen over a reserved-server TeleportService topology
-- because the existing project has no such convention (the base pack's
-- GameManager already cycles minigames in one place) and this repo has no
-- second place to teleport to. Kept behind this module's public surface
-- (JoinQueue/LeaveQueue/Dequeue/GetQueueCount) so a reserved-server model
-- can be swapped in later without touching RoundManager.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Hardcore:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage.Hardcore:WaitForChild("Remotes"))
local Signal = require(ReplicatedStorage.Hardcore:WaitForChild("Signal"))
local HardcoreUtils = require(script.Parent:WaitForChild("HardcoreUtils"))
local MinigameUtils = require(ServerScriptService.Modules:WaitForChild("MinigameUtils"))

local Matchmaking = {}

Matchmaking.QueueChanged = Signal.new()

local queue: { Player } = {}
local queued: { [Player]: boolean } = {}

local function fireQueueUpdate()
	local names = {}
	for _, player in queue do
		table.insert(names, player.Name)
	end
	Remotes.GetEvent("QueueUpdate"):FireAllClients(#queue, names, Config.MinPlayersToStart)
	Matchmaking.QueueChanged:Fire()
end

function Matchmaking.GetQueueCount(): number
	return #queue
end

function Matchmaking.BroadcastQueue()
	fireQueueUpdate()
end

function Matchmaking.JoinQueue(player: Player)
	if queued[player] or not HardcoreUtils.IsCharacterAlive(player) then
		return
	end
	queued[player] = true
	table.insert(queue, player)
	MinigameUtils.TeleportPlayersInCircle({ player }, Config.QueueKioskPosition, Config.QueueAreaRadius, 5)
	fireQueueUpdate()
end

function Matchmaking.LeaveQueue(player: Player)
	if not queued[player] then
		return
	end
	queued[player] = nil
	local index = table.find(queue, player)
	if index then
		table.remove(queue, index)
	end
	fireQueueUpdate()
end

-- Removes and returns up to `count` players from the front of the queue.
function Matchmaking.Dequeue(count: number): { Player }
	local taken = {}
	for _ = 1, count do
		local player = table.remove(queue, 1)
		if not player then
			break
		end
		queued[player] = nil
		table.insert(taken, player)
	end
	fireQueueUpdate()
	return taken
end

function Matchmaking.ReturnFromRound(players: { Player })
	for _, player in players do
		if player.Parent then
			local character = player.Character
			if character then
				character:PivotTo(CFrame.new(Config.QueueKioskPosition + Vector3.new(0, 5, 12)))
			end
		end
	end
end

function Matchmaking.Init()
	local joinRemote = Remotes.GetEvent("RequestJoinQueue")
	local leaveRemote = Remotes.GetEvent("RequestLeaveQueue")
	local rateLimited = HardcoreUtils.NewRateLimiter(4, 3)

	joinRemote.OnServerEvent:Connect(function(player: Player)
		if rateLimited(player) then
			Matchmaking.JoinQueue(player)
		end
	end)

	leaveRemote.OnServerEvent:Connect(function(player: Player)
		if rateLimited(player) then
			Matchmaking.LeaveQueue(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		Matchmaking.LeaveQueue(player)
	end)
end

return Matchmaking
