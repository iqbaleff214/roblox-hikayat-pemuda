-- ModuleScript: ServerScriptService/Server/Services/NPCService
-- Spawns NPCs from AssetConfig, manages daily schedules, and routes dialog.
-- ProximityPrompts added by script — no manual NPC placement in Studio needed.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local InsertService     = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)
local DialogTrees = require(ReplicatedStorage:WaitForChild("Shared").Config.DialogTrees)

local WIB_OFFSET        = 7   -- UTC+7
local SCHEDULE_INTERVAL = 60  -- seconds between schedule checks
local PROMPT_DISTANCE   = 8   -- studs for ProximityPrompt
local TWEEN_INFO        = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- Safe dispatch table for dialog node onEnter actions.
-- Wraps service calls in pcall so missing services (e.g., QuestService in Phase 3)
-- do not break dialog flow.
local ON_ENTER_DISPATCH = {
	QuestService = {
		triggerCheck = function(player, ...)
			local args = { ... }
			pcall(function()
				Knit.GetService("QuestService"):triggerCheck(player, table.unpack(args))
			end)
		end,
		offerQuest = function(player, ...)
			local args = { ... }
			pcall(function()
				Knit.GetService("QuestService"):offerQuest(player, table.unpack(args))
			end)
		end,
	},
}

local NPCService = Knit.CreateService {
	Name   = "NPCService",
	Client = {
		DialogOpen   = Knit.CreateSignal(), -- server → client: (npcId, nodeData)
		DialogClose  = Knit.CreateSignal(), -- server → client: ()
		DialogChoice = Knit.CreateSignal(), -- client → server: (npcId, choiceIndex)
	},

	_npcInstances = nil, -- { [npcId] = model }
	_sessions     = nil, -- { [userId] = { npcId, nodeId } }
	_dataService  = nil,
	_shopService  = nil,
}

-- ── Schedule helpers ──────────────────────────────────────────────

local function currentHourWIB()
	return (math.floor(os.time() / 3600) + WIB_OFFSET) % 24
end

-- True if the schedule entry's time window covers the given hour.
local function scheduleCovers(entry, hour)
	if entry.from <= entry.to then
		return hour >= entry.from and hour < entry.to
	end
	-- Overnight wrap (e.g. from=20, to=6 means 20:00–06:00)
	return hour >= entry.from or hour < entry.to
end

local function activeEntry(npcCfg, hour)
	for _, entry in npcCfg.schedule do
		if scheduleCovers(entry, hour) then
			return entry
		end
	end
	return npcCfg.schedule[1]
end

-- ── Location helpers ──────────────────────────────────────────────

-- Searches workspace/Map/Zones/<zoneName>/<locationName> for a Part or Attachment.
local function findLocationPart(zoneName, locationName)
	local map   = workspace:FindFirstChild("Map")
	local zones = map and map:FindFirstChild("Zones")
	local zone  = zones and zones:FindFirstChild(zoneName)
	if zone then
		return zone:FindFirstChild(locationName, true)
	end
	return nil
end

-- ── NPC model helpers ─────────────────────────────────────────────

-- Minimal placeholder model used when the real asset ID is 0 (dev mode).
local function createPlaceholderModel(npcId)
	local model    = Instance.new("Model")
	model.Name     = npcId

	local root           = Instance.new("Part")
	root.Name            = "HumanoidRootPart"
	root.Size            = Vector3.new(2, 2, 1)
	root.Anchored        = true
	root.CanCollide      = false
	root.BrickColor      = BrickColor.new("Bright blue")
	root.Parent          = model
	model.PrimaryPart    = root

	Instance.new("Humanoid").Parent = model
	return model
end

-- Attempt to load model from Roblox asset ID; falls back to placeholder.
local function loadNPCModel(npcId, modelId)
	local numId = modelId and tonumber(tostring(modelId):match("%d+"))
	if numId and numId > 0 then
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(numId)
		end)
		if ok and asset then
			local m = asset:FindFirstChildOfClass("Model")
			if m then
				m.Name = npcId
				m.Parent = nil
				asset:Destroy()
				return m
			end
			asset:Destroy()
		end
	end
	return createPlaceholderModel(npcId)
end

-- ── Dialog helpers ────────────────────────────────────────────────

