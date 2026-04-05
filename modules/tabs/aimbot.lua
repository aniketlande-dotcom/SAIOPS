local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local AimbotTabModule = {}

function AimbotTabModule:Build(Window, Rayfield, Shared)
	local AimbotTab = Window:CreateTab("Aimbot", "crosshair")

	local aimbotEnabled = false
	local activationMode = "Toggle"
	local selectedKeyCode = Enum.KeyCode.RightAlt
	local toggleActive = false
	local holdActive = false
	local smoothnessPercent = 70
	local smoothness = 0.04
	local targetPartOption = "Head"
	local fovRadius = 120
	local showFov = false
	local fovColor = Color3.fromRGB(255, 255, 255)
	local teamCheckEnabled = true
	local visibilityCheckEnabled = true

	local fovCircle = nil
	if Drawing and type(Drawing.new) == "function" then
		fovCircle = Drawing.new("Circle")
		fovCircle.Visible = false
		fovCircle.Filled = false
		fovCircle.Thickness = 1.5
		fovCircle.NumSides = 72
		fovCircle.Radius = fovRadius
		fovCircle.Color = fovColor
	end

	local function resolveKeyCode(value)
		if typeof(value) == "EnumItem" then
			return value
		end

		if type(value) == "string" then
			if Enum.KeyCode[value] then
				return Enum.KeyCode[value]
			end
		end

		return nil
	end

	local function updateSmoothnessAlpha()
		local t = math.clamp(smoothnessPercent / 100, 0, 1)
		-- Keep aim movement smooth across the full slider range instead of snapping at lower values.
		smoothness = 0.02 + ((1 - t) ^ 1.35) * 0.12
	end

	updateSmoothnessAlpha()

	local function isTeammate(player)
		if not teamCheckEnabled then
			return false
		end

		if not LocalPlayer.Team or not player.Team then
			return false
		end

		return LocalPlayer.Team == player.Team
	end

	local function getTargetPartFromCharacter(character)
		if targetPartOption == "Body" then
			return character:FindFirstChild("HumanoidRootPart")
				or character:FindFirstChild("UpperTorso")
				or character:FindFirstChild("Torso")
				or character:FindFirstChild("LowerTorso")
				or character:FindFirstChild("Head")
		end

		return character:FindFirstChild(targetPartOption)
	end

	local function isVisible(targetCharacter, targetPart)
		if not visibilityCheckEnabled then
			return true
		end

		local localCharacter = LocalPlayer.Character
		if not localCharacter then
			return false
		end

		local origin = Camera.CFrame.Position
		local direction = targetPart.Position - origin
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = {localCharacter}

		local result = workspace:Raycast(origin, direction, params)
		if not result then
			return true
		end

		return result.Instance and result.Instance:IsDescendantOf(targetCharacter)
	end

	local function getBestTarget()
		local mouseLocation = UserInputService:GetMouseLocation()
		local nearestDistance = math.huge
		local bestPart = nil

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not isTeammate(player) and player.Character then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					local targetPart = getTargetPartFromCharacter(player.Character)
					if targetPart then
						local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
						if onScreen and isVisible(player.Character, targetPart) then
							local distance = (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude
							if distance <= fovRadius and distance < nearestDistance then
								nearestDistance = distance
								bestPart = targetPart
							end
						end
					end
				end
			end
		end

		return bestPart
	end

	AimbotTab:CreateSection("Core")

	AimbotTab:CreateToggle({
		Name = "Enable Aimbot",
		CurrentValue = false,
		Flag = "aimbot_enabled",
		Callback = function(value)
			aimbotEnabled = value
			if not value then
				toggleActive = false
				holdActive = false
			end
			Shared:Notify(Rayfield, "Aimbot", value and "Enabled" or "Disabled")
		end
	})

	local keybindElement = AimbotTab:CreateKeybind({
		Name = "Aimbot Key",
		CurrentKeybind = "RightAlt",
		HoldToInteract = false,
		Flag = "aimbot_keybind",
		Callback = function()
		end
	})

	AimbotTab:CreateDropdown({
		Name = "Activation Mode",
		Options = {"Toggle", "Hold"},
		CurrentOption = {"Toggle"},
		MultipleOptions = false,
		Flag = "aimbot_mode",
		Callback = function(options)
			activationMode = options[1] or "Toggle"
			holdActive = false
			if activationMode == "Hold" then
				toggleActive = false
			end
		end
	})

	AimbotTab:CreateDropdown({
		Name = "Target Part",
		Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso", "Body"},
		CurrentOption = {"Head"},
		MultipleOptions = false,
		Flag = "aimbot_target_part",
		Callback = function(options)
			targetPartOption = options[1] or "Head"
		end
	})

	AimbotTab:CreateSlider({
		Name = "Smoothness",
		Range = {1, 100},
		Increment = 1,
		Suffix = "%",
		CurrentValue = smoothnessPercent,
		Flag = "aimbot_smoothness",
		Callback = function(value)
			smoothnessPercent = value
			updateSmoothnessAlpha()
		end
	})

	AimbotTab:CreateToggle({
		Name = "Team Check",
		CurrentValue = true,
		Flag = "aimbot_team_check",
		Callback = function(value)
			teamCheckEnabled = value
		end
	})

	AimbotTab:CreateToggle({
		Name = "Visibility Check",
		CurrentValue = true,
		Flag = "aimbot_visibility_check",
		Callback = function(value)
			visibilityCheckEnabled = value
		end
	})

	AimbotTab:CreateSection("FOV")

	AimbotTab:CreateSlider({
		Name = "FOV Radius",
		Range = {25, 600},
		Increment = 1,
		Suffix = "px",
		CurrentValue = 120,
		Flag = "aimbot_fov_radius",
		Callback = function(value)
			fovRadius = value
			if fovCircle then
				fovCircle.Radius = fovRadius
			end
		end
	})

	AimbotTab:CreateToggle({
		Name = "Show FOV",
		CurrentValue = false,
		Flag = "aimbot_show_fov",
		Callback = function(value)
			showFov = value
			if fovCircle then
				fovCircle.Visible = value
			end
		end
	})

	AimbotTab:CreateColorPicker({
		Name = "FOV Color",
		Color = fovColor,
		Flag = "aimbot_fov_color",
		Callback = function(value)
			fovColor = value
			if fovCircle then
				fovCircle.Color = value
			end
		end
	})

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		local parsed = resolveKeyCode(keybindElement.CurrentKeybind)
		if parsed then
			selectedKeyCode = parsed
		end

		if input.KeyCode == selectedKeyCode and aimbotEnabled then
			if activationMode == "Hold" then
				holdActive = true
			elseif activationMode == "Toggle" then
				toggleActive = not toggleActive
				Shared:Notify(Rayfield, "Aimbot", toggleActive and "Activated" or "Deactivated")
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == selectedKeyCode and activationMode == "Hold" then
			holdActive = false
		end
	end)

	RunService.RenderStepped:Connect(function()
		if fovCircle then
			fovCircle.Visible = showFov and aimbotEnabled
			fovCircle.Position = UserInputService:GetMouseLocation()
			fovCircle.Radius = fovRadius
			fovCircle.Color = fovColor
		end

		local shouldAim = aimbotEnabled and ((activationMode == "Toggle" and toggleActive) or (activationMode == "Hold" and holdActive))
		if not shouldAim then
			return
		end

		local targetPart = getBestTarget()
		if not targetPart then
			return
		end

		local origin = Camera.CFrame.Position
		local targetCFrame = CFrame.new(origin, targetPart.Position)
		Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothness)
	end)

	return AimbotTab
end

return AimbotTabModule