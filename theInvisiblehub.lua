-- Noclip
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local noclip = false

-- Обновляем персонажа при спавне
player.CharacterAdded:Connect(function(char)
	character = char
end)

-- Переключение через клавишу N
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.N then
		noclip = not noclip
	end
end)

-- Применяем ноуклип каждую ступень
RunService.Stepped:Connect(function()
	if not noclip or not character then return end
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			part.CanCollide = false
		end
	end
end)

-- спидхак

local uis = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer

local running = false
local connection

uis.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Z then
		if running then
			-- Выключаем
			if connection then
				connection:Disconnect()
				connection = nil
			end
			running = false
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.WalkSpeed = 12 -- стандарт
			end
		else
			-- Включаем
			running = true
			connection = RunService.RenderStepped:Connect(function()
				if player.Character and player.Character:FindFirstChild("Humanoid") then
					player.Character.Humanoid.WalkSpeed = 65
				end
			end)
		end
	end
end)

-- флай
local uis = game:GetService("UserInputService")
local run = game:GetService("RunService")
local plr = game.Players.LocalPlayer

local fly = false
local bv
local up = 0

local function setFlyState(state)
	local char = plr.Character or plr.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")
	local hum = char:WaitForChild("Humanoid")

	fly = state

	if fly then
		bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1, 1, 1) * 1e6
		bv.Velocity = Vector3.zero
		bv.Parent = root

		run:BindToRenderStep("fly", Enum.RenderPriority.Input.Value, function()
			if not bv or not root then return end
			local moveDir = hum.MoveDirection
			local vertical = Vector3.new(0, up, 0)
			bv.Velocity = (moveDir + vertical) * 50
		end)
	else
		run:UnbindFromRenderStep("fly")
		if bv then
			bv:Destroy()
			bv = nil
		end
	end
end

-- Управление с клавиатуры
uis.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F then
		setFlyState(not fly)
	elseif input.KeyCode == Enum.KeyCode.One then
		up = 1
	elseif input.KeyCode == Enum.KeyCode.Two then
		up = -1
	end
end)

uis.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.Two then
		up = 0
	end
end)

-- Обработка переспавна
plr.CharacterAdded:Connect(function()
	if fly then
		task.wait(1)
		setFlyState(true)
	end
end)

local TeamsFolder = workspace:WaitForChild("GameAssets"):WaitForChild("Teams")

local Survivors = TeamsFolder:WaitForChild("Survivor")
local Killers = TeamsFolder:WaitForChild("Killer")

local LocalPlayer = game.Players.LocalPlayer

-- функция для добавления ESP (Highlight + HP + Имя)
local function addESP(model, color)
	if not (model:IsA("Model") and model:FindFirstChildOfClass("Humanoid")) then return end
	if model == LocalPlayer.Character then return end -- не подсвечиваем себя

	-- Highlight
	if not model:FindFirstChild("ESP_HL") then
		local hl = Instance.new("Highlight")
		hl.Name = "ESP_HL"
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.FillColor = color
		hl.OutlineColor = Color3.new(1,1,1)
		hl.Parent = model
	end

	-- BillboardGui
	if not model:FindFirstChild("ESP_GUI") then
		local hum = model:FindFirstChildOfClass("Humanoid")
		local head = model:FindFirstChild("Head")
		if hum and head then
			local gui = Instance.new("BillboardGui")
			gui.Name = "ESP_GUI"
			gui.Size = UDim2.new(0,100,0,40)
			gui.StudsOffset = Vector3.new(0,3,0)
			gui.AlwaysOnTop = true
			gui.Parent = model

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "NameLabel"
			nameLabel.Size = UDim2.new(1,0,0.5,0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.TextColor3 = Color3.new(1,1,1)
			nameLabel.Font = Enum.Font.SourceSansBold
			nameLabel.TextScaled = true
			nameLabel.Text = model.Name
			nameLabel.Parent = gui

			local healthLabel = Instance.new("TextLabel")
			healthLabel.Name = "HealthLabel"
			healthLabel.Size = UDim2.new(1,0,0.5,0)
			healthLabel.Position = UDim2.new(0,0,0.5,0)
			healthLabel.BackgroundTransparency = 1
			healthLabel.TextColor3 = Color3.new(0,1,0)
			healthLabel.Font = Enum.Font.SourceSans
			healthLabel.TextScaled = true
			healthLabel.Text = tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))
			healthLabel.Parent = gui

			-- обновление HP
			hum.HealthChanged:Connect(function(newHealth)
				if healthLabel then
					healthLabel.Text = tostring(math.floor(newHealth)) .. "/" .. tostring(math.floor(hum.MaxHealth))
				end
			end)
		end
	end
