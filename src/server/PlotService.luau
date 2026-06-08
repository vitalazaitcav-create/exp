--!strict
-- PlotService: builds the bases, assigns one to each player, owns the creature
-- stands, and is the single source of truth for "what creature sits on which
-- slot of which plot". Also tracks each plot's lock level (steal defense) and
-- keeps the player's saved base list in sync with DataService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataService = require(script.Parent.DataService)

local PlotService = {}

type Slot = false | {
	name: string,
	model: Model,
	prompt: ProximityPrompt,
	sellPrompt: ProximityPrompt,
}
type Plot = {
	index: number,
	owner: Player?,
	base: Part,
	label: TextLabel,
	spawnCFrame: CFrame,
	stands: { Part },
	slots: { Slot },
	lockLevel: number,
}

local PLOT_COUNT = 6
local PLOT_SPACING = 70
local PLOT_SIZE = 40
local STAND_COLUMNS = 3

local plots: { Plot } = {}
local byOwner: { [Player]: Plot } = {}
-- Lets StealService map a triggered prompt back to its slot + action kind.
PlotService.promptToSlot = {} :: { [ProximityPrompt]: { plot: Plot, index: number, kind: string } }

local plotsFolder: Folder

-- Effective seconds to steal from this plot, including lock defense.
local function stealTime(plot: Plot): number
	return GameConfig.Settings.BaseStealTime + plot.lockLevel * GameConfig.Settings.LockTimeBonus
end

-- Pushes the plot's current creature list into the owner's saved data.
local function syncProfile(plot: Plot)
	if not plot.owner then
		return
	end
	local list = {}
	for index = 1, GameConfig.Settings.PlotSlots do
		local slot = plot.slots[index]
		if slot then
			table.insert(list, slot.name)
		end
	end
	DataService.setCreatures(plot.owner, list)
end
PlotService.syncProfile = syncProfile

local function createStand(base: Part, origin: Vector3, slotIndex: number): Part
	local column = (slotIndex - 1) % STAND_COLUMNS
	local row = math.floor((slotIndex - 1) / STAND_COLUMNS)

	local stand = Instance.new("Part")
	stand.Name = "Stand" .. slotIndex
	stand.Size = Vector3.new(4, 2, 4)
	stand.Anchored = true
	stand.Material = Enum.Material.Metal
	stand.Color = Color3.fromRGB(40, 40, 50)
	stand.Position = origin + Vector3.new((column - 1) * 10, 2, (row == 0 and -8 or 8))
	stand.Parent = base
	return stand
end

local function createPlot(index: number)
	local origin = Vector3.new(
		(index - 1) * PLOT_SPACING - ((PLOT_COUNT - 1) * PLOT_SPACING) / 2,
		0,
		0
	)

	local base = Instance.new("Part")
	base.Name = "PlotBase" .. index
	base.Size = Vector3.new(PLOT_SIZE, 1, PLOT_SIZE)
	base.Position = origin + Vector3.new(0, 0.5, 0)
	base.Anchored = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(60, 60, 72)
	base.Parent = plotsFolder

	local signPart = Instance.new("Part")
	signPart.Name = "Sign"
	signPart.Size = Vector3.new(1, 1, 1)
	signPart.Transparency = 1
	signPart.CanCollide = false
	signPart.Anchored = true
	signPart.Position = origin + Vector3.new(0, 10, -18)
	signPart.Parent = base

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(10, 2.5)
	billboard.AlwaysOnTop = true
	billboard.Parent = signPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = "Empty Plot"
	label.Parent = billboard

	local plot: Plot = {
		index = index,
		owner = nil,
		base = base,
		label = label,
		spawnCFrame = CFrame.new(origin + Vector3.new(0, 5, 14)),
		stands = {},
		slots = {},
		lockLevel = 0,
	}

	for slotIndex = 1, GameConfig.Settings.PlotSlots do
		plot.stands[slotIndex] = createStand(base, origin, slotIndex)
		plot.slots[slotIndex] = false
	end

	plots[index] = plot
end

function PlotService.findFreeSlot(plot: Plot): number?
	for index = 1, GameConfig.Settings.PlotSlots do
		if not plot.slots[index] then
			return index
		end
	end
	return nil
end

function PlotService.getPlotByOwner(player: Player): Plot?
	return byOwner[player]
end

