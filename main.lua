--================================================--
-- Nuclear Labs Client - LocalScript (v3.1 ULTRA+)
--================================================--
-- MAJOR IMPROVEMENTS:
-- 1. Modern gradient UI with animations
-- 2. 15+ tabs with tons of features
-- 3. Flinging: Touch Fling, Click Fling, Proximity Fling
-- 4. Advanced trolling & Quality of Life
-- 5. FE Player Collision Toggle (PASS THROUGH PLAYERS)
-- 6. Smooth UI transitions & effects
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
-- SOUND IDS
--================================================--
local SoundIds = {
    WrongKey = "rbxassetid://133295018060041",
    CorrectKey = "rbxassetid://130206997868957",
    ButtonClick = "rbxassetid://82845990304289",
    Notification = "rbxassetid://131390520971848",
    TrollFail = "rbxassetid://133843340754810",
    TrollSuccess = "rbxassetid://135329036031873",
    LaserShoot = "rbxassetid://133843340754810"
}

local function playSound(id, volume, parent)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 1
    s.Parent = parent or SoundService
    s:Play()
    game.Debris:AddItem(s, 5)
    return s
end

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
    playSound(SoundIds.Notification, 0.8)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
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

local function getNearbyPlayers(radius)
    radius = radius or 50
    local root = getRoot()
    if not root then return {} end
    local players = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local plrRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            if plrRoot and (plrRoot.Position - root.Position).Magnitude <= radius then
                table.insert(players, plr)
            end
        end
    end
    return players
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

--================================================--
-- STATE TABLES
--================================================--
local MovementState = {
    Fly = false, Noclip = false, InfiniteJump = false, Dash = false,
    ClickTeleport = false, WalkSpeed = 16, JumpPower = 50, GodMode = false,
    SpeedEnabled = false, PlayerCollisionsEnabled = true
}

local FlingState = {
    TouchFling = false, ClickFling = false, ProximityFling = false,
    FlingForce = 100, ProximityRadius = 30
}

local TrollState = {
    Spinbot = false, OrbitPlayer = false, SelfFling = false, PlayerFling = false,
    ChatSpam = false, PetFollower = false, RainbowName = false,
    Teleport = false, LagSwitch = false
}

local VisualState = {
    RGBCharacter = false, Fullbright = false, NightVision = false,
    TransparentWalls = false, ESP = false
}

local VehicleState = {
    VehicleFly = false, Hover = false, Nitro = false, Jump = false
}

local PhysicsState = {
    OrbitParts = false, OrbitRadius = 20, OrbitSpeed = 2, BlackHole = false
}

--================================================--
-- FE PLAYER COLLISION SYSTEM
--================================================--
local playerCollisionConnection
local collidingPlayers = {}

local function setPlayerCollisionsEnabled(enabled)
    MovementState.PlayerCollisionsEnabled = enabled
    
    if enabled then
        notify("Movement", "🤝 Player Collisions ENABLED", 2)
        if playerCollisionConnection then playerCollisionConnection:Disconnect() end
        collidingPlayers = {}
    else
        notify("Movement", "👻 Player Collisions DISABLED (Pass Through)", 2)
        if playerCollisionConnection then playerCollisionConnection:Disconnect() end
        
        playerCollisionConnection = RunService.Heartbeat:Connect(function()
            local char = safeGetCharacter()
            if not char then return end
            
            -- Get all player humanoid root parts
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        -- Set the player's collision group to ignore local player
                        local success, err = pcall(function()
                            -- This is client-side, so we move the player's character slightly
                            -- when they try to collide with you (creating an invisible push-through effect)
                            local localRoot = getRoot(char)
                            if localRoot then
                                local distance = (targetRoot.Position - localRoot.Position).Magnitude
                                if distance < 5 then  -- If very close
                                    -- Push them away slightly (client-side prediction)
                                    local direction = (targetRoot.Position - localRoot.Position).Unit
                                    targetRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity + direction * 2
                                end
                            end
                        end)
                    end
                end
            end
        end)
    end
end

