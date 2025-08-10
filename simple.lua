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

-- Test dengan frame sederhana dulu
local frame = Instance.new("Frame")
frame.Name = "TestFrame"
frame.Size = UDim2.new(0, 200, 0, 150)
frame.Position = UDim2.new(0.5, -100, 0.5, -75)
frame.BackgroundColor3 = Color3.new(1, 1, 1) -- Putih agar terlihat
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.new(0, 0, 0) -- Border hitam

-- Text label untuk test
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0.3, 0)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundColor3 = Color3.new(0.2, 0.6, 1) -- Biru
label.Text = "🎣 FISHING SCRIPT"
label.TextColor3 = Color3.new(1, 1, 1) -- Putih
label.TextScaled = true
label.Font = Enum.Font.SourceSansBold

-- Button test
local button = Instance.new("TextButton")
button.Size = UDim2.new(0.8, 0, 0.2, 0)
button.Position = UDim2.new(0.1, 0, 0.4, 0)
button.BackgroundColor3 = Color3.new(0, 0.8, 0) -- Hijau
button.Text = "CLICK ME - WORKING!"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Font = Enum.Font.SourceSansBold

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
status.Size = UDim2.new(0.8, 0, 0.2, 0)
status.Position = UDim2.new(0.1, 0, 0.7, 0)
status.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1) -- Abu gelap
status.Text = "Status: Ready"
status.TextColor3 = Color3.new(1, 1, 0) -- Kuning
status.TextScaled = true
status.Font = Enum.Font.SourceSans

-- Parent semua element
label.Parent = frame
button.Parent = frame
closeBtn.Parent = frame
status.Parent = frame
frame.Parent = gui

-- PENTING: Set parent ke PlayerGui
gui.Parent = playerGui

print("✅ UI Created successfully!")
print("📍 Frame position: " .. tostring(frame.Position))
print("📏 Frame size: " .. tostring(frame.Size))

-- Test button functionality
button.MouseButton1Click:Connect(function()
	print("🎮 Button clicked!")
	status.Text = "Status: Button Works!"
	button.Text = "BUTTON WORKING! ✅"
	button.BackgroundColor3 = Color3.new(1, 0.5, 0) -- Orange
end)

closeBtn.MouseButton1Click:Connect(function()
	print("❌ Closing UI...")
	gui:Destroy()
end)

-- Auto fishing variables (simple)
local autoFish = false
local fishCount = 0

-- Simple auto fish function
local function startAutoFish()
	if autoFish then return end
	autoFish = true
	status.Text = "Status: Auto Fishing ON"
	
	spawn(function()
		while autoFish do
			-- Simulate fishing
			fishCount = fishCount + 1
			status.Text = "Fishing... Count: " .. fishCount
			print("🎣 Auto fishing... Count: " .. fishCount)
			wait(1) -- 1 second delay
		end
	end)
end

-- Double click to start auto fish
local clickCount = 0
button.MouseButton1Click:Connect(function()
	clickCount = clickCount + 1
	if clickCount >= 2 then
		clickCount = 0
		if not autoFish then
			startAutoFish()
			button.Text = "AUTO FISH ON!"
			button.BackgroundColor3 = Color3.new(1, 0, 1) -- Magenta
		else
			autoFish = false
			button.Text = "AUTO FISH OFF"
			button.BackgroundColor3 = Color3.new(0, 0.8, 0) -- Hijau
			status.Text = "Status: Stopped"
		end
	end
	wait(1)
	clickCount = 0
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
end)

print("")
print("🎮 UI LOADED SUCCESSFULLY!")
print("📋 Instructions:")
print("- White box should appear on screen")
print("- Click green button to test")
print("- Double-click green button for auto fish")
print("- Drag the white box to move")
print("- Red X to close")
print("")
print("⚠️ If you don't see the UI, there might be a game compatibility issue")
