-- Load Kavo UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Create Window
local Window = Library.CreateLib("dr4x internal v1.4 - FIXED AIMBOT", "DarkTheme")

-- ==================== COMBAT TAB ====================
local CombatTab = Window:NewTab("Combat")
local AimbotSection = CombatTab:NewSection("Aimbot (FIXED)")
local AutoPlaySection = CombatTab:NewSection("Auto Play (Full Auto)")
local HitboxSection = CombatTab:NewSection("Hitbox Expander")
local PlayerPullSection = CombatTab:NewSection("Player Pull (Silent Kill)")
local ESPSection = CombatTab:NewSection("ESP")

-- ==================== AIMBOT VARIABLES (FROM WORKING SCRIPT) ====================
getgenv().Aimbot = {
    Enabled = false,
    TeamCheck = false,
    AliveCheck = true,
    WallCheck = false,
    VisibleCheck = true,
    FOV = 300,
    Smoothness = 0.2,
    AimPart = "Head",
    PredictMovement = false,
    PredictionAmount = 0.13,
    IgnoreForcefield = true,
    MaxDistance = 1000,
    CurrentTarget = nil,
    IsAiming = false
}

-- ==================== AIMBOT FUNCTIONS (FROM WORKING SCRIPT) ====================
local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        
        local character = player.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local aimPart = character:FindFirstChild(getgenv().Aimbot.AimPart)
        
        if not aimPart or not rootPart or not humanoid then continue end
        
        -- Team Check
        if getgenv().Aimbot.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        -- Alive Check
        if getgenv().Aimbot.AliveCheck and humanoid.Health <= 0 then continue end
        
        -- Forcefield Check
        if getgenv().Aimbot.IgnoreForcefield and character:FindFirstChildOfClass("ForceField") then continue end
        
        -- Distance Check
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance > getgenv().Aimbot.MaxDistance then continue end
            
            -- Wall Check
            if getgenv().Aimbot.WallCheck then
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.IgnoreWater = true
                
                local rayResult = Workspace:Raycast(
                    Camera.CFrame.Position,
                    (aimPart.Position - Camera.CFrame.Position).Unit * distance,
                    raycastParams
                )
                
                if rayResult then continue end
            end
        end
        
        -- Visible Check
        if getgenv().Aimbot.VisibleCheck then
            local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
            if not onScreen then continue end
        end
        
        -- FOV Check
        local screenPos = Camera:WorldToViewportPoint(aimPart.Position)
        local mousePos = UserInputService:GetMouseLocation()
        local distanceFromMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if distanceFromMouse < getgenv().Aimbot.FOV and distanceFromMouse < shortestDistance then
            closestPlayer = player
            shortestDistance = distanceFromMouse
        end
    end
    
    return closestPlayer
end

local function GetPredictedPosition(part)
    if not getgenv().Aimbot.PredictMovement then
        return part.Position
    end
    
    local velocity = part.AssemblyLinearVelocity
    return part.Position + (velocity * getgenv().Aimbot.PredictionAmount)
end

-- ==================== AIMBOT UI (KAVO STYLE) ====================
AimbotSection:NewToggle("Enable Aimbot", "Lock onto enemies (Hold Right Click)", function(state)
    getgenv().Aimbot.Enabled = state
    if state then
        Library:SendNotification("Aimbot", "FIXED Aimbot Enabled - Hold Right Click")
    else
        Library:SendNotification("Aimbot", "Aimbot Disabled")
    end
end)

AimbotSection:NewSlider("Aimbot FOV", "Detection radius", 800, 100, function(s)
    getgenv().Aimbot.FOV = s
end)

AimbotSection:NewSlider("Smoothness", "Higher = smoother (1-100)", 100, 1, function(s)
    getgenv().Aimbot.Smoothness = s / 100
end)

AimbotSection:NewDropdown("Target Part", "Body part to lock", {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}, function(currentOption)
    getgenv().Aimbot.AimPart = currentOption
end)

AimbotSection:NewToggle("Prediction", "Predict moving targets", function(state)
    getgenv().Aimbot.PredictMovement = state
end)

AimbotSection:NewSlider("Prediction Strength", "Prediction amount", 50, 0, function(s)
    getgenv().Aimbot.PredictionAmount = s / 100
end)

AimbotSection:NewToggle("Team Check", "Ignore teammates", function(state)
    getgenv().Aimbot.TeamCheck = state
end)

