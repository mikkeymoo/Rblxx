--!strict
-- Full-screen "eliminated, now spectating" overlay. Shown only to the
-- targeted client when the server fires YouWereEliminated; hidden again on
-- the next round state change.
local EliminationOverlay = {}
EliminationOverlay.__index = EliminationOverlay

export type EliminationOverlay = typeof(setmetatable(
	{} :: {
		gui: ScreenGui,
	},
	EliminationOverlay
))

function EliminationOverlay.new(playerGui: PlayerGui): EliminationOverlay
	local gui = Instance.new("ScreenGui")
	gui.Name = "HardcoreEliminationOverlay"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local tint = Instance.new("Frame")
	tint.Size = UDim2.fromScale(1, 1)
	tint.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
	tint.BackgroundTransparency = 0.75
	tint.BorderSizePixel = 0
	tint.Parent = gui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 60)
	label.Position = UDim2.new(0, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 34
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.Text = "ELIMINATED - SPECTATING"
	label.Parent = gui

	return setmetatable({ gui = gui }, EliminationOverlay)
end

function EliminationOverlay.Show(self: EliminationOverlay)
	self.gui.Enabled = true
end

function EliminationOverlay.Hide(self: EliminationOverlay)
	self.gui.Enabled = false
end

return EliminationOverlay
