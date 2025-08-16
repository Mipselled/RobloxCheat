local scriptRunning = true -- Main toggle to enable/disable the script

--// Services
local Players = game:GetService("Players") -- Access to player data
local RunService = game:GetService("RunService") -- For frame-based updates
local UserInputService = game:GetService("UserInputService") -- Detect keyboard/mouse input
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera -- The player’s camera
local LocalPlayer = Players.LocalPlayer -- The local player

--// TP Settings
local sortMode = "distance" -- Determines teleport priority: by "distance" or "hp"

--// Flight variables
local flightActive = false -- Tracks if flight is active
local flyBodyVelocity, flyBodyGyro = nil, nil -- Physics objects used for flight
local flightSpeed = 50 -- Default flight speed

--// ESP variables
local espActive = true -- Toggle for ESP visibility
local espList = {} -- Table storing ESP elements for each player

local blockedNames = {} -- Players to ignore

-- Fetch blocked names from external source
local function fetchBlockedNames()
    local url = "https://raw.githubusercontent.com/Mipselled/RobloxCheat/refs/heads/main/blockednames.txt"
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success and response then
        for name in response:gmatch("[^\r\n]+") do
            blockedNames[name] = true -- Add each name to blockedNames
        end
    else
        warn("Failed to fetch blocked names from GitHub")
    end
end

fetchBlockedNames() -- Initialize blocked names

-- Check if a 3D point is inside the camera’s viewport
local function inViewport(v3)
    local s = Camera.ViewportSize
    return v3.Z > 0 and v3.X >= 0 and v3.X <= s.X and v3.Y >= 0 and v3.Y <= s.Y
end

-- Teleports the local player to the closest player (by distance or health)
local function teleportToClosestPlayer()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bestChar, bestHRP
    local bestValue = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not blockedNames[player.Name] and not string.match(player.Name, "^[A-Za-z]+_%d%d%d$") and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if targetHRP and humanoid and humanoid.Health > 0 then
                local value
                if sortMode == "hp" then
                    value = player.Character.Health -- Prioritize low health
                else
                    value = (hrp.Position - targetHRP.Position).Magnitude -- Prioritize distance
                end

                if value < bestValue then
                    bestValue = value
                    bestChar = player.Character
                    bestHRP = targetHRP
                end
            end
        end
    end

    if bestChar and bestHRP then
        local head = bestChar:FindFirstChild("Head")
        if head then
            local lookVec = head.CFrame.LookVector
            -- Teleport behind the target, facing them
            hrp.CFrame = CFrame.new(bestHRP.Position - lookVec * 5, bestHRP.Position + lookVec * 5)
        end
    end
end

--// Flight functions
local function enableFlight()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Create BodyVelocity to move player
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
    flyBodyVelocity.P = 10000
    flyBodyVelocity.Parent = hrp

    -- Create BodyGyro to control rotation
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.D = 500
    flyBodyGyro.P = 10000
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp

    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true -- Prevents default Roblox physics interference
    end

    flightActive = true
end

local function disableFlight()
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end

    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false -- Restore normal movement
        end
    end

    flightActive = false
end

--// Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not scriptRunning then return end
    if input.KeyCode == Enum.KeyCode.F then
        if flightActive then
            disableFlight() -- Toggle off flight
        else
            enableFlight() -- Toggle on flight
        end
    elseif input.KeyCode == Enum.KeyCode.T then
        teleportToClosestPlayer() -- Teleport to nearest player
    elseif input.KeyCode == Enum.KeyCode.U then
        -- Reset script: disable flight, ESP, and reload
        disableFlight()
        flightActive = false
        espActive = false
        scriptRunning = false
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Mipselled/RobloxCheat/refs/heads/main/main.lua"))()
    end
end)