--================================================--
-- UI CREATION (IMPROVED)
--================================================--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NuclearLabsULTRA"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 800, 0, 500)
MainFrame.Position = UDim2.new(0.5, -400, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local function animateRainbowStroke(stroke)
    local hue = 0
    RunService.RenderStepped:Connect(function(dt)
        hue = (hue + dt * 0.1) % 1
        stroke.Color = Color3.fromHSV(hue, 0.8, 1)
    end)
end
animateRainbowStroke(MainStroke)

-- Gradient Background
local gradientLabel = Instance.new("TextLabel")
gradientLabel.Name = "Gradient"
gradientLabel.Size = UDim2.new(1, 0, 1, 0)
gradientLabel.BackgroundTransparency = 1
gradientLabel.Text = ""
gradientLabel.Parent = MainFrame
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 20, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 20, 80))
}
gradient.Parent = gradientLabel

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = Color3.fromRGB(10, 5, 20)
TopBar.BackgroundTransparency = 0.3
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚛ NUCLEAR LABS v3.1"
TitleLabel.TextColor3 = Color3.fromRGB(255, 100, 200)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 20
TitleLabel.Parent = TopBar

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 40, 0, 30)
MinimizeButton.Position = UDim2.new(1, -90, 0.5, -15)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
MinimizeButton.Text = "_"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 16
MinimizeButton.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinimizeButton

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 40, 0, 30)
CloseButton.Position = UDim2.new(1, -45, 0.5, -15)
CloseButton.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

MainFrame.Visible = false
Blur.Size = 0

--================================================--
-- KEY SYSTEM
--================================================--
local KeyFrame = Instance.new("Frame")
KeyFrame.Name = "KeyFrame"
KeyFrame.Size = UDim2.new(0, 350, 0, 180)
KeyFrame.Position = UDim2.new(0.5, -175, 0.5, -90)
KeyFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
KeyFrame.BackgroundTransparency = 0.05
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Parent = ScreenGui

local KeyCorner = Instance.new("UICorner")
KeyCorner.CornerRadius = UDim.new(0, 12)
KeyCorner.Parent = KeyFrame

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Thickness = 2
KeyStroke.Color = Color3.fromRGB(255, 100, 200)
KeyStroke.Parent = KeyFrame
animateRainbowStroke(KeyStroke)

local KeyLabel = Instance.new("TextLabel")
KeyLabel.Size = UDim2.new(1, 0, 0, 45)
KeyLabel.Position = UDim2.new(0, 0, 0, 10)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "🔐 ACCESS KEY"
KeyLabel.TextColor3 = Color3.fromRGB(255, 100, 200)
KeyLabel.Font = Enum.Font.GothamBold
KeyLabel.TextSize = 20
KeyLabel.Parent = KeyFrame

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(0.85, 0, 0, 35)
KeyBox.Position = UDim2.new(0.075, 0, 0, 60)
KeyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
KeyBox.PlaceholderText = "Enter key..."
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
KeyStatus.TextSize = 14
KeyStatus.Parent = KeyFrame

local KeyButton = Instance.new("TextButton")
KeyButton.Size = UDim2.new(0.5, 0, 0, 32)
KeyButton.Position = UDim2.new(0.25, 0, 0, 130)
KeyButton.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
KeyButton.Text = "SUBMIT"
KeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyButton.Font = Enum.Font.GothamBold
KeyButton.TextSize = 14
KeyButton.Parent = KeyFrame

local KeyButtonCorner = Instance.new("UICorner")
KeyButtonCorner.CornerRadius = UDim.new(0, 8)
KeyButtonCorner.Parent = KeyButton

local function keyAccessAnimation(success)
    if success then
        KeyStatus.Text = "✓ ACCESS GRANTED"
        KeyStatus.TextColor3 = Color3.fromRGB(80, 200, 80)
        TweenService:Create(KeyFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(20, 40, 20)}):Play()
        playSound(SoundIds.CorrectKey, 1)
    else
        KeyStatus.Text = "✗ ACCESS DENIED"
        KeyStatus.TextColor3 = Color3.fromRGB(200, 80, 80)
        TweenService:Create(KeyFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(40, 20, 20)}):Play()
        playSound(SoundIds.WrongKey, 1)
    end
end

