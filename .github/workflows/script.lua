-- ==========================================
-- 🛡️ BROWSER & ENVIRONMENT PROTECTION
-- ==========================================
if not game or not pcall(function() return game:GetService("CoreGui") end) then
    return
end

if not identifyexecutor or not pcall(function() return identifyexecutor() end) then
    return
end

-- ==========================================
-- 🛡️ SAFE UNLOADER & MEMORY CLEANUP
-- ==========================================
if getgenv().KudasaiLoaded then
    getgenv().KudasaiLoaded = false
    if _G.KudasaiConnections then
        for _, conn in ipairs(_G.KudasaiConnections) do pcall(function() conn:Disconnect() end) end
    end
    if _G.KudasaiESPObjects then
        for _, obj in pairs(_G.KudasaiESPObjects) do
            pcall(function()
                if obj.Text then obj.Text:Remove() end
                if obj.Box then obj.Box:Remove() end
                if obj.Tracer then obj.Tracer:Remove() end
                if obj.HeadDot then obj.HeadDot:Remove() end
                if obj.Highlight then obj.Highlight:Destroy() end
            end)
        end
    end
    
    -- Revert Hitboxes if active
    pcall(function()
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                p.Character.HumanoidRootPart.Transparency = 1
            end
        end
    end)

    pcall(function() if _G.KudasaiUI then _G.KudasaiUI:Destroy() end end)
    task.wait(0.2)
end

getgenv().KudasaiLoaded = true
_G.KudasaiConnections = {}
_G.KudasaiESPObjects = {}

local function AddConnection(conn)
    table.insert(_G.KudasaiConnections, conn)
    return conn
end

-- ==========================================
-- ⚙️ SERVICES & GLOBALS
-- ==========================================
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Failed to load Rayfield UI library.")
    return
end

_G.KudasaiUI = Rayfield

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StatsService = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local function copyText(str)
    if setclipboard then setclipboard(tostring(str)) elseif toclipboard then toclipboard(tostring(str)) end
end

local StartTime = tick()
local NotificationsEnabled = true
local function sendNotify(title, content, duration)
    if NotificationsEnabled then
        pcall(function() Rayfield:Notify({ Title = title, Content = content, Duration = duration or 2 }) end)
    end
end

