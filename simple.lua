-- Simple Safe Fishing Script
-- Version: 1.0 (Error-Protected & Minimal)

-- Safe cleanup
pcall(function()
	if game.Players.LocalPlayer.PlayerGui:FindFirstChild("SimpleFishingUI") then
		game.Players.LocalPlayer.PlayerGui.SimpleFishingUI:Destroy()
	end
end)

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Safe ReplicatedStorage access
local Rs
pcall(function()
	Rs = game:GetService("ReplicatedStorage")
end)

-- Safe remote access
local EquipRod, ChargeRod, RequestFishing, FishingComplete, noOxygen, spawnBoat, sellAll

pcall(function()
	if Rs and Rs:FindFirstChild("events") then
		EquipRod = Rs.events:FindFirstChild("equiprod")
		ChargeRod = Rs.events:FindFirstChild("chargerod")
		RequestFishing = Rs.events:FindFirstChild("requestfishing")
		FishingComplete = Rs.events:FindFirstChild("fishingcomplete")
		noOxygen = Rs.events:FindFirstChild("nooxygen")
		spawnBoat = Rs.events:FindFirstChild("spawnboat")
		sellAll = Rs.events:FindFirstChild("sellall")
	end
end)

-- Auto fishing variables
local autoFishEnabled = false
local fishingDelay = 0.4
local hybridMode = false
local autoFishThread = nil

-- Auto fishing function
local function toggleFishing()
	if autoFishEnabled then
		autoFishEnabled = false
		if autoFishThread then
			task.cancel(autoFishThread)
			autoFishThread = nil
		end
		print("🎣 Auto Fishing Disabled")
		return
	end
	
	autoFishEnabled = true
	print("🎣 Auto Fishing Enabled with " .. fishingDelay .. "s delay")
	
	autoFishThread = task.spawn(function()
		while autoFishEnabled do
			pcall(function()
				if EquipRod then EquipRod:FireServer() end
				if ChargeRod then ChargeRod:FireServer() end
				if RequestFishing then RequestFishing:FireServer() end
				if FishingComplete then FishingComplete:FireServer() end
			end)
			
			local currentDelay = fishingDelay
			if hybridMode then
				currentDelay = math.random(20, 50) / 100 -- 0.2-0.5 seconds
			end
			
			task.wait(currentDelay)
		end
	end)
end

-- Create simple UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleFishingUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
mainFrame.Size = UDim2.new(0, 300, 0, 200)

-- Round corners
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = mainFrame
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 10, 0, 10)
title.Size = UDim2.new(1, -20, 0, 30)
title.Font = Enum.Font.SourceSansBold
title.Text = "🎣 Simple Safe Fishing"
title.TextColor3 = Color3.white
title.TextScaled = true

-- Auto Fish button
local autoFishBtn = Instance.new("TextButton")
autoFishBtn.Name = "AutoFishButton"
autoFishBtn.Parent = mainFrame
autoFishBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
autoFishBtn.BorderSizePixel = 0
autoFishBtn.Position = UDim2.new(0, 20, 0, 50)
autoFishBtn.Size = UDim2.new(0, 120, 0, 30)
autoFishBtn.Font = Enum.Font.SourceSansBold
autoFishBtn.Text = "Start Auto Fish"
autoFishBtn.TextColor3 = Color3.white
autoFishBtn.TextScaled = true

local autoFishCorner = Instance.new("UICorner")
autoFishCorner.CornerRadius = UDim.new(0, 6)
autoFishCorner.Parent = autoFishBtn

-- Delay input
local delayInput = Instance.new("TextBox")
delayInput.Name = "DelayInput"
delayInput.Parent = mainFrame
delayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
delayInput.BorderSizePixel = 0
delayInput.Position = UDim2.new(0, 160, 0, 50)
delayInput.Size = UDim2.new(0, 120, 0, 30)
delayInput.Font = Enum.Font.SourceSans
delayInput.Text = "0.4"
delayInput.TextColor3 = Color3.white
delayInput.TextScaled = true
delayInput.PlaceholderText = "Delay (seconds)"

local delayCorner = Instance.new("UICorner")
delayCorner.CornerRadius = UDim.new(0, 6)
delayCorner.Parent = delayInput

-- Hybrid mode button
local hybridBtn = Instance.new("TextButton")
hybridBtn.Name = "HybridButton"
hybridBtn.Parent = mainFrame
hybridBtn.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
hybridBtn.BorderSizePixel = 0
hybridBtn.Position = UDim2.new(0, 20, 0, 90)
hybridBtn.Size = UDim2.new(0, 120, 0, 30)
hybridBtn.Font = Enum.Font.SourceSansBold
hybridBtn.Text = "Hybrid: OFF"
hybridBtn.TextColor3 = Color3.white
hybridBtn.TextScaled = true

local hybridCorner = Instance.new("UICorner")
hybridCorner.CornerRadius = UDim.new(0, 6)
hybridCorner.Parent = hybridBtn