-- Filter choices by player morality; preserve original choice index for server routing.
local function filterChoices(choices, morality)
	local filtered = {}
	for idx, choice in choices do
		local pass = true
		if choice.minMorality and morality < choice.minMorality then
			pass = false
		end
		if choice.maxMorality and morality > choice.maxMorality then
			pass = false
		end
		if pass then
			filtered[#filtered + 1] = { labelKey = choice.labelKey, choiceIndex = idx }
		end
	end
	return filtered
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function NPCService:KnitInit()
	self._npcInstances = {}
	self._sessions     = {}
end

function NPCService:KnitStart()
	self._dataService = Knit.GetService("DataService")
	self._shopService = Knit.GetService("ShopService")

	self:_spawnAll()
	self:_startScheduleLoop()

	self.Client.DialogChoice:Connect(function(player, npcId, choiceIndex)
		self:_handleChoice(player, npcId, choiceIndex)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._sessions[player.UserId] = nil
	end)
end

-- ── NPC Spawning ──────────────────────────────────────────────────

function NPCService:_spawnAll()
	local npcFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("NPCs")

	for npcId, npcCfg in AssetConfig.NPCs do
		local model   = loadNPCModel(npcId, npcCfg.modelId)
		local entry   = npcCfg.schedule and npcCfg.schedule[1]
		local locPart = entry and findLocationPart(npcCfg.zone, entry.location)
		local spawnCF = locPart and locPart.CFrame
			or CFrame.new(math.random(-30, 30), 5, math.random(-30, 30))

		if model.PrimaryPart then
			model.PrimaryPart.CFrame = spawnCF
		end
		model.Parent = npcFolder or workspace

		self:_addNameTag(model, npcCfg)
		self:_addProximityPrompts(model, npcId, npcCfg)

		self._npcInstances[npcId] = model
	end
end

function NPCService:_addNameTag(model, npcCfg)
	local anchor = model:FindFirstChild("Head") or model.PrimaryPart
	if not anchor then return end

	local billboard             = Instance.new("BillboardGui")
	billboard.Name              = "NameTag"
	billboard.Size              = UDim2.fromOffset(120, 30)
	billboard.StudsOffset       = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop       = false
	billboard.Parent            = anchor

	local label                 = Instance.new("TextLabel")
	label.Size                  = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3            = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Font                  = Enum.Font.GothamBold
	label.TextScaled            = true
	label.Text                  = npcCfg.id -- localization applied client-side
	label.Parent                = billboard
end

function NPCService:_addProximityPrompts(model, npcId, npcCfg)
	local root = model.PrimaryPart
	if not root then return end

	local talkPrompt                    = Instance.new("ProximityPrompt")
	talkPrompt.ActionText               = "Bicara"
	talkPrompt.MaxActivationDistance    = PROMPT_DISTANCE
	talkPrompt.KeyboardKeyCode          = Enum.KeyCode.E
	talkPrompt.Parent                   = root

	talkPrompt.Triggered:Connect(function(player)
		self:_startDialog(player, npcId)
	end)

	if npcCfg.shopId then
		local shopPrompt                    = Instance.new("ProximityPrompt")
		shopPrompt.ActionText               = "Beli"
		shopPrompt.MaxActivationDistance    = PROMPT_DISTANCE
		shopPrompt.KeyboardKeyCode          = Enum.KeyCode.F
		shopPrompt.Parent                   = root

		shopPrompt.Triggered:Connect(function(player)
			self._shopService:openFor(player, npcCfg.shopId)
		end)
	end
end

-- ── Schedule Loop ─────────────────────────────────────────────────

function NPCService:_startScheduleLoop()
	task.spawn(function()
		while true do
			task.wait(SCHEDULE_INTERVAL)
			local hour = currentHourWIB()

			for npcId, npcCfg in AssetConfig.NPCs do
				local model = self._npcInstances[npcId]
				if model and model.Parent and model.PrimaryPart then
					local entry   = activeEntry(npcCfg, hour)
					local locPart = entry and findLocationPart(npcCfg.zone, entry.location)
					if locPart then
						TweenService:Create(model.PrimaryPart, TWEEN_INFO, {
							CFrame = locPart.CFrame
						}):Play()
					end
				end
			end
		end
	end)
end

-- ── Dialog Routing ────────────────────────────────────────────────

function NPCService:_startDialog(player, npcId)
	local npcCfg = AssetConfig.NPCs[npcId]
	if not npcCfg or not npcCfg.dialogTree then return end

	local tree = DialogTrees[npcCfg.dialogTree]
	if not tree then return end

	self._sessions[player.UserId] = { npcId = npcId, nodeId = tree.root }
	self:_sendNode(player, npcId, tree.root)

	-- Quest / Task: talking to this NPC + checking any delivery objectives
	pcall(function()
		Knit.GetService("QuestService"):triggerCheck(player, "Talk", npcId)
	end)
	pcall(function()
		Knit.GetService("QuestService"):triggerCheck(player, "Deliver", npcId)
	end)
	pcall(function()
		Knit.GetService("TaskService"):triggerCheck(player, "Talk", npcId)
	end)
end

function NPCService:_sendNode(player, npcId, nodeId)
	local npcCfg = AssetConfig.NPCs[npcId]
	if not npcCfg then return end

	local tree = DialogTrees[npcCfg.dialogTree]
	if not tree then return end

	local node = nodeId and tree.nodes[nodeId]
	if not node then
		self._sessions[player.UserId] = nil
		self.Client.DialogClose:Fire(player)
		return
	end

	-- Run onEnter side effect (safe dispatch — no loadstring)
	if node.onEnter then
		local dispatch = ON_ENTER_DISPATCH[node.onEnter.service]
		if dispatch and dispatch[node.onEnter.method] then
			dispatch[node.onEnter.method](player, table.unpack(node.onEnter.args or {}))
		end
	end

	local data     = self._dataService:get(player)
	local morality = data and data.morality or 50

	self.Client.DialogOpen:Fire(player, npcId, {
		speaker = node.speaker,
		textKey = node.textKey,
		choices = filterChoices(node.choices or {}, morality),
	})
end

function NPCService:_handleChoice(player, npcId, choiceIndex)
	local session = self._sessions[player.UserId]
	if not session or session.npcId ~= npcId then return end

	local npcCfg = AssetConfig.NPCs[npcId]
	if not npcCfg then return end

	local tree = DialogTrees[npcCfg.dialogTree]
	if not tree then return end

	local node = tree.nodes[session.nodeId]
	if not node or not node.choices then return end

	local choice = node.choices[choiceIndex]
	if not choice then return end

	if choice.next then
		session.nodeId = choice.next
		self:_sendNode(player, npcId, choice.next)
	else
		self._sessions[player.UserId] = nil
		self.Client.DialogClose:Fire(player)
	end
end

-- ── Public API ────────────────────────────────────────────────────

-- Returns the live NPC model instance, or nil if not spawned.
function NPCService:getNPC(npcId)
	return self._npcInstances[npcId]
end

return NPCService