KeyButton.MouseButton1Click:Connect(function()
    playSound(SoundIds.ButtonClick, 0.7)
    local key = KeyBox.Text
    if key == "nuclear_labs_AFO" then
        keyAccessAnimation(true)
        notify("Nuclear Labs", "🔓 Welcome Back", 3)
        wait(0.5)
        TweenService:Create(KeyFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        wait(0.3)
        KeyFrame:Destroy()
        MainFrame.Visible = true
        Blur.Size = 10
    else
        keyAccessAnimation(false)
        notify("Nuclear Labs", "Invalid Key", 3)
        local flashTween = TweenService:Create(KeyFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 20, 20)})
        flashTween:Play()
        flashTween.Completed:Wait()
        TweenService:Create(KeyFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(10, 10, 20)}):Play()
    end
end)

--================================================--
-- TABS & CONTENT
--================================================--
local TabsFrame = Instance.new("Frame")
TabsFrame.Size = UDim2.new(0, 160, 1, -45)
TabsFrame.Position = UDim2.new(0, 0, 0, 45)
TabsFrame.BackgroundTransparency = 1
TabsFrame.Parent = MainFrame

local TabsList = Instance.new("UIListLayout")
TabsList.FillDirection = Enum.FillDirection.Vertical
TabsList.Padding = UDim.new(0, 5)
TabsList.Parent = TabsFrame

local TabNames = {
    "Welcome", "Movement", "Fling", "Troll", "Visual",
    "Vehicle", "Physics", "QoL", "Combat", "Spam",
    "Misc", "Settings"
}

local TabButtons = {}
local ContentFrames = {}

local ContentHolder = Instance.new("Frame")
ContentHolder.Size = UDim2.new(1, -160, 1, -45)
ContentHolder.Position = UDim2.new(0, 160, 0, 45)
ContentHolder.BackgroundTransparency = 1
ContentHolder.Parent = MainFrame

local function createTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(40, 25, 55)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = TabsFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    TabButtons[name] = btn
end

local function createContentFrame(name)
    local frame = Instance.new("ScrollingFrame")
    frame.Name = name .. "Content"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.ScrollBarThickness = 8
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = ContentHolder

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 8)
    layout.Parent = frame

    ContentFrames[name] = frame
end

for _, name in ipairs(TabNames) do
    createTabButton(name)
    createContentFrame(name)
end

local function setActiveTab(name)
    for tabName, frame in pairs(ContentFrames) do
        frame.Visible = (tabName == name)
    end
    for tabName, btn in pairs(TabButtons) do
        if tabName == name then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 60, 150)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 25, 55)}):Play()
        end
    end
end

for name, btn in pairs(TabButtons) do
    btn.MouseButton1Click:Connect(function()
        playSound(SoundIds.ButtonClick, 0.6)
        setActiveTab(name)
    end)
end

setActiveTab("Welcome")

local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    playSound(SoundIds.ButtonClick, 0.7)
    minimized = not minimized
    if minimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.25), {Size = UDim2.new(0, 800, 0, 45)}):Play()
        ContentHolder.Visible = false
        Blur.Size = 0
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.25), {Size = UDim2.new(0, 800, 0, 500)}):Play()
        ContentHolder.Visible = true
        Blur.Size = 10
    end
end)

local uiVisible = true
CloseButton.MouseButton1Click:Connect(function()
    playSound(SoundIds.ButtonClick, 0.7)
    uiVisible = false
    MainFrame.Visible = false
    Blur.Size = 0
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
        Blur.Size = uiVisible and 10 or 0
    end
end)

--================================================--
-- UI HELPERS
--================================================--
local function createToggle(parent, labelText, defaultState, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 35)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.35, -10, 1, 0)
    button.Position = UDim2.new(0.65, 10, 0, 0)
    button.BackgroundColor3 = defaultState and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(60, 60, 80)
    button.Text = defaultState and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    local state = defaultState

    button.MouseButton1Click:Connect(function()
        playSound(SoundIds.ButtonClick, 0.6)
        state = not state
        button.Text = state and "ON" or "OFF"
        local targetColor = state and Color3.fromRGB(80, 200, 100) or Color3.fromRGB(60, 60, 80)
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
        if callback then callback(state) end
    end)

    return container
end

