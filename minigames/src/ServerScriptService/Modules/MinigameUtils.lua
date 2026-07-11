--!strict
-- Shared helpers used by multiple minigame modules: fall-based elimination and
-- spreading players around a circle. Kept here instead of duplicated per-game.
local RunService = game:GetService("RunService")

local MinigameUtils = {}

export type EliminationCallback = (player: Player) -> ()

-- Connects a Heartbeat watcher that eliminates any player in `alive` whose
-- HumanoidRootPart drops below the threshold returned by `getThresholdY`.
-- Mutates `alive` (removes eliminated players) and invokes `onEliminate`.
function MinigameUtils.WatchForFalls(
	getThresholdY: () -> number,
	alive: { [Player]: boolean },
	onEliminate: EliminationCallback
): RBXScriptConnection
	return RunService.Heartbeat:Connect(function()
		local thresholdY = getThresholdY()
		for player in pairs(alive) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and (root :: BasePart).Position.Y < thresholdY then
				alive[player] = nil
				onEliminate(player)
			elseif not character or not root then
				alive[player] = nil
				onEliminate(player)
			end
		end
	end)
end

function MinigameUtils.TeleportPlayersInCircle(players: { Player }, center: Vector3, radius: number, yOffset: number?)
	local y = yOffset or 5
	local count = math.max(#players, 1)
	for i, player in players do
		local angle = (i / count) * math.pi * 2
		local x = center.X + math.cos(angle) * radius
		local z = center.Z + math.sin(angle) * radius
		local character = player.Character or player.CharacterAdded:Wait()
		character:PivotTo(CFrame.new(x, center.Y + y, z))
	end
end

function MinigameUtils.SendToSpectate(player: Player, spectatePoint: CFrame)
	local character = player.Character
	if not character then
		return
	end
	character:PivotTo(spectatePoint)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end
end

return MinigameUtils