--// Flight movement update
RunService.Heartbeat:Connect(function()
    if not flightActive or not scriptRunning then return end
    local moveDirection = Vector3.new(0, 0, 0)

    -- Keyboard movement input
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDirection = moveDirection + Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDirection = moveDirection - Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDirection = moveDirection - Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDirection = moveDirection + Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveDirection = moveDirection + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        moveDirection = moveDirection - Vector3.new(0, 1, 0)
    end

    -- Normalize direction and multiply by speed
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit * flightSpeed
    end

    if flyBodyVelocity then
        flyBodyVelocity.Velocity = moveDirection
    end

    if flyBodyGyro then
        -- Make player face camera direction
        flyBodyGyro.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, LocalPlayer.Character.HumanoidRootPart.Position + Camera.CFrame.LookVector)
    end
end)

-- Re-enable flight after respawn
LocalPlayer.CharacterAdded:Connect(function()
    if flightActive then
        task.wait(0.5)
        enableFlight()
    end
end)

--// ESP functions
local function createESP(player)
    -- Skip local player, blocked players, or placeholder names
    if player == LocalPlayer or blockedNames[player.Name] or not scriptRunning or string.match(player.Name, "^[A-Za-z]+_%d%d%d$") then
        return
    end

    local visible = true
    local espBox = Drawing.new("Quad") -- Draw a rectangle around player
    espBox.Thickness = 2
    espBox.Color = Color3.fromRGB(0, 255, 0)
    espBox.Transparency = 1
    espBox.Visible = false

    local healthText = Drawing.new("Text") -- Draw health above player
    healthText.Size = 16
    healthText.Center = true
    healthText.Color = Color3.fromRGB(255, 255, 255)
    healthText.Outline = true
    healthText.Visible = false

    espList[player.Name] = {box = espBox, text = healthText}

    RunService.RenderStepped:Connect(function()
        if not espActive or not scriptRunning then
            healthText.Visible = false
            espBox.PointA = Vector2.new(0, 0)
            espBox.PointB = Vector2.new(0, 0)
            espBox.PointC = Vector2.new(0, 0)
            espBox.PointD = Vector2.new(0, 0)
            return
        end

        if not espList[player.Name] then
            healthText.Visible = false
            espBox.PointA = Vector2.new(0, 0)
            espBox.PointB = Vector2.new(0, 0)
            espBox.PointC = Vector2.new(0, 0)
            espBox.PointD = Vector2.new(0, 0)
            return
        end

        local char = player.Character
        if not char then
            healthText.Visible = false
            espBox.PointA = Vector2.new(0, 0)
            espBox.PointB = Vector2.new(0, 0)
            espBox.PointC = Vector2.new(0, 0)
            espBox.PointD = Vector2.new(0, 0)
            return
        end

        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not (root and head and humanoid) then
            healthText.Visible = false
            espBox.PointA = Vector2.new(0, 0)
            espBox.PointB = Vector2.new(0, 0)
            espBox.PointC = Vector2.new(0, 0)
            espBox.PointD = Vector2.new(0, 0)
            return
        end

        -- Convert 3D positions to 2D screen positions
        local rootPos = Camera:WorldToViewportPoint(root.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))

        espBox.Visible = false
        healthText.Visible = false
        if inViewport(rootPos) or inViewport(headPos) then
            -- Draw ESP box
            espBox.PointA = Vector2.new(rootPos.X - 15, rootPos.Y + 30)
            espBox.PointB = Vector2.new(rootPos.X + 15, rootPos.Y + 30)
            espBox.PointC = Vector2.new(headPos.X + 15, headPos.Y)
            espBox.PointD = Vector2.new(headPos.X - 15, headPos.Y)

            -- Show health
            healthText.Text = "Health: " .. math.ceil(humanoid.Health)
            healthText.Position = Vector2.new(headPos.X, headPos.Y - 15)
            healthText.Visible = true
        else
            -- Hide ESP if not in viewport
            espBox.PointA = Vector2.new(0, 0)
            espBox.PointB = Vector2.new(0, 0)
            espBox.PointC = Vector2.new(0, 0)
            espBox.PointD = Vector2.new(0, 0)
        end
    end)
end

-- Create ESP for existing players
for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end

-- Create ESP for new players joining
Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

-- Clean up ESP when a player leaves
Players.PlayerRemoving:Connect(function(player)
    if espList[player.Name] then
        espList[player.Name]:Remove()
    end
end)
