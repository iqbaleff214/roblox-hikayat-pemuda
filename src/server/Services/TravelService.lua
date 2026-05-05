-- ModuleScript: ServerScriptService/Server/Services/TravelService
-- Handles inter-island air travel (TeleportService) and intra-island ferry travel.
-- Adds ProximityPrompts to Bandara/Pelabuhan counter Parts in zone folders.
-- Fires OpenTravelMap to client; client fires TeleportToPlace or FerryTravel back.

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local TravelService = Knit.CreateService {
	Name   = "TravelService",
	Client = {
		OpenTravelMap   = Knit.CreateSignal(), -- server → client: (payload)
		TeleportToPlace = Knit.CreateSignal(), -- client → server: (destPlaceId, destZoneId)
		FerryTravel     = Knit.CreateSignal(), -- client → server: (destZoneId)
	},

	_dataService     = nil,
	_currencyService = nil,
	_zoneService     = nil,
}

-- ── Cost helpers ──────────────────────────────────────────────────

local function getAirCost(fromPlaceId, toPlaceId)
	if fromPlaceId == toPlaceId then
		return AssetConfig.Travel.airTickets.SameIsland
	end
	local key1 = fromPlaceId .. "To" .. toPlaceId
	local key2 = toPlaceId  .. "To" .. fromPlaceId
	return AssetConfig.Travel.airTickets[key1]
		or AssetConfig.Travel.airTickets[key2]
		or AssetConfig.Travel.airTickets.JawaToSumatera
end

-- ── Prompt setup helpers ──────────────────────────────────────────

local function ensurePrompt(part, actionText, keyCode, callback)
	if part:FindFirstChildOfClass("ProximityPrompt") then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText              = actionText
	prompt.KeyboardKeyCode         = keyCode
	prompt.MaxActivationDistance   = 10
	prompt.Parent                  = part
	prompt.Triggered:Connect(callback)
end

function TravelService:_tryAddZonePrompts(zoneFolder, zoneId, zoneCfg)
	if zoneCfg.hasBandara then
		local counter = zoneFolder:FindFirstChild("BandaraTicketCounter")
		if counter and counter:IsA("BasePart") then
			ensurePrompt(counter, "Pesan Tiket (Bandara)", Enum.KeyCode.B, function(player)
				self:_openTravelMap(player, "Bandara", zoneId)
			end)
		end
	end

	if zoneCfg.hasPelabuhan then
		local counter = zoneFolder:FindFirstChild("PelabuhanTicketCounter")
		if counter and counter:IsA("BasePart") then
			ensurePrompt(counter, "Pesan Tiket (Pelabuhan)", Enum.KeyCode.P, function(player)
				self:_openTravelMap(player, "Pelabuhan", zoneId)
			end)
		end
	end

	-- Watch for counter Parts added later (Studio import)
	zoneFolder.DescendantAdded:Connect(function(descendant)
		if not descendant:IsA("BasePart") then return end
		if descendant.Name == "BandaraTicketCounter" and zoneCfg.hasBandara then
			ensurePrompt(descendant, "Pesan Tiket (Bandara)", Enum.KeyCode.B, function(player)
				self:_openTravelMap(player, "Bandara", zoneId)
			end)
		elseif descendant.Name == "PelabuhanTicketCounter" and zoneCfg.hasPelabuhan then
			ensurePrompt(descendant, "Pesan Tiket (Pelabuhan)", Enum.KeyCode.P, function(player)
				self:_openTravelMap(player, "Pelabuhan", zoneId)
			end)
		end
	end)
end

function TravelService:_setupPrompts()
	local zonesFolder = workspace:WaitForChild("Map"):WaitForChild("Zones")

	for zoneId, zoneCfg in AssetConfig.Zones do
		if not (zoneCfg.hasBandara or zoneCfg.hasPelabuhan) then continue end
		local zoneFolder = zonesFolder:FindFirstChild(zoneId)
		if zoneFolder then
			self:_tryAddZonePrompts(zoneFolder, zoneId, zoneCfg)
		end
	end

	-- Also handle zone folders added after startup
	zonesFolder.ChildAdded:Connect(function(child)
		local zoneId  = child.Name
		local zoneCfg = AssetConfig.Zones[zoneId]
		if not zoneCfg then return end
		self:_tryAddZonePrompts(child, zoneId, zoneCfg)
	end)
end

-- ── Travel map payload builder ────────────────────────────────────

