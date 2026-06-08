--!strict
-- DataService: owns each player's leaderstats (Cash + Steals) and exposes
-- simple helpers so other services never touch the values directly.
-- NOTE: this keeps data in memory only. Hook up DataStoreService here later
-- for persistence between sessions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local DataService = {}
local cache: { [Player]: { cash: IntValue, steals: IntValue } } = {}

function DataService.setup(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = GameConfig.Settings.StartingCash
	cash.Parent = leaderstats

	local steals = Instance.new("IntValue")
	steals.Name = "Steals"
	steals.Value = 0
	steals.Parent = leaderstats

	leaderstats.Parent = player
	cache[player] = { cash = cash, steals = steals }
end

function DataService.cleanup(player: Player)
	cache[player] = nil
end

function DataService.getCash(player: Player): number
	local data = cache[player]
	return data and data.cash.Value or 0
end

function DataService.addCash(player: Player, amount: number)
	local data = cache[player]
	if data then
		data.cash.Value += amount
	end
end

function DataService.addSteal(player: Player)
	local data = cache[player]
	if data then
		data.steals.Value += 1
	end
end

function DataService.start()
	Players.PlayerAdded:Connect(DataService.setup)
	Players.PlayerRemoving:Connect(DataService.cleanup)
	for _, player in Players:GetPlayers() do
		DataService.setup(player)
	end
end

return DataService
