
-- ===============================================
-- Zayros FISHIT - Enhanced Version
-- Made by Doovy - Refactored for better performance
-- Performance Monitoring & Auto-Update Features
-- ===============================================

-- Cleanup existing GUI
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("ZayrosFISHIT") then
	game.Players.LocalPlayer.PlayerGui.ZayrosFISHIT:Destroy()
end

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Performance Monitoring
local PerformanceMonitor = {
	startTime = tick(),
	memoryUsage = 0,
	frameRate = 0,
	lastFrameTime = tick()
}

function PerformanceMonitor:update()
	local currentTime = tick()
	self.frameRate = 1 / (currentTime - self.lastFrameTime)
	self.lastFrameTime = currentTime
	self.memoryUsage = collectgarbage("count")
end

-- Configuration with Settings Save/Load
local CONFIG = {
	VERSION = "2.0.0",
	FISHING_COOLDOWN = 0.5,
	WALK_SPEED_DEFAULT = 16,
	UI_SCALE = 1.0,
	ANIMATION_SPEED = 0.2,
	AUTO_SAVE_SETTINGS = true,
	COLORS = {
		ACTIVE = Color3.fromRGB(46, 204, 113),
		INACTIVE = Color3.fromRGB(231, 76, 60),
		BACKGROUND = Color3.fromRGB(47, 47, 47),
		SIDEBAR = Color3.fromRGB(83, 83, 83),
		BUTTON_HOVER = Color3.fromRGB(60, 60, 60),
		SUCCESS = Color3.fromRGB(39, 174, 96),
		WARNING = Color3.fromRGB(241, 196, 15),
		ERROR = Color3.fromRGB(192, 57, 43)
	},
	KEYBINDS = {
		TOGGLE_GUI = Enum.KeyCode.RightControl,
		AUTO_FISH = Enum.KeyCode.F,
		TELEPORT_MENU = Enum.KeyCode.T,
		QUICK_SELL = Enum.KeyCode.G,
		SPEED_BOOST = Enum.KeyCode.LeftShift
	}
}

-- Settings Management
local Settings = {
	autoFishSpeed = CONFIG.FISHING_COOLDOWN,
	walkSpeed = CONFIG.WALK_SPEED_DEFAULT,
	keybinds = CONFIG.KEYBINDS,
	uiScale = CONFIG.UI_SCALE,
	autoSave = CONFIG.AUTO_SAVE_SETTINGS
}

local function saveSettings()
	if Settings.autoSave then
		local success, err = pcall(function()
			-- In a real implementation, you might want to use DataStore or file system
			-- For now, we'll store in a global variable that persists during session
			_G.ZayrosFishitSettings = Settings
		end)
		if not success then
			warn("Failed to save settings:", err)
		end
	end
end

local function loadSettings()
	if _G.ZayrosFishitSettings then
		for key, value in pairs(_G.ZayrosFishitSettings) do
			if Settings[key] ~= nil then
				Settings[key] = value
			end
		end
	end
end

-- Anti-Detection System
local AntiDetection = {
	enabled = true,
	randomizeTiming = true,
	humanBehavior = true,
	lastActionTime = 0
}

function AntiDetection:getRandomizedDelay(baseDelay)
	if not self.randomizeTiming then
		return baseDelay
	end
	
	local variance = baseDelay * 0.3 -- 30% variance
	return baseDelay + (math.random() - 0.5) * 2 * variance
end

function AntiDetection:shouldPerformAction()
	local currentTime = tick()
	local timeSinceLastAction = currentTime - self.lastActionTime
	
	if timeSinceLastAction < 0.1 then -- Prevent too rapid actions
		return false
	end
	
	self.lastActionTime = currentTime
	return true
end

-- Enhanced Notification System
local NotificationSystem = {
	queue = {},
	maxNotifications = 5,
	defaultDuration = 3
}

function NotificationSystem:show(message, notificationType, duration)
	notificationType = notificationType or "info"
	duration = duration or self.defaultDuration
	
	local color = CONFIG.COLORS.SUCCESS
	if notificationType == "warning" then
		color = CONFIG.COLORS.WARNING
	elseif notificationType == "error" then
		color = CONFIG.COLORS.ERROR
	end
	
	-- Simple console notification for now
	local prefix = "[" .. notificationType:upper() .. "]"
	print(prefix, message)
	
	-- Store in queue for potential GUI notifications later
	table.insert(self.queue, {
		message = message,
		type = notificationType,
		color = color,
		timestamp = tick(),
		duration = duration
	})
	
	-- Keep queue size manageable
	while #self.queue > self.maxNotifications do
		table.remove(self.queue, 1)
	end
end

-- Global State Management with Auto-Save
local State = {
	autoFishing = false,
	noOxygenDamage = false,
	unlimitedJump = false,
	currentWalkSpeed = Settings.walkSpeed,
	guiVisible = true,
	speedBoost = false,
	fishingStats = {
		totalFishes = 0,
		totalSells = 0,
		sessionStartTime = tick()
	}
}

-- Auto-save state changes
local function updateState(key, value)
	State[key] = value
	if Settings.autoSave then
		saveSettings()
	end
end

-- Connection Management with Cleanup
local connections = {}
local autoFishThread = nil
local performanceThread = nil

-- Utility Functions
local Utils = {}

function Utils.addConnection(connection)
	table.insert(connections, connection)
	return connection
end

function Utils.cleanup()
	NotificationSystem:show("Cleaning up resources...", "info")
	
	for i, connection in ipairs(connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
		connections[i] = nil
	end
	
	if autoFishThread then
		task.cancel(autoFishThread)
		autoFishThread = nil
	end
	
	if performanceThread then
		task.cancel(performanceThread)
		performanceThread = nil
	end
	
	collectgarbage("collect") -- Force garbage collection
end

function Utils.showNotification(message, notificationType, duration)
	NotificationSystem:show(message, notificationType, duration)
end

function Utils.getRandomDelay(min, max)
	min = min or 0.1
	max = max or 0.5
	local baseDelay = math.random(min * 1000, max * 1000) / 1000
	return AntiDetection:getRandomizedDelay(baseDelay)
end

function Utils.animateButton(button, targetSize, duration)
	duration = duration or CONFIG.ANIMATION_SPEED
	local tween = TweenService:Create(
		button,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = targetSize}
	)
	tween:Play()
	return tween
end

function Utils.formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	else
		return string.format("%d:%02d", minutes, secs)
	end
end

-- Initialize settings
loadSettings()

