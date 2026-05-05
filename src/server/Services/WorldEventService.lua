-- ModuleScript: ServerScriptService/Server/Services/WorldEventService
-- Spawns random world events in zones where players are present.
-- Max one active event per zone at a time. Events auto-clean on timeout or resolution.
-- Fires WorldEventSpawn to all players in the affected zone.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit           = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig    = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)
local MoralityModule = require(ReplicatedStorage:WaitForChild("Shared").Modules.MoralityModule)

local SPAWN_CHECK_INTERVAL = 300 -- 5 minutes between event spawn cycles

local WorldEventService = Knit.CreateService {
	Name   = "WorldEventService",
	Client = {
		WorldEventSpawn = Knit.CreateSignal(), -- server → client: (zoneId, { id, nameKey })
		WorldEventEnd   = Knit.CreateSignal(), -- server → client: (zoneId, { outcome, eventId })
	},

	_dataService      = nil,
	_inventoryService = nil,
	_currencyService  = nil,
	_zoneService      = nil,
	_activeEvents     = {}, -- [zoneId] = { eventId, cleanupTask }
}

-- ── Weighted random event selection ──────────────────────────────

local function pickEvent()
	local total = 0
	for _, e in AssetConfig.WorldEvents do
		total += e.weight
	end
	local r   = math.random() * total
	local cum = 0
	for _, e in AssetConfig.WorldEvents do
		cum += e.weight
		if r <= cum then
			return e
		end
	end
	return AssetConfig.WorldEvents[1]
end

-- ── Zone center helper ────────────────────────────────────────────

local function getZoneCenter(zoneId)
	local map     = workspace:FindFirstChild("Map")
	local zones   = map and map:FindFirstChild("Zones")
	local folder  = zones and zones:FindFirstChild(zoneId)
	local boundary = folder and folder:FindFirstChild("ZoneBoundary")
	if boundary and boundary:IsA("BasePart") then
		return boundary.Position
	end
	return Vector3.new(0, 50, 0)
end

-- ── Reward: grants rupiah and morality to all players in zone ─────

function WorldEventService:_rewardZone(zoneId, rupiahAmount, moralityDelta)
	for _, player in self._zoneService:getPlayersInZone(zoneId) do
		if rupiahAmount and rupiahAmount > 0 then
			self._currencyService:add(player, "Rupiah", rupiahAmount)
		end
		if moralityDelta and moralityDelta ~= 0 then
			MoralityModule.apply(player, moralityDelta)
		end
	end
end

-- ── Placeholder enemy model factory ──────────────────────────────

local function spawnEnemy(name, color, health, position)
	local model   = Instance.new("Model")
	model.Name    = name

	local torso   = Instance.new("Part")
	torso.Name        = "HumanoidRootPart"
	torso.Size        = Vector3.new(2, 2, 1)
	torso.BrickColor  = BrickColor.new(color)
	torso.Anchored    = false
	torso.CFrame      = CFrame.new(position)
	torso.Parent      = model

	local humanoid    = Instance.new("Humanoid")
	humanoid.Health    = health
	humanoid.MaxHealth = health
	humanoid.Parent    = model

	model.PrimaryPart = torso
	model.Parent      = workspace
	return model, humanoid
end

local function destroyAll(list)
	for _, obj in list do
		if obj and obj.Parent then
			obj:Destroy()
		end
	end
end

-- ── Event: MerchantAttacked ───────────────────────────────────────