AimbotSection:NewToggle("Wall Check", "Only shoot through walls", function(state)
    getgenv().Aimbot.WallCheck = state
end)

AimbotSection:NewToggle("Visible Check", "Only visible targets", function(state)
    getgenv().Aimbot.VisibleCheck = state
end)

AimbotSection:NewToggle("Ignore Forcefield", "Ignore players with forcefield", function(state)
    getgenv().Aimbot.IgnoreForcefield = state
end)

AimbotSection:NewSlider("Max Distance", "Max aim distance (studs)", 5000, 100, function(s)
    getgenv().Aimbot.MaxDistance = s
end)

-- Auto Play Variables
getgenv().AutoPlayEnabled = false
getgenv().AutoPlayRadius = 100
getgenv().AutoPlayHeight = 15
getgenv().AutoPlayShootDelay = 0.2
getgenv().AutoPlayKillDelay = 0.5
getgenv().AutoPlayTeamCheck = true
getgenv().AutoPlayTarget = nil

-- Hitbox Expander Variables
getgenv().HitboxEnabled = false
getgenv().HitboxSize = 10
getgenv().HitboxTransparency = 0.5
getgenv().OriginalSizes = {}

-- Player Pull Variables
getgenv().PlayerPullEnabled = false
getgenv().PullDistance = 10
getgenv().PullRadius = 50
getgenv().PullHeight = 0

-- Get Closest Player for Auto Play
local function GetAutoPlayTarget()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and humanoid.Health > 0 and rootPart then
                    if getgenv().AutoPlayTeamCheck then
                        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                            continue
                        end
                    end
                    
                    local distance = (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    
                    if distance <= getgenv().AutoPlayRadius and distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = {
                            player = player,
                            character = character,
                            humanoid = humanoid,
                            rootPart = rootPart,
                            distance = distance
                        }
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- Auto Shoot Function
local function AutoShoot()
    local tool = nil
    
    if LocalPlayer.Character then
        for _, child in pairs(LocalPlayer.Character:GetChildren()) do
            if child:IsA("Tool") then
                tool = child
                break
            end
        end
    end
    
    if tool then
        pcall(function()
            tool:Activate()
        end)
        
        pcall(function()
            mouse1click()
        end)
        
        for _, obj in pairs(tool:GetDescendants()) do
            pcall(function()
                if obj:IsA("RemoteEvent") then
                    local name = obj.Name:lower()
                    if name:find("fire") or name:find("shoot") or name:find("gun") then
                        obj:FireServer()
                    end
                end
            end)
        end
    end
end

-- ==================== AUTO PLAY ====================
AutoPlaySection:NewToggle("Enable Auto Play", "AUTO TP + AIM + SHOOT", function(state)
    getgenv().AutoPlayEnabled = state
    if state then
        Library:SendNotification("Auto Play", "AUTO PLAY ENABLED!")
    else
        Library:SendNotification("Auto Play", "Auto Play Disabled")
        getgenv().AutoPlayTarget = nil
    end
end)

AutoPlaySection:NewSlider("Search Radius", "Max distance to find enemies", 200, 20, function(s)
    getgenv().AutoPlayRadius = s
end)

AutoPlaySection:NewSlider("TP Height", "Height above enemy head (studs)", 30, 5, function(s)
    getgenv().AutoPlayHeight = s
end)

AutoPlaySection:NewSlider("Shoot Delay", "Time between shots (seconds)", 100, 10, function(s)
    getgenv().AutoPlayShootDelay = s / 100
end)

AutoPlaySection:NewSlider("Kill Delay", "Delay after kill (seconds)", 200, 10, function(s)
    getgenv().AutoPlayKillDelay = s / 100
end)

AutoPlaySection:NewToggle("Team Check", "Don't target teammates", function(state)
    getgenv().AutoPlayTeamCheck = state
end)

-- ==================== HITBOX EXPANDER ====================
HitboxSection:NewToggle("Enable Hitbox Expander", "Expand enemy hitboxes", function(state)
    getgenv().HitboxEnabled = state
    if state then
        Library:SendNotification("Hitbox", "Hitbox Expander Enabled")
    else
        Library:SendNotification("Hitbox", "Hitbox Expander Disabled")
    end
end)

HitboxSection:NewSlider("Hitbox Size", "Size of expanded hitbox", 50, 5, function(s)
    getgenv().HitboxSize = s
end)

HitboxSection:NewSlider("Transparency", "Hitbox visibility", 100, 0, function(s)
    getgenv().HitboxTransparency = 1 - (s / 100)
end)

-- Hitbox Expander Function
local function ExpandHitbox(player)
    if not player.Character then return end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    
    if not getgenv().OriginalSizes[player.UserId] then
        getgenv().OriginalSizes[player.UserId] = {}
        
        if humanoidRootPart then
            getgenv().OriginalSizes[player.UserId].HumanoidRootPart = {
                Size = humanoidRootPart.Size,
                Transparency = humanoidRootPart.Transparency,
                CanCollide = humanoidRootPart.CanCollide,
                Massless = humanoidRootPart.Massless,
                Material = humanoidRootPart.Material
            }
        end
        
        if head then
            getgenv().OriginalSizes[player.UserId].Head = {
                Size = head.Size,
                Transparency = head.Transparency,
                CanCollide = head.CanCollide,
                Massless = head.Massless,
                Material = head.Material
            }
        end
    end
    
    if getgenv().HitboxEnabled then
        if humanoidRootPart then
            humanoidRootPart.Size = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)
            humanoidRootPart.Transparency = getgenv().HitboxTransparency
            humanoidRootPart.CanCollide = false
            humanoidRootPart.Massless = true
            
            if getgenv().HitboxTransparency >= 0.99 then
                humanoidRootPart.Transparency = 1
                humanoidRootPart.Material = Enum.Material.ForceField
            end
        end
        
        if head then
            head.Size = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)
            head.Transparency = getgenv().HitboxTransparency
            head.CanCollide = false
            head.Massless = true
            
            if getgenv().HitboxTransparency >= 0.99 then
                head.Transparency = 1
                head.Material = Enum.Material.ForceField
            end
        end
    else
        if getgenv().OriginalSizes[player.UserId] then
            if humanoidRootPart and getgenv().OriginalSizes[player.UserId].HumanoidRootPart then
                local original = getgenv().OriginalSizes[player.UserId].HumanoidRootPart
                humanoidRootPart.Size = original.Size
                humanoidRootPart.Transparency = original.Transparency
                humanoidRootPart.CanCollide = original.CanCollide
                humanoidRootPart.Massless = original.Massless
                humanoidRootPart.Material = original.Material
            end
            
            if head and getgenv().OriginalSizes[player.UserId].Head then
                local original = getgenv().OriginalSizes[player.UserId].Head
                head.Size = original.Size
                head.Transparency = original.Transparency
                head.CanCollide = original.CanCollide
                head.Massless = original.Massless
                head.Material = original.Material
            end
        end
    end
