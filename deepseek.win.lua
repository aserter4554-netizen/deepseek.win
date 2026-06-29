--[[
    deepseek.win v2.0
    Flight + Noclip + Speed + Gravity + Jump + Aimbot (Team Check) + ESP
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ======== SETTINGS ========
local espObjects = {}

local MovementSettings = {
    FlightEnabled = false,
    NoclipEnabled = false,
    Speed = 16,
    Gravity = 50,
    JumpPower = 50
}

local VisualSettings = {
    ESPEnabled = false,
    AimbotEnabled = false,
    AimbotSensitivity = 0.2
}

-- ======== MENU ========
local Window = Rayfield:CreateWindow({
    Name = "⚡ deepseek.win v2.0",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by IHave",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "deepseek",
        FileName = "deepseek_settings"
    },
    Keybind = Enum.KeyCode.Insert,
    Size = UDim2.new(0, 650, 0, 550)
})

-- MOVEMENT TAB
-- ======== ВКЛАДКА MOVEMENT (С ПОЛЗУНКОМ СКОРОСТИ ПОЛЁТА) ========
-- ======== ВКЛАДКА MOVEMENT (С РАБОЧИМ ПОЛЗУНКОМ СКОРОСТИ ПОЛЁТА) ========
local MovementTab = Window:CreateTab("🏃 Movement", 4483362458)

MovementTab:CreateToggle({
    Name = "Flight (E)",
    CurrentValue = false,
    Flag = "Flight",
    Callback = function(v) MovementSettings.FlightEnabled = v end
})

MovementTab:CreateToggle({
    Name = "Noclip (N)",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        MovementSettings.NoclipEnabled = v
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not v
                end
            end
        end
    end
})

MovementTab:CreateSlider({
    Name = "Flight Speed",
    Range = {10, 150},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "FlightSpeed",
    Callback = function(v)
        MovementSettings.FlightSpeed = v
    end
})

MovementTab:CreateSlider({
    Name = "Speed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Flag = "Speed",
    Callback = function(v)
        MovementSettings.Speed = v
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = v
            end
        end
    end
})

MovementTab:CreateSlider({
    Name = "Gravity",
    Range = {0, 196},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "Gravity",
    Callback = function(v)
        MovementSettings.Gravity = v
        workspace.Gravity = v
    end
})

MovementTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 150},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        MovementSettings.JumpPower = v
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                humanoid.JumpPower = v
            end
        end
    end
})
-- AIMBOT TAB
-- ======== AIMBOT (ARSENAL, С TEAM CHECK И ПРОВЕРКОЙ ВИДИМОСТИ) ========
local function isTargetVisible(targetHead)
    local cameraPos = Camera.CFrame.Position
    local direction = (targetHead - cameraPos).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

    local result = workspace:Raycast(cameraPos, direction * 1000, raycastParams)

    if result then
        local hit = result.Instance
        if hit and hit:IsDescendantOf(LocalPlayer.Character) == false then
            local character = hit:FindFirstAncestorOfClass("Model")
            if character and character:FindFirstChildWhichIsA("Humanoid") then
                return true
            end
        end
        return false
    end
    return true
end

local function getClosestVisibleTarget()
    local closest = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local myTeam = LocalPlayer.Team

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Team Check
            if VisualSettings.TeamCheck then
                if myTeam and player.Team and myTeam == player.Team then
                    continue
                end
            end

            local head = player.Character:FindFirstChild("Head")
            if head then
                local headPos = head.Position
                if isTargetVisible(headPos) then
                    local pos, onScreen = Camera:WorldToScreenPoint(headPos)
                    if onScreen then
                        local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closest = player
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if VisualSettings.AimbotEnabled then
        local target = getClosestVisibleTarget()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                local targetPos = head.Position
                local lookAt = CFrame.new(Camera.CFrame.Position, targetPos)
                Camera.CFrame = Camera.CFrame:Lerp(lookAt, VisualSettings.AimbotSensitivity)
            end
        end
    end
end)
-- VISUALS TAB
local VisualsTab = Window:CreateTab("👁️ Visuals", 4483362458)
VisualsTab:CreateToggle({
    Name = "ESP (names + distance)",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(v)
        VisualSettings.ESPEnabled = v
        if not v then clearESP() end
    end
})

-- ======== FLIGHT ========
local flightActive = false
local bv = Instance.new("BodyVelocity")
local bg = Instance.new("BodyGyro")

local function toggleFlight()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    flightActive = not flightActive
    MovementSettings.FlightEnabled = flightActive

    if flightActive then
        bv.Parent = root
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.new(0, 0, 0)

        bg.Parent = root
        bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bg.CFrame = root.CFrame
    else
        bv.Parent = nil
        bg.Parent = nil
        if LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
    end
end

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if flightActive and char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        local cam = workspace.CurrentCamera
        local dir = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end

        bv.Velocity = dir * 50
        bg.CFrame = cam.CFrame
        char.Humanoid.PlatformStand = true
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E then
        toggleFlight()
    end
