--!strict
-- Results screen: final standings for the round that just ended.
local ResultsUI = {}
ResultsUI.__index = ResultsUI

export type ResultEntry = {
	Name: string,
	Placement: number,
	Score: number,
}

export type ResultsUI = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
		titleLabel: TextLabel,
		list: TextLabel,
	},
	ResultsUI
))

function ResultsUI.new(playerGui: PlayerGui): ResultsUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "HardcoreResultsUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(360, 320)
	container.Position = UDim2.new(0.5, -180, 0.5, -160)
	container.BackgroundColor3 = Color3.fromRGB(18, 8, 8)
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = container

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 40)
	titleLabel.Position = UDim2.new(0, 10, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 24
	titleLabel.TextColor3 = Color3.fromRGB(255, 210, 100)
	titleLabel.Text = "Results"
	titleLabel.Parent = container

	local list = Instance.new("TextLabel")
	list.Size = UDim2.new(1, -20, 1, -64)
	list.Position = UDim2.new(0, 10, 0, 56)
	list.BackgroundTransparency = 1
	list.Font = Enum.Font.Gotham
	list.TextSize = 18
	list.TextColor3 = Color3.new(1, 1, 1)
	list.TextXAlignment = Enum.TextXAlignment.Left
	list.TextYAlignment = Enum.TextYAlignment.Top
	list.TextWrapped = true
	list.Text = ""
	list.Parent = container

	return setmetatable({
		gui = gui,
		titleLabel = titleLabel,
		list = list,
	}, ResultsUI)
end

function ResultsUI.Show(self: ResultsUI, gameName: string, results: { ResultEntry })
	self.titleLabel.Text = `{gameName} - Results`

	table.sort(results, function(a, b)
		return a.Placement < b.Placement
	end)

	local lines = {}
	for _, entry in results do
		table.insert(lines, `#{entry.Placement}  {entry.Name}  -  {entry.Score} pts`)
	end
	self.list.Text = if #lines > 0 then table.concat(lines, "\n") else "No results this round."

	self.gui.Enabled = true
end

function ResultsUI.Hide(self: ResultsUI)
	self.gui.Enabled = false
end

return ResultsUI
