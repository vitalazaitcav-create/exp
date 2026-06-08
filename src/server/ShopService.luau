--!strict
-- ShopService: handles every "spend cash" action the player initiates from the
-- HUD — gacha rolls, base-lock upgrades, and rebirths.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

local ShopService = {}

local DEBOUNCE = 0.4
local lastAction: { [Player]: number } = {}

local function debounced(player: Player): boolean
	local now = os.clock()
	if lastAction[player] and now - lastAction[player] < DEBOUNCE then
		return true
	end
	lastAction[player] = now
	return false
end

local function onRoll(player: Player)
	if debounced(player) then
		return
	end
	local plot = PlotService.getPlotByOwner(player)
	if not plot then
		return
	end

	local cost = GameConfig.Settings.RollCost
	if DataService.getCash(player) < cost then
		Remotes.Notify:FireClient(player, "Not enough cash! Need $" .. cost)
		return
	end

	local freeSlot = PlotService.findFreeSlot(plot)
	if not freeSlot then
		Remotes.Notify:FireClient(player, "Your base is full! Sell a creature (press F) first.")
		return
	end

	DataService.addCash(player, -cost)
	local creature = GameConfig.roll()
	PlotService.placeCreature(plot, freeSlot, creature.name)
	Remotes.Notify:FireClient(player, string.format("You rolled %s [%s]!", creature.name, creature.rarity))
end

local function onLock(player: Player)
	if debounced(player) then
		return
	end
	local plot = PlotService.getPlotByOwner(player)
	if not plot then
		return
	end

	local level = plot.lockLevel
	if level >= GameConfig.Settings.LockMaxLevel then
		Remotes.Notify:FireClient(player, "Your base lock is already maxed!")
		return
	end

	local cost = GameConfig.lockCost(level)
	if DataService.getCash(player) < cost then
		Remotes.Notify:FireClient(player, "Need $" .. cost .. " to upgrade your lock!")
		return
	end

	DataService.addCash(player, -cost)
	PlotService.setLockLevel(plot, level + 1)
	DataService.setLockLevel(player, level + 1)
	Remotes.Notify:FireClient(
		player,
		string.format("🔒 Lock Lv.%d! Steal time +%ds", level + 1, GameConfig.Settings.LockTimeBonus)
	)
end

local function onRebirth(player: Player)
	if debounced(player) then
		return
	end
	local plot = PlotService.getPlotByOwner(player)
	if not plot then
		return
	end

	local rebirths = DataService.getRebirths(player)
	local cost = GameConfig.rebirthCost(rebirths)
	if DataService.getCash(player) < cost then
		Remotes.Notify:FireClient(player, "Need $" .. cost .. " to rebirth!")
		return
	end

	PlotService.clearBase(plot)
	DataService.setCash(player, GameConfig.Settings.StartingCash)
	DataService.addRebirth(player)
	local mult = GameConfig.incomeMultiplier(rebirths + 1)
	Remotes.Notify:FireClient(player, string.format("♻️ Rebirth! Income is now x%.1f", mult))
end

function ShopService.start()
	Remotes.RequestRoll.OnServerEvent:Connect(onRoll)
	Remotes.RequestLock.OnServerEvent:Connect(onLock)
	Remotes.RequestRebirth.OnServerEvent:Connect(onRebirth)
	Players.PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
	end)
end

return ShopService
