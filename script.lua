-- Load LinoriaLib
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Create Window
local Window = Library:CreateWindow({
    Title = 'drax universal v1.0 + Aimbot',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Create Tabs
local Tabs = {
    Combat = Window:AddTab('Combat'),
    Player = Window:AddTab('Player'),
    Visual = Window:AddTab('Visual'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- ==================== COMBAT TAB (AIMBOT) ====================
local AimbotBox = Tabs.Combat:AddLeftGroupbox('Aimbot Settings')
local AimbotVisualBox = Tabs.Combat:AddRightGroupbox('Aimbot Visual')

-- Aimbot Variables
getgenv().Aimbot = {
    Enabled = false,
    TeamCheck = true,
    AliveCheck = true,
    WallCheck = false,
    VisibleCheck = true,
    FOV = 120,
    Smoothness = 0.15,
    AimPart = "Head",
    PredictMovement = false,
    PredictionAmount = 0.13,
    IgnoreForcefield = true,
    MaxDistance = 1000,
    ShowFOV = true,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVTransparency = 0.5,
    FOVFilled = false,
    TargetHighlight = true,
    HighlightColor = Color3.fromRGB(255, 0, 0),
    RightClickAim = true,
    CurrentTarget = nil,
    IsAiming = false
}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.NumSides = 50
FOVCircle.Radius = getgenv().Aimbot.FOV
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)

-- Target Highlight
local TargetHighlight = nil

-- Aimbot Functions
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
        
        -- Visible Check (simple version)
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

local function AimAt(position)
    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(currentCFrame.Position, position)
    
    -- Smooth aiming
    local smoothness = getgenv().Aimbot.Smoothness
    Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 - smoothness)
end

-- Aimbot Settings
AimbotBox:AddToggle('AimbotEnabled', {
    Text = 'Enable Aimbot',
    Default = false,
    Callback = function(Value)
        getgenv().Aimbot.Enabled = Value
        if not Value then
            getgenv().Aimbot.IsAiming = false
            getgenv().Aimbot.CurrentTarget = nil
            if TargetHighlight then
                TargetHighlight:Destroy()
                TargetHighlight = nil
            end
        end
    end
})

AimbotBox:AddDivider()

AimbotBox:AddLabel('Trigger: Right Click'):AddKeyPicker('AimbotKey', {
    Default = 'MouseButton2',
    Text = 'Aim Key',
    Mode = 'Hold',
    Callback = function()
        -- Handled in main loop
    end
})

AimbotBox:AddDropdown('AimPart', {
    Values = {'Head', 'Torso', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso'},
    Default = 1,
    Multi = false,
    Text = 'Aim Part',
    Callback = function(Value)
        getgenv().Aimbot.AimPart = Value
    end
})

AimbotBox:AddSlider('AimbotFOV', {
    Text = 'FOV Size',
    Default = 120,
    Min = 20,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        getgenv().Aimbot.FOV = Value
        FOVCircle.Radius = Value
    end
})

AimbotBox:AddSlider('AimbotSmooth', {
    Text = 'Smoothness',
    Default = 0.15,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().Aimbot.Smoothness = Value
    end
})

AimbotBox:AddSlider('MaxDistance', {
    Text = 'Max Distance (studs)',
    Default = 1000,
    Min = 100,
    Max = 5000,
    Rounding = 0,
    Callback = function(Value)
        getgenv().Aimbot.MaxDistance = Value
    end
})

AimbotBox:AddDivider()

AimbotBox:AddToggle('TeamCheck', {
    Text = 'Team Check',
    Default = true,
    Callback = function(Value)
        getgenv().Aimbot.TeamCheck = Value
    end
})

AimbotBox:AddToggle('AliveCheck', {
    Text = 'Alive Check',
    Default = true,
    Callback = function(Value)
        getgenv().Aimbot.AliveCheck = Value
    end
})

AimbotBox:AddToggle('WallCheck', {
    Text = 'Wall Check',
    Default = false,
    Callback = function(Value)
        getgenv().Aimbot.WallCheck = Value
    end
})

AimbotBox:AddToggle('VisibleCheck', {
    Text = 'Visible Check',
    Default = true,
    Callback = function(Value)
        getgenv().Aimbot.VisibleCheck = Value
    end
})

AimbotBox:AddToggle('IgnoreForcefield', {
    Text = 'Ignore Forcefield',
    Default = true,
    Callback = function(Value)
        getgenv().Aimbot.IgnoreForcefield = Value
    end
})

AimbotBox:AddDivider()

AimbotBox:AddToggle('PredictMovement', {
    Text = 'Predict Movement',
    Default = false,
    Callback = function(Value)
        getgenv().Aimbot.PredictMovement = Value
    end
})

AimbotBox:AddSlider('PredictionAmount', {
    Text = 'Prediction Strength',
    Default = 0.13,
    Min = 0,
    Max = 0.5,
    Rounding = 2,
    Callback = function(Value)
        getgenv().Aimbot.PredictionAmount = Value
    end
})

-- Visual Settings
AimbotVisualBox:AddToggle('ShowFOV', {
    Text = 'Show FOV Circle',
    Default = true,
    Callback = function(Value)
        getgenv().Aimbot.ShowFOV = Value
        FOVCircle.Visible = Value
    end
})

AimbotVisualBox:AddToggle('FOVFilled', {
    Text = 'FOV Filled',
    Default = false,
    Callback = function(Value)
        getgenv().Aimbot.FOVFilled = Value
        FOVCircle.Filled = Value
    end
})

AimbotVisualBox:AddSlider('FOVTransparency', {
    Text = 'FOV Transparency',
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        getgenv().Aimbot.FOVTransparency = Value / 100
        FOVCircle.Transparency = 1 - (Value / 100)
    end
})

AimbotVisualBox:AddLabel('FOV Color'):AddColorPicker('FOVColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'FOV Circle Color',
    Callback = function(Value)
        getgenv().Aimbot.FOVColor = Value
        FOVCircle.Color = Value
    end
})

AimbotVisualBox:AddDivider()

AimbotVisualBox:AddToggle('TargetHighlight', {
    Text = 'Highlight Target',
    Default = true,
    Callback = function(Value)
        getgenv().Aimbot.TargetHighlight = Value
        if not Value and TargetHighlight then
            TargetHighlight:Destroy()
            TargetHighlight = nil
        end
    end
})

AimbotVisualBox:AddLabel('Highlight Color'):AddColorPicker('HighlightColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'Target Highlight Color',
    Callback = function(Value)
        getgenv().Aimbot.HighlightColor = Value
    end
})

AimbotVisualBox:AddDivider()

AimbotVisualBox:AddLabel('Current Target: None')

-- ==================== PLAYER TAB ====================
local MovementBox = Tabs.Player:AddLeftGroupbox('Movement')
local AbilitiesBox = Tabs.Player:AddRightGroupbox('Abilities')

-- Movement
MovementBox:AddSlider('WalkSpeed', {
    Text = 'Walk Speed',
    Default = 16,
    Min = 16,
    Max = 500,
    Rounding = 1,
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end
})

MovementBox:AddSlider('JumpPower', {
    Text = 'Jump Power',
    Default = 50,
    Min = 50,
    Max = 500,
    Rounding = 1,
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end
})

MovementBox:AddToggle('InfiniteJump', {
    Text = 'Infinite Jump',
    Default = false,
    Callback = function(Value)
        getgenv().InfJump = Value
    end
})

MovementBox:AddToggle('NoClip', {
    Text = 'NoClip',
    Default = false,
    Callback = function(Value)
        getgenv().NoClip = Value
    end
})

MovementBox:AddLabel('NoClip Key'):AddKeyPicker('NoClipKey', {
    Default = 'C',
    Text = 'NoClip Toggle',
    Mode = 'Toggle',
    Callback = function()
        getgenv().NoClip = not getgenv().NoClip
        Toggles.NoClip:SetValue(getgenv().NoClip)
    end
})

-- Abilities
AbilitiesBox:AddToggle('GodMode', {
    Text = 'God Mode',
    Default = false,
    Callback = function(Value)
        if Value then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.MaxHealth = math.huge
                LocalPlayer.Character.Humanoid.Health = math.huge
            end
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.MaxHealth = 100
                LocalPlayer.Character.Humanoid.Health = 100
            end
        end
    end
})

AbilitiesBox:AddToggle('InfiniteStamina', {
    Text = 'Infinite Stamina',
    Default = false,
    Callback = function(Value)
        getgenv().InfStamina = Value
    end
})

AbilitiesBox:AddToggle('AntiAFK', {
    Text = 'Anti-AFK',
    Default = false,
    Callback = function(Value)
        if Value then
            local vu = game:GetService("VirtualUser")
            LocalPlayer.Idled:connect(function()
                vu:Button2Down(Vector2.new(0,0), Camera.CFrame)
                wait(1)
                vu:Button2Up(Vector2.new(0,0), Camera.CFrame)
            end)
        end
    end
})

AbilitiesBox:AddButton({
    Text = 'Reset Character',
    Func = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end
})

-- ==================== VISUAL TAB ====================
local ESPBox = Tabs.Visual:AddLeftGroupbox('ESP')
local ChamsBox = Tabs.Visual:AddLeftGroupbox('Chams')
local WorldBox = Tabs.Visual:AddRightGroupbox('World')
local CameraBox = Tabs.Visual:AddRightGroupbox('Camera')

-- ESP Variables
getgenv().ESPEnabled = false
getgenv().ESPBox = false
getgenv().ESPName = false
getgenv().ESPHealth = false
getgenv().ESPDistance = false
getgenv().ESPTeam = false

-- ESP Toggles
ESPBox:AddToggle('ESPMaster', {
    Text = 'Enable ESP',
    Default = false,
    Callback = function(Value)
        getgenv().ESPEnabled = Value
    end
})

ESPBox:AddDivider()

ESPBox:AddToggle('ESPBoxToggle', {
    Text = 'Box ESP',
    Default = false,
    Callback = function(Value)
        getgenv().ESPBox = Value
    end
})

ESPBox:AddToggle('ESPNameToggle', {
    Text = 'Name ESP',
    Default = false,
    Callback = function(Value)
        getgenv().ESPName = Value
    end
})

ESPBox:AddToggle('ESPHealthToggle', {
    Text = 'Health Bar',
    Default = false,
    Callback = function(Value)
        getgenv().ESPHealth = Value
    end
})

ESPBox:AddToggle('ESPDistanceToggle', {
    Text = 'Distance ESP',
    Default = false,
    Callback = function(Value)
        getgenv().ESPDistance = Value
    end
})

ESPBox:AddToggle('ESPTeamToggle', {
    Text = 'Team Check',
    Default = false,
    Callback = function(Value)
        getgenv().ESPTeam = Value
    end
})

-- ESP Functions
local function CreateESP(player)
    if not player.Character then return end
    
    local character = player.Character
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Remove old ESP
    if character:FindFirstChild("ESPHighlight") then
        character.ESPHighlight:Destroy()
    end
    
    -- Create Highlight for Box
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.Parent = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    
    -- Create BillboardGui for Name/Health/Distance
    local head = character:FindFirstChild("Head")
    if head and not head:FindFirstChild("ESPBillboard") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPBillboard"
        billboard.Parent = head
        billboard.Size = UDim2.new(0, 200, 0, 100)
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
        
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "DistanceLabel"
        distanceLabel.Parent = billboard
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Position = UDim2.new(0, 0, 0.66, 0)
        distanceLabel.Size = UDim2.new(1, 0, 0.33, 0)
        distanceLabel.Font = Enum.Font.SourceSans
        distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        distanceLabel.TextSize = 14
        distanceLabel.TextStrokeTransparency = 0
    end
end

-- Chams
ChamsBox:AddToggle('ChamsEnabled', {
    Text = 'Enable Chams',
    Default = false,
    Callback = function(Value)
        getgenv().Chams = Value
    end
})

ChamsBox:AddSlider('ChamsTransparency', {
    Text = 'Transparency',
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        getgenv().ChamsTransparency = Value
    end
})

-- World
WorldBox:AddToggle('FullBright', {
    Text = 'Full Bright',
    Default = false,
    Callback = function(Value)
        if Value then
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
    end
})

WorldBox:AddToggle('NoFog', {
    Text = 'No Fog',
    Default = false,
    Callback = function(Value)
        if Value then
            game.Lighting.FogEnd = 100000
        else
            game.Lighting.FogEnd = 500
        end
    end
})

WorldBox:AddSlider('TimeOfDay', {
    Text = 'Time of Day',
    Default = 14,
    Min = 0,
    Max = 24,
    Rounding = 1,
    Callback = function(Value)
        game.Lighting.ClockTime = Value
    end
})

WorldBox:AddToggle('RemoveShadows', {
    Text = 'Remove Shadows',
    Default = false,
    Callback = function(Value)
        game.Lighting.GlobalShadows = not Value
    end
})

-- Camera
CameraBox:AddSlider('FOV', {
    Text = 'Field of View',
    Default = 70,
    Min = 70,
    Max = 120,
    Rounding = 1,
    Callback = function(Value)
        Camera.FieldOfView = Value
    end
})

CameraBox:AddButton({
    Text = 'Reset FOV',
    Func = function()
        Camera.FieldOfView = 70
    end
})

CameraBox:AddToggle('ThirdPerson', {
    Text = 'Third Person',
    Default = false,
    Callback = function(Value)
        if Value then
            LocalPlayer.CameraMaxZoomDistance = 50
            LocalPlayer.CameraMinZoomDistance = 10
        else
            LocalPlayer.CameraMaxZoomDistance = 20
            LocalPlayer.CameraMinZoomDistance = 0.5
        end
    end
})

-- ==================== MISC TAB ====================
local TeleportBox = Tabs.Misc:AddLeftGroupbox('Teleport')
local RecentPlayersBox = Tabs.Misc:AddLeftGroupbox('Recent Players')
local GameBox = Tabs.Misc:AddRightGroupbox('Game')
local UtilityBox = Tabs.Misc:AddRightGroupbox('Utility')

-- Function to get all players
local function GetPlayerList()
    local playerList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    return playerList
end

-- Store selected player
getgenv().SelectedPlayer = nil

-- Create Dropdown for Player Selection
local PlayerDropdown = TeleportBox:AddDropdown('PlayerSelect', {
    Values = GetPlayerList(),
    Default = 1,
    Multi = false,
    Text = 'Select Player',
    Callback = function(Value)
        getgenv().SelectedPlayer = Value
    end
})

-- Refresh Player List
TeleportBox:AddButton({
    Text = 'Refresh Player List',
    Func = function()
        local newPlayerList = GetPlayerList()
        Options.PlayerSelect:SetValues(newPlayerList)
        if #newPlayerList > 0 then
            Options.PlayerSelect:SetValue(newPlayerList[1])
        end
        Library:Notify('Player list refreshed!', 2)
    end
})

-- Teleport to Selected Player
TeleportBox:AddButton({
    Text = 'Teleport to Selected',
    Func = function()
        if getgenv().SelectedPlayer then
            local targetPlayer = Players:FindFirstChild(getgenv().SelectedPlayer)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                Library:Notify('Teleported to ' .. getgenv().SelectedPlayer, 2)
            end
        end
    end
})

TeleportBox:AddButton({
    Text = 'Teleport to Random',
    Func = function()
        local players = Players:GetPlayers()
        local validPlayers = {}
        
        for _, player in pairs(players) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(validPlayers, player)
            end
        end
        
        if #validPlayers > 0 then
            local randomPlayer = validPlayers[math.random(1, #validPlayers)]
            LocalPlayer.Character.HumanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame
            Library:Notify('Teleported to ' .. randomPlayer.Name, 2)
        end
    end
})

TeleportBox:AddButton({
    Text = 'Teleport to Spawn',
    Func = function()
        local spawn = Workspace:FindFirstChild("SpawnLocation")
        if spawn then
            LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.CFrame
        end
    end
})

-- ==================== RECENT PLAYERS ====================
getgenv().RecentPlayers = getgenv().RecentPlayers or {}
getgenv().SelectedRecentPlayer = nil

local function GetRecentPlayers()
    local success, result = pcall(function()
        local HttpService = game:GetService("HttpService")
        local userId = LocalPlayer.UserId
        
        local recentList = {}
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(recentList, {
                    Name = player.Name,
                    UserId = player.UserId,
                    DisplayName = player.DisplayName,
                    Status = "In This Server"
                })
            end
        end
        
        return recentList
    end)
    
    if success and result then
        return result
    else
        return {}
    end
end

local function JoinPlayerServer(userId)
    local success, result = pcall(function()
        local HttpService = game:GetService("HttpService")
        
        local url = string.format("https://presence.roblox.com/v1/presence/users")
        local response = HttpService:JSONDecode(
            game:HttpPost(url, HttpService:JSONEncode({
                userIds = {userId}
            }))
        )
        
        if response and response.userPresences and #response.userPresences > 0 then
            local presence = response.userPresences[1]
            
            if presence.userPresenceType == 2 then
                local placeId = presence.placeId
                local jobId = presence.gameId
                
                if placeId and jobId then
                    Library:Notify('Joining player server...', 2)
                    wait(0.5)
                    game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
                    return true
                end
            else
                Library:Notify('Player is not in game!', 3)
                return false
            end
        end
    end)
    
    if not success then
        Library:Notify('Failed to join player server!', 3)
    end
end

local function UpdateRecentPlayers()
    local recentPlayers = GetRecentPlayers()
    local nameList = {}
    
    getgenv().RecentPlayers = recentPlayers
    
    for _, player in pairs(recentPlayers) do
        table.insert(nameList, player.Name .. " (" .. player.Status .. ")")
    end
    
    if #nameList > 0 then
        Options.RecentPlayerSelect:SetValues(nameList)
        Options.RecentPlayerSelect:SetValue(nameList[1])
    else
        Options.RecentPlayerSelect:SetValues({"No recent players"})
    end
    
    return #nameList
end

RecentPlayersBox:AddDropdown('RecentPlayerSelect', {
    Values = {"Click refresh to load..."},
    Default = 1,
    Multi = false,
    Text = 'Select Recent Player',
    Callback = function(Value)
        local playerName = Value:match("^(.+)%s%(")
        if playerName then
            for _, player in pairs(getgenv().RecentPlayers) do
                if player.Name == playerName then
                    getgenv().SelectedRecentPlayer = player
                    break
                end
            end
        end
    end
})

RecentPlayersBox:AddButton({
    Text = 'Refresh Recent Players',
    Func = function()
        local count = UpdateRecentPlayers()
        Library:Notify('Found ' .. count .. ' recent players', 2)
    end,
    Tooltip = 'Update the recent players list'
})

RecentPlayersBox:AddButton({
    Text = 'Join Selected Player',
    Func = function()
        if getgenv().SelectedRecentPlayer then
            local player = getgenv().SelectedRecentPlayer
            
            if player.Status == "In This Server" then
                local targetPlayer = Players:FindFirstChild(player.Name)
                if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                    Library:Notify('Teleported to ' .. player.Name, 2)
                end
            else
                JoinPlayerServer(player.UserId)
            end
        else
            Library:Notify('Please select a player first!', 3)
        end
    end,
    Tooltip = 'Join or teleport to selected player'
})

RecentPlayersBox:AddLabel('Note: Only shows current server')
RecentPlayersBox:AddLabel('players due to API limitations')

-- Game
GameBox:AddButton({
    Text = 'Rejoin Same Server',
    Func = function()
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\nRejoining...")
            wait()
            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
        else
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end,
    Tooltip = 'Rejoin to this exact server'
})

GameBox:AddButton({
    Text = 'Join Another Server',
    Func = function()
        local currentJobId = game.JobId
        local PlaceId = game.PlaceId
        
        Library:Notify('Finding another server...', 2)
        
        local success, servers = pcall(function()
            return game:GetService('HttpService'):JSONDecode(
                game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceId .. '/servers/Public?sortOrder=Asc&limit=100')
            )
        end)
        
        if success and servers and servers.data then
            for _, server in pairs(servers.data) do
                if server.id ~= currentJobId and tonumber(server.playing) < tonumber(server.maxPlayers) then
                    Library:Notify('Joining different server...', 2)
                    wait(0.5)
                    game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                    return
                end
            end
            Library:Notify('No other servers available!', 3)
        else
            Library:Notify('Failed to get server list!', 3)
        end
    end,
    Tooltip = 'Join a different server (not current one)'
})

GameBox:AddButton({
    Text = 'Rejoin (Any Server)',
    Func = function()
        LocalPlayer:Kick("\nRejoining...")
        wait()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
    Tooltip = 'Rejoin to any available server'
})

GameBox:AddDivider()

getgenv().CustomJobId = ""

GameBox:AddInput('CustomJobID', {
    Default = '',
    Numeric = false,
    Finished = false,
    Text = 'Custom Job ID',
    Tooltip = 'Enter JobId to join specific server',
    Placeholder = 'Paste Job ID here...',
    Callback = function(Value)
        getgenv().CustomJobId = Value
        if Value ~= "" then
            Library:Notify('Job ID saved: ' .. Value:sub(1, 15) .. '...', 2)
        end
    end
})

GameBox:AddButton({
    Text = 'Join Server (JobId)',
    Func = function()
        local jobId = getgenv().CustomJobId
        
        if jobId and jobId ~= "" and #jobId > 10 then
            Library:Notify('Joining server...', 2)
            wait(0.5)
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        else
            Library:Notify('Please enter a valid JobId first!', 3)
        end
    end,
    Tooltip = 'Join server using the JobId above'
})

GameBox:AddButton({
    Text = 'Copy Current Job ID',
    Func = function()
        setclipboard(game.JobId)
        Options.CustomJobID:SetValue(game.JobId)
        getgenv().CustomJobId = game.JobId
        Library:Notify('Job ID copied and loaded!', 2)
    end,
    Tooltip = 'Copy this server JobId'
})

GameBox:AddDivider()

GameBox:AddButton({
    Text = 'Server Hop',
    Func = function()
        local PlaceId = game.PlaceId
        local AllIDs = {}
        local foundAnything = ""
        local actualHour = os.date("!*t").hour
        local Deleted = false
        
        local File = pcall(function()
            AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
        end)
        
        if not File then
            table.insert(AllIDs, actualHour)
            writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
        end
        
        function TPReturner()
            local Site
            if foundAnything == "" then
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceId .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
            
            local ID = ""
            if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
                foundAnything = Site.nextPageCursor
            end
            
            for i,v in pairs(Site.data) do
                local Possible = true
                ID = tostring(v.id)
                if tonumber(v.maxPlayers) > tonumber(v.playing) then
                    for _,Existing in pairs(AllIDs) do
                        if ID == tostring(Existing) then
                            Possible = false
                        end
                    end
                    if Possible == true then
                        table.insert(AllIDs, ID)
                        wait()
                        pcall(function()
                            writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
                            wait()
                            game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceId, ID, game.Players.LocalPlayer)
                        end)
                        wait(4)
                    end
                end
            end
        end
        
        function Teleport()
            while wait() do
                pcall(function()
                    TPReturner()
                    if foundAnything ~= "" then
                        TPReturner()
                    end
                end)
            end
        end
        
        Teleport()
    end,
    DoubleClick = true
})

GameBox:AddDivider()

GameBox:AddLabel('Place ID: ' .. game.PlaceId)
GameBox:AddLabel('Current Job ID: ' .. game.JobId:sub(1, 20) .. '...')

-- Utility
UtilityBox:AddButton({
    Text = 'FPS Booster',
    Func = function()
        local decalsyeeted = true
        local g = game
        local w = g.Workspace
        local l = g.Lighting
        local t = w.Terrain
        
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 0
        l.GlobalShadows = false
        l.FogEnd = 9e9
        l.Brightness = 0
        settings().Rendering.QualityLevel = "Level01"
        
        for i, v in pairs(g:GetDescendants()) do
            if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") and decalsyeeted then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Explosion") then
                v.BlastPressure = 1
                v.BlastRadius = 1
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("MeshPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
            end
        end
        
        Library:Notify('FPS Boost applied!', 3)
    end
})

UtilityBox:AddButton({
    Text = 'Remove Textures',
    Func = function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                v:Destroy()
            end
        end
        Library:Notify('Textures removed!', 2)
    end
})

UtilityBox:AddToggle('AutoSprint', {
    Text = 'Auto Sprint',
    Default = false,
    Callback = function(Value)
        getgenv().AutoSprint = Value
    end
})

-- Auto-refresh player list
Players.PlayerAdded:Connect(function()
    wait(0.5)
    Options.PlayerSelect:SetValues(GetPlayerList())
end)

Players.PlayerRemoving:Connect(function()
    wait(0.5)
    local list = GetPlayerList()
    Options.PlayerSelect:SetValues(list)
    if #list > 0 then
        Options.PlayerSelect:SetValue(list[1])
    end
end)

-- ==================== MAIN LOOPS ====================

-- Aimbot Loop
RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Update FOV Circle Position
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = mousePos
        FOVCircle.Visible = getgenv().Aimbot.ShowFOV and getgenv().Aimbot.Enabled
        
        -- Check if right click is held
        local isRightClickHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        
        if getgenv().Aimbot.Enabled and isRightClickHeld then
            getgenv().Aimbot.IsAiming = true
            
            local target = GetClosestPlayerToCursor()
            getgenv().Aimbot.CurrentTarget = target
            
            if target and target.Character then
                local aimPart = target.Character:FindFirstChild(getgenv().Aimbot.AimPart)
                
                if aimPart then
                    -- Update target label
                    for _, v in pairs(Tabs.Combat:GetChildren()) do
                        if v.Name == "AimbotVisualBox" then
                            for _, label in pairs(v:GetDescendants()) do
                                if label:IsA("TextLabel") and label.Text:find("Current Target:") then
                                    label.Text = "Current Target: " .. target.Name
                                end
                            end
                        end
                    end
                    
                    -- Apply highlight to target
                    if getgenv().Aimbot.TargetHighlight then
                        if not TargetHighlight or TargetHighlight.Parent ~= target.Character then
                            if TargetHighlight then
                                TargetHighlight:Destroy()
                            end
                            
                            TargetHighlight = Instance.new("Highlight")
                            TargetHighlight.Name = "AimbotTargetHighlight"
                            TargetHighlight.Parent = target.Character
                            TargetHighlight.FillColor = getgenv().Aimbot.HighlightColor
                            TargetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                            TargetHighlight.FillTransparency = 0.5
                            TargetHighlight.OutlineTransparency = 0
                        end
                    end
                    
                    -- Aim at predicted position
                    local targetPos = GetPredictedPosition(aimPart)
                    AimAt(targetPos)
                end
            else
                -- Clear target label
                for _, v in pairs(Tabs.Combat:GetChildren()) do
                    if v.Name == "AimbotVisualBox" then
                        for _, label in pairs(v:GetDescendants()) do
                            if label:IsA("TextLabel") and label.Text:find("Current Target:") then
                                label.Text = "Current Target: None"
                            end
                        end
                    end
                end
                
                -- Remove highlight
                if TargetHighlight then
                    TargetHighlight:Destroy()
                    TargetHighlight = nil
                end
            end
        else
            getgenv().Aimbot.IsAiming = false
            getgenv().Aimbot.CurrentTarget = nil
            
            -- Clear target label when not aiming
            for _, v in pairs(Tabs.Combat:GetChildren()) do
                if v.Name == "AimbotVisualBox" then
                    for _, label in pairs(v:GetDescendants()) do
                        if label:IsA("TextLabel") and label.Text:find("Current Target:") then
                            label.Text = "Current Target: None"
                        end
                    end
                end
            end
            
            -- Remove highlight when not aiming
            if TargetHighlight then
                TargetHighlight:Destroy()
                TargetHighlight = nil
            end
        end
    end)
