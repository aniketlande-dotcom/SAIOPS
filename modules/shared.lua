local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local Shared = {
	State = {
		GodMode = false,
		SpeedEnabled = false,
		WalkSpeed = 16,
		JumpEnabled = false,
		JumpPower = 50,
		FlyEnabled = false,
		NoclipEnabled = false,
		AutoFarmEnabled = false,
		EspEnabled = false,
		EspColor = Color3.fromRGB(255, 0, 0)
	}
}

function Shared:GetCharacter()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

function Shared:ApplyMovement()
	local character = self:GetCharacter()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = self.State.SpeedEnabled and self.State.WalkSpeed or 16
	humanoid.JumpPower = self.State.JumpEnabled and self.State.JumpPower or 50
end

function Shared:Notify(Rayfield, title, content, image)
	Rayfield:Notify({
		Title = title,
		Content = content,
		Duration = 4,
		Image = image or "bell"
	})
end

function Shared:FindRayfieldMainFrame()
	for _, gui in ipairs(CoreGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			local main = gui:FindFirstChild("Main", true)
			if main and main:IsA("GuiObject") then
				return main
			end
		end
	end

	return nil
end

function Shared:FindRayfieldScreenGui()
	for _, gui in ipairs(CoreGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui:FindFirstChild("Main", true) then
			return gui
		end
	end

	return nil
end

function Shared:PinMiniPromptToTop()
	local gui = self:FindRayfieldScreenGui()
	if not gui then
		return
	end

	local prompt = gui:FindFirstChild("MPrompt", true)
	if not prompt or not prompt:IsA("GuiObject") then
		return
	end

	prompt.AnchorPoint = Vector2.new(0.5, 0)
	prompt.Position = UDim2.new(0.5, 0, 0, 8)
end

function Shared:PinWindowToTop()
	local main = self:FindRayfieldMainFrame()
	if not main then
		return
	end

	local anchor = main.AnchorPoint
	main.AnchorPoint = Vector2.new(anchor.X, 0)
	main.Position = UDim2.new(0.5, 0, 0, 12)

	self:PinMiniPromptToTop()
end

return Shared