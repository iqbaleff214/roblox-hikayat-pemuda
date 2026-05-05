-- ModuleScript: ServerScriptService/Server/Services/ShopService
-- Handles buying from and selling to NPC shops.
-- PurchaseItem / SellItem are RemoteFunctions (client gets return values).
-- RequestOpenShop fires from client; OpenShop fires back to client with stock data.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)
local ItemModule  = require(ReplicatedStorage:WaitForChild("Shared").Modules.ItemModule)

local PENJAHAT_THRESHOLD = 20   -- morality below this → NPCs refuse to buy from player
local LUCKY_SELL_CHANCE  = 0.03 -- 3% chance on sell
local LUCKY_SELL_MULT    = 1.2  -- 20% bonus price on lucky sell

local ShopService = Knit.CreateService {
	Name   = "ShopService",
	Client = {
		RequestOpenShop = Knit.CreateSignal(), -- client → server: (shopId)
		OpenShop        = Knit.CreateSignal(), -- server → client: (shopId, stockData)
	},

	_dataService      = nil,
	_inventoryService = nil,
	_currencyService  = nil,
}

-- ── Private helpers ───────────────────────────────────────────────

-- Buy price after optional morality discount.
local function getBuyPrice(shopCfg, itemCfg, morality)
	local price = itemCfg.basePrice
	local disc   = shopCfg.moralityDiscount
	if disc and morality >= disc.threshold then
		price = math.floor(price * (1 - disc.discount))
	end
	return price
end

-- Sell price with optional lucky bonus.
local function getSellPrice(shopCfg, itemCfg)
	local price = math.floor(itemCfg.basePrice * shopCfg.sellMultiplier)
	if math.random() < LUCKY_SELL_CHANCE then
		price = math.floor(price * LUCKY_SELL_MULT)
	end
	return price
end

-- True if itemType is in the shop's acceptedTypes list.
local function typeAccepted(shopCfg, itemType)
	for _, t in shopCfg.acceptedTypes do
		if t == itemType then return true end
	end
	return false
end

-- True if itemId is listed in the shop's stock.
local function inStock(shopCfg, itemId)
	for _, id in shopCfg.stock do
		if id == itemId then return true end
	end
	return false
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function ShopService:KnitInit()
end

function ShopService:KnitStart()
	self._dataService      = Knit.GetService("DataService")
	self._inventoryService = Knit.GetService("InventoryService")
	self._currencyService  = Knit.GetService("CurrencyService")

	self.Client.RequestOpenShop:Connect(function(player, shopId)
		self:openFor(player, shopId)
	end)
end

-- Server-callable: open a shop for a player (also used by NPCService proximity prompts).
function ShopService:openFor(player, shopId)
	local shopCfg = AssetConfig.getShop(shopId)
	if not shopCfg then return end

	local data     = self._dataService:get(player)
	local morality = data and data.morality or 50

	local stockData = {}
	for _, itemId in shopCfg.stock do
		local itemCfg = ItemModule.getConfig(itemId)
		if itemCfg then
			stockData[#stockData + 1] = {
				id       = itemId,
				nameKey  = itemCfg.nameKey,
				imageId  = itemCfg.imageId,
				buyPrice = getBuyPrice(shopCfg, itemCfg, morality),
				sellMult = shopCfg.sellMultiplier,
			}
		end
	end

	self.Client.OpenShop:Fire(player, shopId, stockData)
end

-- ── Client RemoteFunctions ────────────────────────────────────────

-- Returns (true, newBalance) or (false, reason).
function ShopService.Client:PurchaseItem(player, shopId, itemId, amount)
	amount = math.max(1, math.floor(amount or 1))

	local shopCfg = AssetConfig.getShop(shopId)
	if not shopCfg then return false, "invalid_shop" end
	if not inStock(shopCfg, itemId) then return false, "not_in_stock" end

	local itemCfg = ItemModule.getConfig(itemId)
	if not itemCfg then return false, "invalid_item" end

	local data = self.Server._dataService:get(player)
	if not data then return false, "not_loaded" end

	local price     = getBuyPrice(shopCfg, itemCfg, data.morality)
	local totalCost = price * amount

	local paid, payReason = self.Server._currencyService:spend(player, "Rupiah", totalCost)
	if not paid then return false, payReason end

	local added, addReason = self.Server._inventoryService:addItem(player, itemId, amount)
	if not added then
		-- Refund — spend already succeeded so we must reverse it
		self.Server._currencyService:add(player, "Rupiah", totalCost)
		return false, addReason
	end

	return true, self.Server._currencyService:get(player, "Rupiah")
end

-- Returns (true, newBalance, earned) or (false, reason).
function ShopService.Client:SellItem(player, shopId, itemId, amount)
	amount = math.max(1, math.floor(amount or 1))

	local shopCfg = AssetConfig.getShop(shopId)
	if not shopCfg then return false, "invalid_shop" end

	local itemCfg = ItemModule.getConfig(itemId)
	if not itemCfg then return false, "invalid_item" end

	local data = self.Server._dataService:get(player)
	if not data then return false, "not_loaded" end

	-- Penjahat: NPCs refuse to deal with criminals
	if data.morality < PENJAHAT_THRESHOLD then
		return false, "penjahat_refused"
	end

	if not typeAccepted(shopCfg, itemCfg.type) then
		return false, "type_not_accepted"
	end

	if not self.Server._inventoryService:hasItem(player, itemId, amount) then
		return false, "insufficient"
	end

	local earnedPerUnit = getSellPrice(shopCfg, itemCfg)
	local totalEarned   = earnedPerUnit * amount

	local removed, removeReason = self.Server._inventoryService:removeItem(player, itemId, amount)
	if not removed then return false, removeReason end

	self.Server._currencyService:add(player, "Rupiah", totalEarned)
	return true, self.Server._currencyService:get(player, "Rupiah"), totalEarned
end

return ShopService
