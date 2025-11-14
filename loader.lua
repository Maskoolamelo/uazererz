local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local workspaceCam = workspace.CurrentCamera
local rootPart = nil

local function refreshCharacter()
	character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
}
refreshCharacter()
LocalPlayer.CharacterAdded:Connect(refreshCharacter)

local canWrite = type(writefile) == "function"
local canRead = type(readfile) == "function"
local canIsFile = type(isfile) == "function"
local canMakeFolder = type(makefolder) == "function"

local function encodeTable(t)
	local ok, res = pcall(function() return HttpService:JSONEncode(t) end)
	return ok and res or ""
end
local function decodeTable(s)
	local ok, res = pcall(function() return HttpService:JSONDecode(s) end)
	return ok and res or nil
end

pcall(function()
	PhysicsService:CreateCollisionGroup("NoPlayerCollide")
	PhysicsService:CollisionGroupSetCollidable("NoPlayerCollide", "Players", false)
end)
local function setPlayerCollisionGroup(char)
	pcall(function()
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(part, "NoPlayerCollide")
			end
		end
	end)
end

local DefaultConfig = {
	binds = {
		PhantomToggle = Enum.KeyCode.E.Name,
		FloorHackToggle = Enum.KeyCode.R.Name
	},
	options = {
		phantom = false,
		anti_bee = false,
		floorhack = false,
		decorationsTransparency = true,
		decorationsTransparencyValue = 0.7,
		esp_players = false,
		invisible_players = false,
		autoexec = false,
		desync = false
	},
	guiPosition = UDim2.new(0.5, -100, 0.5, -150),
    logoPosition = UDim2.new(0, 18, 0.5, -32)
}
local ConfigFileName = "EmpireConfig.json"
local Config = DefaultConfig

if canRead and canIsFile and isfile(ConfigFileName) then
	local ok, s = pcall(readfile, ConfigFileName)
	if ok and s then
		local parsed = decodeTable(s)
		if type(parsed) == "table" then
			if parsed.binds and parsed.options then 
				Config = parsed 
				Config.guiPosition = parsed.guiPosition or DefaultConfig.guiPosition
                Config.logoPosition = parsed.logoPosition or DefaultConfig.logoPosition
				Config.binds.PhantomToggle = parsed.binds.PhantomToggle or DefaultConfig.binds.PhantomToggle
				Config.binds.FloorHackToggle = parsed.binds.FloorHackToggle or DefaultConfig.binds.FloorHackToggle
				Config.options.desync = parsed.options.desync or DefaultConfig.options.desync
			end
		end
	end
end

local function keyFromName(name)
	for _,v in pairs(Enum.KeyCode:GetEnumItems()) do
		if v.Name == name then return v end
	end
	return Enum.KeyCode.Unknown
end

local keybinds = {
	PhantomToggle = keyFromName(Config.binds.PhantomToggle) or Enum.KeyCode.E,
	FloorHackToggle = keyFromName(Config.binds.FloorHackToggle) or Enum.KeyCode.R
}

local stairColor = Color3.fromRGB(0, 200, 255)

local phantomActive = Config.options.phantom
local floorHackActive = Config.options.floorhack
local decorationsTransparencyEnabled = Config.options.decorationsTransparency
local decorationsTransparencyValue = Config.options.decorationsTransparencyValue or 0.7
local espEnabled = Config.options.esp_players or false
local invisibleEnabled = Config.options.invisible_players or false
local antiBeeEnabled = Config.options.anti_bee or false
local desyncActive = Config.options.desync or false
local hiddenCharacters = {}
local effectsBlocked = false
local originalCameraType = workspace.CurrentCamera.CameraType
local espObjects = {}
local espConnection = nil

local BUTTON_SIZE = UDim2.new(0, 64, 0, 64)
local TOGGLE_BUTTON_FIXED_POS = UDim2.new(0, 18, 0.5, -32) 
local BUTTON_MIN_MARGIN = 8

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Empire_Hub_GUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.IgnoreGuiInset = false
screenGui.DisplayOrder = 999999

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "EmpireToggle"
toggleButton.Size = BUTTON_SIZE
if Config.logoPosition then
    toggleButton.Position = Config.logoPosition
