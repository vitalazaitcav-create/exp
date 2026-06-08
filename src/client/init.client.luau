--!strict
-- Client HUD for Yoink Empire: cash counter + rebirth multiplier, a ROLL
-- button, a right-side action stack (Lock / Rebirth / Disguise), a sell hint,
-- and a toast feed for server notifications.

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

local function pad(parent: GuiObject, amount: number)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, amount)
	p.PaddingRight = UDim.new(0, amount)
	p.PaddingTop = UDim.new(0, amount)
	p.PaddingBottom = UDim.new(0, amount)
	p.Parent = parent
end

-- ---- Cash + rebirth multiplier (top-left) ---------------------------------
local statFrame = Instance.new("Frame")
statFrame.Size = UDim2.fromOffset(220, 96)
statFrame.Position = UDim2.new(0, 16, 0, 16)
statFrame.BackgroundColor3 = DARK
statFrame.BackgroundTransparency = 0.1
statFrame.Parent = gui
corner(statFrame, 12)

local statLayout = Instance.new("UIListLayout")
statLayout.FillDirection = Enum.FillDirection.Vertical
statLayout.Padding = UDim.new(0, 2)
statLayout.Parent = statFrame
pad(statFrame, 10)

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(1, 0, 0, 44)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.FredokaOne
cashLabel.TextColor3 = ACCENT
cashLabel.TextScaled = true
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Text = "$0"
cashLabel.Parent = statFrame

local multLabel = Instance.new("TextLabel")
multLabel.Size = UDim2.new(1, 0, 0, 26)
multLabel.BackgroundTransparency = 1
multLabel.Font = Enum.Font.FredokaOne
multLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
multLabel.TextScaled = true
multLabel.TextXAlignment = Enum.TextXAlignment.Left
multLabel.Text = "♻️ x1.0 income"
multLabel.Parent = statFrame

-- ---- ROLL button (bottom-center) ------------------------------------------
local rollButton = Instance.new("TextButton")
rollButton.Size = UDim2.fromOffset(260, 70)
rollButton.AnchorPoint = Vector2.new(0.5, 1)
rollButton.Position = UDim2.new(0.5, 0, 1, -52)
rollButton.BackgroundColor3 = ACCENT
rollButton.Font = Enum.Font.FredokaOne
rollButton.TextColor3 = DARK
rollButton.TextScaled = true
rollButton.Text = string.format("🎲 ROLL ($%d)", GameConfig.Settings.RollCost)
rollButton.Parent = gui
corner(rollButton, 16)
pad(rollButton, 12)
rollButton.MouseButton1Click:Connect(function()
	Remotes.RequestRoll:FireServer()
end)

-- ---- Sell hint (under the ROLL button) ------------------------------------
local hint = Instance.new("TextLabel")
hint.Size = UDim2.fromOffset(360, 24)
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -20)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextColor3 = Color3.fromRGB(220, 220, 230)
hint.TextScaled = true
hint.Text = "Hold E on a rival's creature to STEAL · Press F on yours to SELL"
hint.Parent = gui

-- ---- Action stack (right side): Lock / Rebirth / Disguise -----------------
local actionStack = Instance.new("Frame")
actionStack.Size = UDim2.fromOffset(180, 180)
actionStack.AnchorPoint = Vector2.new(1, 0.5)
actionStack.Position = UDim2.new(1, -16, 0.5, 0)
actionStack.BackgroundTransparency = 1
actionStack.Parent = gui

local stackLayout = Instance.new("UIListLayout")
stackLayout.FillDirection = Enum.FillDirection.Vertical
stackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
stackLayout.Padding = UDim.new(0, 8)
stackLayout.Parent = actionStack

local function makeAction(text: string, color: Color3, onClick: () -> ())
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(180, 50)
	button.BackgroundColor3 = color
	button.Font = Enum.Font.FredokaOne
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Text = text
	button.Parent = actionStack
	corner(button, 12)
	pad(button, 10)
	button.MouseButton1Click:Connect(onClick)
	return button
end

makeAction("🔒 Buy Lock", Color3.fromRGB(70, 130, 220), function()
	Remotes.RequestLock:FireServer()
end)
makeAction("♻️ Rebirth", Color3.fromRGB(150, 90, 220), function()
	Remotes.RequestRebirth:FireServer()
end)
makeAction("🥷 Disguise", Color3.fromRGB(60, 70, 90), function()
	Remotes.ToggleDisguise:FireServer()
end)

-- ---- Toast feed (top-center) ----------------------------------------------
local toastHolder = Instance.new("Frame")
toastHolder.Size = UDim2.fromOffset(440, 300)
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Position = UDim2.new(0.5, 0, 0, 16)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = gui

local toastLayout = Instance.new("UIListLayout")
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastHolder

local function showToast(message: string)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.fromOffset(440, 44)
	toast.BackgroundColor3 = DARK
	toast.BackgroundTransparency = 0.15
	toast.Font = Enum.Font.FredokaOne
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.TextScaled = true
	toast.Text = message
	toast.Parent = toastHolder
	corner(toast, 10)
	pad(toast, 8)

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

-- ---- Bind leaderstats -----------------------------------------------------
local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash") :: IntValue
local rebirths = leaderstats:WaitForChild("Rebirths") :: IntValue

local function updateCash()
	cashLabel.Text = "$" .. cash.Value
end

local function updateMult()
	multLabel.Text = string.format("♻️ x%.1f income", GameConfig.incomeMultiplier(rebirths.Value))
end

updateCash()
updateMult()
cash.Changed:Connect(updateCash)
rebirths.Changed:Connect(updateMult)

-- ---- Show the right prompt per creature -----------------------------------
-- Each creature carries an "OwnerUserId" attribute. We show the owner only the
-- Sell prompt and everyone else only the Steal prompt, so the two never overlap.
local Workspace = game:GetService("Workspace")

local function bindPrompt(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	local model = prompt:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end

	local function apply()
		local ownerId = model:GetAttribute("OwnerUserId")
		if ownerId == nil then
			return
		end
		local isOwner = ownerId == player.UserId
		if prompt.ActionText == "Sell" then
			prompt.Enabled = isOwner
		else
			prompt.Enabled = not isOwner
		end
	end

	apply()
	model:GetAttributeChangedSignal("OwnerUserId"):Connect(apply)
end

for _, descendant in Workspace:GetDescendants() do
	bindPrompt(descendant)
end
Workspace.DescendantAdded:Connect(bindPrompt)

print("[YoinkEmpire] Client HUD ready ✨")