function TravelService:_openTravelMap(player, mode, fromZoneId)
	local data = self._dataService:get(player)
	if not data then return end

	local fromZoneCfg = AssetConfig.Zones[fromZoneId]
	local fromPlaceId = fromZoneCfg and fromZoneCfg.place or "Jawa"

	local destinations = {}

	if mode == "Bandara" then
		for placeId, place in AssetConfig.Places do
			local cost     = getAirCost(fromPlaceId, placeId)
			local unlocked = table.find(data.unlockedPlaces, placeId) ~= nil
			destinations[#destinations + 1] = {
				type     = "Place",
				placeId  = placeId,
				zoneId   = place.bandaraZone,
				nameKey  = place.nameKey,
				cost     = cost,
				unlocked = unlocked,
				canTravel = place.placeId ~= 0, -- placeId 0 = not published yet
			}
		end
	else
		-- Ferry: zones in the same Place with pelabuhan, excluding current
		for zoneId, zoneCfg in AssetConfig.Zones do
			if zoneCfg.place ~= fromPlaceId then continue end
			if not zoneCfg.hasPelabuhan then continue end
			if zoneId == fromZoneId then continue end
			local unlocked = table.find(data.unlockedZones, zoneId) ~= nil
			destinations[#destinations + 1] = {
				type     = "Zone",
				zoneId   = zoneId,
				nameKey  = zoneCfg.nameKey,
				cost     = AssetConfig.Travel.ferryTickets.WithinIsland,
				unlocked = unlocked,
				canTravel = true,
			}
		end
	end

	self.Client.OpenTravelMap:Fire(player, {
		mode           = mode,
		fromZone       = fromZoneId,
		destinations   = destinations,
		rupiah         = data.rupiah or 0,
	})
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function TravelService:KnitInit()
end

function TravelService:KnitStart()
	self._dataService     = Knit.GetService("DataService")
	self._currencyService = Knit.GetService("CurrencyService")
	self._zoneService     = Knit.GetService("ZoneService")

	-- Defer prompt setup so ZoneService has created zone folders first
	task.defer(function()
		task.wait(1)
		self:_setupPrompts()
	end)

	self.Client.TeleportToPlace:Connect(function(player, destPlaceId, destZoneId)
		self:_handleTeleport(player, destPlaceId, destZoneId)
	end)

	self.Client.FerryTravel:Connect(function(player, destZoneId)
		self:_handleFerry(player, destZoneId)
	end)
end

-- ── Travel handlers ───────────────────────────────────────────────

function TravelService:_handleTeleport(player, destPlaceId, destZoneId)
	local data = self._dataService:get(player)
	if not data then return end

	local placeCfg = AssetConfig.Places[destPlaceId]
	if not placeCfg then return end
	if placeCfg.placeId == 0 then return end -- not published

	-- Cost
	local currentPlace = self._zoneService:getPlayerPlace(player) or "Jawa"
	local cost = getAirCost(currentPlace, destPlaceId)

	local ok = self._currencyService:spend(player, "Rupiah", cost)
	if not ok then return end

	-- Save before leaving
	self._dataService:save(player)

	-- Teleport with arrival zone data
	local arrivalZone = destZoneId or placeCfg.bandaraZone
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ arrivalZone = arrivalZone })

	local success, err = pcall(function()
		TeleportService:TeleportAsync(placeCfg.placeId, { player }, options)
	end)

	if not success then
		self._currencyService:add(player, "Rupiah", cost)
		warn("[TravelService] TeleportAsync failed:", err)
	end
end

function TravelService:_handleFerry(player, destZoneId)
	local data = self._dataService:get(player)
	if not data then return end

	local destZoneCfg = AssetConfig.Zones[destZoneId]
	if not destZoneCfg then return end
	if not destZoneCfg.hasPelabuhan then return end

	-- Must be same island
	local currentPlace = self._zoneService:getPlayerPlace(player)
	if currentPlace ~= destZoneCfg.place then return end

	local cost = AssetConfig.Travel.ferryTickets.WithinIsland
	local ok   = self._currencyService:spend(player, "Rupiah", cost)
	if not ok then return end

	-- Unlock destination zone
	self._zoneService:unlockZone(player, destZoneId)

	-- Move character to SpawnPoint in destination zone folder
	local zonesFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Zones")
	local zoneFolder  = zonesFolder and zonesFolder:FindFirstChild(destZoneId)
	local spawnPart   = zoneFolder and zoneFolder:FindFirstChild("SpawnPoint")

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and spawnPart and spawnPart:IsA("BasePart") then
		root.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
	end
end

-- ── Public: server-side open (e.g. from NPC dialog trigger) ──────

function TravelService:openForPlayer(player, mode, fromZoneId)
	self:_openTravelMap(player, mode, fromZoneId)
end

return TravelService