end)

-- ======== NOCLIP ========
local noclipActive = false

local function toggleNoclip()
    noclipActive = not noclipActive
    MovementSettings.NoclipEnabled = noclipActive
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not noclipActive
            end
        end
    end
end

RunService.Stepped:Connect(function()
    if noclipActive then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.N then
        toggleNoclip()
    end
end)

-- ======== ESP ========
local espGui = Instance.new("ScreenGui")
espGui.Name = "ESPGui"
espGui.ResetOnSpawn = false
espGui.Parent = PlayerGui

function clearESP()
    for id, obj in pairs(espObjects) do
        if obj.Container then obj.Container:Destroy() end
        if obj.Highlight then obj.Highlight:Destroy() end
        if obj.Beam then obj.Beam:Destroy() end
        if obj.TargetAttachment then obj.TargetAttachment:Destroy() end
    end
    espObjects = {}
end

local function createEspLabel(player)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    if player.Character then
        highlight.Parent = player.Character
    end

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, 200, 0, 50)
    container.Parent = espGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 25)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Code
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Parent = container

    local healthBarBackground = Instance.new("Frame")
    healthBarBackground.Size = UDim2.new(0.6, 0, 0, 4)
    healthBarBackground.Position = UDim2.new(0.2, 0, 0.8, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0
    healthBarBackground.Parent = container

    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBackground

    local targetAttachment = nil
    local beam = Instance.new("Beam")
    beam.FaceCamera = true
    beam.Width0 = 0.15
    beam.Width1 = 0.15
    beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
    beam.Enabled = false
    beam.Parent = workspace.Terrain

    local rootPart = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso"))
    if rootPart then
        targetAttachment = Instance.new("Attachment")
        targetAttachment.Parent = rootPart
        beam.Attachment1 = targetAttachment
    end

    return {
        Container = container,
        NameLabel = nameLabel,
        HealthBar = healthBar,
        Highlight = highlight,
        Beam = beam,
        TargetAttachment = targetAttachment,
        Player = player
    }
end

local myAttachment = Instance.new("Attachment")
RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
    if myRoot then
        myAttachment.Parent = myRoot
    else
        myAttachment.Parent = nil
    end
end)

function updateESP()
    if not VisualSettings.ESPEnabled then
        clearESP()
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
            if rootPart then
                local pos, onScreen = Camera:WorldToScreenPoint(rootPart.Position)
                if onScreen then
                    if not espObjects[player.UserId] then
                        espObjects[player.UserId] = createEspLabel(player)
                    end

                    local data = espObjects[player.UserId]
                    local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")

                    if data.Highlight.Parent ~= player.Character then
                        data.Highlight.Parent = player.Character
                    end
                    if not data.TargetAttachment or data.TargetAttachment.Parent ~= rootPart then
                        if data.TargetAttachment then data.TargetAttachment:Destroy() end
                        data.TargetAttachment = Instance.new("Attachment")
                        data.TargetAttachment.Parent = rootPart
                        data.Beam.Attachment1 = data.TargetAttachment
                    end

                    data.Container.Visible = true
                    data.Container.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 60)

                    local dist = math.floor((rootPart.Position - Camera.CFrame.Position).Magnitude)
                    local hp = humanoid and math.max(0, humanoid.Health) or 100
                    local maxHp = humanoid and (humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100) or 100
                    local hpPercent = math.clamp(hp / maxHp, 0, 1)

                    data.NameLabel.Text = string.format("%s\n[%dm] [%d HP]", player.Name, dist, math.floor(hp))
                    data.HealthBar.Size = UDim2.new(hpPercent, 0, 1, 0)
                    data.HealthBar.BackgroundColor3 = Color3.fromHSV(hpPercent * 0.33, 1, 1)

                    if myAttachment.Parent then
                        data.Beam.Attachment0 = myAttachment
                        data.Beam.Enabled = true
                    else
                        data.Beam.Enabled = false
                    end
                else
                    if espObjects[player.UserId] then
                        espObjects[player.UserId].Container.Visible = false
                        espObjects[player.UserId].Beam.Enabled = false
                    end
                end
            end
        end
    end

    for id, obj in pairs(espObjects) do
        if not obj.Player or not obj.Player.Parent then
            if obj.Container then obj.Container:Destroy() end
            if obj.Highlight then obj.Highlight:Destroy() end
            if obj.Beam then obj.Beam:Destroy() end
            if obj.TargetAttachment then obj.TargetAttachment:Destroy() end
            espObjects[id] = nil
        end
    end
end

RunService.RenderStepped:Connect(updateESP)

-- ======== VISIBILITY CHECK ========
local function isVisible(headPosition)
    local cameraPos = Camera.CFrame.Position
    local direction = (headPosition - cameraPos).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

    local result = workspace:Raycast(cameraPos, direction * 1000, raycastParams)

    if result then
        local hit = result.Instance
        if hit and hit:IsDescendantOf(LocalPlayer.Character) == false then
            local character = hit:FindFirstAncestorOfClass("Model")
            if character and character:FindFirstChildWhichIsA("Humanoid") then
                return true
            end
        end
        return false
    end
    return true
