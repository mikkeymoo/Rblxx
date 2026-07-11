--!strict
-- Intermission screen: announces the next minigame and counts down to its start.
local IntermissionScreen = {}
IntermissionScreen.__index = IntermissionScreen

export type IntermissionScreen = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
		titleLabel: TextLabel,
		countdownLabel: TextLabel,
	},
	IntermissionScreen
))

function IntermissionScreen.new(playerGui: PlayerGui): IntermissionScreen
	local gui = Instance.new("ScreenGui")
	gui.Name = "IntermissionScreen"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(500, 140)
	container.Position = UDim2.new(0.5, -250, 0.5, -70)
	container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	container.BackgroundTransparency = 0.2
	container.BorderSizePixel = 0
	container.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = container

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 60)
	titleLabel.Position = UDim2.new(0, 10, 0, 15)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 32
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextWrapped = true
	titleLabel.Text = ""
	titleLabel.Parent = container

	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Size = UDim2.new(1, -20, 0, 40)
	countdownLabel.Position = UDim2.new(0, 10, 0, 80)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Font = Enum.Font.Gotham
	countdownLabel.TextSize = 22
	countdownLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	countdownLabel.Text = ""
	countdownLabel.Parent = container

	return setmetatable({
		gui = gui,
		titleLabel = titleLabel,
		countdownLabel = countdownLabel,
	}, IntermissionScreen)
end

function IntermissionScreen.Show(self: IntermissionScreen, text: string)
	self.titleLabel.Text = text
	self.countdownLabel.Text = ""
	self.gui.Enabled = true
end

function IntermissionScreen.Hide(self: IntermissionScreen)
	self.gui.Enabled = false
end

function IntermissionScreen.SetCountdown(self: IntermissionScreen, seconds: number)
	self.countdownLabel.Text = `Starting in {seconds}...`
end

return IntermissionScreen
