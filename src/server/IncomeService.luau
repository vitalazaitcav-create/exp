--!strict
-- IncomeService: every tick, pays each player the summed income of all
-- creatures currently sitting on their base.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

local IncomeService = {}

function IncomeService.start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.Settings.IncomeInterval)
			for _, player in Players:GetPlayers() do
				local plot = PlotService.getPlotByOwner(player)
				if plot then
					local income = 0
					for _, slot in plot.slots do
						if slot then
							income += GameConfig.getIncome(slot.name)
						end
					end
					if income > 0 then
						local total = math.floor(income * DataService.getIncomeMultiplier(player))
						DataService.addCash(player, total)
					end
				end
			end
		end
	end)
end

return IncomeService
