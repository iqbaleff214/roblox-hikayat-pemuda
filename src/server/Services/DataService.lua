-- ModuleScript: ServerScriptService/Server/Services/DataService
-- Knit Service wrapping ProfileService for all player data persistence.
-- ALL other server systems read/write player data through DataService only.
-- DataStore is Universe-wide by default — same keys work across all 7 Places.

local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit           = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local ProfileService = require(game:GetService("ServerScriptService"):WaitForChild("ServerPackages").ProfileService)

-- ── Default data schema v2 (matches GDD §18.1) ───────────────────
local PROFILE_TEMPLATE = {
	version          = 2,
	rupiah           = 0,
	gold             = 0,
	morality         = 50,
	inventory        = {},  -- { { id, amount } }
	hotbar           = {},  -- { [slotIndex] = itemId }
	hotbarSize       = 4,
	inventorySize    = 20,

	questProgress    = {},  -- { [questId] = { status, objectiveProgress = {} } }
	completedQuests  = {},  -- { [questId] = true }
	activeQuests     = {},  -- array of questIds, max 5 Side quests

	relationships    = {},  -- { [targetUserId] = relationType }
	unlockedPlaces   = { "Jawa" },
	unlockedZones    = { "Suroboyo", "KotaJogja" },

	-- Task system
	dailyTasks       = {},  -- { { id, templateId, progress, completed, claimed } }
	weeklyTasks      = {},  -- same shape
	lastDailyReset   = 0,
	lastWeeklyReset  = 0,
	dailyRerollsUsed = 0,

	-- Retention
	loginStreak          = 0,
	lastLoginDate        = "",  -- "YYYY-MM-DD" in WIB
	streakRewardsClaimed = {},  -- { [day] = true }

	achievements     = {},  -- { [achId] = { completed, claimedAt } }
	collectibleCount = 0,

	-- Galeri
	galeriLayout     = {},  -- { [pedestalSlot] = itemId }

	-- Event currencies
	eventCurrencies  = {},  -- { [eventId] = amount }

	-- Combat
	equippedWeapon   = nil,

	-- Zone tracking (persisted so player returns to last zone on rejoin)
	lastZone         = "KotaJogja",
}

-- Profile key format — "PlayerData_v2_<userId>" across all 7 Places
local STORE_NAME    = "PlayerData"
local KEY_PREFIX    = "PlayerData_v2_"

local ProfileStore = ProfileService.GetProfileStore(STORE_NAME, PROFILE_TEMPLATE)

-- ── Service definition ────────────────────────────────────────────
local DataService = Knit.CreateService {
	Name   = "DataService",
	Client = {},

	_profiles    = {},  -- { [userId] = Profile }
	_loadedEvent = Instance.new("BindableEvent"),  -- fires (player) when data is ready
}

-- ── Private: migrate v1 → v2 (idempotent) ────────────────────────
local function migrate(data)
	if (data.version or 0) >= 2 then return end

	data.version             = 2
	data.hotbarSize          = data.hotbarSize          or 4
	data.inventorySize       = data.inventorySize       or 20
	data.unlockedPlaces      = data.unlockedPlaces      or { "Jawa" }
	data.unlockedZones       = data.unlockedZones       or { "Suroboyo", "KotaJogja" }
	data.dailyTasks          = data.dailyTasks          or {}
	data.weeklyTasks         = data.weeklyTasks         or {}
	data.lastDailyReset      = data.lastDailyReset      or 0
	data.lastWeeklyReset     = data.lastWeeklyReset     or 0
	data.dailyRerollsUsed    = data.dailyRerollsUsed    or 0
	data.loginStreak         = data.loginStreak         or 0
	data.lastLoginDate       = data.lastLoginDate       or ""
	data.streakRewardsClaimed= data.streakRewardsClaimed or {}
	data.achievements        = data.achievements        or {}
	data.collectibleCount    = data.collectibleCount    or 0
	data.galeriLayout        = data.galeriLayout        or {}
	data.eventCurrencies     = data.eventCurrencies     or {}
	data.equippedWeapon      = data.equippedWeapon      or nil
	data.lastZone            = data.lastZone            or "KotaJogja"
