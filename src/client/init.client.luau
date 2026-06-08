--!strict
-- Client HUD for Yoink Empire: cash counter, a big ROLL button, and a
-- toast feed for steal/roll notifications from the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ACCENT = Color3.fromRGB(255, 196, 0)
local DARK = Color3.fromRGB(28, 28, 36)

local gui = Instance.new("ScreenGui")
gui.Name = "YoinkHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(parent: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

-- ---- Cash counter (top-left) ----------------------------------------------
local cashFrame = Instance.new("Frame")
cashFrame.Size = UDim2.fromOffset(220, 64)
cashFrame.Position = UDim2.new(0, 16, 0, 16)
cashFrame.BackgroundColor3 = DARK
cashFrame.BackgroundTransparency = 0.1
cashFrame.Parent = gui
corner(cashFrame, 12)

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.fromScale(1, 1)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.FredokaOne
cashLabel.TextColor3 = ACCENT
cashLabel.TextScaled = true
cashLabel.Text = "$0"
cashLabel.Parent = cashFrame

local cashPadding = Instance.new("UIPadding")
cashPadding.PaddingLeft = UDim.new(0, 16)
cashPadding.PaddingRight = UDim.new(0, 16)
cashPadding.PaddingTop = UDim.new(0, 10)
cashPadding.PaddingBottom = UDim.new(0, 10)
cashPadding.Parent = cashLabel

-- ---- Roll button (bottom-center) ------------------------------------------
local rollButton = Instance.new("TextButton")
rollButton.Size = UDim2.fromOffset(260, 70)
rollButton.AnchorPoint = Vector2.new(0.5, 1)
rollButton.Position = UDim2.new(0.5, 0, 1, -28)
rollButton.BackgroundColor3 = ACCENT
rollButton.Font = Enum.Font.FredokaOne
rollButton.TextColor3 = DARK
rollButton.TextScaled = true
rollButton.Text = string.format("🎲 ROLL ($%d)", GameConfig.Settings.RollCost)
rollButton.AutoButtonColor = true
rollButton.Parent = gui
corner(rollButton, 16)

local rollPadding = Instance.new("UIPadding")
rollPadding.PaddingTop = UDim.new(0, 12)
rollPadding.PaddingBottom = UDim.new(0, 12)
rollPadding.PaddingLeft = UDim.new(0, 16)
rollPadding.PaddingRight = UDim.new(0, 16)
rollPadding.Parent = rollButton

rollButton.MouseButton1Click:Connect(function()
	Remotes.RequestRoll:FireServer()
end)

-- ---- Toast feed (top-center) ----------------------------------------------
local toastHolder = Instance.new("Frame")
toastHolder.Size = UDim2.fromOffset(420, 300)
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Position = UDim2.new(0.5, 0, 0, 16)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = gui

local toastLayout = Instance.new("UIListLayout")
toastLayout.FillDirection = Enum.FillDirection.Vertical
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Top
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastHolder

local function showToast(message: string)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.fromOffset(420, 44)
	toast.BackgroundColor3 = DARK
	toast.BackgroundTransparency = 0.15
	toast.Font = Enum.Font.FredokaOne
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.TextScaled = true
	toast.Text = message
	toast.Parent = toastHolder
	corner(toast, 10)

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = toast

	task.delay(3, function()
		local fade = TweenService:Create(
			toast,
			TweenInfo.new(0.5),
			{ BackgroundTransparency = 1, TextTransparency = 1 }
		)
		fade:Play()
		fade.Completed:Wait()
		toast:Destroy()
	end)
end

Remotes.Notify.OnClientEvent:Connect(showToast)

-- ---- Bind cash leaderstat -------------------------------------------------
local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash") :: IntValue

local function updateCash()
	cashLabel.Text = "$" .. cash.Value
end

updateCash()
cash.Changed:Connect(updateCash)

print("[YoinkEmpire] Client HUD ready ✨")
