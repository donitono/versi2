-- Ultra Simple Fishing Script - Tampilan Pasti Muncul
-- Version: 1.0 (Basic UI)

print("🎣 Loading Ultra Simple Fishing Script...")

-- Hapus UI lama jika ada
pcall(function()
	local gui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("UltraSimpleFishing")
	if gui then gui:Destroy() end
end)

wait(0.5)

-- Services
local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui

print("✅ Player found: " .. player.Name)

-- Buat ScreenGui langsung
local gui = Instance.new("ScreenGui")
gui.Name = "UltraSimpleFishing"
gui.ResetOnSpawn = false

-- Test dengan frame yang lebih besar untuk fitur lengkap
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 400, 0, 300)
frame.Position = UDim2.new(0.5, -200, 0.5, -150)
frame.BackgroundColor3 = Color3.new(1, 1, 1) -- Putih agar terlihat
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.new(0, 0, 0) -- Border hitam

-- Text label untuk test
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.15, 0)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundColor3 = Color3.new(0.2, 0.6, 1) -- Biru
label.Text = "🎣 ADVANCED FISHING SCRIPT"
label.TextColor3 = Color3.new(1, 1, 1) -- Putih
label.TextScaled = true
label.Font = Enum.Font.SourceSansBold

-- Auto Fish Button functionality
local autoFishBtn = Instance.new("TextButton")
autoFishBtn.Size = UDim2.new(0.45, 0, 0.12, 0)
autoFishBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
autoFishBtn.BackgroundColor3 = Color3.new(0, 0.8, 0) -- Hijau
autoFishBtn.Text = "🎣 START AUTO FISH"
autoFishBtn.TextColor3 = Color3.new(1, 1, 1)
autoFishBtn.TextScaled = true
autoFishBtn.Font = Enum.Font.SourceSansBold

-- Sell All Button
local sellAllBtn = Instance.new("TextButton")
sellAllBtn.Size = UDim2.new(0.45, 0, 0.12, 0)
sellAllBtn.Position = UDim2.new(0.5, 0, 0.2, 0)
sellAllBtn.BackgroundColor3 = Color3.new(1, 0.5, 0) -- Orange
sellAllBtn.Text = "💰 SELL ALL"
sellAllBtn.TextColor3 = Color3.new(1, 1, 1)
sellAllBtn.TextScaled = true
sellAllBtn.Font = Enum.Font.SourceSansBold

-- Delay Input
local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(0.3, 0, 0.08, 0)
delayLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
delayLabel.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
delayLabel.Text = "Delay (sec):"
delayLabel.TextColor3 = Color3.new(0, 0, 0)
delayLabel.TextScaled = true
delayLabel.Font = Enum.Font.SourceSans

local delayInput = Instance.new("TextBox")
delayInput.Size = UDim2.new(0.15, 0, 0.08, 0)
delayInput.Position = UDim2.new(0.4, 0, 0.35, 0)
delayInput.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
delayInput.Text = "0.4"
delayInput.TextColor3 = Color3.new(0, 0, 0)
delayInput.TextScaled = true
delayInput.Font = Enum.Font.SourceSans

-- Hybrid Mode Button
local hybridBtn = Instance.new("TextButton")
hybridBtn.Size = UDim2.new(0.35, 0, 0.08, 0)
hybridBtn.Position = UDim2.new(0.6, 0, 0.35, 0)
hybridBtn.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5) -- Abu-abu
hybridBtn.Text = "🎲 HYBRID: OFF"
hybridBtn.TextColor3 = Color3.new(1, 1, 1)
hybridBtn.TextScaled = true
hybridBtn.Font = Enum.Font.SourceSans

-- No Oxygen Button
local noOxygenBtn = Instance.new("TextButton")
noOxygenBtn.Size = UDim2.new(0.45, 0, 0.12, 0)
noOxygenBtn.Position = UDim2.new(0.05, 0, 0.46, 0)
noOxygenBtn.BackgroundColor3 = Color3.new(0, 0.5, 1) -- Biru
noOxygenBtn.Text = "🫁 NO OXYGEN"
noOxygenBtn.TextColor3 = Color3.new(1, 1, 1)
noOxygenBtn.TextScaled = true
noOxygenBtn.Font = Enum.Font.SourceSansBold

