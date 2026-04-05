local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local VisualTabModule = {}

function VisualTabModule:Build(Window, Rayfield, Shared)
	local VisualTab = Window:CreateTab("Visual", "eye")

	local espEnabled = false
	local teamCheckEnabled = true
	local espColor = Color3.fromRGB(255, 0, 0)
	local espUpdateThreadRunning = false

	local espFolder = Instance.new("Folder")
	espFolder.Name = "SAIOPS_ESP"
	espFolder.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local function sameTeam(player)
		if not teamCheckEnabled then
			return false
		end

		if not LocalPlayer.Team or not player.Team then
			return false
		end

		return LocalPlayer.Team == player.Team
	end

	local function clearESP()
		for _, child in ipairs(espFolder:GetChildren()) do
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

	local function getHumanoid(player)
		local character = player.Character
		if not character then
			return nil
		end

		return character:FindFirstChildOfClass("Humanoid")
	end

	local function hasAliveHumanoid(player)
		local humanoid = getHumanoid(player)
		return humanoid and humanoid.Health > 0
	end

	local function updateESP()
		if not espEnabled then
			clearESP()
			return
		end

		local active = {}
		local myRoot = getRootPart(LocalPlayer)

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and hasAliveHumanoid(player) and not sameTeam(player) then
				local rootPart = getRootPart(player)
				local humanoid = getHumanoid(player)
				if rootPart and humanoid then
					local espId = "ESP_" .. player.UserId
					active[espId] = true

					local espGui = espFolder:FindFirstChild(espId)
					if not espGui then
						espGui = Instance.new("BillboardGui")
						espGui.Name = espId
						espGui.Size = UDim2.new(4, 0, 5, 0)
						espGui.AlwaysOnTop = true
						espGui.MaxDistance = 500
						espGui.Parent = espFolder

						local nameLabel = Instance.new("TextLabel")
						nameLabel.Name = "NameLabel"
						nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
						nameLabel.Position = UDim2.new(0, 0, 0, 0)
						nameLabel.BackgroundTransparency = 1
						nameLabel.TextScaled = true
						nameLabel.Font = Enum.Font.GothamBold
						nameLabel.Parent = espGui

						local healthLabel = Instance.new("TextLabel")
						healthLabel.Name = "HealthLabel"
						healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
						healthLabel.Position = UDim2.new(0, 0, 0.35, 0)
						healthLabel.BackgroundTransparency = 1
						healthLabel.TextScaled = true
						healthLabel.Font = Enum.Font.Gotham
						healthLabel.Parent = espGui

						local distanceLabel = Instance.new("TextLabel")
						distanceLabel.Name = "DistanceLabel"
						distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
						distanceLabel.Position = UDim2.new(0, 0, 0.7, 0)
						distanceLabel.BackgroundTransparency = 1
						distanceLabel.TextScaled = true
						distanceLabel.Font = Enum.Font.Gotham
						distanceLabel.Parent = espGui
					end

				espGui.Adornee = rootPart

				local nameLabel = espGui:FindFirstChild("NameLabel")
				local healthLabel = espGui:FindFirstChild("HealthLabel")
				local distanceLabel = espGui:FindFirstChild("DistanceLabel")

				if nameLabel then
					nameLabel.Text = player.Name
					nameLabel.TextColor3 = espColor
				end

				if healthLabel then
					local maxHealth = math.max(humanoid.MaxHealth, 1)
					local healthPercent = math.floor((humanoid.Health / maxHealth) * 100)
					healthLabel.Text = "HP: " .. healthPercent .. "%"
					healthLabel.TextColor3 = espColor
				end

				if distanceLabel and myRoot then
					local distance = math.floor((myRoot.Position - rootPart.Position).Magnitude)
					distanceLabel.Text = "[" .. distance .. "m]"
					distanceLabel.TextColor3 = espColor
				elseif distanceLabel then
					distanceLabel.Text = "[--m]"
				end
			end
		end

		for _, child in ipairs(espFolder:GetChildren()) do
			if not active[child.Name] then
				child:Destroy()
			end
		end
	end

	VisualTab:CreateSection("ESP")

	VisualTab:CreateToggle({
		Name = "Enable ESP",
		CurrentValue = false,
		Flag = "esp_enabled",
		Callback = function(value)
			espEnabled = value
			Shared:Notify(Rayfield, "ESP", value and "Enabled" or "Disabled")
			updateESP()
		end
	})

	VisualTab:CreateToggle({
		Name = "Team Check",
		CurrentValue = true,
		Flag = "esp_team_check",
		Callback = function(value)
			teamCheckEnabled = value
			updateESP()
		end
	})

	VisualTab:CreateColorPicker({
		Name = "ESP Color",
		Color = espColor,
		Flag = "esp_color",
		Callback = function(value)
			espColor = value
			updateESP()
		end
	})

	if not espUpdateThreadRunning then
		espUpdateThreadRunning = true
		task.spawn(function()
			while task.wait(0.15) do
				updateESP()
			end
		end)
	end

	return VisualTab
end

return VisualTabModule