--!strict
-- Server bootstrap for Yoink Empire. Order matters: DataService sets up
-- leaderstats first so plot assignment and income have data to work with.

local DataService = require(script.DataService)
local PlotService = require(script.PlotService)
local IncomeService = require(script.IncomeService)
local ShopService = require(script.ShopService)
local StealService = require(script.StealService)

DataService.start()
PlotService.start()
IncomeService.start()
ShopService.start()
StealService.start()

print("[YoinkEmpire] Server started 🎮")
