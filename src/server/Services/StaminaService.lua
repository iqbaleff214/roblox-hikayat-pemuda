-- ModuleScript: ServerScriptService/Server/Services/StaminaService
-- Manages per-player stamina entirely server-side.
-- Other services call spend() / restore(). Client receives updates via signals.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local MAX        = AssetConfig.Stamina.Max
local REGEN_RATE = AssetConfig.Stamina.RegenRate

-- Seconds after last spend before regen kicks in
local REGEN_DELAY = 0.5

local StaminaService = Knit.CreateService {
	Name   = "StaminaService",
	Client = {
		StaminaUpdate   = Knit.CreateSignal(), -- server → client: (value: number)
		StaminaDepleted = Knit.CreateSignal(), -- server → client: () — triggers red vignette
		StaminaTooLow   = Knit.CreateSignal(), -- server → client: () — attack rejected
	},

	_stamina   = {}, -- { [userId] = currentValue }
	_lastSpend = {}, -- { [userId] = tick() of last spend call }
}

-- ── Private ───────────────────────────────────────────────────────
function StaminaService:_initPlayer(player)
	local userId = player.UserId
	self._stamina[userId]   = MAX
	self._lastSpend[userId] = 0
	-- Send initial value so HUD renders correctly on join
	self.Client.StaminaUpdate:Fire(player, MAX)
end

function StaminaService:_cleanPlayer(player)
	self._stamina[player.UserId]   = nil
	self._lastSpend[player.UserId] = nil
end

-- ── KnitInit ─────────────────────────────────────────────────────
function StaminaService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
		self:_initPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_cleanPlayer(player)
	end)

	for _, player in Players:GetPlayers() do
		self:_initPlayer(player)
	end
end

-- ── KnitStart ────────────────────────────────────────────────────
function StaminaService:KnitStart()
	-- Regen loop: runs every 1 second, regenerates stamina for idle players.
	task.spawn(function()
		while true do
			task.wait(1)
			local now = tick()
			for _, player in Players:GetPlayers() do
				local userId  = player.UserId
				local current = self._stamina[userId]
				if current == nil then continue end

				local sinceLastSpend = now - (self._lastSpend[userId] or 0)
				if sinceLastSpend > REGEN_DELAY and current < MAX then
					local newVal = math.min(current + REGEN_RATE, MAX)
					self._stamina[userId] = newVal
					self.Client.StaminaUpdate:Fire(player, newVal)
				end
			end
		end
	end)
end

-- ── Public API (called by other server Services) ──────────────────

-- Deducts `amount` from the player's stamina.
-- Returns true on success, false if insufficient (also fires StaminaTooLow).
function StaminaService:spend(player, amount)
	local userId  = player.UserId
	local current = self._stamina[userId]
	if current == nil then return false end

	if current < amount then
		self.Client.StaminaTooLow:Fire(player)
		return false
	end

	local newVal = current - amount
	self._stamina[userId]   = newVal
	self._lastSpend[userId] = tick()
	self.Client.StaminaUpdate:Fire(player, newVal)

	if newVal <= 0 then
		self.Client.StaminaDepleted:Fire(player)
	end

	return true
end

-- Adds `amount` to the player's stamina, capped at Max.
-- Called by InventoryService when player consumes food/drink.
function StaminaService:restore(player, amount)
	local userId = player.UserId
	if not self._stamina[userId] then return end
	local newVal = math.min((self._stamina[userId] or 0) + amount, MAX)
	self._stamina[userId] = newVal
	self.Client.StaminaUpdate:Fire(player, newVal)
end

-- Deducts sprint cost per second while player is sprinting.
-- Called by CombatController's SprintStarted / SprintEnded signals.
function StaminaService:spendSprint(player)
	return self:spend(player, AssetConfig.Stamina.SprintCost)
end

-- Returns current stamina value (used by CombatService for validation).
function StaminaService:get(player)
	return self._stamina[player.UserId] or 0
end

-- Force-sets stamina to a specific value (used on respawn: restore 50%).
function StaminaService:set(player, value)
	local userId = player.UserId
	if not self._stamina[userId] then return end
	self._stamina[userId] = math.clamp(value, 0, MAX)
	self.Client.StaminaUpdate:Fire(player, self._stamina[userId])
end

return StaminaService
