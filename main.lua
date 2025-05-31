-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Load Rayfield with error handling
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not success then
    warn("Failed to load Rayfield: " .. tostring(Rayfield))
    return
end

-- Create the main window
local Window = Rayfield:CreateWindow({
    Name = "Neptune Rivals",
    LoadingTitle = "Neptune Rivals",
    LoadingSubtitle = "by Asegarg",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NeptuneRivalsConfig",
        FileName = "NeptuneRivals"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)
local MainSection = MainTab:CreateSection("Main")

-- Aimbot variables
local aimbotEnabled = false
local localPlayer = Players.LocalPlayer
local aimbotSmoothness = 0.5

-- Function to find the closest living player
local function getClosestPlayer()
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil -- Prevent nil reference if character isn't loaded
    end
    local closestPlayer = nil
    local closestDistance = math.huge
    local camera = workspace.CurrentCamera
    local localPos = localPlayer.Character.HumanoidRootPart.Position

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
        -- Ensure smoothness is never exactly 0 to avoid snapping
        camera.CFrame = camera.CFrame:Lerp(targetCFrame, math.clamp(1 - aimbotSmoothness, 0.01, 1))
    end
end

-- Aimbot connection
local aimbotConnection

-- Aimbot toggle button
local AimbotToggle = MainTab:CreateButton({
    Name = "Aimbot",
    Callback = function()
        aimbotEnabled = not aimbotEnabled
        Rayfield:Notify({
            Title = "Aimbot",
            Content = aimbotEnabled and "Aimbot enabled" or "Aimbot disabled",
            Duration = 3
        })
        if aimbotEnabled then
            aimbotConnection = RunService:BindToRenderStep("Aimbot", Enum.RenderPriority.Camera.Value + 1, aimbotUpdate)
        else
            if aimbotConnection then 
                RunService:UnbindFromRenderStep("Aimbot") 
                aimbotConnection = nil
            end
        end
    end
})

local SmoothnessSlider = MainTab:CreateSlider({
    Name = "Aimbot Smoothness",
    Range = {0.1, 1}, -- Adjusted range to prevent snapping
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 0.5,
    Callback = function(value)
        aimbotSmoothness = value
        Rayfield:Notify({
            Title = "Aimbot Smoothness",
            Content = "Smoothness set to " .. tostring(value),
            Duration = 3
        })
    end
})

-- Visuals Tab (ESP)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local VisualsSection = VisualsTab:CreateSection("Visuals")

local espEnabled = false
local highlights = {}

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

local ESPToggle = VisualsTab:CreateButton({
    Name = "ESP Outline",
    Callback = function()
        espEnabled = not espEnabled
        Rayfield:Notify({
            Title = "ESP",
            Content = espEnabled and "ESP enabled" or "ESP disabled",
            Duration = 3
        })
        if espEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                applyESP(player)
            end
        else
            for player, _ in pairs(highlights) do
                removeESP(player)
            end
        end
    end
})

local boxESPEnabled = false
local boxDrawings = {}

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
                local headPos, onScreen = camera:WorldToViewportPoint(head.Position)
                local rootPos = camera:WorldToViewportPoint(rootPart.Position)
                quad.Visible = onScreen and headPos.Z > 0
                if quad.Visible then
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

local boxESPConnection

local BoxESPToggle = VisualsTab:CreateButton({
    Name = "Box ESP",
    Callback = function()
        boxESPEnabled = not boxESPEnabled
        Rayfield:Notify({
            Title = "Box ESP",
            Content = boxESPEnabled and "Box ESP enabled" or "Box ESP disabled",
            Duration = 3
        })
        if boxESPEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                applyBoxESP(player)
            end
            boxESPConnection = RunService.RenderStepped:Connect(updateBoxESP)
        else
            for player, _ in pairs(boxDrawings) do
                removeBoxESP(player)
            end
            if boxESPConnection then 
                boxESPConnection:Disconnect() 
                boxESPConnection = nil 
            end
        end
    end
})

local tracersEnabled = false
local tracerDrawings = {}

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
            line.Visible = onScreen and headPos.Z > 0
            if line.Visible then
                line.From = bottomCenter
                line.To = Vector2.new(headPos.X, headPos.Y)
            end
        else
            line.Visible = false
        end
    end
end

local tracersConnection

local TracersToggle = VisualsTab:CreateButton({
    Name = "Tracers",
    Callback = function()
        tracersEnabled = not tracersEnabled
        Rayfield:Notify({
            Title = "Tracers",
            Content = tracersEnabled and "Tracers enabled" or "Tracers disabled",
            Duration = 3
        })
        if tracersEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                applyTracer(player)
            end
            tracersConnection = RunService.RenderStepped:Connect(updateTracers)
        else
            for player, _ in pairs(tracerDrawings) do
                removeTracer(player)
            end
            if tracersConnection then 
                tracersConnection:Disconnect() 
                tracersConnection = nil 
            end
        end
    end
})

local skeletonESPEnabled = false
local skeletonDrawings = {}

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

local skeletonESPConnection

local SkeletonESPToggle = VisualsTab:CreateButton({
    Name = "Skeleton ESP",
    Callback = function()
        skeletonESPEnabled = not skeletonESPEnabled
        Rayfield:Notify({
            Title = "Skeleton ESP",
            Content = skeletonESPEnabled and "Skeleton ESP enabled" or "Skeleton ESP disabled",
            Duration = 3
        })
        if skeletonESPEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                applySkeletonESP(player)
            end
            skeletonESPConnection = RunService.RenderStepped:Connect(updateSkeletonESP)
        else
            for player, _ in pairs(skeletonDrawings) do
                removeSkeletonESP(player)
            end
            if skeletonESPConnection then 
                skeletonESPConnection:Disconnect() 
                skeletonESPConnection = nil 
            end
        end
    end
})

-- Health Bar ESP
local healthBarEnabled = false
local healthBars = {}

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
    if not healthBars[player] and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") then
        local billboardGui = createHealthBar(player)
        billboardGui.Parent = player.Character.Head
        healthBars[player] = billboardGui

        local humanoid = player.Character.Humanoid
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

local function removeHealthBar(player)
    if healthBars[player] then
        healthBars[player]:Destroy()
        healthBars[player] = nil
    end
end

local HealthBarToggle = VisualsTab:CreateButton({
    Name = "Health Bar ESP",
    Callback = function()
        healthBarEnabled = not healthBarEnabled
        Rayfield:Notify({
            Title = "Health Bar ESP",
            Content = healthBarEnabled and "Health Bar ESP enabled" or "Health Bar ESP disabled",
            Duration = 3
        })
        if healthBarEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                applyHealthBar(player)
            end
        else
            for player, _ in pairs(healthBars) do
                removeHealthBar(player)
            end
        end
    end
})

-- Misc Tab
local MiscTab = Window:CreateTab("Misc", 4483362458)
local MiscSection = MiscTab:CreateSection("Miscellaneous")

local speedEnabled = false
local selectedSpeed = 16
local speedConnection

local function updateSpeed()
    if speedEnabled and localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
        localPlayer.Character.Humanoid.WalkSpeed = selectedSpeed
    end
end

local SpeedDropdown = MiscTab:CreateDropdown({
    Name = "Walk Speed",
    Options = {"16", "32", "48", "64", "80", "100"},
    CurrentOption = "16",
    Callback = function(value)
        selectedSpeed = tonumber(value)
        speedEnabled = true
        Rayfield:Notify({
            Title = "Walk Speed",
            Content = "Walk speed set to " .. value,
            Duration = 3
        })
        if speedConnection then speedConnection:Disconnect() end
        speedConnection = RunService.Heartbeat:Connect(updateSpeed)
        updateSpeed()
    end
})

local ResetSpeedButton = MiscTab:CreateButton({
    Name = "Reset Walk Speed",
    Callback = function()
        speedEnabled = false
        selectedSpeed = 16
        SpeedDropdown:Set("16")
        if speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end
        if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
            localPlayer.Character.Humanoid.WalkSpeed = 16
        end
        Rayfield:Notify({
            Title = "Walk Speed",
            Content = "Walk speed reset to default (16)",
            Duration = 3
        })
    end
})

local function onCharacterAdded(character)
    if speedEnabled then
        updateSpeed()
    end
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

local removeHairEnabled = false

local function removePlayerHair(player)
    if player == localPlayer or not player.Character or not removeHairEnabled then return end
    for _, accessory in ipairs(player.Character:GetChildren()) do
        if accessory:IsA("Accessory") and accessory.AccessoryType == Enum.AccessoryType.Hair then
            accessory:Destroy()
        end
    end
end

local function applyRemoveHair()
    if not removeHairEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        removePlayerHair(player)
    end
end

local RemoveHairButton = MiscTab:CreateButton({
    Name = "Hair Cut",
    Callback = function()
        removeHairEnabled = not removeHairEnabled
        Rayfield:Notify({
            Title = "Hair Cut",
            Content = removeHairEnabled and "Hair cut enabled" or "Hair cut disabled",
            Duration = 3
        })
        if removeHairEnabled then
            applyRemoveHair()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    player.CharacterAdded:Connect(function()
                        removePlayerHair(player)
                    end)
                end
            end
        end
    end
})

local phaseEnabled = false
local phaseConnection
local phaseCooldown = 0
local PHASE_COOLDOWN_TIME = 0.1
local MAX_WALL_THICKNESS = 10
local PHASE_DISTANCE = 5

local function togglePhase()
    phaseEnabled = not phaseEnabled
    Rayfield:Notify({
        Title = "Phase",
        Content = phaseEnabled and "Phase enabled (Hold E to phase through walls)" or "Phase disabled",
        Duration = 3
    })
    
    if phaseEnabled then
        phaseConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") or not localPlayer.Character:FindFirstChild("Humanoid") then return end
            local rootPart = localPlayer.Character.HumanoidRootPart
            local isPressingE = UserInputService:IsKeyDown(Enum.KeyCode.E)
            phaseCooldown = math.max(0, phaseCooldown - deltaTime)
            
            if isPressingE and phaseCooldown <= 0 then
                local rayOrigin = rootPart.Position
                local rayDirection = rootPart.CFrame.LookVector * PHASE_DISTANCE
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {localPlayer.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.IgnoreWater = true
                
                local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                
                if raycastResult then
                    local hitPosition = raycastResult.Position
                    local rayDirectionUnit = rayDirection.Unit
                    local backRayOrigin = hitPosition + rayDirectionUnit * 0.1
                    local backRayDirection = -rayDirection
                    local backRaycastResult = workspace:Raycast(backRayOrigin, backRayDirection * MAX_WALL_THICKNESS, raycastParams)
                    
                    local wallThickness = MAX_WALL_THICKNESS
                    if backRaycastResult then
                        wallThickness = (backRaycastResult.Position - hitPosition).Magnitude
                    end
                    
                    if wallThickness <= MAX_WALL_THICKNESS then
                        local teleportOffset = rayDirectionUnit * (wallThickness + 0.5)
                        local newPosition = rootPart.Position + teleportOffset
                        
                        local spaceCheckParams = RaycastParams.new()
                        spaceCheckParams.FilterDescendantsInstances = {localPlayer.Character}
                        spaceCheckParams.FilterType = Enum.RaycastFilterType.Exclude
                        local clearCheckRay = workspace:Raycast(newPosition, Vector3.new(0, -2, 0), spaceCheckParams)
                        
                        if not clearCheckRay then
                            rootPart.CFrame = CFrame.new(newPosition, newPosition + rootPart.CFrame.LookVector)
                            phaseCooldown = PHASE_COOLDOWN_TIME
                        end
                    end
                end
            end
        end)
    else
        if phaseConnection then 
            phaseConnection:Disconnect() 
            phaseConnection = nil 
        end
    end
end

local PhaseToggle = MiscTab:CreateButton({
    Name = "Toggle Phase",
    Callback = togglePhase
})

local infiniteJumpEnabled = false
local jumpConnection

local function toggleInfiniteJump()
    infiniteJumpEnabled = not infiniteJumpEnabled
    Rayfield:Notify({
        Title = "Infinite Jump",
        Content = infiniteJumpEnabled and "Infinite Jump enabled" or "Infinite Jump disabled",
        Duration = 3
    })
    
    if infiniteJumpEnabled then
        jumpConnection = UserInputService.JumpRequest:Connect(function()
            if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
                localPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if jumpConnection then 
            jumpConnection:Disconnect() 
            jumpConnection = nil 
        end
    end
end

local InfiniteJumpToggle = MiscTab:CreateButton({
    Name = "Toggle Infinite Jump",
    Callback = toggleInfiniteJump
})

-- Consolidated cleanup for player events
local function cleanupPlayer(player)
    removeESP(player)
    removeBoxESP(player)
    removeTracer(player)
    removeSkeletonESP(player)
    removeHealthBar(player)
end

-- Consolidated RenderStepped for performance
local function updateVisuals()
    updateBoxESP()
    updateTracers()
    updateSkeletonESP()
end

local visualsConnection
local function toggleVisualsConnection()
    if boxESPEnabled or tracersEnabled or skeletonESPEnabled then
        if not visualsConnection then
            visualsConnection = RunService.RenderStepped:Connect(updateVisuals)
        end
    else
        if visualsConnection then
            visualsConnection:Disconnect()
            visualsConnection = nil
        end
    end
end

-- Override toggles to manage consolidated RenderStepped
local originalBoxESPToggle = BoxESPToggle.Callback
BoxESPToggle.Callback = function()
    originalBoxESPToggle()
    toggleVisualsConnection()
end

local originalTracersToggle = TracersToggle.Callback
TracersToggle.Callback = function()
    originalTracersToggle()
    toggleVisualsConnection()
end

local originalSkeletonESPToggle = SkeletonESPToggle.Callback
SkeletonESPToggle.Callback = function()
    originalSkeletonESPToggle()
    toggleVisualsConnection()
end

-- Player event handling
local playerConnections = {}
Players.PlayerAdded:Connect(function(player)
    local characterConnection
    characterConnection = player.CharacterAdded:Connect(function()
        applyESP(player)
        applyBoxESP(player)
        applyTracer(player)
        applySkeletonESP(player)
        removePlayerHair(player)
        applyHealthBar(player)
    end)
    playerConnections[player] = characterConnection
end)

Players.PlayerRemoving:Connect(function(player)
    cleanupPlayer(player)
    if playerConnections[player] then
        playerConnections[player]:Disconnect()
        playerConnections[player] = nil
    end
end)

-- Script cleanup
game:BindToClose(function()
    -- Clean up all connections
    if aimbotConnection then RunService:UnbindFromRenderStep("Aimbot") end
    if visualsConnection then visualsConnection:Disconnect() end
    if speedConnection then speedConnection:Disconnect() end
    if phaseConnection then phaseConnection:Disconnect() end
    if jumpConnection then jumpConnection:Disconnect() end
    
    -- Clean up drawings
    for _, quad in pairs(boxDrawings) do quad:Remove() end
    for _, line in pairs(tracerDrawings) do line:Remove() end
    for _, lines in pairs(skeletonDrawings) do
        for _, line in pairs(lines) do line:Remove() end
    end
    
    -- Clean up highlights and health bars
    for player, _ in pairs(highlights) do removeESP(player) end
    for player, _ in pairs(healthBars) do removeHealthBar(player) end
    
    -- Clean up player connections
    for player, connection in pairs(playerConnections) do
        connection:Disconnect()
    end
end)

Rayfield:LoadConfiguration()
