--!strict
-- MonetizationService: game passes + developer products.
--
-- IDs live in GameConfig.Monetization. Until you create the passes/products in
-- the Creator Dashboard and paste their IDs there, everything degrades
-- gracefully (the VIP button just says "coming soon").

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local MonetizationService = {}

local ownsVIP: { [Player]: boolean } = {}

local function refreshVIP(player: Player)
	local id = GameConfig.Monetization.GamePasses.VIP
	if not id or id == 0 then
		ownsVIP[player] = false
		return
	end
	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
	end)
	ownsVIP[player] = ok and result or false
end

-- Income multiplier from purchases (VIP doubles income).
function MonetizationService.getIncomeBonus(player: Player): number
	return ownsVIP[player] and 2 or 1
end

local function onPrompt(player: Player, key: string)
	local id = GameConfig.Monetization.GamePasses[key]
	if not id or id == 0 then
		Remotes.Notify:FireClient(player, "Shop coming soon! (owner must set the Game Pass ID)")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, id)
end

function MonetizationService.start()
	for _, player in Players:GetPlayers() do
		task.spawn(refreshVIP, player)
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(refreshVIP, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		ownsVIP[player] = nil
	end)

	Remotes.PromptPurchase.OnServerEvent:Connect(onPrompt)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased and passId == GameConfig.Monetization.GamePasses.VIP then
			ownsVIP[player] = true
			Remotes.Notify:FireClient(player, "💎 VIP active — x2 income!")
		end
	end)

	-- Developer products grant cash.
	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local amount = GameConfig.Monetization.ProductCash[receipt.ProductId]
		if not amount then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		DataService.addCash(player, amount)
		Remotes.Notify:FireClient(player, string.format("💰 +$%d added!", amount))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return MonetizationService
