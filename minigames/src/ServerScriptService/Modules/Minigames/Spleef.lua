--!strict
-- Spleef: a floating tile arena. Tiles vanish shortly after a player touches them.
-- Last player standing (or whoever's left when the round timer forces an end) wins.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local MinigameUtils = require(script.Parent.Parent:WaitForChild("MinigameUtils"))

local Spleef = {}

local arenaFolder: Folder? = nil
local alive: { [Player]: boolean } = {}
local fallConnection: RBXScriptConnection? = nil

local function vanishTile(tile: BasePart)
	if tile:GetAttribute("Vanishing") then
		return
	end
	tile:SetAttribute("Vanishing", true)
	task.delay(Config.Spleef.FallDelay, function()
		if not tile.Parent then
			return
		end
		tile.CanCollide = false
		local tween = TweenService:Create(tile, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Transparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		if tile.Parent then
			tile:Destroy()
		end
	end)
end

local function buildArena(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "SpleefArena"

	local center = Config.Spleef.Center
	local radius = Config.Spleef.ArenaRadius
	local tileSize = Config.Spleef.TileSize
	local step = tileSize + Config.Spleef.TileGap
	local count = math.floor((radius * 2) / step)

	for xi = 0, count do
		for zi = 0, count do
			local x = center.X - radius + xi * step
			local z = center.Z - radius + zi * step
			if (Vector3.new(x, 0, z) - Vector3.new(center.X, 0, center.Z)).Magnitude <= radius then
				local tile = Instance.new("Part")
				tile.Name = "Tile"
				tile.Size = Vector3.new(tileSize, Config.Spleef.TileHeight, tileSize)
				tile.Position = Vector3.new(x, center.Y, z)
				tile.Anchored = true
				tile.Material = Enum.Material.Ice
				tile.Color = Color3.fromRGB(150, 210, 255)
				tile.Parent = folder

				tile.Touched:Connect(function(hit: BasePart)
					local character = hit.Parent
					local player = character and Players:GetPlayerFromCharacter(character)
					if player then
						vanishTile(tile)
					end
				end)
			end
		end
	end

	folder.Parent = Workspace
	return folder
end

function Spleef.Init(players: { Player })
	alive = {}
	for _, player in players do
		alive[player] = true
	end
	arenaFolder = buildArena()
	MinigameUtils.TeleportPlayersInCircle(players, Config.Spleef.Center, Config.Spleef.ArenaRadius * 0.4, Config.Spleef.TileHeight + 4)
end

function Spleef.Start()
	fallConnection = MinigameUtils.WatchForFalls(function()
		return Config.Spleef.Center.Y - 15
	end, alive, function(player)
		MinigameUtils.SendToSpectate(player, CFrame.new(Config.Spleef.Center + Vector3.new(0, 50, 0)))
	end)
end

function Spleef.Cleanup()
	if fallConnection then
		fallConnection:Disconnect()
		fallConnection = nil
	end
	if arenaFolder then
		arenaFolder:Destroy()
		arenaFolder = nil
	end
	alive = {}
end

function Spleef.GetWinners(final: boolean?): { Player }
	local remaining: { Player } = {}
	for player in pairs(alive) do
		table.insert(remaining, player)
	end
	if #remaining <= 1 or final then
		return remaining
	end
	return {}
end

return Spleef