function WorldEventService:_spawnMerchantAttacked(zoneId, eventCfg)
	local center  = getZoneCenter(zoneId)
	local bandits = {}
	local killed  = 0

	for i = 1, eventCfg.banditCount do
		local offset = Vector3.new(math.random(-5, 5), 3, math.random(-5, 5))
		local model, humanoid = spawnEnemy("Bandit_" .. i, "Bright red", 60, center + offset)
		bandits[#bandits + 1] = model

		local conn
		conn = humanoid.Died:Connect(function()
			conn:Disconnect()
			killed += 1
			if killed < eventCfg.banditCount then return end

			self:_rewardZone(zoneId, eventCfg.rupiahReward, eventCfg.moralityReward)
			destroyAll(bandits)
			self._activeEvents[zoneId] = nil

			for _, pl in self._zoneService:getPlayersInZone(zoneId) do
				pcall(function()
					Knit.GetService("AchievementService"):check(pl, "Combat")
				end)
			end

			self.Client.WorldEventEnd:FireAll(zoneId, {
				outcome = "success",
				eventId = eventCfg.id,
			})
		end)
	end

	local cleanupTask = task.delay(eventCfg.duration, function()
		if not self._activeEvents[zoneId] then return end
		destroyAll(bandits)
		self._activeEvents[zoneId] = nil
		self.Client.WorldEventEnd:FireAll(zoneId, {
			outcome = "expired",
			eventId = eventCfg.id,
		})
	end)

	return { cleanupTask = cleanupTask }
end

-- ── Event: RareIngredientSpawn ────────────────────────────────────

function WorldEventService:_spawnRareIngredient(zoneId, eventCfg)
	local center = getZoneCenter(zoneId)

	local part        = Instance.new("Part")
	part.Name         = "RareIngredient_WorldEvent"
	part.Size         = Vector3.new(1, 1, 1)
	part.Shape        = Enum.PartType.Ball
	part.Material     = Enum.Material.Neon
	part.BrickColor   = BrickColor.new("Bright yellow")
	part.Anchored     = true
	part.CanCollide   = false
	part.CFrame       = CFrame.new(center + Vector3.new(0, 2, 0))
	part.Parent       = workspace

	local claimed = false
	local touchConn
	touchConn = part.Touched:Connect(function(hit)
		if claimed then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end

		claimed = true
		touchConn:Disconnect()

		pcall(function()
			self._inventoryService:addItem(player, eventCfg.itemId, 1)
		end)

		if part.Parent then
			part:Destroy()
		end

		self._activeEvents[zoneId] = nil
		self.Client.WorldEventEnd:FireAll(zoneId, {
			outcome = "claimed",
			eventId = eventCfg.id,
		})
	end)

	local cleanupTask = task.delay(eventCfg.duration, function()
		if not self._activeEvents[zoneId] then return end
		touchConn:Disconnect()
		if part.Parent then
			part:Destroy()
		end
		self._activeEvents[zoneId] = nil
		self.Client.WorldEventEnd:FireAll(zoneId, {
			outcome = "expired",
			eventId = eventCfg.id,
		})
	end)

	return { cleanupTask = cleanupTask }
end

-- ── Event: NPCDistress ────────────────────────────────────────────

function WorldEventService:_spawnNPCDistress(zoneId, eventCfg)
	local map        = workspace:FindFirstChild("Map")
	local npcsFolder = map and map:FindFirstChild("NPCs")
	local target     = nil

	if npcsFolder then
		for _, npcModel in npcsFolder:GetChildren() do
			local npcId  = npcModel:GetAttribute("NPCId")
			local npcCfg = npcId and AssetConfig.NPCs[npcId]
			if npcCfg and npcCfg.zone == zoneId
				and (not npcCfg.npcType or npcCfg.npcType ~= "Enemy")
			then
				target = npcModel
				break
			end
		end
	end

	local cleanup = {}

	if target and target.PrimaryPart then
		local billboard           = Instance.new("BillboardGui")
		billboard.Name            = "DistressGui"
		billboard.Size            = UDim2.fromOffset(40, 40)
		billboard.StudsOffset     = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop     = false
		billboard.Parent          = target.PrimaryPart

		local label               = Instance.new("TextLabel")
		label.Size                = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text                = "!"
		label.TextScaled          = true
		label.TextColor3          = Color3.fromRGB(255, 60, 60)
		label.Font                = Enum.Font.GothamBold
		label.Parent              = billboard

		cleanup[#cleanup + 1] = billboard

		local prompt              = Instance.new("ProximityPrompt")
		prompt.ActionText         = "Bantu"
		prompt.KeyboardKeyCode    = Enum.KeyCode.F
		prompt.MaxActivationDistance = 8
		prompt.Parent             = target.PrimaryPart

		cleanup[#cleanup + 1] = prompt

		local helped = false
		prompt.Triggered:Connect(function(player)
			if helped then return end
			helped = true

			self._currencyService:add(player, "Rupiah", eventCfg.rupiahReward)
			MoralityModule.apply(player, eventCfg.moralityReward)
			destroyAll(cleanup)
			self._activeEvents[zoneId] = nil
			self.Client.WorldEventEnd:FireAll(zoneId, {
				outcome = "helped",
				eventId = eventCfg.id,
			})
		end)
	end

	local cleanupTask = task.delay(eventCfg.duration, function()
		if not self._activeEvents[zoneId] then return end
		destroyAll(cleanup)
		self._activeEvents[zoneId] = nil
		self.Client.WorldEventEnd:FireAll(zoneId, {
			outcome = "expired",
			eventId = eventCfg.id,
		})
	end)

	return { cleanupTask = cleanupTask }
end

-- ── Event: PoacherCamp ────────────────────────────────────────────

function WorldEventService:_spawnPoacherCamp(zoneId, eventCfg)
	local center  = getZoneCenter(zoneId)
	local poachers = {}
	local killed   = 0

	for i = 1, eventCfg.poacherCount do
		local offset = Vector3.new(math.random(-8, 8), 3, math.random(-8, 8))
		local model, humanoid = spawnEnemy("Poacher_" .. i, "Dark orange", 80, center + offset)
		poachers[#poachers + 1] = model

		local conn
		conn = humanoid.Died:Connect(function()
			conn:Disconnect()
			killed += 1

			for _, pl in self._zoneService:getPlayersInZone(zoneId) do
				pcall(function()
					Knit.GetService("AchievementService"):check(pl, "Combat")
				end)
			end

			if killed < eventCfg.poacherCount then return end

			self:_rewardZone(zoneId, eventCfg.rupiahReward, eventCfg.moralityReward)
			destroyAll(poachers)
			self._activeEvents[zoneId] = nil
			self.Client.WorldEventEnd:FireAll(zoneId, {
				outcome = "cleared",
				eventId = eventCfg.id,
			})
		end)
	end

	local cleanupTask = task.delay(eventCfg.duration, function()
		if not self._activeEvents[zoneId] then return end
		destroyAll(poachers)
		self._activeEvents[zoneId] = nil
		self.Client.WorldEventEnd:FireAll(zoneId, {
			outcome = "expired",
			eventId = eventCfg.id,
		})
	end)

	return { cleanupTask = cleanupTask }
end

-- ── Event spawner dispatch ────────────────────────────────────────

function WorldEventService:_spawnEvent(zoneId)
	if self._activeEvents[zoneId] then return end

	local eventCfg = pickEvent()
	local state

	if eventCfg.id == "MerchantAttacked" then
		state = self:_spawnMerchantAttacked(zoneId, eventCfg)
	elseif eventCfg.id == "RareIngredientSpawn" then
		state = self:_spawnRareIngredient(zoneId, eventCfg)
	elseif eventCfg.id == "NPCDistress" then
		state = self:_spawnNPCDistress(zoneId, eventCfg)
	elseif eventCfg.id == "PoacherCamp" then
		state = self:_spawnPoacherCamp(zoneId, eventCfg)
	end

	if not state then return end

	state.eventId             = eventCfg.id
	self._activeEvents[zoneId] = state

	for _, player in self._zoneService:getPlayersInZone(zoneId) do
		self.Client.WorldEventSpawn:Fire(player, zoneId, {
			id      = eventCfg.id,
			nameKey = eventCfg.nameKey,
		})
	end
end

-- ── Main check loop ───────────────────────────────────────────────

function WorldEventService:_checkZones()
	for zoneId in AssetConfig.Zones do
		if self._activeEvents[zoneId] then continue end
		if #self._zoneService:getPlayersInZone(zoneId) == 0 then continue end
		self:_spawnEvent(zoneId)
	end
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function WorldEventService:KnitInit()
end

function WorldEventService:KnitStart()
	self._dataService      = Knit.GetService("DataService")
	self._inventoryService = Knit.GetService("InventoryService")
	self._currencyService  = Knit.GetService("CurrencyService")
	self._zoneService      = Knit.GetService("ZoneService")

	task.spawn(function()
		while true do
			task.wait(SPAWN_CHECK_INTERVAL)
			self:_checkZones()
		end
	end)
end

return WorldEventService
