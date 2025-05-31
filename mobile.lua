-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configuration variables (edit these to change settings)
local aimbotEnabled = true
local aimbotSpeed = 0.8  -- Renamed from aimbotSmoothness for clarity; higher value = faster aim
local espEnabled = true
local boxESPEnabled = true
local tracersEnabled = true
local skeletonESPEnabled = true
local healthBarEnabled = false

-- Internal variables
local localPlayer = Players.LocalPlayer
local aimbotConnection
local boxESPConnection
local tracersConnection
local skeletonESPConnection
local highlights = {}
local boxDrawings = {}
local tracerDrawings = {}
local skeletonDrawings = {}
local healthBars = {}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Neptune Rivals Mobile",
   Icon = 0,
   LoadingTitle = "Neptune Rivals Mobile",
   LoadingSubtitle = "by Asegarg and Nexus Services",
   Theme = "Purple",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "Neptune Rivals"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})

local MainTab = Window:CreateTab("Main", 4483362458)
local MainSection = MainTab:CreateSection("Aimbot Controls")

local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local VisualsSection = VisualsTab:CreateSection("ESP Controls")

-- Aimbot Controls (Main Tab)
local AimbotToggle = MainTab:CreateToggle({
   Name = "Aimbot Enabled",
   CurrentValue = aimbotEnabled,
   Callback = function(Value)
      aimbotEnabled = Value
      if Value then
         aimbotConnection = RunService:BindToRenderStep("Aimbot", Enum.RenderPriority.Camera.Value + 1, aimbotUpdate)
      else
         if aimbotConnection then RunService:UnbindFromRenderStep("Aimbot") end
      end
   end
})

local AimbotSpeedSlider = MainTab:CreateSlider({
   Name = "Aimbot Speed",
   Range = {0, 1},
   Increment = 0.1,
   Suffix = "Speed",
   CurrentValue = aimbotSpeed,
   Callback = function(Value)
      aimbotSpeed = Value
   end
})

-- ESP Controls (Visuals Tab)
local ESPToggle = VisualsTab:CreateToggle({
   Name = "ESP Enabled",
   CurrentValue = espEnabled,
   Callback = function(Value)
      espEnabled = Value
      for _, player in ipairs(Players:GetPlayers()) do
         if Value then
            applyESP(player)
         else
            removeESP(player)
         end
      end
   end
})

local BoxESPToggle = VisualsTab:CreateToggle({
   Name = "Box ESP Enabled",
   CurrentValue = boxESPEnabled,
   Callback = function(Value)
      boxESPEnabled = Value
      if Value then
         boxESPConnection = RunService.RenderStepped:Connect(updateBoxESP)
         for _, player in ipairs(Players:GetPlayers()) do
            applyBoxESP(player)
         end
      else
         if boxESPConnection then boxESPConnection:Disconnect() end
         for _, player in ipairs(Players:GetPlayers()) do
            removeBoxESP(player)
         end
      end
   end
})

local TracersToggle = VisualsTab:CreateToggle({
   Name = "Tracers Enabled",
   CurrentValue = tracersEnabled,
   Callback = function(Value)
      tracersEnabled = Value
      if Value then
         tracersConnection = RunService.RenderStepped:Connect(updateTracers)
         for _, player in ipairs(Players:GetPlayers()) do
            applyTracer(player)
         end
      else
         if tracersConnection then tracersConnection:Disconnect() end
         for _, player in ipairs(Players:GetPlayers()) do
            removeTracer(player)
         end
      end
   end
})

local SkeletonESPToggle = VisualsTab:CreateToggle({
   Name = "Skeleton ESP Enabled",
   CurrentValue = skeletonESPEnabled,
   Callback = function(Value)
      skeletonESPEnabled = Value
      if Value then
         skeletonESPConnection = RunService.RenderStepped:Connect(updateSkeletonESP)
         for _, player in ipairs(Players:GetPlayers()) do
            applySkeletonESP(player)
         end
      else
         if skeletonESPConnection then skeletonESPConnection:Disconnect() end
         for _, player in ipairs(Players:GetPlayers()) do
            removeSkeletonESP(player)
         end
      end
   end
})

