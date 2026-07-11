--!strict
-- Winner celebration screen: shown during Results, lists the round's winning player names.
local WinnerScreen = {}
WinnerScreen.__index = WinnerScreen

export type WinnerScreen = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
		titleLabel: TextLabel,
		namesLabel: TextLabel,
	},
	WinnerScreen
))

function WinnerScreen.new(playerGui: PlayerGui): WinnerScreen
	local gui = Instance.new("ScreenGui")
	gui.Name = "WinnerScreen"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(500, 180)
	container.Position = UDim2.new(0.5, -250, 0.5, -90)
	container.BackgroundColor3 = Color3.fromRGB(25, 20, 10)
	container.BackgroundTransparency = 0.15
	container.BorderSizePixel = 0
	container.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = container

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 50)
	titleLabel.Position = UDim2.new(0, 10, 0, 15)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 28
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
	titleLabel.Text = ""
	titleLabel.Parent = container

	local namesLabel = Instance.new("TextLabel")
	namesLabel.Size = UDim2.new(1, -20, 0, 90)
	namesLabel.Position = UDim2.new(0, 10, 0, 70)
	namesLabel.BackgroundTransparency = 1
	namesLabel.Font = Enum.Font.Gotham
	namesLabel.TextSize = 22
	namesLabel.TextWrapped = true
	namesLabel.TextColor3 = Color3.new(1, 1, 1)
	namesLabel.Text = ""
	namesLabel.Parent = container

	return setmetatable({
		gui = gui,
		titleLabel = titleLabel,
		namesLabel = namesLabel,
	}, WinnerScreen)
end

function WinnerScreen.Show(self: WinnerScreen, gameName: string, winnerNames: { string })
	self.titleLabel.Text = `{gameName} - Results`
	if #winnerNames == 0 then
		self.namesLabel.Text = "No winners this round!"
	elseif #winnerNames == 1 then
		self.namesLabel.Text = `Winner: {winnerNames[1]}`
	else
		self.namesLabel.Text = `Winners: {table.concat(winnerNames, ", ")}`
	end
	self.gui.Enabled = true
end

function WinnerScreen.Hide(self: WinnerScreen)
	self.gui.Enabled = false
end

return WinnerScreen
