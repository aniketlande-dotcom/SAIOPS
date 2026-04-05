local UtilityTabModule = {}

function UtilityTabModule:Build(Window, Rayfield, Shared)
	local UtilityTab = Window:CreateTab("Utility", "wrench")

	UtilityTab:CreateSection("Automation")

	UtilityTab:CreateToggle({
		Name = "Auto Farm (Placeholder)",
		CurrentValue = false,
		Flag = "autofarm_enabled",
		Callback = function(value)
			Shared.State.AutoFarmEnabled = value
			Shared:Notify(Rayfield, "Auto Farm", value and "Enabled" or "Disabled")
		end
	})

	UtilityTab:CreateButton({
		Name = "Reapply Movement",
		Callback = function()
			Shared:ApplyMovement()
			Shared:Notify(Rayfield, "Utility", "Movement values reapplied")
		end
	})

	UtilityTab:CreateInput({
		Name = "Notification Test",
		CurrentValue = "",
		PlaceholderText = "Type message and press Enter",
		RemoveTextAfterFocusLost = false,
		Flag = "notify_text",
		Callback = function(text)
			if text and text ~= "" then
				Shared:Notify(Rayfield, "Custom Message", text)
			end
		end
	})

	return UtilityTab
end

return UtilityTabModule