local HealthBarToggle = VisualsTab:CreateToggle({
   Name = "Health Bar Enabled",
   CurrentValue = healthBarEnabled,
   Callback = function(Value)
      healthBarEnabled = Value
      for _, player in ipairs(Players:GetPlayers()) do
         if Value then
            applyHealthBar(player)
         else
            removeHealthBar(player)
         end
      end
   end
})

Rayfield:LoadConfiguration()

-- Function to find the closest living player within 250 studs
local function getClosestPlayer()
    local closestPlayer = nil
    local closestDistance = 250  -- Max distance set to 250 studs
    local camera = workspace.CurrentCamera
    local localPos = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character.HumanoidRootPart.Position or camera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local head = player.Character.Head
            local distance = (localPos - head.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end
    return closestPlayer
end

-- Aimbot update function
local function aimbotUpdate()
    if not aimbotEnabled then return end
    local camera = workspace.CurrentCamera
    local target = getClosestPlayer()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local headPos = target.Character.Head.Position
        local targetCFrame = CFrame.new(camera.CFrame.Position, headPos)
        camera.CFrame = camera.CFrame:Lerp(targetCFrame, aimbotSpeed)  -- Changed to use aimbotSpeed directly
    end
end

-- ESP functions
local function applyESP(player)
    if player == localPlayer or not player.Character or not espEnabled then return end
    local highlight = player.Character:FindFirstChild("Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "Highlight"
        highlight.FillTransparency = 1
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Parent = player.Character
        highlights[player] = highlight
    end
end

local function removeESP(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end

-- Box ESP functions
local function createBoxDrawing()
    local quad = Drawing.new("Quad")
    quad.Visible = false
    quad.Color = Color3.fromRGB(255, 255, 255)
    quad.Thickness = 2
    quad.Transparency = 1
    quad.Filled = false
    return quad
end

local function applyBoxESP(player)
    if player == localPlayer or not player.Character or not boxESPEnabled then return end
    if not boxDrawings[player] then
        boxDrawings[player] = createBoxDrawing()
    end
end

local function removeBoxESP(player)
    if boxDrawings[player] then
        boxDrawings[player]:Remove()
        boxDrawings[player] = nil
    end
end

local function updateBoxESP()
    if not boxESPEnabled then return end
    local camera = workspace.CurrentCamera
    for player, quad in pairs(boxDrawings) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local rootPart = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head")
            if head then
                local headPos = camera:WorldToViewportPoint(head.Position)
                local rootPos = camera:WorldToViewportPoint(rootPart.Position)
                local onScreen = headPos.Z > 0
                quad.Visible = onScreen
                if onScreen then
                    local distanceY = math.clamp((Vector2.new(headPos.X, headPos.Y) - Vector2.new(rootPos.X, rootPos.Y)).Magnitude, 2, math.huge)
                    quad.PointA = Vector2.new(rootPos.X + distanceY, rootPos.Y - distanceY * 2)
                    quad.PointB = Vector2.new(rootPos.X - distanceY, rootPos.Y - distanceY * 2)
                    quad.PointC = Vector2.new(rootPos.X - distanceY, rootPos.Y + distanceY * 2)
                    quad.PointD = Vector2.new(rootPos.X + distanceY, rootPos.Y + distanceY * 2)
                end
            else
                quad.Visible = false
            end
        else
            quad.Visible = false
        end
    end
end

-- Tracer functions
local function createTracerDrawing()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(255, 255, 255)
    line.Thickness = 2
    line.Transparency = 1
    return line
end

local function applyTracer(player)
    if player == localPlayer or not player.Character or not tracersEnabled then return end
    if not tracerDrawings[player] then
        tracerDrawings[player] = createTracerDrawing()
    end
end

local function removeTracer(player)
    if tracerDrawings[player] then
        tracerDrawings[player]:Remove()
        tracerDrawings[player] = nil
    end
end

local function updateTracers()
    if not tracersEnabled then return end
    local camera = workspace.CurrentCamera
    local screenSize = camera.ViewportSize
    local bottomCenter = Vector2.new(screenSize.X / 2, screenSize.Y)
    
    for player, line in pairs(tracerDrawings) do
        if player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local head = player.Character.Head
            local headPos, onScreen = camera:WorldToViewportPoint(head.Position)
            line.Visible = onScreen
            if onScreen then
                line.From = bottomCenter
                line.To = Vector2.new(headPos.X, headPos.Y)
            end
        else
            line.Visible = false
        end
    end
end

-- Skeleton ESP functions
local function createSkeletonDrawing()
    local lines = {}
    local parts = {"Head-Torso", "Torso-LeftArm", "Torso-RightArm", "Torso-LeftLeg", "Torso-RightLeg", "LeftArm-LeftHand", "RightArm-RightHand", "LeftLeg-LeftFoot", "RightLeg-RightFoot"}
    for _, part in ipairs(parts) do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 1
        line.Transparency = 1
        lines[part] = line
    end
    return lines
end

local function applySkeletonESP(player)
    if player == localPlayer or not player.Character or not skeletonESPEnabled then return end
    if not skeletonDrawings[player] then
        skeletonDrawings[player] = createSkeletonDrawing()
    end
end

local function removeSkeletonESP(player)
    if skeletonDrawings[player] then
        for _, line in pairs(skeletonDrawings[player]) do
            line:Remove()
        end
        skeletonDrawings[player] = nil
    end
end

local function updateSkeletonESP()
    if not skeletonESPEnabled then return end
    local camera = workspace.CurrentCamera
    for player, lines in pairs(skeletonDrawings) do
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local character = player.Character
            local parts = {
                Head = character:FindFirstChild("Head"),
                Torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
                LeftArm = character:FindFirstChild("LeftUpperArm"),
                RightArm = character:FindFirstChild("RightUpperArm"),
                LeftLeg = character:FindFirstChild("LeftUpperLeg"),
                RightLeg = character:FindFirstChild("RightUpperLeg"),
                LeftHand = character:FindFirstChild("LeftHand"),
                RightHand = character:FindFirstChild("RightHand"),
                LeftFoot = character:FindFirstChild("LeftFoot"),
                RightFoot = character:FindFirstChild("RightFoot")
            }
            local allPartsExist = true
            for _, part in pairs(parts) do
                if not part then
                    allPartsExist = false
                    break
                end
            end
            if allPartsExist then
                local connections = {
                    ["Head-Torso"] = {parts.Head, parts.Torso},
                    ["Torso-LeftArm"] = {parts.Torso, parts.LeftArm},
                    ["Torso-RightArm"] = {parts.Torso, parts.RightArm},
                    ["Torso-LeftLeg"] = {parts.Torso, parts.LeftLeg},
                    ["Torso-RightLeg"] = {parts.Torso, parts.RightLeg},
                    ["LeftArm-LeftHand"] = {parts.LeftArm, parts.LeftHand},
                    ["RightArm-RightHand"] = {parts.RightArm, parts.RightHand},
                    ["LeftLeg-LeftFoot"] = {parts.LeftLeg, parts.LeftFoot},
                    ["RightLeg-RightFoot"] = {parts.RightLeg, parts.RightFoot}
                }
                for key, line in pairs(lines) do
                    local partA, partB = unpack(connections[key])
                    local posA, visibleA = camera:WorldToViewportPoint(partA.Position)
                    local posB, visibleB = camera:WorldToViewportPoint(partB.Position)
                    line.Visible = visibleA and visibleB and posA.Z > 0 and posB.Z > 0
                    if line.Visible then
                        line.From = Vector2.new(posA.X, posA.Y)
                        line.To = Vector2.new(posB.X, posB.Y)
                    end
                end
            else
                for _, line in pairs(lines) do
                    line.Visible = false
                end
            end
        else
            for _, line in pairs(lines) do
                line.Visible = false
            end
        end
    end
end

-- Health Bar functions
local function createHealthBar(player)
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "HealthBarGUI"
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(2, 0, 0.5, 0)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.MaxDistance = 100

    local frame = Instance.new("Frame", billboardGui)
    frame.Size = UDim2.new(1, 0, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    frame.BorderSizePixel = 0

    local healthFill = Instance.new("Frame", frame)
    healthFill.Name = "HealthFill"
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.BorderSizePixel = 0

    local textLabel = Instance.new("TextLabel", billboardGui)
    textLabel.Size = UDim2.new(1, 0, 0.6, 0)
    textLabel.Position = UDim2.new(0, 0, 0.4, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Text = "100/100"

    return billboardGui
end

local function applyHealthBar(player)
    if player == localPlayer or not player.Character or not healthBarEnabled then return end
    if not healthBars[player] and player.Character:FindFirstChild("Head") then
        local billboardGui = createHealthBar(player)
        billboardGui.Parent = player.Character.Head
        healthBars[player] = billboardGui

        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if healthBars[player] and humanoid.Health > 0 then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local healthFill = healthBars[player]:FindFirstChild("HealthFill", true)
                    local textLabel = healthBars[player]:FindFirstChildOfClass("TextLabel")
                    if healthFill and textLabel then
                        healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                        healthFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                        textLabel.Text = string.format("%d/%d", math.floor(humanoid.Health), humanoid.MaxHealth)
                    end
                else
                    removeHealthBar(player)
                end
            end)
        end
    end
end

local function removeHealthBar(player)
    if healthBars[player] then
        healthBars[player]:Destroy()
        healthBars[player] = nil
    end
end

-- Consolidated cleanup for player events
local function cleanupPlayer(player)
    removeESP(player)
    removeBoxESP(player)
    removeTracer(player)
    removeSkeletonESP(player)
    removeHealthBar(player)
end

-- Initialize features based on configuration
if aimbotEnabled then
    aimbotConnection = RunService:BindToRenderStep("Aimbot", Enum.RenderPriority.Camera.Value + 1, aimbotUpdate)
end

if boxESPEnabled then
    boxESPConnection = RunService.RenderStepped:Connect(updateBoxESP)
end

if tracersEnabled then
    tracersConnection = RunService.RenderStepped:Connect(updateTracers)
end

if skeletonESPEnabled then
    skeletonESPConnection = RunService.RenderStepped:Connect(updateSkeletonESP)
end

-- Apply features to existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        applyESP(player)
        applyBoxESP(player)
        applyTracer(player)
        applySkeletonESP(player)
        applyHealthBar(player)
    end
    player.CharacterAdded:Connect(function()
        applyESP(player)
        applyBoxESP(player)
        applyTracer(player)
        applySkeletonESP(player)
        applyHealthBar(player)
    end)
end

Players.PlayerRemoving:Connect(cleanupPlayer)

-- Script cleanup
game:BindToClose(function()
    if aimbotConnection then RunService:UnbindFromRenderStep("Aimbot") end
    if boxESPConnection then boxESPConnection:Disconnect() end
    if tracersConnection then tracersConnection:Disconnect() end
    if skeletonESPConnection then skeletonESPConnection:Disconnect() end

    for _, quad in pairs(boxDrawings) do quad:Remove() end
    for _, line in pairs(tracerDrawings) do line:Remove() end
    for _, lines in pairs(skeletonDrawings) do
        for _, line in pairs(lines) do line:Remove() end
    end
    for player, _ in pairs(highlights) do removeESP(player) end
    for player, _ in pairs(healthBars) do removeHealthBar(player) end
end)
