--!strict
-- Shows WaitingForPlayers/Intermission/Loading text plus a countdown. Only
-- shown to players who are queued or already locked into the round (see
-- HardcoreMain), so idle spectators in the base pack aren't interrupted.
local IntermissionUI = {}
IntermissionUI.__index = IntermissionUI

export type IntermissionUI = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
		titleLabel: TextLabel,
		countdownLabel: TextLabel,
	},
	IntermissionUI
))

function IntermissionUI.new(playerGui: PlayerGui): IntermissionUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "HardcoreIntermissionUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(480, 130)
	container.Position = UDim2.new(0.5, -240, 0, 40)
	container.BackgroundColor3 = Color3.fromRGB(20, 8, 8)
	container.BackgroundTransparency = 0.15
	container.BorderSizePixel = 0
	container.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = container

	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(1, 0, 0, 4)
	stripe.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
	stripe.BorderSizePixel = 0
	stripe.Parent = container

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 50)
	titleLabel.Position = UDim2.new(0, 10, 0, 16)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 26
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextWrapped = true
	titleLabel.Text = ""
	titleLabel.Parent = container

	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Size = UDim2.new(1, -20, 0, 34)
	countdownLabel.Position = UDim2.new(0, 10, 0, 74)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Font = Enum.Font.Gotham
	countdownLabel.TextSize = 20
	countdownLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
	countdownLabel.Text = ""
	countdownLabel.Parent = container

	return setmetatable({
		gui = gui,
		titleLabel = titleLabel,
		countdownLabel = countdownLabel,
	}, IntermissionUI)
end

function IntermissionUI.Show(self: IntermissionUI, text: string)
	self.titleLabel.Text = text
	self.countdownLabel.Text = ""
	self.gui.Enabled = true
end

function IntermissionUI.Hide(self: IntermissionUI)
	self.gui.Enabled = false
end

function IntermissionUI.SetCountdown(self: IntermissionUI, seconds: number)
	self.countdownLabel.Text = `Starting in {seconds}...`
end

return IntermissionUI
