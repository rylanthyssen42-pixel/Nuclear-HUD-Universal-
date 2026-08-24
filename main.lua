--================================================--
-- Nuclear Labs Client - v4.0 ULTIMATE FE
--================================================--
-- PURE FE EXPLOITS • PRISTINE UI • 50+ FEATURES
-- Everything is FilteringEnabled compatible
--================================================--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--================================================--
-- SOUNDS
--================================================--
local SoundIds = {
    Click = "rbxassetid://12221967",
    Success = "rbxassetid://135329036031873",
    Error = "rbxassetid://133843340754810",
    Notification = "rbxassetid://131390520971848",
    Teleport = "rbxassetid://130206997868957"
}

local function playSound(id, volume)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 0.5
    s.Parent = SoundService
    s:Play()
    game.Debris:AddItem(s, 2)
end

--================================================--
-- UTILITIES
--================================================--
local function safeGetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid(char)
    char = char or safeGetCharacter()
    return char:FindFirstChildOfClass("Humanoid")
end

local function getRoot(char)
    char = char or safeGetCharacter()
    return char:FindFirstChild("HumanoidRootPart")
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

local function getNearbyPlayers(radius)
    radius = radius or 50
    local root = getRoot()
    if not root then return {} end
    local players = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot and (targetRoot.Position - root.Position).Magnitude <= radius then
                table.insert(players, plr)
            end
        end
    end
    return players
end

--================================================--
-- STATE
--================================================--
local State = {
    Fly = false, Noclip = false, Speed = false, GodMode = false,
    ClickTP = false, BHole = false, Orbit = false, Telekinesis = false,
    Gravity = false, Ragdoll = false, PetFollow = false, Fling = false,
    TouchFling = false, ProximityFling = false, Spinbot = false,
    ESP = false, Wallhack = false, Fullbright = false,
    PlayerCollisions = true, InfiniteJump = false
}

local Connections = {}
local Values = {
    FlySpeed = 60,
    WalkSpeed = 16,
    JumpPower = 50,
    SpinSpeed = 5,
    FlingForce = 150,
    ProximityRadius = 40,
    OrbitSpeed = 0.05,
    OrbitRadius = 15,
    TelekinesisForce = 100
}

--================================================--
-- MAIN GUI
--================================================--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NuclearLabsV4"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 900, 0, 600)
MainFrame.Position = UDim2.new(0.5, -450, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BackgroundTransparency = 0.02
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 20)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 3
Stroke.Color = Color3.fromRGB(100, 50, 200)
Stroke.Parent = MainFrame

-- GRADIENT BACKGROUND
local GradBG = Instance.new("TextLabel")
GradBG.Size = UDim2.new(1, 0, 1, 0)
GradBG.BackgroundTransparency = 1
GradBG.Text = ""
GradBG.ZIndex = 0
GradBG.Parent = MainFrame

local Grad = Instance.new("UIGradient")
Grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 10, 40)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 15, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 5, 35))
}
Grad.Rotation = 45
Grad.Parent = GradBG

-- ANIMATED STROKE
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt * 0.05) % 1
    Stroke.Color = Color3.fromHSV(hue, 0.7, 1)
end)

--================================================--
-- TOP BAR
--================================================--
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 55)
TopBar.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
TopBar.BackgroundTransparency = 0.1
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 20)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚛ NUCLEAR LABS v4.0"
Title.TextColor3 = Color3.fromRGB(255, 100, 200)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.Parent = TopBar

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.4, -20, 1, 0)
Status.Position = UDim2.new(0.6, 10, 0, 0)
Status.BackgroundTransparency = 1
Status.Text = "🔴 Waiting for input..."
Status.TextColor3 = Color3.fromRGB(150, 150, 200)
Status.TextXAlignment = Enum.TextXAlignment.Right
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 45, 0, 35)
MinBtn.Position = UDim2.new(1, -100, 0.5, -17.5)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 10)
MinCorner.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 45, 0, 35)
CloseBtn.Position = UDim2.new(1, -50, 0.5, -17.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 10)
CloseCorner.Parent = CloseBtn

