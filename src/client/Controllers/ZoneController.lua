-- LocalScript: StarterPlayerScripts/Client/Controllers/ZoneController
-- Caches the player's current zone and unlocked zones.
-- Listens to ZoneChanged and ZoneUnlocked Knit signals from ZoneService.
-- Other controllers call ZoneController.getCurrentZone() for zone-aware UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local ZoneController = Knit.CreateController { Name = "ZoneController" }

-- ── State ─────────────────────────────────────────────────────────

local _currentZone    = nil
local _currentZoneCfg = nil
local _unlockedZones  = {}
local _unlockedPlaces = {}

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function ZoneController:KnitInit()
end

function ZoneController:KnitStart()
	local zoneService = Knit.GetService("ZoneService")

	zoneService.ZoneChanged:Connect(function(zoneId, zoneCfg)
		_currentZone    = zoneId
		_currentZoneCfg = zoneCfg

		if zoneId and not table.find(_unlockedZones, zoneId) then
			_unlockedZones[#_unlockedZones + 1] = zoneId
		end

		if zoneCfg and zoneCfg.place and not table.find(_unlockedPlaces, zoneCfg.place) then
			_unlockedPlaces[#_unlockedPlaces + 1] = zoneCfg.place
		end
	end)

	zoneService.ZoneUnlocked:Connect(function(zoneId)
		if not table.find(_unlockedZones, zoneId) then
			_unlockedZones[#_unlockedZones + 1] = zoneId
		end
	end)

	-- Seed from player data on join
	local dataService = Knit.GetService("DataService")
	task.spawn(function()
		local data = dataService:GetPlayerData()
		if not data then return end
		_unlockedZones  = data.unlockedZones  or {}
		_unlockedPlaces = data.unlockedPlaces or {}
		_currentZone    = data.lastZone
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function ZoneController:getCurrentZone()
	return _currentZone
end

function ZoneController:getCurrentZoneCfg()
	return _currentZoneCfg
end

function ZoneController:isUnlocked(zoneId)
	return table.find(_unlockedZones, zoneId) ~= nil
end

function ZoneController:isPlaceUnlocked(placeId)
	return table.find(_unlockedPlaces, placeId) ~= nil
end

function ZoneController:getUnlockedZones()
	return _unlockedZones
end

function ZoneController:getUnlockedPlaces()
	return _unlockedPlaces
end

return ZoneController
