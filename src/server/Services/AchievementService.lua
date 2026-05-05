-- ModuleScript: ServerScriptService/Server/Services/AchievementService
-- Tracks one-time achievements. Called by other systems via check(player, category).
-- Grants rewards and fires AchievementUnlocked to client on first unlock.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit          = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig   = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)
local MoralityModule = require(ReplicatedStorage:WaitForChild("Shared").Modules.MoralityModule)

local AchievementService = Knit.CreateService {
	Name   = "AchievementService",
	Client = {
		AchievementUnlocked = Knit.CreateSignal(), -- server → client: (achConfig)
	},

	_dataService      = nil,
	_inventoryService = nil,
	_currencyService  = nil,
}

-- ── Private helpers ───────────────────────────────────────────────

local function findAchConfig(achId)
	for _, ach in AssetConfig.Achievements do
		if ach.id == achId then return ach end
	end
	return nil
end

-- True if the morality tier's labelKey corresponds to the achievement target string.
-- ach.target is e.g. "Pahlawan"; tier.labelKey is e.g. "morality.pahlawan".
local function moralityTierMatches(tier, achTarget)
	return tier.labelKey == ("morality." .. achTarget:lower())
end

-- Evaluates whether an achievement's condition is currently met for this player.
-- For "Combat" and "Craft" types, also increments a persistent progress counter.
local function evaluate(ach, data, category, incrementNeeded)
	local achRecord = data.achievements[ach.id] or {}

	if category == "Combat" or category == "Craft" or category == "Quest" then
		if not incrementNeeded then
			return achRecord.progress and achRecord.progress >= (ach.count or 1)
		end
		achRecord.progress       = (achRecord.progress or 0) + 1
		data.achievements[ach.id] = achRecord
		return achRecord.progress >= (ach.count or 1)

	elseif category == "ExplorePlace" then
		return #(data.unlockedPlaces or {}) >= (ach.count or 1)

	elseif category == "ExploreZone" then
		local count = 0
		for _, zoneId in (data.unlockedZones or {}) do
			local zoneCfg = AssetConfig.getZone(zoneId)
			if zoneCfg and zoneCfg.place == ach.place then
				count += 1
			end
		end
		return count >= (ach.count or 1)

	elseif category == "Morality" then
		local tier = MoralityModule.getTier(data.morality or 50)
		return moralityTierMatches(tier, ach.target or "")

	elseif category == "Relationship" then
		for _, relType in (data.relationships or {}) do
			if relType == ach.target then return true end
		end
		return false
	end

	return false
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function AchievementService:KnitInit()
end

function AchievementService:KnitStart()
	self._dataService      = Knit.GetService("DataService")
	self._inventoryService = Knit.GetService("InventoryService")
	self._currencyService  = Knit.GetService("CurrencyService")
end

-- ── Public API ────────────────────────────────────────────────────

-- Called by other systems after an action in the given category.
-- category: "Combat" | "Craft" | "Quest" | "ExplorePlace" | "ExploreZone"
--           | "Morality" | "Relationship"
function AchievementService:check(player, category)
	local data = self._dataService:get(player)
	if not data then return end

	for _, ach in AssetConfig.Achievements do
		if ach.type ~= category then continue end

		local record = data.achievements[ach.id] or {}
		if record.completed then continue end

		-- Progress types need increment=true on first pass so the counter advances
		local needsIncrement = (category == "Combat" or category == "Craft" or category == "Quest")
		if evaluate(ach, data, category, needsIncrement) then
			self:unlock(player, ach.id)
		end
	end
end

-- Marks an achievement complete, grants its reward, and notifies the client.
-- Idempotent — safe to call twice (second call is a no-op).
function AchievementService:unlock(player, achId)
	local data = self._dataService:get(player)
	if not data then return end

	local record = data.achievements[achId] or {}
	if record.completed then return end

	-- Persist completion (preserve progress counter if present)
	data.achievements[achId] = {
		progress  = record.progress,
		completed = true,
		claimedAt = os.time(),
	}

	local ach = findAchConfig(achId)
	if not ach then return end

	-- Grant reward
	if ach.reward then
		local r = ach.reward
		if r.rupiah and r.rupiah > 0 then
			self._currencyService:add(player, "Rupiah", r.rupiah)
		end
		if r.gold and r.gold > 0 then
			self._currencyService:add(player, "Gold", r.gold)
		end
		if r.items then
			for _, itemReward in r.items do
				self._inventoryService:addItem(player, itemReward.id, itemReward.amount)
			end
		end
	end

	self.Client.AchievementUnlocked:Fire(player, ach)
end

return AchievementService