end

-- ======== AIMBOT (С TEAM CHECK) ========
local function getClosestVisibleTarget()
    local closest = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    local myTeam = LocalPlayer.Team

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Team Check
            if myTeam and player.Team and myTeam == player.Team then
                continue -- пропускаем союзников
            end

            local head = player.Character:FindFirstChild("Head")
            if head then
                local headPos = head.Position
                if isVisible(headPos) then
                    local pos, onScreen = Camera:WorldToScreenPoint(headPos)
                    if onScreen then
                        local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closest = player
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if VisualSettings.AimbotEnabled then
        local target = getClosestVisibleTarget()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                local targetPos = head.Position
                local lookAt = CFrame.new(Camera.CFrame.Position, targetPos)
                Camera.CFrame = Camera.CFrame:Lerp(lookAt, VisualSettings.AimbotSensitivity)
            end
        end
    end
end)

-- ======== TOGGLE X ========
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.X then
        VisualSettings.AimbotEnabled = not VisualSettings.AimbotEnabled
        Rayfield:Notify({
            Title = "Aimbot",
            Content = VisualSettings.AimbotEnabled and "🔴 ENABLED" or "⚫ DISABLED",
            Duration = 2,
        })
    end
end)

-- ======== CHARACTER ADDED ========
local function onCharacterAdded(char)
    task.wait(0.5)
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = MovementSettings.Speed
        humanoid.JumpPower = MovementSettings.JumpPower
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    task.wait(0.5)
    onCharacterAdded(LocalPlayer.Character)
end
-- ======== ЛЕВАЯ ВЕРХНЯЯ ПАНЕЛЬ (FPS + NICK + deepseek.win) ========
-- ======== ЛЕВАЯ ВЕРХНЯЯ ПАНЕЛЬ (FPS + NICK + deepseek.win) ========
task.wait(1)

local topPanelGui = Instance.new("ScreenGui")
topPanelGui.Name = "TopPanel"
topPanelGui.ResetOnSpawn = false
topPanelGui.IgnoreGuiInset = true
topPanelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
topPanelGui.DisplayOrder = 999
topPanelGui.Parent = game:GetService("CoreGui")

-- Чёрный овал (фон)
local oval = Instance.new("Frame")
oval.Size = UDim2.new(0, 400, 0, 40)
oval.Position = UDim2.new(0, 10, 0, 60)  -- Сдвинуто на 50 пикселей вниз
oval.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
oval.BackgroundTransparency = 0.7
oval.BorderSizePixel = 0
oval.ZIndex = 999
oval.Parent = topPanelGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0) -- Полный овал
corner.Parent = oval

-- Текст: FPS
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 60, 1, 0)
fpsLabel.Position = UDim2.new(0, 10, 0, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: 0"
fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 14
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.ZIndex = 999
fpsLabel.Parent = oval

-- Текст: Ник в Roblox
local nickLabel = Instance.new("TextLabel")
nickLabel.Size = UDim2.new(0, 150, 1, 0)
nickLabel.Position = UDim2.new(0, 80, 0, 0)
nickLabel.BackgroundTransparency = 1
nickLabel.Text = LocalPlayer.Name
nickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nickLabel.Font = Enum.Font.GothamBold
nickLabel.TextSize = 14
nickLabel.TextXAlignment = Enum.TextXAlignment.Left
nickLabel.ZIndex = 999
nickLabel.Parent = oval

-- Текст: deepseek.win (радужный)
local watermarkLabel = Instance.new("TextLabel")
watermarkLabel.Size = UDim2.new(0, 150, 1, 0)
watermarkLabel.Position = UDim2.new(1, -160, 0, 0)
watermarkLabel.BackgroundTransparency = 1
watermarkLabel.Text = "deepseek.win"
watermarkLabel.Font = Enum.Font.GothamBold
watermarkLabel.TextSize = 14
watermarkLabel.TextXAlignment = Enum.TextXAlignment.Right
watermarkLabel.ZIndex = 999
watermarkLabel.Parent = oval

-- FPS счётчик
local fps = 0
local fpsUpdateTime = 0

game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
    fpsUpdateTime = fpsUpdateTime + deltaTime
    if fpsUpdateTime >= 0.5 then
        fps = math.floor(1 / deltaTime)
        fpsLabel.Text = "FPS: " .. tostring(fps)
        fpsUpdateTime = 0
    end
end)

-- Радужный эффект для deepseek.win
local hue = 0
game:GetService("RunService").RenderStepped:Connect(function()
    hue = (hue + 0.5) % 360
    watermarkLabel.TextColor3 = Color3.fromHSV(hue/360, 1, 1)
end)

Rayfield:Notify({
    Title = "deepseek.win v2.0",
    Content = "E - Flight | N - Noclip | X - Aimbot | Insert - Menu",
    Duration = 5,
    Image = 4483362458,
})