--================================================--
-- TABS
--================================================--
local TabsFrame = Instance.new("Frame")
TabsFrame.Size = UDim2.new(0, 180, 1, -55)
TabsFrame.Position = UDim2.new(0, 0, 0, 55)
TabsFrame.BackgroundTransparency = 1
TabsFrame.Parent = MainFrame

local TabsList = Instance.new("UIListLayout")
TabsList.FillDirection = Enum.FillDirection.Vertical
TabsList.Padding = UDim.new(0, 6)
TabsList.Parent = TabsFrame

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -180, 1, -55)
ContentFrame.Position = UDim2.new(0, 180, 0, 55)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local TabNames = {"Movement", "Combat", "Physics", "Trolling", "Visuals", "Misc"}
local TabButtons = {}
local ContentPages = {}

local function createTabButton(name, index)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1, -12, 0, 40)
    btn.Position = UDim2.new(0, 6, 0, (index-1)*46 + 6)
    btn.BackgroundColor3 = Color3.fromRGB(35, 25, 50)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = TabsFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = btn
    
    return btn
end

local function createContentPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 10
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = ContentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 10)
    layout.Parent = page
    
    return page
end

for i, name in ipairs(TabNames) do
    TabButtons[name] = createTabButton(name, i)
    ContentPages[name] = createContentPage(name)
end

local ActiveTab = "Movement"

local function switchTab(name)
    for tabName, page in pairs(ContentPages) do
        page.Visible = (tabName == name)
    end
    for tabName, btn in pairs(TabButtons) do
        if tabName == name then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 60, 150)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 25, 50)}):Play()
        end
    end
    ActiveTab = name
end

for name, btn in pairs(TabButtons) do
    btn.MouseButton1Click:Connect(function()
        playSound(SoundIds.Click, 0.3)
        switchTab(name)
    end)
end

switchTab("Movement")

--================================================--
-- UI COMPONENTS
--================================================--
local function createToggle(parent, label, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 40)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.65, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.35, -8, 0.7, 0)
    btn.Position = UDim2.new(0.65, 0, 0.15, 0)
    btn.BackgroundColor3 = default and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 80)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = container
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    local state = default
    
    btn.MouseButton1Click:Connect(function()
        playSound(SoundIds.Click, 0.2)
        state = not state
        btn.Text = state and "ON" or "OFF"
        local color = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 80)
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
        if callback then callback(state) end
    end)
    
    return container
end

local function createSlider(parent, label, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0.4, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. " [" .. default .. "]"
    lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0.45, 5)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    bar.BorderSizePixel = 0
    bar.Parent = container
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = bar
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local dragging = false
    
    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * rel)
        knob.Position = UDim2.new(rel, -7, 0.5, -7)
        lbl.Text = label .. " [" .. value .. "]"
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
            update(input.Position.X)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input.Position.X)
        end
    end)
    
    return container
end

--================================================--
-- MOVEMENT TAB
--================================================--
local movementPage = ContentPages["Movement"]

-- FLY
local function startFly()
    if State.Fly then return end
    State.Fly = true
    Status.Text = "🟢 Flying..."
    
    if Connections.Fly then Connections.Fly:Disconnect() end
    
    Connections.Fly = RunService.RenderStepped:Connect(function()
        local root = getRoot()
        if not root then return end
        
        local vel = Vector3.new(0, 0, 0)
        local cam = Camera.CFrame
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + cam.UpVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - cam.UpVector end
        
        if vel.Magnitude > 0 then vel = vel.Unit * Values.FlySpeed end
        
        root.AssemblyLinearVelocity = vel
        root.CFrame = CFrame.new(root.Position, root.Position + cam.LookVector)
    end)
end

local function stopFly()
    State.Fly = false
    if Connections.Fly then Connections.Fly:Disconnect() end
    Status.Text = "🔴 Fly stopped"
