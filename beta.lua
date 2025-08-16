--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Flight variables
local flightActive = false
local flyBodyVelocity, flyBodyGyro = nil, nil
local flightSpeed = 50 -- change default flight speed here

--// ESP variables
local espActive = true
local espList = {}

-- add this helper once near the top
local function inViewport(v3)
    local s = Camera.ViewportSize
    return v3.Z > 0 and v3.X >= 0 and v3.X <= s.X and v3.Y >= 0 and v3.Y <= s.Y
end


--// Flight functions
local function enableFlight()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
    flyBodyVelocity.P = 10000
    flyBodyVelocity.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.D = 500
    flyBodyGyro.P = 10000
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp

    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end

    flightActive = true
end

local function disableFlight()
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end

    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end

    flightActive = false
end

--// Toggle flight with F
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        if flightActive then
            disableFlight()
        else
            enableFlight()
        end
    end
end)

--// Flight movement update
RunService.Heartbeat:Connect(function()
    if not flightActive then return end
    local moveDirection = Vector3.new(0, 0, 0)

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

    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit * flightSpeed
    end

    if flyBodyVelocity then
        flyBodyVelocity.Velocity = moveDirection
    end

	if flyBodyGyro then
        flyBodyGyro.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, LocalPlayer.Character.HumanoidRootPart.Position + Camera.CFrame.LookVector)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if flightActive then
        task.wait(0.5)
        enableFlight()
    end
end)

--// ESP functions
local function createESP(player)
    if player == LocalPlayer then
        return
    end

    local espBox = Drawing.new("Quad")
    espBox.Thickness = 2
    espBox.Color = Color3.fromRGB(0, 255, 0) -- Green ESP
    espBox.Transparency = 1
    espBox.Visible = false

    local healthText = Drawing.new("Text")
    healthText.Size = 16
    healthText.Center = true
    healthText.Color = Color3.fromRGB(255, 255, 255) -- White
    healthText.Outline = true
    healthText.Visible = false

    espList[player.Name] = {box = espBox, text = healthText}

    RunService.RenderStepped:Connect(
        function()
            if not espActive then
                espBox.Visible = false
                healthText.Visible = false
                return
            end
			
			if not espList[player.Name] then
                espBox.Visible = false
                healthText.Visible = false
                return
            end

            local char = player.Character
            if not char then
                espBox.Visible = false
                healthText.Visible = false
                return
            end

            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not (root and head and humanoid) then
                espBox.Visible = false
                healthText.Visible = false
                return
            end

            local rootPos = Camera:WorldToViewportPoint(root.Position)
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))

            espBox.Visible = false
            healthText.Visible = false
            if inViewport(rootPos) or inViewport(headPos) then
                espBox.PointA = Vector2.new(rootPos.X - 15, rootPos.Y + 30)
                espBox.PointB = Vector2.new(rootPos.X + 15, rootPos.Y + 30)
                espBox.PointC = Vector2.new(headPos.X + 15, headPos.Y)
                espBox.PointD = Vector2.new(headPos.X - 15, headPos.Y)

                healthText.Text = "Health: " .. math.floor(humanoid.Health)
                healthText.Position = Vector2.new(headPos.X, headPos.Y - 15)
                healthText.Visible = true
            else
				espBox.PointA = Vector2.new(0, 0)
                espBox.PointB = Vector2.new(0, 0)
                espBox.PointC = Vector2.new(0, 0)
                espBox.PointD = Vector2.new(0, 0)
			end

			if espBox.Visible then
                
			end
        end
    )
end

for _, player in pairs(Players:GetPlayers()) do
    createESP(player)
end

Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if espList[player.Name] then
        espList[player.Name]:Remove()
    end
end)
