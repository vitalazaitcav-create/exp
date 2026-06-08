--!strict
-- StealService: the heart of the game. When a player finishes holding a
-- creature's "Steal" prompt, this validates the attempt and transfers the
-- creature to the thief's base (or sells it if the thief's base is full).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

local StealService = {}

local cooldowns: { [Player]: number } = {}

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	local entry = PlotService.promptToSlot[prompt]
	if not entry then
		return -- not a steal prompt
	end

	local sourcePlot = entry.plot
	if sourcePlot.owner == player then
		Remotes.Notify:FireClient(player, "You can't steal from yourself!")
		return
	end

	local now = os.clock()
	local lastSteal = cooldowns[player]
	if lastSteal and now - lastSteal < GameConfig.Settings.StealCooldown then
		local remaining = math.ceil(GameConfig.Settings.StealCooldown - (now - lastSteal))
		Remotes.Notify:FireClient(player, "Steal on cooldown! (" .. remaining .. "s)")
		return
	end

	local slot = sourcePlot.slots[entry.index]
	if not slot then
		return -- already taken by someone else
	end

	local thiefPlot = PlotService.getPlotByOwner(player)
	if not thiefPlot then
		return
	end

	-- Commit the steal.
	local creatureName = slot.name
	cooldowns[player] = now
	PlotService.removeCreature(sourcePlot, entry.index)
	DataService.addSteal(player)

	local freeSlot = PlotService.findFreeSlot(thiefPlot)
	if freeSlot then
		PlotService.placeCreature(thiefPlot, freeSlot, creatureName)
		Remotes.Notify:FireClient(player, "You stole " .. creatureName .. "!")
	else
		local value = GameConfig.getIncome(creatureName) * GameConfig.Settings.SellMultiplier
		DataService.addCash(player, value)
		Remotes.Notify:FireClient(
			player,
			string.format("Base full — sold %s for $%d!", creatureName, value)
		)
	end

	if sourcePlot.owner then
		Remotes.Notify:FireClient(
			sourcePlot.owner,
			string.format("%s stole your %s!", player.Name, creatureName)
		)
	end
end

function StealService.start()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)
end

return StealService