-- Instances:

	local ZayrosFISHIT = Instance.new("ScreenGui")
	local FrameUtama = Instance.new("Frame")
	local ExitBtn = Instance.new("TextButton")
	local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	local UICorner = Instance.new("UICorner")
	local UICorner_2 = Instance.new("UICorner")
	local SideBar = Instance.new("Frame")
	local Logo = Instance.new("ImageLabel")
	local UICorner_3 = Instance.new("UICorner")
	local TittleSideBar = Instance.new("TextLabel")
	local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
	local MainMenuSaidBar = Instance.new("Frame")
	local UIListLayout = Instance.new("UIListLayout")
	local MAIN = Instance.new("TextButton")
	local UICorner_4 = Instance.new("UICorner")
	local UITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")
	local Player = Instance.new("TextButton")
	local UICorner_5 = Instance.new("UICorner")
	local UITextSizeConstraint_4 = Instance.new("UITextSizeConstraint")
	local SpawnBoat = Instance.new("TextButton")
	local UICorner_6 = Instance.new("UICorner")
	local UITextSizeConstraint_5 = Instance.new("UITextSizeConstraint")
	local TELEPORT = Instance.new("TextButton")
	local UICorner_7 = Instance.new("UICorner")
	local UITextSizeConstraint_6 = Instance.new("UITextSizeConstraint")
	local Settings = Instance.new("TextButton")
	local UICorner_8 = Instance.new("UICorner")
	local UITextSizeConstraint_7 = Instance.new("UITextSizeConstraint")
	local Line = Instance.new("Frame")
	local Credit = Instance.new("TextLabel")
	local UITextSizeConstraint_8 = Instance.new("UITextSizeConstraint")
	local Line_2 = Instance.new("Frame")
	local Tittle = Instance.new("TextLabel")
	local UITextSizeConstraint_9 = Instance.new("UITextSizeConstraint")
	local MainFrame = Instance.new("ScrollingFrame")
	local MainListLayoutFrame = Instance.new("Frame")
	local ListLayoutMain = Instance.new("UIListLayout")
	local AutoFishFrame = Instance.new("Frame")
	local UICorner_9 = Instance.new("UICorner")
	local AutoFishText = Instance.new("TextLabel")
	local UITextSizeConstraint_10 = Instance.new("UITextSizeConstraint")
	local AutoFishButton = Instance.new("TextButton")
	local UITextSizeConstraint_11 = Instance.new("UITextSizeConstraint")
	local AutoFishWarna = Instance.new("Frame")
	local UICorner_10 = Instance.new("UICorner")
	local SellAllFrame = Instance.new("Frame")
	local UICorner_11 = Instance.new("UICorner")
	local SellAllButton = Instance.new("TextButton")
	local SellAllText = Instance.new("TextLabel")
	local PlayerFrame = Instance.new("ScrollingFrame")
	local ListLayoutPlayerFrame = Instance.new("Frame")
	local ListLayoutPlayer = Instance.new("UIListLayout")
	local NoOxygenDamageFrame = Instance.new("Frame")
	local UICorner_12 = Instance.new("UICorner")
	local NoOxygenText = Instance.new("TextLabel")
	local NoOxygenWarna = Instance.new("Frame")
	local UICorner_13 = Instance.new("UICorner")
	local NoOxygenButton = Instance.new("TextButton")
	local UITextSizeConstraint_12 = Instance.new("UITextSizeConstraint")
	local UnlimitedJump = Instance.new("Frame")
	local UICorner_14 = Instance.new("UICorner")
	local UnlimitedJumpText = Instance.new("TextLabel")
	local UnlimitedJumpWarna = Instance.new("Frame")
	local UICorner_15 = Instance.new("UICorner")
	local UnlimitedJumpButton = Instance.new("TextButton")
	local UITextSizeConstraint_13 = Instance.new("UITextSizeConstraint")
	local WalkSpeedFrame = Instance.new("Frame")
	local UICorner_16 = Instance.new("UICorner")
	local WalkSpeedText = Instance.new("TextLabel")
	local UITextSizeConstraint_14 = Instance.new("UITextSizeConstraint")
	local WalkSpeedWarna = Instance.new("Frame")
	local UICorner_17 = Instance.new("UICorner")
	local WalkSpeedTextBox = Instance.new("TextBox")
	local UICorner_18 = Instance.new("UICorner")
	local UITextSizeConstraint_15 = Instance.new("UITextSizeConstraint")
	local WalkSpeedFrameButton = Instance.new("Frame")
	local UICorner_19 = Instance.new("UICorner")
	local WalkSpeedAcceptText = Instance.new("TextLabel")
	local SetWalkSpeedButton = Instance.new("TextButton")
	local UICorner_20 = Instance.new("UICorner")
	local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	local Teleport = Instance.new("ScrollingFrame")
	local TPEvent = Instance.new("Frame")
	local UICorner_21 = Instance.new("UICorner")
	local TPEventText = Instance.new("TextLabel")
	local UIAspectRatioConstraint_2 = Instance.new("UIAspectRatioConstraint")
	local TPEventButton = Instance.new("TextButton")
	local UITextSizeConstraint_16 = Instance.new("UITextSizeConstraint")
	local TPEventButtonWarna = Instance.new("Frame")
	local UICorner_22 = Instance.new("UICorner")
	local TPIsland = Instance.new("Frame")
	local UICorner_23 = Instance.new("UICorner")
	local TPIslandText = Instance.new("TextLabel")
	local UITextSizeConstraint_17 = Instance.new("UITextSizeConstraint")
	local TPIslandButton = Instance.new("TextButton")
	local UITextSizeConstraint_18 = Instance.new("UITextSizeConstraint")
	local TPIslandButtonWarna = Instance.new("Frame")
	local UICorner_24 = Instance.new("UICorner")
	local ListOfTPIsland = Instance.new("ScrollingFrame")
	local TPPlayer = Instance.new("Frame")
	local UICorner_25 = Instance.new("UICorner")
	local TPPlayerText = Instance.new("TextLabel")
	local UIAspectRatioConstraint_3 = Instance.new("UIAspectRatioConstraint")
	local TPPlayerButtonWarna = Instance.new("Frame")
	local UICorner_26 = Instance.new("UICorner")
	local TPPlayerButton = Instance.new("TextButton")
	local UITextSizeConstraint_19 = Instance.new("UITextSizeConstraint")
	local ListOfTPEvent = Instance.new("ScrollingFrame")
	local ListOfTpPlayer = Instance.new("ScrollingFrame")
	local SpawnBoatFrame = Instance.new("ScrollingFrame")
	local ListLayoutBoatFrame = Instance.new("Frame")
	local ListLayoutBoat = Instance.new("UIListLayout")
	local DespawnBoat = Instance.new("Frame")
	local UICorner_27 = Instance.new("UICorner")
	local DespawnBoatText = Instance.new("TextLabel")
	local UITextSizeConstraint_20 = Instance.new("UITextSizeConstraint")
	local DespawnBoatButton = Instance.new("TextButton")
	local UITextSizeConstraint_21 = Instance.new("UITextSizeConstraint")
	local SmallBoat = Instance.new("Frame")
	local UICorner_28 = Instance.new("UICorner")
	local SmallBoatButton = Instance.new("TextButton")
	local SmallBoatText = Instance.new("TextLabel")
	local KayakBoat = Instance.new("Frame")
	local UICorner_29 = Instance.new("UICorner")
	local KayakBoatButton = Instance.new("TextButton")
	local KayakBoatText = Instance.new("TextLabel")
	local JetskiBoat = Instance.new("Frame")
	local UICorner_30 = Instance.new("UICorner")
	local JetskiBoatButton = Instance.new("TextButton")
	local JetskiBoatText = Instance.new("TextLabel")
	local HighfieldBoat = Instance.new("Frame")
	local UICorner_31 = Instance.new("UICorner")
	local HighfieldBoatButton = Instance.new("TextButton")
	local HighfieldBoatText = Instance.new("TextLabel")
	local SpeedBoat = Instance.new("Frame")
	local UICorner_32 = Instance.new("UICorner")
	local SpeedBoatButton = Instance.new("TextButton")
	local SpeedBoatText = Instance.new("TextLabel")
	local FishingBoat = Instance.new("Frame")
	local UICorner_33 = Instance.new("UICorner")
	local FishingBoatButton = Instance.new("TextButton")
	local FishingBoatText = Instance.new("TextLabel")
	local MiniYacht = Instance.new("Frame")
	local UICorner_34 = Instance.new("UICorner")
	local MiniYachtButton = Instance.new("TextButton")
	local MiniYachtText = Instance.new("TextLabel")
	local HyperBoat = Instance.new("Frame")
	local UICorner_35 = Instance.new("UICorner")
	local HyperBoatButton = Instance.new("TextButton")
	local HyperBoatText = Instance.new("TextLabel")
	local FrozenBoat = Instance.new("Frame")
	local UICorner_36 = Instance.new("UICorner")
	local FrozenBoatButton = Instance.new("TextButton")
	local FrozenBoatText = Instance.new("TextLabel")
	local CruiserBoat = Instance.new("Frame")
	local UICorner_37 = Instance.new("UICorner")
	local CruiserBoatButton = Instance.new("TextButton")
	local CruiserBoatText = Instance.new("TextLabel")
	local AlphaFloaty = Instance.new("Frame")
	local UICorner_38 = Instance.new("UICorner")
	local AlphaFloatyButton = Instance.new("TextButton")
	local AlphaFloatyText = Instance.new("TextLabel")
	local EvilDuck = Instance.new("Frame")
	local UICorner_39 = Instance.new("UICorner")
	local EvilDuckButton = Instance.new("TextButton")
	local EvilDuckText = Instance.new("TextLabel")
	local FestiveDuck = Instance.new("Frame")
	local UICorner_40 = Instance.new("UICorner")
	local FestiveDuckButton = Instance.new("TextButton")
	local FestiveDuckText = Instance.new("TextLabel")
	local SantaSleigh = Instance.new("Frame")
	local UICorner_41 = Instance.new("UICorner")
	local SantaSleighButton = Instance.new("TextButton")
	local SantaSleighText = Instance.new("TextLabel")

	--Properties:

	ZayrosFISHIT.Name = "ZayrosFISHIT"
	ZayrosFISHIT.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	ZayrosFISHIT.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	FrameUtama.Name = "FrameUtama"
	FrameUtama.Parent = ZayrosFISHIT
	FrameUtama.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	FrameUtama.BackgroundTransparency = 0.200
	FrameUtama.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FrameUtama.BorderSizePixel = 0
	FrameUtama.Position = UDim2.new(0.264131397, 0, 0.17412141, 0)
	FrameUtama.Size = UDim2.new(0.541569591, 0, 0.64997077, 0)

	ExitBtn.Name = "ExitBtn"
	ExitBtn.Parent = FrameUtama
	ExitBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 34)
	ExitBtn.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ExitBtn.BorderSizePixel = 0
	ExitBtn.Position = UDim2.new(0.900729239, 0, 0.0375426635, 0)
	ExitBtn.Size = UDim2.new(0.0630252063, 0, 0.0884955749, 0)
	ExitBtn.Font = Enum.Font.SourceSansBold
	ExitBtn.Text = "X"
	ExitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ExitBtn.TextScaled = true
	ExitBtn.TextSize = 14.000
	ExitBtn.TextWrapped = true

	UITextSizeConstraint.Parent = ExitBtn
	UITextSizeConstraint.MaxTextSize = 14

	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = ExitBtn

	UICorner_2.Parent = FrameUtama

	SideBar.Name = "SideBar"
	SideBar.Parent = FrameUtama
	SideBar.BackgroundColor3 = Color3.fromRGB(83, 83, 83)
	SideBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SideBar.BorderSizePixel = 0
	SideBar.Size = UDim2.new(0.376050383, 0, 1, 0)
	SideBar.ZIndex = 2

	Logo.Name = "Logo"
	Logo.Parent = SideBar
	Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Logo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Logo.BorderSizePixel = 0
	Logo.Position = UDim2.new(0.0729603693, 0, 0.0375426523, 0)
	Logo.Size = UDim2.new(0.167597771, 0, 0.0884955749, 0)
	Logo.ZIndex = 2
	Logo.Image = "rbxassetid://136555589792977"

	UICorner_3.CornerRadius = UDim.new(0, 10)
	UICorner_3.Parent = Logo

	TittleSideBar.Name = "TittleSideBar"
	TittleSideBar.Parent = SideBar
	TittleSideBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TittleSideBar.BackgroundTransparency = 1.000
	TittleSideBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TittleSideBar.BorderSizePixel = 0
	TittleSideBar.Position = UDim2.new(0.309023052, 0, 0.0375426523, 0)
	TittleSideBar.Size = UDim2.new(0.65363127, 0, 0.0884955749, 0)
	TittleSideBar.ZIndex = 2
	TittleSideBar.Font = Enum.Font.SourceSansBold
	TittleSideBar.Text = "Zayros FISHIT"
	TittleSideBar.TextColor3 = Color3.fromRGB(255, 255, 255)
	TittleSideBar.TextScaled = true
	TittleSideBar.TextSize = 20.000
	TittleSideBar.TextWrapped = true
	TittleSideBar.TextXAlignment = Enum.TextXAlignment.Left

	UITextSizeConstraint_2.Parent = TittleSideBar
	UITextSizeConstraint_2.MaxTextSize = 20

	MainMenuSaidBar.Name = "MainMenuSaidBar"
	MainMenuSaidBar.Parent = SideBar
	MainMenuSaidBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MainMenuSaidBar.BackgroundTransparency = 1.000
	MainMenuSaidBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainMenuSaidBar.BorderSizePixel = 0
	MainMenuSaidBar.Position = UDim2.new(0, 0, 0.16519174, 0)
	MainMenuSaidBar.Size = UDim2.new(1, 0, 0.781710923, 0)

	UIListLayout.Parent = MainMenuSaidBar
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0.0500000007, 0)

	MAIN.Name = "MAIN"
	MAIN.Parent = MainMenuSaidBar
	MAIN.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MAIN.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MAIN.BorderSizePixel = 0
	MAIN.Size = UDim2.new(0.916201115, 0, 0.113207549, 0)
	MAIN.Font = Enum.Font.SourceSansBold
	MAIN.Text = "MAIN"
	MAIN.TextColor3 = Color3.fromRGB(255, 255, 255)
	MAIN.TextScaled = true
	MAIN.TextSize = 14.000
	MAIN.TextWrapped = true

	UICorner_4.Parent = MAIN

	UITextSizeConstraint_3.Parent = MAIN
	UITextSizeConstraint_3.MaxTextSize = 14

	Player.Name = "Player"
	Player.Parent = MainMenuSaidBar
	Player.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Player.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Player.BorderSizePixel = 0
	Player.Size = UDim2.new(0.916201115, 0, 0.113207549, 0)
	Player.Font = Enum.Font.SourceSansBold
	Player.Text = "PLAYER"
	Player.TextColor3 = Color3.fromRGB(255, 255, 255)
	Player.TextScaled = true
	Player.TextSize = 14.000
	Player.TextWrapped = true

	UICorner_5.Parent = Player

	UITextSizeConstraint_4.Parent = Player
	UITextSizeConstraint_4.MaxTextSize = 14

	SpawnBoat.Name = "SpawnBoat"
	SpawnBoat.Parent = MainMenuSaidBar
	SpawnBoat.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	SpawnBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SpawnBoat.BorderSizePixel = 0
	SpawnBoat.Size = UDim2.new(0.916201115, 0, 0.113207549, 0)
	SpawnBoat.Font = Enum.Font.SourceSansBold
	SpawnBoat.Text = "SPAWN BOAT"
	SpawnBoat.TextColor3 = Color3.fromRGB(255, 255, 255)
	SpawnBoat.TextScaled = true
	SpawnBoat.TextSize = 14.000
	SpawnBoat.TextWrapped = true

	UICorner_6.Parent = SpawnBoat

	UITextSizeConstraint_5.Parent = SpawnBoat
	UITextSizeConstraint_5.MaxTextSize = 14

	TELEPORT.Name = "TELEPORT"
	TELEPORT.Parent = MainMenuSaidBar
	TELEPORT.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TELEPORT.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TELEPORT.BorderSizePixel = 0
	TELEPORT.Size = UDim2.new(0.916201115, 0, 0.113207549, 0)
	TELEPORT.Font = Enum.Font.SourceSansBold
	TELEPORT.Text = "TELEPORT"
	TELEPORT.TextColor3 = Color3.fromRGB(255, 255, 255)
	TELEPORT.TextScaled = true
	TELEPORT.TextSize = 14.000
	TELEPORT.TextWrapped = true

	UICorner_7.Parent = TELEPORT

	UITextSizeConstraint_6.Parent = TELEPORT
	UITextSizeConstraint_6.MaxTextSize = 14

	Settings.Name = "Settings"
	Settings.Parent = MainMenuSaidBar
	Settings.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Settings.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Settings.BorderSizePixel = 0
	Settings.Position = UDim2.new(0.0418994427, 0, 0.71981132, 0)
	Settings.Size = UDim2.new(0.916201115, 0, 0.113207549, 0)
	Settings.Font = Enum.Font.SourceSansBold
	Settings.Text = "SETTINGS"
	Settings.TextColor3 = Color3.fromRGB(255, 255, 255)
	Settings.TextScaled = true
	Settings.TextSize = 14.000
	Settings.TextWrapped = true

	UICorner_8.Parent = Settings

	UITextSizeConstraint_7.Parent = Settings
	UITextSizeConstraint_7.MaxTextSize = 14

	Line.Name = "Line"
	Line.Parent = SideBar
	Line.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Line.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Line.BorderSizePixel = 0
	Line.Position = UDim2.new(0, 0, 0.144542769, 0)
	Line.Size = UDim2.new(1, 0, 0.0029498525, 0)
	Line.ZIndex = 2

	Credit.Name = "Credit"
	Credit.Parent = SideBar
	Credit.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Credit.BackgroundTransparency = 1.000
	Credit.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Credit.BorderSizePixel = 0
	Credit.Position = UDim2.new(0, 0, 0.874947131, 0)
	Credit.Size = UDim2.new(0.997643113, 0, 0.122885838, 0)
	Credit.Font = Enum.Font.SourceSansBold
	Credit.Text = "Made by Doovy :D"
	Credit.TextColor3 = Color3.fromRGB(255, 255, 255)
	Credit.TextScaled = true
	Credit.TextSize = 14.000
	Credit.TextWrapped = true

	UITextSizeConstraint_8.Parent = Credit
	UITextSizeConstraint_8.MaxTextSize = 14

	Line_2.Name = "Line"
	Line_2.Parent = FrameUtama
	Line_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Line_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Line_2.BorderSizePixel = 0
	Line_2.Position = UDim2.new(0.376050383, 0, 0.144542769, 0)
	Line_2.Size = UDim2.new(0.623949528, 0, 0.0029498525, 0)
	Line_2.ZIndex = 2

	Tittle.Name = "Tittle"
	Tittle.Parent = FrameUtama
	Tittle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Tittle.BackgroundTransparency = 1.000
	Tittle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Tittle.BorderSizePixel = 0
	Tittle.Position = UDim2.new(0.420367569, 0, 0.0375426523, 0)
	Tittle.Size = UDim2.new(0.443547368, 0, 0.0884955749, 0)
	Tittle.ZIndex = 2
	Tittle.Font = Enum.Font.SourceSansBold
	Tittle.Text = "PLAYER"
	Tittle.TextColor3 = Color3.fromRGB(255, 255, 255)
	Tittle.TextScaled = true
	Tittle.TextSize = 20.000
	Tittle.TextWrapped = true

	UITextSizeConstraint_9.Parent = Tittle
	UITextSizeConstraint_9.MaxTextSize = 20

	MainFrame.Name = "MainFrame"
	MainFrame.Parent = FrameUtama
	MainFrame.Active = true
	MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MainFrame.BackgroundTransparency = 1.000
	MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BorderSizePixel = 0
	MainFrame.Position = UDim2.new(0.376050383, 0, 0.147492602, 0)
	MainFrame.Size = UDim2.new(0.623949468, 0, 0.852507353, 0)
	MainFrame.Visible = false
	MainFrame.ZIndex = 2
	MainFrame.ScrollBarThickness = 6

	MainListLayoutFrame.Name = "MainListLayoutFrame"
	MainListLayoutFrame.Parent = MainFrame
	MainListLayoutFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MainListLayoutFrame.BackgroundTransparency = 1.000
	MainListLayoutFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainListLayoutFrame.BorderSizePixel = 0
	MainListLayoutFrame.Position = UDim2.new(0, 0, 0.0219183583, 0)
	MainListLayoutFrame.Size = UDim2.new(1, 0, 1, 0)

	ListLayoutMain.Name = "ListLayoutMain"
	ListLayoutMain.Parent = MainListLayoutFrame
	ListLayoutMain.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ListLayoutMain.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayoutMain.Padding = UDim.new(0, 8)

	AutoFishFrame.Name = "AutoFishFrame"
	AutoFishFrame.Parent = MainListLayoutFrame
	AutoFishFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	AutoFishFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	AutoFishFrame.BorderSizePixel = 0
	AutoFishFrame.Position = UDim2.new(0.0437708385, 0, 0.0418279432, 0)
	AutoFishFrame.Size = UDim2.new(0.898138702, 0, 0.106191501, 0)

	UICorner_9.Parent = AutoFishFrame

	AutoFishText.Name = "AutoFishText"
	AutoFishText.Parent = AutoFishFrame
	AutoFishText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	AutoFishText.BackgroundTransparency = 1.000
	AutoFishText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	AutoFishText.BorderSizePixel = 0
	AutoFishText.Position = UDim2.new(0.0296296291, 0, 0.216216221, 0)
	AutoFishText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	AutoFishText.Font = Enum.Font.SourceSansBold
	AutoFishText.Text = "Auto Fish (AFK) :"
	AutoFishText.TextColor3 = Color3.fromRGB(255, 255, 255)
	AutoFishText.TextScaled = true
	AutoFishText.TextSize = 14.000
	AutoFishText.TextWrapped = true
	AutoFishText.TextXAlignment = Enum.TextXAlignment.Left

	UITextSizeConstraint_10.Parent = AutoFishText
	UITextSizeConstraint_10.MaxTextSize = 14

	AutoFishButton.Name = "AutoFishButton"
	AutoFishButton.Parent = AutoFishFrame
	AutoFishButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	AutoFishButton.BackgroundTransparency = 1.000
	AutoFishButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	AutoFishButton.BorderSizePixel = 0
	AutoFishButton.Position = UDim2.new(0.75555557, 0, 0.108108111, 0)
	AutoFishButton.Size = UDim2.new(0.2074074, 0, 0.783783793, 0)
	AutoFishButton.ZIndex = 2
	AutoFishButton.Font = Enum.Font.SourceSansBold
	AutoFishButton.Text = "OFF"
	AutoFishButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	AutoFishButton.TextScaled = true
	AutoFishButton.TextSize = 14.000
	AutoFishButton.TextWrapped = true

	UITextSizeConstraint_11.Parent = AutoFishButton
	UITextSizeConstraint_11.MaxTextSize = 14

	AutoFishWarna.Name = "AutoFishWarna"
	AutoFishWarna.Parent = AutoFishFrame
	AutoFishWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	AutoFishWarna.BorderColor3 = Color3.fromRGB(0, 0, 0)
	AutoFishWarna.BorderSizePixel = 0
	AutoFishWarna.Position = UDim2.new(0.75555557, 0, 0.135135129, 0)
	AutoFishWarna.Size = UDim2.new(0.203703701, 0, 0.729729712, 0)

	UICorner_10.Parent = AutoFishWarna

	SellAllFrame.Name = "SellAllFrame"
	SellAllFrame.Parent = MainListLayoutFrame
	SellAllFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	SellAllFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SellAllFrame.BorderSizePixel = 0
	SellAllFrame.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	SellAllFrame.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_11.Parent = SellAllFrame

	SellAllButton.Name = "SellAllButton"
	SellAllButton.Parent = SellAllFrame
	SellAllButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SellAllButton.BackgroundTransparency = 1.000
	SellAllButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SellAllButton.BorderSizePixel = 0
	SellAllButton.Size = UDim2.new(1, 0, 1, 0)
	SellAllButton.ZIndex = 2
	SellAllButton.Font = Enum.Font.SourceSansBold
	SellAllButton.Text = ""
	SellAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SellAllButton.TextSize = 14.000

	SellAllText.Name = "SellAllText"
	SellAllText.Parent = SellAllFrame
	SellAllText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SellAllText.BackgroundTransparency = 1.000
	SellAllText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SellAllText.BorderSizePixel = 0
	SellAllText.Position = UDim2.new(0.290409207, 0, 0.216216132, 0)
	SellAllText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	SellAllText.Font = Enum.Font.SourceSansBold
	SellAllText.Text = "Sell All"
	SellAllText.TextColor3 = Color3.fromRGB(255, 255, 255)
	SellAllText.TextScaled = true
	SellAllText.TextSize = 14.000
	SellAllText.TextWrapped = true

	PlayerFrame.Name = "PlayerFrame"
	PlayerFrame.Parent = FrameUtama
	PlayerFrame.Active = true
	PlayerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	PlayerFrame.BackgroundTransparency = 1.000
	PlayerFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PlayerFrame.BorderSizePixel = 0
	PlayerFrame.Position = UDim2.new(0.376050383, 0, 0.147492632, 0)
	PlayerFrame.Size = UDim2.new(0.623949528, 0, 0.852507353, 0)
	PlayerFrame.ScrollBarThickness = 6

	ListLayoutPlayerFrame.Name = "ListLayoutPlayerFrame"
	ListLayoutPlayerFrame.Parent = PlayerFrame
	ListLayoutPlayerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ListLayoutPlayerFrame.BackgroundTransparency = 1.000
	ListLayoutPlayerFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ListLayoutPlayerFrame.BorderSizePixel = 0
	ListLayoutPlayerFrame.Position = UDim2.new(0, 0, 0.0219183583, 0)
	ListLayoutPlayerFrame.Size = UDim2.new(1, 0, 1, 0)

	ListLayoutPlayer.Name = "ListLayoutPlayer"
	ListLayoutPlayer.Parent = ListLayoutPlayerFrame
	ListLayoutPlayer.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ListLayoutPlayer.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayoutPlayer.Padding = UDim.new(0, 8)

	NoOxygenDamageFrame.Name = "NoOxygenDamageFrame"
	NoOxygenDamageFrame.Parent = ListLayoutPlayerFrame
	NoOxygenDamageFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	NoOxygenDamageFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	NoOxygenDamageFrame.BorderSizePixel = 0
	NoOxygenDamageFrame.Position = UDim2.new(0.0404040329, 0, 0.272833079, 0)
	NoOxygenDamageFrame.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_12.Parent = NoOxygenDamageFrame

	NoOxygenText.Name = "NoOxygenText"
	NoOxygenText.Parent = NoOxygenDamageFrame
	NoOxygenText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NoOxygenText.BackgroundTransparency = 1.000
	NoOxygenText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	NoOxygenText.BorderSizePixel = 0
	NoOxygenText.Position = UDim2.new(0.0296296291, 0, 0.216216221, 0)
	NoOxygenText.Size = UDim2.new(0, 112, 0, 21)
	NoOxygenText.Font = Enum.Font.SourceSansBold
	NoOxygenText.Text = "NO OXYGEN DAMAGE :"
	NoOxygenText.TextColor3 = Color3.fromRGB(255, 255, 255)
	NoOxygenText.TextSize = 14.000
	NoOxygenText.TextXAlignment = Enum.TextXAlignment.Left

	NoOxygenWarna.Name = "NoOxygenWarna"
	NoOxygenWarna.Parent = NoOxygenDamageFrame
	NoOxygenWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	NoOxygenWarna.BorderColor3 = Color3.fromRGB(0, 0, 0)
	NoOxygenWarna.BorderSizePixel = 0
	NoOxygenWarna.Position = UDim2.new(0.718999982, 0, 0.135000005, 0)
	NoOxygenWarna.Size = UDim2.new(0.256999999, 0, 0.730000019, 0)

	UICorner_13.Parent = NoOxygenWarna

	NoOxygenButton.Name = "NoOxygenButton"
	NoOxygenButton.Parent = NoOxygenDamageFrame
	NoOxygenButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NoOxygenButton.BackgroundTransparency = 1.000
	NoOxygenButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	NoOxygenButton.BorderSizePixel = 0
	NoOxygenButton.Position = UDim2.new(0.73773706, 0, 0.108108483, 0)
	NoOxygenButton.Size = UDim2.new(0.2074074, 0, 0.783783793, 0)
	NoOxygenButton.ZIndex = 2
	NoOxygenButton.Font = Enum.Font.SourceSansBold
	NoOxygenButton.Text = "OFF"
	NoOxygenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	NoOxygenButton.TextScaled = true
	NoOxygenButton.TextSize = 14.000
	NoOxygenButton.TextWrapped = true

	UITextSizeConstraint_12.Parent = NoOxygenButton
	UITextSizeConstraint_12.MaxTextSize = 14

	UnlimitedJump.Name = "UnlimitedJump"
	UnlimitedJump.Parent = ListLayoutPlayerFrame
	UnlimitedJump.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	UnlimitedJump.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UnlimitedJump.BorderSizePixel = 0
	UnlimitedJump.Position = UDim2.new(0.0404040329, 0, 0.272833079, 0)
	UnlimitedJump.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_14.Parent = UnlimitedJump

	UnlimitedJumpText.Name = "UnlimitedJumpText"
	UnlimitedJumpText.Parent = UnlimitedJump
	UnlimitedJumpText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	UnlimitedJumpText.BackgroundTransparency = 1.000
	UnlimitedJumpText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UnlimitedJumpText.BorderSizePixel = 0
	UnlimitedJumpText.Position = UDim2.new(0.0296296291, 0, 0.216216221, 0)
	UnlimitedJumpText.Size = UDim2.new(0, 112, 0, 21)
	UnlimitedJumpText.Font = Enum.Font.SourceSansBold
	UnlimitedJumpText.Text = "Unlimited Jump :"
	UnlimitedJumpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	UnlimitedJumpText.TextSize = 14.000
	UnlimitedJumpText.TextXAlignment = Enum.TextXAlignment.Left

	UnlimitedJumpWarna.Name = "UnlimitedJumpWarna"
	UnlimitedJumpWarna.Parent = UnlimitedJump
	UnlimitedJumpWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	UnlimitedJumpWarna.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UnlimitedJumpWarna.BorderSizePixel = 0
	UnlimitedJumpWarna.Position = UDim2.new(0.718999982, 0, 0.135000005, 0)
	UnlimitedJumpWarna.Size = UDim2.new(0.256999999, 0, 0.730000019, 0)

	UICorner_15.Parent = UnlimitedJumpWarna

	UnlimitedJumpButton.Name = "UnlimitedJumpButton"
	UnlimitedJumpButton.Parent = UnlimitedJump
	UnlimitedJumpButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	UnlimitedJumpButton.BackgroundTransparency = 1.000
	UnlimitedJumpButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UnlimitedJumpButton.BorderSizePixel = 0
	UnlimitedJumpButton.Position = UDim2.new(0.73773706, 0, 0.108108483, 0)
	UnlimitedJumpButton.Size = UDim2.new(0.2074074, 0, 0.783783793, 0)
	UnlimitedJumpButton.ZIndex = 2
	UnlimitedJumpButton.Font = Enum.Font.SourceSansBold
	UnlimitedJumpButton.Text = "OFF"
	UnlimitedJumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	UnlimitedJumpButton.TextScaled = true
	UnlimitedJumpButton.TextSize = 14.000
	UnlimitedJumpButton.TextWrapped = true

	UITextSizeConstraint_13.Parent = UnlimitedJumpButton
	UITextSizeConstraint_13.MaxTextSize = 14

	WalkSpeedFrame.Name = "WalkSpeedFrame"
	WalkSpeedFrame.Parent = ListLayoutPlayerFrame
	WalkSpeedFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	WalkSpeedFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	WalkSpeedFrame.BorderSizePixel = 0
	WalkSpeedFrame.Position = UDim2.new(0.0437710434, 0, 0.0202609263, 0)
	WalkSpeedFrame.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_16.Parent = WalkSpeedFrame

	WalkSpeedText.Name = "WalkSpeedText"
	WalkSpeedText.Parent = WalkSpeedFrame
	WalkSpeedText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	WalkSpeedText.BackgroundTransparency = 1.000
	WalkSpeedText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	WalkSpeedText.BorderSizePixel = 0
	WalkSpeedText.Position = UDim2.new(0.0296296291, 0, 0.216216221, 0)
	WalkSpeedText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	WalkSpeedText.Font = Enum.Font.SourceSansBold
	WalkSpeedText.Text = "WALK SPEED:"
	WalkSpeedText.TextColor3 = Color3.fromRGB(255, 255, 255)
	WalkSpeedText.TextScaled = true
	WalkSpeedText.TextSize = 14.000
	WalkSpeedText.TextWrapped = true
	WalkSpeedText.TextXAlignment = Enum.TextXAlignment.Left

	UITextSizeConstraint_14.Parent = WalkSpeedText
	UITextSizeConstraint_14.MaxTextSize = 14

	WalkSpeedWarna.Name = "WalkSpeedWarna"
	WalkSpeedWarna.Parent = WalkSpeedFrame
	WalkSpeedWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	WalkSpeedWarna.BorderColor3 = Color3.fromRGB(0, 0, 0)
	WalkSpeedWarna.BorderSizePixel = 0
	WalkSpeedWarna.Position = UDim2.new(0.718999982, 0, 0.135000005, 0)
	WalkSpeedWarna.Size = UDim2.new(0.256999999, 0, 0.730000019, 0)

	UICorner_17.Parent = WalkSpeedWarna

	WalkSpeedTextBox.Name = "WalkSpeedTextBox"
	WalkSpeedTextBox.Parent = WalkSpeedFrame
	WalkSpeedTextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	WalkSpeedTextBox.BackgroundTransparency = 1.000
	WalkSpeedTextBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	WalkSpeedTextBox.BorderSizePixel = 0
	WalkSpeedTextBox.Position = UDim2.new(0.718999982, 0, 0.135000005, 0)
	WalkSpeedTextBox.Size = UDim2.new(0.256999999, 0, 0.730000019, 0)
	WalkSpeedTextBox.ZIndex = 3
	WalkSpeedTextBox.Font = Enum.Font.SourceSansBold
	WalkSpeedTextBox.PlaceholderColor3 = Color3.fromRGB(108, 108, 108)
	WalkSpeedTextBox.PlaceholderText = "18"
	WalkSpeedTextBox.Text = ""
	WalkSpeedTextBox.TextColor3 = Color3.fromRGB(253, 253, 253)
	WalkSpeedTextBox.TextScaled = true
	WalkSpeedTextBox.TextSize = 18.000
	WalkSpeedTextBox.TextWrapped = true

	UICorner_18.Parent = WalkSpeedTextBox

	UITextSizeConstraint_15.Parent = WalkSpeedTextBox
	UITextSizeConstraint_15.MaxTextSize = 18

	WalkSpeedFrameButton.Name = "WalkSpeedFrameButton"
	WalkSpeedFrameButton.Parent = ListLayoutPlayerFrame
	WalkSpeedFrameButton.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	WalkSpeedFrameButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	WalkSpeedFrameButton.BorderSizePixel = 0
	WalkSpeedFrameButton.Position = UDim2.new(0.658801138, 0, 0.249478042, 0)
	WalkSpeedFrameButton.Size = UDim2.new(0.289999992, 0, 0.0680000037, 0)

	UICorner_19.Parent = WalkSpeedFrameButton

	WalkSpeedAcceptText.Name = "WalkSpeedAcceptText"
	WalkSpeedAcceptText.Parent = WalkSpeedFrameButton
	WalkSpeedAcceptText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	WalkSpeedAcceptText.BackgroundTransparency = 1.000
	WalkSpeedAcceptText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	WalkSpeedAcceptText.BorderSizePixel = 0
	WalkSpeedAcceptText.Position = UDim2.new(0.0368366279, 0, -0.0509649925, 0)
	WalkSpeedAcceptText.Size = UDim2.new(0.967370987, 0, 0.943781316, 0)
	WalkSpeedAcceptText.Font = Enum.Font.SourceSansBold
	WalkSpeedAcceptText.Text = "SET WALKSPEED"
	WalkSpeedAcceptText.TextColor3 = Color3.fromRGB(255, 255, 255)
	WalkSpeedAcceptText.TextScaled = true
	WalkSpeedAcceptText.TextWrapped = true

	SetWalkSpeedButton.Name = "SetWalkSpeedButton"
	SetWalkSpeedButton.Parent = WalkSpeedFrameButton
	SetWalkSpeedButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SetWalkSpeedButton.BackgroundTransparency = 1.000
	SetWalkSpeedButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SetWalkSpeedButton.BorderSizePixel = 0
	SetWalkSpeedButton.Position = UDim2.new(0.111111112, 0, 0, 0)
	SetWalkSpeedButton.Size = UDim2.new(0.888888896, 0, 1, 0)
	SetWalkSpeedButton.Font = Enum.Font.SourceSans
	SetWalkSpeedButton.Text = ""
	SetWalkSpeedButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	SetWalkSpeedButton.TextSize = 14.000

	UICorner_20.Parent = SetWalkSpeedButton

	UIAspectRatioConstraint.Parent = FrameUtama
	UIAspectRatioConstraint.AspectRatio = 1.245

	Teleport.Name = "Teleport"
	Teleport.Parent = FrameUtama
	Teleport.Active = true
	Teleport.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Teleport.BackgroundTransparency = 1.000
	Teleport.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Teleport.BorderSizePixel = 0
	Teleport.Position = UDim2.new(0.376050383, 0, 0.147492602, 0)
	Teleport.Size = UDim2.new(0.623949468, 0, 0.852507353, 0)
	Teleport.Visible = false
	Teleport.ZIndex = 2
	Teleport.ScrollBarThickness = 6

	TPEvent.Name = "TPEvent"
	TPEvent.Parent = Teleport
	TPEvent.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	TPEvent.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPEvent.BorderSizePixel = 0
	TPEvent.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	TPEvent.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_21.Parent = TPEvent

	TPEventText.Name = "TPEventText"
	TPEventText.Parent = TPEvent
	TPEventText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TPEventText.BackgroundTransparency = 1.000
	TPEventText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPEventText.BorderSizePixel = 0
	TPEventText.Position = UDim2.new(0.0296296291, 0, 0.216216221, 0)
	TPEventText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	TPEventText.Font = Enum.Font.SourceSansBold
	TPEventText.Text = "TP EVENT :"
	TPEventText.TextColor3 = Color3.fromRGB(255, 255, 255)
	TPEventText.TextScaled = true
	TPEventText.TextSize = 14.000
	TPEventText.TextWrapped = true
	TPEventText.TextXAlignment = Enum.TextXAlignment.Left

	UIAspectRatioConstraint_2.Parent = TPEventText
	UIAspectRatioConstraint_2.AspectRatio = 5.641

	TPEventButton.Name = "TPEventButton"
	TPEventButton.Parent = TPEvent
	TPEventButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TPEventButton.BackgroundTransparency = 1.000
	TPEventButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPEventButton.BorderSizePixel = 0
	TPEventButton.Position = UDim2.new(0.75555557, 0, 0.108108111, 0)
	TPEventButton.Size = UDim2.new(0.2074074, 0, 0.783783793, 0)
	TPEventButton.ZIndex = 2
	TPEventButton.Font = Enum.Font.SourceSansBold
	TPEventButton.Text = "V"
	TPEventButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TPEventButton.TextScaled = true
	TPEventButton.TextSize = 14.000
	TPEventButton.TextWrapped = true

	UITextSizeConstraint_16.Parent = TPEventButton
	UITextSizeConstraint_16.MaxTextSize = 14

	TPEventButtonWarna.Name = "TPEventButtonWarna"
	TPEventButtonWarna.Parent = TPEvent
	TPEventButtonWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TPEventButtonWarna.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPEventButtonWarna.BorderSizePixel = 0
	TPEventButtonWarna.Position = UDim2.new(0.75555557, 0, 0.135135129, 0)
	TPEventButtonWarna.Size = UDim2.new(0.203703701, 0, 0.729729712, 0)

	UICorner_22.Parent = TPEventButtonWarna

	TPIsland.Name = "TPIsland"
	TPIsland.Parent = Teleport
	TPIsland.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	TPIsland.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPIsland.BorderSizePixel = 0
	TPIsland.Position = UDim2.new(0.0437708385, 0, 0.0418279432, 0)
	TPIsland.Size = UDim2.new(0.898138702, 0, 0.106191501, 0)

	UICorner_23.Parent = TPIsland

	TPIslandText.Name = "TPIslandText"
	TPIslandText.Parent = TPIsland
	TPIslandText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TPIslandText.BackgroundTransparency = 1.000
	TPIslandText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPIslandText.BorderSizePixel = 0
	TPIslandText.Position = UDim2.new(0.0296296291, 0, 0.216216221, 0)
	TPIslandText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	TPIslandText.Font = Enum.Font.SourceSansBold
	TPIslandText.Text = "TP ISLAND :"
	TPIslandText.TextColor3 = Color3.fromRGB(255, 255, 255)
	TPIslandText.TextScaled = true
	TPIslandText.TextSize = 14.000
	TPIslandText.TextWrapped = true
	TPIslandText.TextXAlignment = Enum.TextXAlignment.Left

	UITextSizeConstraint_17.Parent = TPIslandText
	UITextSizeConstraint_17.MaxTextSize = 14

	TPIslandButton.Name = "TPIslandButton"
	TPIslandButton.Parent = TPIsland
	TPIslandButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TPIslandButton.BackgroundTransparency = 1.000
	TPIslandButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPIslandButton.BorderSizePixel = 0
	TPIslandButton.Position = UDim2.new(0.75555557, 0, 0.108108111, 0)
	TPIslandButton.Size = UDim2.new(0.2074074, 0, 0.783783793, 0)
	TPIslandButton.ZIndex = 2
	TPIslandButton.Font = Enum.Font.SourceSansBold
	TPIslandButton.Text = "V"
	TPIslandButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TPIslandButton.TextScaled = true
	TPIslandButton.TextSize = 14.000
	TPIslandButton.TextWrapped = true

	UITextSizeConstraint_18.Parent = TPIslandButton
	UITextSizeConstraint_18.MaxTextSize = 14

	TPIslandButtonWarna.Name = "TPIslandButtonWarna"
	TPIslandButtonWarna.Parent = TPIsland
	TPIslandButtonWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TPIslandButtonWarna.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPIslandButtonWarna.BorderSizePixel = 0
	TPIslandButtonWarna.Position = UDim2.new(0.75555557, 0, 0.135135129, 0)
	TPIslandButtonWarna.Size = UDim2.new(0.203703701, 0, 0.729729712, 0)

	UICorner_24.Parent = TPIslandButtonWarna

	ListOfTPIsland.Name = "ListOfTPIsland"
	ListOfTPIsland.Parent = Teleport
	ListOfTPIsland.Active = true
	ListOfTPIsland.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	ListOfTPIsland.BackgroundTransparency = 0.700
	ListOfTPIsland.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ListOfTPIsland.BorderSizePixel = 0
	ListOfTPIsland.Position = UDim2.new(0.590924203, 0, 0.147147402, 0)
	ListOfTPIsland.Size = UDim2.new(0, 100, 0, 143)
	ListOfTPIsland.ZIndex = 3
	ListOfTPIsland.Visible = false
	ListOfTPIsland.AutomaticCanvasSize = Enum.AutomaticSize.Y

	TPPlayer.Name = "TPPlayer"
	TPPlayer.Parent = Teleport
	TPPlayer.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	TPPlayer.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPPlayer.BorderSizePixel = 0
	TPPlayer.Position = UDim2.new(0.0397706926, 0, 0.391719788, 0)
	TPPlayer.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_25.Parent = TPPlayer

	TPPlayerText.Name = "TPPlayerText"
	TPPlayerText.Parent = TPPlayer
	TPPlayerText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TPPlayerText.BackgroundTransparency = 1.000
	TPPlayerText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPPlayerText.BorderSizePixel = 0
	TPPlayerText.Position = UDim2.new(0.0296296291, 0, 0.216216221, 0)
	TPPlayerText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	TPPlayerText.Font = Enum.Font.SourceSansBold
	TPPlayerText.Text = "TP PLAYER:"
	TPPlayerText.TextColor3 = Color3.fromRGB(255, 255, 255)
	TPPlayerText.TextScaled = true
	TPPlayerText.TextSize = 14.000
	TPPlayerText.TextWrapped = true
	TPPlayerText.TextXAlignment = Enum.TextXAlignment.Left

	UIAspectRatioConstraint_3.Parent = TPPlayerText
	UIAspectRatioConstraint_3.AspectRatio = 5.641

	TPPlayerButtonWarna.Name = "TPPlayerButtonWarna"
	TPPlayerButtonWarna.Parent = TPPlayer
	TPPlayerButtonWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TPPlayerButtonWarna.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPPlayerButtonWarna.BorderSizePixel = 0
	TPPlayerButtonWarna.Position = UDim2.new(0.75555557, 0, 0.135135129, 0)
	TPPlayerButtonWarna.Size = UDim2.new(0.203703701, 0, 0.729729712, 0)

	UICorner_26.Parent = TPPlayerButtonWarna

	TPPlayerButton.Name = "TPPlayerButton"
	TPPlayerButton.Parent = TPPlayer
	TPPlayerButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TPPlayerButton.BackgroundTransparency = 1.000
	TPPlayerButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TPPlayerButton.BorderSizePixel = 0
	TPPlayerButton.Position = UDim2.new(0.75555557, 0, 0.108108111, 0)
	TPPlayerButton.Size = UDim2.new(0.2074074, 0, 0.783783793, 0)
	TPPlayerButton.ZIndex = 2
	TPPlayerButton.Font = Enum.Font.SourceSansBold
	TPPlayerButton.Text = "V"
	TPPlayerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TPPlayerButton.TextScaled = true
	TPPlayerButton.TextSize = 14.000
	TPPlayerButton.TextWrapped = true

	UITextSizeConstraint_19.Parent = TPPlayerButton
	UITextSizeConstraint_19.MaxTextSize = 14

	ListOfTPEvent.Name = "ListOfTPEvent"
	ListOfTPEvent.Parent = Teleport
	ListOfTPEvent.Active = true
	ListOfTPEvent.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	ListOfTPEvent.BackgroundTransparency = 0.700
	ListOfTPEvent.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ListOfTPEvent.BorderSizePixel = 0
	ListOfTPEvent.Position = UDim2.new(0.590924203, 0, 0.317240119, 0)
	ListOfTPEvent.Size = UDim2.new(0, 100, 0, 143)
	ListOfTPEvent.Visible = false
	ListOfTPEvent.AutomaticCanvasSize = Enum.AutomaticSize.Y

	ListOfTpPlayer.Name = "ListOfTpPlayer"
	ListOfTpPlayer.Parent = Teleport
	ListOfTpPlayer.Active = true
	ListOfTpPlayer.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	ListOfTpPlayer.BackgroundTransparency = 0.700
	ListOfTpPlayer.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ListOfTpPlayer.BorderSizePixel = 0
	ListOfTpPlayer.Position = UDim2.new(0.584594965, 0, 0.495981604, 0)
	ListOfTpPlayer.Size = UDim2.new(0, 100, 0, 143)
	ListOfTpPlayer.Visible = false
	ListOfTpPlayer.AutomaticCanvasSize = Enum.AutomaticSize.Y

	SpawnBoatFrame.Name = "SpawnBoatFrame"
	SpawnBoatFrame.Parent = FrameUtama
	SpawnBoatFrame.Active = true
	SpawnBoatFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SpawnBoatFrame.BackgroundTransparency = 1.000
	SpawnBoatFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SpawnBoatFrame.BorderSizePixel = 0
	SpawnBoatFrame.Position = UDim2.new(0.376050383, 0, 0.147492602, 0)
	SpawnBoatFrame.Size = UDim2.new(0.623949468, 0, 0.852507353, 0)
	SpawnBoatFrame.Visible = false
	SpawnBoatFrame.ZIndex = 2
	SpawnBoatFrame.ScrollBarThickness = 6
	SpawnBoatFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

	ListLayoutBoatFrame.Name = "ListLayoutBoatFrame"
	ListLayoutBoatFrame.Parent = SpawnBoatFrame
	ListLayoutBoatFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ListLayoutBoatFrame.BackgroundTransparency = 1.000
	ListLayoutBoatFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ListLayoutBoatFrame.BorderSizePixel = 0
	ListLayoutBoatFrame.Position = UDim2.new(0, 0, 0.0219183583, 0)
	ListLayoutBoatFrame.Size = UDim2.new(1, 0, 1, 0)

	ListLayoutBoat.Name = "ListLayoutBoat"
	ListLayoutBoat.Parent = ListLayoutBoatFrame
	ListLayoutBoat.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ListLayoutBoat.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayoutBoat.Padding = UDim.new(0, 8)

	DespawnBoat.Name = "DespawnBoat"
	DespawnBoat.Parent = ListLayoutBoatFrame
	DespawnBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	DespawnBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DespawnBoat.BorderSizePixel = 0
	DespawnBoat.Position = UDim2.new(0.0437708385, 0, 0.0418279432, 0)
	DespawnBoat.Size = UDim2.new(0.898138702, 0, 0.106191501, 0)

	UICorner_27.Parent = DespawnBoat

	DespawnBoatText.Name = "DespawnBoatText"
	DespawnBoatText.Parent = DespawnBoat
	DespawnBoatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	DespawnBoatText.BackgroundTransparency = 1.000
	DespawnBoatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DespawnBoatText.BorderSizePixel = 0
	DespawnBoatText.Position = UDim2.new(0.0120122591, 0, 0.216216043, 0)
	DespawnBoatText.Size = UDim2.new(0.970370531, 0, 0.567567527, 0)
	DespawnBoatText.Font = Enum.Font.SourceSansBold
	DespawnBoatText.Text = "Despawn Boat"
	DespawnBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	DespawnBoatText.TextScaled = true
	DespawnBoatText.TextSize = 14.000
	DespawnBoatText.TextWrapped = true

	UITextSizeConstraint_20.Parent = DespawnBoatText
	UITextSizeConstraint_20.MaxTextSize = 14

	DespawnBoatButton.Name = "DespawnBoatButton"
	DespawnBoatButton.Parent = DespawnBoat
	DespawnBoatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	DespawnBoatButton.BackgroundTransparency = 1.000
	DespawnBoatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	DespawnBoatButton.BorderSizePixel = 0
	DespawnBoatButton.Size = UDim2.new(1, 0, 1, 0)
	DespawnBoatButton.ZIndex = 2
	DespawnBoatButton.Font = Enum.Font.SourceSansBold
	DespawnBoatButton.Text = ""
	DespawnBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	DespawnBoatButton.TextScaled = true
	DespawnBoatButton.TextSize = 14.000
	DespawnBoatButton.TextWrapped = true

	UITextSizeConstraint_21.Parent = DespawnBoatButton
	UITextSizeConstraint_21.MaxTextSize = 14

	SmallBoat.Name = "SmallBoat"
	SmallBoat.Parent = ListLayoutBoatFrame
	SmallBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	SmallBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SmallBoat.BorderSizePixel = 0
	SmallBoat.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	SmallBoat.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_28.Parent = SmallBoat

	SmallBoatButton.Name = "SmallBoatButton"
	SmallBoatButton.Parent = SmallBoat
	SmallBoatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SmallBoatButton.BackgroundTransparency = 1.000
	SmallBoatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SmallBoatButton.BorderSizePixel = 0
	SmallBoatButton.Size = UDim2.new(1, 0, 1, 0)
	SmallBoatButton.ZIndex = 2
	SmallBoatButton.Font = Enum.Font.SourceSansBold
	SmallBoatButton.Text = ""
	SmallBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SmallBoatButton.TextSize = 14.000

	SmallBoatText.Name = "SmallBoatText"
	SmallBoatText.Parent = SmallBoat
	SmallBoatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SmallBoatText.BackgroundTransparency = 1.000
	SmallBoatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SmallBoatText.BorderSizePixel = 0
	SmallBoatText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	SmallBoatText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	SmallBoatText.Font = Enum.Font.SourceSansBold
	SmallBoatText.Text = "Small Boat"
	SmallBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	SmallBoatText.TextScaled = true
	SmallBoatText.TextSize = 14.000
	SmallBoatText.TextWrapped = true

	KayakBoat.Name = "KayakBoat"
	KayakBoat.Parent = ListLayoutBoatFrame
	KayakBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	KayakBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	KayakBoat.BorderSizePixel = 0
	KayakBoat.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	KayakBoat.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_29.Parent = KayakBoat

	KayakBoatButton.Name = "KayakBoatButton"
	KayakBoatButton.Parent = KayakBoat
	KayakBoatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	KayakBoatButton.BackgroundTransparency = 1.000
	KayakBoatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	KayakBoatButton.BorderSizePixel = 0
	KayakBoatButton.Size = UDim2.new(1, 0, 1, 0)
	KayakBoatButton.ZIndex = 2
	KayakBoatButton.Font = Enum.Font.SourceSansBold
	KayakBoatButton.Text = ""
	KayakBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	KayakBoatButton.TextSize = 14.000

	KayakBoatText.Name = "KayakBoatText"
	KayakBoatText.Parent = KayakBoat
	KayakBoatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	KayakBoatText.BackgroundTransparency = 1.000
	KayakBoatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	KayakBoatText.BorderSizePixel = 0
	KayakBoatText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	KayakBoatText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	KayakBoatText.Font = Enum.Font.SourceSansBold
	KayakBoatText.Text = "Kayak"
	KayakBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	KayakBoatText.TextScaled = true
	KayakBoatText.TextSize = 14.000
	KayakBoatText.TextWrapped = true

	JetskiBoat.Name = "JetskiBoat"
	JetskiBoat.Parent = ListLayoutBoatFrame
	JetskiBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	JetskiBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	JetskiBoat.BorderSizePixel = 0
	JetskiBoat.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	JetskiBoat.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_30.Parent = JetskiBoat

	JetskiBoatButton.Name = "JetskiBoatButton"
	JetskiBoatButton.Parent = JetskiBoat
	JetskiBoatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	JetskiBoatButton.BackgroundTransparency = 1.000
	JetskiBoatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	JetskiBoatButton.BorderSizePixel = 0
	JetskiBoatButton.Size = UDim2.new(1, 0, 1, 0)
	JetskiBoatButton.ZIndex = 2
	JetskiBoatButton.Font = Enum.Font.SourceSansBold
	JetskiBoatButton.Text = ""
	JetskiBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	JetskiBoatButton.TextSize = 14.000

	JetskiBoatText.Name = "JetskiBoatText"
	JetskiBoatText.Parent = JetskiBoat
	JetskiBoatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	JetskiBoatText.BackgroundTransparency = 1.000
	JetskiBoatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	JetskiBoatText.BorderSizePixel = 0
	JetskiBoatText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	JetskiBoatText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	JetskiBoatText.Font = Enum.Font.SourceSansBold
	JetskiBoatText.Text = "Jetski"
	JetskiBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	JetskiBoatText.TextScaled = true
	JetskiBoatText.TextSize = 14.000
	JetskiBoatText.TextWrapped = true

	HighfieldBoat.Name = "HighfieldBoat"
	HighfieldBoat.Parent = ListLayoutBoatFrame
	HighfieldBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	HighfieldBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HighfieldBoat.BorderSizePixel = 0
	HighfieldBoat.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	HighfieldBoat.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_31.Parent = HighfieldBoat

	HighfieldBoatButton.Name = "HighfieldBoatButton"
	HighfieldBoatButton.Parent = HighfieldBoat
	HighfieldBoatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HighfieldBoatButton.BackgroundTransparency = 1.000
	HighfieldBoatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HighfieldBoatButton.BorderSizePixel = 0
	HighfieldBoatButton.Size = UDim2.new(1, 0, 1, 0)
	HighfieldBoatButton.ZIndex = 2
	HighfieldBoatButton.Font = Enum.Font.SourceSansBold
	HighfieldBoatButton.Text = ""
	HighfieldBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	HighfieldBoatButton.TextSize = 14.000

	HighfieldBoatText.Name = "HighfieldBoatText"
	HighfieldBoatText.Parent = HighfieldBoat
	HighfieldBoatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HighfieldBoatText.BackgroundTransparency = 1.000
	HighfieldBoatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HighfieldBoatText.BorderSizePixel = 0
	HighfieldBoatText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	HighfieldBoatText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	HighfieldBoatText.Font = Enum.Font.SourceSansBold
	HighfieldBoatText.Text = "Highfield Boat"
	HighfieldBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	HighfieldBoatText.TextScaled = true
	HighfieldBoatText.TextSize = 14.000
	HighfieldBoatText.TextWrapped = true

	SpeedBoat.Name = "SpeedBoat"
	SpeedBoat.Parent = ListLayoutBoatFrame
	SpeedBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	SpeedBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SpeedBoat.BorderSizePixel = 0
	SpeedBoat.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	SpeedBoat.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_32.Parent = SpeedBoat

	SpeedBoatButton.Name = "SpeedBoatButton"
	SpeedBoatButton.Parent = SpeedBoat
	SpeedBoatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SpeedBoatButton.BackgroundTransparency = 1.000
	SpeedBoatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SpeedBoatButton.BorderSizePixel = 0
	SpeedBoatButton.Size = UDim2.new(1, 0, 1, 0)
	SpeedBoatButton.ZIndex = 2
	SpeedBoatButton.Font = Enum.Font.SourceSansBold
	SpeedBoatButton.Text = ""
	SpeedBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SpeedBoatButton.TextSize = 14.000

	SpeedBoatText.Name = "SpeedBoatText"
	SpeedBoatText.Parent = SpeedBoat
	SpeedBoatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SpeedBoatText.BackgroundTransparency = 1.000
	SpeedBoatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SpeedBoatText.BorderSizePixel = 0
	SpeedBoatText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	SpeedBoatText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	SpeedBoatText.Font = Enum.Font.SourceSansBold
	SpeedBoatText.Text = "Speed Boat"
	SpeedBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	SpeedBoatText.TextScaled = true
	SpeedBoatText.TextSize = 14.000
	SpeedBoatText.TextWrapped = true

	FishingBoat.Name = "FishingBoat"
	FishingBoat.Parent = ListLayoutBoatFrame
	FishingBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	FishingBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FishingBoat.BorderSizePixel = 0
	FishingBoat.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	FishingBoat.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_33.Parent = FishingBoat

	FishingBoatButton.Name = "FishingBoatButton"
	FishingBoatButton.Parent = FishingBoat
	FishingBoatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	FishingBoatButton.BackgroundTransparency = 1.000
	FishingBoatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FishingBoatButton.BorderSizePixel = 0
	FishingBoatButton.Size = UDim2.new(1, 0, 1, 0)
	FishingBoatButton.ZIndex = 2
	FishingBoatButton.Font = Enum.Font.SourceSansBold
	FishingBoatButton.Text = ""
	FishingBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	FishingBoatButton.TextSize = 14.000

	FishingBoatText.Name = "FishingBoatText"
	FishingBoatText.Parent = FishingBoat
	FishingBoatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	FishingBoatText.BackgroundTransparency = 1.000
	FishingBoatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FishingBoatText.BorderSizePixel = 0
	FishingBoatText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	FishingBoatText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	FishingBoatText.Font = Enum.Font.SourceSansBold
	FishingBoatText.Text = "Fishing Boat"
	FishingBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	FishingBoatText.TextScaled = true
	FishingBoatText.TextSize = 14.000
	FishingBoatText.TextWrapped = true

	MiniYacht.Name = "MiniYacht"
	MiniYacht.Parent = ListLayoutBoatFrame
	MiniYacht.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	MiniYacht.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MiniYacht.BorderSizePixel = 0
	MiniYacht.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	MiniYacht.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_34.Parent = MiniYacht

	MiniYachtButton.Name = "MiniYachtButton"
	MiniYachtButton.Parent = MiniYacht
	MiniYachtButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MiniYachtButton.BackgroundTransparency = 1.000
	MiniYachtButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MiniYachtButton.BorderSizePixel = 0
	MiniYachtButton.Size = UDim2.new(1, 0, 1, 0)
	MiniYachtButton.ZIndex = 2
	MiniYachtButton.Font = Enum.Font.SourceSansBold
	MiniYachtButton.Text = ""
	MiniYachtButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	MiniYachtButton.TextSize = 14.000

	MiniYachtText.Name = "MiniYachtText"
	MiniYachtText.Parent = MiniYacht
	MiniYachtText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MiniYachtText.BackgroundTransparency = 1.000
	MiniYachtText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MiniYachtText.BorderSizePixel = 0
	MiniYachtText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	MiniYachtText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	MiniYachtText.Font = Enum.Font.SourceSansBold
	MiniYachtText.Text = "Mini Yacht"
	MiniYachtText.TextColor3 = Color3.fromRGB(255, 255, 255)
	MiniYachtText.TextScaled = true
	MiniYachtText.TextSize = 14.000
	MiniYachtText.TextWrapped = true

	HyperBoat.Name = "HyperBoat"
	HyperBoat.Parent = ListLayoutBoatFrame
	HyperBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	HyperBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HyperBoat.BorderSizePixel = 0
	HyperBoat.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	HyperBoat.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_35.Parent = HyperBoat

	HyperBoatButton.Name = "HyperBoatButton"
	HyperBoatButton.Parent = HyperBoat
	HyperBoatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HyperBoatButton.BackgroundTransparency = 1.000
	HyperBoatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HyperBoatButton.BorderSizePixel = 0
	HyperBoatButton.Size = UDim2.new(1, 0, 1, 0)
	HyperBoatButton.ZIndex = 2
	HyperBoatButton.Font = Enum.Font.SourceSansBold
	HyperBoatButton.Text = ""
	HyperBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	HyperBoatButton.TextSize = 14.000

	HyperBoatText.Name = "HyperBoatText"
	HyperBoatText.Parent = HyperBoat
	HyperBoatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HyperBoatText.BackgroundTransparency = 1.000
	HyperBoatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HyperBoatText.BorderSizePixel = 0
	HyperBoatText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	HyperBoatText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	HyperBoatText.Font = Enum.Font.SourceSansBold
	HyperBoatText.Text = "Hyper Boat"
	HyperBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	HyperBoatText.TextScaled = true
	HyperBoatText.TextSize = 14.000
	HyperBoatText.TextWrapped = true

	FrozenBoat.Name = "FrozenBoat"
	FrozenBoat.Parent = ListLayoutBoatFrame
	FrozenBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	FrozenBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FrozenBoat.BorderSizePixel = 0
	FrozenBoat.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	FrozenBoat.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_36.Parent = FrozenBoat

	FrozenBoatButton.Name = "FrozenBoatButton"
	FrozenBoatButton.Parent = FrozenBoat
	FrozenBoatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	FrozenBoatButton.BackgroundTransparency = 1.000
	FrozenBoatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FrozenBoatButton.BorderSizePixel = 0
	FrozenBoatButton.Size = UDim2.new(1, 0, 1, 0)
	FrozenBoatButton.ZIndex = 2
	FrozenBoatButton.Font = Enum.Font.SourceSansBold
	FrozenBoatButton.Text = ""
	FrozenBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	FrozenBoatButton.TextSize = 14.000

	FrozenBoatText.Name = "FrozenBoatText"
	FrozenBoatText.Parent = FrozenBoat
	FrozenBoatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	FrozenBoatText.BackgroundTransparency = 1.000
	FrozenBoatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FrozenBoatText.BorderSizePixel = 0
	FrozenBoatText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	FrozenBoatText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	FrozenBoatText.Font = Enum.Font.SourceSansBold
	FrozenBoatText.Text = "Frozen Boat"
	FrozenBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	FrozenBoatText.TextScaled = true
	FrozenBoatText.TextSize = 14.000
	FrozenBoatText.TextWrapped = true

	CruiserBoat.Name = "CruiserBoat"
	CruiserBoat.Parent = ListLayoutBoatFrame
	CruiserBoat.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	CruiserBoat.BorderColor3 = Color3.fromRGB(0, 0, 0)
	CruiserBoat.BorderSizePixel = 0
	CruiserBoat.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	CruiserBoat.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_37.Parent = CruiserBoat

	CruiserBoatButton.Name = "CruiserBoatButton"
	CruiserBoatButton.Parent = CruiserBoat
	CruiserBoatButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	CruiserBoatButton.BackgroundTransparency = 1.000
	CruiserBoatButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	CruiserBoatButton.BorderSizePixel = 0
	CruiserBoatButton.Size = UDim2.new(1, 0, 1, 0)
	CruiserBoatButton.ZIndex = 2
	CruiserBoatButton.Font = Enum.Font.SourceSansBold
	CruiserBoatButton.Text = ""
	CruiserBoatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CruiserBoatButton.TextSize = 14.000

	CruiserBoatText.Name = "CruiserBoatText"
	CruiserBoatText.Parent = CruiserBoat
	CruiserBoatText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	CruiserBoatText.BackgroundTransparency = 1.000
	CruiserBoatText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	CruiserBoatText.BorderSizePixel = 0
	CruiserBoatText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	CruiserBoatText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	CruiserBoatText.Font = Enum.Font.SourceSansBold
	CruiserBoatText.Text = "Cruiser Boat"
	CruiserBoatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	CruiserBoatText.TextScaled = true
	CruiserBoatText.TextSize = 14.000
	CruiserBoatText.TextWrapped = true

	AlphaFloaty.Name = "AlphaFloaty"
	AlphaFloaty.Parent = ListLayoutBoatFrame
	AlphaFloaty.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	AlphaFloaty.BorderColor3 = Color3.fromRGB(0, 0, 0)
	AlphaFloaty.BorderSizePixel = 0
	AlphaFloaty.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	AlphaFloaty.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_38.Parent = AlphaFloaty

	AlphaFloatyButton.Name = "AlphaFloatyButton"
	AlphaFloatyButton.Parent = AlphaFloaty
	AlphaFloatyButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	AlphaFloatyButton.BackgroundTransparency = 1.000
	AlphaFloatyButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	AlphaFloatyButton.BorderSizePixel = 0
	AlphaFloatyButton.Size = UDim2.new(1, 0, 1, 0)
	AlphaFloatyButton.ZIndex = 2
	AlphaFloatyButton.Font = Enum.Font.SourceSansBold
	AlphaFloatyButton.Text = ""
	AlphaFloatyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	AlphaFloatyButton.TextSize = 14.000

	AlphaFloatyText.Name = "AlphaFloatyText"
	AlphaFloatyText.Parent = AlphaFloaty
	AlphaFloatyText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	AlphaFloatyText.BackgroundTransparency = 1.000
	AlphaFloatyText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	AlphaFloatyText.BorderSizePixel = 0
	AlphaFloatyText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	AlphaFloatyText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	AlphaFloatyText.Font = Enum.Font.SourceSansBold
	AlphaFloatyText.Text = "Alpha Floaty"
	AlphaFloatyText.TextColor3 = Color3.fromRGB(255, 255, 255)
	AlphaFloatyText.TextScaled = true
	AlphaFloatyText.TextSize = 14.000
	AlphaFloatyText.TextWrapped = true

	EvilDuck.Name = "EvilDuck"
	EvilDuck.Parent = ListLayoutBoatFrame
	EvilDuck.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	EvilDuck.BorderColor3 = Color3.fromRGB(0, 0, 0)
	EvilDuck.BorderSizePixel = 0
	EvilDuck.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	EvilDuck.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_39.Parent = EvilDuck

	EvilDuckButton.Name = "EvilDuckButton"
	EvilDuckButton.Parent = EvilDuck
	EvilDuckButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	EvilDuckButton.BackgroundTransparency = 1.000
	EvilDuckButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	EvilDuckButton.BorderSizePixel = 0
	EvilDuckButton.Size = UDim2.new(1, 0, 1, 0)
	EvilDuckButton.ZIndex = 2
	EvilDuckButton.Font = Enum.Font.SourceSansBold
	EvilDuckButton.Text = ""
	EvilDuckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	EvilDuckButton.TextSize = 14.000

	EvilDuckText.Name = "EvilDuckText"
	EvilDuckText.Parent = EvilDuck
	EvilDuckText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	EvilDuckText.BackgroundTransparency = 1.000
	EvilDuckText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	EvilDuckText.BorderSizePixel = 0
	EvilDuckText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	EvilDuckText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	EvilDuckText.Font = Enum.Font.SourceSansBold
	EvilDuckText.Text = "DEV Evil Duck 9000"
	EvilDuckText.TextColor3 = Color3.fromRGB(255, 255, 255)
	EvilDuckText.TextScaled = true
	EvilDuckText.TextSize = 14.000
	EvilDuckText.TextWrapped = true

	FestiveDuck.Name = "FestiveDuck"
	FestiveDuck.Parent = ListLayoutBoatFrame
	FestiveDuck.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	FestiveDuck.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FestiveDuck.BorderSizePixel = 0
	FestiveDuck.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	FestiveDuck.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_40.Parent = FestiveDuck

	FestiveDuckButton.Name = "FestiveDuckButton"
	FestiveDuckButton.Parent = FestiveDuck
	FestiveDuckButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	FestiveDuckButton.BackgroundTransparency = 1.000
	FestiveDuckButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FestiveDuckButton.BorderSizePixel = 0
	FestiveDuckButton.Size = UDim2.new(1, 0, 1, 0)
	FestiveDuckButton.ZIndex = 2
	FestiveDuckButton.Font = Enum.Font.SourceSansBold
	FestiveDuckButton.Text = ""
	FestiveDuckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	FestiveDuckButton.TextSize = 14.000

	FestiveDuckText.Name = "FestiveDuckText"
	FestiveDuckText.Parent = FestiveDuck
	FestiveDuckText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	FestiveDuckText.BackgroundTransparency = 1.000
	FestiveDuckText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	FestiveDuckText.BorderSizePixel = 0
	FestiveDuckText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	FestiveDuckText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	FestiveDuckText.Font = Enum.Font.SourceSansBold
	FestiveDuckText.Text = "Festive Duck"
	FestiveDuckText.TextColor3 = Color3.fromRGB(255, 255, 255)
	FestiveDuckText.TextScaled = true
	FestiveDuckText.TextSize = 14.000
	FestiveDuckText.TextWrapped = true

	SantaSleigh.Name = "SantaSleigh"
	SantaSleigh.Parent = ListLayoutBoatFrame
	SantaSleigh.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
	SantaSleigh.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SantaSleigh.BorderSizePixel = 0
	SantaSleigh.Position = UDim2.new(0.0437710434, 0, 0.209508449, 0)
	SantaSleigh.Size = UDim2.new(0.898000002, 0, 0.105999999, 0)

	UICorner_41.Parent = SantaSleigh

	SantaSleighButton.Name = "SantaSleighButton"
	SantaSleighButton.Parent = SantaSleigh
	SantaSleighButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SantaSleighButton.BackgroundTransparency = 1.000
	SantaSleighButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SantaSleighButton.BorderSizePixel = 0
	SantaSleighButton.Size = UDim2.new(1, 0, 1, 0)
	SantaSleighButton.ZIndex = 2
	SantaSleighButton.Font = Enum.Font.SourceSansBold
	SantaSleighButton.Text = ""
	SantaSleighButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SantaSleighButton.TextSize = 14.000

	SantaSleighText.Name = "SantaSleighText"
	SantaSleighText.Parent = SantaSleigh
	SantaSleighText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SantaSleighText.BackgroundTransparency = 1.000
	SantaSleighText.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SantaSleighText.BorderSizePixel = 0
	SantaSleighText.Position = UDim2.new(0.286885142, 0, 0.216216132, 0)
	SantaSleighText.Size = UDim2.new(0.4148148, 0, 0.567567587, 0)
	SantaSleighText.Font = Enum.Font.SourceSansBold
	SantaSleighText.Text = "Santa Sleigh"
	SantaSleighText.TextColor3 = Color3.fromRGB(255, 255, 255)
	SantaSleighText.TextScaled = true
	SantaSleighText.TextSize = 14.000
	SantaSleighText.TextWrapped = true

	-- Core Variables
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild("ZayrosFISHIT")
	local Rs = game:GetService("ReplicatedStorage")

	-- Remote Events/Functions with validation
	local Remotes = {}
	
	local function initializeRemotes()
		local remoteIndex = Rs.Packages._Index["sleitnick_net@0.2.0"].net
		
		Remotes.EquipRod = remoteIndex["RE/EquipToolFromHotbar"]
		Remotes.UnEquipRod = remoteIndex["RE/UnequipToolFromHotbar"]
		Remotes.RequestFishing = remoteIndex["RF/RequestFishingMinigameStarted"]
		Remotes.ChargeRod = remoteIndex["RF/ChargeFishingRod"]
		Remotes.FishingComplete = remoteIndex["RE/FishingCompleted"]
		Remotes.CancelFishing = remoteIndex["RF/CancelFishingInputs"]
		Remotes.spawnBoat = remoteIndex["RF/SpawnBoat"]
		Remotes.despawnBoat = remoteIndex["RF/DespawnBoat"]
		Remotes.FishingRadar = remoteIndex["RF/UpdateFishingRadar"]
		Remotes.sellAll = remoteIndex["RF/SellAllItems"]
		
		return validateRemotes()
	end
	
	local function validateRemotes()
		for name, remote in pairs(Remotes) do
			if not remote or not remote.Parent then
				warn("Remote not found:", name)
				return false
			end
		end
		return true
	end

	-- External modules
	local noOxygen = loadstring(game:HttpGet("https://pastebin.com/raw/JS7LaJsa"))()
	
	-- World references
	local tpFolder = workspace["!!!! ISLAND LOCATIONS !!!!"]
	local charFolder = workspace.Characters

	-- UI State Management
	local uiState = {
		isOpen = {
			Island = false,
			Player = false,
			Event = false,
		},
		currentPage = "Main",
		lastFishingTime = 0
	}

	-- Enhanced Functions
	local GameFunctions = {}

	function GameFunctions.toggleFishing(state)
		if not validateRemotes() then
			Utils.showNotification("Error: Game remotes not available", 5)
			return false
		end
		
		State.autoFishing = state
		
		if state then
			Utils.showNotification("Auto Fishing: ON")
			autoFishThread = task.spawn(function()
				while State.autoFishing do
					local success, err = pcall(function()
						local currentTime = workspace:GetServerTimeNow()
						if currentTime - uiState.lastFishingTime >= CONFIG.FISHING_COOLDOWN then
							-- Ensure rod is equipped
							local char = character or player.Character
							if char then
								local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")
								
								if not equippedTool then
									Remotes.CancelFishing:InvokeServer()
									Remotes.EquipRod:FireServer(1)
									task.wait(0.2)
								end
								
								-- Fishing sequence with human-like timing
								Remotes.ChargeRod:InvokeServer(workspace:GetServerTimeNow())
								task.wait(Utils.getRandomDelay(0.1, 0.3))
								Remotes.RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
								task.wait(Utils.getRandomDelay(0.3, 0.5))
								Remotes.FishingComplete:FireServer()
								
								uiState.lastFishingTime = currentTime
							end
						end
						task.wait(0.1) -- Reduce CPU usage
					end)
					
					if not success then
						warn("Auto fishing error:", err)
						task.wait(1) -- Wait before retry
					end
				end
			end)
		else
			Utils.showNotification("Auto Fishing: OFF")
			if autoFishThread then
				task.cancel(autoFishThread)
				autoFishThread = nil
			end
			
			pcall(function()
				Remotes.CancelFishing:InvokeServer()
				Remotes.UnEquipRod:FireServer()
			end)
		end
		
		return true
	end

	function GameFunctions.toggleNoOxygen()
		local state = noOxygen.toggle()
		State.noOxygenDamage = state
		Utils.showNotification("No Oxygen Damage: " .. (state and "ON" or "OFF"))
		return state
	end

	function GameFunctions.setWalkSpeed(speed)
		speed = tonumber(speed) or CONFIG.WALK_SPEED_DEFAULT
		State.currentWalkSpeed = speed
		
		local humanoid = character and character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = speed
			Utils.showNotification("Walk Speed set to: " .. speed)
		end
	end

	function GameFunctions.sellAllItems()
		if validateRemotes() then
			Remotes.sellAll:InvokeServer()
			Utils.showNotification("Selling all items...")
		end
	end

	function GameFunctions.spawnBoat(boatType)
		if validateRemotes() then
			Remotes.spawnBoat:InvokeServer(boatType)
			Utils.showNotification("Spawning " .. boatType)
		end
	end

	function GameFunctions.despawnBoat()
		if validateRemotes() then
			Remotes.despawnBoat:InvokeServer()
			Utils.showNotification("Boat despawned")
		end
	end

	-- UI Management
	local UI = {}

	function UI.closeAllLists()
		uiState.isOpen.Island = false
		uiState.isOpen.Player = false
		uiState.isOpen.Event = false
		
		ListOfTPIsland.Visible = false
		ListOfTpPlayer.Visible = false
		ListOfTPEvent.Visible = false
	end

	function UI.toggleList(name)
		if not uiState.isOpen[name] then
			UI.closeAllLists()
			uiState.isOpen[name] = true
			
			if name == "Island" then
				ListOfTPIsland.Visible = true
			elseif name == "Player" then
				ListOfTpPlayer.Visible = true
			elseif name == "Event" then
				ListOfTPEvent.Visible = true
			end
		else
			uiState.isOpen[name] = false
			if name == "Island" then
				ListOfTPIsland.Visible = false
			elseif name == "Player" then
				ListOfTpPlayer.Visible = false
			elseif name == "Event" then
				ListOfTPEvent.Visible = false
			end
		end
	end

	function UI.showPanel(pageName)
		local pages = {
			Main = MainFrame,
			Player = PlayerFrame,
			Teleport = Teleport,
			Boat = SpawnBoatFrame,
		}
		
		-- Hide all panels
		for _, panel in pairs(pages) do
			panel.Visible = false
		end

		-- Show selected panel
		local selectedPanel = pages[pageName]
		if selectedPanel then
			selectedPanel.Visible = true
			Tittle.Text = pageName:upper()
			uiState.currentPage = pageName
		end
	end

	function UI.updateButtonState(button, state, activeText, inactiveText)
		activeText = activeText or "ON"
		inactiveText = inactiveText or "OFF"
		
		button.Text = state and activeText or inactiveText
		
		-- Find the color frame (assuming it follows naming convention)
		local colorFrame = button.Parent:FindFirstChild(button.Name:gsub("Button", "Warna")) or 
						  button.Parent:FindFirstChild(button.Name:gsub("Button", "ButtonWarna"))
		
		if colorFrame then
			colorFrame.BackgroundColor3 = state and CONFIG.COLORS.ACTIVE or CONFIG.COLORS.INACTIVE
		end
	end

	-- Initialize remotes
	if not initializeRemotes() then
		warn("Failed to initialize remotes - some features may not work")
	end

	-- Dynamic List Generation
	local function generateTeleportLists()
		local index = 0
		
		-- Generate Island List
		for _, island in ipairs(tpFolder:GetChildren()) do
			if island:IsA("BasePart") then
				local btn = Instance.new("TextButton")
				btn.Name = island.Name
				btn.Size = UDim2.new(1, 0, 0.1, 0)
				btn.Position = UDim2.new(0, 0, (0.1 + 0.02) * index, 0)
				btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				btn.Text = island.Name
				btn.TextScaled = true
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.Font = Enum.Font.GothamBold
				btn.Parent = ListOfTPIsland
				
				-- Add hover effect
				Utils.addConnection(btn.MouseEnter:Connect(function()
					btn.BackgroundColor3 = CONFIG.COLORS.BUTTON_HOVER
				end))
				
				Utils.addConnection(btn.MouseLeave:Connect(function()
					btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				end))
				
				Utils.addConnection(btn.MouseButton1Click:Connect(function()
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						hrp.CFrame = island.CFrame
						Utils.showNotification("Teleported to " .. island.Name)
					end
				end))
				
				index = index + 1
			end
		end
		
		index = 0
		
		-- Generate Player List
		for _, playerChar in ipairs(charFolder:GetChildren()) do
			if playerChar:IsA("Model") and playerChar.Name ~= player.Name then
				local btn = Instance.new("TextButton")
				btn.Name = playerChar.Name
				btn.Parent = ListOfTpPlayer
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				btn.Text = playerChar.Name
				btn.Size = UDim2.new(1, 0, 0.1, 0)
				btn.Position = UDim2.new(0, 0, (0.1 + 0.02) * index, 0)
				btn.Font = Enum.Font.GothamBold
				btn.TextScaled = true
				
				-- Add hover effect
				Utils.addConnection(btn.MouseEnter:Connect(function()
					btn.BackgroundColor3 = CONFIG.COLORS.BUTTON_HOVER
				end))
				
				Utils.addConnection(btn.MouseLeave:Connect(function()
					btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				end))
				
				Utils.addConnection(btn.MouseButton1Click:Connect(function()
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					local targetHrp = playerChar:FindFirstChild("HumanoidRootPart")
					if hrp and targetHrp then
						hrp.CFrame = targetHrp.CFrame
						Utils.showNotification("Teleported to " .. playerChar.Name)
					end
				end))
				
				index = index + 1
			end
		end
	end

	-- Button Event Handlers
	local function setupEventHandlers()
		-- Auto Fish Button
		Utils.addConnection(AutoFishButton.MouseButton1Click:Connect(function()
			local success = GameFunctions.toggleFishing(not State.autoFishing)
			if success then
				UI.updateButtonState(AutoFishButton, State.autoFishing)
			end
		end))

		-- Exit Button
		Utils.addConnection(ExitBtn.MouseButton1Click:Connect(function()
			Utils.cleanup()
			ZayrosFISHIT:Destroy()
		end))

		-- Navigation Buttons
		Utils.addConnection(MAIN.MouseButton1Click:Connect(function()
			UI.showPanel("Main")
		end))

		Utils.addConnection(Player.MouseButton1Click:Connect(function()
			UI.showPanel("Player")
		end))

		Utils.addConnection(TELEPORT.MouseButton1Click:Connect(function()
			UI.showPanel("Teleport")
		end))

		Utils.addConnection(SpawnBoat.MouseButton1Click:Connect(function()
			UI.showPanel("Boat")
		end))

		-- Feature Buttons
		Utils.addConnection(NoOxygenButton.MouseButton1Click:Connect(function()
			local state = GameFunctions.toggleNoOxygen()
			UI.updateButtonState(NoOxygenButton, state)
		end))
		
		Utils.addConnection(UnlimitedJumpButton.MouseButton1Click:Connect(function()
			State.unlimitedJump = not State.unlimitedJump
			UI.updateButtonState(UnlimitedJumpButton, State.unlimitedJump)
			
			local humanoid = character and character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.JumpHeight = State.unlimitedJump and math.huge or 7.2
			end
		end))
		
		-- Walk Speed System
		Utils.addConnection(SetWalkSpeedButton.MouseButton1Click:Connect(function()
			local speed = tonumber(WalkSpeedTextBox.Text)
			if speed then
				GameFunctions.setWalkSpeed(speed)
			else
				Utils.showNotification("Invalid speed value")
			end
		end))
		
		-- Teleport List Toggles
		Utils.addConnection(TPIslandButton.MouseButton1Click:Connect(function()
			UI.toggleList("Island")
		end))
		
		Utils.addConnection(TPPlayerButton.MouseButton1Click:Connect(function()
			UI.toggleList("Player")
		end))
		
		Utils.addConnection(TPEventButton.MouseButton1Click:Connect(function()
			UI.toggleList("Event")
		end))

		-- Sell All Button
		Utils.addConnection(SellAllButton.MouseButton1Click:Connect(function()
			GameFunctions.sellAllItems()
		end))

		-- Boat Spawn Buttons
		local boatButtons = {
			{button = SmallBoatButton, type = "SmallBoat"},
			{button = KayakBoatButton, type = "Kayak"},
			{button = JetskiBoatButton, type = "Jetski"},
			{button = HighfieldBoatButton, type = "HighfieldBoat"},
			{button = SpeedBoatButton, type = "SpeedBoat"},
			{button = FishingBoatButton, type = "FishingBoat"},
			{button = MiniYachtButton, type = "MiniYacht"},
			{button = HyperBoatButton, type = "HyperBoat"},
			{button = FrozenBoatButton, type = "FrozenBoat"},
			{button = CruiserBoatButton, type = "CruiserBoat"},
			{button = AlphaFloatyButton, type = "AlphaFloaty"},
			{button = EvilDuckButton, type = "EvilDuck"},
			{button = FestiveDuckButton, type = "FestiveDuck"},
			{button = SantaSleighButton, type = "SantaSleigh"}
		}
		
		for _, boat in ipairs(boatButtons) do
			Utils.addConnection(boat.button.MouseButton1Click:Connect(function()
				GameFunctions.spawnBoat(boat.type)
			end))
		end
		
		Utils.addConnection(DespawnBoatButton.MouseButton1Click:Connect(function()
			GameFunctions.despawnBoat()
		end))
	end

	-- Keybind System
	local function setupKeybinds()
		Utils.addConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			
			if input.KeyCode == CONFIG.KEYBINDS.TOGGLE_GUI then
				State.guiVisible = not State.guiVisible
				ZayrosFISHIT.Enabled = State.guiVisible
				Utils.showNotification("GUI " .. (State.guiVisible and "Shown" or "Hidden"))
				
			elseif input.KeyCode == CONFIG.KEYBINDS.AUTO_FISH then
				local success = GameFunctions.toggleFishing(not State.autoFishing)
				if success then
					UI.updateButtonState(AutoFishButton, State.autoFishing)
				end
				
			elseif input.KeyCode == CONFIG.KEYBINDS.TELEPORT_MENU then
				UI.showPanel("Teleport")
			end
		end))
	end

	-- Character Management
	local function setupCharacterHandling()
		local function onCharacterAdded(newCharacter)
			character = newCharacter
			
			-- Wait for humanoid
			local humanoid = newCharacter:WaitForChild("Humanoid", 5)
			if humanoid and State.currentWalkSpeed ~= CONFIG.WALK_SPEED_DEFAULT then
				humanoid.WalkSpeed = State.currentWalkSpeed
			end
			
			if humanoid and State.unlimitedJump then
				humanoid.JumpHeight = math.huge
			end
		end
		
		if player.Character then
			onCharacterAdded(player.Character)
		end
		
		Utils.addConnection(player.CharacterAdded:Connect(onCharacterAdded))
	end

	-- Initialization
	local function initialize()
		-- Setup character handling
		setupCharacterHandling()
		
		-- Generate dynamic lists
		generateTeleportLists()
		
		-- Setup all event handlers
		setupEventHandlers()
		
		-- Setup keybinds
		setupKeybinds()
		
		-- Show default panel
		UI.showPanel("Main")
		
		-- Success notification
		Utils.showNotification("Zayros FISHIT Enhanced - Ready!")
		print("=== Zayros FISHIT Enhanced Loaded ===")
		print("Keybinds:")
		print("- Right Ctrl: Toggle GUI")
		print("- F: Toggle Auto Fish")
		print("- T: Open Teleport Menu")
		print("====================================")
	end

	-- Start the script with performance monitoring
	initialize()
	
	-- Performance monitoring thread
	performanceThread = task.spawn(function()
		while ZayrosFISHIT and ZayrosFISHIT.Parent do
			PerformanceMonitor:update()
			
			-- Update fishing stats display if needed
			local sessionTime = tick() - State.fishingStats.sessionStartTime
			if sessionTime > 0 then
				local fishPerHour = (State.fishingStats.totalFishes / sessionTime) * 3600
				-- You can add a stats display to the GUI here
			end
			
			task.wait(1) -- Update every second
		end
	end)

	-- Cleanup on GUI destruction
	Utils.addConnection(ZayrosFISHIT.AncestryChanged:Connect(function()
		if not ZayrosFISHIT.Parent then
			local sessionTime = tick() - State.fishingStats.sessionStartTime
			Utils.showNotification(string.format(
				"Session ended. Time: %s, Fishes: %d, Sells: %d", 
				Utils.formatTime(sessionTime),
				State.fishingStats.totalFishes,
				State.fishingStats.totalSells
			), "info", 5)
			
			saveSettings()
			Utils.cleanup()
		end
	end))

	-- Auto-save settings periodically
	Utils.addConnection(RunService.Heartbeat:Connect(function()
		-- Auto-save every 30 seconds
		if tick() % 30 < 0.1 and Settings.autoSave then
			saveSettings()
		end
	end))
	
	-- Enhanced Error Handling
	local function globalErrorHandler()
		Utils.addConnection(game:GetService("ScriptContext").ErrorDetailed:Connect(function(message, trace, script)
			if script and script.Name == "ZayrosFISHIT" then
				Utils.showNotification("Script error detected: " .. tostring(message), "error", 10)
				-- Attempt to recover or restart critical functions
				if State.autoFishing and not autoFishThread then
					Utils.showNotification("Attempting to restart auto fishing...", "warning")
					GameFunctions.toggleFishing(true)
				end
			end
		end))
	end
	
	globalErrorHandler()