-- ==========================================
-- 🚀 MAIN HUB INITIALIZATION
-- ==========================================
local function InitMainHub()
    local Window = Rayfield:CreateWindow({
        Name = "kudasai's universal hub v3",
        Icon = 0,
        LoadingTitle = "Initializing Systems...",
        LoadingSubtitle = "by kudasai & z1.f",
        ShowText = "Rayfield",
        Theme = "Default",
        ToggleUIKeybind = "K",
        ConfigurationSaving = { Enabled = true, FolderName = "kudasai_hub_v3", FileName = "config" },
        KeySystem = false
    })

    local HomeTab        = Window:CreateTab("Home", 4483362458)
    local CombatTab      = Window:CreateTab("Combat", 4483345998)
    local MovementTab    = Window:CreateTab("Movement", 4483362458)
    local VisualsTab     = Window:CreateTab("Visuals", 4483345998)
    local PlayerTab      = Window:CreateTab("Player", 4483362748)
    local ServerTab      = Window:CreateTab("Server", 4483362458)
    local CameraTab      = Window:CreateTab("Camera", 4483345998)
    local InteractionTab = Window:CreateTab("Interaction", 4483362748)
    local MiscTab        = Window:CreateTab("Misc", 4483362748)
    local SettingsTab    = Window:CreateTab("Settings", 4483362748)

    -- ==========================================
    -- 🏠 1. HOME TAB
    -- ==========================================
    HomeTab:CreateSection("Welcome")
    HomeTab:CreateLabel("Welcome back, " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")")

    HomeTab:CreateSection("Live Diagnostics")
    local fpsLabel = HomeTab:CreateLabel("FPS: Calculating...")
    local pingLabel = HomeTab:CreateLabel("Ping: Calculating...")
    local serverUptimeLabel = HomeTab:CreateLabel("Uptime: 0s")

    task.spawn(function()
        while getgenv().KudasaiLoaded do
            local fps = math.floor(workspace:GetRealPhysicsFPS())
            local ping = 0
            local perf = StatsService:FindFirstChild("PerformanceStats")
            if perf and perf:FindFirstChild("Ping") then ping = math.floor(perf.Ping:GetValue()) end
            local uptime = math.floor(tick() - StartTime)
            
            pcall(function()
                fpsLabel:Set(string.format("FPS: %d", fps))
                pingLabel:Set(string.format("Ping: %d ms", ping))
                serverUptimeLabel:Set(string.format("Uptime: %02dh %02dm %02ds", math.floor(uptime/3600), math.floor((uptime%3600)/60), uptime%60))
            end)
            task.wait(1)
        end
    end)

    HomeTab:CreateSection("Session Data")
    HomeTab:CreateLabel("Place ID: " .. tostring(game.PlaceId))
    HomeTab:CreateLabel("Job ID: " .. tostring(game.JobId ~= "" and game.JobId or "Local Server"))
    HomeTab:CreateButton({
        Name = "Quick Rejoin",
        Callback = function()
            sendNotify("Rejoin", "Reconnecting to server...", 3)
            if #Players:GetPlayers() <= 1 then
                LocalPlayer:Kick("\nRejoining...")
                task.wait()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end
        end,
    })

    -- ==========================================
    -- ⚔️ 2. COMBAT TAB
    -- ==========================================
    local AimlockEnabled, AimlockTeamCheck, AimlockShowFOV = false, false, false
    local AimlockKey = Enum.UserInputType.MouseButton2
    local AimlockTargetPart = "Head"
    local AimlockSmoothness, AimlockFOV = 1, 120
    local aimTarget, isAiming = nil, false

    local fovCircle
    pcall(function()
        if Drawing then
            fovCircle = Drawing.new("Circle")
            fovCircle.Thickness = 1
            fovCircle.NumSides = 64
            fovCircle.Filled = false
            fovCircle.Color = Color3.fromRGB(255, 255, 255)
            fovCircle.Visible = false
        end
    end)

    local function GetClosestTarget()
        local bestTarget, shortestDist = nil, AimlockFOV
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and (not AimlockTeamCheck or player.Team ~= LocalPlayer.Team) then
                local part = player.Character:FindFirstChild(AimlockTargetPart)
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if screenDist < shortestDist then shortestDist = screenDist bestTarget = part end
                    end
                end
            end
        end
        return bestTarget
    end

    AddConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not AimlockEnabled then return end
        if gameProcessed and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
        if input.UserInputType == AimlockKey or input.KeyCode == AimlockKey then
            isAiming = true
            aimTarget = GetClosestTarget()
        end
    end))

    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == AimlockKey or input.KeyCode == AimlockKey then
            isAiming = false
            aimTarget = nil
        end
    end))

    AddConnection(RunService.RenderStepped:Connect(function()
        if fovCircle then
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            fovCircle.Radius = AimlockFOV
            fovCircle.Visible = AimlockEnabled and AimlockShowFOV
        end

        if not AimlockEnabled or not isAiming or not aimTarget or not aimTarget.Parent then 
            aimTarget = nil return 
        end

        local hum = aimTarget.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, aimTarget.Position)
            Camera.CFrame = AimlockSmoothness <= 1 and targetCFrame or Camera.CFrame:Lerp(targetCFrame, 1 / AimlockSmoothness)
        else
            aimTarget, isAiming = nil, false
        end
    end))

    CombatTab:CreateSection("Aim Lock Controls")
    CombatTab:CreateToggle({ Name = "Enable Aim Lock (Hold RMB)", CurrentValue = false, Flag = "t_aim", Callback = function(v) AimlockEnabled = v aimTarget = nil isAiming = false end })
    CombatTab:CreateToggle({ Name = "Show FOV Circle", CurrentValue = false, Flag = "t_fov", Callback = function(v) AimlockShowFOV = v end })
    CombatTab:CreateToggle({ Name = "Team Check", CurrentValue = false, Flag = "t_ateam", Callback = function(v) AimlockTeamCheck = v aimTarget = nil end })
    CombatTab:CreateDropdown({ Name = "Target Bone", Options = {"Head", "HumanoidRootPart", "UpperTorso"}, CurrentOption = {"Head"}, Flag = "d_bone", Callback = function(o) AimlockTargetPart = o[1] aimTarget = nil end })
    CombatTab:CreateSlider({ Name = "FOV Radius", Range = {30, 600}, Increment = 10, CurrentValue = 120, Flag = "s_fov", Callback = function(v) AimlockFOV = v end })
    CombatTab:CreateSlider({ Name = "Aim Smoothness", Range = {1, 20}, Increment = 1, CurrentValue = 1, Flag = "s_smooth", Callback = function(v) AimlockSmoothness = v end })

    CombatTab:CreateSection("Hitbox & Trigger")

    local triggerBot = false
    CombatTab:CreateToggle({ Name = "TriggerBot (Auto-Shoot)", CurrentValue = false, Flag = "t_tbot", Callback = function(v) triggerBot = v end })
    AddConnection(RunService.RenderStepped:Connect(function()
        if triggerBot and Mouse.Target then
            local model = Mouse.Target:FindFirstAncestorOfClass("Model")
            if model and model:FindFirstChild("Humanoid") and model.Name ~= LocalPlayer.Name then
                pcall(function() mouse1click() end)
                task.wait(0.05)
            end
        end
    end))

    local hitboxExpander = false
    local hitboxSize = 5
    CombatTab:CreateToggle({ 
        Name = "Hitbox Expander", CurrentValue = false, Flag = "t_hitbox", 
        Callback = function(v) 
            hitboxExpander = v 
            if not v then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                        p.Character.HumanoidRootPart.Transparency = 1
                    end
                end
            end
        end 
    })
    CombatTab:CreateSlider({ Name = "Hitbox Size", Range = {2, 25}, Increment = 1, CurrentValue = 5, Flag = "s_hboxsize", Callback = function(v) hitboxSize = v end })

    AddConnection(RunService.RenderStepped:Connect(function()
        if hitboxExpander then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    if not AimlockTeamCheck or p.Team ~= LocalPlayer.Team then
                        local hrp = p.Character.HumanoidRootPart
                        hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                        hrp.Transparency = 0.5
                        hrp.CanCollide = false
                    end
                end
            end
        end
    end))

    -- ==========================================
    -- 🏃 3. MOVEMENT TAB
    -- ==========================================
    MovementTab:CreateSection("Locomotion")
    local wsSlider = MovementTab:CreateSlider({ Name = "WalkSpeed", Range = {16, 350}, Increment = 1, CurrentValue = 16, Flag = "m_ws", Callback = function(v) local c = LocalPlayer.Character if c and c:FindFirstChildOfClass("Humanoid") then c.Humanoid.WalkSpeed = v end end })
    local jpSlider = MovementTab:CreateSlider({ Name = "JumpPower", Range = {50, 400}, Increment = 1, CurrentValue = 50, Flag = "m_jp", Callback = function(v) local c = LocalPlayer.Character if c and c:FindFirstChildOfClass("Humanoid") then c.Humanoid.UseJumpPower = true c.Humanoid.JumpPower = v end end })
    local gravSlider = MovementTab:CreateSlider({ Name = "Gravity", Range = {0, 300}, Increment = 1, CurrentValue = workspace.Gravity, Flag = "m_grav", Callback = function(v) workspace.Gravity = v end })

    MovementTab:CreateButton({
        Name = "Reset WalkSpeed, JumpPower & Gravity",
        Callback = function()
            local c = LocalPlayer.Character
            if c and c:FindFirstChildOfClass("Humanoid") then c.Humanoid.WalkSpeed = 16 c.Humanoid.JumpPower = 50 end
            workspace.Gravity = 196.2
            pcall(function() wsSlider:Set(16) jpSlider:Set(50) gravSlider:Set(196.2) end)
            sendNotify("Reset", "Physics restored to default values.", 2)
        end
    })

    MovementTab:CreateSection("Automation & Assists")
    local infJump = false
    MovementTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Flag = "t_infj", Callback = function(v) infJump = v end })
    AddConnection(UserInputService.JumpRequest:Connect(function()
        if infJump and LocalPlayer.Character then
            local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))

    local autoJump, bunnyHop = false, false
    MovementTab:CreateToggle({ Name = "Auto-Jump", CurrentValue = false, Flag = "t_aj", Callback = function(v) autoJump = v end })
    MovementTab:CreateToggle({ Name = "Bunny Hop", CurrentValue = false, Flag = "t_bh", Callback = function(v) bunnyHop = v end })
    AddConnection(RunService.RenderStepped:Connect(function()
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h and h.FloorMaterial ~= Enum.Material.Air then
            if autoJump or (bunnyHop and h.MoveDirection.Magnitude > 0) then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))

    local noclip = false
    MovementTab:CreateToggle({ Name = "NoClip", CurrentValue = false, Flag = "t_nc", Callback = function(v) noclip = v end })
    AddConnection(RunService.Stepped:Connect(function()
        if noclip and LocalPlayer.Character then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end))

    local spinbot, spinSpeed = false, 50
    MovementTab:CreateToggle({ Name = "Spinbot", CurrentValue = false, Flag = "t_spin", Callback = function(v) spinbot = v end })
    MovementTab:CreateSlider({ Name = "Spin Speed", Range = {10, 100}, Increment = 5, CurrentValue = 50, Flag = "s_spins", Callback = function(v) spinSpeed = v end })
    AddConnection(RunService.Stepped:Connect(function()
        if spinbot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
        end
    end))

    local flying, flySpeed, flyBV, flyBG = false, 50, nil, nil
    local function stopFly()
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = false end
    end

    MovementTab:CreateToggle({
        Name = "Fly (WASD)", CurrentValue = false, Flag = "t_fly",
        Callback = function(v)
            flying = v
            if flying then
                local c = LocalPlayer.Character
                if c and c:FindFirstChild("HumanoidRootPart") then
                    flyBV = Instance.new("BodyVelocity", c.HumanoidRootPart)
                    flyBV.Velocity = Vector3.zero
                    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    flyBG = Instance.new("BodyGyro", c.HumanoidRootPart)
                    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                    flyBG.P = 9e4
                    c:FindFirstChildOfClass("Humanoid").PlatformStand = true
                end
            else stopFly() end
        end
    })
    MovementTab:CreateSlider({ Name = "Fly Speed", Range = {10, 250}, Increment = 5, CurrentValue = 50, Flag = "s_fs", Callback = function(v) flySpeed = v end })

    AddConnection(RunService.RenderStepped:Connect(function()
        if flying and flyBV and flyBG then
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
            flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
            flyBG.CFrame = Camera.CFrame
        end
    end))

    -- ==========================================
    -- 👁️ 4. VISUALS TAB (UNIFIED ESP)
    -- ==========================================
    local ESPMaster, ESPNames, ESPDist, ESPHealth, ESPTeamCheck = false, true, true, true, false
    local ESPTracers, ESPBoxes, ESPHeadDots, ESPChams = false, false, false, false
    local ESPMaxDist, ESPColor, ESPTrans = 1500, Color3.fromRGB(255, 60, 60), 0.8

    local function GetESPObj(plr)
        if not _G.KudasaiESPObjects[plr] then
            local obj = {}
            pcall(function()
                obj.Text = Drawing.new("Text") obj.Text.Visible = false obj.Text.Center = true obj.Text.Outline = true obj.Text.Font = 1
                obj.Box = Drawing.new("Square") obj.Box.Visible = false obj.Box.Filled = false obj.Box.Thickness = 1
                obj.Tracer = Drawing.new("Line") obj.Tracer.Visible = false obj.Tracer.Thickness = 1
                obj.HeadDot = Drawing.new("Circle") obj.HeadDot.Visible = false obj.HeadDot.Filled = true obj.HeadDot.Radius = 4
                obj.Highlight = Instance.new("Highlight") obj.Highlight.Enabled = false obj.Highlight.FillTransparency = 0.5 obj.Highlight.OutlineTransparency = 0
            end)
            _G.KudasaiESPObjects[plr] = obj
        end
        return _G.KudasaiESPObjects[plr]
    end

    AddConnection(RunService.RenderStepped:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local obj = GetESPObj(plr)
                if obj and obj.Text then
                    local visible = false
                    local c = plr.Character
                    local root = c and c:FindFirstChild("HumanoidRootPart")
                    local head = c and c:FindFirstChild("Head")
                    local hum = c and c:FindFirstChildOfClass("Humanoid")
                    
                    if ESPMaster and root and head and hum and hum.Health > 0 then
                        local myChar = LocalPlayer.Character
                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        local dist = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 0

                        if (dist <= ESPMaxDist) and (not ESPTeamCheck or plr.Team ~= LocalPlayer.Team) then
                            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                            local rootPos = Camera:WorldToViewportPoint(root.Position)
                            local bottomPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

                            if onScreen then
                                visible = true
                                local label = (ESPNames and plr.Name.." " or "")..(ESPDist and "["..dist.."m] " or "")..(ESPHealth and "("..math.floor(hum.Health).."hp)" or "")
                                
                                obj.Text.Text = label obj.Text.Size = 13 obj.Text.Color = ESPColor obj.Text.Transparency = ESPTrans
                                obj.Text.Position = Vector2.new(headPos.X, headPos.Y - 20) obj.Text.Visible = (label ~= "")

                                if ESPBoxes then
                                    local h = math.abs(headPos.Y - bottomPos.Y) local w = h * 0.65
                                    obj.Box.Size = Vector2.new(w, h) obj.Box.Position = Vector2.new(rootPos.X - w/2, headPos.Y)
                                    obj.Box.Color = ESPColor obj.Box.Transparency = ESPTrans obj.Box.Visible = true
                                else obj.Box.Visible = false end

                                if ESPTracers then
                                    obj.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y) obj.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                                    obj.Tracer.Color = ESPColor obj.Tracer.Transparency = ESPTrans obj.Tracer.Visible = true
                                else obj.Tracer.Visible = false end

                                if ESPHeadDots then
                                    obj.HeadDot.Position = Vector2.new(headPos.X, headPos.Y + 5) obj.HeadDot.Color = ESPColor
                                    obj.HeadDot.Transparency = ESPTrans obj.HeadDot.Visible = true
                                else obj.HeadDot.Visible = false end

                                if ESPChams then
                                    obj.Highlight.Parent = c obj.Highlight.FillColor = ESPColor obj.Highlight.OutlineColor = Color3.fromRGB(255,255,255) obj.Highlight.Enabled = true
                                else obj.Highlight.Enabled = false end
                            end
                        end
                    end
                    if not visible then
                        obj.Text.Visible = false obj.Box.Visible = false obj.Tracer.Visible = false obj.HeadDot.Visible = false obj.Highlight.Enabled = false
                    end
                end
            end
        end
    end))

    VisualsTab:CreateSection("ESP Switches")
    VisualsTab:CreateToggle({ Name = "Master ESP Toggle", CurrentValue = false, Flag = "e_m", Callback = function(v) ESPMaster = v end })
    VisualsTab:CreateToggle({ Name = "Show Names", CurrentValue = true, Flag = "e_n", Callback = function(v) ESPNames = v end })
    VisualsTab:CreateToggle({ Name = "Show Distance", CurrentValue = true, Flag = "e_d", Callback = function(v) ESPDist = v end })
    VisualsTab:CreateToggle({ Name = "Show Health", CurrentValue = true, Flag = "e_h", Callback = function(v) ESPHealth = v end })
    VisualsTab:CreateToggle({ Name = "Boxes", CurrentValue = false, Flag = "e_b", Callback = function(v) ESPBoxes = v end })
    VisualsTab:CreateToggle({ Name = "Tracers", CurrentValue = false, Flag = "e_t", Callback = function(v) ESPTracers = v end })
    VisualsTab:CreateToggle({ Name = "Head Dots", CurrentValue = false, Flag = "e_hd", Callback = function(v) ESPHeadDots = v end })
    VisualsTab:CreateToggle({ Name = "Chams", CurrentValue = false, Flag = "e_c", Callback = function(v) ESPChams = v end })
    VisualsTab:CreateToggle({ Name = "Team Check", CurrentValue = false, Flag = "e_tc", Callback = function(v) ESPTeamCheck = v end })
    VisualsTab:CreateColorPicker({ Name = "ESP Color", Color = Color3.fromRGB(255, 60, 60), Flag = "e_col", Callback = function(v) ESPColor = v end })

    VisualsTab:CreateSection("Lighting & Environment")
    local fullbright = false
    local origLighting = { Ambient = Lighting.Ambient, Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, GlobalShadows = Lighting.GlobalShadows }

    VisualsTab:CreateToggle({ 
        Name = "Fullbright", CurrentValue = false, Flag = "t_fb", 
        Callback = function(v) 
            fullbright = v 
            if v then
                origLighting = { Ambient = Lighting.Ambient, Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, GlobalShadows = Lighting.GlobalShadows }
            else
                Lighting.Ambient = origLighting.Ambient Lighting.Brightness = origLighting.Brightness Lighting.ClockTime = origLighting.ClockTime Lighting.GlobalShadows = origLighting.GlobalShadows
            end
        end 
    })
    AddConnection(RunService.RenderStepped:Connect(function()
        if fullbright then Lighting.Ambient = Color3.fromRGB(255, 255, 255) Lighting.Brightness = 2 Lighting.ClockTime = 14 Lighting.GlobalShadows = false end
    end))

    -- ==========================================
    -- 🧍 5. PLAYER TAB
    -- ==========================================
    PlayerTab:CreateSection("Defensive Systems")
    local antiFling = false
    AddConnection(RunService.Stepped:Connect(function()
        if not antiFling then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end
        local c = LocalPlayer.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r and (r.Velocity.Magnitude > 250 or r.RotVelocity.Magnitude > 250) then
            r.Velocity = Vector3.zero r.RotVelocity = Vector3.zero
            if r.AssemblyLinearVelocity then r.AssemblyLinearVelocity = Vector3.zero r.AssemblyAngularVelocity = Vector3.zero end
        end
    end))
    PlayerTab:CreateToggle({ Name = "Anti-Fling", CurrentValue = false, Flag = "t_af", Callback = function(v) antiFling = v end })

    local antiAFK, afkConn = false, nil
    PlayerTab:CreateToggle({ Name = "Anti-AFK", CurrentValue = false, Flag = "t_aafk", Callback = function(v)
        antiAFK = v
        if antiAFK then
            afkConn = LocalPlayer.Idled:Connect(function() pcall(function() VirtualUser:Button2Down(Vector2.zero, Camera.CFrame) task.wait(1) VirtualUser:Button2Up(Vector2.zero, Camera.CFrame) end) end)
            AddConnection(afkConn)
        elseif afkConn then afkConn:Disconnect() end
    end})

    PlayerTab:CreateButton({ Name = "Respawn", Callback = function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character.Humanoid.Health = 0 end end })
    PlayerTab:CreateButton({ Name = "Force Sit", Callback = function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character.Humanoid.Sit = true end end })

    PlayerTab:CreateSection("Visual Appearance (Client)")

    local avatarTarget = nil
    local function getAvatarPlrs() local t = {} for _,p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p.Name) end end if #t==0 then table.insert(t,"None") end return t end
    local avatarDD = PlayerTab:CreateDropdown({ Name = "Select Player to Copy", Options = getAvatarPlrs(), CurrentOption = {"None"}, Flag = "d_avatar", Callback = function(o) avatarTarget = Players:FindFirstChild(o[1]) end })
    AddConnection(Players.PlayerAdded:Connect(function() avatarDD:Refresh(getAvatarPlrs()) end))
    AddConnection(Players.PlayerRemoving:Connect(function() avatarDD:Refresh(getAvatarPlrs()) end))

    PlayerTab:CreateButton({
        Name = "Clone Avatar (Local)",
        Callback = function()
            if not avatarTarget or not avatarTarget.Character then 
                sendNotify("Error", "Target player or character not found.", 2) 
                return 
            end
            
            local myChar = LocalPlayer.Character
            local theirChar = avatarTarget.Character
            if not myChar then return end

            pcall(function()
                for _, v in ipairs(myChar:GetChildren()) do
                    if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") or v:IsA("CharacterMesh") then
                        v:Destroy()
                    end
                end
                
                for _, v in ipairs(theirChar:GetChildren()) do
                    if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") or v:IsA("CharacterMesh") then
                        v:Clone().Parent = myChar
                    end
                end
                
                local myHead = myChar:FindFirstChild("Head")
                local theirHead = theirChar:FindFirstChild("Head")
                if myHead and theirHead then
                    for _, v in ipairs(myHead:GetChildren()) do
                        if v:IsA("Decal") or v:IsA("SpecialMesh") then v:Destroy() end
                    end
                    for _, v in ipairs(theirHead:GetChildren()) do
                        if v:IsA("Decal") or v:IsA("SpecialMesh") then v:Clone().Parent = myHead end
                    end
                end
                sendNotify("Avatar Cloned", "Successfully copied " .. avatarTarget.Name .. "'s look.", 3)
            end)
        end
    })

    PlayerTab:CreateButton({
        Name = "Visual Headless (Client)",
        Callback = function()
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("Head") then
                c.Head.Transparency = 1
                if c.Head:FindFirstChildOfClass("Decal") then
                    c.Head:FindFirstChildOfClass("Decal").Transparency = 1
                end
                sendNotify("Headless", "Head transparency set to 1.", 2)
            end
        end,
    })

    PlayerTab:CreateButton({
        Name = "Visual Korblox (Client)",
        Callback = function()
            local c = LocalPlayer.Character
            if c then
                local rLeg = c:FindFirstChild("Right Leg")
                if rLeg then rLeg.Transparency = 1 end
                
                local r15Parts = {"RightUpperLeg", "RightLowerLeg", "RightFoot"}
                for _, pName in ipairs(r15Parts) do
                    local part = c:FindFirstChild(pName)
                    if part then 
                        part.Transparency = 1 
                        for _, v in ipairs(part:GetDescendants()) do
                            if v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
                        end
                    end
                end
                sendNotify("Korblox", "Right leg completely hidden.", 2)
            end
        end,
    })

    -- ==========================================
    -- 🌐 6. SERVER TAB
    -- ==========================================
    ServerTab:CreateSection("Network")
    ServerTab:CreateButton({ Name = "Server Hop", Callback = function()
        local api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local s, r = pcall(function() return HttpService:JSONDecode(game:HttpGet(api)) end)
        if s and r and r.data then
            for _, srv in ipairs(r.data) do
                if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer) return end
            end
        end
    end})
    ServerTab:CreateButton({ Name = "Copy JobId", Callback = function() copyText(game.JobId) sendNotify("Copied", "JobId copied") end })

    -- ==========================================
    -- 🎥 7. CAMERA TAB
    -- ==========================================
    CameraTab:CreateSection("Spectator")
    local specTarget = nil
    local function getSpecPlrs() local t = {} for _,p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p.Name) end end if #t==0 then table.insert(t,"None") end return t end
    local specDD = CameraTab:CreateDropdown({ Name = "Spectate Player", Options = getSpecPlrs(), CurrentOption = {"None"}, Flag = "d_spec", Callback = function(o) specTarget = Players:FindFirstChild(o[1]) end })
    AddConnection(Players.PlayerAdded:Connect(function() specDD:Refresh(getSpecPlrs()) end))
    AddConnection(Players.PlayerRemoving:Connect(function() specDD:Refresh(getSpecPlrs()) end))

    AddConnection(RunService.RenderStepped:Connect(function()
        if specTarget and specTarget.Character and specTarget.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = specTarget.Character.Humanoid
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = LocalPlayer.Character.Humanoid
            end
        end
    end))

    CameraTab:CreateButton({ Name = "Stop Spectating", Callback = function()
        specTarget = nil
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end
    end})

    CameraTab:CreateSection("Perspective")
    CameraTab:CreateSlider({ Name = "Field of View", Range = {40, 120}, Increment = 1, CurrentValue = 70, Flag = "c_fov", Callback = function(v) Camera.FieldOfView = v end })
    CameraTab:CreateSlider({ Name = "Max Zoom", Range = {10, 500}, Increment = 10, CurrentValue = 128, Flag = "c_mz", Callback = function(v) LocalPlayer.CameraMaxZoomDistance = v end })

    local showCrosshair, l1, l2 = false, nil, nil
    pcall(function() if Drawing then l1 = Drawing.new("Line") l2 = Drawing.new("Line") for _, l in ipairs({l1, l2}) do l.Thickness = 2 l.Color = Color3.fromRGB(0, 255, 170) l.Visible = false end end end)
    AddConnection(RunService.RenderStepped:Connect(function()
        if l1 and l2 then
            if showCrosshair then
                local mid = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                l1.From = Vector2.new(mid.X - 7, mid.Y) l1.To = Vector2.new(mid.X + 7, mid.Y) l1.Visible = true
                l2.From = Vector2.new(mid.X, mid.Y - 7) l2.To = Vector2.new(mid.X, mid.Y + 7) l2.Visible = true
            else l1.Visible = false l2.Visible = false end
        end
    end))
    CameraTab:CreateToggle({ Name = "Screen Crosshair", CurrentValue = false, Flag = "t_cx", Callback = function(v) showCrosshair = v end })

    -- ==========================================
    -- 🖱️ 8. INTERACTION TAB
    -- ==========================================
    local selectedTarget = nil
    local function getInteractPlrs() local t = {} for _,p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p.Name) end end if #t==0 then table.insert(t,"None") end return t end
    local interactDD = InteractionTab:CreateDropdown({ Name = "Select Target", Options = getInteractPlrs(), CurrentOption = {"None"}, Flag = "d_tgt", Callback = function(o) selectedTarget = Players:FindFirstChild(o[1]) end })
    AddConnection(Players.PlayerAdded:Connect(function() interactDD:Refresh(getInteractPlrs()) end))
    AddConnection(Players.PlayerRemoving:Connect(function() interactDD:Refresh(getInteractPlrs()) end))

    InteractionTab:CreateButton({ Name = "Goto Target", Callback = function()
        if selectedTarget and selectedTarget.Character and LocalPlayer.Character then
            LocalPlayer.Character:MoveTo(selectedTarget.Character:GetPivot().Position)
        end
    end})

    local clickTP = false
    AddConnection(Mouse.Button1Down:Connect(function()
        if clickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and LocalPlayer.Character and Mouse.Hit then
            LocalPlayer.Character:MoveTo(Mouse.Hit.Position)
        end
    end))
    InteractionTab:CreateToggle({ Name = "Click Teleport (LCtrl + Click)", CurrentValue = false, Flag = "t_ctp", Callback = function(v) clickTP = v end })

    InteractionTab:CreateSection("Target Fling Utility")

    local flingTargetPlayer = nil
    local function getFlingPlrs() local t = {} for _,p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(t, p.Name) end end if #t==0 then table.insert(t,"None") end return t end
    local flingDD = InteractionTab:CreateDropdown({ Name = "Select Player to Fling", Options = getFlingPlrs(), CurrentOption = {"None"}, Flag = "d_flingtgt", Callback = function(o) flingTargetPlayer = Players:FindFirstChild(o[1]) end })
    AddConnection(Players.PlayerAdded:Connect(function() flingDD:Refresh(getFlingPlrs()) end))
    AddConnection(Players.PlayerRemoving:Connect(function() flingDD:Refresh(getFlingPlrs()) end))

    local targetedFlingActive = false
    InteractionTab:CreateToggle({
        Name = "Enable Targeted Fling",
        CurrentValue = false,
        Flag = "t_targetedfling",
        Callback = function(v)
            targetedFlingActive = v
            sendNotify("Targeted Fling", v and "Flinging Target..." or "Fling Stopped", 2)
        end
    })

    AddConnection(RunService.Heartbeat:Connect(function()
        if not targetedFlingActive or not flingTargetPlayer or not flingTargetPlayer.Character or not LocalPlayer.Character then return end
        local targetRoot = flingTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        if targetRoot and myRoot and myHum then
            local originalPos = myRoot.CFrame
            myRoot.CFrame = targetRoot.CFrame
            myRoot.Velocity = Vector3.new(30000, 30000, 30000)
            RunService.RenderStepped:Wait()
        end
    end))

    -- ==========================================
    -- 🔧 9. MISC TAB
    -- ==========================================
    MiscTab:CreateSection("Chat & Messages")
    local chatSpammer = false
    local spamText = "kudasai hub v3 on top!"

    MiscTab:CreateInput({ 
        Name = "Spam Message", 
        PlaceholderText = "Enter message...", 
        RemoveTextAfterFocusLost = false, 
        Callback = function(t) 
            spamText = t 
        end 
    })

    MiscTab:CreateToggle({ 
        Name = "Enable Chat Spammer", 
        CurrentValue = false, 
        Flag = "t_chat", 
        Callback = function(v) 
            chatSpammer = v 
        end 
    })

    task.spawn(function()
        while task.wait(2) do
            if getgenv().KudasaiLoaded and chatSpammer and spamText ~= "" then
                pcall(function()
                    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                        TextChatService.TextChannels.RBXGeneral:SendAsync(spamText)
                    else
                        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(spamText, "All")
                    end
                end)
            end
        end
    end)

    MiscTab:CreateSection("Optimization")
    MiscTab:CreateSlider({ Name = "Max FPS Cap", Range = {30, 240}, Increment = 5, CurrentValue = 60, Flag = "s_fpscap", Callback = function(v) pcall(function() setfpscap(v) end) end })

    MiscTab:CreateButton({ Name = "Low Graphics Mode", Callback = function()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("ParticleEmitter") then v:Destroy() end
        end
        pcall(function() settings().Rendering.QualityLevel = 1 end)
    end})

    -- ==========================================
    -- ⚙️ 10. SETTINGS TAB
    -- ==========================================
    SettingsTab:CreateSection("System")
    SettingsTab:CreateButton({ Name = "Save Config", Callback = function() pcall(function() Rayfield:SaveConfiguration() end) sendNotify("Saved", "Config saved.") end })
    SettingsTab:CreateButton({
        Name = "Unload Script Entirely",
        Callback = function()
            getgenv().KudasaiLoaded = false
            if _G.KudasaiConnections then for _, conn in ipairs(_G.KudasaiConnections) do pcall(function() conn:Disconnect() end) end end
            if _G.KudasaiESPObjects then for _, obj in pairs(_G.KudasaiESPObjects) do pcall(function() obj.Text:Remove() obj.Box:Remove() obj.Tracer:Remove() obj.HeadDot:Remove() obj.Highlight:Destroy() end) end end
            if fovCircle then pcall(function() fovCircle:Remove() end) end
            if l1 then pcall(function() l1:Remove() l2:Remove() end) end
            
            pcall(function()
                stopFly()
                workspace.Gravity = 196.2
                Lighting.Ambient = origLighting.Ambient
                Lighting.Brightness = origLighting.Brightness
                Lighting.ClockTime = origLighting.ClockTime
                Lighting.GlobalShadows = origLighting.GlobalShadows
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                        p.Character.HumanoidRootPart.Transparency = 1
                    end
                end
            end)

            pcall(function() Rayfield:Destroy() end)
        end,
    })

    SettingsTab:CreateSection("Credits")
    SettingsTab:CreateLabel("Script Developer: kudasai")
    SettingsTab:CreateLabel("Co-Developer & UI Design: z1.f")

    pcall(function() Rayfield:LoadConfiguration() end)
