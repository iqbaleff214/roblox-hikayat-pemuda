-- LocalScript: StarterPlayerScripts/Client/Main
-- Single client entry point. Loads all Knit Controllers then starts Knit.
-- This file is identical in all 7 island Places.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

-- ── Load Controllers ──────────────────────────────────────────────
-- Phase 1: Core Mechanics
local Controllers = script.Parent:WaitForChild("Controllers")
require(Controllers:WaitForChild("InventoryController"))
require(Controllers:WaitForChild("HotbarController"))
require(Controllers:WaitForChild("CombatController"))

-- Phase 3: NPC & Dialog
require(Controllers:WaitForChild("DialogController"))

-- Phase 4+:
-- require(Controllers:WaitForChild("QuestController"))
-- require(Controllers:WaitForChild("TaskController"))

-- Phase 5+:
-- require(Controllers:WaitForChild("MoralityController"))
-- require(Controllers:WaitForChild("AchievementController"))

-- Phase 6+:
-- require(Controllers:WaitForChild("ZoneController"))
-- require(Controllers:WaitForChild("TravelController"))

-- Phase 7 UI:
-- require(Controllers:WaitForChild("HUDController"))
-- require(Controllers:WaitForChild("ShopController"))
-- require(Controllers:WaitForChild("GaleriController"))

-- Phase 9:
-- require(Controllers:WaitForChild("AudioController"))

-- ── Start Knit ────────────────────────────────────────────────────
Knit.Start():andThen(function()
	print("[Main.client] Knit controllers ready.")
end):catch(function(err)
	warn("[Main.client] Knit failed to start: " .. tostring(err))
end)
