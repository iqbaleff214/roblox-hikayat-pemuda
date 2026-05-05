-- ModuleScript: ReplicatedStorage/Shared/Modules/AchievementModule
-- Pure utility — safe to require from client or server.

local AchievementModule = {}

-- Returns true if the achievement has been completed in the player's data.
function AchievementModule.isCompleted(data, achId)
	local record = data.achievements and data.achievements[achId]
	return record ~= nil and record.completed == true
end

return AchievementModule
