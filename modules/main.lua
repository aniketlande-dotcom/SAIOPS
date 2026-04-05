local REPO_PATH = "aniketlande-dotcom/SAIOPS/main/"
local REPO_REF = "c5f07b1"

local function GetPublicFile(path)
	return game:HttpGet("https://raw.githubusercontent.com/aniketlande-dotcom/SAIOPS/" .. REPO_REF .. "/" .. path, true)
end

local function LoadModule(path)
	if type(loadstring) ~= "function" then
		error("SAIOPS: loadstring is not available in this executor.")
	end

	local source = GetPublicFile(path)
	if type(source) ~= "string" or source == "" then
		error("SAIOPS: unable to fetch " .. path .. " from the public repository.")
	end

	local chunk, loadError = loadstring(source)
	if not chunk then
		error("SAIOPS: invalid module " .. path .. ": " .. tostring(loadError))
	end

	return chunk()
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Shared = LoadModule("modules/shared.lua")
local WindowModule = LoadModule("modules/window.lua")
local PlayerTabModule = LoadModule("modules/tabs/player.lua")
local VisualTabModule = LoadModule("modules/tabs/visual.lua")
local AimbotTabModule = LoadModule("modules/tabs/aimbot.lua")
local UtilityTabModule = LoadModule("modules/tabs/utility.lua")
local SettingsTabModule = LoadModule("modules/tabs/settings.lua")

local Window = WindowModule:Create(Rayfield)

PlayerTabModule:Build(Window, Rayfield, Shared)
VisualTabModule:Build(Window, Rayfield, Shared)
AimbotTabModule:Build(Window, Rayfield, Shared)
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
	while task.wait(0.05) do
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