-- Spawn Boat Button
local spawnBoatBtn = Instance.new("TextButton")
spawnBoatBtn.Size = UDim2.new(0.45, 0, 0.12, 0)
spawnBoatBtn.Position = UDim2.new(0.5, 0, 0.46, 0)
spawnBoatBtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.8) -- Biru tua
spawnBoatBtn.Text = "🚤 SPAWN BOAT"
spawnBoatBtn.TextColor3 = Color3.new(1, 1, 1)
spawnBoatBtn.TextScaled = true
spawnBoatBtn.Font = Enum.Font.SourceSansBold

-- Walkspeed Controls
local walkspeedLabel = Instance.new("TextLabel")
walkspeedLabel.Size = UDim2.new(0.3, 0, 0.08, 0)
walkspeedLabel.Position = UDim2.new(0.05, 0, 0.61, 0)
walkspeedLabel.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
walkspeedLabel.Text = "Walkspeed:"
walkspeedLabel.TextColor3 = Color3.new(0, 0, 0)
walkspeedLabel.TextScaled = true
walkspeedLabel.Font = Enum.Font.SourceSans

local walkspeedInput = Instance.new("TextBox")
walkspeedInput.Size = UDim2.new(0.15, 0, 0.08, 0)
walkspeedInput.Position = UDim2.new(0.4, 0, 0.61, 0)
walkspeedInput.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
walkspeedInput.Text = "16"
walkspeedInput.TextColor3 = Color3.new(0, 0, 0)
walkspeedInput.TextScaled = true
walkspeedInput.Font = Enum.Font.SourceSans

-- Unlimited Jump Button
local jumpBtn = Instance.new("TextButton")
jumpBtn.Size = UDim2.new(0.35, 0, 0.08, 0)
jumpBtn.Position = UDim2.new(0.6, 0, 0.61, 0)
jumpBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.8) -- Ungu
jumpBtn.Text = "🚀 UNLIMITED JUMP"
jumpBtn.TextColor3 = Color3.new(1, 1, 1)
jumpBtn.TextScaled = true
jumpBtn.Font = Enum.Font.SourceSans

-- Button test (keep the old one for compatibility)
local button = autoFishBtn -- Alias untuk kompatibilitas

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.new(1, 0, 0) -- Merah
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.SourceSansBold

-- Status label
local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.9, 0, 0.15, 0)
status.Position = UDim2.new(0.05, 0, 0.72, 0)
status.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1) -- Abu gelap
status.Text = "Status: Ready to Fish!\nDelay: 0.4s | Mode: Normal | Fish Count: 0"
status.TextColor3 = Color3.new(1, 1, 0) -- Kuning
status.TextScaled = true
status.Font = Enum.Font.SourceSans
status.TextWrapped = true

-- Parent semua element
label.Parent = frame
autoFishBtn.Parent = frame
sellAllBtn.Parent = frame
delayLabel.Parent = frame
delayInput.Parent = frame
hybridBtn.Parent = frame
noOxygenBtn.Parent = frame
spawnBoatBtn.Parent = frame
walkspeedLabel.Parent = frame
walkspeedInput.Parent = frame
jumpBtn.Parent = frame
closeBtn.Parent = frame
status.Parent = frame
frame.Parent = gui

-- Floating Button untuk show/hide UI
local floatingBtn = Instance.new("TextButton")
floatingBtn.Name = "FloatingButton"
floatingBtn.Size = UDim2.new(0, 60, 0, 60)
floatingBtn.Position = UDim2.new(1, -80, 0.5, -30)
floatingBtn.BackgroundColor3 = Color3.new(0.2, 0.6, 1) -- Biru
floatingBtn.Text = "🎣"
floatingBtn.TextColor3 = Color3.new(1, 1, 1)
floatingBtn.TextScaled = true
floatingBtn.Font = Enum.Font.SourceSansBold
floatingBtn.BorderSizePixel = 2
floatingBtn.BorderColor3 = Color3.new(1, 1, 1) -- Border putih
floatingBtn.ZIndex = 10
floatingBtn.Parent = gui

