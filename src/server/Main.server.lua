-- Script: ServerScriptService/Server/Main
-- Single server entry point for all Places.
-- 1. Creates folder/remote hierarchy (Bootstrap step).
-- 2. Loads all Knit Services.
-- 3. Starts Knit.
-- This file is identical in all 7 island Places — no per-Place changes needed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

-- ── Step 1: Folder & Remote hierarchy ────────────────────────────
-- Creates all required folders and RemoteEvents/RemoteFunctions so
-- other services can reference them without worrying about ordering.

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

-- ReplicatedStorage folders
local repRemotes = ensureFolder(ReplicatedStorage, "RemoteEvents")
ensureFolder(ReplicatedStorage, "Config")
ensureFolder(ReplicatedStorage, "Modules")

-- Workspace folders for runtime objects
local mapFolder = ensureFolder(workspace, "Map")
ensureFolder(mapFolder, "Zones")
ensureFolder(mapFolder, "NPCs")
ensureFolder(mapFolder, "Props")

-- RemoteEvents (client↔server)
local REMOTE_EVENTS = {
	-- Core
	"ZoneChanged",
	"ZoneUnlocked",
	"MoralityChanged",
	"GameTimeUpdate",
	-- Inventory & Hotbar
	"SyncInventory",
	"UpdateHotbar",
	"HotbarUpgrade",
	"WeaponEquipped",
	-- Combat
	"CombatHit",
	"StaminaUpdate",
	"StaminaDepleted",
	"StatusEffectApply",
	-- Quest & Tasks
	"QuestUpdate",
	"TaskUpdate",
	-- Shop & Economy
	"OpenShop",
	-- Social & Progression
	"AchievementUnlocked",
	"LoginStreakClaimed",
	-- UI panels
	"DialogOpen",
	"OpenGaleri",
	"OpenTravelMap",
	-- Travel
	"TeleportToPlace",
	-- World
	"WorldEventSpawn",
}

for _, name in REMOTE_EVENTS do
	if not repRemotes:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = repRemotes
	end
end

-- RemoteFunctions (Knit wires its own, but non-Knit ones go here)
-- NOTE: Knit auto-creates RemoteFunctions for Client methods.
-- Additional non-Knit RFs (if any future system needs them):
local REMOTE_FUNCTIONS = {
	-- "ExampleRF",
}

for _, name in REMOTE_FUNCTIONS do
	if not repRemotes:FindFirstChild(name) then
		local rf = Instance.new("RemoteFunction")
		rf.Name = name
		rf.Parent = repRemotes
	end
end

-- ── Step 2: Load Services ─────────────────────────────────────────
-- Require every service so Knit registers them before Knit.Start().
-- Services are loaded in dependency order (dependencies first).

local Services = script.Parent:WaitForChild("Services")

-- Phase 0: Foundation
require(Services:WaitForChild("DataService"))
require(Services:WaitForChild("GameService"))

-- Phase 1: Core Mechanics
require(Services:WaitForChild("StaminaService"))
require(Services:WaitForChild("CurrencyService"))
require(Services:WaitForChild("InventoryService"))
require(Services:WaitForChild("CombatService"))

-- Phase 2: Economy
require(Services:WaitForChild("ShopService"))
require(Services:WaitForChild("CraftingService"))

-- Phase 3: NPC & Dialog
require(Services:WaitForChild("NPCService"))

-- Phase 4: Quest & Task Systems
require(Services:WaitForChild("QuestService"))
require(Services:WaitForChild("TaskService"))

-- Phase 5: Morality & Progression
require(Services:WaitForChild("AchievementService"))
require(Services:WaitForChild("LoginStreakService"))

-- Phase 6: World & Travel
require(Services:WaitForChild("ZoneService"))
require(Services:WaitForChild("TravelService"))
require(Services:WaitForChild("WorldEventService"))
require(Services:WaitForChild("DayNightService"))

-- Future services (uncomment as implemented):
-- require(Services:WaitForChild("ZoneService"))
-- require(Services:WaitForChild("TravelService"))
-- require(Services:WaitForChild("RelationshipService"))
-- require(Services:WaitForChild("LeaderboardService"))
-- require(Services:WaitForChild("EventService"))
-- require(Services:WaitForChild("AudioService"))

-- ── Step 3: Start Knit ────────────────────────────────────────────
Knit.Start():andThen(function()
	print("[Main] Knit started — all services ready.")
end):catch(function(err)
	warn("[Main] Knit failed to start: " .. tostring(err))
end)
