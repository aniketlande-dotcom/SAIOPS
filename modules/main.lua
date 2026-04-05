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

local function LoadPrivateModule(path)
	local source = GetPrivateFile(path)
	if type(source) ~= "string" or source == "" then
		error("SAIOPS: unable to fetch " .. path .. ". This executor needs request/http_request/syn.request support to load private GitHub modules.")
	end

	local chunk, loadError = loadstring(source)
	if not chunk then
		error("SAIOPS: invalid module " .. path .. ": " .. tostring(loadError))
	end

	return chunk()
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Shared = LoadPrivateModule("modules/shared.lua")
local WindowModule = LoadPrivateModule("modules/window.lua")
local PlayerTabModule = LoadPrivateModule("modules/tabs/player.lua")
local VisualTabModule = LoadPrivateModule("modules/tabs/visual.lua")
local UtilityTabModule = LoadPrivateModule("modules/tabs/utility.lua")
local SettingsTabModule = LoadPrivateModule("modules/tabs/settings.lua")

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

>>>>>>> 951e6f4 (Update private loader token)
Rayfield:LoadConfiguration()