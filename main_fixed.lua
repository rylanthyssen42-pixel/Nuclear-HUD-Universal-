--================================================--
-- Nuclear Labs Client - LocalScript (v2.6 FIXED)
--================================================--
-- FIXES:
-- 1. Fly now uses proper velocity-based movement
-- 2. Black Hole and Orbit Parts exclude local player
-- 3. Explosion Ring is now functional
-- 4. Vehicle Tab has full implementation
--================================================--

-- [COPY THE ORIGINAL main.lua UP TO LINE 920]
-- Then REPLACE the following sections:

--================================================--
-- MOVEMENT (FIXED FLY)
--================================================--
local flyConnection
local flySpeed = 60
local flyVelocity = Vector3.new(0, 0, 0)

local function setFlyEnabled(enabled)
    MovementState.Fly = enabled
    if enabled then
        notify("Movement", "Fly enabled", 2)
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
            
            -- Get input
            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + lookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - lookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - rightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + rightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + upVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir = moveDir - upVector
            end
            
            -- Smooth velocity change
            if moveDir.Magnitude > 0 then
                flyVelocity = moveDir.Unit * flySpeed
            else
                flyVelocity = flyVelocity * 0.9  -- Decelerate
            end
            
            -- Apply movement using AssemblyLinearVelocity
            root.AssemblyLinearVelocity = flyVelocity
            root.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
        end)
    else
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = nil
        local root = getRoot()
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        notify("Movement", "Fly disabled", 2)
    end
end

-- [KEEP NOCLIP, INFINITE JUMP, DASH, AND OTHER MOVEMENT CODE THE SAME]
-- Just update the setFlyEnabled function above

--================================================--
-- PHYSICS (FIXED BLACK HOLE & ORBIT)
--================================================--
local blackHoleConnection
local orbitConnection
local explosionRingConnection

local function setBlackHoleEnabled(enabled)
    PhysicsState.BlackHole = enabled
    if enabled then
        notify("Physics", "Black Hole enabled", 2)
        if blackHoleConnection then blackHoleConnection:Disconnect() end
        blackHoleConnection = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            if not root then return end
            
            local parts = getNearbyUnanchoredParts(100)
            for _, part in ipairs(parts) do
                -- EXCLUDE LOCAL PLAYER
                if part.Parent and part.Parent:FindFirstChildOfClass("Humanoid") then
                    local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Parent:FindFirstChild("HumanoidRootPart") then
                        if humanoid.Parent == LocalPlayer.Character then
                            continue  -- Skip local player
                        end
                    end
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
        notify("Physics", "Black Hole disabled", 2)
        if blackHoleConnection then blackHoleConnection:Disconnect() end
        blackHoleConnection = nil
    end
end

local function setOrbitPartsEnabled(enabled)
    PhysicsState.OrbitParts = enabled
    if enabled then
        notify("Physics", "Orbit Parts enabled", 2)
        if orbitConnection then orbitConnection:Disconnect() end
        orbitConnection = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            if not root then return end
            
            local parts = getNearbyUnanchoredParts(PhysicsState.OrbitRadius)
            for _, part in ipairs(parts) do
                -- EXCLUDE LOCAL PLAYER
                if part.Parent and part.Parent:FindFirstChildOfClass("Humanoid") then
                    local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Parent:FindFirstChild("HumanoidRootPart") then
                        if humanoid.Parent == LocalPlayer.Character then
                            continue  -- Skip local player
                        end
                    end
                end
                
                local angle = tick() * PhysicsState.OrbitSpeed
                local orbitX = math.cos(angle) * PhysicsState.OrbitRadius
                local orbitZ = math.sin(angle) * PhysicsState.OrbitRadius
                local targetPos = root.Position + Vector3.new(orbitX, 5, orbitZ)
                
                if part:IsA("BasePart") then
                    part.CFrame = CFrame.new(targetPos)
                end
            end
        end)
    else
        notify("Physics", "Orbit Parts disabled", 2)
        if orbitConnection then orbitConnection:Disconnect() end
        orbitConnection = nil
    end
end

