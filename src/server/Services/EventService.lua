-- ModuleScript: ServerScriptService/Server/Services/EventService
-- Detects active Indonesian holiday events from AssetConfig.Events date ranges.
-- On server start: checks real-world UTC date, fires EventActive to all players,
-- clones zone decorations, and exposes the active event for TaskService / ShopService.
-- Event currency is stored in player data under data.eventCurrencies[eventId].

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local EventService = Knit.CreateService {
	Name   = "EventService",
	Client = {
		-- server → client
		EventActive = Knit.CreateSignal(), -- (eventConfig | nil)
	},

	_activeEvent   = nil,   -- current AssetConfig.Events entry or nil
	_dataService   = nil,
	_decorClones   = {},    -- [zoneId] = Model instance (for cleanup)
}

-- ── Date helpers ──────────────────────────────────────────────────

local function isEventActive(eventCfg)
	local now = os.date("!*t")  -- UTC table
	local month = now.month
	local day   = now.day

	local sm = eventCfg.startMonth
	local sd = eventCfg.startDay
	local em = eventCfg.endMonth
	local ed = eventCfg.endDay

	if sm == nil or em == nil then return false end

	-- Convert to a comparable day-of-year-like number
	-- Works correctly even when start/end span month boundaries
	-- (does not handle year-wrap e.g. Dec→Jan for now)
	local function toOrd(m, d) return m * 100 + d end
	local cur  = toOrd(month, day)
	local s    = toOrd(sm, sd)
	local e    = toOrd(em, ed)

	if s <= e then
		return cur >= s and cur <= e
	else
		-- Wraps year boundary (e.g. Dec 25 → Jan 5)
		return cur >= s or cur <= e
	end
end

-- ── Zone decorations ──────────────────────────────────────────────

local function ensureGalerisFolder()
	local map = workspace:FindFirstChild("Map")
	if not map then return nil end
	return map:FindFirstChild("Zones")
end

local function placeDecorations(self, eventCfg)
	local prefabs   = ReplicatedStorage:FindFirstChild("Prefabs")
	local decorRoot = prefabs and prefabs:FindFirstChild("EventDecor")
	if not decorRoot then return end

	local eventDecor = decorRoot:FindFirstChild(eventCfg.id)
	if not eventDecor then return end

	local zonesFolder = ensureGalerisFolder()
	if not zonesFolder then return end

	for _, zoneId in eventCfg.decorZones or {} do
		local zoneFolder = zonesFolder:FindFirstChild(zoneId)
		if not zoneFolder then continue end

		local clone   = eventDecor:Clone()
		clone.Name    = "EventDecor_" .. eventCfg.id
		clone.Parent  = zoneFolder

		self._decorClones[zoneId] = clone
	end
end

local function removeDecorations(self)
	for zoneId, clone in self._decorClones do
		if clone and clone.Parent then
			clone:Destroy()
		end
		self._decorClones[zoneId] = nil
	end
end

-- ── Event activation ──────────────────────────────────────────────

local function detectActiveEvent()
	for _, eventCfg in AssetConfig.Events do
		if isEventActive(eventCfg) then
			return eventCfg
		end
	end
	return nil
end

local function broadcastEventState(self, player)
	self.Client.EventActive:Fire(player, self._activeEvent)
end

local function activateEvent(self, eventCfg)
	self._activeEvent = eventCfg
	placeDecorations(self, eventCfg)

	-- Broadcast to all currently connected players
	for _, player in Players:GetPlayers() do
		broadcastEventState(self, player)
	end
end

local function deactivateEvent(self)
	if not self._activeEvent then return end
	removeDecorations(self)
	self._activeEvent = nil
	for _, player in Players:GetPlayers() do
		self.Client.EventActive:Fire(player, nil)
	end
end

-- ── Player data: event currency helpers ───────────────────────────

function EventService:getEventCurrency(player, eventId)
	local data = self._dataService:get(player)
	if not data then return 0 end
	data.eventCurrencies = data.eventCurrencies or {}
	return data.eventCurrencies[eventId] or 0
end

function EventService:addEventCurrency(player, eventId, amount)
	local data = self._dataService:get(player)
	if not data then return end
	data.eventCurrencies              = data.eventCurrencies or {}
	data.eventCurrencies[eventId]     = (data.eventCurrencies[eventId] or 0) + amount
end

-- ── Public API ────────────────────────────────────────────────────

function EventService:getActiveEvent()
	return self._activeEvent
end

function EventService:isEventActive()
	return self._activeEvent ~= nil
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function EventService:KnitInit()
end

function EventService:KnitStart()
	self._dataService = Knit.GetService("DataService")

	-- Detect and activate on server start
	local eventCfg = detectActiveEvent()
	if eventCfg then
		activateEvent(self, eventCfg)
	end

	-- Broadcast event state to each player when they join
	Players.PlayerAdded:Connect(function(player)
		-- Small delay to ensure player data is loaded
		task.delay(3, function()
			broadcastEventState(self, player)
		end)
	end)

	-- Re-check event state once per hour (in case server stays up across midnight)
	task.spawn(function()
		while true do
			task.wait(3600)
			local current = detectActiveEvent()
			if current and not self._activeEvent then
				activateEvent(self, current)
			elseif not current and self._activeEvent then
				deactivateEvent(self)
			elseif current and self._activeEvent
				and current.id ~= self._activeEvent.id
			then
				deactivateEvent(self)
				activateEvent(self, current)
			end
		end
	end)
end

return EventService