-- Sell All button
local sellBtn = Instance.new("TextButton")
sellBtn.Name = "SellButton"
sellBtn.Parent = mainFrame
sellBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
sellBtn.BorderSizePixel = 0
sellBtn.Position = UDim2.new(0, 160, 0, 90)
sellBtn.Size = UDim2.new(0, 120, 0, 30)
sellBtn.Font = Enum.Font.SourceSansBold
sellBtn.Text = "💰 Sell All"
sellBtn.TextColor3 = Color3.white
sellBtn.TextScaled = true

local sellCorner = Instance.new("UICorner")
sellCorner.CornerRadius = UDim.new(0, 6)
sellCorner.Parent = sellBtn

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Parent = mainFrame
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
closeBtn.BorderSizePixel = 0
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.white
closeBtn.TextScaled = true

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 12)
closeCorner.Parent = closeBtn

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Parent = mainFrame
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 10, 0, 130)
statusLabel.Size = UDim2.new(1, -20, 0, 60)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Text = "Ready to fish!\nDelay: 0.4s | Mode: Normal"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextScaled = true
statusLabel.TextWrapped = true

-- Floating button
local floatingBtn = Instance.new("TextButton")
floatingBtn.Name = "FloatingButton"
floatingBtn.Parent = screenGui
floatingBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
floatingBtn.BorderSizePixel = 0
floatingBtn.Position = UDim2.new(1, -60, 0.5, -25)
floatingBtn.Size = UDim2.new(0, 50, 0, 50)
floatingBtn.Font = Enum.Font.SourceSansBold
floatingBtn.Text = "🎣"
floatingBtn.TextColor3 = Color3.white
floatingBtn.TextScaled = true
floatingBtn.ZIndex = 10

local floatingCorner = Instance.new("UICorner")
floatingCorner.CornerRadius = UDim.new(0, 25)
floatingCorner.Parent = floatingBtn

-- Button connections
autoFishBtn.MouseButton1Click:Connect(function()
	toggleFishing()
	if autoFishEnabled then
		autoFishBtn.Text = "Stop Auto Fish"
		autoFishBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
	else
		autoFishBtn.Text = "Start Auto Fish"
		autoFishBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
	end
	statusLabel.Text = autoFishEnabled and "Auto Fishing Active!" or "Auto Fishing Stopped"
	statusLabel.Text = statusLabel.Text .. "\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal")
end)

delayInput.FocusLost:Connect(function()
	local newDelay = tonumber(delayInput.Text)
	if newDelay and newDelay >= 0.1 and newDelay <= 5 then
		fishingDelay = newDelay
		statusLabel.Text = "Delay updated to " .. fishingDelay .. "s"
		statusLabel.Text = statusLabel.Text .. "\nMode: " .. (hybridMode and "Hybrid" or "Normal")
	else
		delayInput.Text = tostring(fishingDelay)
		statusLabel.Text = "Invalid delay! Use 0.1-5.0 seconds"
	end
end)

hybridBtn.MouseButton1Click:Connect(function()
	hybridMode = not hybridMode
	if hybridMode then
		hybridBtn.Text = "Hybrid: ON"
		hybridBtn.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
	else
		hybridBtn.Text = "Hybrid: OFF"
		hybridBtn.BackgroundColor3 = Color3.fromRGB(108, 117, 125)
	end
	statusLabel.Text = "Mode changed to " .. (hybridMode and "Hybrid" or "Normal")
	statusLabel.Text = statusLabel.Text .. "\nDelay: " .. fishingDelay .. "s"
end)

sellBtn.MouseButton1Click:Connect(function()
	if sellAll then
		pcall(function()
			sellAll:InvokeServer()
			statusLabel.Text = "💰 Sold all items!"
		end)
	else
		statusLabel.Text = "❌ Sell function not available"
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

floatingBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	floatingBtn.Text = mainFrame.Visible and "❌" or "🎣"
end)

-- Keyboard controls
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Z then
		screenGui.Enabled = not screenGui.Enabled
	elseif input.KeyCode == Enum.KeyCode.M then
		mainFrame.Visible = not mainFrame.Visible
		floatingBtn.Text = mainFrame.Visible and "❌" or "🎣"
	end
end)

-- Make UI draggable
local dragToggle = nil
local dragSpeed = 0.25
local dragStart = nil
local startPos = nil

local function updateInput(input)
	local delta = input.Position - dragStart
	local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	TweenService:Create(mainFrame, TweenInfo.new(dragSpeed), {Position = position}):Play()
end

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragToggle = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragToggle = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		if dragToggle then
			updateInput(input)
		end
	end
end)

-- Startup messages
print("🎣 Simple Safe Fishing Script Loaded!")
print("📋 Controls:")
print("- Z: Toggle UI visibility")
print("- M: Minimize/restore UI")
print("- Drag UI to move it")
print("")
print("🔧 Features:")
if EquipRod and ChargeRod and RequestFishing and FishingComplete then
	print("✅ Auto Fishing Available")
else
	print("❌ Auto Fishing Not Available (game not supported)")
end
if sellAll then
	print("✅ Sell All Available")
else
	print("❌ Sell All Not Available")
end
print("✅ Simple UI with error protection")
print("")
print("⚠️ This is a safe version that handles errors gracefully!")
