--!strict
-- Persistent bottom-left widget: shows the Hardcore pack queue status and a
-- join/leave toggle. This is the pack's only always-visible UI; everything
-- else only appears once a player is queued or in a round. Emits signals
-- instead of touching remotes directly so HardcoreMain owns all networking.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Hardcore:WaitForChild("Signal"))

local QueueWidget = {}
QueueWidget.__index = QueueWidget

export type QueueWidget = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
		statusLabel: TextLabel,
		toggleButton: TextButton,
		isQueued: boolean,
		JoinClicked: Signal.Signal,
		LeaveClicked: Signal.Signal,
		LeaderboardClicked: Signal.Signal,
	},
	QueueWidget
))

function QueueWidget.new(playerGui: PlayerGui): QueueWidget
	local gui = Instance.new("ScreenGui")
	gui.Name = "HardcoreQueueWidget"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(240, 110)
	container.Position = UDim2.new(0, 12, 1, -122)
	container.BackgroundColor3 = Color3.fromRGB(25, 10, 10)
	container.BackgroundTransparency = 0.15
	container.BorderSizePixel = 0
	container.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -16, 0, 22)
	titleLabel.Position = UDim2.new(0, 8, 0, 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "HARDCORE PACK"
	titleLabel.Parent = container

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -16, 0, 36)
	statusLabel.Position = UDim2.new(0, 8, 0, 28)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 14
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
	statusLabel.Text = "0 waiting"
	statusLabel.Parent = container

	local toggleButton = Instance.new("TextButton")
	toggleButton.Size = UDim2.new(1, -16, 0, 30)
	toggleButton.Position = UDim2.new(0, 8, 1, -36)
	toggleButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextSize = 15
	toggleButton.TextColor3 = Color3.new(1, 1, 1)
	toggleButton.Text = "Join Queue"
	toggleButton.AutoButtonColor = true
	toggleButton.Parent = container

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = toggleButton

	local leaderboardButton = Instance.new("TextButton")
	leaderboardButton.Size = UDim2.fromOffset(28, 28)
	leaderboardButton.Position = UDim2.new(1, -34, 0, 6)
	leaderboardButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	leaderboardButton.Font = Enum.Font.GothamBold
	leaderboardButton.TextSize = 16
	leaderboardButton.TextColor3 = Color3.new(1, 1, 1)
	leaderboardButton.Text = "\226\152\133"
	leaderboardButton.Parent = container

	local leaderboardCorner = Instance.new("UICorner")
	leaderboardCorner.CornerRadius = UDim.new(0, 8)
	leaderboardCorner.Parent = leaderboardButton

	local self = setmetatable({
		gui = gui,
		statusLabel = statusLabel,
		toggleButton = toggleButton,
		isQueued = false,
		JoinClicked = Signal.new(),
		LeaveClicked = Signal.new(),
		LeaderboardClicked = Signal.new(),
	}, QueueWidget) :: QueueWidget

	toggleButton.MouseButton1Click:Connect(function()
		if self.isQueued then
			self.LeaveClicked:Fire()
		else
			self.JoinClicked:Fire()
		end
	end)

	leaderboardButton.MouseButton1Click:Connect(function()
		self.LeaderboardClicked:Fire()
	end)

	return self
end

function QueueWidget.SetQueue(self: QueueWidget, count: number, minToStart: number, isQueued: boolean)
	self.isQueued = isQueued
	self.toggleButton.Text = if isQueued then "Leave Queue" else "Join Queue"
	self.toggleButton.BackgroundColor3 = if isQueued
		then Color3.fromRGB(70, 70, 80)
		else Color3.fromRGB(200, 40, 40)
	self.statusLabel.Text = `{count} waiting (need {minToStart})`
end

return QueueWidget
