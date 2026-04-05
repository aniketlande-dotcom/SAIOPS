local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local VisualTabModule = {}

function VisualTabModule:Build(Window, Rayfield, Shared)
	local VisualTab = Window:CreateTab("Visual", "eye")

	local charmsEnabled = false
	local teamCheckEnabled = true
	local charmColor = Color3.fromRGB(255, 0, 0)

	local charmFolder = Instance.new("Folder")
	charmFolder.Name = "SAIOPS_Charms"
	charmFolder.Parent = game:GetService("CoreGui")

	local function sameTeam(player)
		if not teamCheckEnabled then
			return false
		end

		if not LocalPlayer.Team or not player.Team then
			return false
		end

		return LocalPlayer.Team == player.Team
	end

	local function clearCharms()
		for _, child in ipairs(charmFolder:GetChildren()) do
			child:Destroy()
		end
	end

	local function getRootPart(player)
		local character = player.Character
		if not character then
			return nil
		end

		return character:FindFirstChild("HumanoidRootPart")
	end

	local function hasAliveHumanoid(player)
		local character = player.Character
		if not character then
			return false
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		return humanoid and humanoid.Health > 0
	end

	local function updateCharms()
		if not charmsEnabled then
			clearCharms()
			return
		end

		local active = {}

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and hasAliveHumanoid(player) and not sameTeam(player) then
				local rootPart = getRootPart(player)
				if rootPart then
					local name = "Charm_" .. player.UserId
					active[name] = true

					local charm = charmFolder:FindFirstChild(name)
					if not charm then
						charm = Instance.new("BoxHandleAdornment")
						charm.Name = name
						charm.AlwaysOnTop = true
						charm.ZIndex = 5
						charm.Transparency = 0.35
						charm.Size = Vector3.new(2.5, 3.2, 1.6)
						charm.Parent = charmFolder
					end

					charm.Color3 = charmColor
					charm.Adornee = rootPart
				end
			end
		end

		for _, child in ipairs(charmFolder:GetChildren()) do
			if not active[child.Name] then
				child:Destroy()
			end
		end
	end

	VisualTab:CreateSection("Charms")

	VisualTab:CreateToggle({
		Name = "Enable Charms",
		CurrentValue = false,
		Flag = "charms_enabled",
		Callback = function(value)
			charmsEnabled = value
			Shared:Notify(Rayfield, "Charms", value and "Enabled" or "Disabled")
			updateCharms()
		end
	})

	VisualTab:CreateToggle({
		Name = "Team Check",
		CurrentValue = true,
		Flag = "charms_team_check",
		Callback = function(value)
			teamCheckEnabled = value
			updateCharms()
		end
	})

	VisualTab:CreateColorPicker({
		Name = "Charm Color",
		Color = charmColor,
		Flag = "charms_color",
		Callback = function(value)
			charmColor = value
			updateCharms()
		end
	})

	RunService.RenderStepped:Connect(function()
		updateCharms()
	end)

	return VisualTab
end

return VisualTabModule