end
toggleButton.AnchorPoint = Vector2.new(0, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(18,18,18)
toggleButton.BackgroundTransparency = 0.15
toggleButton.Text = "⚡"
toggleButton.Font = Enum.Font.Arcade
toggleButton.TextSize = 24
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.AutoButtonColor = false
toggleButton.Active = true
toggleButton.Draggable = true
toggleButton.Parent = screenGui

local btnCorner = Instance.new("UICorner", toggleButton)
btnCorner.CornerRadius = UDim.new(1, 0)

local btnStroke = Instance.new("UIStroke", toggleButton)
btnStroke.Thickness = 3
btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local shadow = Instance.new("ImageLabel", toggleButton)
shadow.Size = UDim2.new(1.2,0,1.2,0)
shadow.Position = UDim2.new(-0.1,0,-0.1,0)
shadow.Image = "rbxassetid://5028857084"
shadow.BackgroundTransparency = 1
shadow.ImageTransparency = 0.7
shadow.ZIndex = 0
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(24,24,276,276)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 300)
mainFrame.Position = Config.guiPosition
mainFrame.BackgroundColor3 = Color3.fromRGB(12,12,12)
mainFrame.BackgroundTransparency = 0.12
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 3
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Transparency = 0.1

RunService.Heartbeat:Connect(function()
	local hue = (tick() * 0.45) % 1
	local color = Color3.fromHSV(hue, 1, 1)
	btnStroke.Color = color
	mainStroke.Color = color
end)

local function clampMainFrameOnScreen()
	local viewport = workspaceCam and workspaceCam.ViewportSize or Vector2.new(1920,1080)
	local absPos = mainFrame.AbsolutePosition
	local absSize = mainFrame.AbsoluteSize
	local newX = math.clamp(absPos.X, BUTTON_MIN_MARGIN, viewport.X - absSize.X - BUTTON_MIN_MARGIN)
	local newY = math.clamp(absPos.Y, BUTTON_MIN_MARGIN, viewport.Y - absSize.Y - BUTTON_MIN_MARGIN)
	mainFrame.Position = UDim2.new(0, newX, 0, newY)
end
RunService.RenderStepped:Connect(clampMainFrameOnScreen)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if mainFrame.Draggable then
            Config.guiPosition = mainFrame.Position
        end
        if toggleButton.Draggable then
            Config.logoPosition = toggleButton.Position
        end
        commitConfig()
    end
end)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1,0,0,30)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "⚡ EMPIRE HUB"
title.Font = Enum.Font.Arcade
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)

local listLayout = Instance.new("UIListLayout", mainFrame)
listLayout.Padding = UDim.new(0,6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	mainFrame.Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, math.max(80, listLayout.AbsoluteContentSize.Y + 45))
end)

local function createMenuButton(text, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 170, 0, 32)
	b.BackgroundColor3 = color or Color3.fromRGB(52, 58, 64)
	b.Text = text
	b.Font = Enum.Font.Arcade
	b.TextSize = 14
	b.TextColor3 = Color3.new(1,1,1)
	b.Parent = mainFrame
	b.LayoutOrder = #mainFrame:GetChildren()
	local c = Instance.new("UICorner", b)
	c.CornerRadius = UDim.new(0,8)
	return b
end

local btnPhantom = createMenuButton("Phantom Glide ["..keybinds.PhantomToggle.Name.."]")
local btnFloor = createMenuButton("Floor Hack ["..keybinds.FloorHackToggle.Name.."]")
local btnDesync = createMenuButton("Desync")
local btnESP = createMenuButton("Player ESP")
local btnInvisible = createMenuButton("Invisible Players")
local btnAntiBee = createMenuButton("Anti-Bee")
local btnDecorations = createMenuButton("Deco Transparent")
local btnAutoExec = createMenuButton("AutoExec")
local btnSaveConfig = createMenuButton("Save Config", Color3.fromRGB(40, 167, 69))
local btnLoadConfig = createMenuButton("Load Config", Color3.fromRGB(0, 123, 255))
local btnDiscord = createMenuButton("👾 Discord", Color3.fromRGB(88, 101, 242))
title.LayoutOrder = 0