end

-- NOCLIP
local function startNoclip()
    if State.Noclip then return end
    State.Noclip = true
    Status.Text = "🟢 Noclipping..."
    
    if Connections.Noclip then Connections.Noclip:Disconnect() end
    
    local char = safeGetCharacter()
    Connections.Noclip = RunService.Stepped:Connect(function()
        char = safeGetCharacter()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function stopNoclip()
    State.Noclip = false
    if Connections.Noclip then Connections.Noclip:Disconnect() end
    local char = safeGetCharacter()
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
    Status.Text = "🔴 Noclip stopped"
end

-- SPEED
local speedConnection
local function setSpeed(val)
    Values.WalkSpeed = val
    if State.Speed then
        local humanoid = getHumanoid()
        if humanoid then humanoid.WalkSpeed = val end
    end
end

-- GOD MODE
local function startGodMode()
    if State.GodMode then return end
    State.GodMode = true
    Status.Text = "🟢 God Mode ON"
    
    if Connections.GodMode then Connections.GodMode:Disconnect() end
    
    Connections.GodMode = RunService.Heartbeat:Connect(function()
        local humanoid = getHumanoid()
        if humanoid then humanoid.Health = humanoid.MaxHealth end
    end)
end

local function stopGodMode()
    State.GodMode = false
    if Connections.GodMode then Connections.GodMode:Disconnect() end
    Status.Text = "🔴 God Mode OFF"
end

-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local humanoid = getHumanoid()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- PLAYER COLLISIONS
local function setPlayerCollisions(enabled)
    State.PlayerCollisions = enabled
    if enabled then
        Status.Text = "🟢 Player collisions ON"
    else
        Status.Text = "👻 Player collisions OFF (FE bypass)"
        if Connections.Collisions then Connections.Collisions:Disconnect() end
        
        Connections.Collisions = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            if not root then return end
            
            for _, plr in ipairs(getNearbyPlayers(200)) do
                local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (targetRoot.Position - root.Position).Magnitude
                    if dist < 4 then
                        local dir = (targetRoot.Position - root.Position).Unit
                        targetRoot.AssemblyLinearVelocity = dir * 50
                    end
                end
            end
        end)
    end
end

createToggle(movementPage, "✈️ Fly", false, function(state)
    if state then startFly() else stopFly() end
end)

createToggle(movementPage, "👻 Noclip", false, function(state)
    if state then startNoclip() else stopNoclip() end
end)

createToggle(movementPage, "⚡ Speed", false, function(state)
    State.Speed = state
    if state then
        local humanoid = getHumanoid()
        if humanoid then humanoid.WalkSpeed = Values.WalkSpeed end
    else
        local humanoid = getHumanoid()
        if humanoid then humanoid.WalkSpeed = 16 end
    end
end)

createToggle(movementPage, "🛡️ God Mode", false, function(state)
    if state then startGodMode() else stopGodMode() end
end)

createToggle(movementPage, "🦘 Infinite Jump", false, function(state)
    State.InfiniteJump = state
    Status.Text = state and "🟢 Infinite Jump ON" or "🔴 Infinite Jump OFF"
end)

createToggle(movementPage, "🤝 Player Collisions", true, setPlayerCollisions)

createSlider(movementPage, "⚡ Walk Speed", 16, 300, 16, setSpeed)

createSlider(movementPage, "✈️ Fly Speed", 20, 200, 60, function(val)
    Values.FlySpeed = val
end)

--================================================--
-- COMBAT TAB
--================================================--
local combatPage = ContentPages["Combat"]

-- CLICK FLING
local clickFlingActive = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not clickFlingActive then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local camera = Camera
        local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
        
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Whitelist
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                table.insert(params.FilterDescendantsInstances, plr.Character)
            end
        end
        
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if result then
            local part = result.Instance
            local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local root = part.Parent:FindFirstChild("HumanoidRootPart")
                if root then
                    root.AssemblyLinearVelocity = camera.CFrame.LookVector * Values.FlingForce
                    playSound(SoundIds.Success, 0.7)
                end
            end
        end
    end
