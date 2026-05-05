-- ModuleScript: ServerScriptService/Server/Services/ZoneService
-- Detects which zone each player is in, fires ZoneChanged on transition (debounced).
-- Creates ZoneBoundary Parts from AssetConfig.ZoneBounds for existing zone folders.
-- unlockZone() is the single entry point called by QuestService and TravelService.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local ZONE_CHECK_INTERVAL = 2     -- seconds between zone scans
local ZONE_DEBOUNCE_TIME  = 0.5   -- ignore zone flicker shorter than this

local ZoneService = Knit.CreateService {
	Name   = "ZoneService",
	Client = {
		ZoneChanged  = Knit.CreateSignal(), -- server → client: (zoneId, zoneCfg)
		ZoneUnlocked = Knit.CreateSignal(), -- server → client: (zoneId)
	},

	_dataService    = nil,
	_playerZones    = {},  -- [userId] = zoneId (current)
	_zoneDebounce   = {},  -- [userId] = tick() of last change
	_zoneBoundaries = {},  -- [zoneId] = Part
}

-- ── Zone boundary creation ────────────────────────────────────────

-- Only creates boundaries for zone folders that already exist in workspace
-- (placed by Studio terrain work or by NPCService). Zones in other Places
-- that share the same coordinate origins are naturally absent here.
local function buildBoundaries(self, zonesFolder)
	for zoneId, bounds in AssetConfig.ZoneBounds do
		local zoneFolder = zonesFolder:FindFirstChild(zoneId)
		if not zoneFolder then continue end

		local existing = zoneFolder:FindFirstChild("ZoneBoundary")
		if existing and existing:IsA("BasePart") then
			self._zoneBoundaries[zoneId] = existing
			continue
		end

		local part = Instance.new("Part")
		part.Name         = "ZoneBoundary"
		part.Anchored     = true
		part.CanCollide   = false
		part.CastShadow   = false
		part.Transparency = 1
		part.Size         = bounds.size
		part.CFrame       = CFrame.new(bounds.center)
		part.Parent       = zoneFolder

		self._zoneBoundaries[zoneId] = part
	end
end

-- ── Position → zone lookup ────────────────────────────────────────

local function zoneAtPosition(self, position)
	for zoneId, part in self._zoneBoundaries do
		local halfSize = part.Size / 2
		local localPos = part.CFrame:PointToObjectSpace(position)
		if math.abs(localPos.X) <= halfSize.X
			and math.abs(localPos.Y) <= halfSize.Y
			and math.abs(localPos.Z) <= halfSize.Z
		then
			return zoneId
		end
	end
	return nil
end

-- ── Zone scan loop ────────────────────────────────────────────────

function ZoneService:_checkAllZones()
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local newZone  = zoneAtPosition(self, root.Position)
		local prevZone = self._playerZones[player.UserId]
		if newZone == prevZone then continue end

		-- Debounce: ignore brief boundary crossings
		local now        = tick()
		local lastChange = self._zoneDebounce[player.UserId] or 0
		if (now - lastChange) < ZONE_DEBOUNCE_TIME then continue end
		self._zoneDebounce[player.UserId] = now

		self._playerZones[player.UserId] = newZone

		if newZone then
			local zoneCfg = AssetConfig.Zones[newZone]
			self.Client.ZoneChanged:Fire(player, newZone, zoneCfg)

			-- Unlock on first visit
			self:unlockZone(player, newZone)

			-- Achievement checks
			pcall(function()
				Knit.GetService("AchievementService"):check(player, "ExploreZone")
			end)
			pcall(function()
				Knit.GetService("AchievementService"):check(player, "ExplorePlace")
			end)
		end
	end
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function ZoneService:KnitInit()
end

function ZoneService:KnitStart()
	self._dataService = Knit.GetService("DataService")

	-- Build boundaries after a short defer so NPCService has created zone folders first
	task.defer(function()
		local zonesFolder = workspace:WaitForChild("Map"):WaitForChild("Zones")
		buildBoundaries(self, zonesFolder)

		-- Re-check when new zone folders are added (lazy Studio import)
		zonesFolder.ChildAdded:Connect(function(_child)
			buildBoundaries(self, zonesFolder)
		end)
	end)

	Players.PlayerAdded:Connect(function(player)
		local joinData = player:GetJoinData()
		local teleportData = joinData and joinData.TeleportData
		local arrivalZone  = teleportData and teleportData.arrivalZone

		local loaded = self._dataService:waitForLoad(player, 10)
		if not loaded then return end

		-- Unlock arrival zone if player teleported in
		if arrivalZone then
			self:unlockZone(player, arrivalZone)
			self._playerZones[player.UserId] = arrivalZone
		else
			-- Restore last-known zone
			local data = self._dataService:get(player)
			if data and data.lastZone then
				self._playerZones[player.UserId] = data.lastZone
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- Persist current zone for next session
		local zoneId = self._playerZones[player.UserId]
		if zoneId then
			local data = self._dataService:get(player)
			if data then
				data.lastZone = zoneId
			end
		end
		self._playerZones[player.UserId] = nil
		self._zoneDebounce[player.UserId] = nil
	end)

	-- Periodic zone detection loop
	task.spawn(function()
		while true do
			task.wait(ZONE_CHECK_INTERVAL)
			self:_checkAllZones()
		end
	end)
end

-- ── Public API ────────────────────────────────────────────────────

-- Adds zoneId to player's unlocked list. Idempotent.
function ZoneService:unlockZone(player, zoneId)
	local data = self._dataService:get(player)
	if not data then return end

	if table.find(data.unlockedZones, zoneId) then return end
	data.unlockedZones[#data.unlockedZones + 1] = zoneId

	-- Unlock the parent Place on first zone in that place
	local zoneCfg = AssetConfig.Zones[zoneId]
	if zoneCfg and zoneCfg.place then
		if not table.find(data.unlockedPlaces, zoneCfg.place) then
			data.unlockedPlaces[#data.unlockedPlaces + 1] = zoneCfg.place
		end
	end

	self.Client.ZoneUnlocked:Fire(player, zoneId)
end

function ZoneService:isUnlocked(player, zoneId)
	local data = self._dataService:get(player)
	if not data then return false end
	return table.find(data.unlockedZones, zoneId) ~= nil
end

function ZoneService:getPlayerZone(player)
	return self._playerZones[player.UserId]
end

function ZoneService:getPlayerPlace(player)
	local zoneId = self._playerZones[player.UserId]
	if not zoneId then return nil end
	local zoneCfg = AssetConfig.Zones[zoneId]
	return zoneCfg and zoneCfg.place
end

-- Returns all players currently in the given zone.
function ZoneService:getPlayersInZone(zoneId)
	local result = {}
	for _, player in Players:GetPlayers() do
		if self._playerZones[player.UserId] == zoneId then
			result[#result + 1] = player
		end
	end
	return result
end

return ZoneService