local uiVisible = false
toggleButton.MouseButton1Click:Connect(function()
	uiVisible = not uiVisible
	mainFrame.Visible = uiVisible
end)

local function commitConfig()
	local cfg = {
		binds = { PhantomToggle = keybinds.PhantomToggle.Name, FloorHackToggle = keybinds.FloorHackToggle.Name },
		options = {
			phantom = phantomActive,
			anti_bee = antiBeeEnabled,
			floorhack = floorHackActive,
			decorationsTransparency = decorationsTransparencyEnabled,
			decorationsTransparencyValue = decorationsTransparencyValue,
			esp_players = espEnabled,
			invisible_players = invisibleEnabled,
			autoexec = Config.options.autoexec,
			desync = desyncActive
		},
		guiPosition = Config.guiPosition,
        logoPosition = Config.logoPosition,
	}
	Config = cfg
	if canWrite then
		pcall(function() writefile(ConfigFileName, encodeTable(cfg)) end)
	end
end

-- ====================================================
-- LOGIQUE DE DESYNC (FFlags)
-- ====================================================

local desyncFFlags = {
    ["GameNetPVHeaderRotationalVelocityZeroCutoffExponent"] = "-5000",
    ["GameNetPVHeaderLinearVelocityZeroCutoffExponent"] = "-5000",
    ["LargeReplicatorWrite5"] = "True",
    ["LargeReplicatorEnabled9"] = "True",
    ["AngularVelocityLimit"] = "360",
    ["TimestepArbiterVelocityCriteriaThresholdTwoDt"] = "2147483646",
    ["S2PhysicsSenderRate"] = "15000",
    ["DisableDPIScale"] = "True",
    ["MaxDataPacketPerSend"] = "2147483647",
    ["ServerMaxBandwidth"] = "52",
    ["PhysicsSenderMaxBandwidthBps"] = "20000",
    ["MaxTimestepMultiplierBuoyancy"] = "2147483647",
    ["SimOwnedOUCountThresholdMillionth"] = "2147483647",
    ["MaxMissedWorldStepsRemembered"] = "-2147483648",
    ["PlayerHumanoidPropertyUpdateRestrict"] = "False",
    ["SimDefaultHumanoidTimestepMultiplier"] = "150",
    ["StreamJobNOUVolumeLengthCap"] = "2147483647",
    ["DebugSendDistInSteps"] = "-2147483648",
    ["MaxTimestepMultiplierIteration"] = "2147483647",
    ["MaxTimestepMultiplierAcceleration"] = "2147483647",
    ["LargeReplicatorRead5"] = "True",
    ["SimExplicitlyCappedTimestepMultiplier"] = "2147483646",
    ["GameNetDontSendRedundantNumTimes"] = "1",
    ["CheckPVCachedRotVelThresholdPercent"] = "10",
    ["CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent"] = "1",
    ["NextGenReplicatorEnabledWrite4"] = "True",
    ["TimestepArbiterHumanoidLinearVelThreshold"] = "1",
    ["LargeReplicatorSerializeRead3"] = "True",
    ["ReplicationFocusNouExtentsSizeCutoffForPauseStuds"] = "2147483647",
    ["WorldStepMax"] = "30",
    ["CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth"] = "1",
    ["GameNetDontSendRedundantDeltaPositionMillionth"] = "1",
    ["InterpolationFrameVelocityThresholdMillionth"] = "5",
    ["StreamJobNOUVolumeCap"] = "2147483647",
    ["InterpolationFrameRotVelocityThresholdMillionth"] = "5",
    ["CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth"] = "1",
    ["MaxTimestepMultiplierHumanoid"] = "2147483647",
    ["InterpolationFramePositionThresholdMillionth"] = "5",
    ["TimestepArbiterHumanoidTurningVelThreshold"] = "1",
    ["MaxTimestepMultiplierConstraint"] = "2147483647",
    ["CheckPVCachedVelThresholdPercent"] = "10",
    ["TimestepArbiterOmegaThou"] = "1073741823",
    ["MaxAcceptableUpdateDelay"] = "1",
    ["LargeReplicatorSerializeWrite4"] = "True",
}