function PlotService.placeCreature(plot: Plot, slotIndex: number, name: string)
	local creature = GameConfig.getCreature(name)
	if not creature then
		return
	end
	local rarity = GameConfig.Rarities[creature.rarity]
	local stand = plot.stands[slotIndex]

	local model = Instance.new("Model")
	model.Name = name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3, 3)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.Neon
	body.Color = rarity.color
	body.CFrame = stand.CFrame * CFrame.new(0, 3, 0)
	body.Parent = model
	model.PrimaryPart = body

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(6, 2)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = rarity.color
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Text = string.format("%s\n[%s]", name, creature.rarity)
	nameLabel.Parent = billboard

	-- Thieves hold this to steal.
	local stealPrompt = Instance.new("ProximityPrompt")
	stealPrompt.ActionText = "Steal"
	stealPrompt.ObjectText = name
	stealPrompt.HoldDuration = stealTime(plot)
	stealPrompt.KeyboardKeyCode = Enum.KeyCode.E
	stealPrompt.RequiresLineOfSight = false
	stealPrompt.MaxActivationDistance = 10
	stealPrompt.Parent = body

	-- The owner presses this to sell.
	local sellPrompt = Instance.new("ProximityPrompt")
	sellPrompt.ActionText = "Sell"
	sellPrompt.ObjectText = name
	sellPrompt.HoldDuration = 0
	sellPrompt.KeyboardKeyCode = Enum.KeyCode.F
	sellPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	sellPrompt.RequiresLineOfSight = false
	sellPrompt.MaxActivationDistance = 10
	sellPrompt.Parent = body

	model.Parent = plot.base

	plot.slots[slotIndex] = { name = name, model = model, prompt = stealPrompt, sellPrompt = sellPrompt }
	PlotService.promptToSlot[stealPrompt] = { plot = plot, index = slotIndex, kind = "steal" }
	PlotService.promptToSlot[sellPrompt] = { plot = plot, index = slotIndex, kind = "sell" }

	syncProfile(plot)
end

function PlotService.removeCreature(plot: Plot, slotIndex: number)
	local slot = plot.slots[slotIndex]
	if not slot then
		return
	end
	PlotService.promptToSlot[slot.prompt] = nil
	PlotService.promptToSlot[slot.sellPrompt] = nil
	slot.model:Destroy()
	plot.slots[slotIndex] = false
	syncProfile(plot)
end

function PlotService.clearBase(plot: Plot)
	for index = 1, GameConfig.Settings.PlotSlots do
		PlotService.removeCreature(plot, index)
	end
end

-- Raises the plot's lock level and re-tunes every existing steal prompt.
function PlotService.setLockLevel(plot: Plot, level: number)
	plot.lockLevel = level
	local time = stealTime(plot)
	for index = 1, GameConfig.Settings.PlotSlots do
		local slot = plot.slots[index]
		if slot then
			slot.prompt.HoldDuration = time
		end
	end
end

local function assignPlot(player: Player)
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			plot.label.Text = player.Name .. "'s Base"
			byOwner[player] = plot
			return
		end
	end
	warn("[PlotService] No free plot for " .. player.Name)
end

local function freePlot(player: Player)
	local plot = byOwner[player]
	if not plot then
		return
	end
	PlotService.clearBase(plot)
	plot.owner = nil
	plot.lockLevel = 0
	plot.label.Text = "Empty Plot"
	byOwner[player] = nil
end

local function teleportToPlot(player: Player)
	local plot = byOwner[player]
	if not plot then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.CFrame = plot.spawnCFrame
	end
end

local function onPlayerAdded(player: Player)
	assignPlot(player)
	local plot = byOwner[player]

	-- Restore saved lock + creatures once data is loaded.
	task.spawn(function()
		DataService.waitForLoad(player)
		if not plot or byOwner[player] ~= plot then
			return
		end
		PlotService.setLockLevel(plot, DataService.getLockLevel(player))
		for _, name in DataService.getCreatures(player) do
			local free = PlotService.findFreeSlot(plot)
			if free then
				PlotService.placeCreature(plot, free, name)
			end
		end
	end)

	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		task.wait()
		teleportToPlot(player)
	end)
	if player.Character then
		teleportToPlot(player)
	end
end

function PlotService.start()
	plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = workspace

	for index = 1, PLOT_COUNT do
		createPlot(index)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(freePlot)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return PlotService
