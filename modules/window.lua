local WindowModule = {}

function WindowModule:Create(Rayfield)
	local Window = Rayfield:CreateWindow({
		Name = "SAIOPS Mod Menu",
		Icon = "shield",
		LoadingTitle = "SAIOPS",
		LoadingSubtitle = "Rayfield UI",
		ShowText = "SAIOPS",
		Theme = "Amethyst",

		ToggleUIKeybind = Enum.KeyCode.RightControl,

		DisableRayfieldPrompts = false,
		DisableBuildWarnings = false,

		ConfigurationSaving = {
			Enabled = true,
			FolderName = "SAIOPS",
			FileName = "SAIOP_Config"
		},

		Discord = {
			Enabled = false,
			Invite = "",
			RememberJoins = true
		},

		KeySystem = false,
		KeySettings = {
			Title = "SAIOPS",
			Subtitle = "Key System",
			Note = "No key required",
			FileName = "SAIOPS_Key",
			SaveKey = false,
			GrabKeyFromSite = false,
			Key = {""}
		}
	})

	return Window
end

return WindowModule