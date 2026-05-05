-- ModuleScript: ServerScriptService/Server/Services/CraftingService
-- Handles all crafting operations server-side.
-- Client fires CraftItem signal; server responds via CraftStarted/CraftComplete/CraftFailed.
-- GetRecipes is a RemoteFunction for the UI to list available recipes.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local ENHANCED_CHANCE = 0.01 -- 1% chance output becomes enhanced

local CraftingService = Knit.CreateService {
	Name   = "CraftingService",
	Client = {
		CraftItem     = Knit.CreateSignal(), -- client → server: (recipeIndex)
		CraftStarted  = Knit.CreateSignal(), -- server → client: (recipeIndex, craftTime)
		CraftComplete = Knit.CreateSignal(), -- server → client: (outputId, amount, enhanced)
		CraftFailed   = Knit.CreateSignal(), -- server → client: (reason)
	},

	_dataService      = nil,
	_inventoryService = nil,
	_activeCrafts     = nil, -- { [userId] = true } prevent concurrent crafts per player
}

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function CraftingService:KnitInit()
	self._activeCrafts = {}
end

function CraftingService:KnitStart()
	self._dataService      = Knit.GetService("DataService")
	self._inventoryService = Knit.GetService("InventoryService")

	-- Clean up active craft lock if player leaves mid-craft
	Players.PlayerRemoving:Connect(function(player)
		self._activeCrafts[player.UserId] = nil
	end)

	self.Client.CraftItem:Connect(function(player, recipeIndex)
		self:_handleCraft(player, recipeIndex)
	end)
end

-- ── Private: craft logic ──────────────────────────────────────────

function CraftingService:_handleCraft(player, recipeIndex)
	local recipe = AssetConfig.Recipes[recipeIndex]
	if not recipe then
		self.Client.CraftFailed:Fire(player, "invalid_recipe")
		return
	end

	local userId = player.UserId
	if self._activeCrafts[userId] then
		self.Client.CraftFailed:Fire(player, "already_crafting")
		return
	end

	-- Validate all ingredients before consuming any
	for _, ingredient in recipe.ingredients do
		if not self._inventoryService:hasItem(player, ingredient.id, ingredient.amount) then
			self.Client.CraftFailed:Fire(player, "missing_ingredient")
			return
		end
	end

	-- Consume ingredients
	for _, ingredient in recipe.ingredients do
		local ok, reason = self._inventoryService:removeItem(player, ingredient.id, ingredient.amount)
		if not ok then
			-- Shouldn't happen since hasItem passed, but guard anyway
			self.Client.CraftFailed:Fire(player, reason or "consume_failed")
			return
		end
	end

	self._activeCrafts[userId] = true
	self.Client.CraftStarted:Fire(player, recipeIndex, recipe.craftTime)

	task.spawn(function()
		task.wait(recipe.craftTime)
		self._activeCrafts[userId] = nil

		-- Player may have left during craft
		if not player.Parent then return end

		local isEnhanced = math.random() < ENHANCED_CHANCE
		local added, reason = self._inventoryService:addItem(
			player, recipe.output, recipe.outputAmount, isEnhanced
		)

		if added then
			self.Client.CraftComplete:Fire(player, recipe.output, recipe.outputAmount, isEnhanced)
			-- Notify AchievementService if loaded (Phase 8)
			pcall(function()
				Knit.GetService("AchievementService"):check(player, "Craft")
			end)
		else
			self.Client.CraftFailed:Fire(player, reason or "add_failed")
		end
	end)
end

-- ── Client RemoteFunction ─────────────────────────────────────────

-- Returns the full recipes table for the crafting UI.
function CraftingService.Client:GetRecipes(_player)
	return AssetConfig.Recipes
end

return CraftingService
