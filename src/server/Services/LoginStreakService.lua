-- ModuleScript: ServerScriptService/Server/Services/LoginStreakService
-- Awards login streak rewards on join. Streak resets if a day is missed.
-- Fires LoginStreakClaimed to client so it can show the streak popup.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local LoginStreakService = Knit.CreateService {
	Name   = "LoginStreakService",
	Client = {
		LoginStreakClaimed = Knit.CreateSignal(), -- server → client: (payload)
	},

	_dataService      = nil,
	_inventoryService = nil,
	_currencyService  = nil,
}

-- ── Date helpers (WIB = UTC+7) ────────────────────────────────────

local WIB_OFFSET = 7 * 3600  -- seconds

local function todayWIB()
	return os.date("!%Y-%m-%d", os.time() + WIB_OFFSET)
end

local function yesterdayWIB()
	return os.date("!%Y-%m-%d", os.time() + WIB_OFFSET - 86400)
end

-- ── Reward helpers ────────────────────────────────────────────────

-- Find the highest unclaimed milestone entry where entry.day <= streak.
local function findNextClaimable(data, streak)
	local bestEntry = nil
	local bestDay   = 0
	for _, entry in AssetConfig.LoginStreak do
		if entry.day <= streak
			and entry.day > bestDay
			and not (data.streakRewardsClaimed and data.streakRewardsClaimed[entry.day])
		then
			bestDay   = entry.day
			bestEntry = entry
		end
	end
	return bestEntry, bestDay
end

-- Find the next unclaimed milestone above the current streak.
local function findNextPending(data, streak)
	local nextEntry = nil
	local nextDay   = math.huge
	for _, entry in AssetConfig.LoginStreak do
		if entry.day > streak
			and entry.day < nextDay
			and not (data.streakRewardsClaimed and data.streakRewardsClaimed[entry.day])
		then
			nextDay   = entry.day
			nextEntry = entry
		end
	end
	return nextEntry, (nextDay == math.huge and nil or nextDay)
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function LoginStreakService:KnitInit()
end

function LoginStreakService:KnitStart()
	self._dataService      = Knit.GetService("DataService")
	self._inventoryService = Knit.GetService("InventoryService")
	self._currencyService  = Knit.GetService("CurrencyService")

	Players.PlayerAdded:Connect(function(player)
		local loaded = self._dataService:waitForLoad(player, 10)
		if loaded then
			self:_handleLogin(player)
		end
	end)
end

-- ── Login handling ────────────────────────────────────────────────

function LoginStreakService:_handleLogin(player)
	local data = self._dataService:get(player)
	if not data then return end

	local today     = todayWIB()
	local yesterday = yesterdayWIB()

	-- Already claimed today — skip
	if data.lastLoginDate == today then return end

	-- Calculate new streak
	local newStreak
	if data.lastLoginDate == yesterday then
		newStreak = (data.loginStreak or 0) + 1
	else
		newStreak = 1  -- streak broken or first login
	end

	data.loginStreak    = newStreak
	data.lastLoginDate  = today

	-- Ensure claimed table exists
	if not data.streakRewardsClaimed then
		data.streakRewardsClaimed = {}
	end

	-- Find and grant the highest newly unlocked milestone
	local claimEntry, claimDay = findNextClaimable(data, newStreak)
	if not claimEntry then return end

	data.streakRewardsClaimed[claimDay] = true

	-- Grant reward
	local r = claimEntry.reward
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

	-- Find next upcoming milestone for the popup preview
	local nextEntry, nextDay = findNextPending(data, newStreak)

	self.Client.LoginStreakClaimed:Fire(player, {
		streak      = newStreak,
		day         = claimDay,
		reward      = r,
		nextDay     = nextDay,
		nextReward  = nextEntry and nextEntry.reward or nil,
	})
end

return LoginStreakService
