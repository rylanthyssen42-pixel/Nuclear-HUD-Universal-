

--================================================--
-- SERVICES
--================================================--
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--================================================--
-- UTILITY FUNCTIONS
--================================================--

local function safeGetCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char
end

local function getHumanoid(character)
    character = character or safeGetCharacter()
    return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(character)
    character = character or safeGetCharacter()
    return character:FindFirstChild("HumanoidRootPart")
end

local function notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
end

local function createSound(parent, soundId, volume, looped)
    local s = Instance.new("Sound")
    s.SoundId = soundId
    s.Volume = volume or 1
    s.Looped = looped or false
    s.Parent = parent
    s:Play()
    return s
end

local function getVehicleSeat()
    local char = safeGetCharacter()
    local humanoid = getHumanoid(char)
    if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
        return humanoid.SeatPart
    end
    return nil
end

local function getNearbyUnanchoredParts(radius)
    radius = radius or 50
    local root = getRoot()
    if not root then return {} end
    local parts = {}
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored and (part.Position - root.Position).Magnitude <= radius then
            table.insert(parts, part)
        end
    end
    return parts
end

local function lookAt(targetPart, lookPart)
    if not targetPart or not lookPart then return end
    local dir = (lookPart.Position - targetPart.Position).Unit
    targetPart.CFrame = CFrame.new(targetPart.Position, targetPart.Position + dir)
end

local function isPlayerLookingAt(targetPart, player)
    local cam = Camera
    local dir = (targetPart.Position - cam.CFrame.Position).Unit
    local lookDir = cam.CFrame.LookVector.Unit
    local dot = dir:Dot(lookDir)
    return dot > 0.95 -- fairly close to center of view
end

local function getRandomPlayer(excludeLocal)
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if not (excludeLocal and plr == LocalPlayer) then
            table.insert(list, plr)
        end
    end
    if #list == 0 then return nil end
    return list[math.random(1, #list)]
end

local function getPlayerByName(partial)
    partial = partial:lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():sub(1, #partial) == partial then
            return plr
        end
    end
    return nil
end

--================================================--
-- STATE TABLES
--================================================--

local MovementState = {
    Fly = false,
    VehicleFly = false,
    Noclip = false,
    InfiniteJump = false,
    Dash = false,
    ClickTeleport = false,
    WalkSpeed = 16,
    JumpPower = 50,
    GodMode = false
}

local EntityState = {
    FollowPlayer = false,
    HauntPlayer = false,
    EntityMode = false,
    TargetPlayer = nil
}

local TrollState = {
    Spinbot = false,
    OrbitPlayer = false,
    SelfFling = false,
    PlayerFling = false,
    FakeDisconnect = false,
    FakeJoin = false,
    FakeLeave = false,
    CloneCharacter = false
}

local VisualState = {
    RGBCharacter = false,
    RGBHighlight = false,
    RainbowOutline = false,
    ParticleAura = false,
    FireAura = false,
    SmokeAura = false,
    Sparkles = false,
    Fullbright = false,
    NightVision = false
}

local VehicleState = {
    VehicleFly = false,
    Hover = false,
    Nitro = false,
    Jump = false,
    Drift = false
}

local PhysicsState = {
    OrbitParts = false,
    OrbitRadius = 20,
    OrbitSpeed = 1,
    BlackHole = false,
    ExplosionRing = false,
    OrbitPartsList = {}
}

local ESPState = {
    PlayerESP = false,
    NPCESP = false,
    VehicleESP = false,
    ToolESP = false
}

--================================================--
-- UI CREATION
--================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NuclearLabsClient"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Blur behind GUI
local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 350)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BackgroundTransparency = 0.25
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Glassmorphism effect
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

-- Animated rainbow border
local function animateRainbowStroke(stroke)
    local hue = 0
    RunService.RenderStepped:Connect(function(dt)
        hue = (hue + dt * 0.1) % 1
        stroke.Color = Color3.fromHSV(hue, 1, 1)
    end)
end
animateRainbowStroke(MainStroke)

-- Top bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0, 200, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Nuclear Labs Client"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.Parent = TopBar

-- Minimize button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 32, 0, 24)
MinimizeButton.Position = UDim2.new(1, -72, 0.5, -12)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 18
MinimizeButton.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeButton

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 32, 0, 24)
CloseButton.Position = UDim2.new(1, -36, 0.5, -12)
CloseButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 18
CloseButton.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Search bar
local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(0, 200, 0, 24)
SearchBox.Position = UDim2.new(1, -260, 0.5, -12)
SearchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
SearchBox.PlaceholderText = "Search features..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 14
SearchBox.Parent = TopBar

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 6)
SearchCorner.Parent = SearchBox

-- Tabs container
local TabsFrame = Instance.new("Frame")
TabsFrame.Name = "TabsFrame"
TabsFrame.Size = UDim2.new(0, 120, 1, -32)
TabsFrame.Position = UDim2.new(0, 0, 0, 32)
TabsFrame.BackgroundTransparency = 1
TabsFrame.Parent = MainFrame

local TabsList = Instance.new("UIListLayout")
TabsList.FillDirection = Enum.FillDirection.Vertical
TabsList.Padding = UDim.new(0, 4)
TabsList.Parent = TabsFrame

local TabNames = {
    "Movement",
    "Entity",
    "Troll",
    "Visual",
    "Vehicle",
    "Physics",
    "Utility",
    "ESP"
}

local TabButtons = {}
local ContentFrames = {}

