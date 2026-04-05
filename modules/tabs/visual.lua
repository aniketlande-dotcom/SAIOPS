local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local VisualTabModule = {}

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

	local function hasAliveHumanoid(player)
		local humanoid = getHumanoid(player)
		return humanoid and humanoid.Health > 0
	end

	local function getFirstPart(character, partNames)
		for _, partName in ipairs(partNames) do
			local part = character:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				return part
			end
		end

		return nil
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
			HealthBar = createLine(2),
			HealthBarOutline = createLine(4),
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

		for _ = 1, 13 do
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
		set.HealthBar.Visible = false
		set.HealthBarOutline.Visible = false

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
		set.HealthBar:Remove()
		set.HealthBarOutline:Remove()
	end

	local function clearESP()
		for userId, set in pairs(espObjects) do
			removeObjectSet(set)
			espObjects[userId] = nil
		end
	end

	local function worldToScreen(position)
		local viewportPoint, onScreen = Camera:WorldToViewportPoint(position)
		return Vector2.new(viewportPoint.X, viewportPoint.Y), onScreen, viewportPoint.Z
	end

	local function getScreenBounds(character)
		local minX, minY = math.huge, math.huge
		local maxX, maxY = -math.huge, -math.huge
		local pointCount = 0

		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") then
				local screenPos, onScreen, depth = worldToScreen(descendant.Position)
				if onScreen and depth > 0 then
					minX = math.min(minX, screenPos.X)
					minY = math.min(minY, screenPos.Y)
					maxX = math.max(maxX, screenPos.X)
					maxY = math.max(maxY, screenPos.Y)
					pointCount = pointCount + 1
				end
			end
		end

		if pointCount == 0 then
			return nil
		end

		local width = maxX - minX
		local height = maxY - minY
		if width < 2 or height < 2 then
			return nil
		end

		return {
			MinX = minX,
			MinY = minY,
			MaxX = maxX,
			MaxY = maxY,
			Width = width,
			Height = height,
			CenterX = (minX + maxX) * 0.5
		}
	end

	local function getSkeletonPairs(character)
		local head = getFirstPart(character, { "Head" })
		local upperTorso = getFirstPart(character, { "UpperTorso", "Torso" })
		local lowerTorso = getFirstPart(character, { "LowerTorso", "Torso" })

		local leftUpperArm = getFirstPart(character, { "LeftUpperArm", "Left Arm" })
		local leftLowerArm = getFirstPart(character, { "LeftLowerArm" })
		local leftHand = getFirstPart(character, { "LeftHand" })

		local rightUpperArm = getFirstPart(character, { "RightUpperArm", "Right Arm" })
		local rightLowerArm = getFirstPart(character, { "RightLowerArm" })
		local rightHand = getFirstPart(character, { "RightHand" })

		local leftUpperLeg = getFirstPart(character, { "LeftUpperLeg", "Left Leg" })
		local leftLowerLeg = getFirstPart(character, { "LeftLowerLeg" })
		local leftFoot = getFirstPart(character, { "LeftFoot" })

		local rightUpperLeg = getFirstPart(character, { "RightUpperLeg", "Right Leg" })
		local rightLowerLeg = getFirstPart(character, { "RightLowerLeg" })
		local rightFoot = getFirstPart(character, { "RightFoot" })

		local pelvis = lowerTorso or upperTorso

		return {
			{ head, upperTorso },
			{ upperTorso, lowerTorso },
			{ upperTorso, leftUpperArm },
			{ leftUpperArm, leftLowerArm or leftHand },
			{ leftLowerArm, leftHand },
			{ upperTorso, rightUpperArm },
			{ rightUpperArm, rightLowerArm or rightHand },
			{ rightLowerArm, rightHand },
			{ pelvis, leftUpperLeg },
			{ leftUpperLeg, leftLowerLeg or leftFoot },
			{ leftLowerLeg, leftFoot },
			{ pelvis, rightUpperLeg },
			{ rightUpperLeg, rightLowerLeg or rightFoot },
			{ rightLowerLeg, rightFoot }
		}
	end

	local function updateSkeleton(set, character)
		local pairsToDraw = getSkeletonPairs(character)
		for index, line in ipairs(set.SkeletonLines) do
			local pair = pairsToDraw[index]
			if pair and pair[1] and pair[2] then
				local fromPos, fromOnScreen, fromDepth = worldToScreen(pair[1].Position)
				local toPos, toOnScreen, toDepth = worldToScreen(pair[2].Position)
				if fromOnScreen and toOnScreen and fromDepth > 0 and toDepth > 0 then
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
			if player ~= LocalPlayer and hasAliveHumanoid(player) and not sameTeam(player) then
				local character = player.Character
				local humanoid = getHumanoid(player)
				if character and humanoid then
					local bounds = getScreenBounds(character)
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

						local maxHealth = math.max(humanoid.MaxHealth, 1)
						local healthRatio = math.clamp(humanoid.Health / maxHealth, 0, 1)
						local healthTopY = bounds.MaxY - (bounds.Height * healthRatio)
						local healthX = bounds.MaxX + 6

						set.HealthBarOutline.From = Vector2.new(healthX, bounds.MinY)
						set.HealthBarOutline.To = Vector2.new(healthX, bounds.MaxY)
						set.HealthBarOutline.Color = Color3.new(0, 0, 0)
						set.HealthBarOutline.Visible = true

						set.HealthBar.From = Vector2.new(healthX, bounds.MaxY)
						set.HealthBar.To = Vector2.new(healthX, healthTopY)
						set.HealthBar.Color = espColor
						set.HealthBar.Visible = true

						updateSkeleton(set, character)
					else
						local set = espObjects[player.UserId]
						if set then
							hideObjectSet(set)
						end
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
			while task.wait(0.03) do
				updateESP()
			end
		end)
	end

	return VisualTab
end

return VisualTabModule