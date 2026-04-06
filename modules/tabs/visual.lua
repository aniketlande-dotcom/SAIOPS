local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local CUSTOM_PLACE_ID = 292439477

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

local MAX_SKELETON_LINES = math.max(#R6_CONNECTIONS, #R15_CONNECTIONS, 15) -- 15 bones for custom Phantom Forces skeleton

function VisualTabModule:Build(Window, Rayfield, Shared)
	local VisualTab = Window:CreateTab("Visual", "eye")
	local isCustomMode = game.PlaceId == CUSTOM_PLACE_ID

	local espEnabled = false
	local teamCheckEnabled = true
	local espUpdateThreadRunning = false

	local showBox = true
	local showSkeleton = true
	local showName = true
	local showHealthBar = true
	local showHeadCircle = true

	local distanceEffectsEnabled = true
	local visibilityCheckEnabled = true
	local visibleColorOverrideEnabled = false
	local skeletonSmoothingEnabled = false
	local skeletonSmoothingAlpha = 0.35
	local maxRenderDistance = 1200
	local visibilityUpdateInterval = 0.12
	local updateInterval = 1 / 90
	local showDistanceInName = true
	local nameTextSize = 13
	local lastUpdateTime = 0

	local boxColor = Color3.fromRGB(255, 0, 0)
	local skeletonColor = Color3.fromRGB(255, 255, 255)
	local nameColor = Color3.fromRGB(255, 255, 255)
	local headColor = Color3.fromRGB(255, 230, 120)
	local visibleBoxColor = Color3.fromRGB(0, 255, 120)
	local visibleSkeletonColor = Color3.fromRGB(0, 255, 120)

	local drawingAvailable = type(Drawing) == "table" and type(Drawing.new) == "function"
	local espObjects = {}
	local visibilityCache = {}
	local customModelCache = {}
	local customCacheTtl = 0.08

	local function sameTeam(player)
		if not teamCheckEnabled then
			return false
		end

		if LocalPlayer.Team and player.Team then
			return LocalPlayer.Team == player.Team
		end

		if LocalPlayer.TeamColor and player.TeamColor then
			return tostring(LocalPlayer.TeamColor) == tostring(player.TeamColor)
		end

		return false
	end

	local function getHumanoid(player)
		local character = player.Character
		if not character then
			return nil
		end

		return character:FindFirstChildOfClass("Humanoid")
	end

	local function getRootPart(player)
		local character = player.Character
		if not character then
			return nil
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root
		end

		return nil
	end

	local function getFirstMeshPartRecursive(root)
		if not root then
			return nil
		end

		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("MeshPart") then
				return child
			end

			local found = getFirstMeshPartRecursive(child)
			if found then
				return found
			end
		end

		return nil
	end

	local function getModelPlayerFromTag(model)
		local tagGui = model:FindFirstChild("NameTagGui", true)
		if not tagGui then
			return nil
		end

		local playerTag = tagGui:FindFirstChild("PlayerTag")
		if not playerTag or not playerTag:IsA("TextLabel") then
			return nil
		end

		local name = playerTag.Text
		if type(name) ~= "string" or name == "" then
			return nil
		end

		return Players:FindFirstChild(name)
	end

	local function shouldRenderCustomModel(model)
		return model and model.Parent ~= nil
	end

	local function getCustomCharacterModels()
		local playersFolder = workspace:FindFirstChild("Players")
		if not playersFolder then
			return {}
		end

		local topChildren = playersFolder:GetChildren()
		local enemyFolder = topChildren[1]
		if not enemyFolder then
			return {}
		end

		local models = {}
		for _, model in ipairs(enemyFolder:GetChildren()) do
			if model:IsA("Model") or model:IsA("Folder") then
				table.insert(models, model)
			end
		end

		return models
	end

	local function getModelTagGui(model)
		return model:FindFirstChild("NameTagGui", true)
	end

	local function getCustomDisplayName(model)
		local tagGui = getModelTagGui(model)
		if not tagGui then
			return nil
		end

		local playerTag = tagGui:FindFirstChild("PlayerTag")
		if not playerTag or not playerTag:IsA("TextLabel") then
			return nil
		end

		local tagText = playerTag.Text
		if type(tagText) ~= "string" or tagText == "" then
			return nil
		end

		local mapped = Players:FindFirstChild(tagText)
		if mapped then
			return mapped.DisplayName or mapped.Name or tagText
		end

		return tagText
	end

	local function getCustomHealthRatio(model)
		local mapped = getModelPlayerFromTag(model)
		if mapped and mapped.Character then
			local humanoid = mapped.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.MaxHealth > 0 then
				return math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
			end
		end

		local tagGui = getModelTagGui(model)
		if tagGui then
			local healthFrame = tagGui:FindFirstChild("Health")
			local percent = healthFrame and healthFrame:FindFirstChild("Percent")
			if percent and percent:IsA("Frame") then
				local ratio = percent.Size.X.Scale
				if type(ratio) == "number" then
					return math.clamp(ratio, 0, 1)
				end
			end
		end

		return nil
	end

	local function getMeshParts(model, maxCount)
		local container = model
		local bestDirectMeshCount = 0

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("Folder") or child:IsA("Model") then
				local directCount = 0
				for _, nested in ipairs(child:GetChildren()) do
					if nested:IsA("MeshPart") then
						directCount = directCount + 1
					end
				end

				if directCount > bestDirectMeshCount then
					bestDirectMeshCount = directCount
					container = child
				end
			end
		end

		local parts = {}
		for _, d in ipairs(container:GetDescendants()) do
			if d:IsA("MeshPart") then
				table.insert(parts, d)
				if #parts >= (maxCount or 24) then
					break
				end
			end
		end
		return parts
	end

	local function getCustomModelData(model)
		local now = os.clock()
		local cached = customModelCache[model]
		if cached and (now - cached.Time) <= customCacheTtl and model.Parent then
			return cached
		end

		local parts = getMeshParts(model, 40)
		if #parts == 0 then
			customModelCache[model] = nil
			return nil
		end

		local anchors = {}
		for _, ch in ipairs(model:GetChildren()) do
			if ch:IsA("BasePart") then
				table.insert(anchors, ch)
			end
		end

		local head, feet = parts[1], parts[1]
		local minY, maxY = parts[1].Position.Y, parts[1].Position.Y
		local sum = Vector3.new(0, 0, 0)

		for _, p in ipairs(parts) do
			sum = sum + p.Position
			if p.Position.Y > head.Position.Y then
				head = p
			end
			if p.Position.Y < feet.Position.Y then
				feet = p
			end
			if p.Position.Y < minY then
				minY = p.Position.Y
			end
			if p.Position.Y > maxY then
				maxY = p.Position.Y
			end
		end

		local centerPos = sum / #parts
		local centerPart = parts[1]
		local bestDist = (parts[1].Position - centerPos).Magnitude
		for i = 2, #parts do
			local dist = (parts[i].Position - centerPos).Magnitude
			if dist < bestDist then
				bestDist = dist
				centerPart = parts[i]
			end
		end

		local data = {
			Time = now,
			Head = head,
			Feet = feet,
			MinY = minY,
			MaxY = maxY,
			Parts = parts,
			Anchors = anchors,
			CenterPos = centerPos,
			CenterPart = centerPart
		}
		customModelCache[model] = data
		return data
	end

	local function getCustomSkeletonPoints(model, trackingPart)
		local data = getCustomModelData(model)
		if not data then
			return nil
		end

		return {
			Head = data.Head,
			Center = trackingPart or data.Head,
			Feet = data.Feet
		}
	end

	local worldToScreen

	local function updateCustomSkeleton(set, model, trackingPart, bounds, alpha, thickness, lineColor)
		if not showSkeleton then
			for i, line in ipairs(set.SkeletonLines) do
				line.Visible = false
				set.SkeletonState[i] = nil
			end
			return
		end

		local data = getCustomModelData(model)
		if not data or not data.Anchors or #data.Anchors < 3 then
			for i, line in ipairs(set.SkeletonLines) do
				line.Visible = false
				set.SkeletonState[i] = nil
			end
			return
		end

		local projectedAnchors = {}
		for _, part in ipairs(data.Anchors) do
			local screenPos, onScreen, depth = worldToScreen(part.Position)
			if screenPos and onScreen and depth > 0 then
				table.insert(projectedAnchors, {
					Part = part,
					Pos = screenPos,
					X = screenPos.X,
					Y = screenPos.Y,
					WorldY = part.Position.Y
				})
			end
		end

		if #projectedAnchors < 3 then
			for i, line in ipairs(set.SkeletonLines) do
				line.Visible = false
				set.SkeletonState[i] = nil
			end
			return
		end

		table.sort(projectedAnchors, function(a, b)
			return a.WorldY > b.WorldY
		end)

		local center = data.CenterPos
		local centerX = bounds.CenterX

		local head = projectedAnchors[1]

		table.sort(projectedAnchors, function(a, b)
			return a.WorldY < b.WorldY
		end)
		local lowA = projectedAnchors[1]
		local lowB = projectedAnchors[math.min(2, #projectedAnchors)]

		if lowA and lowB and lowA.X > lowB.X then
			lowA, lowB = lowB, lowA
		end

		local torso = nil
		for _, p in ipairs(projectedAnchors) do
			if p ~= lowA and p ~= lowB and p ~= head then
				local worldPos = p.Part.Position
				local dist = (worldPos - center).Magnitude
				if not torso or dist < torso.Dist then
					torso = { Pos = p.Pos, Dist = dist }
				end
			end
		end

		local torsoPos = torso and torso.Pos or Vector2.new(centerX, bounds.MinY + (bounds.Height * 0.45))
		local headPos = head and head.Pos or Vector2.new(centerX, bounds.MinY + (bounds.Height * 0.12))

		local leftArm, rightArm = nil, nil
		for _, p in ipairs(projectedAnchors) do
			if p ~= head and p ~= lowA and p ~= lowB then
				if p.X < centerX then
					if not leftArm or p.X < leftArm.X then
						leftArm = p
					end
				else
					if not rightArm or p.X > rightArm.X then
						rightArm = p
					end
				end
			end
		end

		local leftArmPos = leftArm and leftArm.Pos or Vector2.new(bounds.MinX + bounds.Width * 0.2, bounds.MinY + bounds.Height * 0.45)
		local rightArmPos = rightArm and rightArm.Pos or Vector2.new(bounds.MaxX - bounds.Width * 0.2, bounds.MinY + bounds.Height * 0.45)
		local leftLegPos = lowA and lowA.Pos or Vector2.new(bounds.MinX + bounds.Width * 0.35, bounds.MaxY)
		local rightLegPos = lowB and lowB.Pos or Vector2.new(bounds.MaxX - bounds.Width * 0.35, bounds.MaxY)

		local pairsList = {
			{ headPos, torsoPos },
			{ torsoPos, leftArmPos },
			{ torsoPos, rightArmPos },
			{ torsoPos, leftLegPos },
			{ torsoPos, rightLegPos }
		}

		for i, line in ipairs(set.SkeletonLines) do
			local pair = pairsList[i]
			if not pair then
				line.Visible = false
				set.SkeletonState[i] = nil
			else
				local drawFrom = pair[1]
				local drawTo = pair[2]

				if skeletonSmoothingEnabled then
					local state = set.SkeletonState[i]
					if not state then
						state = { From = drawFrom, To = drawTo }
						set.SkeletonState[i] = state
					end

					state.From = state.From:Lerp(drawFrom, skeletonSmoothingAlpha)
					state.To = state.To:Lerp(drawTo, skeletonSmoothingAlpha)
					drawFrom = state.From
					drawTo = state.To
				else
					set.SkeletonState[i] = nil
				end

				line.From = drawFrom
				line.To = drawTo
				line.Color = lineColor
				line.Transparency = alpha
				line.Thickness = math.max(1, thickness)
				line.Visible = true
			end
		end
	end

	local function updateCustomHeadCircle(set, model, trackingPart, bounds, alpha, thickness)
		if not showHeadCircle then
			set.HeadCircle.Visible = false
			set.HeadCircleOutline.Visible = false
			return
		end

		local data = getCustomModelData(model)
		local headPart = data and data.Head
		local center = nil
		if headPart then
			local projected, onScreen, depth = worldToScreen(headPart.Position)
			if projected and onScreen and depth > 0 then
				center = projected
			end
		end

		if not center then
			center = Vector2.new(bounds.CenterX, bounds.MinY + (bounds.Height * 0.15))
		end
		local radius = math.clamp(bounds.Width * 0.18, 4, 32)

		set.HeadCircleOutline.Position = center
		set.HeadCircleOutline.Radius = radius
		set.HeadCircleOutline.Transparency = alpha
		set.HeadCircleOutline.Visible = true

		set.HeadCircle.Position = center
		set.HeadCircle.Radius = radius
		set.HeadCircle.Thickness = math.max(1, thickness)
		set.HeadCircle.Transparency = math.clamp(alpha * 0.55, 0.2, 0.95)
		set.HeadCircle.Color = headColor
		set.HeadCircle.Visible = true
	end

	worldToScreen = function(position)
		local camera = workspace.CurrentCamera
		if not camera then
			return nil, false, -1
		end

		local viewportPoint, onScreen = camera:WorldToViewportPoint(position)
		return Vector2.new(viewportPoint.X, viewportPoint.Y), onScreen, viewportPoint.Z
	end

	local function isVisible(targetCharacter, targetPart)
		if not visibilityCheckEnabled then
			return true
		end

		local localCharacter = LocalPlayer.Character
		if not localCharacter then
			return false
		end

		local camera = workspace.CurrentCamera
		if not camera then
			return false
		end

		local origin = camera.CFrame.Position
		local direction = targetPart.Position - origin

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = { localCharacter, targetCharacter }

		local result = workspace:Raycast(origin, direction, params)
		return result == nil
	end

	local function createLine(thickness)
		local line = Drawing.new("Line")
		line.Visible = false
		line.Thickness = thickness or 1
		line.Transparency = 1
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
			HeadCircle = Drawing.new("Circle"),
			HeadCircleOutline = Drawing.new("Circle"),
			SkeletonLines = {},
			SkeletonState = {}
		}

		set.Box.Visible = false
		set.Box.Filled = false
		set.Box.Thickness = 1.5
		set.Box.Transparency = 1
		set.Box.Color = Color3.new(1, 0, 0) -- Initialize to red, will be overridden

		set.BoxOutline.Visible = false
		set.BoxOutline.Filled = false
		set.BoxOutline.Thickness = 3
		set.BoxOutline.Transparency = 1
		set.BoxOutline.Color = Color3.new(0, 0, 0)

		set.Name.Visible = false
		set.Name.Size = nameTextSize
		set.Name.Center = true
		set.Name.Outline = true
		set.Name.Font = 2
		set.Name.Transparency = 1

		set.HealthBackground.Visible = false
		set.HealthBackground.Filled = true
		set.HealthBackground.Thickness = 1
		set.HealthBackground.Transparency = 0.7
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

		set.HeadCircle.Visible = false
		set.HeadCircle.Filled = true
		set.HeadCircle.NumSides = 24
		set.HeadCircle.Thickness = 1
		set.HeadCircle.Transparency = 0.5

		set.HeadCircleOutline.Visible = false
		set.HeadCircleOutline.Filled = false
		set.HeadCircleOutline.NumSides = 24
		set.HeadCircleOutline.Thickness = 3
		set.HeadCircleOutline.Transparency = 1
		set.HeadCircleOutline.Color = Color3.new(0, 0, 0)

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
		set.HeadCircle.Visible = false
		set.HeadCircleOutline.Visible = false

		for lineIndex, line in ipairs(set.SkeletonLines) do
			line.Visible = false
			set.SkeletonState[lineIndex] = nil
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
		set.HeadCircle:Remove()
		set.HeadCircleOutline:Remove()
	end

	local function clearESP()
		for userId, set in pairs(espObjects) do
			removeObjectSet(set)
			espObjects[userId] = nil
			visibilityCache[userId] = nil
		end
	end

	local function getVisibilityCached(userId, targetCharacter, targetPart, now)
		if not visibilityCheckEnabled then
			return true
		end

		local cached = visibilityCache[userId]
		if cached and (now - cached.Time) <= visibilityUpdateInterval then
			return cached.Value
		end

		local value = isVisible(targetCharacter, targetPart)
		visibilityCache[userId] = {
			Value = value,
			Time = now
		}

		return value
	end

	local function getRigConnections(humanoid)
		if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
			return R6_CONNECTIONS
		end

		return R15_CONNECTIONS
	end

	local function getDistanceStyle(distance)
		if not distanceEffectsEnabled then
			return 1, 2
		end

		local nearDistance = 20
		local farDistance = 260
		local t = math.clamp((distance - nearDistance) / (farDistance - nearDistance), 0, 1)

		local alpha = math.clamp(1 - (t * 0.75), 0.25, 1)
		local thickness = math.clamp(2.2 - (t * 1.2), 1, 2.2)
		return alpha, thickness
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
		local width = math.clamp(height * widthScale, 4, 140)
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

	local function getBoxBoundsFromPart(model, targetPart)
		if not model or not targetPart or not targetPart:IsA("BasePart") then
			return nil
		end

		local data = getCustomModelData(model)
		if not data or not data.Parts then
			return nil
		end

		local minX, minY = math.huge, math.huge
		local maxX, maxY = -math.huge, -math.huge
		local visibleCount = 0

		for _, part in ipairs(data.Parts) do
			local screenPos, onScreen, depth = worldToScreen(part.Position)
			if screenPos and onScreen and depth > 0 then
				visibleCount = visibleCount + 1
				if screenPos.X < minX then minX = screenPos.X end
				if screenPos.X > maxX then maxX = screenPos.X end
				if screenPos.Y < minY then minY = screenPos.Y end
				if screenPos.Y > maxY then maxY = screenPos.Y end
			end
		end

		if visibleCount < 4 then
			return nil
		end

		local height = maxY - minY
		if height < 8 then
			return nil
		end

		local width = maxX - minX
		local minAllowed = height * 0.2
		local maxAllowed = height * 0.72
		width = math.clamp(width, minAllowed, maxAllowed)

		local centerX = (minX + maxX) * 0.5
		minX = centerX - (width * 0.5)
		maxX = centerX + (width * 0.5)

		return {
			MinX = minX,
			MinY = minY,
			MaxX = maxX,
			MaxY = maxY,
			Width = width,
			Height = height,
			CenterX = centerX
		}
	end

	local function getHealthColor(ratio)
		local red = math.floor(255 * (1 - ratio))
		local green = math.floor(255 * ratio)
		return Color3.fromRGB(red, green, 40)
	end

	local function updateHealthBar(set, bounds, humanoid, alpha)
		if not showHealthBar then
			set.HealthBackground.Visible = false
			set.HealthFill.Visible = false
			set.HealthOutline.Visible = false
			return
		end

		local maxHealth = math.max(humanoid.MaxHealth, 1)
		local ratio = math.clamp(humanoid.Health / maxHealth, 0, 1)

		local barWidth = 4
		local barX = bounds.MaxX + 5
		local barY = bounds.MinY
		local barHeight = bounds.Height
		local fillHeight = math.max(1, math.floor(barHeight * ratio))

		set.HealthBackground.Position = Vector2.new(barX, barY)
		set.HealthBackground.Size = Vector2.new(barWidth, barHeight)
		set.HealthBackground.Transparency = math.clamp(alpha * 0.6, 0.2, 1)
		set.HealthBackground.Visible = true

		set.HealthFill.Position = Vector2.new(barX, barY + (barHeight - fillHeight))
		set.HealthFill.Size = Vector2.new(barWidth, fillHeight)
		set.HealthFill.Color = getHealthColor(ratio)
		set.HealthFill.Transparency = alpha
		set.HealthFill.Visible = true

		set.HealthOutline.Position = Vector2.new(barX - 1, barY - 1)
		set.HealthOutline.Size = Vector2.new(barWidth + 2, barHeight + 2)
		set.HealthOutline.Transparency = alpha
		set.HealthOutline.Visible = true
	end

	local function updateHeadCircle(set, character, bounds, alpha, thickness)
		if not showHeadCircle then
			set.HeadCircle.Visible = false
			set.HeadCircleOutline.Visible = false
			return
		end

		local head = character:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") then
			set.HeadCircle.Visible = false
			set.HeadCircleOutline.Visible = false
			return
		end

		local center, centerOnScreen, centerDepth = worldToScreen(head.Position)
		if not center or not centerOnScreen or centerDepth <= 0 then
			set.HeadCircle.Visible = false
			set.HeadCircleOutline.Visible = false
			return
		end

		local camera = workspace.CurrentCamera
		local rightOffset = camera and (camera.CFrame.RightVector * (head.Size.X * 0.5)) or Vector3.new(0.5, 0, 0)
		local edge, edgeOnScreen, edgeDepth = worldToScreen(head.Position + rightOffset)
		local radius = bounds.Width * 0.18
		if edge and edgeOnScreen and edgeDepth > 0 then
			radius = (edge - center).Magnitude
		end

		radius = math.clamp(radius, 4, 35)

		set.HeadCircleOutline.Position = center
		set.HeadCircleOutline.Radius = radius
		set.HeadCircleOutline.Transparency = alpha
		set.HeadCircleOutline.Visible = true

		set.HeadCircle.Position = center
		set.HeadCircle.Radius = radius
		set.HeadCircle.Thickness = math.max(1, thickness)
		set.HeadCircle.Transparency = math.clamp(alpha * 0.55, 0.2, 0.95)
		set.HeadCircle.Color = headColor
		set.HeadCircle.Visible = true
	end

	local function updateSkeleton(set, character, humanoid, alpha, thickness, lineColor)
		if not showSkeleton then
			for lineIndex, line in ipairs(set.SkeletonLines) do
				line.Visible = false
				set.SkeletonState[lineIndex] = nil
			end
			return
		end

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
				set.SkeletonState[lineIndex] = nil
			else
				local partA = partCache[pair[1]]
				local partB = partCache[pair[2]]

				if partA and partB then
					local fromPos, fromOnScreen, fromDepth = worldToScreen(partA.Position)
					local toPos, toOnScreen, toDepth = worldToScreen(partB.Position)

					if fromPos and toPos and fromOnScreen and toOnScreen and fromDepth > 0 and toDepth > 0 then
						local drawFrom = fromPos
						local drawTo = toPos

						if skeletonSmoothingEnabled then
							local state = set.SkeletonState[lineIndex]
							if not state then
								state = { From = fromPos, To = toPos }
								set.SkeletonState[lineIndex] = state
							end

							state.From = state.From:Lerp(fromPos, skeletonSmoothingAlpha)
							state.To = state.To:Lerp(toPos, skeletonSmoothingAlpha)
							drawFrom = state.From
							drawTo = state.To
						else
							set.SkeletonState[lineIndex] = nil
						end

						line.From = drawFrom
						line.To = drawTo
						line.Color = lineColor
						line.Transparency = alpha
						line.Thickness = math.max(1, thickness)
						line.Visible = true
					else
						line.Visible = false
						set.SkeletonState[lineIndex] = nil
					end
				else
					line.Visible = false
					set.SkeletonState[lineIndex] = nil
				end
			end
		end
	end

	local function updateESP()
		if not drawingAvailable then
			return
		end

		local now = os.clock()
		local effectiveInterval = updateInterval
		if isCustomMode then
			effectiveInterval = math.max(updateInterval, 1 / 45)
		end

		if (now - lastUpdateTime) < effectiveInterval then
			return
		end
		lastUpdateTime = now

		if not espEnabled then
			for _, set in pairs(espObjects) do
				hideObjectSet(set)
			end
			return
		end

		if isCustomMode then
			local active = {}
			local myRoot = getRootPart(LocalPlayer)

			for _, enemyModel in ipairs(getCustomCharacterModels()) do
				if shouldRenderCustomModel(enemyModel) then
					local modelData = getCustomModelData(enemyModel)
					local trackingPart = modelData and (modelData.CenterPart or modelData.Head) or getFirstMeshPartRecursive(enemyModel)
					if trackingPart then
					local distance = myRoot and (myRoot.Position - trackingPart.Position).Magnitude or 0
					if distance <= maxRenderDistance then
						local bounds = getBoxBoundsFromPart(enemyModel, trackingPart)
						if bounds then
							active[enemyModel] = true

							local set = espObjects[enemyModel]
							if not set then
								set = createObjectSet()
								espObjects[enemyModel] = set
							end

							local alpha, thickness = getDistanceStyle(distance)
							local targetVisible = getVisibilityCached(enemyModel, enemyModel, trackingPart, now)
							local currentBoxColor = boxColor
							local currentSkeletonColor = skeletonColor
							if visibleColorOverrideEnabled and targetVisible then
								currentBoxColor = visibleBoxColor
								currentSkeletonColor = visibleSkeletonColor
							end

							if showBox then
								set.BoxOutline.Position = Vector2.new(bounds.MinX, bounds.MinY)
								set.BoxOutline.Size = Vector2.new(bounds.Width, bounds.Height)
								set.BoxOutline.Transparency = alpha
								set.BoxOutline.Visible = true

								set.Box.Position = Vector2.new(bounds.MinX, bounds.MinY)
								set.Box.Size = Vector2.new(bounds.Width, bounds.Height)
								set.Box.Color = currentBoxColor
								set.Box.Thickness = math.max(1.2, thickness)
								set.Box.Transparency = alpha
								set.Box.Visible = true
							else
								set.Box.Visible = false
								set.BoxOutline.Visible = false
							end

							if showName then
								local displayName = getCustomDisplayName(enemyModel)
								if not displayName then
									set.Name.Visible = false
								else
								if showDistanceInName then
									set.Name.Text = string.format("%s [%.0fm]", displayName, distance)
								else
									set.Name.Text = displayName
								end
								set.Name.Position = Vector2.new(bounds.CenterX, bounds.MinY - 16)
								set.Name.Size = nameTextSize
								set.Name.Color = nameColor
								set.Name.Transparency = alpha
								set.Name.Visible = true
								end
							else
								set.Name.Visible = false
							end

							local healthRatio = getCustomHealthRatio(enemyModel)
							if showHealthBar and healthRatio then
								local barWidth = 4
								local barX = bounds.MinX - 7
								local barY = bounds.MinY
								local barHeight = bounds.Height
								local fillHeight = math.max(1, math.floor(barHeight * healthRatio))

								set.HealthBackground.Position = Vector2.new(barX, barY)
								set.HealthBackground.Size = Vector2.new(barWidth, barHeight)
								set.HealthBackground.Transparency = math.clamp(alpha * 0.6, 0.2, 1)
								set.HealthBackground.Visible = true

								set.HealthFill.Position = Vector2.new(barX, barY + (barHeight - fillHeight))
								set.HealthFill.Size = Vector2.new(barWidth, fillHeight)
								set.HealthFill.Color = getHealthColor(healthRatio)
								set.HealthFill.Transparency = alpha
								set.HealthFill.Visible = true

								set.HealthOutline.Position = Vector2.new(barX - 1, barY - 1)
								set.HealthOutline.Size = Vector2.new(barWidth + 2, barHeight + 2)
								set.HealthOutline.Transparency = alpha
								set.HealthOutline.Visible = true
							else
								set.HealthBackground.Visible = false
								set.HealthFill.Visible = false
								set.HealthOutline.Visible = false
							end

							updateCustomSkeleton(set, enemyModel, trackingPart, bounds, alpha, thickness, currentSkeletonColor)
							updateCustomHeadCircle(set, enemyModel, trackingPart, bounds, alpha, thickness)
						else
							local set = espObjects[enemyModel]
							if set then
								hideObjectSet(set)
							end
							visibilityCache[enemyModel] = nil
						end
					else
						local set = espObjects[enemyModel]
						if set then
							hideObjectSet(set)
						end
						visibilityCache[enemyModel] = nil
					end
				else
					local set = espObjects[enemyModel]
					if set then
						hideObjectSet(set)
					end
					visibilityCache[enemyModel] = nil
				end
			end
			end

			for key, set in pairs(espObjects) do
				if not active[key] then
					hideObjectSet(set)
					visibilityCache[key] = nil
				end
			end

			return
		end

		local active = {}
		local myRoot = getRootPart(LocalPlayer)

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not sameTeam(player) then
				local character = player.Character
				local humanoid = getHumanoid(player)
				local root = getRootPart(player)

				if character and humanoid and root and humanoid.Health > 0 then
					local distance = myRoot and (myRoot.Position - root.Position).Magnitude or 0
					if distance > maxRenderDistance then
						local set = espObjects[player.UserId]
						if set then
							hideObjectSet(set)
						end
						visibilityCache[player.UserId] = nil
					else
						local bounds = getBoxBounds(character, humanoid)
						if bounds then
							active[player.UserId] = true

							local set = espObjects[player.UserId]
							if not set then
								set = createObjectSet()
								espObjects[player.UserId] = set
							end

							local alpha, thickness = getDistanceStyle(distance)

							local visibilityPart = character:FindFirstChild("Head") or root
							local targetVisible = visibilityPart and getVisibilityCached(player.UserId, character, visibilityPart, now) or false

							local currentBoxColor = boxColor
							local currentSkeletonColor = skeletonColor
							if visibleColorOverrideEnabled and targetVisible then
								currentBoxColor = visibleBoxColor
								currentSkeletonColor = visibleSkeletonColor
							end

							if showBox then
								set.BoxOutline.Position = Vector2.new(bounds.MinX, bounds.MinY)
								set.BoxOutline.Size = Vector2.new(bounds.Width, bounds.Height)
								set.BoxOutline.Transparency = alpha
								set.BoxOutline.Visible = true

								set.Box.Position = Vector2.new(bounds.MinX, bounds.MinY)
								set.Box.Size = Vector2.new(bounds.Width, bounds.Height)
								set.Box.Color = currentBoxColor
								set.Box.Thickness = math.max(1, thickness)
								set.Box.Transparency = alpha
								set.Box.Visible = true
							else
								set.Box.Visible = false
								set.BoxOutline.Visible = false
							end

							if showName then
								if showDistanceInName then
									set.Name.Text = string.format("%s [%.0fm]", player.Name, distance)
								else
									set.Name.Text = player.Name
								end
								set.Name.Position = Vector2.new(bounds.CenterX, bounds.MinY - 16)
								set.Name.Size = nameTextSize
								set.Name.Color = nameColor
								set.Name.Transparency = alpha
								set.Name.Visible = true
							else
								set.Name.Visible = false
							end

							updateHealthBar(set, bounds, humanoid, alpha)
							updateSkeleton(set, character, humanoid, alpha, thickness, currentSkeletonColor)
							updateHeadCircle(set, character, bounds, alpha, thickness)
						else
							local set = espObjects[player.UserId]
							if set then
								hideObjectSet(set)
							end
							visibilityCache[player.UserId] = nil
						end
					end
				else
					local set = espObjects[player.UserId]
					if set then
						hideObjectSet(set)
					end
					visibilityCache[player.UserId] = nil
				end
			else
				local set = espObjects[player.UserId]
				if set then
					hideObjectSet(set)
				end
				visibilityCache[player.UserId] = nil
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

	if isCustomMode then
		Shared:Notify(Rayfield, "ESP", "Custom ESP mode detected for this game")
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

	VisualTab:CreateToggle({
		Name = "Visibility Check",
		CurrentValue = true,
		Flag = "esp_visibility_check",
		Callback = function(value)
			visibilityCheckEnabled = value
			if not value then
				visibilityCache = {}
			end
			updateESP()
		end
	})

	VisualTab:CreateSection("ESP Clarity")

	VisualTab:CreateToggle({
		Name = "Show Distance In Name",
		CurrentValue = true,
		Flag = "esp_show_distance_name",
		Callback = function(value)
			showDistanceInName = value
			updateESP()
		end
	})

	VisualTab:CreateSlider({
		Name = "Name Text Size",
		Range = { 10, 20 },
		Increment = 1,
		Suffix = "px",
		CurrentValue = 13,
		Flag = "esp_name_text_size",
		Callback = function(value)
			nameTextSize = value
			updateESP()
		end
	})

	VisualTab:CreateSection("ESP Elements")

	VisualTab:CreateToggle({
		Name = "Show Box",
		CurrentValue = true,
		Flag = "esp_show_box",
		Callback = function(value)
			showBox = value
			updateESP()
		end
	})

	VisualTab:CreateToggle({
		Name = "Show Skeleton",
		CurrentValue = true,
		Flag = "esp_show_skeleton",
		Callback = function(value)
			showSkeleton = value
			updateESP()
		end
	})

	VisualTab:CreateToggle({
		Name = "Show Name",
		CurrentValue = true,
		Flag = "esp_show_name",
		Callback = function(value)
			showName = value
			updateESP()
		end
	})

	VisualTab:CreateToggle({
		Name = "Show Health Bar",
		CurrentValue = true,
		Flag = "esp_show_health",
		Callback = function(value)
			showHealthBar = value
			updateESP()
		end
	})

	VisualTab:CreateToggle({
		Name = "Show Head Circle",
		CurrentValue = true,
		Flag = "esp_show_head_circle",
		Callback = function(value)
			showHeadCircle = value
			updateESP()
		end
	})

	VisualTab:CreateSection("ESP Colors")

	VisualTab:CreateColorPicker({
		Name = "Box Color",
		Color = boxColor,
		Flag = "esp_box_color",
		Callback = function(value)
			boxColor = value
			updateESP()
		end
	})

	VisualTab:CreateColorPicker({
		Name = "Skeleton Color",
		Color = skeletonColor,
		Flag = "esp_skeleton_color",
		Callback = function(value)
			skeletonColor = value
			updateESP()
		end
	})

	VisualTab:CreateColorPicker({
		Name = "Name Color",
		Color = nameColor,
		Flag = "esp_name_color",
		Callback = function(value)
			nameColor = value
			updateESP()
		end
	})

	VisualTab:CreateColorPicker({
		Name = "Head Circle Color",
		Color = headColor,
		Flag = "esp_head_color",
		Callback = function(value)
			headColor = value
			updateESP()
		end
	})

	VisualTab:CreateSection("ESP Visibility Colors")

	VisualTab:CreateToggle({
		Name = "Visible Color Override",
		CurrentValue = false,
		Flag = "esp_visible_color_override",
		Callback = function(value)
			visibleColorOverrideEnabled = value
			updateESP()
		end
	})

	VisualTab:CreateColorPicker({
		Name = "Visible Box Color",
		Color = visibleBoxColor,
		Flag = "esp_visible_box_color",
		Callback = function(value)
			visibleBoxColor = value
			updateESP()
		end
	})

	VisualTab:CreateColorPicker({
		Name = "Visible Skeleton Color",
		Color = visibleSkeletonColor,
		Flag = "esp_visible_skeleton_color",
		Callback = function(value)
			visibleSkeletonColor = value
			updateESP()
		end
	})

	VisualTab:CreateSection("ESP Smoothing")

	VisualTab:CreateToggle({
		Name = "Distance Fade and Thickness",
		CurrentValue = true,
		Flag = "esp_distance_style",
		Callback = function(value)
			distanceEffectsEnabled = value
			updateESP()
		end
	})

	VisualTab:CreateToggle({
		Name = "Skeleton Smoothing",
		CurrentValue = false,
		Flag = "esp_skeleton_smoothing",
		Callback = function(value)
			skeletonSmoothingEnabled = value
			if not value then
				for _, set in pairs(espObjects) do
					set.SkeletonState = {}
				end
			end
			updateESP()
		end
	})

	VisualTab:CreateSlider({
		Name = "Skeleton Smoothness",
		Range = { 5, 100 },
		Increment = 5,
		Suffix = "%",
		CurrentValue = 35,
		Flag = "esp_skeleton_smoothness",
		Callback = function(value)
			skeletonSmoothingAlpha = math.clamp(value / 100, 0.05, 1)
		end
	})

	VisualTab:CreateSection("ESP Performance")

	VisualTab:CreateSlider({
		Name = "Max Render Distance",
		Range = { 100, 3000 },
		Increment = 25,
		Suffix = "m",
		CurrentValue = 1200,
		Flag = "esp_max_render_distance",
		Callback = function(value)
			maxRenderDistance = value
			updateESP()
		end
	})

	VisualTab:CreateSlider({
		Name = "ESP Update Rate",
		Range = { 30, 144 },
		Increment = 1,
		Suffix = "fps",
		CurrentValue = 90,
		Flag = "esp_update_rate",
		Callback = function(value)
			updateInterval = 1 / math.max(1, value)
		end
	})

	VisualTab:CreateSlider({
		Name = "Visibility Refresh",
		Range = { 20, 500 },
		Increment = 10,
		Suffix = "ms",
		CurrentValue = 120,
		Flag = "esp_visibility_refresh",
		Callback = function(value)
			visibilityUpdateInterval = math.max(0.02, value / 1000)
			visibilityCache = {}
		end
	})

	if not espUpdateThreadRunning then
		espUpdateThreadRunning = true
		RunService.RenderStepped:Connect(updateESP)
	end

	Players.PlayerRemoving:Connect(function(player)
		local set = espObjects[player.UserId]
		if set then
			removeObjectSet(set)
			espObjects[player.UserId] = nil
		end
		visibilityCache[player.UserId] = nil
	end)

	LocalPlayer.CharacterRemoving:Connect(function()
		clearESP()
	end)

	return VisualTab
end

return VisualTabModule