end

-- ==================== PLAYER PULL ====================
PlayerPullSection:NewToggle("Enable Player Pull", "Teleport enemies to you", function(state)
    getgenv().PlayerPullEnabled = state
    if state then
        Library:SendNotification("Player Pull", "Player Pull Enabled!")
    else
        Library:SendNotification("Player Pull", "Player Pull Disabled")
    end
end)

PlayerPullSection:NewSlider("Pull Radius", "Max distance to pull", 500, 10, function(s)
    getgenv().PullRadius = s
end)

PlayerPullSection:NewSlider("Pull Distance", "Distance in front of you", 50, 1, function(s)
    getgenv().PullDistance = s
end)

PlayerPullSection:NewSlider("Height Offset", "Height adjustment", 20, -20, function(s)
    getgenv().PullHeight = s
end)

-- Player Pull Function
local function PullPlayer(player)
    if not player.Character or not LocalPlayer.Character then return end
    if player == LocalPlayer then return end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local localRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if humanoidRootPart and localRootPart then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if humanoid and humanoid.Health > 0 then
            if getgenv().Aimbot.TeamCheck then
                if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    return
                end
            end
            
            local distance = (humanoidRootPart.Position - localRootPart.Position).Magnitude
            
            if distance <= getgenv().PullRadius then
                local lookVector = localRootPart.CFrame.LookVector
                local pullPosition = localRootPart.Position + (lookVector * getgenv().PullDistance) + Vector3.new(0, getgenv().PullHeight, 0)
                
                humanoidRootPart.CFrame = CFrame.new(pullPosition)
                humanoidRootPart.CanCollide = false
                humanoidRootPart.Anchored = true
            end
        end
    end
end

-- ESP Variables
getgenv().ESPEnabled = false
getgenv().BoxESP = false
getgenv().NameESP = false
getgenv().HealthESP = false
getgenv().TracerESP = false
getgenv().SkeletonESP = false
getgenv().DistanceESP = false