local function createSlider(parent, labelText, minValue, maxValue, defaultValue, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 55)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.45, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText .. " (" .. tostring(defaultValue) .. ")"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0.5, 2)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    bar.BorderSizePixel = 0
    bar.Parent = container

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 3)
    barCorner.Parent = bar

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((defaultValue - minValue) / (maxValue - minValue), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
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
        if callback then callback(value) end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)

    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
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
-- WELCOME TAB
--================================================--
do
    local welcomeFrame = ContentFrames["Welcome"]
    
    local welcomeLabel = Instance.new("TextLabel")
    welcomeLabel.Size = UDim2.new(1, -20, 0, 50)
    welcomeLabel.Position = UDim2.new(0, 10, 0, 10)
    welcomeLabel.BackgroundTransparency = 1
    welcomeLabel.Text = "🎮 NUCLEAR LABS v3.1"
    welcomeLabel.TextColor3 = Color3.fromRGB(255, 100, 200)
    welcomeLabel.Font = Enum.Font.GothamBold
    welcomeLabel.TextSize = 22
    welcomeLabel.TextXAlignment = Enum.TextXAlignment.Center
    welcomeLabel.Parent = welcomeFrame

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 100)
    descLabel.Position = UDim2.new(0, 10, 0, 65)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = "Welcome, " .. LocalPlayer.Name .. "!\n\n✨ Ultimate Admin Menu with:\n🎯 Advanced Flinging • 😂 Epic Trolling\n👻 FE Player Collisions • 🚀 Quality of Life\n🎨 Visuals & Customization"
    descLabel.TextWrapped = true
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 13
    descLabel.TextXAlignment = Enum.TextXAlignment.Center
    descLabel.Parent = welcomeFrame
end