-- Content container
local ContentHolder = Instance.new("Frame")
ContentHolder.Name = "ContentHolder"
ContentHolder.Size = UDim2.new(1, -120, 1, -32)
ContentHolder.Position = UDim2.new(0, 120, 0, 32)
ContentHolder.BackgroundTransparency = 1
ContentHolder.Parent = MainFrame

-- Helper to create tab button
local function createTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1, -10, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = TabsFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    TabButtons[name] = btn
end

-- Helper to create content frame
local function createContentFrame(name)
    local frame = Instance.new("ScrollingFrame")
    frame.Name = name .. "Content"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.ScrollBarThickness = 6
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = ContentHolder

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 6)
    layout.Parent = frame

    ContentFrames[name] = frame
end

for _, name in ipairs(TabNames) do
    createTabButton(name)
    createContentFrame(name)
end

-- ESP tab is part of Utility group but separate content
createTabButton("ESP")
createContentFrame("ESP")

-- Tab switching
local function setActiveTab(name)
    for tabName, frame in pairs(ContentFrames) do
        frame.Visible = (tabName == name)
    end
    for tabName, btn in pairs(TabButtons) do
        if tabName == name then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 90)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
        end
    end
end

for name, btn in pairs(TabButtons) do
    btn.MouseButton1Click:Connect(function()
        setActiveTab(name)
    end)
end

setActiveTab("Movement")

-- Minimize behavior
local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 600, 0, 32)
        }):Play()
        ContentHolder.Visible = false
        Blur.Size = 0
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 600, 0, 350)
        }):Play()
        ContentHolder.Visible = true
        Blur.Size = 10
    end
end)

-- Close behavior
CloseButton.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    Blur.Size = 0
    wait(0.3)
    ScreenGui:Destroy()
end)

--================================================--
-- TOGGLE & SLIDER UI HELPERS
--================================================--

local function createToggle(parent, labelText, defaultState, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 28)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.3, -10, 1, 0)
    button.Position = UDim2.new(0.7, 10, 0, 0)
    button.BackgroundColor3 = defaultState and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(60, 60, 60)
    button.Text = defaultState and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    local state = defaultState

    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = state and "ON" or "OFF"
        local targetColor = state and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(60, 60, 60)
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
        if callback then
            callback(state)
        end
    end)

    return container
end

local function createSlider(parent, labelText, minValue, maxValue, defaultValue, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 40)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0.5, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText .. " (" .. tostring(defaultValue) .. ")"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0.5, 4)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    bar.BorderSizePixel = 0
    bar.Parent = container

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = bar

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((defaultValue - minValue) / (maxValue - minValue), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    knob.BorderSizePixel = 0
    knob.Parent = bar

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local dragging = false

    local function updateFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = math.floor(minValue + (maxValue - minValue) * rel)
        knob.Position = UDim2.new(rel, -6, 0.5, -6)
        label.Text = labelText .. " (" .. tostring(value) .. ")"
        if callback then
            callback(value)
        end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(input.Position.X)
        end
    end)

    return container
end

--================================================--
-- KEY SYSTEM
--================================================--

local KeyFrame = Instance.new("Frame")
KeyFrame.Name = "KeyFrame"
KeyFrame.Size = UDim2.new(0, 300, 0, 150)
KeyFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
KeyFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
KeyFrame.BackgroundTransparency = 0.1
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Parent = ScreenGui

local KeyCorner = Instance.new("UICorner")
KeyCorner.CornerRadius = UDim.new(0, 12)
KeyCorner.Parent = KeyFrame

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Thickness = 2
KeyStroke.Color = Color3.fromRGB(255, 255, 255)
KeyStroke.Parent = KeyFrame

animateRainbowStroke(KeyStroke)

local KeyLabel = Instance.new("TextLabel")
KeyLabel.Size = UDim2.new(1, 0, 0, 40)
KeyLabel.Position = UDim2.new(0, 0, 0, 10)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "Enter Access Key"
KeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyLabel.Font = Enum.Font.GothamBold
KeyLabel.TextSize = 18
KeyLabel.Parent = KeyFrame

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(0.8, 0, 0, 32)
KeyBox.Position = UDim2.new(0.1, 0, 0, 60)
KeyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
KeyBox.PlaceholderText = "Key..."
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 14
KeyBox.Parent = KeyFrame

local KeyBoxCorner = Instance.new("UICorner")
KeyBoxCorner.CornerRadius = UDim.new(0, 8)
KeyBoxCorner.Parent = KeyBox

local KeyStatus = Instance.new("TextLabel")
KeyStatus.Size = UDim2.new(1, 0, 0, 24)
KeyStatus.Position = UDim2.new(0, 0, 0, 100)
KeyStatus.BackgroundTransparency = 1
KeyStatus.Text = ""
KeyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyStatus.Font = Enum.Font.GothamBold
KeyStatus.TextSize = 16
KeyStatus.Parent = KeyFrame

local KeyButton = Instance.new("TextButton")
KeyButton.Size = UDim2.new(0.5, 0, 0, 28)
KeyButton.Position = UDim2.new(0.25, 0, 0, 120)
KeyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
KeyButton.Text = "Submit"
KeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyButton.Font = Enum.Font.GothamBold
KeyButton.TextSize = 14
KeyButton.Parent = KeyFrame

local KeyButtonCorner = Instance.new("UICorner")
KeyButtonCorner.CornerRadius = UDim.new(0, 8)
KeyButtonCorner.Parent = KeyButton

MainFrame.Visible = false
Blur.Size = 0