-- Rounded corners untuk floating button
local floatingCorner = Instance.new("UICorner")
floatingCorner.CornerRadius = UDim.new(0, 30) -- Bulat penuh
floatingCorner.Parent = floatingBtn

-- PENTING: Set parent ke PlayerGui
gui.Parent = playerGui

print("✅ UI Created successfully!")
print("📍 Frame position: " .. tostring(frame.Position))
print("📏 Frame size: " .. tostring(frame.Size))

-- Safe access to game services dan remotes
local Rs
local EquipRod, ChargeRod, RequestFishing, FishingComplete, noOxygen, spawnBoat, sellAll

pcall(function()
	Rs = game:GetService("ReplicatedStorage")
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

-- Variables untuk fitur
local autoFish = false
local fishCount = 0
local fishingDelay = 0.4
local hybridMode = false
local noOxygenActive = false
local unlimitedJump = false

-- Auto fishing function yang proper
local function startAutoFish()
	if autoFish then return end
	autoFish = true
	autoFishBtn.Text = "🛑 STOP AUTO FISH"
	autoFishBtn.BackgroundColor3 = Color3.new(1, 0, 0) -- Merah
	status.Text = "Status: Auto Fishing ACTIVE!\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
	
	spawn(function()
		while autoFish do
			pcall(function()
				if EquipRod then EquipRod:FireServer() end
				if ChargeRod then ChargeRod:FireServer() end
				if RequestFishing then RequestFishing:FireServer() end
				if FishingComplete then FishingComplete:FireServer() end
				
				fishCount = fishCount + 1
				status.Text = "Status: Auto Fishing ACTIVE!\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
			end)
			
			local currentDelay = fishingDelay
			if hybridMode then
				currentDelay = math.random(20, 50) / 100 -- 0.2-0.5 seconds
			end
			
			wait(currentDelay)
		end
	end)
end

local function stopAutoFish()
	autoFish = false
	autoFishBtn.Text = "🎣 START AUTO FISH"
	autoFishBtn.BackgroundColor3 = Color3.new(0, 0.8, 0) -- Hijau
	status.Text = "Status: Auto Fishing STOPPED\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
end

-- Floating Button functionality
local isUIVisible = true
floatingBtn.MouseButton1Click:Connect(function()
	isUIVisible = not isUIVisible
	frame.Visible = isUIVisible
	
	if isUIVisible then
		floatingBtn.Text = "🎣"
		floatingBtn.BackgroundColor3 = Color3.new(0.2, 0.6, 1) -- Biru
		print("🎮 UI Opened")
	else
		floatingBtn.Text = "❌"
		floatingBtn.BackgroundColor3 = Color3.new(1, 0.2, 0.2) -- Merah
		print("🎮 UI Hidden")
	end
end)

-- Floating button hover effects
floatingBtn.MouseEnter:Connect(function()
	-- Efek hover - membesar sedikit
	local originalSize = floatingBtn.Size
	floatingBtn.Size = UDim2.new(0, 65, 0, 65)
	floatingBtn.BorderColor3 = Color3.new(1, 1, 0) -- Border kuning saat hover
end)

floatingBtn.MouseLeave:Connect(function()
	-- Kembali ke ukuran normal
	floatingBtn.Size = UDim2.new(0, 60, 0, 60)
	floatingBtn.BorderColor3 = Color3.new(1, 1, 1) -- Border putih normal
end)

-- Drag functionality untuk floating button
local floatingDragging = false
local floatingDragStart = nil
local floatingStartPos = nil

floatingBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		floatingDragging = true
		floatingDragStart = input.Position
		floatingStartPos = floatingBtn.Position
	end
end)

floatingBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		floatingDragging = false
	end
end)
autoFishBtn.MouseButton1Click:Connect(function()
	if autoFish then
		stopAutoFish()
	else
		startAutoFish()
	end
end)

-- Sell All Button functionality
sellAllBtn.MouseButton1Click:Connect(function()
	if sellAll then
		pcall(function()
			sellAll:InvokeServer()
			status.Text = "Status: 💰 SOLD ALL ITEMS!\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
		end)
	else
		status.Text = "Status: ❌ Sell All not available\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
	end
end)

-- Delay Input functionality
delayInput.FocusLost:Connect(function()
	local newDelay = tonumber(delayInput.Text)
	if newDelay and newDelay >= 0.1 and newDelay <= 5 then
		fishingDelay = newDelay
		status.Text = "Status: Delay updated to " .. fishingDelay .. "s\nMode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
	else
		delayInput.Text = tostring(fishingDelay)
		status.Text = "Status: ❌ Invalid delay! Use 0.1-5.0\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
	end
end)

-- Hybrid Mode Button functionality
hybridBtn.MouseButton1Click:Connect(function()
	hybridMode = not hybridMode
	if hybridMode then
		hybridBtn.Text = "🎲 HYBRID: ON"
		hybridBtn.BackgroundColor3 = Color3.new(0, 0.8, 0) -- Hijau
	else
		hybridBtn.Text = "🎲 HYBRID: OFF"
		hybridBtn.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5) -- Abu-abu
	end
	status.Text = "Status: Mode changed to " .. (hybridMode and "Hybrid" or "Normal") .. "\nDelay: " .. fishingDelay .. "s | Fish Count: " .. fishCount
end)

-- No Oxygen Button functionality
noOxygenBtn.MouseButton1Click:Connect(function()
	if noOxygen then
		pcall(function()
			noOxygen:FireServer()
			noOxygenActive = not noOxygenActive
			if noOxygenActive then
				noOxygenBtn.Text = "🫁 NO OXYGEN: ON"
				noOxygenBtn.BackgroundColor3 = Color3.new(0, 0.8, 0) -- Hijau
				status.Text = "Status: 🫁 No Oxygen ENABLED\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
			else
				noOxygenBtn.Text = "🫁 NO OXYGEN: OFF"
				noOxygenBtn.BackgroundColor3 = Color3.new(0, 0.5, 1) -- Biru
				status.Text = "Status: 🫁 No Oxygen DISABLED\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
			end
		end)
	else
		status.Text = "Status: ❌ No Oxygen not available\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
	end
end)

-- Spawn Boat Button functionality
spawnBoatBtn.MouseButton1Click:Connect(function()
	if spawnBoat then
		pcall(function()
			spawnBoat:InvokeServer("SmallDingy") -- Default boat
			status.Text = "Status: 🚤 Boat spawned!\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
		end)
	else
		status.Text = "Status: ❌ Spawn Boat not available\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
	end
end)

-- Walkspeed Input functionality
walkspeedInput.FocusLost:Connect(function()
	local newSpeed = tonumber(walkspeedInput.Text)
	if newSpeed and newSpeed >= 1 and newSpeed <= 100 then
		pcall(function()
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.WalkSpeed = newSpeed
				status.Text = "Status: 🚶 Walkspeed set to " .. newSpeed .. "\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
			end
		end)
	else
		walkspeedInput.Text = "16"
		status.Text = "Status: ❌ Invalid speed! Use 1-100\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
	end
end)

-- Unlimited Jump Button functionality
jumpBtn.MouseButton1Click:Connect(function()
	unlimitedJump = not unlimitedJump
	if unlimitedJump then
		jumpBtn.Text = "🚀 UNLIMITED: ON"
		jumpBtn.BackgroundColor3 = Color3.new(0, 0.8, 0) -- Hijau
		pcall(function()
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.JumpPower = 100
			end
		end)
		status.Text = "Status: 🚀 Unlimited Jump ENABLED\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
	else
		jumpBtn.Text = "🚀 UNLIMITED: OFF"
		jumpBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.8) -- Ungu
		pcall(function()
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.JumpPower = 50 -- Default
			end
		end)
		status.Text = "Status: 🚀 Unlimited Jump DISABLED\nDelay: " .. fishingDelay .. "s | Mode: " .. (hybridMode and "Hybrid" or "Normal") .. " | Fish Count: " .. fishCount
	end
