--!strict
-- ShopService: handles gacha rolls. Validates cash + free space, charges the
-- player, rolls a creature and places it on their base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

local ShopService = {}

local ROLL_COST = GameConfig.Settings.RollCost
local ROLL_DEBOUNCE = 0.4
local lastRoll: { [Player]: number } = {}

local function onRoll(player: Player)
	-- Anti-spam debounce so a held mouse can't fire dozens of rolls a frame.
	local now = os.clock()
	if lastRoll[player] and now - lastRoll[player] < ROLL_DEBOUNCE then
		return
	end
	lastRoll[player] = now

	local plot = PlotService.getPlotByOwner(player)
	if not plot then
		return
	end

	if DataService.getCash(player) < ROLL_COST then
		Remotes.Notify:FireClient(player, "Not enough cash! Need $" .. ROLL_COST)
		return
	end

	local freeSlot = PlotService.findFreeSlot(plot)
	if not freeSlot then
		Remotes.Notify:FireClient(player, "Your base is full! Sell or lose a creature first.")
		return
	end

	DataService.addCash(player, -ROLL_COST)
	local creature = GameConfig.roll()
	PlotService.placeCreature(plot, freeSlot, creature.name)
	Remotes.Notify:FireClient(
		player,
		string.format("You rolled %s [%s]!", creature.name, creature.rarity)
	)
end

function ShopService.start()
	Remotes.RequestRoll.OnServerEvent:Connect(onRoll)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastRoll[player] = nil
	end)
end

return ShopService