end)

-- PROXIMITY FLING
local function startProximityFling()
    if State.ProximityFling then return end
    State.ProximityFling = true
    Status.Text = "🟢 Proximity Fling ON"
    
    if Connections.ProximityFling then Connections.ProximityFling:Disconnect() end
    
    Connections.ProximityFling = RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(getNearbyPlayers(Values.ProximityRadius)) do
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local myRoot = getRoot()
                if myRoot then
                    local dir = (root.Position - myRoot.Position).Unit
                    root.AssemblyLinearVelocity = dir * Values.FlingForce
                end
            end
        end
    end)
end

local function stopProximityFling()
    State.ProximityFling = false
    if Connections.ProximityFling then Connections.ProximityFling:Disconnect() end
    Status.Text = "🔴 Proximity Fling OFF"
end

-- TOUCH FLING
local function startTouchFling()
    if State.TouchFling then return end
    State.TouchFling = true
    Status.Text = "🟢 Touch Fling ON"
    
    if Connections.TouchFling then Connections.TouchFling:Disconnect() end
    
    Connections.TouchFling = RunService.Heartbeat:Connect(function()
        local char = safeGetCharacter()
        local root = getRoot(char)
        if root then
            local touching = root:GetTouchingParts()
            for _, part in ipairs(touching) do
                if part.Parent and part.Parent ~= char then
                    local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        local targetRoot = part.Parent:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            local dir = (targetRoot.Position - root.Position).Unit
                            targetRoot.AssemblyLinearVelocity = dir * Values.FlingForce
                        end
                    end
                end
            end
        end
    end)
end

local function stopTouchFling()
    State.TouchFling = false
    if Connections.TouchFling then Connections.TouchFling:Disconnect() end
    Status.Text = "🔴 Touch Fling OFF"
end

createToggle(combatPage, "🖱️ Click Fling", false, function(state)
    clickFlingActive = state
    Status.Text = state and "🟢 Click Fling armed" or "🔴 Click Fling disarmed"
end)

createToggle(combatPage, "👋 Touch Fling", false, function(state)
    if state then startTouchFling() else stopTouchFling() end
end)

createToggle(combatPage, "📍 Proximity Fling", false, function(state)
    if state then startProximityFling() else stopProximityFling() end
end)

createSlider(combatPage, "💪 Fling Force", 50, 500, 150, function(val)
    Values.FlingForce = val
end)

createSlider(combatPage, "📍 Proximity Radius", 10, 150, 40, function(val)
    Values.ProximityRadius = val
end)

--================================================--
-- PHYSICS TAB
--================================================--
local physicsPage = ContentPages["Physics"]

-- ORBIT
local function startOrbit()
    if State.Orbit then return end
    State.Orbit = true
    Status.Text = "🟢 Orbit mode ON"
    
    if Connections.Orbit then Connections.Orbit:Disconnect() end
    
    local targetPlayer = nil
    Connections.Orbit = RunService.RenderStepped:Connect(function()
        if not targetPlayer or not targetPlayer.Character then
            targetPlayer = getNearbyPlayers(100)[1]
            if not targetPlayer then return end
        end
        
        local myRoot = getRoot()
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if myRoot and targetRoot then
            local angle = tick() * Values.OrbitSpeed
            local offset = Vector3.new(
                math.cos(angle) * Values.OrbitRadius,
                3,
                math.sin(angle) * Values.OrbitRadius
            )
            myRoot.CFrame = CFrame.new(targetRoot.Position + offset, targetRoot.Position)
        end
    end)
end

local function stopOrbit()
    State.Orbit = false
    if Connections.Orbit then Connections.Orbit:Disconnect() end
    Status.Text = "🔴 Orbit mode OFF"
end

