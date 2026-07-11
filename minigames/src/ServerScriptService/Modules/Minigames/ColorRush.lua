--!strict
-- Color Rush: a floor of colored pads. A safe color is announced, then every other
-- pad falls after a shrinking countdown. Repeats until one color (and its players)
-- remains, or the round timer forces an end.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local MinigameUtils = require(script.Parent.Parent:WaitForChild("MinigameUtils"))

local ColorRush = {}

local PALETTE = {
	Color3.fromRGB(220, 60, 60),
	Color3.fromRGB(60, 140, 220),
	Color3.fromRGB(60, 200, 100),
	Color3.fromRGB(230, 200, 60),
}

local COLOR_NAMES: { [string]: string } = {
	["220,60,60"] = "Red",
	["60,140,220"] = "Blue",
	["60,200,100"] = "Green",
	["230,200,60"] = "Yellow",
}

local function colorKey(color: Color3): string
	return `{math.floor(color.R * 255)},{math.floor(color.G * 255)},{math.floor(color.B * 255)}`
end

local arenaFolder: Folder? = nil
local signLabel: TextLabel? = nil
local alive: { [Player]: boolean } = {}
local fallConnection: RBXScriptConnection? = nil
local pads: { BasePart } = {}
local running = false
local sequenceDone = false
local winners: { Player } = {}

local function announce(text: string)
	if signLabel then
		signLabel.Text = text
	end
end

local function buildArena(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "ColorRushArena"

	local center = Config.ColorRush.Center
	local gridSize = Config.ColorRush.GridSize
	local padSize = Config.ColorRush.PadSize
	local half = (gridSize * padSize) / 2

	pads = {}
	for xi = 0, gridSize - 1 do
		for zi = 0, gridSize - 1 do
			local color = PALETTE[math.random(1, #PALETTE)]
			local pad = Instance.new("Part")
			pad.Name = "Pad"
			pad.Size = Vector3.new(padSize - 0.4, 1, padSize - 0.4)
			pad.Position = Vector3.new(
				center.X - half + xi * padSize + padSize / 2,
				center.Y,
				center.Z - half + zi * padSize + padSize / 2
			)
			pad.Anchored = true
			pad.Material = Enum.Material.SmoothPlastic
			pad.Color = color
			pad.Parent = folder
			table.insert(pads, pad)
		end
	end

	local sign = Instance.new("Part")
	sign.Name = "AnnouncementSign"
	sign.Anchored = true
	sign.CanCollide = false
	sign.Transparency = 1
	sign.Size = Vector3.new(1, 1, 1)
	sign.Position = center + Vector3.new(0, 20, 0)
	sign.Parent = folder

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(400, 100)
	billboard.AlwaysOnTop = true
	billboard.Parent = sign

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = "Color Rush!"
	label.Parent = billboard

	signLabel = label

	folder.Parent = Workspace
	return folder
end

local function fallPad(pad: BasePart)
	pad.CanCollide = false
	local tween = TweenService:Create(pad, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Transparency = 1 })
	tween:Play()
	task.delay(0.5, function()
		if pad.Parent then
			pad:Destroy()
		end
	end)
end

local function countAlive(): number
	local n = 0
	for _ in pairs(alive) do
		n += 1
	end
	return n
end

local function remainingAlive(): { Player }
	local remaining: { Player } = {}
	for player in pairs(alive) do
		table.insert(remaining, player)
	end
	return remaining
end

local function runSequence()
	local countdownTime = Config.ColorRush.InitialCountdown
	while running and countAlive() > 1 and #pads > 0 do
		local presentColors: { Color3 } = {}
		local seen: { [string]: boolean } = {}
		for _, pad in pads do
			if pad.Parent then
				local key = colorKey(pad.Color)
				if not seen[key] then
					seen[key] = true
					table.insert(presentColors, pad.Color)
				end
			end
		end
		if #presentColors <= 1 then
			break
		end

		local safeColor = presentColors[math.random(1, #presentColors)]
		announce(`Safe color: {COLOR_NAMES[colorKey(safeColor)] or "?"}`)

		task.wait(countdownTime)
		if not running then
			return
		end

		local remainingPads: { BasePart } = {}
		for _, pad in pads do
			if pad.Parent then
				if colorKey(pad.Color) ~= colorKey(safeColor) then
					fallPad(pad)
				else
					table.insert(remainingPads, pad)
				end
			end
		end
		pads = remainingPads

		announce("Go!")
		task.wait(Config.ColorRush.FallDelay)

		countdownTime = math.max(Config.ColorRush.MinCountdown, countdownTime - Config.ColorRush.CountdownDecrement)
	end

	sequenceDone = true
	winners = remainingAlive()
end

function ColorRush.Init(players: { Player })
	alive = {}
	for _, player in players do
		alive[player] = true
	end
	winners = {}
	sequenceDone = false
	arenaFolder = buildArena()
	MinigameUtils.TeleportPlayersInCircle(
		players,
		Config.ColorRush.Center,
		Config.ColorRush.GridSize * Config.ColorRush.PadSize * 0.25,
		4
	)
end

function ColorRush.Start()
	running = true
	fallConnection = MinigameUtils.WatchForFalls(function()
		return Config.ColorRush.Center.Y - 15
	end, alive, function(player)
		MinigameUtils.SendToSpectate(player, CFrame.new(Config.ColorRush.Center + Vector3.new(0, 50, 0)))
	end)
	task.spawn(runSequence)
end

function ColorRush.Cleanup()
	running = false
	if fallConnection then
		fallConnection:Disconnect()
		fallConnection = nil
	end
	if arenaFolder then
		arenaFolder:Destroy()
		arenaFolder = nil
	end
	pads = {}
	alive = {}
	signLabel = nil
end

function ColorRush.GetWinners(final: boolean?): { Player }
	if sequenceDone then
		return winners
	end
	if countAlive() <= 1 or final then
		return remainingAlive()
	end
	return {}
end

return ColorRush
