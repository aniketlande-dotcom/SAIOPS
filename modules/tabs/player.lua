local PlayerTabModule = {}

function PlayerTabModule:Build(Window, Rayfield, Shared)
	local PlayerTab = Window:CreateTab("Player", "user")

	PlayerTab:CreateSection("Movement")

	PlayerTab:CreateToggle({
		Name = "Enable Speed",
		CurrentValue = false,
		Flag = "speed_enabled",
		Callback = function(value)
			Shared.State.SpeedEnabled = value
			Shared:ApplyMovement()
			Shared:Notify(Rayfield, "Speed", value and "Speed enabled" or "Speed disabled")
		end
	})

	PlayerTab:CreateSlider({
		Name = "WalkSpeed",
		Range = {16, 200},
		Increment = 1,
		Suffix = "WS",
		CurrentValue = 16,
		Flag = "walk_speed",
		Callback = function(value)
			Shared.State.WalkSpeed = value
			Shared:ApplyMovement()
		end
	})

	PlayerTab:CreateToggle({
		Name = "Enable Jump",
		CurrentValue = false,
		Flag = "jump_enabled",
		Callback = function(value)
			Shared.State.JumpEnabled = value
			Shared:ApplyMovement()
			Shared:Notify(Rayfield, "Jump", value and "Jump power enabled" or "Jump power disabled")
		end
	})

	PlayerTab:CreateSlider({
		Name = "JumpPower",
		Range = {50, 200},
		Increment = 1,
		Suffix = "JP",
		CurrentValue = 50,
		Flag = "jump_power",
		Callback = function(value)
			Shared.State.JumpPower = value
			Shared:ApplyMovement()
		end
	})

	PlayerTab:CreateDivider()

	PlayerTab:CreateToggle({
		Name = "God Mode (Placeholder)",
		CurrentValue = false,
		Flag = "god_mode",
		Callback = function(value)
			Shared.State.GodMode = value
			Shared:Notify(Rayfield, "God Mode", value and "Enabled" or "Disabled")
		end
	})

	PlayerTab:CreateToggle({
		Name = "Fly (Placeholder)",
		CurrentValue = false,
		Flag = "fly_enabled",
		Callback = function(value)
			Shared.State.FlyEnabled = value
			Shared:Notify(Rayfield, "Fly", value and "Enabled" or "Disabled")
		end
	})

	PlayerTab:CreateToggle({
		Name = "Noclip (Placeholder)",
		CurrentValue = false,
		Flag = "noclip_enabled",
		Callback = function(value)
			Shared.State.NoclipEnabled = value
			Shared:Notify(Rayfield, "Noclip", value and "Enabled" or "Disabled")
		end
	})

	return PlayerTab
end

return PlayerTabModule