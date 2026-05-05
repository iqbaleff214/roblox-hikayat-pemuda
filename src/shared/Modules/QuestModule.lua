-- ModuleScript: ReplicatedStorage/Shared/Modules/QuestModule
-- Pure utility — safe to require from client or server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local QuestModule = {}

-- Returns the AssetConfig entry for a questId, or nil.
function QuestModule.getConfig(questId)
	return AssetConfig.Quests[questId]
end

-- Returns the current progress count for a specific objective (0 if not started).
-- objectiveProgress is stored as { [objIndex] = count }.
function QuestModule.getObjectiveProgress(playerData, questId, objIndex)
	local qp = playerData.questProgress and playerData.questProgress[questId]
	if not qp then return 0 end
	return (qp.objectiveProgress and qp.objectiveProgress[objIndex]) or 0
end

return QuestModule