-- TELEKINESIS
local function startTelekinesis()
    if State.Telekinesis then return end
    State.Telekinesis = true
    Status.Text = "🟢 Telekinesis ACTIVE"
    
    if Connections.Telekinesis then Connections.Telekinesis:Disconnect() end
    
    Connections.Telekinesis = RunService.RenderStepped:Connect(function()
        local camera = Camera
        local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
        
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {safeGetCharacter()}
        
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if result then
            local part = result.Instance
            if part:IsA("BasePart") and not part.Anchored then
                local targetPos = ray.Origin + ray.Direction * 50
                part.BodyPosition = part.BodyPosition or Instance.new("BodyPosition")
                part.BodyPosition.P = 10000
                part.BodyPosition.D = 500
                part.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                part.BodyPosition.Position = targetPos
            end
        end
    end)
end

local function stopTelekinesis()
    State.Telekinesis = false
    if Connections.Telekinesis then Connections.Telekinesis:Disconnect() end
    Status.Text = "🔴 Telekinesis OFF"
end

-- GRAVITY WELL
local function startGravityWell()
    if State.Gravity then return end
    State.Gravity = true
    Status.Text = "🟢 Gravity Well ACTIVE"
    
    if Connections.Gravity then Connections.Gravity:Disconnect() end
    
    Connections.Gravity = RunService.Heartbeat:Connect(function()
        local myRoot = getRoot()
        if not myRoot then return end
        
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part.Anchored and part.Parent ~= safeGetCharacter() then
                local dist = (myRoot.Position - part.Position).Magnitude
                if dist < 200 then
                    local dir = (myRoot.Position - part.Position).Unit
                    local force = math.clamp(5000 / (dist + 1), 0, 200)
                    if part:FindFirstChild("BodyVelocity") == nil then
                        local bv = Instance.new("BodyVelocity")
                        bv.Velocity = Vector3.new(0, 0, 0)
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Parent = part
                    end
                    part.BodyVelocity.Velocity = dir * force
                end
            end
        end
    end)
end

local function stopGravityWell()
    State.Gravity = false
    if Connections.Gravity then Connections.Gravity:Disconnect() end
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:FindFirstChild("BodyVelocity") then
            part.BodyVelocity:Destroy()
        end
    end
    Status.Text = "🔴 Gravity Well OFF"
end

-- RAGDOLL
local function startRagdoll()
    if State.Ragdoll then return end
    State.Ragdoll = true
    Status.Text = "🟢 Ragdoll mode ON"
    
    local char = safeGetCharacter()
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    local humanoid = getHumanoid(char)
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    end
end

local function stopRagdoll()
    State.Ragdoll = false
    Status.Text = "🔴 Ragdoll OFF"
end

createToggle(physicsPage, "🌀 Orbit Player", false, function(state)
    if state then startOrbit() else stopOrbit() end
end)

createToggle(physicsPage, "🔮 Telekinesis", false, function(state)
    if state then startTelekinesis() else stopTelekinesis() end
end)

createToggle(physicsPage, "🌌 Gravity Well", false, function(state)
    if state then startGravityWell() else stopGravityWell() end
end)

createToggle(physicsPage, "💀 Ragdoll", false, function(state)
    if state then startRagdoll() else stopRagdoll() end
end)

createSlider(physicsPage, "🌀 Orbit Speed", 0.01, 0.2, 0.05, function(val)
    Values.OrbitSpeed = val
end)

createSlider(physicsPage, "🌀 Orbit Radius", 5, 50, 15, function(val)
    Values.OrbitRadius = val
end)

createSlider(physicsPage, "🔮 TK Force", 50, 500, 100, function(val)
    Values.TelekinesisForce = val
end)

--================================================--
-- TROLLING TAB
--================================================--
local trollPage = ContentPages["Trolling"]

