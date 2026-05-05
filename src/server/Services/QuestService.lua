-- ModuleScript: ServerScriptService/Server/Services/QuestService
-- Tracks quest progress, handles accept/complete/offer flows.
-- Called by combat, dialog, inventory, and crafting systems via triggerCheck().

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local MAX_SIDE_QUESTS = 5

local QuestService = Knit.CreateService {
	Name   = "QuestService",
	Client = {
		QuestUpdate  = Knit.CreateSignal(), -- server → client: (snapshot)
		QuestOffer   = Knit.CreateSignal(), -- server → client: (questId, questCfg)
		QuestAccept  = Knit.CreateSignal(), -- client → server: (questId)
		QuestDecline = Knit.CreateSignal(), -- client → server: (questId)  [no-op]
	},

	_dataService      = nil,
	_inventoryService = nil,
	_currencyService  = nil,
}

-- ── Private helpers ───────────────────────────────────────────────

function QuestService:_syncToClient(player)
	local data = self._dataService:get(player)
	if not data then return end
	self.Client.QuestUpdate:Fire(player, {
		activeQuests    = data.activeQuests,
		completedQuests = data.completedQuests,
		questProgress   = data.questProgress,
	})
end

-- True if every objective in cfg meets its required count in qp.
local function isComplete(cfg, qp)
	for i, obj in cfg.objectives do
		local progress = (qp.objectiveProgress and qp.objectiveProgress[i]) or 0
		if progress < (obj.count or 1) then
			return false
		end
	end
	return true
end

-- True if a trigger (type + target) matches a quest objective entry.
-- For "Deliver" the caller must also verify item ownership.
local function objectiveMatches(obj, trigType, target)
	if obj.type ~= trigType then return false end
	if trigType == "Talk"    then return obj.target == target end
	if trigType == "Deliver" then return obj.target == target end
	if trigType == "Gather"  then return obj.item   == target end
	if trigType == "Explore" then return obj.zone   == target end
	-- "Combat" — any kill
	return true
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function QuestService:KnitInit()
end

function QuestService:KnitStart()
	self._dataService      = Knit.GetService("DataService")
	self._inventoryService = Knit.GetService("InventoryService")
	self._currencyService  = Knit.GetService("CurrencyService")

	-- Sync quest state when player data loads
	Players.PlayerAdded:Connect(function(player)
		local loaded = self._dataService:waitForLoad(player, 10)
		if loaded then
			self:_syncToClient(player)
		end
	end)

	-- Client fires QuestAccept after seeing a QuestOffer popup
	self.Client.QuestAccept:Connect(function(player, questId)
		self:accept(player, questId)
	end)

	-- QuestDecline is intentionally a no-op (player just closes the popup)
	self.Client.QuestDecline:Connect(function(_player, _questId)
	end)
end

-- ── Public API ────────────────────────────────────────────────────

-- Adds a quest to the player's active list.
-- Returns (true) or (false, reason).
function QuestService:accept(player, questId)
	local data = self._dataService:get(player)
	if not data then return false, "not_loaded" end

	local cfg = AssetConfig.Quests[questId]
	if not cfg then return false, "invalid_quest" end

	if data.completedQuests[questId]          then return false, "already_completed" end
	if table.find(data.activeQuests, questId) then return false, "already_active"    end

	-- Enforce side quest cap
	if cfg.type == "Side" then
		local sideCount = 0
		for _, qId in data.activeQuests do
			local qCfg = AssetConfig.Quests[qId]
			if qCfg and qCfg.type == "Side" then
				sideCount += 1
			end
		end
		if sideCount >= MAX_SIDE_QUESTS then
			return false, "side_quest_cap"
		end
	end

	table.insert(data.activeQuests, questId)
	data.questProgress[questId] = { status = "Active", objectiveProgress = {} }

	self:_syncToClient(player)
	return true
end

-- Fires QuestOffer to client (player sees accept/decline popup).
-- No-ops if quest is already active or completed.
function QuestService:offerQuest(player, questId)
	local data = self._dataService:get(player)
	if not data then return end

	local cfg = AssetConfig.Quests[questId]
	if not cfg then return end

	if data.completedQuests[questId]          then return end
	if table.find(data.activeQuests, questId) then return end

	self.Client.QuestOffer:Fire(player, questId, cfg)
end

-- Called by other systems after relevant actions (Combat, Talk, Gather, Explore, Deliver, Craft).
function QuestService:triggerCheck(player, trigType, target, amount)
	amount = amount or 1
	local data = self._dataService:get(player)
	if not data then return end

	local toComplete = {}

	for _, questId in data.activeQuests do
		local cfg = AssetConfig.Quests[questId]
		if not cfg then continue end

		local qp = data.questProgress[questId]
		if not qp then continue end

		for i, obj in cfg.objectives do
			local progress    = (qp.objectiveProgress[i] or 0)
			local targetCount = (obj.count or 1)
			if progress >= targetCount then continue end

			if objectiveMatches(obj, trigType, target) then
				-- Deliver requires the item; consume it here
				if trigType == "Deliver" then
					if not self._inventoryService:hasItem(player, obj.item, 1) then
						continue
					end
					self._inventoryService:removeItem(player, obj.item, 1)
				end

				qp.objectiveProgress[i] = math.min(progress + amount, targetCount)
			end
		end

		if isComplete(cfg, qp) then
			toComplete[#toComplete + 1] = questId
		end
	end

	if #toComplete > 0 then
		for _, questId in toComplete do
			self:complete(player, questId)
		end
		-- complete() calls _syncToClient
	else
		self:_syncToClient(player)
	end
end

-- Marks a quest complete, grants rewards, auto-advances main quest chain.
function QuestService:complete(player, questId)
	local data = self._dataService:get(player)
	if not data then return end

	-- Mark complete and remove from active list
	data.completedQuests[questId] = true
	local idx = table.find(data.activeQuests, questId)
	if idx then table.remove(data.activeQuests, idx) end
	data.questProgress[questId] = nil

	-- Grant rewards
	local cfg = AssetConfig.Quests[questId]
	if cfg and cfg.rewards then
		local r = cfg.rewards
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
		if r.morality and r.morality ~= 0 then
			data.morality = math.clamp((data.morality or 50) + r.morality, 0, 100)
		end
	end

	-- Auto-accept next main quest in chain
	if cfg and cfg.type == "Main" and cfg.nextQuest then
		self:accept(player, cfg.nextQuest)
	end

	-- Unlock place in player data (ZoneService wired in Phase 6)
	if cfg and cfg.unlockPlace then
		if not table.find(data.unlockedPlaces, cfg.unlockPlace) then
			data.unlockedPlaces[#data.unlockedPlaces + 1] = cfg.unlockPlace
		end
		pcall(function()
			Knit.GetService("ZoneService"):unlockZone(player, cfg.unlockPlace)
		end)
	end

	-- Notify dependents (Phase 5+: Achievement; Phase 4: Task)
	pcall(function()
		Knit.GetService("AchievementService"):check(player, "Quest")
	end)
	pcall(function()
		Knit.GetService("TaskService"):triggerCheck(player, "CompleteQuest", cfg and cfg.type)
	end)

	self:_syncToClient(player)
end

return QuestService