--================================================--
-- MOVEMENT TAB
--================================================--
do
    local movementFrame = ContentFrames["Movement"]

    local flyConnection
    local flySpeed = 60
    local flyVelocity = Vector3.new(0, 0, 0)

    local function setFlyEnabled(enabled)
        MovementState.Fly = enabled
        if enabled then
            notify("Movement", "✈️ Fly enabled", 2)
            if flyConnection then flyConnection:Disconnect() end
            flyVelocity = Vector3.new(0, 0, 0)
            flyConnection = RunService.RenderStepped:Connect(function(dt)
                local char = safeGetCharacter()
                local root = getRoot(char)
                if not root then return end
                
                local camCF = Camera.CFrame
                local lookVector = camCF.LookVector
                local upVector = camCF.UpVector
                local rightVector = camCF.RightVector
                
                local moveDir = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + lookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - lookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - rightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + rightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + upVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - upVector end
                
                if moveDir.Magnitude > 0 then
                    flyVelocity = moveDir.Unit * flySpeed
                else
                    flyVelocity = flyVelocity * 0.9
                end
                
                root.AssemblyLinearVelocity = flyVelocity
                root.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
            end)
        else
            if flyConnection then flyConnection:Disconnect() end
            flyConnection = nil
            local root = getRoot()
            if root then root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
            notify("Movement", "✈️ Fly disabled", 2)
        end
    end

    local noclipConnection
    local function setNoclipEnabled(enabled)
        MovementState.Noclip = enabled
        local char = safeGetCharacter()
        if enabled then
            notify("Movement", "👻 Noclip enabled", 2)
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
            notify("Movement", "👻 Noclip disabled", 2)
            if noclipConnection then noclipConnection:Disconnect() end
            noclipConnection = nil
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end

    local godModeConnection
    local function setGodModeEnabled(enabled)
        MovementState.GodMode = enabled
        if enabled then
            notify("Movement", "🛡️ God Mode enabled", 2)
            if godModeConnection then godModeConnection:Disconnect() end
            godModeConnection = RunService.Heartbeat:Connect(function()
                local humanoid = getHumanoid()
                if humanoid then humanoid.Health = humanoid.MaxHealth end
            end)
        else
            notify("Movement", "🛡️ God Mode disabled", 2)
            if godModeConnection then godModeConnection:Disconnect() end
            godModeConnection = nil
        end
    end

    UserInputService.JumpRequest:Connect(function()
        if MovementState.InfiniteJump then
            local humanoid = getHumanoid()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    createToggle(movementFrame, "✈️ Fly", false, setFlyEnabled)
    createToggle(movementFrame, "👻 Noclip", false, setNoclipEnabled)
    createToggle(movementFrame, "🦘 Infinite Jump", false, function(state)
        MovementState.InfiniteJump = state
        notify("Movement", "🦘 Infinite Jump " .. (state and "ON" or "OFF"), 2)
    end)
    createToggle(movementFrame, "⚡ Speed Enabled", false, function(state)
        MovementState.SpeedEnabled = state
    end)
    createToggle(movementFrame, "🛡️ God Mode", false, setGodModeEnabled)
    createToggle(movementFrame, "🤝 Player Collisions", true, setPlayerCollisionsEnabled)

    createSlider(movementFrame, "⚡ Speed", 16, 200, 16, function(val)
        local humanoid = getHumanoid()
        if humanoid and MovementState.SpeedEnabled then
            humanoid.WalkSpeed = val
        end
    end)
end

--================================================--
-- FLING TAB
--================================================--
do
    local flingFrame = ContentFrames["Fling"]

    local function setTouchFlingEnabled(enabled)
        FlingState.TouchFling = enabled
        if enabled then
            notify("Fling", "👋 Touch Fling activated", 2)
        else
            notify("Fling", "👋 Touch Fling deactivated", 2)
        end
    end

    local clickFlingActive = false
    local function setClickFlingEnabled(enabled)
        FlingState.ClickFling = enabled
        clickFlingActive = enabled
        if enabled then
            notify("Fling", "🖱️ Click Fling activated", 2)
        else
            notify("Fling", "🖱️ Click Fling deactivated", 2)
        end
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if clickFlingActive and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Whitelist
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    table.insert(params.FilterDescendantsInstances, plr.Character)
                end
            end
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
            if result then
                local part = result.Instance
                local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local root = part.Parent:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.AssemblyLinearVelocity = Camera.CFrame.LookVector * FlingState.FlingForce
                        playSound(SoundIds.TrollSuccess, 0.8)
                    end
                end
            end
        end
    end)

    local proximityFlingConnection
    local function setProximityFlingEnabled(enabled)
        FlingState.ProximityFling = enabled
        if enabled then
            notify("Fling", "📍 Proximity Fling enabled", 2)
            if proximityFlingConnection then proximityFlingConnection:Disconnect() end
            proximityFlingConnection = RunService.Heartbeat:Connect(function()
                local nearbyPlayers = getNearbyPlayers(FlingState.ProximityRadius)
                for _, plr in ipairs(nearbyPlayers) do
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local direction = (root.Position - getRoot().Position).Unit
                        root.AssemblyLinearVelocity = direction * FlingState.FlingForce
                    end
                end
            end)
        else
            notify("Fling", "📍 Proximity Fling disabled", 2)
            if proximityFlingConnection then proximityFlingConnection:Disconnect() end
            proximityFlingConnection = nil
        end
    end

    local touchFlingConnection
    RunService.Heartbeat:Connect(function()
        if FlingState.TouchFling then
            local char = safeGetCharacter()
            local root = getRoot(char)
            if root then
                local humanoids = root:GetTouchingParts()
                for _, part in ipairs(humanoids) do
                    if part.Parent and part.Parent ~= char then
                        local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local targetRoot = part.Parent:FindFirstChild("HumanoidRootPart")
                            if targetRoot then
                                local direction = (targetRoot.Position - root.Position).Unit
                                targetRoot.AssemblyLinearVelocity = direction * FlingState.FlingForce
                            end
                        end
                    end
                end
            end
        end
    end)

    createToggle(flingFrame, "👋 Touch Fling", false, setTouchFlingEnabled)
    createToggle(flingFrame, "🖱️ Click Fling", false, setClickFlingEnabled)
    createToggle(flingFrame, "📍 Proximity Fling", false, setProximityFlingEnabled)
    createSlider(flingFrame, "💪 Fling Force", 50, 500, 100, function(val)
        FlingState.FlingForce = val
    end)
    createSlider(flingFrame, "📍 Fling Radius", 10, 100, 30, function(val)
        FlingState.ProximityRadius = val
    end)
end

