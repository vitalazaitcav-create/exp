--!strict
-- DisguiseService: our signature mechanic. A player can disguise as a wooden
-- crate to sneak onto rival bases — their character turns invisible, a crate is
-- welded on, their nameplate is hidden, and they move slower. The disguise
-- auto-reveals after a timer, has a cooldown, and breaks the moment they steal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DisguiseService = {}

local disguised: { [Player]: any } = {} -- value is a per-disguise token
local cooldowns: { [Player]: number } = {}

local DEFAULT_WALKSPEED = 16

local function applyDisguise(player: Player, on: boolean)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return
	end

	if on then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.WalkSpeed = GameConfig.Settings.DisguiseWalkSpeed
		for _, d in character:GetDescendants() do
			if (d:IsA("BasePart") and d ~= root) or d:IsA("Decal") then
				d:SetAttribute("YoinkOrigTransparency", d.Transparency)
				d.Transparency = 1
			end
		end

		local crate = Instance.new("Part")
		crate.Name = "YoinkDisguise"
		crate.Size = Vector3.new(4, 4, 4)
		crate.Color = Color3.fromRGB(150, 100, 60)
		crate.Material = Enum.Material.WoodPlanks
		crate.CanCollide = false
		crate.Massless = true
		crate.CFrame = root.CFrame
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = crate
		weld.Parent = crate
		crate.Parent = character
	else
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
		humanoid.WalkSpeed = DEFAULT_WALKSPEED
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				local orig = d:GetAttribute("YoinkOrigTransparency")
				if orig ~= nil then
					d.Transparency = orig :: number
					d:SetAttribute("YoinkOrigTransparency", nil)
				end
			end
		end
		local crate = character:FindFirstChild("YoinkDisguise")
		if crate then
			crate:Destroy()
		end
	end
end

function DisguiseService.isDisguised(player: Player): boolean
	return disguised[player] ~= nil
end

function DisguiseService.undisguise(player: Player)
	if not disguised[player] then
		return
	end
	disguised[player] = nil
	applyDisguise(player, false)
end

local function disguise(player: Player)
	local now = os.clock()
	if cooldowns[player] and now - cooldowns[player] < GameConfig.Settings.DisguiseCooldown then
		local remaining = math.ceil(GameConfig.Settings.DisguiseCooldown - (now - cooldowns[player]))
		Remotes.Notify:FireClient(player, "Disguise on cooldown! (" .. remaining .. "s)")
		return
	end

	local token = {}
	disguised[player] = token
	cooldowns[player] = now
	applyDisguise(player, true)
	Remotes.Notify:FireClient(player, "🥷 Disguised as a crate! Sneak onto a base...")

	task.delay(GameConfig.Settings.DisguiseDuration, function()
		if disguised[player] == token then
			DisguiseService.undisguise(player)
			Remotes.Notify:FireClient(player, "Your disguise wore off!")
		end
	end)
end

local function onToggle(player: Player)
	if disguised[player] then
		DisguiseService.undisguise(player)
	else
		disguise(player)
	end
end

function DisguiseService.start()
	Remotes.ToggleDisguise.OnServerEvent:Connect(onToggle)
	Players.PlayerRemoving:Connect(function(player)
		disguised[player] = nil
		cooldowns[player] = nil
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterRemoving:Connect(function()
			disguised[player] = nil
		end)
	end)
end

return DisguiseService
