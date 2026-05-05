-- ModuleScript: ServerScriptService/Server/Services/CurrencyService
-- Manages Rupiah and Gold balances for all players.
-- All currency changes across the game go through this service.
-- format() is the canonical Indonesian number formatter shared with clients.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local VALID_TYPES = { Rupiah = true, Gold = true }

local CurrencyService = Knit.CreateService {
	Name   = "CurrencyService",
	Client = {
		CurrencyUpdate = Knit.CreateSignal(), -- server → client: (type, newBalance, formattedString)
	},

	_dataService = nil,
}

-- ── Formatting ────────────────────────────────────────────────────
-- Returns an Indonesian-style formatted string.
-- 12500 → "Rp 12.500"   |   1000000 → "Rp 1.000.000"   |   3 → "◆ 3"
local function formatAmount(amount, currencyType)
	local n = math.floor(math.abs(amount))
	local s = tostring(n)
	local len = #s
	local result = ""

	for i = 1, len do
		-- Insert dot separator before every group of 3 digits (from the right)
		if i > 1 and (len - i + 1) % 3 == 0 then
			result = result .. "."
		end
		result = result .. s:sub(i, i)
	end

	if amount < 0 then result = "-" .. result end

	if currencyType == "Gold" then
		return "◆ " .. result
	else
		return "Rp " .. result
	end
end

-- ── KnitInit ─────────────────────────────────────────────────────
function CurrencyService:KnitInit()
end

-- ── KnitStart ────────────────────────────────────────────────────
function CurrencyService:KnitStart()
	self._dataService = Knit.GetService("DataService")
end

-- ── Internal helper ───────────────────────────────────────────────
function CurrencyService:_fireUpdate(player, currencyType)
	local balance = self:get(player, currencyType)
	self.Client.CurrencyUpdate:Fire(player, currencyType, balance, formatAmount(balance, currencyType))
end

-- ── Public API ────────────────────────────────────────────────────

-- Returns current balance. type = "Rupiah" | "Gold".
function CurrencyService:get(player, currencyType)
	assert(VALID_TYPES[currencyType], "Invalid currency type: " .. tostring(currencyType))
	local key  = currencyType == "Gold" and "gold" or "rupiah"
	return self._dataService:get(player, key) or 0
end

-- Adds amount to balance. Negative values reduce it (but use spend() for validation).
function CurrencyService:add(player, currencyType, amount)
	assert(VALID_TYPES[currencyType], "Invalid currency type: " .. tostring(currencyType))
	local key     = currencyType == "Gold" and "gold" or "rupiah"
	local current = self._dataService:get(player, key) or 0
	self._dataService:set(player, key, math.max(0, current + amount))
	self:_fireUpdate(player, currencyType)
end

-- Attempts to deduct amount. Returns false if balance is insufficient.
-- Returns true on success (balance already deducted).
function CurrencyService:spend(player, currencyType, amount)
	assert(VALID_TYPES[currencyType], "Invalid currency type: " .. tostring(currencyType))
	if amount <= 0 then return true end

	local current = self:get(player, currencyType)
	if current < amount then
		return false
	end

	local key = currencyType == "Gold" and "gold" or "rupiah"
	self._dataService:set(player, key, current - amount)
	self:_fireUpdate(player, currencyType)
	return true
end

-- Convenience: formats a number without a player context (pure utility).
-- Accessible from client via the Client method below.
function CurrencyService.format(amount, currencyType)
	return formatAmount(amount, currencyType or "Rupiah")
end

-- ── Client-facing ─────────────────────────────────────────────────

-- Client requests current balance on join or after a transaction.
function CurrencyService.Client:GetBalance(player, currencyType)
	local balance = self.Server:get(player, currencyType or "Rupiah")
	return balance, formatAmount(balance, currencyType or "Rupiah")
end

-- Client can call format without knowing the logic (e.g. for UI display).
function CurrencyService.Client:FormatAmount(_player, amount, currencyType)
	return formatAmount(amount, currencyType or "Rupiah")
end

return CurrencyService