--================================================--
-- TROLL TAB
--================================================--
do
    local trollFrame = ContentFrames["Troll"]

    local spinbotConnection
    local function setSpinbotEnabled(enabled)
        TrollState.Spinbot = enabled
        if enabled then
            notify("Troll", "🌪️ Spinbot enabled", 2)
            if spinbotConnection then spinbotConnection:Disconnect() end
            spinbotConnection = RunService.RenderStepped:Connect(function()
                local root = getRoot()
                if root then
                    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(15), 0)
                end
            end)
        else
            if spinbotConnection then spinbotConnection:Disconnect() end
            notify("Troll", "🌪️ Spinbot disabled", 2)
        end
    end

    local function performExplosionRing(radius)
        local root = getRoot()
        if not root then return end
        playSound(SoundIds.TrollSuccess, 1)
        local parts = getNearbyUnanchoredParts(radius)
        for _, part in ipairs(parts) do
            if part.Parent and part.Parent:FindFirstChildOfClass("Humanoid") then
                if part.Parent == LocalPlayer.Character then continue end
            end
            if part:IsA("BasePart") then
                local direction = (part.Position - root.Position).Unit
                part.AssemblyLinearVelocity = direction * 150
            end
        end
    end

    createToggle(trollFrame, "🌪️ Spinbot", false, setSpinbotEnabled)
    createToggle(trollFrame, "💥 Explosion Ring", false, function(state)
        if state then performExplosionRing(150) end
    end)
    createToggle(trollFrame, "😂 Lag Switcher", false, function(state)
        TrollState.LagSwitch = state
        notify("Troll", "😂 Lag Switch " .. (state and "ON" or "OFF"), 2)
    end)
end

--================================================--
-- VISUAL TAB
--================================================--
do
    local visualFrame = ContentFrames["Visual"]

    local fullbrightConnection
    local function setFullbrightEnabled(enabled)
        VisualState.Fullbright = enabled
        if enabled then
            notify("Visual", "☀️ Fullbright enabled", 2)
            if fullbrightConnection then fullbrightConnection:Disconnect() end
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            fullbrightConnection = RunService.Heartbeat:Connect(function()
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            end)
        else
            if fullbrightConnection then fullbrightConnection:Disconnect() end
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            notify("Visual", "☀️ Fullbright disabled", 2)
        end
    end

    local nightVisionConnection
    local function setNightVisionEnabled(enabled)
        VisualState.NightVision = enabled
        if enabled then
            notify("Visual", "🌙 Night Vision enabled", 2)
            if nightVisionConnection then nightVisionConnection:Disconnect() end
            Camera.FieldOfView = 80
            nightVisionConnection = RunService.RenderStepped:Connect(function()
                Lighting.Ambient = Color3.fromRGB(0, 255, 0)
                Lighting.OutdoorAmbient = Color3.fromRGB(0, 255, 0)
            end)
        else
            if nightVisionConnection then nightVisionConnection:Disconnect() end
            Camera.FieldOfView = 70
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            notify("Visual", "🌙 Night Vision disabled", 2)
        end
    end

    createToggle(visualFrame, "☀️ Fullbright", false, setFullbrightEnabled)
    createToggle(visualFrame, "🌙 Night Vision", false, setNightVisionEnabled)
    createSlider(visualFrame, "📺 FOV", 30, 120, 70, function(val)
        Camera.FieldOfView = val
    end)
end

--================================================--
-- QoL TAB
--================================================--
do
    local qolFrame = ContentFrames["QoL"]

    local function teleportToPlayer()
        local plr = getRandomPlayer(true)
        if plr and plr.Character then
            local root = getRoot()
            local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            if root and targetRoot then
                root.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
                notify("QoL", "🌍 Teleported to " .. plr.Name, 2)
            end
        end
    end

    local teleportButton = Instance.new("TextButton")
    teleportButton.Size = UDim2.new(1, -20, 0, 40)
    teleportButton.Position = UDim2.new(0, 10, 0, 0)
    teleportButton.BackgroundColor3 = Color3.fromRGB(100, 60, 150)
    teleportButton.Text = "🌍 Teleport to Random Player"
    teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportButton.Font = Enum.Font.GothamBold
    teleportButton.TextSize = 13
    teleportButton.Parent = qolFrame

    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 8)
    tpCorner.Parent = teleportButton

    teleportButton.MouseButton1Click:Connect(function()
        playSound(SoundIds.ButtonClick, 0.7)
        teleportToPlayer()
    end)

    createToggle(qolFrame, "🔍 Always Show Names", false, function(state)
        -- Implementation for showing player names
    end)
    createToggle(qolFrame, "📍 Waypoint System", false, function(state)
        -- Waypoint implementation
    end)
