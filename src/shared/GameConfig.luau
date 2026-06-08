--!strict
-- GameConfig: central tuning for Yoink Empire.
-- Designers can edit numbers here without touching gameplay code.

local GameConfig = {}

GameConfig.Settings = {
	PlotSlots = 6, -- how many creatures a base can hold
	StartingCash = 100, -- cash a new player spawns with
	IncomeInterval = 1, -- seconds between income ticks
	BaseStealTime = 6, -- seconds a thief must hold to steal a creature
	StealCooldown = 8, -- seconds before a player can steal again
	RollCost = 50, -- cash to roll one creature from the gacha
	SellMultiplier = 25, -- sell value = creature income * this

	-- Base defense (locks): each level adds steal time, cost grows per level.
	LockCostBase = 200,
	LockCostScale = 1.8,
	LockTimeBonus = 2, -- extra seconds to steal, per lock level
	LockMaxLevel = 5,

	-- Rebirth: reset progress for a permanent income multiplier.
	RebirthBaseCost = 5000,
	RebirthCostScale = 2.5,
	RebirthMultPerLevel = 0.5, -- income x = 1 + rebirths * this

	-- Disguise (our signature mechanic): sneak onto bases as a crate.
	DisguiseWalkSpeed = 10,
	DisguiseDuration = 20, -- auto-reveal after this many seconds
	DisguiseCooldown = 12,

	AutosaveInterval = 60, -- seconds between background saves
}

-- Rarity table. `weight` drives the gacha odds, `mult` is cash/second the creature earns.
GameConfig.Rarities = {
	Common = { color = Color3.fromRGB(205, 205, 215), weight = 100, mult = 1 },
	Uncommon = { color = Color3.fromRGB(120, 220, 130), weight = 45, mult = 3 },
	Rare = { color = Color3.fromRGB(80, 150, 255), weight = 18, mult = 8 },
	Epic = { color = Color3.fromRGB(190, 90, 255), weight = 7, mult = 20 },
	Legendary = { color = Color3.fromRGB(255, 180, 40), weight = 2.5, mult = 55 },
	Mythic = { color = Color3.fromRGB(255, 70, 90), weight = 0.7, mult = 140 },
	Secret = { color = Color3.fromRGB(25, 25, 30), weight = 0.1, mult = 400 },
}

-- Our own original roster of goofy meme creatures (no third-party trademarks).
GameConfig.Creatures = {
	{ name = "Derp Duck", rarity = "Common" },
	{ name = "Soggy Toast", rarity = "Common" },
	{ name = "Confused Pigeon", rarity = "Common" },
	{ name = "Mr. Potato Guy", rarity = "Common" },
	{ name = "Buff Shrimp", rarity = "Uncommon" },
	{ name = "Disco Snail", rarity = "Uncommon" },
	{ name = "Karate Carrot", rarity = "Uncommon" },
	{ name = "Turbo Raccoon", rarity = "Rare" },
	{ name = "Ninja Avocado", rarity = "Rare" },
	{ name = "Cyber Llama", rarity = "Rare" },
	{ name = "Galaxy Goose", rarity = "Epic" },
	{ name = "Lava Llama", rarity = "Epic" },
	{ name = "Mega Yapper", rarity = "Legendary" },
	{ name = "Golden Gigafrog", rarity = "Legendary" },
	{ name = "Cosmic Capybara", rarity = "Mythic" },
	{ name = "The Glorptron 9000", rarity = "Secret" },
}

-- Pre-built lookups so runtime code stays O(1).
local byName = {}
local byRarity = {}
for _, creature in GameConfig.Creatures do
	byName[creature.name] = creature
	byRarity[creature.rarity] = byRarity[creature.rarity] or {}
	table.insert(byRarity[creature.rarity], creature)
end

-- Returns the creature definition for a name, or nil.
function GameConfig.getCreature(name: string)
	return byName[name]
end

-- Cash-per-tick a given creature produces.
function GameConfig.getIncome(name: string): number
	local creature = byName[name]
	if not creature then
		return 0
	end
	return GameConfig.Rarities[creature.rarity].mult
end

-- Weighted gacha roll: pick a rarity by weight, then a random creature of that rarity.
function GameConfig.roll()
	local total = 0
	for rarity, data in GameConfig.Rarities do
		if byRarity[rarity] then
			total += data.weight
		end
	end

	local pick = math.random() * total
	local chosenRarity = "Common"
	for rarity, data in GameConfig.Rarities do
		if byRarity[rarity] then
			pick -= data.weight
			if pick <= 0 then
				chosenRarity = rarity
				break
			end
		end
	end

	local list = byRarity[chosenRarity]
	return list[math.random(1, #list)]
end

-- Cost of the next lock level given the current level.
function GameConfig.lockCost(level: number): number
	return math.floor(GameConfig.Settings.LockCostBase * GameConfig.Settings.LockCostScale ^ level)
end

-- Cost of the next rebirth given how many the player already has.
function GameConfig.rebirthCost(rebirths: number): number
	return math.floor(GameConfig.Settings.RebirthBaseCost * GameConfig.Settings.RebirthCostScale ^ rebirths)
end

-- Income multiplier granted by rebirths.
function GameConfig.incomeMultiplier(rebirths: number): number
	return 1 + rebirths * GameConfig.Settings.RebirthMultPerLevel
end

return GameConfig