local function ApplyDesync()
    local ok = pcall(function()
        for fflag, value in pairs(desyncFFlags) do
            setfflag(fflag, value)
        end
    end)
    return ok
end

local function ResetDesync()
    pcall(function() setfflag("WorldStepMax", "-1") end)
}

local function setDesyncState(state)
    desyncActive = state
    Config.options.desync = desyncActive

    if desyncActive then
        local success = ApplyDesync()
        if success then
            btnDesync.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            btnDesync.Text = "Desync (ON) + RESET"
            
            -- ⭐ MODIFICATION CLÉ : Réinitialisation du personnage (en mettant la santé à 0)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character:FindFirstChild("Humanoid").Health = 0 -- Triggers a full character respawn
            end
            
        else
            desyncActive = false
            btnDesync.BackgroundColor3 = Color3.fromRGB(220, 20, 60)
            btnDesync.Text = "Desync (FAIL)"
            task.wait(1.5)
            btnDesync.Text = "Desync"
            btnDesync.BackgroundColor3 = Color3.fromRGB(52, 58, 64)
        end
    else
        ResetDesync()
        btnDesync.BackgroundColor3 = Color3.fromRGB(52, 58, 64)
        btnDesync.Text = "Desync"
    end
}
btnDesync.MouseButton1Click:Connect(function() setDesyncState(not desyncActive); commitConfig() end)

LocalPlayer.CharacterAdded:Connect(function()
    if not desyncActive then
        btnDesync.BackgroundColor3 = Color3.fromRGB(52, 58, 64)
        btnDesync.Text = "Desync"
    else
        btnDesync.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        btnDesync.Text = "Desync (ON) + RESET"
    end
end)

-- ====================================================
-- FIN LOGIQUE DE DESYNC
-- ====================================================


local function setPhantomState(state)
	phantomActive = state
	btnPhantom.Text = "Phantom Glide " .. (phantomActive and "(ON)" or "(OFF)") .. " [".. keybinds.PhantomToggle.Name .."]"
	btnPhantom.BackgroundColor3 = phantomActive and Color3.fromRGB(0,170,0) or Color3.fromRGB(52, 58, 64)
	Config.options.phantom = phantomActive
	if phantomActive then
		task.spawn(function()
			while phantomActive and rootPart and rootPart.Parent do
				rootPart.Velocity = rootPart.CFrame.LookVector * 28
				RunService.Heartbeat:Wait()
			end
		end)
	end
end
btnPhantom.MouseButton1Click:Connect(function() setPhantomState(not phantomActive); commitConfig() end)