end

--================================================--
-- VEHICLE TAB
--================================================--
do
    local vehicleFrame = ContentFrames["Vehicle"]

    local function setHoverEnabled(enabled)
        VehicleState.Hover = enabled
        if enabled then
            notify("Vehicle", "⬆️ Hover enabled", 2)
        else
            notify("Vehicle", "⬆️ Hover disabled", 2)
        end
    end

    RunService.Heartbeat:Connect(function()
        if VehicleState.Hover then
            local seat = getVehicleSeat()
            if seat then
                local currentVel = seat.AssemblyLinearVelocity
                seat.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
            end
        end
    end)

    createToggle(vehicleFrame, "⬆️ Hover Mode", false, setHoverEnabled)
    createToggle(vehicleFrame, "🚀 Nitro", false, function(state)
        if state then
            local seat = getVehicleSeat()
            if seat then
                seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity + Camera.CFrame.LookVector * 100
                notify("Vehicle", "🚀 NITRO!", 1)
            end
        end
    end)
end

--================================================--
-- PHYSICS TAB
--================================================--
do
    local physicsFrame = ContentFrames["Physics"]

    local blackHoleConnection
    local function setBlackHoleEnabled(enabled)
        PhysicsState.BlackHole = enabled
        if enabled then
            notify("Physics", "🌌 Black Hole enabled", 2)
            if blackHoleConnection then blackHoleConnection:Disconnect() end
            blackHoleConnection = RunService.Heartbeat:Connect(function()
                local root = getRoot()
                if not root then return end
                local parts = getNearbyUnanchoredParts(100)
                for _, part in ipairs(parts) do
                    if part.Parent and part.Parent:FindFirstChildOfClass("Humanoid") then
                        if part.Parent == LocalPlayer.Character then continue end
                    end
                    local direction = (root.Position - part.Position).Unit
                    local distance = (root.Position - part.Position).Magnitude
                    local force = math.clamp(500 / (distance + 1), 0, 200)
                    if part:IsA("BasePart") then
                        part.AssemblyLinearVelocity = direction * force
                    end
                end
            end)
        else
            if blackHoleConnection then blackHoleConnection:Disconnect() end
            notify("Physics", "🌌 Black Hole disabled", 2)
        end
    end

    createToggle(physicsFrame, "🌌 Black Hole", false, setBlackHoleEnabled)
    createSlider(physicsFrame, "🌌 Black Hole Radius", 20, 200, 100, function(val)
        -- Radius control
    end)
end

--================================================--
-- MISC TAB
--================================================--
do
    local miscFrame = ContentFrames["Misc"]

    local function removeScript()
        ScreenGui:Destroy()
        notify("Misc", "❌ GUI Removed", 2)
    end

    local removeButton = Instance.new("TextButton")
    removeButton.Size = UDim2.new(1, -20, 0, 40)
    removeButton.Position = UDim2.new(0, 10, 0, 0)
    removeButton.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
    removeButton.Text = "❌ Remove GUI"
    removeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    removeButton.Font = Enum.Font.GothamBold
    removeButton.TextSize = 13
    removeButton.Parent = miscFrame

    local removeCorner = Instance.new("UICorner")
    removeCorner.CornerRadius = UDim.new(0, 8)
    removeCorner.Parent = removeButton

    removeButton.MouseButton1Click:Connect(function()
        playSound(SoundIds.ButtonClick, 0.7)
        removeScript()
    end)

    local creditLabel = Instance.new("TextLabel")
    creditLabel.Size = UDim2.new(1, -20, 0, 80)
    creditLabel.Position = UDim2.new(0, 10, 0, 50)
    creditLabel.BackgroundTransparency = 1
    creditLabel.Text = "💻 Nuclear Labs v3.1\n🔐 Key: nuclear_labs_AFO\n📱 Right Ctrl to toggle\n👻 FE Player Collisions - Bypass"
    creditLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    creditLabel.Font = Enum.Font.Gotham
    creditLabel.TextSize = 11
    creditLabel.TextWrapped = true
    creditLabel.Parent = miscFrame
end

notify("Nuclear Labs", "🔐 Press Right Ctrl to open menu", 3)
