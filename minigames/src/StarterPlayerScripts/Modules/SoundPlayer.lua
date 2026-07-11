--!strict
-- Plays one-shot sounds from Config.Sounds (built-in rbxasset:// paths only) and
-- cleans the Sound instance up afterward.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local SoundPlayer = {}

function SoundPlayer.Play(name: string)
	local soundId = Config.Sounds[name]
	if not soundId then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	sound:Play()
	task.delay(10, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

return SoundPlayer