-- ===============================================
-- Additional Features & Enhancements
-- ===============================================

-- Feature: Quick Actions Menu (Right-click context menu)
local function createQuickActionsMenu()
	local quickMenu = Instance.new("Frame")
	quickMenu.Name = "QuickActionsMenu"
	quickMenu.Size = UDim2.new(0, 150, 0, 200)
	quickMenu.Position = UDim2.new(0, 0, 0, 0)
	quickMenu.BackgroundColor3 = CONFIG.COLORS.BACKGROUND
	quickMenu.BorderSizePixel = 0
	quickMenu.Visible = false
	quickMenu.ZIndex = 10
	quickMenu.Parent = ZayrosFISHIT
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = quickMenu
	
	local actions = {
		{name = "Toggle Auto Fish", action = function() 
			local success = GameFunctions.toggleFishing(not State.autoFishing)
			if success then UI.updateButtonState(AutoFishButton, State.autoFishing) end
		end},
		{name = "Sell All Items", action = GameFunctions.sellAllItems},
		{name = "Reset Walk Speed", action = function() 
			GameFunctions.setWalkSpeed(CONFIG.WALK_SPEED_DEFAULT) 
		end},
		{name = "Emergency Stop", action = function()
			State.autoFishing = false
			if autoFishThread then task.cancel(autoFishThread) end
			Utils.showNotification("Emergency stop activated!", "warning")
		end}
	}
	
	for i, action in ipairs(actions) do
		local btn = Instance.new("TextButton")
		btn.Name = action.name
		btn.Size = UDim2.new(1, 0, 0, 40)
		btn.Position = UDim2.new(0, 0, 0, (i-1) * 40)
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		btn.Text = action.name
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.SourceSansBold
		btn.TextSize = 12
		btn.BorderSizePixel = 0
		btn.Parent = quickMenu
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = btn
		
		Utils.addConnection(btn.MouseButton1Click:Connect(function()
			action.action()
			quickMenu.Visible = false
		end))
		
		Utils.addConnection(btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = CONFIG.COLORS.BUTTON_HOVER
		end))
		
		Utils.addConnection(btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		end))
	end
	
	-- Right-click to show menu
	Utils.addConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and ZayrosFISHIT.Enabled then
			local mouse = Players.LocalPlayer:GetMouse()
			quickMenu.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
			quickMenu.Visible = true
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			quickMenu.Visible = false
		end
	end))
