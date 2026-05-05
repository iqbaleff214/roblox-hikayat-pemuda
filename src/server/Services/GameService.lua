-- ModuleScript: ServerScriptService/Server/Services/GameService
-- Central server orchestrator.
-- Handles player join/leave lifecycle and distributes initial state to clients.
-- Other systems query GameService for the current zone of any player.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local DEFAULT_ZONE = "KotaJogja"

local GameService = Knit.CreateService {
	Name   = "GameService",
	Client = {},

	_playerZones = {},  -- { [userId] = zoneId }
	_dataService = nil,
	_assetConfig = nil,
}

-- ── KnitInit ─────────────────────────────────────────────────────
function GameService:KnitInit()
	-- Load shared modules
	local Shared      = ReplicatedStorage:WaitForChild("Shared")
	self._assetConfig = require(Shared.Config.AssetConfig)
end

-- ── KnitStart (all services initialised) ─────────────────────────
function GameService:KnitStart()
	self._dataService = Knit.GetService("DataService")

	local remotes = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	local moralityRE  = remotes:WaitForChild("MoralityChanged",  10)
	local zoneRE      = remotes:WaitForChild("ZoneChanged",      10)

	Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player, moralityRE, zoneRE)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._playerZones[player.UserId] = nil
	end)

	-- Handle players already in-game (Studio play-solo edge case)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_onPlayerAdded(player, moralityRE, zoneRE)
		end)
	end
end

-- ── Private ───────────────────────────────────────────────────────
function GameService:_onPlayerAdded(player, moralityRE, zoneRE)
	-- Wait for DataService to finish loading this player's profile
	local loaded = self._dataService:waitForLoad(player, 10)
	if not loaded then
		warn("[GameService] Data never loaded for " .. player.Name)
		return
	end

	local data = self._dataService:get(player)
	if not data then return end

	-- Assign starting zone: last unlocked zone, or the island's first zone
	local zones    = data.unlockedZones
	local startZone = (zones and #zones > 0) and zones[#zones] or DEFAULT_ZONE
	self._playerZones[player.UserId] = startZone

	-- Sync morality tier to client so HUD badge shows correct tier on spawn
	moralityRE:FireClient(player, data.morality)

	-- Notify client of their current zone
	zoneRE:FireClient(player, startZone)
end

-- ── Public API ────────────────────────────────────────────────────

-- Returns the current zone ID for a player. Used by ZoneManager, TravelServer, etc.
function GameService:getZone(player)
	return self._playerZones[player.UserId] or DEFAULT_ZONE
end

-- Called by ZoneManager when a player crosses a zone boundary.
function GameService:setZone(player, zoneId)
	local config = self._assetConfig.getZone(zoneId)
	if not config then
		warn("[GameService] setZone: unknown zone '" .. tostring(zoneId) .. "'")
		return
	end

	self._playerZones[player.UserId] = zoneId

	-- Unlock zone in player data if first visit
	local data       = self._dataService:get(player)
	local unlockedZones = data.unlockedZones
	local alreadyUnlocked = false

	for _, id in unlockedZones do
		if id == zoneId then
			alreadyUnlocked = true
			break
		end
	end

	if not alreadyUnlocked then
		table.insert(unlockedZones, zoneId)
		-- Unlock the Place too if it's new
		local placeId = config.place
		local unlockedPlaces = data.unlockedPlaces
		local placeKnown = false
		for _, pid in unlockedPlaces do
			if pid == placeId then placeKnown = true; break end
		end
		if not placeKnown then
			table.insert(unlockedPlaces, placeId)
		end
	end

	-- Notify client of zone change (AudioManager uses this for BGM crossfade)
	local remotes = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
	local zoneRE  = remotes:FindFirstChild("ZoneChanged")
	if zoneRE then
		zoneRE:FireClient(player, zoneId)
	end
end

-- ── Client-facing ─────────────────────────────────────────────────

-- Client can query their current zone (e.g. for travel UI)
function GameService.Client:GetCurrentZone(player)
	return self.Server:getZone(player)
end

return GameService
