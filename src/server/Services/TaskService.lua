-- ModuleScript: ServerScriptService/Server/Services/TaskService
-- Generates and tracks daily (5) and weekly (3) tasks per player.
-- Resets on schedule (daily: 17:00 UTC; weekly: Monday 17:00 UTC).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)
local TaskModule  = require(ReplicatedStorage:WaitForChild("Shared").Modules.TaskModule)

local TaskService = Knit.CreateService {
	Name   = "TaskService",
	Client = {
		TaskUpdate  = Knit.CreateSignal(), -- server → client: ({ dailyTasks, weeklyTasks })
		ClaimTask   = Knit.CreateSignal(), -- client → server: (taskIndex, isWeekly)
		RerollTask  = Knit.CreateSignal(), -- client → server: (taskIndex)
	},

	_dataService      = nil,
	_currencyService  = nil,
}

-- ── Task pool helper ──────────────────────────────────────────────

-- Returns up to `count` task entries of the given difficulty, excluding excludeIds.
local function generateFromPool(difficulty, count, excludeIds)
	local pool = {}
	for _, tmpl in AssetConfig.Tasks.Templates do
		if tmpl.difficulty == difficulty then
			local excluded = false
			for _, eid in (excludeIds or {}) do
				if eid == tmpl.id then excluded = true; break end
			end
			if not excluded then
				pool[#pool + 1] = tmpl
			end
		end
	end

	-- Fisher-Yates shuffle for fair random selection
	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end

	local result = {}
	for i = 1, math.min(count, #pool) do
		local tmpl = pool[i]
		result[#result + 1] = {
			templateId = tmpl.id,
			target     = tmpl.count or tmpl.targetRupiah or 1,
			progress   = 0,
			completed  = false,
			claimed    = false,
		}
	end
	return result
end

-- True if `tmpl.type` matches the trigger type (Craft also advances CraftVariety tasks).
local function templateMatches(tmpl, trigType, target)
	local typeOk = (tmpl.type == trigType)
		or (trigType == "Craft" and tmpl.type == "CraftVariety")
	if not typeOk then return false end

	if trigType == "Gather" then
		return tmpl.item == target
	elseif trigType == "CompleteQuest" then
		return tmpl.questType == nil or tmpl.questType == target
	elseif trigType == "Collect" then
		return tmpl.itemType == nil or tmpl.itemType == target
	end
	-- Talk, Combat, Craft, CraftVariety, SellValue, Explore — type match is sufficient
	return true
end

-- ── Private helpers ───────────────────────────────────────────────

function TaskService:_syncToClient(player)
	local data = self._dataService:get(player)
	if not data then return end
	self.Client.TaskUpdate:Fire(player, {
		dailyTasks  = data.dailyTasks,
		weeklyTasks = data.weeklyTasks,
	})
end

function TaskService:_checkReset(player)
	local data = self._dataService:get(player)
	if not data then return end

	local changed = false
	local quota   = AssetConfig.Tasks

	-- Daily reset (or first-time generation)
	if TaskModule.shouldResetDaily(data) or #data.dailyTasks == 0 then
		local tasks = {}
		for _, entry in generateFromPool("Easy",   quota.dailyQuota.easy)   do tasks[#tasks + 1] = entry end
		for _, entry in generateFromPool("Medium",  quota.dailyQuota.medium) do tasks[#tasks + 1] = entry end
		data.dailyTasks       = tasks
		data.lastDailyReset   = os.time()
		data.dailyRerollsUsed = 0
		changed = true
	end

	-- Weekly reset (or first-time generation)
	if TaskModule.shouldResetWeekly(data) or #data.weeklyTasks == 0 then
		local tasks = {}
		for _, entry in generateFromPool("Medium", quota.weeklyQuota.medium) do tasks[#tasks + 1] = entry end
		for _, entry in generateFromPool("Hard",   quota.weeklyQuota.hard)   do tasks[#tasks + 1] = entry end
		data.weeklyTasks      = tasks
		data.lastWeeklyReset  = os.time()
		changed = true
	end

	if changed then
		self:_syncToClient(player)
	end
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function TaskService:KnitInit()
end

function TaskService:KnitStart()
	self._dataService     = Knit.GetService("DataService")
	self._currencyService = Knit.GetService("CurrencyService")

	Players.PlayerAdded:Connect(function(player)
		local loaded = self._dataService:waitForLoad(player, 10)
		if loaded then
			self:_checkReset(player)
			self:_syncToClient(player)
		end
	end)

	self.Client.ClaimTask:Connect(function(player, taskIndex, isWeekly)
		self:_handleClaim(player, taskIndex, isWeekly)
	end)

	self.Client.RerollTask:Connect(function(player, taskIndex)
		self:_handleReroll(player, taskIndex)
	end)
end

-- ── Public API ────────────────────────────────────────────────────

-- Called by other systems after relevant player actions.
function TaskService:triggerCheck(player, trigType, target, amount)
	amount = amount or 1
	local data = self._dataService:get(player)
	if not data then return end

	local changed = false

	local function checkList(tasks)
		for _, task in tasks do
			if task.completed then continue end
			local tmpl = TaskModule.getTemplate(task.templateId)
			if not tmpl then continue end

			if templateMatches(tmpl, trigType, target) then
				task.progress = math.min(task.progress + amount, task.target)
				if task.progress >= task.target then
					task.completed = true
				end
				changed = true
			end
		end
	end

	checkList(data.dailyTasks)
	checkList(data.weeklyTasks)

	if changed then
		self:_syncToClient(player)
	end
end

-- ── Private: claim & reroll ───────────────────────────────────────

function TaskService:_handleClaim(player, taskIndex, isWeekly)
	local data = self._dataService:get(player)
	if not data then return end

	local tasks = isWeekly and data.weeklyTasks or data.dailyTasks
	local task  = tasks[taskIndex]
	if not task or not task.completed or task.claimed then return end

	local tmpl = TaskModule.getTemplate(task.templateId)
	if not tmpl or not tmpl.reward then return end

	task.claimed = true

	-- Grant reward
	if tmpl.reward.rupiah and tmpl.reward.rupiah > 0 then
		self._currencyService:add(player, "Rupiah", tmpl.reward.rupiah)
	end
	if tmpl.reward.gold and tmpl.reward.gold > 0 then
		self._currencyService:add(player, "Gold", tmpl.reward.gold)
	end

	-- All-claimed bonus for the period
	local allClaimed = true
	for _, t in tasks do
		if not t.claimed then allClaimed = false; break end
	end

	if allClaimed then
		local bonus = isWeekly
			and AssetConfig.Tasks.allWeeklyBonus
			or  AssetConfig.Tasks.allDailyBonus

		if bonus.rupiah then
			local amt = math.random(bonus.rupiah.min, bonus.rupiah.max)
			self._currencyService:add(player, "Rupiah", amt)
		end
		if bonus.gold and bonus.gold > 0 then
			self._currencyService:add(player, "Gold", bonus.gold)
		end
		if bonus.morality and bonus.morality > 0 then
			local d = self._dataService:get(player)
			if d then
				d.morality = math.clamp((d.morality or 50) + bonus.morality, 0, 100)
			end
		end
	end

	self:_syncToClient(player)
end

function TaskService:_handleReroll(player, taskIndex)
	local data = self._dataService:get(player)
	if not data then return end

	local rerollsUsed = data.dailyRerollsUsed or 0
	if rerollsUsed >= AssetConfig.Tasks.rerollsPerDay then return end

	local task = data.dailyTasks[taskIndex]
	if not task or task.completed then return end

	-- Deduct cost
	local cost = AssetConfig.Tasks.rerollCost.rupiah
	local ok   = self._currencyService:spend(player, "Rupiah", cost)
	if not ok then return end

	local currentTmpl = TaskModule.getTemplate(task.templateId)
	if not currentTmpl then
		self._currencyService:add(player, "Rupiah", cost)
		return
	end

	-- Exclude all current daily template IDs to avoid duplicates
	local excludeIds = {}
	for _, t in data.dailyTasks do
		excludeIds[#excludeIds + 1] = t.templateId
	end

	local newEntries = generateFromPool(currentTmpl.difficulty, 1, excludeIds)
	if #newEntries == 0 then
		self._currencyService:add(player, "Rupiah", cost)
		return
	end

	data.dailyTasks[taskIndex] = newEntries[1]
	data.dailyRerollsUsed      = rerollsUsed + 1

	self:_syncToClient(player)
end

return TaskService
