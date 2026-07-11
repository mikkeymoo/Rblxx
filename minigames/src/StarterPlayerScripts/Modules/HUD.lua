--!strict
-- In-round HUD: round timer, current game name, coin count. Built entirely in code.
local HUD = {}
HUD.__index = HUD

export type HUD = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
		gameLabel: TextLabel,
		timeLabel: TextLabel,
		coinLabel: TextLabel,
	},
	HUD
))

function HUD.new(playerGui: PlayerGui): HUD
	local gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.fromOffset(280, 90)
	container.Position = UDim2.new(0.5, -140, 0, 10)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	container.BackgroundTransparency = 0.25
	container.BorderSizePixel = 0
	container.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	local gameLabel = Instance.new("TextLabel")
	gameLabel.Name = "GameLabel"
	gameLabel.Size = UDim2.new(1, 0, 0, 28)
	gameLabel.Position = UDim2.new(0, 0, 0, 4)
	gameLabel.BackgroundTransparency = 1
	gameLabel.Font = Enum.Font.GothamBold
	gameLabel.TextSize = 20
	gameLabel.TextColor3 = Color3.new(1, 1, 1)
	gameLabel.Text = ""
	gameLabel.Parent = container

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(1, 0, 0, 36)
	timeLabel.Position = UDim2.new(0, 0, 0, 32)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.TextSize = 30
	timeLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	timeLabel.Text = "0"
	timeLabel.Parent = container

	local coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinLabel"
	coinLabel.Size = UDim2.new(1, 0, 0, 22)
	coinLabel.Position = UDim2.new(0, 0, 0, 68)
	coinLabel.BackgroundTransparency = 1
	coinLabel.Font = Enum.Font.Gotham
	coinLabel.TextSize = 16
	coinLabel.TextColor3 = Color3.fromRGB(255, 240, 180)
	coinLabel.Text = "Coins: 0"
	coinLabel.Parent = container

	return setmetatable({
		gui = gui,
		gameLabel = gameLabel,
		timeLabel = timeLabel,
		coinLabel = coinLabel,
	}, HUD)
end

function HUD.SetVisible(self: HUD, visible: boolean)
	self.gui.Enabled = visible
end

function HUD.SetGameName(self: HUD, name: string)
	self.gameLabel.Text = name
end

function HUD.SetTime(self: HUD, seconds: number)
	self.timeLabel.Text = tostring(seconds)
end

function HUD.SetCoins(self: HUD, coins: number)
	self.coinLabel.Text = `Coins: {coins}`
end

return HUD
