--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--// Blocked names
local blockedNames = {
    ["Youtube_Ebi"] = true,
    ["CBYBKB"] = true,
    ["123IDiddleKids"] = true,
    ["Skystrikerxy"] = true,
    ["Hurtbringer25"] = true,
    ["Hackerman123_XD"] = true,
    ["Masteryao2"] = true
}

--// Teleport to closest player (ignores blockedNames)
local function teleportToClosestPlayer()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local closestChar, closestHRP, closestDist = nil, nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not blockedNames[player.Name] and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local dist = (hrp.Position - targetHRP.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestChar = player.Character
                    closestHRP = targetHRP
                end
            end
        end
    end

    if closestChar and closestHRP then
        local head = closestChar:FindFirstChild("Head")
        if head then
            local lookVec = head.CFrame.LookVector
            -- Use HRP for position but Head for facing direction
            hrp.CFrame = CFrame.new(closestHRP.Position - lookVec * 5, closestHRP.Position + lookVec * 5)
        end
    end
end

--// Toggle teleport with T
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        teleportToClosestPlayer()
    end
end)