-- ESP Toggles
ESPSection:NewToggle("Enable ESP", "Show player info", function(state)
    getgenv().ESPEnabled = state
end)

ESPSection:NewToggle("Box ESP", "Show boxes", function(state)
    getgenv().BoxESP = state
end)

ESPSection:NewToggle("Name ESP", "Show names", function(state)
    getgenv().NameESP = state
end)

ESPSection:NewToggle("Health Bar", "Show health", function(state)
    getgenv().HealthESP = state
end)

ESPSection:NewToggle("Tracer Lines", "Lines to players", function(state)
    getgenv().TracerESP = state
end)

ESPSection:NewToggle("Skeleton ESP", "Show skeleton", function(state)
    getgenv().SkeletonESP = state
end)

ESPSection:NewToggle("Distance ESP", "Show distance", function(state)
    getgenv().DistanceESP = state
end)

-- ESP Functions
local function CreateESP(player)
    if not player.Character then return end
    
    local character = player.Character
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    if character:FindFirstChild("ESPHighlight") then
        character.ESPHighlight:Destroy()
    end
    if head:FindFirstChild("ESPBillboard") then
        head.ESPBillboard:Destroy()
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.Parent = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPBillboard"
    billboard.Parent = head
    billboard.Size = UDim2.new(0, 200, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Parent = billboard
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.33, 0)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 16
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Text = player.Name
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Parent = billboard
    healthLabel.BackgroundTransparency = 1
    healthLabel.Position = UDim2.new(0, 0, 0.33, 0)
    healthLabel.Size = UDim2.new(1, 0, 0.33, 0)
    healthLabel.Font = Enum.Font.SourceSans
    healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    healthLabel.TextSize = 14
    healthLabel.TextStrokeTransparency = 0
    healthLabel.Text = ""
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Parent = billboard
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Position = UDim2.new(0, 0, 0.66, 0)
    distanceLabel.Size = UDim2.new(1, 0, 0.33, 0)
    distanceLabel.Font = Enum.Font.SourceSans
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextSize = 14
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Text = ""
end

local tracers = {}

local function CreateTracer(player)
    if tracers[player] then
        tracers[player]:Remove()
    end
    
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Thickness = 2
    line.Transparency = 1
    
    tracers[player] = line
    
    return line
end

local skeletons = {}

local function CreateSkeleton(player)
    if skeletons[player] then
        for _, line in pairs(skeletons[player]) do
            line:Remove()
        end
    end
    
    skeletons[player] = {}
    
    local connections = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"}
    }
    
    for _, connection in pairs(connections) do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 2
        line.Transparency = 1
        
        table.insert(skeletons[player], {line = line, from = connection[1], to = connection[2]})
    end
end

-- ==================== MOVEMENT TAB ====================
local MovementTab = Window:NewTab("Movement")
local SpeedSection = MovementTab:NewSection("Speed (LOOP FIX)")
local FlySection = MovementTab:NewSection("Fly")
local JumpSection = MovementTab:NewSection("Jump")
local NoclipSection = MovementTab:NewSection("Noclip")

-- Speed Variables
getgenv().SpeedEnabled = false
getgenv().SpeedValue = 16
getgenv().SpeedKeybind = Enum.KeyCode.Q

-- Speed Toggle
SpeedSection:NewToggle("Enable Speed", "Press Q to toggle (AUTO LOOP)", function(state)
    getgenv().SpeedEnabled = state
    if state then
        Library:SendNotification("Speed", "Speed LOOP Enabled - Won't reset!")
    else
        Library:SendNotification("Speed", "Speed Disabled")
    end
end)

-- Speed Slider
SpeedSection:NewSlider("Speed Value", "Walk speed amount", 200, 16, function(s)
    getgenv().SpeedValue = s
end)

SpeedSection:NewLabel("Keybind: Q")
SpeedSection:NewLabel("LOOP: Auto reapply every 2 seconds!")

-- Fly Variables
getgenv().FlyEnabled = false
getgenv().FlySpeed = 50
getgenv().FlyKeybind = Enum.KeyCode.E
getgenv().FlyBodyVelocity = nil
getgenv().FlyBodyGyro = nil