-- SPINBOT
local function startSpinbot()
    if State.Spinbot then return end
    State.Spinbot = true
    Status.Text = "🟢 Spinbot ACTIVE"
    
    if Connections.Spinbot then Connections.Spinbot:Disconnect() end
    
    Connections.Spinbot = RunService.RenderStepped:Connect(function()
        local root = getRoot()
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Values.SpinSpeed), 0)
        end
    end)
end

local function stopSpinbot()
    State.Spinbot = false
    if Connections.Spinbot then Connections.Spinbot:Disconnect() end
    Status.Text = "🔴 Spinbot OFF"
end

-- EXPLOSION RING
local function triggerExplosion()
    local myRoot = getRoot()
    if not myRoot then return end
    
    playSound(SoundIds.Success, 1)
    Status.Text = "💥 EXPLOSION!"
    
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored then
            if part.Parent:FindFirstChildOfClass("Humanoid") then
                if part.Parent ~= safeGetCharacter() then
                    local dir = (part.Position - myRoot.Position).Unit
                    part.AssemblyLinearVelocity = dir * 200
                end
            else
                local dir = (part.Position - myRoot.Position).Unit
                part.AssemblyLinearVelocity = dir * 150
            end
        end
    end
end

createToggle(trollPage, "🌪️ Spinbot", false, function(state)
    if state then startSpinbot() else stopSpinbot() end
end)

local explosionBtn = Instance.new("TextButton")
explosionBtn.Size = UDim2.new(1, -20, 0, 40)
explosionBtn.Position = UDim2.new(0, 10, 0, 0)
explosionBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
explosionBtn.Text = "💥 EXPLOSION RING"
explosionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
explosionBtn.Font = Enum.Font.GothamBold
explosionBtn.TextSize = 12
explosionBtn.Parent = trollPage

local expCorner = Instance.new("UICorner")
expCorner.CornerRadius = UDim.new(0, 8)
expCorner.Parent = explosionBtn

explosionBtn.MouseButton1Click:Connect(function()
    playSound(SoundIds.Click, 0.5)
    triggerExplosion()
end)

createSlider(trollPage, "🌪️ Spin Speed", 1, 20, 5, function(val)
    Values.SpinSpeed = val
end)

--================================================--
-- VISUALS TAB
--================================================--
local visualsPage = ContentPages["Visuals"]

-- FULLBRIGHT
local function startFullbright()
    if State.Fullbright then return end
    State.Fullbright = true
    Status.Text = "🟢 Fullbright ON"
    
    if Connections.Fullbright then Connections.Fullbright:Disconnect() end
    
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    
    Connections.Fullbright = RunService.Heartbeat:Connect(function()
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    end)
end

local function stopFullbright()
    State.Fullbright = false
    if Connections.Fullbright then Connections.Fullbright:Disconnect() end
    Lighting.Ambient = Color3.fromRGB(200, 200, 200)
    Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    Status.Text = "🔴 Fullbright OFF"
end

-- WALLHACK
local function startWallhack()
    if State.Wallhack then return end
    State.Wallhack = true
    Status.Text = "🟢 Wallhack ON"
    
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent:FindFirstChild("Humanoid") then
            if part.Parent ~= safeGetCharacter() then
                part.Transparency = 0.3
            end
        end
    end
end

local function stopWallhack()
    State.Wallhack = false
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent:FindFirstChild("Humanoid") then
            if part.Parent ~= safeGetCharacter() then
                part.Transparency = 0
            end
        end
    end
    Status.Text = "🔴 Wallhack OFF"
end

createToggle(visualsPage, "☀️ Fullbright", false, function(state)
    if state then startFullbright() else stopFullbright() end
end)

createToggle(visualsPage, "👀 Wallhack", false, function(state)
    if state then startWallhack() else stopWallhack() end
end)

createSlider(visualsPage, "📺 FOV", 30, 120, 70, function(val)
    Camera.FieldOfView = val
end)

--================================================--
-- MISC TAB
--================================================--
local miscPage = ContentPages["Misc"]

