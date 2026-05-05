-- ModuleScript: ReplicatedStorage/Shared/SharedConfig
-- Dev mode: references local ModuleScript instances directly.
-- After publishing each module as a Roblox asset, replace each value
-- with the numeric asset ID (e.g. AssetConfig = 1234567890).
-- Accessible from BOTH client and server.
--
-- Workflow to publish a shared module:
--   1. Right-click the ModuleScript in Studio → "Save to Roblox" → note the asset ID
--   2. Replace the Instance reference below with the numeric ID
--   3. Copy the updated SharedConfig to all 7 Places
--   After: require(SharedConfig.AssetConfig) works identically in all 7 Places.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
assert(Shared, "[SharedConfig] ReplicatedStorage.Shared not found — check Rojo sync")

local Config  = Shared:WaitForChild("Config", 10)
local Modules = Shared:WaitForChild("Modules", 10)

return {
	-- Core config (all 7 Places read from one published asset)
	AssetConfig      = Config:WaitForChild("AssetConfig", 10),

	-- Shared utility modules
	LocalizationUtil = Modules:WaitForChild("LocalizationUtil", 10),

	-- Future shared modules (add here after creating and publishing):
	-- StaminaModule   = Modules:WaitForChild("StaminaModule", 10),
	-- MoralityModule  = Modules:WaitForChild("MoralityModule", 10),
	-- QuestEngine     = Modules:WaitForChild("QuestEngine", 10),
	-- TaskEngine      = Modules:WaitForChild("TaskEngine", 10),
	-- InventoryModule = Modules:WaitForChild("InventoryModule", 10),
	-- CraftingModule  = Modules:WaitForChild("CraftingModule", 10),
}