local floorLoop = nil
local floorPart = nil
local function setFloorHack(state)
	floorHackActive = state
	btnFloor.Text = "Floor Hack " .. (floorHackActive and "(ON)" or "(OFF)") .. " [".. keybinds.FloorHackToggle.Name .."]"
	btnFloor.BackgroundColor3 = floorHackActive and Color3.fromRGB(0,170,0) or Color3.fromRGB(52, 58, 64)
	Config.options.floorhack = floorHackActive
	if floorHackActive then
		if not rootPart then refreshCharacter() end
		if floorPart and floorPart.Parent then floorPart:Destroy() end
		floorPart = Instance.new("Part")
		floorPart.Size = Vector3.new(8, 0.4, 8)
		floorPart.Anchored = true
		floorPart.CanCollide = true
		floorPart.Material = Enum.Material.Neon
		floorPart.Color = stairColor
		floorPart.CFrame = CFrame.new((rootPart and rootPart.Position or Vector3.new(0,0,0)) - Vector3.new(0,3,0))
		floorPart.Parent = workspace
		floorLoop = RunService.Heartbeat:Connect(function()
			if not rootPart or not rootPart.Parent or not floorPart or not floorPart.Parent then return end
			local pos = Vector3.new(rootPart.Position.X, floorPart.Position.Y, rootPart.Position.Z)
			floorPart.CFrame = CFrame.new(pos)
			local rayOrigin = floorPart.Position + Vector3.new(0, 0.5, 0)
			local rayDirection = Vector3.new(0, 3.5, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {character, floorPart}
			raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
			local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			if not rayResult then
				floorPart.CFrame = floorPart.CFrame + Vector3.new(0, 0.18, 0)
			end
		end)
	else
		if floorLoop then floorLoop:Disconnect() end
		if floorPart and floorPart.Parent then floorPart:Destroy() end
		floorPart = nil
	end
end
btnFloor.MouseButton1Click:Connect(function() setFloorHack(not floorHackActive); commitConfig() end)
LocalPlayer.CharacterAdded:Connect(function() if floorHackActive then setFloorHack(false) end end)

local function getRainbowColor()
	return Color3.fromHSV((tick()/4)%1, 1, 1)
end
local function createESPForPlayer(plr)
	if not plr or not plr.Character or plr == LocalPlayer or espObjects[plr] then return end
	local hl = Instance.new("Highlight")
	hl.Name = "EmpireESP"
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.Parent = plr.Character
	espObjects[plr] = hl
	plr.CharacterAdded:Connect(function(char)
		task.wait(0.8)
		if espObjects[plr] then espObjects[plr].Parent = char end
	end)
end
local function removeESPForPlayer(plr)
	if espObjects[plr] then
		pcall(function() espObjects[plr]:Destroy() end)
		espObjects[plr] = nil
	end
end
local function enableESP(state)
	espEnabled = state
	btnESP.Text = "Player ESP " .. (espEnabled and "(ON)" or "(OFF)")
	btnESP.BackgroundColor3 = espEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(52, 58, 64)
	Config.options.esp_players = espEnabled
	if espEnabled then
		for _,plr in ipairs(Players:GetPlayers()) do createESPForPlayer(plr) end
		Players.PlayerAdded:Connect(createESPForPlayer)
		Players.PlayerRemoving:Connect(removeESPForPlayer)
		if espConnection then espConnection:Disconnect() end
		espConnection = RunService.RenderStepped:Connect(function()
			local color = getRainbowColor()
			for _,hl in pairs(espObjects) do
				if hl and hl.Parent then pcall(function() hl.OutlineColor = color end) end
			end
		end)
	else
		if espConnection then espConnection:Disconnect() end
		for plr,_ in pairs(espObjects) do removeESPForPlayer(plr) end
		espObjects = {}
	end
end
btnESP.MouseButton1Click:Connect(function() enableESP(not espEnabled); commitConfig() end)

local function hidePlayer(otherPlayer)
	if not otherPlayer or not otherPlayer.Character or hiddenCharacters[otherPlayer] then return end
	local char = otherPlayer.Character
	hiddenCharacters[otherPlayer] = {}
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			table.insert(hiddenCharacters[otherPlayer], {Part = obj, OriginalTransparency = obj.Transparency, OriginalCanCollide = obj.CanCollide})
			pcall(function() obj.Transparency = 1; obj.CanCollide = false end)
		end
	end
end
local function restorePlayer(otherPlayer)
	if not hiddenCharacters[otherPlayer] then return end
	for _, data in ipairs(hiddenCharacters[otherPlayer]) do
		if data.Part and data.Part.Parent then
			pcall(function() data.Part.Transparency = data.OriginalTransparency; data.Part.CanCollide = data.OriginalCanCollide end)
		end
	end
	hiddenCharacters[otherPlayer] = nil
end
local function setInvisiblePlayers(state)
	invisibleEnabled = state
	btnInvisible.Text = "Invisible Players " .. (invisibleEnabled and "(ON)" or "(OFF)")
	btnInvisible.BackgroundColor3 = invisibleEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(52, 58, 64)
	Config.options.invisible_players = invisibleEnabled
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			if invisibleEnabled then
				hidePlayer(plr)
			else
				restorePlayer(plr)
			end
		end
	end
end
btnInvisible.MouseButton1Click:Connect(function() setInvisiblePlayers(not invisibleEnabled); commitConfig() end)
Players.PlayerAdded:Connect(function(p) if invisibleEnabled then p.CharacterAdded:Connect(function() hidePlayer(p) end) end end)
Players.PlayerRemoving:Connect(restorePlayer)

local function blockEffects(enable)
	antiBeeEnabled = enable
	effectsBlocked = enable
	btnAntiBee.Text = "Anti-Bee " .. (antiBeeEnabled and "(ON)" or "(OFF)")
	btnAntiBee.BackgroundColor3 = antiBeeEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(52, 58, 64)
	Config.options.anti_bee = antiBeeEnabled
	if enable then
		originalCameraType = workspaceCam.CameraType
		local function onChildAdded(child)
			if child:IsA("ParticleEmitter") or child:IsA("Explosion") or child:IsA("Fire") or child:IsA("Smoke") or child:IsA("Sparkles") then child:Destroy() end
		end
		workspace.ChildAdded:Connect(onChildAdded)
		Lighting.ChildAdded:Connect(onChildAdded)
		for _, s in ipairs(workspace:GetDescendants()) do if s:IsA("Sound") then s:Stop() end end
		workspace.DescendantAdded:Connect(function(d) if d:IsA("Sound") then d:Stop() end end)
		RunService:BindToRenderStep("AntiBeeCam", Enum.RenderPriority.Camera.Value, function()
			if workspaceCam.CameraType ~= Enum.CameraType.Custom then workspaceCam.CameraType = Enum.CameraType.Custom end
		end)
	else
		RunService:UnbindFromRenderStep("AntiBeeCam")
		workspaceCam.CameraType = originalCameraType
	end
end
btnAntiBee.MouseButton1Click:Connect(function() blockEffects(not antiBeeEnabled); commitConfig() end)

local function setDecorationsTransparency(state)
	decorationsTransparencyEnabled = state
	btnDecorations.Text = "Deco Transparent " .. (decorationsTransparencyEnabled and "(ON)" or "(OFF)")
	btnDecorations.BackgroundColor3 = decorationsTransparencyEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(52, 58, 64)
	Config.options.decorationsTransparency = decorationsTransparencyEnabled
	local transparency = decorationsTransparencyEnabled and decorationsTransparencyValue or 0
	local plotsFolder = workspace:FindFirstChild("Plots")
	if not plotsFolder then return end
	for _, base in ipairs(plotsFolder:GetChildren()) do
		local decorations = base:FindFirstChild("Decorations")
		if decorations then
			for _, obj in ipairs(decorations:GetDescendants()) do
				if obj:IsA("BasePart") then pcall(function() obj.Transparency = transparency end) end
			end
		end
	end
end
btnDecorations.MouseButton1Click:Connect(function() setDecorationsTransparency(not decorationsTransparencyEnabled); commitConfig() end)

local function setAutoExecFlag(state)
	Config.options.autoexec = state
	btnAutoExec.Text = "AutoExec " .. (state and "(ON)" or "(OFF)")
	btnAutoExec.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(52, 58, 64)
	if state then
		if canMakeFolder and not isfolder("autoexec") then pcall(makefolder, "autoexec") end
		if canWrite then
			local launcher = "-- Empire AutoExec loader\nif isfile and readfile and isfile('autoexec/Empire_autoexec_script.lua') then loadstring(readfile('autoexec/Empire_autoexec_script.lua'))() end"
			pcall(writefile, "autoexec/Empire_autoexec_launcher.lua", launcher)
			if script and script.Source then pcall(writefile, "autoexec/Empire_autoexec_script.lua", script.Source) end
		end
	elseif canWrite and isfile and isfile("autoexec/Empire_autoexec_launcher.lua") then
		pcall(writefile, "autoexec/Empire_autoexec_launcher.lua", "")
	end
	commitConfig()
end
btnAutoExec.MouseButton1Click:Connect(function() setAutoExecFlag(not Config.options.autoexec) end)

btnSaveConfig.MouseButton1Click:Connect(function()
	commitConfig()
	btnSaveConfig.Text = "Saved!"
	task.wait(1.5)
	btnSaveConfig.Text = "Save Config"
end)

local dragging = false
local dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(
        0,
        startPos.X + delta.X,
        0,
        startPos.Y + delta.Y
    )
end

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Vector2.new(
            mainFrame.AbsolutePosition.X,
            mainFrame.AbsolutePosition.Y
        )

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false

                Config.guiPosition = mainFrame.Position
                commitConfig()
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if dragging then update(input) end
    end
end)