end

-- функция для удаления ESP
local function removeESP(model)
	local hl = model:FindFirstChild("ESP_HL")
	if hl then hl:Destroy() end
	local gui = model:FindFirstChild("ESP_GUI")
	if gui then gui:Destroy() end
end

-- следим за папкой
local function watchFolder(folder, color)
	-- подсветим уже существующих
	for _, obj in ipairs(folder:GetChildren()) do
		addESP(obj, color)
	end

	-- новый объект
	folder.ChildAdded:Connect(function(obj)
		addESP(obj, color)
	end)

	-- объект ушёл
	folder.ChildRemoved:Connect(function(obj)
		removeESP(obj)
	end)

	-- доп. проверка: чтобы ESP не пропадал
	game:GetService("RunService").Heartbeat:Connect(function()
		for _, obj in ipairs(folder:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
				if not obj:FindFirstChild("ESP_HL") or not obj:FindFirstChild("ESP_GUI") then
					addESP(obj, color)
				end
			end
		end
	end)
end

-- Survivors → зелёный
watchFolder(Survivors, Color3.fromRGB(0, 255, 0))

-- Killers → красный
watchFolder(Killers, Color3.fromRGB(255, 0, 0))

-- на случай, если твой персонаж появится внутри этих папок
LocalPlayer.CharacterAdded:Connect(function(char)
	removeESP(char)
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local character, humanoid, root
local target

local function setupCharacter(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	root = character:WaitForChild("HumanoidRootPart")

	if not target then
		target = Instance.new("Part")
		target.Size = Vector3.new(2, 1, 2)
		target.Anchored = true
		target.CanCollide = false
		target.Transparency = 0.5
		target.Color = Color3.fromRGB(255, 0, 0)
		target.Name = "TargetPoint"
		target.Parent = workspace
	end

	target.Position = root.Position
end

setupCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(setupCharacter)

local function checkGround(pos)
	local rayOrigin = pos + Vector3.new(0, 5, 0)
	local rayDirection = Vector3.new(0, -50, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character, target}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	return result ~= nil
end

local enabled = false
local paused = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.U then
		enabled = not enabled
	end
end)

task.spawn(function()
	while true do
		if not enabled or not character or not root then
			task.wait(1)
			continue
		end

		if not paused and math.random(1, 10) == 1 then
			paused = true
			task.wait(math.random(3, 5))
			paused = false
		end

		if not paused then
			local success = false
			local attempts = 0
			local newPos

			while not success and attempts < 20 do
				attempts += 1
				local angle = math.rad(math.random(-90, 90))
				local rotatedLook = (root.CFrame * CFrame.Angles(0, angle, 0)).LookVector

				local distance = math.random(-140, 140)
				local sideOffset = math.random(-140, 140)

				newPos = root.Position + (rotatedLook * distance) + (root.CFrame.RightVector * sideOffset)

				if checkGround(newPos) then
					target.Position = Vector3.new(newPos.X, root.Position.Y, newPos.Z)
					success = true
				end
			end

			local dist = (root.Position - target.Position).Magnitude
			local waitTime = math.clamp(dist / 20, 0.5, 4)
			task.wait(waitTime)
		else
			task.wait(0.5)
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if enabled and not paused and humanoid and root then
		humanoid:MoveTo(target.Position)
	end
end)