end)

-- Movement Loop
RunService.Heartbeat:Connect(function()
    pcall(function()
        -- NoClip
        if getgenv().NoClip and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        
        -- Infinite Jump
        if getgenv().InfJump then
            UserInputService.JumpRequest:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
                end
            end)
        end
        
        -- ESP Update
        if getgenv().ESPEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if not player.Character:FindFirstChild("ESPHighlight") then
                        CreateESP(player)
                    end
                    
                    local character = player.Character
                    local highlight = character:FindFirstChild("ESPHighlight")
                    local head = character:FindFirstChild("Head")
                    local billboard = head and head:FindFirstChild("ESPBillboard")
                    
                    -- Update Highlight (Box)
                    if highlight then
                        highlight.Enabled = getgenv().ESPBox
                    end
                    
                    -- Update Billboard
                    if billboard then
                        billboard.Enabled = getgenv().ESPName or getgenv().ESPHealth or getgenv().ESPDistance
                        
                        if getgenv().ESPName then
                            billboard.NameLabel.Visible = true
                        else
                            billboard.NameLabel.Visible = false
                        end
                        
                        if getgenv().ESPHealth and character:FindFirstChildOfClass("Humanoid") then
                            local humanoid = character:FindFirstChildOfClass("Humanoid")
                            local health = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                            billboard.HealthLabel.Text = health .. " HP"
                            billboard.HealthLabel.TextColor3 = Color3.fromRGB(255 - (health * 2.55), health * 2.55, 0)
                            billboard.HealthLabel.Visible = true
                        else
                            billboard.HealthLabel.Visible = false
                        end
                        
                        if getgenv().ESPDistance and character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local distance = math.floor((character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                            billboard.DistanceLabel.Text = distance .. "m"
                            billboard.DistanceLabel.Visible = true
                        else
                            billboard.DistanceLabel.Visible = false
                        end
                    end
                end
            end
        else
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    local highlight = player.Character:FindFirstChild("ESPHighlight")
                    if highlight then highlight.Enabled = false end
                    
                    local head = player.Character:FindFirstChild("Head")
                    local billboard = head and head:FindFirstChild("ESPBillboard")
                    if billboard then billboard.Enabled = false end
                end
            end
        end
        
        -- Chams
        if getgenv().Chams then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local highlight = player.Character:FindFirstChild("ESPHighlight")
                    if highlight then
                        highlight.Enabled = true
                        highlight.FillTransparency = (getgenv().ChamsTransparency or 50) / 100
                    end
                end
            end
        end
    end)
end)

-- Character Respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    wait(0.5)
    pcall(function()
        if Options.WalkSpeed and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Options.WalkSpeed.Value
        end
        if Options.JumpPower and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = Options.JumpPower.Value
        end
    end)
end)

-- UI Settings
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder('draxUniversal')
SaveManager:SetFolder('draxUniversal/configs')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

pcall(function()
    SaveManager:LoadAutoloadConfig()
end)

-- Load notification
Library:Notify('drax universal v1.0 + Aimbot loaded!', 3)
print('drax universal v1.0 + Aimbot | All features loaded!')
print('Aimbot: Right Click to aim at closest target in FOV')
