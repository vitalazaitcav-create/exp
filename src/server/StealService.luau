--!strict
-- StealService: handles the prompts on creatures. A prompt is either a "steal"
-- (used by rivals) or a "sell" (used by the owner). It routes each triggered
-- prompt to the right handler.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local DisguiseService = require(script.Parent.DisguiseService)

local StealService = {}

local cooldowns: { [Player]: number } = {}

local function handleSell(entry, player: Player)
	local plot = entry.plot
	if plot.owner ~= player then
		Remotes.Notify:FireClient(player, "That's not yours to sell!")
		return
	end
	local slot = plot.slots[entry.index]
	if not slot then
		return
	end
	local name = slot.name
	local value = GameConfig.getIncome(name) * GameConfig.Settings.SellMultiplier
	PlotService.removeCreature(plot, entry.index)
	DataService.addCash(player, value)
	Remotes.Notify:FireClient(player, string.format("Sold %s for $%d!", name, value))
end

local function handleSteal(entry, player: Player)
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

	local creatureName = slot.name
	cooldowns[player] = now
	PlotService.removeCreature(sourcePlot, entry.index)
	DataService.addSteal(player)

	-- Stealing always blows your cover.
	if DisguiseService.isDisguised(player) then
		DisguiseService.undisguise(player)
	end

	local freeSlot = PlotService.findFreeSlot(thiefPlot)
	if freeSlot then
		PlotService.placeCreature(thiefPlot, freeSlot, creatureName)
		Remotes.Notify:FireClient(player, "You stole " .. creatureName .. "!")
	else
		local value = GameConfig.getIncome(creatureName) * GameConfig.Settings.SellMultiplier
		DataService.addCash(player, value)
		Remotes.Notify:FireClient(player, string.format("Base full — sold %s for $%d!", creatureName, value))
	end

	if sourcePlot.owner then
		-- Alarm drives the red flash + siren on the victim's screen.
		Remotes.Alarm:FireClient(sourcePlot.owner, player.Name, creatureName)
	end
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	local entry = PlotService.promptToSlot[prompt]
	if not entry then
		return
	end
	if entry.kind == "sell" then
		handleSell(entry, player)
	else
		handleSteal(entry, player)
	end
end

function StealService.start()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)
end

return StealService