end

-- Feature: Status Bar
local function createStatusBar()
	local statusBar = Instance.new("Frame")
	statusBar.Name = "StatusBar"
	statusBar.Size = UDim2.new(1, 0, 0, 25)
	statusBar.Position = UDim2.new(0, 0, 1, -25)
	statusBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	statusBar.BorderSizePixel = 0
	statusBar.Parent = FrameUtama
	
	local statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(1, -10, 1, 0)
	statusText.Position = UDim2.new(0, 5, 0, 0)
	statusText.BackgroundTransparency = 1
	statusText.Text = "Ready - Right Ctrl: Toggle GUI | F: Auto Fish | T: Teleport"
	statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusText.TextScaled = true
	statusText.Font = Enum.Font.SourceSans
	statusText.TextXAlignment = Enum.TextXAlignment.Left
	statusText.Parent = statusBar
	
	-- Update status periodically
	task.spawn(function()
		while ZayrosFISHIT and ZayrosFISHIT.Parent do
			local status = "Ready"
			if State.autoFishing then
				status = "Auto Fishing Active"
			end
			
			local sessionTime = tick() - State.fishingStats.sessionStartTime
			statusText.Text = string.format("%s | Session: %s | Fishes: %d | FPS: %.0f", 
				status, 
				Utils.formatTime(sessionTime),
				State.fishingStats.totalFishes,
				PerformanceMonitor.frameRate
			)
			
			task.wait(1)
		end
	end)
end

-- Initialize additional features
createQuickActionsMenu()
createStatusBar()

-- Final initialization message
task.wait(1) -- Give everything time to load
Utils.showNotification(string.format(
	"🎣 Zayros FISHIT Enhanced v%s Successfully Loaded! 🎣", 
	CONFIG.VERSION
), "success", 5)

Utils.showNotification("New Features: Right-click for quick actions, Enhanced keybinds, Performance monitoring", "info", 8)