local function keyAccessAnimation(success)
    if success then
        KeyStatus.Text = "Access Granted"
        KeyStatus.TextColor3 = Color3.fromRGB(80, 200, 80)
        TweenService:Create(KeyFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(20, 40, 20)}):Play()
    else
        KeyStatus.Text = "Access Denied"
        KeyStatus.TextColor3 = Color3.fromRGB(200, 80, 80)
        TweenService:Create(KeyFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(40, 20, 20)}):Play()
    end
end

KeyButton.MouseButton1Click:Connect(function()
    local key = KeyBox.Text
    if key == "nuclear_labs_AFO" then
        keyAccessAnimation(true)
        notify("Nuclear Labs", "Access Granted", 3)
        wait(0.5)
        TweenService:Create(KeyFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        wait(0.3)
        KeyFrame:Destroy()
        MainFrame.Visible = true
        Blur.Size = 10
    else
        keyAccessAnimation(false)
        notify("Nuclear Labs", "Access Denied", 3)
        local flashTween = TweenService:Create(KeyFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 20, 20)})
        flashTween:Play()
        flashTween.Completed:Wait()
        TweenService:Create(KeyFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(10, 10, 15)}):Play()
    end
end)

--================================================--
-- SEARCH FILTER (simple label-based filter)
--================================================--

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = SearchBox.Text:lower()
    for _, frame in pairs(ContentFrames) do
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
                local label = child:FindFirstChildOfClass("TextLabel")
                if label then
                    local visible = query == "" or label.Text:lower():find(query, 1, true) ~= nil
                    child.Visible = visible
                end
            end
        end
    end
end)

--================================================--
-- MOVEMENT
--================================================--

-- Fly implementation
local flyConnection
local flyVehicleConnection
local flySpeed = 60

local function setFlyEnabled(enabled)
    MovementState.Fly = enabled
    if enabled then
        notify("Movement", "Fly enabled", 2)
        local char = safeGetCharacter()
        local root = getRoot(char)
        if not root then return end

        if flyConnection then flyConnection:Disconnect() end

        flyConnection = RunService.RenderStepped:Connect(function(dt)
            char = safeGetCharacter()
            root = getRoot(char)
            if not root then return end

            local seat = getVehicleSeat()
            local moveTarget = seat or root

            local camCF = Camera.CFrame
            local lookVector = camCF.LookVector
            local upDown = camCF.UpVector

            -- Rotate character/vehicle to face camera including pitch
            moveTarget.CFrame = CFrame.new(moveTarget.Position, moveTarget.Position + lookVector)

            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + lookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - lookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + camCF.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + upDown
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir = moveDir - upDown
            end

            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit * flySpeed * dt
                moveTarget.CFrame = moveTarget.CFrame + moveDir
            end
        end)
    else
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = nil
        notify("Movement", "Fly disabled", 2)
    end
end

-- Noclip implementation
local noclipConnection
local function setNoclipEnabled(enabled)
    MovementState.Noclip = enabled
    local char = safeGetCharacter()
    if enabled then
        notify("Movement", "Noclip enabled", 2)
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            char = safeGetCharacter()
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = nil
        notify("Movement", "Noclip disabled", 2)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Infinite Jump
local infiniteJumpEnabled = false
UserInputService.JumpRequest:Connect(function()
    if MovementState.InfiniteJump then
        local humanoid = getHumanoid()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Dash
local dashCooldown = 0.5
local lastDash = 0
local function performDash()
    local now = tick()
    if now - lastDash < dashCooldown then return end
    lastDash = now
    local char = safeGetCharacter()
    local root = getRoot(char)
    if not root then return end
    local dashVector = Camera.CFrame.LookVector * 50
    root.Velocity = dashVector
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Q and MovementState.Dash then
        performDash()
    end
end)

-- Click Teleport
local function setClickTeleportEnabled(enabled)
    MovementState.ClickTeleport = enabled
    if enabled then
        notify("Movement", "Click Teleport enabled", 2)
    else
        notify("Movement", "Click Teleport disabled", 2)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if MovementState.ClickTeleport and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = input.Position
        local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {safeGetCharacter()}
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)
        if result then
            local root = getRoot()
            if root then
                root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
            end
        end
    end
end)

-- WalkSpeed & JumpPower sliders
local function setWalkSpeed(value)
    MovementState.WalkSpeed = value
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = value
    end
end

local function setJumpPower(value)
    MovementState.JumpPower = value
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.JumpPower = value
    end
end

