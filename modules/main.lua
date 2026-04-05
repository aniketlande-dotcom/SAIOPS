local GITHUB_TOKEN = "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"
local REPO_PATH = "aniketlande-dotcom/SAIOPS/main/"

local function GetPrivateFile(path)
	local url = "https://raw.githubusercontent.com/" .. REPO_PATH .. path
	local requestFunction = request or http_request or (syn and syn.request)

	if requestFunction then
		local response = requestFunction({
			Url = url,
			Method = "GET",
			Headers = {
				["Authorization"] = "token " .. GITHUB_TOKEN
			}
		})

		if response and response.Body then
			return response.Body
		end
	end

	return game:HttpGet(url, true)
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Shared = loadstring(GetPrivateFile("modules/shared.lua"))()
local WindowModule = loadstring(GetPrivateFile("modules/window.lua"))()
local PlayerTabModule = loadstring(GetPrivateFile("modules/tabs/player.lua"))()
local VisualTabModule = loadstring(GetPrivateFile("modules/tabs/visual.lua"))()
local UtilityTabModule = loadstring(GetPrivateFile("modules/tabs/utility.lua"))()
local SettingsTabModule = loadstring(GetPrivateFile("modules/tabs/settings.lua"))()

local Window = WindowModule:Create(Rayfield)

PlayerTabModule:Build(Window, Rayfield, Shared)
VisualTabModule:Build(Window, Rayfield, Shared)
UtilityTabModule:Build(Window, Rayfield, Shared)
SettingsTabModule:Build(Window, Rayfield, Shared)

pcall(function()
	Shared:PinWindowToTop()
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	Shared:ApplyMovement()
end)

task.spawn(function()
	while task.wait(0.2) do
		pcall(function()
			Shared:PinWindowToTop()
		end)
	end
end)

Rayfield:Notify({
	Title = "SAIOPS",
	Content = "Mod menu loaded successfully",
	Duration = 5,
	Image = "check-circle"
})

Rayfield:LoadConfiguration()