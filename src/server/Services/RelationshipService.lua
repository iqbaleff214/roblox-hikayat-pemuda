-- ModuleScript: ServerScriptService/Server/Services/RelationshipService
-- Manages player-to-player relationship requests, formation, and removal.
-- Validates constraints: requireItem (Cincin for Menikah), maxPerPlayer (1 marriage).
-- Broadcasts nameplate update signals to all clients after relationship changes.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local RelationshipService = Knit.CreateService {
	Name   = "RelationshipService",
	Client = {
		-- server → client
		RelationshipRequestReceived = Knit.CreateSignal(), -- (fromUserId, fromName, relType)
		RelationshipFormed          = Knit.CreateSignal(), -- (withUserId, withName, relType)
		RelationshipRemoved         = Knit.CreateSignal(), -- (withUserId)
		UpdateNameplate             = Knit.CreateSignal(), -- (userId, relType or nil)
		-- client → server
		SendRequest                 = Knit.CreateSignal(), -- (targetUserId: number, relType: string)
		AcceptRequest               = Knit.CreateSignal(), -- ()
		DeclineRequest              = Knit.CreateSignal(), -- ()
		RemoveRelationship          = Knit.CreateSignal(), -- (targetUserId: number)
	},

	_dataService        = nil,
	_inventoryService   = nil,
	_achievementService = nil,
	-- [targetUserId] = { fromUserId, fromName, relType }
	_pendingRequests    = {},
}

-- ── Private helpers ───────────────────────────────────────────────

local function broadcastNameplate(self, userId, relType)
	for _, player in Players:GetPlayers() do
		self.Client.UpdateNameplate:Fire(player, userId, relType)
	end
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function RelationshipService:KnitInit()
end

function RelationshipService:KnitStart()
	self._dataService = Knit.GetService("DataService")

	pcall(function()
		self._inventoryService = Knit.GetService("InventoryService")
	end)
	pcall(function()
		self._achievementService = Knit.GetService("AchievementService")
	end)

	self.Client.SendRequest:Connect(function(player, targetUserId, relType)
		self:_handleSendRequest(player, targetUserId, relType)
	end)

	self.Client.AcceptRequest:Connect(function(player)
		self:_handleAcceptRequest(player)
	end)

	self.Client.DeclineRequest:Connect(function(player)
		self._pendingRequests[player.UserId] = nil
	end)

	self.Client.RemoveRelationship:Connect(function(player, targetUserId)
		self:_handleRemoveRelationship(player, targetUserId)
	end)
end

-- ── Request handlers ──────────────────────────────────────────────

function RelationshipService:_handleSendRequest(player, targetUserId, relType)
	if type(targetUserId) ~= "number" or type(relType) ~= "string" then
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return
	end

	local relCfg = AssetConfig.Relationships[relType]
	if not relCfg then
		return
	end

	local dataA = self._dataService:get(player)
	if not dataA then
		return
	end

	-- Validate and consume requireItem
	if relCfg.requireItem then
		if not self._inventoryService then
			return
		end
		if not self._inventoryService:hasItem(player, relCfg.requireItem, 1) then
			return
		end
		self._inventoryService:removeItem(player, relCfg.requireItem, 1)
	end

	-- Validate maxPerPlayer=1 (Menikah: only one marriage allowed)
	if relCfg.maxPerPlayer and relCfg.maxPerPlayer == 1 then
		for _, existingRel in (dataA.relationships or {}) do
			if existingRel == relType then
				return
			end
		end
	end

	self._pendingRequests[targetPlayer.UserId] = {
		fromUserId = player.UserId,
		fromName   = player.Name,
		relType    = relType,
	}

	self.Client.RelationshipRequestReceived:Fire(
		targetPlayer,
		player.UserId,
		player.Name,
		relType
	)
end

function RelationshipService:_handleAcceptRequest(player)
	local pending = self._pendingRequests[player.UserId]
	if not pending then
		return
	end

	self._pendingRequests[player.UserId] = nil

	local relType  = pending.relType
	local fromId   = pending.fromUserId
	local fromName = pending.fromName

	local dataB = self._dataService:get(player)
	if not dataB then
		return
	end

	-- Write to B's data
	dataB.relationships[tostring(fromId)] = relType

	-- Write to A's data if still in server
	local fromPlayer = Players:GetPlayerByUserId(fromId)
	if fromPlayer then
		local dataA = self._dataService:get(fromPlayer)
		if dataA then
			dataA.relationships[tostring(player.UserId)] = relType
		end

		self.Client.RelationshipFormed:Fire(
			fromPlayer,
			player.UserId,
			player.Name,
			relType
		)

		if self._achievementService then
			pcall(function()
				self._achievementService:check(fromPlayer, "Relationship")
			end)
		end
	end

	self.Client.RelationshipFormed:Fire(
		player,
		fromId,
		fromName,
		relType
	)

	if self._achievementService then
		pcall(function()
			self._achievementService:check(player, "Relationship")
		end)
	end

	broadcastNameplate(self, fromId, relType)
	broadcastNameplate(self, player.UserId, relType)
end

function RelationshipService:_handleRemoveRelationship(player, targetUserId)
	if type(targetUserId) ~= "number" then
		return
	end

	local dataA = self._dataService:get(player)
	if not dataA then
		return
	end

	dataA.relationships[tostring(targetUserId)] = nil

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		local dataB = self._dataService:get(targetPlayer)
		if dataB then
			dataB.relationships[tostring(player.UserId)] = nil
		end
		self.Client.RelationshipRemoved:Fire(targetPlayer, player.UserId)
	end

	self.Client.RelationshipRemoved:Fire(player, targetUserId)

	broadcastNameplate(self, player.UserId, nil)
	broadcastNameplate(self, targetUserId, nil)
end

-- ── Public API ────────────────────────────────────────────────────

-- Returns the relationship type between player and targetUserId, or nil.
function RelationshipService:getRelationship(player, targetUserId)
	local data = self._dataService:get(player)
	if not data then
		return nil
	end
	return data.relationships[tostring(targetUserId)]
end

return RelationshipService
