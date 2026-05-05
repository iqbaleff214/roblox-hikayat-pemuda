-- ModuleScript: ReplicatedStorage/Shared/Modules/MoralityModule
-- getTier() is pure and safe to call from client or server.
-- apply() and get() are server-only (defined only when RunService:IsServer()).

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local MoralityModule = {}

-- Pure: returns the matching tier table for a morality value (0–100).
function MoralityModule.getTier(value)
	return AssetConfig.getMoralityTier(value)
end

-- ── Server-only functions ─────────────────────────────────────────
-- These are only defined when running on the server; calling them on the
-- client will error, which is the intended guard against misuse.

if RunService:IsServer() then
	local Knit             = require(ReplicatedStorage:WaitForChild("Packages").Knit)
	local moralityChangedRE = ReplicatedStorage
		:WaitForChild("RemoteEvents")
		:WaitForChild("MoralityChanged")

	local _dataService = nil
	local function ds()
		if not _dataService then
			_dataService = Knit.GetService("DataService")
		end
		return _dataService
	end

	-- Apply a morality delta: clamps to 0–100, persists, fires MoralityChanged to client.
	-- Also triggers AchievementService check (Phase 5+).
	function MoralityModule.apply(player, delta)
		local data = ds():get(player)
		if not data then return end

		local newValue = math.clamp((data.morality or 50) + delta, 0, 100)
		data.morality  = newValue

		local tier = AssetConfig.getMoralityTier(newValue)
		moralityChangedRE:FireClient(player, {
			value    = newValue,
			delta    = delta,
			tier     = tier,
			labelKey = tier.labelKey,
			color    = tier.color,
		})

		pcall(function()
			Knit.GetService("AchievementService"):check(player, "Morality")
		end)
	end

	-- Returns the player's current morality value (default 50 if not loaded).
	function MoralityModule.get(player)
		local data = ds():get(player)
		return data and data.morality or 50
	end
end

return MoralityModule