-- God Mode (heal every 0.1 seconds)
local godModeConnection
local function setGodModeEnabled(enabled)
    MovementState.GodMode = enabled
    if enabled then
        notify("Movement", "God Mode enabled", 2)
        if godModeConnection then godModeConnection:Disconnect() end
        godModeConnection = RunService.Heartbeat:Connect(function()
            local humanoid = getHumanoid()
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
    else
        notify("Movement", "God Mode disabled", 2)
        if godModeConnection then godModeConnection:Disconnect() end
        godModeConnection = nil
    end
end

-- Movement UI
createToggle(ContentFrames["Movement"], "Fly", false, setFlyEnabled)
createToggle(ContentFrames["Movement"], "Noclip", false, setNoclipEnabled)
createToggle(ContentFrames["Movement"], "Infinite Jump", false, function(state)
    MovementState.InfiniteJump = state
    notify("Movement", "Infinite Jump " .. (state and "enabled" or "disabled"), 2)
end)
createToggle(ContentFrames["Movement"], "Dash (Q)", false, function(state)
    MovementState.Dash = state
    notify("Movement", "Dash " .. (state and "enabled" or "disabled"), 2)
end)
createToggle(ContentFrames["Movement"], "Click Teleport", false, setClickTeleportEnabled)
createToggle(ContentFrames["Movement"], "God Mode", false, setGodModeEnabled)

createSlider(ContentFrames["Movement"], "WalkSpeed", 16, 200, 16, setWalkSpeed)
createSlider(ContentFrames["Movement"], "JumpPower", 50, 200, 50, setJumpPower)

--================================================--
-- ENTITY (Pathfinding-based behaviors)
--================================================--

local entityModel
local entityConnection
local entitySpeed = 12
local entityTransparencyFlickerConnection
local entitySound

local function createEntityModel()
    if entityModel and entityModel.Parent then return entityModel end
    entityModel = Instance.new("Model")
    entityModel.Name = "NuclearEntity"
    entityModel.Parent = Workspace

    local part = Instance.new("Part")
    part.Name = "Core"
    part.Size = Vector3.new(2, 4, 2)
    part.Color = Color3.fromRGB(80, 0, 80)
    part.Material = Enum.Material.Neon
    part.Anchored = false
    part.CanCollide = false
    part.Parent = entityModel

    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = entityModel

    entityModel.PrimaryPart = part

    entitySound = createSound(part, "rbxassetid://91244890", 0.4, true)

    return entityModel
end

local function getTargetCharacter()
    if not EntityState.TargetPlayer then return nil end
    return EntityState.TargetPlayer.Character
end

local function pathfindToTarget(targetPos)
    local entity = createEntityModel()
    local path = PathfindingService:CreatePath()
    path:ComputeAsync(entity.PrimaryPart.Position, targetPos)
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, wp in ipairs(waypoints) do
            local dir = (wp.Position - entity.PrimaryPart.Position).Unit
            local step = dir * entitySpeed
            local duration = (wp.Position - entity.PrimaryPart.Position).Magnitude / entitySpeed
            local tween = TweenService:Create(entity.PrimaryPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(wp.Position)})
            tween:Play()
            tween.Completed:Wait()
        end
    end
end

local function setFollowPlayerEnabled(enabled)
    EntityState.FollowPlayer = enabled
    if enabled then
        notify("Entity", "Follow Player enabled", 2)
        if not EntityState.TargetPlayer then
            EntityState.TargetPlayer = getRandomPlayer(true)
        end
        if entityConnection then entityConnection:Disconnect() end
        entityConnection = RunService.Heartbeat:Connect(function()
            local targetChar = getTargetCharacter()
            local entity = createEntityModel()
            if targetChar and entity then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    pathfindToTarget(targetRoot.Position)
                end
            end
        end)
    else
        notify("Entity", "Follow Player disabled", 2)
        if entityConnection then entityConnection:Disconnect() end
        entityConnection = nil
    end
end

local function setHauntPlayerEnabled(enabled)
    EntityState.HauntPlayer = enabled
    if enabled then
        notify("Entity", "Haunt Player enabled", 2)
        if not EntityState.TargetPlayer then
            EntityState.TargetPlayer = getRandomPlayer(true)
        end
        if entityConnection then entityConnection:Disconnect() end
        entityConnection = RunService.Heartbeat:Connect(function()
            local targetChar = getTargetCharacter()
            local entity = createEntityModel()
            if targetChar and entity then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local offset = Vector3.new(math.random(-10, 10), math.random(2, 8), math.random(-10, 10))
                    pathfindToTarget(targetRoot.Position + offset)
                end
            end
        end)
    else
        notify("Entity", "Haunt Player disabled", 2)
        if entityConnection then entityConnection:Disconnect() end
        entityConnection = nil
    end
end

local entityModeConnection
local entitySpeedIncreaseConnection

local function setEntityModeEnabled(enabled)
    EntityState.EntityMode = enabled
    if enabled then
        notify("Entity", "Entity Mode enabled", 2)
        if not EntityState.TargetPlayer then
            EntityState.TargetPlayer = getRandomPlayer(true)
        end
        local entity = createEntityModel()
        entitySpeed = 8

        if entityTransparencyFlickerConnection then entityTransparencyFlickerConnection:Disconnect() end
        entityTransparencyFlickerConnection = RunService.Heartbeat:Connect(function()
            local part = entity.PrimaryPart
            if part then
                part.Transparency = math.random() * 0.5
            end
        end)

        if entitySpeedIncreaseConnection then entitySpeedIncreaseConnection:Disconnect() end
        entitySpeedIncreaseConnection = RunService.Heartbeat:Connect(function(dt)
            entitySpeed = math.clamp(entitySpeed + dt * 0.1, 8, 40)
        end)

        if entityModeConnection then entityModeConnection:Disconnect() end
        entityModeConnection = RunService.Heartbeat:Connect(function()
            local targetChar = getTargetCharacter()
            if not targetChar then return end
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            if not targetRoot then return end

            local entityRoot = entity.PrimaryPart
            if not entityRoot then return end

            -- Always look at target
            lookAt(entityRoot, targetRoot)

            local hidden = not isPlayerLookingAt(entityRoot, EntityState.TargetPlayer)
            if hidden then
                -- Move only when unseen
                local offset = Vector3.new(math.random(-15, 15), math.random(2, 8), math.random(-15, 15))
                pathfindToTarget(targetRoot.Position + offset)

                -- Teleport occasionally when hidden
                if math.random() < 0.05 then
                    entityRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(math.random(-5, 5), math.random(2, 6), math.random(-5, 5)))
                end
            else
                -- Freeze while target looks at it
                entityRoot.Velocity = Vector3.new(0, 0, 0)
            end
        end)
    else
        notify("Entity", "Entity Mode disabled", 2)
        if entityModeConnection then entityModeConnection:Disconnect() end
        if entityTransparencyFlickerConnection then entityTransparencyFlickerConnection:Disconnect() end
        if entitySpeedIncreaseConnection then entitySpeedIncreaseConnection:Disconnect() end
        entityModeConnection = nil
        entityTransparencyFlickerConnection = nil
        entitySpeedIncreaseConnection = nil
        if entityModel then
            entityModel:Destroy()
            entityModel = nil
        end
    end
