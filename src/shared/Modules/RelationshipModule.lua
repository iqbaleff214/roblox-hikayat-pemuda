-- ModuleScript: ReplicatedStorage/Shared/Modules/RelationshipModule
-- Pure shared helper for relationship lookups. No server dependencies.

local RelationshipModule = {}

-- Returns the relationship type between the given player data and a target userId,
-- or nil if none exists. Works on both client (cached data) and server.
function RelationshipModule.getRelationship(data, targetUserId)
	if not data then
		return nil
	end
	if not data.relationships then
		return nil
	end
	return data.relationships[tostring(targetUserId)]
end

-- Returns true if the player's data already has a Menikah relationship.
function RelationshipModule.hasMarriage(data)
	if not data then
		return false
	end
	for _, relType in (data.relationships or {}) do
		if relType == "Menikah" then
			return true
		end
	end
	return false
end

return RelationshipModule
