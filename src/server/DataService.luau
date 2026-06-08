--!strict
-- DataService: owns each player's profile (leaderstats + saved base) and
-- persists it to a DataStore. Other services read/write through the helpers
-- here and never touch values directly.
--
-- IMPORTANT: DataStore only works in Studio if "Game Settings -> Security ->
-- Enable Studio Access to API Services" is ON, and best on a published place.
-- If it's off, saves silently fail (caught below) and the game still runs
-- with in-session-only data.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local DataService = {}

local store = DataStoreService:GetDataStore("YoinkEmpire_v1")

type State = {
	cash: IntValue,
	steals: IntValue,
	rebirths: IntValue,
	creatures: { string },
	lockLevel: number,
	loaded: boolean,
}

local state: { [Player]: State } = {}

local function defaultData()
	return {
		cash = GameConfig.Settings.StartingCash,
		steals = 0,
		rebirths = 0,
		lockLevel = 0,
		creatures = {},
	}
end

local function load(player: Player)
	local key = "Player_" .. player.UserId
	local data
	local ok, err = pcall(function()
		data = store:GetAsync(key)
	end)
	if not ok then
		warn("[DataService] load failed for " .. player.Name .. ": " .. tostring(err))
	end

	data = data or defaultData()
	data.cash = data.cash or GameConfig.Settings.StartingCash
	data.steals = data.steals or 0
	data.rebirths = data.rebirths or 0
	data.lockLevel = data.lockLevel or 0
	data.creatures = data.creatures or {}

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data.cash
	cash.Parent = leaderstats

	local steals = Instance.new("IntValue")
	steals.Name = "Steals"
	steals.Value = data.steals
	steals.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = data.rebirths
	rebirths.Parent = leaderstats

	leaderstats.Parent = player

	state[player] = {
		cash = cash,
		steals = steals,
		rebirths = rebirths,
		creatures = data.creatures,
		lockLevel = data.lockLevel,
		loaded = true,
	}
end

local function save(player: Player)
	local s = state[player]
	if not s then
		return
	end
	local data = {
		cash = s.cash.Value,
		steals = s.steals.Value,
		rebirths = s.rebirths.Value,
		lockLevel = s.lockLevel,
		creatures = s.creatures,
	}
	local ok, err = pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)
	if not ok then
		warn("[DataService] save failed for " .. player.Name .. ": " .. tostring(err))
	end
end
DataService.save = save

-- Yields until the player's profile is loaded (or they leave / time out).
function DataService.waitForLoad(player: Player): boolean
	local elapsed = 0
	while (not state[player] or not state[player].loaded) and player.Parent and elapsed < 10 do
		task.wait(0.1)
		elapsed += 0.1
	end
	return state[player] ~= nil
end

function DataService.getCash(player: Player): number
	local s = state[player]
	return s and s.cash.Value or 0
end

function DataService.addCash(player: Player, amount: number)
	local s = state[player]
	if s then
		s.cash.Value += amount
	end
end

function DataService.setCash(player: Player, value: number)
	local s = state[player]
	if s then
		s.cash.Value = value
	end
end

function DataService.addSteal(player: Player)
	local s = state[player]
	if s then
		s.steals.Value += 1
	end
end

function DataService.getRebirths(player: Player): number
	local s = state[player]
	return s and s.rebirths.Value or 0
end

function DataService.addRebirth(player: Player)
	local s = state[player]
	if s then
		s.rebirths.Value += 1
	end
end

function DataService.getIncomeMultiplier(player: Player): number
	return GameConfig.incomeMultiplier(DataService.getRebirths(player))
end

function DataService.getCreatures(player: Player): { string }
	local s = state[player]
	return s and s.creatures or {}
end

function DataService.setCreatures(player: Player, list: { string })
	local s = state[player]
	if s then
		s.creatures = list
	end
end

function DataService.getLockLevel(player: Player): number
	local s = state[player]
	return s and s.lockLevel or 0
end

function DataService.setLockLevel(player: Player, level: number)
	local s = state[player]
	if s then
		s.lockLevel = level
	end
end

function DataService.start()
	Players.PlayerAdded:Connect(load)
	Players.PlayerRemoving:Connect(function(player)
		save(player)
		state[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			save(player)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(GameConfig.Settings.AutosaveInterval)
			for _, player in Players:GetPlayers() do
				save(player)
			end
		end
	end)
end

return DataService