end

-- ── Private: load profile for a player ───────────────────────────
function DataService:_loadProfile(player)
	local profile = ProfileStore:LoadProfileAsync(
		KEY_PREFIX .. player.UserId,
		"ForceLoad"
	)

	if not profile then
		-- ProfileService returns nil if it can't load (e.g. Studio offline)
		warn("[DataService] Could not load profile for " .. player.Name .. " — kicking")
		player:Kick("Gagal memuat data. Silakan coba lagi.")
		return
	end

	-- GDPR compliance: associate userId with this profile
	profile:AddUserId(player.UserId)

	-- Fill any missing keys from PROFILE_TEMPLATE without overwriting existing data
	profile:Reconcile()

	-- Handle remote session release (another server stole the session lock)
	profile:ListenToRelease(function()
		self._profiles[player.UserId] = nil
		player:Kick("Sesi data diambil oleh server lain. Silakan bergabung kembali.")
	end)

	if player:IsDescendantOf(Players) then
		-- Migrate schema if needed, then store
		migrate(profile.Data)
		self._profiles[player.UserId] = profile
		self._loadedEvent:Fire(player)
	else
		-- Player left before profile finished loading
		profile:Release()
	end
end

-- ── KnitInit: runs before KnitStart, safe to set up internals ────
function DataService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
		self:_loadProfile(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local profile = self._profiles[player.UserId]
		if profile then
			profile:Release()
			self._profiles[player.UserId] = nil
		end
	end)

	-- Handle players already in-game when the service initialises
	-- (can happen in Studio play solo)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			self:_loadProfile(player)
		end)
	end
end

-- ── KnitStart: all services ready ────────────────────────────────
function DataService:KnitStart()
	-- Nothing additional needed; ProfileService handles auto-save internally.
end

-- ── Public API (called by other server Services) ──────────────────

-- Wait until this player's profile is loaded (max `timeout` seconds).
-- Returns true if loaded, false if timed out.
function DataService:waitForLoad(player, timeout)
	timeout = timeout or 10
	if self._profiles[player.UserId] then return true end

	local deadline = tick() + timeout
	local conn
	local loaded = false

	conn = self._loadedEvent.Event:Connect(function(loadedPlayer)
		if loadedPlayer == player then
			loaded = true
		end
	end)

	while not loaded and tick() < deadline do
		task.wait(0.05)
	end

	conn:Disconnect()
	return loaded
end

-- Returns the entire data table, or a specific key's value.
function DataService:get(player, key)
	local profile = self._profiles[player.UserId]
	if not profile then return nil end
	if key ~= nil then
		return profile.Data[key]
	end
	return profile.Data
end

-- Sets a key in the player's data.
function DataService:set(player, key, value)
	local profile = self._profiles[player.UserId]
	if not profile then
		warn("[DataService] set() called for unloaded player: " .. player.Name)
		return
	end
	profile.Data[key] = value
end

-- Increments a numeric key by `delta` (default 1). Returns new value.
function DataService:increment(player, key, delta)
	delta = delta or 1
	local profile = self._profiles[player.UserId]
	if not profile then return nil end
	local current = profile.Data[key] or 0
	profile.Data[key] = current + delta
	return profile.Data[key]
end

-- Returns true if the player's profile is currently loaded.
function DataService:isLoaded(player)
	return self._profiles[player.UserId] ~= nil
end

-- Manually triggers a save for a player (e.g. before teleport).
-- ProfileService auto-saves on release, so this is best-effort.
function DataService:save(player)
	local profile = self._profiles[player.UserId]
	if not profile then return end
	pcall(function()
		profile:Save()
	end)
end

-- ── Client-facing methods (auto-wired as RemoteFunctions by Knit) ─

-- Client calls this once on join to receive their full data snapshot.
function DataService.Client:GetPlayerData(player)
	self.Server:waitForLoad(player, 10)
	return self.Server:get(player)
end

return DataService