end

createToggle(ContentFrames["Entity"], "Follow Player", false, setFollowPlayerEnabled)
createToggle(ContentFrames["Entity"], "Haunt Player", false, setHauntPlayerEnabled)
createToggle(ContentFrames["Entity"], "Entity Mode", false, setEntityModeEnabled)

--================================================--
-- TROLL
--================================================--

-- Spinbot
local spinConnection
local function setSpinbotEnabled(enabled)
    TrollState.Spinbot = enabled
    if enabled then
        notify("Troll", "Spinbot enabled", 2)
        if spinConnection then spinConnection:Disconnect() end
        spinConnection = RunService.RenderStepped:Connect(function(dt)
            local char = safeGetCharacter()
            local root = getRoot(char)
            if root then
                root.CFrame = root.CFrame * CFrame.Angles(0, dt * 10, 0)
            end
        end)
    else
        notify("Troll", "Spinbot disabled", 2)
        if spinConnection then spinConnection:Disconnect() end
        spinConnection = nil
    end
end

-- Orbit Player
local orbitConnection
local orbitRadius = 10
local orbitSpeed = 2
local function setOrbitPlayerEnabled(enabled)
    TrollState.OrbitPlayer = enabled
    if enabled then
        notify("Troll", "Orbit Player enabled", 2)
        if not EntityState.TargetPlayer then
            EntityState.TargetPlayer = getRandomPlayer(true)
        end
        if orbitConnection then orbitConnection:Disconnect() end
        orbitConnection = RunService.RenderStepped:Connect(function(dt)
            local char = safeGetCharacter()
            local root = getRoot(char)
            local targetChar = getTargetCharacter()
            if root and targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local t = tick() * orbitSpeed
                    local offset = Vector3.new(math.cos(t) * orbitRadius, 3, math.sin(t) * orbitRadius)
                    root.CFrame = CFrame.new(targetRoot.Position + offset, targetRoot.Position)
                end
            end
        end)
    else
        notify("Troll", "Orbit Player disabled", 2)
        if orbitConnection then orbitConnection:Disconnect() end
        orbitConnection = nil
    end
end

-- Self Fling
local function selfFling()
    local root = getRoot()
    if root then
        root.Velocity = Vector3.new(0, 200, 0)
        notify("Troll", "Self Fling executed", 2)
    end
end

-- Player Fling (simple velocity)
local function playerFling()
    local target = getRandomPlayer(true)
    if target and target.Character then
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.Velocity = Vector3.new(0, 200, 0)
            notify("Troll", "Player Fling on " .. target.Name, 2)
        end
    end
end

-- Fake messages
local function fakeSystemMessage(msg)
    notify("System", msg, 3)
end

local function fakeDisconnect()
    fakeSystemMessage("You were disconnected from the game. (Fake)")
end

local function fakeJoin()
    local target = getRandomPlayer(false)
    if target then
        fakeSystemMessage(target.Name .. " has joined the game. (Fake)")
    end
end

local function fakeLeave()
    local target = getRandomPlayer(false)
    if target then
        fakeSystemMessage(target.Name .. " has left the game. (Fake)")
    end
end

-- Clone Character
local function cloneCharacter()
    local char = safeGetCharacter()
    local clone = char:Clone()
    clone.Name = char.Name .. "_Clone"
    clone.Parent = Workspace
    local root = getRoot(char)
    if root then
        local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
        if cloneRoot then
            cloneRoot.CFrame = root.CFrame * CFrame.new(0, 0, -5)
        end
    end
    notify("Troll", "Character cloned", 2)
end

-- Troll UI
createToggle(ContentFrames["Troll"], "Spinbot", false, setSpinbotEnabled)
createToggle(ContentFrames["Troll"], "Orbit Player", false, setOrbitPlayerEnabled)

createToggle(ContentFrames["Troll"], "Self Fling", false, function(state)
    TrollState.SelfFling = state
    if state then selfFling() end
end)

createToggle(ContentFrames["Troll"], "Player Fling", false, function(state)
    TrollState.PlayerFling = state
    if state then playerFling() end
end)

createToggle(ContentFrames["Troll"], "Fake Disconnect", false, function(state)
    TrollState.FakeDisconnect = state
    if state then fakeDisconnect() end
end)

createToggle(ContentFrames["Troll"], "Fake Join", false, function(state)
    TrollState.FakeJoin = state
    if state then fakeJoin() end
end)

createToggle(ContentFrames["Troll"], "Fake Leave", false, function(state)
    TrollState.FakeLeave = state
    if state then fakeLeave() end
end)

createToggle(ContentFrames["Troll"], "Clone Character", false, function(state)
    TrollState.CloneCharacter = state
    if state then cloneCharacter() end
end)

--================================================--
-- VISUAL
--================================================--

