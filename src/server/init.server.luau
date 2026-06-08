--!strict
-- Server bootstrap for Yoink Empire.
--
-- We create the RemoteEvents FIRST so clients never hang waiting for them, then
-- start each service inside a pcall so a single failure can't take down the
-- rest of the game (e.g. plots still build even if saving has an issue).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Creating the Remotes folder up front (server side).
require(ReplicatedStorage.Shared.Remotes)

local startup = {
	{ name = "DataService", module = require(script.DataService) },
	{ name = "MonetizationService", module = require(script.MonetizationService) },
	{ name = "PlotService", module = require(script.PlotService) },
	{ name = "IncomeService", module = require(script.IncomeService) },
	{ name = "ShopService", module = require(script.ShopService) },
	{ name = "DisguiseService", module = require(script.DisguiseService) },
	{ name = "StealService", module = require(script.StealService) },
}

for _, entry in startup do
	local ok, err = pcall(entry.module.start)
	if ok then
		print("[YoinkEmpire] " .. entry.name .. " started")
	else
		warn("[YoinkEmpire] " .. entry.name .. " FAILED: " .. tostring(err))
	end
end

print("[YoinkEmpire] Server boot complete 🎮")