-- Fly Toggle
FlySection:NewToggle("Enable Fly", "Press E to toggle", function(state)
    getgenv().FlyEnabled = state
    
    if not state then
        if getgenv().FlyBodyVelocity then
            getgenv().FlyBodyVelocity:Destroy()
            getgenv().FlyBodyVelocity = nil
        end
        if getgenv().FlyBodyGyro then
            getgenv().FlyBodyGyro:Destroy()
            getgenv().FlyBodyGyro = nil
        end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
    end
end)

-- Fly Speed
FlySection:NewSlider("Fly Speed", "Flight speed", 200, 10, function(s)
    getgenv().FlySpeed = s
end)

FlySection:NewLabel("Keybind: E")
FlySection:NewLabel("Controls: WASD + Space/Shift")

-- Fly Function
local function UpdateFly()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    
    if getgenv().FlyEnabled then
        if not getgenv().FlyBodyVelocity then
            getgenv().FlyBodyVelocity = Instance.new("BodyVelocity")
            getgenv().FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            getgenv().FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            getgenv().FlyBodyVelocity.Parent = rootPart
        end
        
        if not getgenv().FlyBodyGyro then
            getgenv().FlyBodyGyro = Instance.new("BodyGyro")
            getgenv().FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            getgenv().FlyBodyGyro.P = 9e4
            getgenv().FlyBodyGyro.Parent = rootPart
        end
        
        humanoid.PlatformStand = true
        
        local velocity = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            velocity = velocity + (Camera.CFrame.LookVector * getgenv().FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            velocity = velocity - (Camera.CFrame.LookVector * getgenv().FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            velocity = velocity - (Camera.CFrame.RightVector * getgenv().FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            velocity = velocity + (Camera.CFrame.RightVector * getgenv().FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            velocity = velocity + (Vector3.new(0, 1, 0) * getgenv().FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            velocity = velocity - (Vector3.new(0, 1, 0) * getgenv().FlySpeed)
        end
        
        getgenv().FlyBodyVelocity.Velocity = velocity
        getgenv().FlyBodyGyro.CFrame = Camera.CFrame
    else
        if getgenv().FlyBodyVelocity then
            getgenv().FlyBodyVelocity:Destroy()
            getgenv().FlyBodyVelocity = nil
        end
        if getgenv().FlyBodyGyro then
            getgenv().FlyBodyGyro:Destroy()
            getgenv().FlyBodyGyro = nil
        end
        humanoid.PlatformStand = false
    end
end

-- Jump Settings
JumpSection:NewSlider("Jump Power", "Jump height", 300, 50, function(s)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = s
    end
end)

-- Infinite Jump
getgenv().InfJump = false

JumpSection:NewToggle("Infinite Jump", "Jump infinitely", function(state)
    getgenv().InfJump = state
end)

-- Noclip Variables
getgenv().NoclipEnabled = false
getgenv().NoclipKeybind = Enum.KeyCode.C

-- Noclip Toggle
NoclipSection:NewToggle("Enable Noclip", "Press C to toggle", function(state)
    getgenv().NoclipEnabled = state
end)

NoclipSection:NewLabel("Keybind: C")

-- ==================== VISUAL TAB ====================
local VisualTab = Window:NewTab("Visual")
local LightingSection = VisualTab:NewSection("Lighting")
local CameraSection = VisualTab:NewSection("Camera")

-- Full Bright
LightingSection:NewToggle("Full Bright", "See everything clearly", function(state)
    if state then
        game.Lighting.Brightness = 2
        game.Lighting.ClockTime = 14
        game.Lighting.FogEnd = 100000
        game.Lighting.GlobalShadows = false
        game.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        game.Lighting.Brightness = 1
        game.Lighting.ClockTime = 12
        game.Lighting.FogEnd = 100000
        game.Lighting.GlobalShadows = true
        game.Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
    end
end)

-- Remove Fog
LightingSection:NewButton("Remove Fog", "Clear all fog", function()
    game.Lighting.FogEnd = 100000
end)

-- FOV Slider
CameraSection:NewSlider("Field of View", "Camera FOV", 120, 70, function(s)
    Camera.FieldOfView = s
end)

-- Reset FOV
CameraSection:NewButton("Reset FOV", "Reset to default", function()
    Camera.FieldOfView = 70
end)

-- ==================== MISC TAB ====================
local MiscTab = Window:NewTab("Misc")
local MiscSection = MiscTab:NewSection("Miscellaneous")
local ControlSection = MiscTab:NewSection("Controls")

-- Anti AFK
MiscSection:NewToggle("Anti-AFK", "Prevent AFK kick", function(state)
    if state then
        local vu = game:GetService("VirtualUser")
        LocalPlayer.Idled:connect(function()
            vu:Button2Down(Vector2.new(0,0), Camera.CFrame)
            wait(1)
            vu:Button2Up(Vector2.new(0,0), Camera.CFrame)
        end)
    end
end)

-- Reset Character
ControlSection:NewButton("Reset Character", "Kill yourself", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
end)

-- Minimize Menu Button
ControlSection:NewButton("Minimize Menu", "Minimize/Restore menu", function()
    local ui = game:GetService("CoreGui"):FindFirstChild("Kavo UI") or 
               game:GetService("CoreGui"):FindFirstChild("KavoUI") or
               game:GetService("CoreGui"):FindFirstChild("dr4x internal v1.4 - FIXED AIMBOT")
    
    if ui then
        local main = ui:FindFirstChild("Main")
        if main then
            main.Visible = not main.Visible
            if main.Visible then
                Library:SendNotification("Menu", "Menu Restored")
            else
                Library:SendNotification("Menu", "Menu Minimized - Press RightCtrl to restore")
            end
        else
            ui.Enabled = not ui.Enabled
        end
    end
end)

ControlSection:NewLabel("Keybind: RightCtrl")

-- Rejoin Server
ControlSection:NewButton("Rejoin Server", "Rejoin current server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- ==================== INFO TAB ====================
local InfoTab = Window:NewTab("Info")
local InfoSection = InfoTab:NewSection("Script Info")

InfoSection:NewLabel("dr4x internal v1.4")
InfoSection:NewLabel("FIXED AIMBOT + SPEED LOOP")
InfoSection:NewLabel("")
InfoSection:NewLabel("NEW FEATURES:")
InfoSection:NewLabel("• FIXED AIMBOT (Working 100%)")
InfoSection:NewLabel("• Speed Loop (Won't reset)")
InfoSection:NewLabel("• Auto Play Mode")
InfoSection:NewLabel("• Hitbox Expander")
InfoSection:NewLabel("• Player Pull (500 studs)")
InfoSection:NewLabel("• ESP (Box/Name/Health/etc)")
InfoSection:NewLabel("")
InfoSection:NewLabel("Keybinds:")
InfoSection:NewLabel("Q = Speed Toggle")
InfoSection:NewLabel("E = Fly Toggle")
InfoSection:NewLabel("C = Noclip Toggle")
InfoSection:NewLabel("Right Click = Aimbot Lock")
InfoSection:NewLabel("RightCtrl = Minimize Menu")

-- ==================== MINIMIZE MENU TOGGLE ====================
local MenuVisible = true

local HideMenuConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightControl then
        MenuVisible = not MenuVisible
        
        local ui = game:GetService("CoreGui"):FindFirstChild("Kavo UI") or 
                   game:GetService("CoreGui"):FindFirstChild("KavoUI") or
                   game:GetService("CoreGui"):FindFirstChild("dr4x internal v1.4 - FIXED AIMBOT")
        
        if ui then
            local main = ui:FindFirstChild("Main")
            if main then
                main.Visible = MenuVisible
                if MenuVisible then
                    Library:SendNotification("Menu", "Menu Restored")
                else
                    Library:SendNotification("Menu", "Menu Minimized")
                end
            else
                ui.Enabled = MenuVisible
            end
        end
    end
end)

-- ==================== KEYBIND HANDLER ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Speed Keybind (Q)
    if input.KeyCode == getgenv().SpeedKeybind then
        getgenv().SpeedEnabled = not getgenv().SpeedEnabled
        if getgenv().SpeedEnabled then
            Library:SendNotification("Speed", "Speed LOOP Enabled!")
        else
            Library:SendNotification("Speed", "Speed Disabled")
        end
    end
    
    -- Fly Keybind (E)
    if input.KeyCode == getgenv().FlyKeybind then
        getgenv().FlyEnabled = not getgenv().FlyEnabled
        
        if not getgenv().FlyEnabled then
            if getgenv().FlyBodyVelocity then
                getgenv().FlyBodyVelocity:Destroy()
                getgenv().FlyBodyVelocity = nil
            end
            if getgenv().FlyBodyGyro then
                getgenv().FlyBodyGyro:Destroy()
                getgenv().FlyBodyGyro = nil
            end
            
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character.Humanoid.PlatformStand = false
            end
        end
    end
    
    -- Noclip Keybind (C)
    if input.KeyCode == getgenv().NoclipKeybind then
        getgenv().NoclipEnabled = not getgenv().NoclipEnabled
    end
end)

-- ==================== MAIN LOOPS ====================

-- AIMBOT LOOP (FIXED - FROM WORKING SCRIPT)
local AimbotConnection = RunService.RenderStepped:Connect(function()
    pcall(function()
        if not getgenv().Aimbot.Enabled then
            return
        end
        
        -- Check if right click is held
        local isRightClickHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        
        if isRightClickHeld then
            getgenv().Aimbot.IsAiming = true
            
            local target = GetClosestPlayerToCursor()
            getgenv().Aimbot.CurrentTarget = target
            
            if target and target.Character then
                local aimPart = target.Character:FindFirstChild(getgenv().Aimbot.AimPart)
                
                -- Fallback to other parts if selected part doesn't exist
                if not aimPart then
                    aimPart = target.Character:FindFirstChild("Head") or 
                              target.Character:FindFirstChild("HumanoidRootPart") or
                              target.Character:FindFirstChild("Torso") or
                              target.Character:FindFirstChild("UpperTorso")
                end
                
                if aimPart then
                    -- Aim at predicted position
                    local targetPos = GetPredictedPosition(aimPart)
                    
                    -- Apply smoothing
                    local currentCam = Camera.CFrame
                    local targetCam = CFrame.new(currentCam.Position, targetPos)
                    
                    -- Use smoothness (0 = instant, 1 = no aim)
                    local smoothness = math.clamp(getgenv().Aimbot.Smoothness, 0, 0.99)
                    local alpha = 1 - smoothness
                    
                    -- Apply the aim
                    Camera.CFrame = currentCam:Lerp(targetCam, alpha)
                end
            end
        else
            getgenv().Aimbot.IsAiming = false
            getgenv().Aimbot.CurrentTarget = nil
        end
    end)
end)

-- AUTO PLAY LOOP
spawn(function()
    while wait() do
        if getgenv().AutoPlayEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local target = GetAutoPlayTarget()
                
                if target and target.humanoid.Health > 0 then
                    getgenv().AutoPlayTarget = target
                    
                    local head = target.character:FindFirstChild("Head")
                    if head then
                        -- Step 1: Teleport above enemy's head
                        local tpPosition = head.Position + Vector3.new(0, getgenv().AutoPlayHeight, 0)
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(tpPosition)
                        
                        -- Step 2: Aim at head
                        local aimCFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                        Camera.CFrame = aimCFrame
                        
                        -- Step 3: Shoot
                        wait(getgenv().AutoPlayShootDelay)
                        AutoShoot()
                        
                        -- Check if still alive
                        if target.humanoid.Health <= 0 then
                            wait(getgenv().AutoPlayKillDelay)
                            getgenv().AutoPlayTarget = nil
                        end
                    end
                else
                    wait(0.5)
                    getgenv().AutoPlayTarget = nil
                end
            end)
        else
            wait(0.5)
        end
    end
end)

-- SPEED LOOP (NEW - AUTO REAPPLY EVERY 2 SECONDS)
spawn(function()
    while wait(2) do -- Loop every 2 seconds
        if getgenv().SpeedEnabled then
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.WalkSpeed = getgenv().SpeedValue
                end
            end)
        end
    end
end)

-- Movement, ESP & Hitbox Loop
RunService.Heartbeat:Connect(function()
    -- Noclip
    if getgenv().NoclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- Fly
    if getgenv().FlyEnabled then
        UpdateFly()
    end
    
    -- Infinite Jump
    if getgenv().InfJump then
        UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
            end
        end)
    end
    
    -- Hitbox Expander Loop
    if getgenv().HitboxEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                ExpandHitbox(player)
            end
        end
    end
    
    -- Player Pull Loop
    if getgenv().PlayerPullEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                PullPlayer(player)
            end
        end
    end
    
    -- ESP & Visual Update
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not getgenv().HitboxEnabled then
                ExpandHitbox(player)
            end
            
            if not player.Character:FindFirstChild("ESPHighlight") then
                CreateESP(player)
            end
            
            if not tracers[player] then
                CreateTracer(player)
            end
            
            if not skeletons[player] then
                CreateSkeleton(player)
            end
            
            local character = player.Character
            local highlight = character:FindFirstChild("ESPHighlight")
            local head = character:FindFirstChild("Head")
            local billboard = head and head:FindFirstChild("ESPBillboard")
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            if getgenv().ESPEnabled then
                if highlight then
                    highlight.Enabled = getgenv().BoxESP
                end
                
                if billboard then
                    billboard.Enabled = getgenv().NameESP or getgenv().HealthESP or getgenv().DistanceESP
                    
                    if billboard.Enabled then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        local distance = humanoidRootPart and math.floor((humanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) or 0
                        
                        if getgenv().NameESP then
                            billboard.NameLabel.Visible = true
                        else
                            billboard.NameLabel.Visible = false
                        end
                        
                        if getgenv().HealthESP and humanoid then
                            local health = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                            billboard.HealthLabel.Visible = true
                            billboard.HealthLabel.Text = health .. " HP"
                            billboard.HealthLabel.TextColor3 = Color3.fromRGB(255 - (health * 2.55), health * 2.55, 0)
                        else
                            billboard.HealthLabel.Visible = false
                        end
                        
                        if getgenv().DistanceESP then
                            billboard.DistanceLabel.Visible = true
                            billboard.DistanceLabel.Text = distance .. "m"
                        else
                            billboard.DistanceLabel.Visible = false
                        end
                    end
                end
                
                if getgenv().TracerESP and tracers[player] and humanoidRootPart then
                    local tracer = tracers[player]
                    local screenPos, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
                    
                    if onScreen then
                        tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                        tracer.Visible = true
                    else
                        tracer.Visible = false
                    end
                else
                    if tracers[player] then
                        tracers[player].Visible = false
                    end
                end
                
                if getgenv().SkeletonESP and skeletons[player] then
                    for _, connection in pairs(skeletons[player]) do
                        local fromPart = character:FindFirstChild(connection.from)
                        local toPart = character:FindFirstChild(connection.to)
                        
                        if fromPart and toPart then
                            local fromPos, fromOnScreen = Camera:WorldToViewportPoint(fromPart.Position)
                            local toPos, toOnScreen = Camera:WorldToViewportPoint(toPart.Position)
                            
                            if fromOnScreen and toOnScreen then
                                connection.line.From = Vector2.new(fromPos.X, fromPos.Y)
                                connection.line.To = Vector2.new(toPos.X, toPos.Y)
                                connection.line.Visible = true
                            else
                                connection.line.Visible = false
                            end
                        else
                            connection.line.Visible = false
                        end
                    end
                else
                    if skeletons[player] then
                        for _, connection in pairs(skeletons[player]) do
                            connection.line.Visible = false
                        end
                    end
                end
            else
                if highlight then highlight.Enabled = false end
                if billboard then billboard.Enabled = false end
                if tracers[player] then tracers[player].Visible = false end
                if skeletons[player] then
                    for _, connection in pairs(skeletons[player]) do
                        connection.line.Visible = false
                    end
                end
            end
        end
    end
end)

-- Character Respawn Handler
LocalPlayer.CharacterAdded:Connect(function(char)
    wait(0.5)
    if getgenv().SpeedEnabled and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = getgenv().SpeedValue
    end
    
    if getgenv().FlyBodyVelocity then
        getgenv().FlyBodyVelocity:Destroy()
        getgenv().FlyBodyVelocity = nil
    end
    if getgenv().FlyBodyGyro then
        getgenv().FlyBodyGyro:Destroy()
        getgenv().FlyBodyGyro = nil
    end
end)

-- Player Added/Removed
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(0.5)
        CreateESP(player)
        CreateTracer(player)
        CreateSkeleton(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if tracers[player] then
        tracers[player]:Remove()
        tracers[player] = nil
    end
    
    if skeletons[player] then
        for _, connection in pairs(skeletons[player]) do
            connection.line:Remove()
        end
        skeletons[player] = nil
    end
    
    if getgenv().OriginalSizes[player.UserId] then
        getgenv().OriginalSizes[player.UserId] = nil
    end
end)

print("===========================================")
print("dr4x internal v1.4 - FIXED AIMBOT + SPEED LOOP")
print("All features loaded successfully!")
print("===========================================")
print("NEW: FIXED AIMBOT - Hold Right Click")
print("NEW: SPEED LOOP - Auto reapply every 2 seconds")
print("Auto Play | Hitbox | Player Pull | ESP")
print("===========================================")

Library:SendNotification("Script Loaded", "dr4x v1.4 ready! All features working!", 5)