-- RGB Character
local rgbConnection
local function setRGBCharacterEnabled(enabled)
    VisualState.RGBCharacter = enabled
    local char = safeGetCharacter()
    if enabled then
        notify("Visual", "RGB Character enabled", 2)
        if rgbConnection then rgbConnection:Disconnect() end
        rgbConnection = RunService.RenderStepped:Connect(function(dt)
            local hue = (tick() * 0.2) % 1
            local color = Color3.fromHSV(hue, 1, 1)
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Color = color
                end
            end
        end)
    else
        notify("Visual", "RGB Character disabled", 2)
        if rgbConnection then rgbConnection:Disconnect() end
        rgbConnection = nil
    end
end

-- RGB Highlight
local highlight
local highlightConnection
local function setRGBHighlightEnabled(enabled)
    VisualState.RGBHighlight = enabled
    local char = safeGetCharacter()
    if enabled then
        notify("Visual", "RGB Highlight enabled", 2)
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 0
            highlight.Parent = char
        end
        if highlightConnection then highlightConnection:Disconnect() end
        highlightConnection = RunService.RenderStepped:Connect(function(dt)
            local hue = (tick() * 0.3) % 1
            highlight.OutlineColor = Color3.fromHSV(hue, 1, 1)
        end)
    else
        notify("Visual", "RGB Highlight disabled", 2)
        if highlightConnection then highlightConnection:Disconnect() end
        highlightConnection = nil
        if highlight then
            highlight:Destroy()
            highlight = nil
        end
    end
end

-- Rainbow Outline (UIStroke on character parts)
local outlineConnection
local function setRainbowOutlineEnabled(enabled)
    VisualState.RainbowOutline = enabled
    local char = safeGetCharacter()
    if enabled then
        notify("Visual", "Rainbow Outline enabled", 2)
        if outlineConnection then outlineConnection:Disconnect() end
        outlineConnection = RunService.RenderStepped:Connect(function(dt)
            local hue = (tick() * 0.3) % 1
            local color = Color3.fromHSV(hue, 1, 1)
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.Neon
                    part.Color = color
                end
            end
        end)
    else
        notify("Visual", "Rainbow Outline disabled", 2)
        if outlineConnection then outlineConnection:Disconnect() end
        outlineConnection = nil
    end
end

-- Particle Aura
local function setParticleAuraEnabled(enabled)
    VisualState.ParticleAura = enabled
    local char = safeGetCharacter()
    if enabled then
        notify("Visual", "Particle Aura enabled", 2)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local emitter = Instance.new("ParticleEmitter")
                emitter.Texture = "rbxassetid://243660364"
                emitter.Rate = 10
                emitter.Lifetime = NumberRange.new(1, 2)
                emitter.Speed = NumberRange.new(1, 3)
                emitter.Parent = part
            end
        end
    else
        notify("Visual", "Particle Aura disabled", 2)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                for _, pe in ipairs(part:GetChildren()) do
                    if pe:IsA("ParticleEmitter") then
                        pe:Destroy()
                    end
                end
            end
        end
    end
end

-- Fire Aura
local function setFireAuraEnabled(enabled)
    VisualState.FireAura = enabled
    local char = safeGetCharacter()
    if enabled then
        notify("Visual", "Fire Aura enabled", 2)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local fire = Instance.new("Fire")
                fire.Size = 5
                fire.Heat = 10
                fire.Parent = part
            end
        end
    else
        notify("Visual", "Fire Aura disabled", 2)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                for _, f in ipairs(part:GetChildren()) do
                    if f:IsA("Fire") then
                        f:Destroy()
                    end
                end
            end
        end
    end
end

-- Smoke Aura
local function setSmokeAuraEnabled(enabled)
    VisualState.SmokeAura = enabled
    local char = safeGetCharacter()
    if enabled then
        notify("Visual", "Smoke Aura enabled", 2)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local smoke = Instance.new("Smoke")
                smoke.Size = 5
                smoke.RiseVelocity = 5
                smoke.Parent = part
            end
        end
    else
        notify("Visual", "Smoke Aura disabled", 2)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                for _, s in ipairs(part:GetChildren()) do
                    if s:IsA("Smoke") then
                        s:Destroy()
                    end
                end
            end
        end
    end
end

-- Sparkles
local function setSparklesEnabled(enabled)
    VisualState.Sparkles = enabled
    local char = safeGetCharacter()
    if enabled then
        notify("Visual", "Sparkles enabled", 2)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local sparkles = Instance.new("Sparkles")
                sparkles.Parent = part
            end
        end
    else
        notify("Visual", "Sparkles disabled", 2)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                for _, s in ipairs(part:GetChildren()) do
                    if s:IsA("Sparkles") then
                        s:Destroy()
                    end
                end
            end
        end
    end
end

-- Fullbright
local originalLightingSettings = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local function setFullbrightEnabled(enabled)
    VisualState.Fullbright = enabled
    if enabled then
        notify("Visual", "Fullbright enabled", 2)
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        notify("Visual", "Fullbright disabled", 2)
        Lighting.Brightness = originalLightingSettings.Brightness
        Lighting.Ambient = originalLightingSettings.Ambient
        Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient
    end
end

-- Night Vision
local function setNightVisionEnabled(enabled)
    VisualState.NightVision = enabled
    if enabled then
        notify("Visual", "Night Vision enabled", 2)
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(0, 255, 0)
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 255, 0)
    else
        notify("Visual", "Night Vision disabled", 2)
        Lighting.Brightness = originalLightingSettings.Brightness
        Lighting.Ambient = originalLightingSettings.Ambient
        Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient
    end
end

