local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local VisualTabModule = {}

local R6_CONNECTIONS = {
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Torso", "Right Arm" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" }
}

local R15_CONNECTIONS = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" }
}

local MAX_SKELETON_LINES = math.max(#R6_CONNECTIONS, #R15_CONNECTIONS)

function VisualTabModule:Build(Window, Rayfield, Shared)
	local VisualTab = Window:CreateTab("Visual", "eye")

	local espEnabled = false
	local teamCheckEnabled = true
	local espColor = Color3.fromRGB(255, 0, 0)
	local espUpdateThreadRunning = false

	local drawingAvailable = type(Drawing) == "table" and type(Drawing.new) == "function"
	local espObjects = {}

	local function sameTeam(player)
		if not teamCheckEnabled then
			return false
		end

		if not LocalPlayer.Team or not player.Team then
			return false
		end

		return LocalPlayer.Team == player.Team
	end

	local function getHumanoid(player)
		local character = player.Character
		if not character then
			return nil
		end

		return character:FindFirstChildOfClass("Humanoid")
	end

	local function worldToScreen(position)
		local camera = workspace.CurrentCamera
		if not camera then
			return nil, false, -1
		end

		local viewportPoint, onScreen = camera:WorldToViewportPoint(position)
		return Vector2.new(viewportPoint.X, viewportPoint.Y), onScreen, viewportPoint.Z
	end

	local function createLine(thickness)
		local line = Drawing.new("Line")
		line.Visible = false
		line.Thickness = thickness or 1
		line.Transparency = 1
		line.Color = espColor
		return line
	end

	local function createObjectSet()
		local set = {
			Box = Drawing.new("Square"),
			BoxOutline = Drawing.new("Square"),
			Name = Drawing.new("Text"),
			HealthBackground = Drawing.new("Square"),
			HealthFill = Drawing.new("Square"),
			HealthOutline = Drawing.new("Square"),
			SkeletonLines = {}
		}

		set.Box.Visible = false
		set.Box.Filled = false
		set.Box.Thickness = 1
		set.Box.Transparency = 1
		set.Box.Color = espColor

		set.BoxOutline.Visible = false
		set.BoxOutline.Filled = false
		set.BoxOutline.Thickness = 3
		set.BoxOutline.Transparency = 1
		set.BoxOutline.Color = Color3.new(0, 0, 0)

		set.Name.Visible = false
		set.Name.Size = 13
		set.Name.Center = true
		set.Name.Outline = true
		set.Name.Font = 2
		set.Name.Transparency = 1
		set.Name.Color = espColor

		set.HealthBackground.Visible = false
		set.HealthBackground.Filled = true
		set.HealthBackground.Thickness = 1
		set.HealthBackground.Transparency = 0.75
		set.HealthBackground.Color = Color3.new(0, 0, 0)

		set.HealthFill.Visible = false
		set.HealthFill.Filled = true
		set.HealthFill.Thickness = 1
		set.HealthFill.Transparency = 1

		set.HealthOutline.Visible = false
		set.HealthOutline.Filled = false
		set.HealthOutline.Thickness = 1
		set.HealthOutline.Transparency = 1
		set.HealthOutline.Color = Color3.new(0, 0, 0)

		for _ = 1, MAX_SKELETON_LINES do
			table.insert(set.SkeletonLines, createLine(1.5))
		end

		return set
	end

	local function hideObjectSet(set)
		if not set then
			return
		end

		set.Box.Visible = false
		set.BoxOutline.Visible = false
		set.Name.Visible = false
		set.HealthBackground.Visible = false
		set.HealthFill.Visible = false
		set.HealthOutline.Visible = false

		for _, line in ipairs(set.SkeletonLines) do
			line.Visible = false
		end
	end

	local function removeObjectSet(set)
		if not set then
			return
		end

		for _, line in ipairs(set.SkeletonLines) do
			line:Remove()
		end

		set.Box:Remove()
		set.BoxOutline:Remove()
		set.Name:Remove()
		set.HealthBackground:Remove()
		set.HealthFill:Remove()
		set.HealthOutline:Remove()
	end

	local function clearESP()
		for userId, set in pairs(espObjects) do
			removeObjectSet(set)
			espObjects[userId] = nil
		end
	end

	local function getRigConnections(humanoid)
		if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
			return R6_CONNECTIONS
		end

		return R15_CONNECTIONS
	end

	local function getBoxBounds(character, humanoid)
		local root = character:FindFirstChild("HumanoidRootPart")
		local head = character:FindFirstChild("Head")
		if not root or not head or not root:IsA("BasePart") or not head:IsA("BasePart") then
			return nil
		end

		local topWorld = head.Position + Vector3.new(0, 0.6, 0)
		local bottomOffset = humanoid.RigType == Enum.HumanoidRigType.R6 and 2.9 or 3.1
		local bottomWorld = root.Position - Vector3.new(0, bottomOffset, 0)

		local topScreen, topOnScreen, topDepth = worldToScreen(topWorld)
		local bottomScreen, bottomOnScreen, bottomDepth = worldToScreen(bottomWorld)
		local rootScreen, rootOnScreen, rootDepth = worldToScreen(root.Position)

		if not topScreen or not bottomScreen or not rootScreen then
			return nil
		end

		if not topOnScreen or not bottomOnScreen or not rootOnScreen then
			return nil
		end

		if topDepth <= 0 or bottomDepth <= 0 or rootDepth <= 0 then
			return nil
		end

		local minY = math.min(topScreen.Y, bottomScreen.Y)
		local maxY = math.max(topScreen.Y, bottomScreen.Y)
		local height = maxY - minY
		if height < 6 then
			return nil
		end

		local widthScale = humanoid.RigType == Enum.HumanoidRigType.R6 and 0.52 or 0.45
		local width = math.clamp(height * widthScale, 14, 140)
		local minX = rootScreen.X - (width * 0.5)
		local maxX = rootScreen.X + (width * 0.5)

		return {
			MinX = minX,
			MinY = minY,
			MaxX = maxX,
			MaxY = maxY,
			Width = width,
			Height = height,
			CenterX = rootScreen.X
		}
	end

	local function getHealthColor(ratio)
		local red = math.floor(255 * (1 - ratio))
		local green = math.floor(255 * ratio)
		return Color3.fromRGB(red, green, 40)
	end

	local function updateHealthBar(set, bounds, humanoid)
		local maxHealth = math.max(humanoid.MaxHealth, 1)
		local ratio = math.clamp(humanoid.Health / maxHealth, 0, 1)

		local barWidth = 4
		local barX = bounds.MaxX + 5
		local barY = bounds.MinY
		local barHeight = bounds.Height
		local fillHeight = math.max(1, math.floor(barHeight * ratio))

		set.HealthBackground.Position = Vector2.new(barX, barY)
		set.HealthBackground.Size = Vector2.new(barWidth, barHeight)
		set.HealthBackground.Visible = true

		set.HealthFill.Position = Vector2.new(barX, barY + (barHeight - fillHeight))
		set.HealthFill.Size = Vector2.new(barWidth, fillHeight)
		set.HealthFill.Color = getHealthColor(ratio)
		set.HealthFill.Visible = true

		set.HealthOutline.Position = Vector2.new(barX - 1, barY - 1)
		set.HealthOutline.Size = Vector2.new(barWidth + 2, barHeight + 2)
		set.HealthOutline.Visible = true
	end

	local function updateSkeleton(set, character, humanoid)
		local connections = getRigConnections(humanoid)
		local partCache = {}

		for _, pair in ipairs(connections) do
			for i = 1, 2 do
				local partName = pair[i]
				if partCache[partName] == nil then
					local part = character:FindFirstChild(partName)
					if part and part:IsA("BasePart") then
						partCache[partName] = part
					else
						partCache[partName] = false
					end
				end
			end
		end

		for lineIndex, line in ipairs(set.SkeletonLines) do
			local pair = connections[lineIndex]
			if not pair then
				line.Visible = false
			else
				local partA = partCache[pair[1]]
				local partB = partCache[pair[2]]

				if partA and partB then
					local fromPos, fromOnScreen, fromDepth = worldToScreen(partA.Position)
					local toPos, toOnScreen, toDepth = worldToScreen(partB.Position)

					if fromPos and toPos and fromOnScreen and toOnScreen and fromDepth > 0 and toDepth > 0 then
						line.From = fromPos
						line.To = toPos
						line.Color = espColor
						line.Visible = true
					else
						line.Visible = false
					end
				else
					line.Visible = false
				end
			end
		end
	end

	local function updateESP()
		if not drawingAvailable then
			return
		end

		if not espEnabled then
			for _, set in pairs(espObjects) do
				hideObjectSet(set)
			end
			return
		end

		local active = {}

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not sameTeam(player) then
				local character = player.Character
				local humanoid = getHumanoid(player)

				if character and humanoid and humanoid.Health > 0 then
					local bounds = getBoxBounds(character, humanoid)
					if bounds then
						active[player.UserId] = true

						local set = espObjects[player.UserId]
						if not set then
							set = createObjectSet()
							espObjects[player.UserId] = set
						end

						set.BoxOutline.Position = Vector2.new(bounds.MinX, bounds.MinY)
						set.BoxOutline.Size = Vector2.new(bounds.Width, bounds.Height)
						set.BoxOutline.Visible = true

						set.Box.Position = Vector2.new(bounds.MinX, bounds.MinY)
						set.Box.Size = Vector2.new(bounds.Width, bounds.Height)
						set.Box.Color = espColor
						set.Box.Visible = true

						set.Name.Text = player.Name
						set.Name.Position = Vector2.new(bounds.CenterX, bounds.MinY - 16)
						set.Name.Color = espColor
						set.Name.Visible = true

						updateHealthBar(set, bounds, humanoid)
						updateSkeleton(set, character, humanoid)
					else
						local set = espObjects[player.UserId]
						if set then
							hideObjectSet(set)
						end
					end
				else
					local set = espObjects[player.UserId]
					if set then
						hideObjectSet(set)
					end
				end
			else
				local set = espObjects[player.UserId]
				if set then
					hideObjectSet(set)
				end
			end
		end

		for userId, set in pairs(espObjects) do
			if not active[userId] then
				hideObjectSet(set)
			end
		end
	end

	if not drawingAvailable then
		Shared:Notify(Rayfield, "ESP", "Drawing API not available in this executor")
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

			if not value then
				for _, set in pairs(espObjects) do
					hideObjectSet(set)
				end
			end
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
		RunService.RenderStepped:Connect(updateESP)
	end

	LocalPlayer.CharacterRemoving:Connect(function()
		clearESP()
	end)

	return VisualTab
end

return VisualTabModule