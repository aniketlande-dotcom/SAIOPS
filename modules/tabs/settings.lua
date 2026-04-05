local SettingsTabModule = {}

function SettingsTabModule:Build(Window, Rayfield, Shared)
	local SettingsTab = Window:CreateTab("Settings", "settings")

	SettingsTab:CreateSection("Interface")

	SettingsTab:CreateParagraph({
		Title = "Theme",
		Content = "Theme is fixed to Amethyst in this build."
	})

	SettingsTab:CreateKeybind({
		Name = "Toggle UI",
		CurrentKeybind = "RightCtrl",
		HoldToInteract = false,
		Flag = "toggle_ui_keybind",
		Callback = function()
			Rayfield:SetVisibility(not Rayfield:IsVisible())
			task.defer(function()
				Shared:PinWindowToTop()
			end)
		end
	})

	SettingsTab:CreateButton({
		Name = "Re-pin Window",
		Callback = function()
			Shared:PinWindowToTop()
		end
	})

	return SettingsTab
end

return SettingsTabModule