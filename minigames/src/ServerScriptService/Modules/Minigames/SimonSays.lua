--!strict
-- Simon Says: four colored pads flash a growing sequence, then everyone must step on
-- them in the same order. A wrong pad, or running out of time, eliminates you. The
-- sequence gets one step longer each round until one player (or none) remains.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local MinigameUtils = require(script.Parent.Parent:WaitForChild("MinigameUtils"))

local SimonSays = {}

local PAD_COLORS = {
	Color3.fromRGB(220, 60, 60),
	Color3.fromRGB(60, 140, 220),
	Color3.fromRGB(60, 200, 100),
	Color3.fromRGB(230, 200, 60),
}

local arenaFolder: Folder? = nil
local signLabel: TextLabel? = nil
local pads: { BasePart } = {}
local alive: { [Player]: boolean } = {}
local progress: { [Player]: number } = {}
local touchCooldown: { [Player]: number } = {}
local fallConnection: RBXScriptConnection? = nil
local sequence: { number } = {}
local inputPhase = false
local running = false
local sequenceDone = false
local winners: { Player } = {}

local function announce(text: string)
	if signLabel then
		signLabel.Text = text
	end
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

local function buildArena(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "SimonSaysArena"

	local center = Config.SimonSays.Center
	local padSize = Config.SimonSays.PadSize
	local half = (padSize + Config.SimonSays.PadGap) / 2

	local offsets = {
		Vector3.new(-half, 0, -half),
		Vector3.new(half, 0, -half),
		Vector3.new(-half, 0, half),
		Vector3.new(half, 0, half),
	}

	pads = {}
	for index, offset in offsets do
		local pad = Instance.new("Part")
		pad.Name = "Pad" .. index
		pad.Size = Vector3.new(padSize, 1, padSize)
		pad.Position = center + offset
		pad.Anchored = true
		pad.Material = Enum.Material.SmoothPlastic
		pad.Color = PAD_COLORS[index]
		pad.Parent = folder
		pads[index] = pad

		pad.Touched:Connect(function(hit: BasePart)
			if not inputPhase then
				return
			end
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if not player or not alive[player] then
				return
			end
			local currentStep = progress[player] or 1
			if currentStep > #sequence then
				return
			end
			local now = os.clock()
			if (touchCooldown[player] or 0) > now then
				return
			end
			touchCooldown[player] = now + Config.SimonSays.TouchCooldown

			if sequence[currentStep] == index then
				progress[player] = currentStep + 1
			else
				alive[player] = nil
				MinigameUtils.SendToSpectate(player, CFrame.new(center + Vector3.new(0, 40, 0)))
			end
		end)
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
	label.Text = "Simon Says!"
	label.Parent = billboard

	signLabel = label

	folder.Parent = Workspace
	return folder
end

local function flashPad(index: number)
	local pad = pads[index]
	if not pad then
		return
	end
	local original = PAD_COLORS[index]
	local up = TweenService:Create(pad, TweenInfo.new(Config.SimonSays.FlashTime / 2, Enum.EasingStyle.Quad), {
		Color = Color3.new(1, 1, 1),
	})
	up:Play()
	up.Completed:Wait()
	local down = TweenService:Create(pad, TweenInfo.new(Config.SimonSays.FlashTime / 2, Enum.EasingStyle.Quad), {
		Color = original,
	})
	down:Play()
	down.Completed:Wait()
end

local function playSequence()
	for _, index in sequence do
		if not running then
			return
		end
		flashPad(index)
		task.wait(Config.SimonSays.GapTime)
	end
end

local function allDone(): boolean
	for player in pairs(alive) do
		if (progress[player] or 1) <= #sequence then
			return false
		end
	end
	return true
end

local function runRounds()
	while running and countAlive() > 1 do
		if #sequence == 0 then
			for _ = 1, Config.SimonSays.StartLength do
				table.insert(sequence, math.random(1, #pads))
			end
		else
			table.insert(sequence, math.random(1, #pads))
		end
		for player in pairs(alive) do
			progress[player] = 1
		end

		announce("Watch closely...")
		task.wait(0.5)
		if not running then
			return
		end
		playSequence()
		if not running then
			return
		end

		announce("Your turn!")
		inputPhase = true
		local deadline = os.clock() + (#sequence * Config.SimonSays.StepTimeout)
		while running and os.clock() < deadline and not allDone() do
			task.wait(0.1)
		end
		inputPhase = false
		if not running then
			return
		end

		for player in pairs(alive) do
			if (progress[player] or 1) <= #sequence then
				alive[player] = nil
				MinigameUtils.SendToSpectate(player, CFrame.new(Config.SimonSays.Center + Vector3.new(0, 40, 0)))
			end
		end

		if countAlive() <= 1 then
			break
		end
		announce("Next round...")
		task.wait(Config.SimonSays.RoundPause)
	end

	sequenceDone = true
	winners = remainingAlive()
end

function SimonSays.Init(players: { Player })
	alive = {}
	progress = {}
	touchCooldown = {}
	sequence = {}
	winners = {}
	sequenceDone = false
	inputPhase = false
	for _, player in players do
		alive[player] = true
		progress[player] = 1
	end
	arenaFolder = buildArena()
	MinigameUtils.TeleportPlayersInCircle(players, Config.SimonSays.Center, Config.SimonSays.PadSize * 0.8, 4)
end

function SimonSays.Start()
	running = true
	fallConnection = MinigameUtils.WatchForFalls(function()
		return Config.SimonSays.Center.Y - 15
	end, alive, function(player)
		MinigameUtils.SendToSpectate(player, CFrame.new(Config.SimonSays.Center + Vector3.new(0, 40, 0)))
	end)
	task.spawn(runRounds)
end

function SimonSays.Cleanup()
	running = false
	inputPhase = false
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
	progress = {}
	touchCooldown = {}
	sequence = {}
	signLabel = nil
end

function SimonSays.GetWinners(final: boolean?): { Player }
	if sequenceDone then
		return winners
	end
	if countAlive() <= 1 or final then
		return remainingAlive()
	end
	return {}
end

return SimonSays
