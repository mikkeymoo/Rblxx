--!strict
-- In-round HUD: game name, round timer, players left, and your score if the
-- current game tracks one (Signal Jammer). Every value comes from server
-- broadcasts (GameUpdate/Tick) — this module only renders.
local Players = game:GetService("Players")

local GameHUD = {}
GameHUD.__index = GameHUD

export type GameHUD = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
		gameLabel: TextLabel,
		timeLabel: TextLabel,
		playersLeftLabel: TextLabel,
		scoreLabel: TextLabel,
	},
	GameHUD
))

function GameHUD.new(playerGui: PlayerGui): GameHUD
	local gui = Instance.new("ScreenGui")
	gui.Name = "HardcoreGameHUD"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(300, 116)
	container.Position = UDim2.new(0.5, -150, 0, 10)
	container.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	container.BackgroundTransparency = 0.25
	container.BorderSizePixel = 0
	container.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	local gameLabel = Instance.new("TextLabel")
	gameLabel.Size = UDim2.new(1, 0, 0, 26)
	gameLabel.Position = UDim2.new(0, 0, 0, 4)
	gameLabel.BackgroundTransparency = 1
	gameLabel.Font = Enum.Font.GothamBold
	gameLabel.TextSize = 18
	gameLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	gameLabel.Text = ""
	gameLabel.Parent = container

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(1, 0, 0, 36)
	timeLabel.Position = UDim2.new(0, 0, 0, 30)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.TextSize = 30
	timeLabel.TextColor3 = Color3.new(1, 1, 1)
	timeLabel.Text = "0"
	timeLabel.Parent = container

	local playersLeftLabel = Instance.new("TextLabel")
	playersLeftLabel.Size = UDim2.new(1, 0, 0, 20)
	playersLeftLabel.Position = UDim2.new(0, 0, 0, 68)
	playersLeftLabel.BackgroundTransparency = 1
	playersLeftLabel.Font = Enum.Font.Gotham
	playersLeftLabel.TextSize = 15
	playersLeftLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
	playersLeftLabel.Text = "Players left: 0"
	playersLeftLabel.Parent = container

	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Size = UDim2.new(1, 0, 0, 20)
	scoreLabel.Position = UDim2.new(0, 0, 0, 90)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Font = Enum.Font.Gotham
	scoreLabel.TextSize = 15
	scoreLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	scoreLabel.Text = ""
	scoreLabel.Parent = container

	return setmetatable({
		gui = gui,
		gameLabel = gameLabel,
		timeLabel = timeLabel,
		playersLeftLabel = playersLeftLabel,
		scoreLabel = scoreLabel,
	}, GameHUD)
end

function GameHUD.SetVisible(self: GameHUD, visible: boolean)
	self.gui.Enabled = visible
end

function GameHUD.SetGameName(self: GameHUD, name: string)
	self.gameLabel.Text = name
end

function GameHUD.SetTime(self: GameHUD, seconds: number)
	self.timeLabel.Text = tostring(seconds)
end

function GameHUD.ApplyUpdate(self: GameHUD, data: { [string]: any })
	local playersLeft = data.PlayersLeft
	if type(playersLeft) == "number" then
		self.playersLeftLabel.Text = `Players left: {playersLeft}`
	end

	local scores = data.Scores
	if type(scores) == "table" then
		local localPlayer = Players.LocalPlayer
		local myScore = scores[localPlayer]
		if type(myScore) == "number" then
			self.scoreLabel.Text = `Your score: {math.floor(myScore)}`
			return
		end
	end

	local landed = data.Landed
	if type(landed) == "number" then
		self.scoreLabel.Text = `Landed: {landed}`
		return
	end

	self.scoreLabel.Text = ""
end

return GameHUD