btnLoadConfig.MouseButton1Click:Connect(function()
	if canRead and canIsFile and isfile(ConfigFileName) then
		local ok, s = pcall(readfile, ConfigFileName)
		if ok and s then
			local parsed = decodeTable(s)
			if type(parsed) == "table" then
				Config = parsed
				
				if Config.guiPosition then
					mainFrame.Position = Config.guiPosition
				end
				if Config.logoPosition then
    toggleButton.Position = Config.logoPosition
end

				keybinds.PhantomToggle = keyFromName(Config.binds.PhantomToggle) or Enum.KeyCode.E
				keybinds.FloorHackToggle = keyFromName(Config.binds.FloorHackToggle) or Enum.KeyCode.R

				setPhantomState(Config.options.phantom)
				setFloorHack(Config.options.floorhack)
				enableESP(Config.options.esp_players)
				setInvisiblePlayers(Config.options.invisible_players)
				blockEffects(Config.options.anti_bee)
				setDecorationsTransparency(Config.options.decorationsTransparency)
				setAutoExecFlag(Config.options.autoexec)
				setDesyncState(Config.options.desync)

				btnLoadConfig.Text = "Loaded!"
				task.wait(1.5)
				btnLoadConfig.Text = "Load Config"
				return
			end
		end
	end
	btnLoadConfig.Text = "Load Failed!"
	task.wait(1.5)
	btnLoadConfig.Text = "Load Config"
end)

