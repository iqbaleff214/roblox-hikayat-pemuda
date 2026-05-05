-- ModuleScript: ReplicatedStorage/Shared/Modules/TaskModule
-- Pure utility — safe to require from client or server.
-- Reset boundary logic uses AssetConfig.Tasks.resetHourUTC (17 = 00:00 WIB).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local RESET_HOUR_UTC    = AssetConfig.Tasks.resetHourUTC   -- 17
local RESET_OFFSET_SECS = RESET_HOUR_UTC * 3600

local TaskModule = {}

-- Returns the template table for a given templateId, or nil.
function TaskModule.getTemplate(templateId)
	for _, tmpl in AssetConfig.Tasks.Templates do
		if tmpl.id == templateId then return tmpl end
	end
	return nil
end

-- Most recent daily reset boundary (Unix timestamp).
-- Daily reset = every day at RESET_HOUR_UTC:00 UTC.
local function lastDailyBoundary(now)
	local secsInDay = now % 86400
	if secsInDay >= RESET_OFFSET_SECS then
		return now - (secsInDay - RESET_OFFSET_SECS)
	end
	return now - (secsInDay + (86400 - RESET_OFFSET_SECS))
end

-- Most recent weekly reset boundary (every Monday at RESET_HOUR_UTC:00 UTC).
local function lastWeeklyBoundary(now)
	local t             = os.date("!*t", now)
	-- wday: 1=Sun 2=Mon … 7=Sat → daysSinceMon: Mon=0, Tue=1 … Sun=6
	local daysSinceMon  = (t.wday - 2) % 7
	local secsSinceMonMidnight = daysSinceMon * 86400 + (now % 86400)
	if secsSinceMonMidnight >= RESET_OFFSET_SECS then
		return now - (secsSinceMonMidnight - RESET_OFFSET_SECS)
	end
	return now - (secsSinceMonMidnight + 7 * 86400 - RESET_OFFSET_SECS)
end

-- Returns true if daily tasks should be regenerated for this player.
function TaskModule.shouldResetDaily(data)
	return (data.lastDailyReset or 0) < lastDailyBoundary(os.time())
end

-- Returns true if weekly tasks should be regenerated for this player.
function TaskModule.shouldResetWeekly(data)
	return (data.lastWeeklyReset or 0) < lastWeeklyBoundary(os.time())
end

return TaskModule