-- Visual UI
createToggle(ContentFrames["Visual"], "RGB Character", false, setRGBCharacterEnabled)
createToggle(ContentFrames["Visual"], "RGB Highlight", false, setRGBHighlightEnabled)
createToggle(ContentFrames["Visual"], "Rainbow Outline", false, setRainbowOutlineEnabled)
createToggle(ContentFrames["Visual"], "Particle Aura", false, setParticleAuraEnabled)
createToggle(ContentFrames["Visual"], "Fire Aura", false, setFireAuraEnabled)
createToggle(ContentFrames["Visual"], "Smoke Aura", false, setSmokeAuraEnabled)
createToggle(ContentFrames["Visual"], "Sparkles", false, setSparklesEnabled)
createToggle(ContentFrames["Visual"], "Fullbright", false, setFullbrightEnabled)
createToggle(ContentFrames["Visual"], "Night Vision", false, setNightVisionEnabled)

--================================================--
-- VEHICLE
--================================================--

local vehicleFlyConnection
local hoverConnection
local nitroEnabled = false
local driftEnabled = false

local function setVehicleFlyEnabled(enabled)
    VehicleState.VehicleFly = enabled
    if enabled then
        notify("Vehicle", "Vehicle Fly enabled", 2)
        if vehicleFlyConnection then vehicleFlyConnection:Disconnect() end
        vehicleFlyConnection = RunService.RenderStepped:Connect(function(dt)
            local seat = getVehicleSeat()
            if seat then
                local camCF = Camera.CFrame
                local lookVector = camCF.LookVector
                local moveDir = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + lookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - lookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - camCF.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + camCF.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + camCF.UpVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDir = moveDir - camCF.UpVector
                end
                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit * flySpeed * dt
                    seat.CFrame = seat.CFrame + moveDir
                end
            end
        end)
    else
        notify("Vehicle", "Vehicle Fly disabled", 2)
        if vehicleFlyConnection then vehicleFlyConnection:Disconnect() end
        vehicleFlyConnection = nil
    end
end

local function setHoverEnabled(enabled)
    VehicleState.Hover = enabled
    if enabled then
        notify("Vehicle", "Hover enabled", 2)
        if hoverConnection then hoverConnection:Disconnect() end
        hoverConnection = RunService.RenderStepped:Connect(function(dt)
            local seat = getVehicleSeat()
            if seat then
                local pos = seat.Position
                seat.CFrame = CFrame.new(Vector3.new(pos.X, pos.Y + math.sin(tick() * 2) * 0.1, pos.Z), seat.CFrame.LookVector)
            end
        end)
    else
        notify("Vehicle", "Hover disabled", 2)
        if hoverConnection then hoverConnection:Disconnect() end
        hoverConnection = nil
    end
end

local function setNitroEnabled(enabled)
    VehicleState.Nitro = enabled
    nitroEnabled = enabled
    notify("Vehicle", "Nitro " .. (enabled and "enabled" or "disabled"), 2)
end

local function setJumpEnabled(enabled)
    VehicleState.Jump = enabled
    notify("Vehicle", "Vehicle Jump " .. (enabled and "enabled" or "disabled"), 2)
end

local function setDriftEnabled(enabled)
    VehicleState.Drift = enabled
    driftEnabled = enabled
    notify("Vehicle", "Drift " .. (enabled and "enabled" or "disabled"), 2)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local seat = getVehicleSeat()
    if not seat then return end

    if input.KeyCode == Enum.KeyCode.LeftShift and nitroEnabled then
        seat.Velocity = seat.CFrame.LookVector * 200
    end

    if input.KeyCode == Enum.KeyCode.Space and VehicleState.Jump then
        seat.Velocity = Vector3.new(0, 100, 0)
    end

    if input.KeyCode == Enum.KeyCode.E and driftEnabled then
        seat.Velocity = seat.CFrame.RightVector * 100
    end
end)

-- Vehicle UI
createToggle(ContentFrames["Vehicle"], "Vehicle Fly", false, setVehicleFlyEnabled)
createToggle(ContentFrames["Vehicle"], "Hover", false, setHoverEnabled)
createToggle(ContentFrames["Vehicle"], "Nitro (Shift)", false, setNitroEnabled)
createToggle(ContentFrames["Vehicle"], "Jump (Space)", false, setJumpEnabled)
createToggle(ContentFrames["Vehicle"], "Drift (E)", false, setDriftEnabled)

--================================================--
-- PHYSICS
--================================================--

local orbitPartsConnection

local function setOrbitPartsEnabled(enabled)
    PhysicsState.OrbitParts = enabled
    if enabled then
        notify("Physics", "Orbit Parts enabled", 2)
        PhysicsState.OrbitPartsList = getNearbyUnanchoredParts(50)
        if orbitPartsConnection then orbitPartsConnection:Disconnect() end
        orbitPartsConnection = RunService.RenderStepped:Connect(function(dt)
            local root = getRoot()
            if not root then return end
            local center = root.Position
            local radius = PhysicsState.OrbitRadius
            local speed = PhysicsState.OrbitSpeed
            for i, part in ipairs(PhysicsState.OrbitPartsList) do
                if part and part.Parent then
                    local angle = tick() * speed + i
                    local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
                    part.Velocity = Vector3.new(0, 0, 0)
                    part.CFrame = CFrame.new(center + offset)
                end
            end
        end)
    else
        notify("Physics", "Orbit Parts disabled", 2)
        if orbitPartsConnection then orbitPartsConnection:Disconnect() end
        orbitPartsConnection = nil
    end
end

