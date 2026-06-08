--!strict
-- PlotService: builds the bases, assigns one to each player, and owns the
-- creature stands. It is the single source of truth for "what creature sits
-- on which slot of which plot", which ShopService/StealService/IncomeService
-- all read from.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PlotService = {}

type Slot = false | { name: string, model: Model, prompt: ProximityPrompt }
type Plot = {
	index: number,
	owner: Player?,
	base: Part,
	label: TextLabel,
	spawnCFrame: CFrame,
	stands: { Part },
	slots: { Slot },
}

local PLOT_COUNT = 6
local PLOT_SPACING = 70
local PLOT_SIZE = 40
local STAND_COLUMNS = 3

local plots: { Plot } = {}
local byOwner: { [Player]: Plot } = {}
-- Lets StealService map a triggered prompt back to its slot.
PlotService.promptToSlot = {} :: { [ProximityPrompt]: { plot: Plot, index: number } }

local plotsFolder: Folder

local function createStand(plot: Plot, base: Part, origin: Vector3, slotIndex: number): Part
	local column = (slotIndex - 1) % STAND_COLUMNS
	local row = math.floor((slotIndex - 1) / STAND_COLUMNS)

	local stand = Instance.new("Part")
	stand.Name = "Stand" .. slotIndex
	stand.Size = Vector3.new(4, 2, 4)
	stand.Anchored = true
	stand.Material = Enum.Material.Metal
	stand.Color = Color3.fromRGB(40, 40, 50)
	stand.Position = origin
		+ Vector3.new((column - 1) * 10, 2, (row == 0 and -8 or 8))
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

	-- Floating name sign over the base.
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
	}

	for slotIndex = 1, GameConfig.Settings.PlotSlots do
		plot.stands[slotIndex] = createStand(plot, base, origin, slotIndex)
		plot.slots[slotIndex] = false
	end

	plots[index] = plot
end

-- Returns the first empty slot index of a plot, or nil if full.
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

-- Spawns a creature model on a stand and wires its steal prompt.
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

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal"
	prompt.ObjectText = name
	prompt.HoldDuration = GameConfig.Settings.BaseStealTime
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = body

	model.Parent = plot.base

	plot.slots[slotIndex] = { name = name, model = model, prompt = prompt }
	PlotService.promptToSlot[prompt] = { plot = plot, index = slotIndex }
end

-- Removes whatever creature is on a slot (used by selling/stealing/leaving).
function PlotService.removeCreature(plot: Plot, slotIndex: number)
	local slot = plot.slots[slotIndex]
	if not slot then
		return
	end
	PlotService.promptToSlot[slot.prompt] = nil
	slot.model:Destroy()
	plot.slots[slotIndex] = false
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
	for index = 1, GameConfig.Settings.PlotSlots do
		PlotService.removeCreature(plot, index)
	end
	plot.owner = nil
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
	player.CharacterAdded:Connect(function(character)
		-- Wait until the root part exists before teleporting.
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
