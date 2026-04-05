local VisualTabModule = {}

function VisualTabModule:Build(Window, Rayfield, Shared)
	local VisualTab = Window:CreateTab("Visual", "eye")

	VisualTab:CreateSection("ESP")

	VisualTab:CreateToggle({
		Name = "Enable ESP (Placeholder)",
		CurrentValue = false,
		Flag = "esp_enabled",
		Callback = function(value)
			Shared.State.EspEnabled = value
			Shared:Notify(Rayfield, "ESP", value and "Enabled" or "Disabled")
		end
	})

	VisualTab:CreateColorPicker({
		Name = "ESP Color",
		Color = Shared.State.EspColor,
		Flag = "esp_color",
		Callback = function(value)
			Shared.State.EspColor = value
		end
	})

	VisualTab:CreateParagraph({
		Title = "Note",
		Content = "ESP, fly, noclip, and god mode are scaffolded as placeholders. Add game-specific logic in each callback."
	})

	return VisualTab
end

return VisualTabModule