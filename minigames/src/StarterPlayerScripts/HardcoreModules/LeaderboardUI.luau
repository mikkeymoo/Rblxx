--!strict
-- Toggleable leaderboard panel: global top-N by points, plus your own
-- wins/points/best placement/games played. Data is fetched by HardcoreMain
-- via the GetLeaderboardSnapshot RemoteFunction; this module only renders.
local LeaderboardUI = {}
LeaderboardUI.__index = LeaderboardUI

export type TopNEntry = { Name: string, Points: number }
export type SelfStats = { Wins: number, Points: number, BestPlacement: number, GamesPlayed: number }

export type LeaderboardUI = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
		topList: TextLabel,
		selfLabel: TextLabel,
	},
	LeaderboardUI
))

function LeaderboardUI.new(playerGui: PlayerGui): LeaderboardUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "HardcoreLeaderboardUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(320, 400)
	container.Position = UDim2.new(1, -336, 0.5, -200)
	container.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = container

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -50, 0, 34)
	titleLabel.Position = UDim2.new(0, 12, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 22
	titleLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "Hardcore Leaderboard"
	titleLabel.Parent = container

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.fromOffset(28, 28)
	closeButton.Position = UDim2.new(1, -38, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 16
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Text = "X"
	closeButton.Parent = container

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	local topList = Instance.new("TextLabel")
	topList.Size = UDim2.new(1, -24, 1, -160)
	topList.Position = UDim2.new(0, 12, 0, 50)
	topList.BackgroundTransparency = 1
	topList.Font = Enum.Font.Code
	topList.TextSize = 16
	topList.TextColor3 = Color3.fromRGB(230, 230, 235)
	topList.TextXAlignment = Enum.TextXAlignment.Left
	topList.TextYAlignment = Enum.TextYAlignment.Top
	topList.TextWrapped = true
	topList.Text = "Loading..."
	topList.Parent = container

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -24, 0, 1)
	divider.Position = UDim2.new(0, 12, 1, -100)
	divider.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	divider.BorderSizePixel = 0
	divider.Parent = container

	local selfLabel = Instance.new("TextLabel")
	selfLabel.Size = UDim2.new(1, -24, 0, 90)
	selfLabel.Position = UDim2.new(0, 12, 1, -94)
	selfLabel.BackgroundTransparency = 1
	selfLabel.Font = Enum.Font.Gotham
	selfLabel.TextSize = 15
	selfLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	selfLabel.TextXAlignment = Enum.TextXAlignment.Left
	selfLabel.TextYAlignment = Enum.TextYAlignment.Top
	selfLabel.TextWrapped = true
	selfLabel.Text = ""
	selfLabel.Parent = container

	local self = setmetatable({
		gui = gui,
		topList = topList,
		selfLabel = selfLabel,
	}, LeaderboardUI)

	closeButton.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)

	return self
end

function LeaderboardUI.Toggle(self: LeaderboardUI)
	self.gui.Enabled = not self.gui.Enabled
end

function LeaderboardUI.Show(self: LeaderboardUI)
	self.gui.Enabled = true
end

function LeaderboardUI.IsVisible(self: LeaderboardUI): boolean
	return self.gui.Enabled
end

function LeaderboardUI.SetData(self: LeaderboardUI, topN: { TopNEntry }, selfStats: SelfStats)
	if #topN == 0 then
		self.topList.Text = "No scores yet. Be the first!"
	else
		local lines = {}
		for i, entry in topN do
			table.insert(lines, `{i}. {entry.Name} - {entry.Points} pts`)
		end
		self.topList.Text = table.concat(lines, "\n")
	end

	self.selfLabel.Text = table.concat({
		"Your stats:",
		`Wins: {selfStats.Wins}   Points: {selfStats.Points}`,
		`Best placement: {if selfStats.BestPlacement > 0 then tostring(selfStats.BestPlacement) else "-"}`,
		`Games played: {selfStats.GamesPlayed}`,
	}, "\n")
end

return LeaderboardUI