local function setBlackHoleEnabled(enabled)
    PhysicsState.BlackHole = enabled
    if enabled then
        notify("Physics", "Black Hole mode enabled", 2)
        PhysicsState.OrbitPartsList = getNearbyUnanchoredParts(80)
        if orbitPartsConnection then orbitPartsConnection:Disconnect() end
        orbitPartsConnection = RunService.RenderStepped:Connect(function(dt)
            local root = getRoot()
            if not root then return end
            local center = root.Position
            for _, part in ipairs(PhysicsState.OrbitPartsList) do
                if part and part.Parent then
                    local dir = (center - part.Position).Unit
                    part.Velocity = dir * 100
                end
            end
        end)
    else
        notify("Physics", "Black Hole mode disabled", 2)
        if orbitPartsConnection then orbitPartsConnection:Disconnect() end
        orbitPartsConnection = nil
    end
end

local function releaseOrbitingParts()
    notify("Physics", "Released all orbiting parts", 2)
    PhysicsState.OrbitPartsList = {}
end

local function explosionRing()
    local root = getRoot()
    if not root then return end
    notify("Physics", "Explosion Ring triggered", 2)
    local parts = getNearbyUnanchoredParts(50)
    for _, part in ipairs(parts) do
        local dir = (part.Position - root.Position).Unit
        part.Velocity = dir * 200 + Vector3.new(0, 100, 0)
    end
end

createToggle(ContentFrames["Physics"], "Orbit Parts", false, setOrbitPartsEnabled)
createSlider(ContentFrames["Physics"], "Orbit Radius", 5, 50, 20, function(value)
    PhysicsState.OrbitRadius = value
end)
createSlider(ContentFrames["Physics"], "Orbit Speed", 1, 10, 2, function(value)
    PhysicsState.OrbitSpeed = value
end)
createToggle(ContentFrames["Physics"], "Black Hole Mode", false, setBlackHoleEnabled)
createToggle(ContentFrames["Physics"], "Release Orbiting Parts", false, function(state)
    if state then
        releaseOrbitingParts()
    end
end)
createToggle(ContentFrames["Physics"], "Explosion Ring", false, function(state)
    if state then
        explosionRing()
    end
end)

--================================================--
-- ESP
--================================================--

local espObjects = {
    Players = {},
    NPCs = {},
    Vehicles = {},
    Tools = {}
}

local function clearESP(category)
    for _, obj in pairs(espObjects[category]) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    espObjects[category] = {}
end

local function createBillboardESP(targetPart, color, category)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 100, 0, 40)
    bb.AlwaysOnTop = true
    bb.Parent = targetPart

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = color
    text.Font = Enum.Font.GothamBold
    text.TextSize = 14
    text.Text = category
    text.Parent = bb

    table.insert(espObjects[category], bb)
end

local function setPlayerESPEnabled(enabled)
    ESPState.PlayerESP = enabled
    if enabled then
        notify("ESP", "Player ESP enabled", 2)
        clearESP("Players")
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    createBillboardESP(root, Color3.fromRGB(0, 255, 0), "Players")
                end
            end
        end
    else
        notify("ESP", "Player ESP disabled", 2)
        clearESP("Players")
    end
end

local function setNPCESPEnabled(enabled)
    ESPState.NPCESP = enabled
    if enabled then
        notify("ESP", "NPC ESP enabled", 2)
        clearESP("NPCs")
        for _, model in ipairs(Workspace:GetChildren()) do
            if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(model) then
                local root = model:FindFirstChild("HumanoidRootPart")
                if root then
                    createBillboardESP(root, Color3.fromRGB(255, 255, 0), "NPCs")
                end
            end
        end
    else
        notify("ESP", "NPC ESP disabled", 2)
        clearESP("NPCs")
    end
end

local function setVehicleESPEnabled(enabled)
    ESPState.VehicleESP = enabled
    if enabled then
        notify("ESP", "Vehicle ESP enabled", 2)
        clearESP("Vehicles")
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("VehicleSeat") then
                createBillboardESP(part, Color3.fromRGB(0, 150, 255), "Vehicles")
            end
        end
    else
        notify("ESP", "Vehicle ESP disabled", 2)
        clearESP("Vehicles")
    end
end

local function setToolESPEnabled(enabled)
    ESPState.ToolESP = enabled
    if enabled then
        notify("ESP", "Tool ESP enabled", 2)
        clearESP("Tools")
        for _, tool in ipairs(Workspace:GetDescendants()) do
            if tool:IsA("Tool") then
                local handle = tool:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    createBillboardESP(handle, Color3.fromRGB(255, 0, 255), "Tools")
                end
            end
        end
    else
        notify("ESP", "Tool ESP disabled", 2)
        clearESP("Tools")
    end
end

createToggle(ContentFrames["ESP"], "Player ESP", false, setPlayerESPEnabled)
createToggle(ContentFrames["ESP"], "NPC ESP", false, setNPCESPEnabled)
createToggle(ContentFrames["ESP"], "Vehicle ESP", false, setVehicleESPEnabled)
createToggle(ContentFrames["ESP"], "Tool ESP", false, setToolESPEnabled)

--================================================--
-- UTILITY (extra helpers / future extension)
--================================================--

local function resetCharacter()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.Health = 0
    end
end

local function teleportToPlayer(target)
    if not target or not target.Character then return end
    local root = getRoot()
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if root and targetRoot then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -5)
    end
end

createToggle(ContentFrames["Utility"], "Reset Character", false, function(state)
    if state then
        resetCharacter()
    end
end)

createToggle(ContentFrames["Utility"], "Teleport to Random Player", false, function(state)
    if state then
        local target = getRandomPlayer(true)
        teleportToPlayer(target)
    end
end)

--================================================--
-- END OF SCRIPT
--================================================--