end)

-- Test button functionality (untuk kompatibilitas)
button.MouseButton1Click:Connect(function()
	-- Ini sekarang adalah autoFishBtn, jadi tidak perlu kode tambahan
end)

closeBtn.MouseButton1Click:Connect(function()
	print("❌ Closing UI...")
	gui:Destroy()
end)

-- Drag functionality
local dragging = false
local dragStart = nil
local startPos = nil

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

frame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
	
	-- Handle floating button dragging in the same event
	if floatingDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - floatingDragStart
		floatingBtn.Position = UDim2.new(
			floatingStartPos.X.Scale,
			floatingStartPos.X.Offset + delta.X,
			floatingStartPos.Y.Scale,
			floatingStartPos.Y.Offset + delta.Y
		)
	end
end)

-- Keyboard controls untuk toggle UI
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Z then
		-- Toggle visibility entire UI
		gui.Enabled = not gui.Enabled
		print("🎮 UI Toggled: " .. (gui.Enabled and "ON" or "OFF"))
	elseif input.KeyCode == Enum.KeyCode.M then
		-- Toggle main frame visibility (sama seperti floating button)
		isUIVisible = not isUIVisible
		frame.Visible = isUIVisible
		
		if isUIVisible then
			floatingBtn.Text = "🎣"
			floatingBtn.BackgroundColor3 = Color3.new(0.2, 0.6, 1) -- Biru
			print("🎮 Main UI Opened")
		else
			floatingBtn.Text = "❌"
			floatingBtn.BackgroundColor3 = Color3.new(1, 0.2, 0.2) -- Merah
			print("🎮 Main UI Hidden")
		end
	end
end)

print("")
print("🎮 ADVANCED FISHING UI LOADED!")
print("📋 Features Available:")
print("🎣 Auto Fishing with custom delay")
print("🎲 Hybrid mode (random delays)")
print("💰 Sell All items")
print("🫁 No Oxygen damage")
print("🚤 Spawn boats")
print("🚶 Custom walkspeed")
print("🚀 Unlimited jump")
print("🔘 Floating button for easy access")
print("")
print("📋 Controls:")
print("🔘 FLOATING BUTTON (🎣): Click to show/hide main UI")
print("⌨️ Z Key: Toggle entire UI on/off")
print("⌨️ M Key: Show/hide main panel (same as floating button)")
print("🖱️ Drag: Both main UI and floating button are draggable")
print("❌ Red X: Close entire script")
print("")
print("🎯 UI Instructions:")
print("- Green button: Start/Stop Auto Fish")
print("- Orange button: Sell All items")
print("- Change delay in text box (0.1-5.0 seconds)")
print("- Toggle Hybrid mode for random delays")
print("- Adjust walkspeed (1-100)")
print("- Enable unlimited jump")
print("")
print("🔧 Game Compatibility:")
if EquipRod and ChargeRod and RequestFishing and FishingComplete then
	print("✅ Auto Fishing - Available")
else
	print("❌ Auto Fishing - Not Available")
end
if sellAll then
	print("✅ Sell All - Available")
else
	print("❌ Sell All - Not Available")
end
if noOxygen then
	print("✅ No Oxygen - Available")
else
	print("❌ No Oxygen - Not Available")
end
if spawnBoat then
	print("✅ Spawn Boat - Available")
else
	print("❌ Spawn Boat - Not Available")
end
print("✅ Player Mods - Always Available")
print("✅ Floating Button - Always Available")
print("")
print("⚠️ Script loaded with full error protection!")
print("🔘 Look for the blue floating button (🎣) on the right side!")