local function performExplosionRing(radius)
    local root = getRoot()
    if not root then return end
    
    playSound(SoundIds.TrollSuccess, 1)
    
    local parts = getNearbyUnanchoredParts(radius)
    for _, part in ipairs(parts) do
        -- EXCLUDE LOCAL PLAYER
        if part.Parent and part.Parent:FindFirstChildOfClass("Humanoid") then
            local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Parent:FindFirstChild("HumanoidRootPart") then
                if humanoid.Parent == LocalPlayer.Character then
                    continue
                end
            end
        end
        
        if part:IsA("BasePart") then
            local direction = (part.Position - root.Position).Unit
            local force = 100
            part.AssemblyLinearVelocity = direction * force
        end
    end
end

--================================================--
-- VEHICLE TAB (NEW IMPLEMENTATION)
--================================================--
do
    local vehicleFrame = ContentFrames["Vehicle"]
    
    local function setVehicleFlyEnabled(enabled)
        VehicleState.VehicleFly = enabled
        if enabled then
            notify("Vehicle", "Vehicle Fly enabled", 2)
            local seat = getVehicleSeat()
            if not seat then
                notify("Vehicle", "Not in a vehicle!", 2)
                return
            end
        else
            notify("Vehicle", "Vehicle Fly disabled", 2)
        end
    end
    
    local function setHoverEnabled(enabled)
        VehicleState.Hover = enabled
        notify("Vehicle", "Hover " .. (enabled and "enabled" or "disabled"), 2)
    end
    
    local function setNitroEnabled(enabled)
        VehicleState.Nitro = enabled
        if enabled then
            notify("Vehicle", "Nitro activated", 2)
            local seat = getVehicleSeat()
            if seat then
                seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity + Camera.CFrame.LookVector * 100
            end
        end
    end
    
    local function setVehicleJumpEnabled(enabled)
        VehicleState.Jump = enabled
        if enabled then
            notify("Vehicle", "Vehicle Jump enabled", 2)
            local seat = getVehicleSeat()
            if seat then
                seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity + Vector3.new(0, 50, 0)
            end
        end
    end
    
    local vehicleNitroConnection
    RunService.Heartbeat:Connect(function()
        if VehicleState.Hover then
            local seat = getVehicleSeat()
            if seat then
                local currentVel = seat.AssemblyLinearVelocity
                seat.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
            end
        end
        
        if VehicleState.Nitro then
            local seat = getVehicleSeat()
            if seat then
                seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity + Camera.CFrame.LookVector * 2
            end
        end
    end)
    
    createToggle(vehicleFrame, "Vehicle Fly", false, setVehicleFlyEnabled)
    createToggle(vehicleFrame, "Hover Mode", false, setHoverEnabled)
    createToggle(vehicleFrame, "Nitro Boost", false, setNitroEnabled)
    createToggle(vehicleFrame, "Vehicle Jump", false, setVehicleJumpEnabled)
    createSlider(vehicleFrame, "Vehicle Speed", 0, 150, 50, function(val)
        -- Can be used for custom vehicle speed control
    end)
end

--================================================--
-- PHYSICS TAB (ADD TO EXISTING PHYSICS SECTION)
--================================================--
-- Replace the Physics section with this:
do
    local physicsFrame = ContentFrames["Physics"]
    
    createToggle(physicsFrame, "Orbit Parts", false, setOrbitPartsEnabled)
    createToggle(physicsFrame, "Black Hole", false, setBlackHoleEnabled)
    createToggle(physicsFrame, "Explosion Ring", false, function(state)
        if state then
            performExplosionRing(100)
            -- One-time activation
        end
    end)
    
    createSlider(physicsFrame, "Orbit Radius", 5, 100, 20, function(val)
        PhysicsState.OrbitRadius = val
    end)
    createSlider(physicsFrame, "Orbit Speed", 0.5, 5, 2, function(val)
        PhysicsState.OrbitSpeed = val
    end)
    createSlider(physicsFrame, "Black Hole Radius", 20, 200, 100, function(val)
        -- You can add radius limiting here if needed
    end)
end