btnDiscord.MouseButton1Click:Connect(function()
	if setclipboard then setclipboard("https://discord.gg/gXnTrfbd") end
	btnDiscord.Text = "Copied!"
	task.wait(1.5)
	btnDiscord.Text = "👾 Discord"
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == keybinds.PhantomToggle then
			setPhantomState(not phantomActive); commitConfig()
		elseif input.KeyCode == keybinds.FloorHackToggle then
			setFloorHack(not floorHackActive); commitConfig()
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.8)
	refreshCharacter()
	setPlayerCollisionGroup(char)
	mainFrame.Visible = false
	uiVisible = false
end)

local function initFromConfig()
	setPhantomState(Config.options.phantom)
	setFloorHack(Config.options.floorhack)
	enableESP(Config.options.esp_players)
	setInvisiblePlayers(Config.options.invisible_players)
	blockEffects(Config.options.anti_bee)
	setDecorationsTransparency(Config.options.decorationsTransparency)
	setAutoExecFlag(Config.options.autoexec)
	setDesyncState(Config.options.desync)
	setDecorationsTransparency(true)
	
	if Config.guiPosition and Config.guiPosition.X.Scale >= 0 and Config.guiPosition.Y.Scale >= 0 then
		mainFrame.Position = Config.guiPosition
	end
end
initFromConfig()
