--!strict
-- Small server-only helpers that don't belong to any single minigame:
-- remote rate-limiting (anti-spam) and alive/character sanity checks.
-- Teleport-in-circle and spectator placement already exist and are reused
-- as-is from the base pack's ServerScriptService/Modules/MinigameUtils.

local HardcoreUtils = {}

-- Returns a per-player token-bucket check: at most `maxCalls` within any
-- rolling `perSeconds` window. Used to stop RequestJoinQueue/RequestLeaveQueue
-- spam from a misbehaving or malicious client.
function HardcoreUtils.NewRateLimiter(maxCalls: number, perSeconds: number): (player: Player) -> boolean
	local windows: { [number]: { count: number, windowStart: number } } = {}

	return function(player: Player): boolean
		local now = os.clock()
		local entry = windows[player.UserId]
		if not entry or now - entry.windowStart >= perSeconds then
			windows[player.UserId] = { count = 1, windowStart = now }
			return true
		end
		if entry.count >= maxCalls then
			return false
		end
		entry.count += 1
		return true
	end
end

function HardcoreUtils.IsCharacterAlive(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	return humanoid ~= nil and root ~= nil and humanoid.Health > 0
end

-- Every map builder needs somewhere safe to park eliminated players. One
-- shared builder keeps the look/behavior consistent across all three games.
function HardcoreUtils.BuildSpectatorStand(parent: Instance, position: Vector3): Part
	local stand = Instance.new("Part")
	stand.Name = "SpectatorStand"
	stand.Anchored = true
	stand.CanCollide = true
	stand.Material = Enum.Material.Metal
	stand.Color = Color3.fromRGB(40, 40, 45)
	stand.Size = Vector3.new(16, 1, 16)
	stand.CFrame = CFrame.new(position)
	stand.Parent = parent
	return stand
end

return HardcoreUtils