end

-- ==========================================
-- 🔑 CUSTOM DISCORD KEY SYSTEM GUI & AUTO-AUTH
-- ==========================================
local CoreGui = game:GetService("CoreGui")
local premiumFilePath = "kudasai_univ_premium.txt"
local freeFilePath = "kudasai_univ_freekey.txt"
local duration = 6 * 60 * 60 -- 6 hours in seconds

local function HasActiveAuth()
    if not (isfile and readfile) then return false end
    
    -- 1. Check if they have the premium lifetime auth saved
    if isfile(premiumFilePath) then 
        return true 
    end
    
    -- 2. Check if they have an active 6-hour free key
    if isfile(freeFilePath) then
        local s, content = pcall(function() return readfile(freeFilePath) end)
        if s and content then
            local expiry = tonumber(content)
            if expiry and os.time() < expiry then
                return true
            end
        end
    end
    
    return false
end

-- If they are already authenticated, skip the GUI and load directly
if HasActiveAuth() then
    InitMainHub()
else
    local KeyScreen = Instance.new("ScreenGui")
    KeyScreen.Name = "KudasaiKeySystem"
    KeyScreen.ResetOnSpawn = false
    pcall(function() KeyScreen.Parent = CoreGui end)
    if not KeyScreen.Parent then KeyScreen.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local Frame = Instance.new("Frame", KeyScreen)
    Frame.Size = UDim2.new(0, 360, 0, 240)
    Frame.Position = UDim2.new(0.5, -180, 0.5, -120)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Frame.BorderSizePixel = 0

    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 8)

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Text = "Kudasai Hub | Key System"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.BackgroundTransparency = 1

    local LinkBox = Instance.new("TextBox", Frame)
    LinkBox.Size = UDim2.new(0.85, 0, 0, 30)
    LinkBox.Position = UDim2.new(0.075, 0, 0, 45)
    LinkBox.Text = "https://discord.gg/wGXEEzqxpk"
    LinkBox.TextColor3 = Color3.fromRGB(180, 180, 180)
    LinkBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    LinkBox.Font = Enum.Font.Gotham
    LinkBox.TextSize = 12
    LinkBox.ClearTextOnFocus = false
    LinkBox.TextEditable = false 
    Instance.new("UICorner", LinkBox).CornerRadius = UDim.new(0, 6)

    local CopyBtn = Instance.new("TextButton", Frame)
    CopyBtn.Size = UDim2.new(0.85, 0, 0, 32)
    CopyBtn.Position = UDim2.new(0.075, 0, 0, 85)
    CopyBtn.Text = "Copy Discord Link"
    CopyBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.TextSize = 13
    Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)

    CopyBtn.MouseButton1Click:Connect(function()
        copyText("https://discord.gg/wGXEEzqxpk")
        CopyBtn.Text = "Copied to Clipboard!"
        task.wait(1.5)
        CopyBtn.Text = "Copy Discord Link"
    end)

    local KeyInput = Instance.new("TextBox", Frame)
    KeyInput.Size = UDim2.new(0.85, 0, 0, 32)
    KeyInput.Position = UDim2.new(0.075, 0, 0, 130)
    KeyInput.PlaceholderText = "Enter key here..."
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.TextSize = 13
    Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 6)

    local SubmitBtn = Instance.new("TextButton", Frame)
    SubmitBtn.Size = UDim2.new(0.85, 0, 0, 32)
    SubmitBtn.Position = UDim2.new(0.075, 0, 0, 175)
    SubmitBtn.Text = "Submit Key"
    SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 120)
    SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitBtn.Font = Enum.Font.GothamBold
    SubmitBtn.TextSize = 13
    Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 6)

    SubmitBtn.MouseButton1Click:Connect(function()
        local entered = KeyInput.Text
        
        if entered == "kudasaiisgoated" then
            if writefile then pcall(function() writefile(premiumFilePath, "lifetime_auth") end) end
            KeyScreen:Destroy()
            InitMainHub()
            
        elseif entered == "kudasai-v3-freekey" then
            if writefile then pcall(function() writefile(freeFilePath, tostring(os.time() + duration)) end) end
            KeyScreen:Destroy()
            InitMainHub()
            
        else
            SubmitBtn.Text = "Invalid Key!"
            SubmitBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            task.wait(1.5)
            SubmitBtn.Text = "Submit Key"
            SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 120)
        end
    end)
end