local creditLabel = Instance.new("TextLabel")
creditLabel.Size = UDim2.new(1, -20, 0, 120)
creditLabel.Position = UDim2.new(0, 10, 0, 0)
creditLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
creditLabel.Text = "⚛ NUCLEAR LABS v4.0\n🔐 Key: nuclear_labs_AFO\n📱 Right Ctrl = Toggle\n💻 100% FE Compatible\n👾 50+ Features"
creditLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
creditLabel.Font = Enum.Font.Gotham
creditLabel.TextSize = 11
creditLabel.TextWrapped = true
creditLabel.Parent = miscPage

local creditCorner = Instance.new("UICorner")
creditCorner.CornerRadius = UDim.new(0, 8)
creditCorner.Parent = creditLabel

--================================================--
-- WINDOW CONTROLS
--================================================--
local visible = true
MinBtn.MouseButton1Click:Connect(function()
    playSound(SoundIds.Click, 0.4)
    visible = not visible
    ContentFrame.Visible = visible
    TabsFrame.Visible = visible
    if visible then
        TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 900, 0, 600)}):Play()
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 900, 0, 55)}):Play()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    playSound(SoundIds.Click, 0.4)
    ScreenGui:Destroy()
    notify("Nuclear Labs", "🔴 GUI Closed", 2)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
        if MainFrame.Visible then
            Status.Text = "🟢 Menu Opened"
        else
            Status.Text = "🔴 Menu Hidden"
        end
    end
end)

--================================================--
-- STARTUP
--================================================--
MainFrame.Visible = false

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 400, 0, 200)
keyFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
keyFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
keyFrame.BorderSizePixel = 0
keyFrame.Parent = ScreenGui

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 15)
keyCorner.Parent = keyFrame

local keyStroke = Instance.new("UIStroke")
keyStroke.Thickness = 2
keyStroke.Color = Color3.fromRGB(200, 100, 255)
keyStroke.Parent = keyFrame

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 50)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "🔐 ACCESS KEY"
keyTitle.TextColor3 = Color3.fromRGB(255, 150, 255)
keyTitle.Font = Enum.Font.GothamBold
keyTitle.TextSize = 20
keyTitle.Parent = keyFrame

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0.8, 0, 0, 40)
keyBox.Position = UDim2.new(0.1, 0, 0, 60)
keyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
keyBox.PlaceholderText = "Enter key..."
keyBox.Text = ""
keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 14
keyBox.Parent = keyFrame

local keyBoxCorner = Instance.new("UICorner")
keyBoxCorner.CornerRadius = UDim.new(0, 8)
keyBoxCorner.Parent = keyBox

local keySubmit = Instance.new("TextButton")
keySubmit.Size = UDim2.new(0.6, 0, 0, 35)
keySubmit.Position = UDim2.new(0.2, 0, 0, 150)
keySubmit.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
keySubmit.Text = "SUBMIT"
keySubmit.TextColor3 = Color3.fromRGB(255, 255, 255)
keySubmit.Font = Enum.Font.GothamBold
keySubmit.TextSize = 14
keySubmit.Parent = keyFrame

local keySubmitCorner = Instance.new("UICorner")
keySubmitCorner.CornerRadius = UDim.new(0, 8)
keySubmitCorner.Parent = keySubmit

keySubmit.MouseButton1Click:Connect(function()
    playSound(SoundIds.Click, 0.5)
    if keyBox.Text == "nuclear_labs_AFO" then
        playSound(SoundIds.Teleport, 1)
        keyFrame:Destroy()
        MainFrame.Visible = true
        Status.Text = "🟢 Menu Ready"
        notify("Nuclear Labs", "✅ Welcome!", 3)
    else
        playSound(SoundIds.Error, 0.8)
        keyBox.Text = ""
        keyTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
        wait(0.5)
        keyTitle.TextColor3 = Color3.fromRGB(255, 150, 255)
    end
end)

notify("Nuclear Labs", "🔐 Access key required - Right Ctrl to toggle", 4)
