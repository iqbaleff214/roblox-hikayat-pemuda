-- LocalScript: StarterPlayerScripts/Client/Controllers/HUDController
-- Always-visible HUD: stamina bar, morality tier, currency, quest objective,
-- directional compass, hotbar (4-8 slots). All positions use UDim2 scale values.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local HUDController = Knit.CreateController { Name = "HUDController" }

-- ── Module state ──────────────────────────────────────────────────

local _hud               = nil
local _hotbarSlots       = {}
local _hotbarSize        = 4
local _hotbarController  = nil
local _inventoryController = nil
local _questController   = nil

local _rupiah = 0
local _gold   = 0

-- ── UI construction ───────────────────────────────────────────────

local function buildHUD()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "HUDGui"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = false
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Parent             = playerGui

	-- ── Top-left: Quest Objective ──────────────────────────────
	local questFrame              = Instance.new("TextButton")
	questFrame.Name               = "QuestObjective"
	questFrame.Size               = UDim2.new(0.34, 0, 0.075, 0)
	questFrame.Position           = UDim2.new(0, 8, 0, 8)
	questFrame.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
	questFrame.BackgroundTransparency = 0.55
	questFrame.BorderSizePixel    = 0
	questFrame.AutoButtonColor    = false
	questFrame.Text               = ""
	questFrame.ZIndex             = 2
	questFrame.Parent             = sg

	local qCorner       = Instance.new("UICorner")
	qCorner.CornerRadius = UDim.new(0, 6)
	qCorner.Parent       = questFrame

	local questLabel              = Instance.new("TextLabel")
	questLabel.Name               = "QuestLabel"
	questLabel.Size               = UDim2.new(1, -16, 1, 0)
	questLabel.Position           = UDim2.fromOffset(8, 0)
	questLabel.BackgroundTransparency = 1
	questLabel.Font               = Enum.Font.Gotham
	questLabel.TextSize           = 12
	questLabel.TextColor3         = Color3.fromRGB(220, 220, 180)
	questLabel.TextXAlignment     = Enum.TextXAlignment.Left
	questLabel.TextYAlignment     = Enum.TextYAlignment.Center
	questLabel.TextWrapped        = true
	questLabel.Text               = "—"
	questLabel.ZIndex             = 3
	questLabel.Parent             = questFrame

	-- ── Top-center: Compass ────────────────────────────────────
	local compassOuter              = Instance.new("Frame")
	compassOuter.Name               = "Compass"
	compassOuter.Size               = UDim2.new(0.08, 0, 0.07, 0)
	compassOuter.AnchorPoint        = Vector2.new(0.5, 0)
	compassOuter.Position           = UDim2.new(0.5, 0, 0, 8)
	compassOuter.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
	compassOuter.BackgroundTransparency = 0.55
	compassOuter.BorderSizePixel    = 0
	compassOuter.ClipsDescendants   = false
	compassOuter.ZIndex             = 2
	compassOuter.Parent             = sg

	local compassCircle       = Instance.new("UICorner")
	compassCircle.CornerRadius = UDim.new(0.5, 0)
	compassCircle.Parent       = compassOuter

	-- Cardinal ring (non-rotating)
	local cardinalLabel              = Instance.new("TextLabel")
	cardinalLabel.Name               = "Cardinal"
	cardinalLabel.Size               = UDim2.fromScale(1, 1)
	cardinalLabel.BackgroundTransparency = 1
	cardinalLabel.Font               = Enum.Font.Gotham
	cardinalLabel.TextScaled         = true
	cardinalLabel.TextColor3         = Color3.fromRGB(160, 160, 160)
	cardinalLabel.Text               = "N"
	cardinalLabel.ZIndex             = 3
	cardinalLabel.Parent             = compassOuter

	-- Needle (rotating red triangle)
	local needle              = Instance.new("TextLabel")
	needle.Name               = "Needle"
	needle.Size               = UDim2.fromScale(1, 1)
	needle.BackgroundTransparency = 1
	needle.Font               = Enum.Font.GothamBold
	needle.TextScaled         = true
	needle.TextColor3         = Color3.fromRGB(255, 80, 80)
	needle.Text               = "▲"
	needle.ZIndex             = 4
	needle.Parent             = compassOuter

	-- ── Top-right: Currency ────────────────────────────────────
	local currencyLabel              = Instance.new("TextLabel")
	currencyLabel.Name               = "Currency"
	currencyLabel.Size               = UDim2.new(0.28, 0, 0.055, 0)
	currencyLabel.AnchorPoint        = Vector2.new(1, 0)
	currencyLabel.Position           = UDim2.new(1, -8, 0, 8)
	currencyLabel.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
	currencyLabel.BackgroundTransparency = 0.55
	currencyLabel.BorderSizePixel    = 0
	currencyLabel.Font               = Enum.Font.GothamBold
	currencyLabel.TextSize           = 13
	currencyLabel.TextColor3         = Color3.fromRGB(255, 215, 0)
	currencyLabel.TextXAlignment     = Enum.TextXAlignment.Right
	currencyLabel.Text               = "Rp 0  ◆ 0"
	currencyLabel.ZIndex             = 2
	currencyLabel.Parent             = sg

	local currCorner       = Instance.new("UICorner")
	currCorner.CornerRadius = UDim.new(0, 6)
	currCorner.Parent       = currencyLabel

	-- ── Bottom strip ───────────────────────────────────────────
	-- Strip sits between stamina label and hotbar

	-- Bottom-left: Morality
	local moralityFrame              = Instance.new("Frame")
	moralityFrame.Name               = "Morality"
	moralityFrame.Size               = UDim2.new(0.21, 0, 0.055, 0)
	moralityFrame.AnchorPoint        = Vector2.new(0, 1)
	moralityFrame.Position           = UDim2.new(0, 8, 0.92, 0)
	moralityFrame.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
	moralityFrame.BackgroundTransparency = 0.55
	moralityFrame.BorderSizePixel    = 0
	moralityFrame.ZIndex             = 2
	moralityFrame.Parent             = sg

	local morCorner       = Instance.new("UICorner")
	morCorner.CornerRadius = UDim.new(0, 6)
	morCorner.Parent       = moralityFrame

	local moralityLabel              = Instance.new("TextLabel")
	moralityLabel.Name               = "MoralityLabel"
	moralityLabel.Size               = UDim2.fromScale(1, 1)
	moralityLabel.BackgroundTransparency = 1
	moralityLabel.Font               = Enum.Font.GothamBold
	moralityLabel.TextScaled         = true
	moralityLabel.TextColor3         = Color3.fromRGB(180, 180, 180)
	moralityLabel.Text               = "—"
	moralityLabel.ZIndex             = 3
	moralityLabel.Parent             = moralityFrame

	-- Bottom-center: Stamina label + bar
	local staminaLabel              = Instance.new("TextLabel")
	staminaLabel.Name               = "StaminaLabel"
	staminaLabel.Size               = UDim2.new(0.32, 0, 0.03, 0)
	staminaLabel.AnchorPoint        = Vector2.new(0.5, 1)
	staminaLabel.Position           = UDim2.new(0.5, 0, 0.88, 0)
	staminaLabel.BackgroundTransparency = 1
	staminaLabel.Font               = Enum.Font.Gotham
	staminaLabel.TextScaled         = true
	staminaLabel.TextColor3         = Color3.fromRGB(180, 255, 180)
	staminaLabel.Text               = "100 / 100"
	staminaLabel.ZIndex             = 2
	staminaLabel.Parent             = sg

	local staminaOuter              = Instance.new("Frame")
	staminaOuter.Name               = "StaminaOuter"
	staminaOuter.Size               = UDim2.new(0.32, 0, 0.022, 0)
	staminaOuter.AnchorPoint        = Vector2.new(0.5, 1)
	staminaOuter.Position           = UDim2.new(0.5, 0, 0.92, 0)
	staminaOuter.BackgroundColor3   = Color3.fromRGB(40, 40, 40)
	staminaOuter.BackgroundTransparency = 0.3
	staminaOuter.BorderSizePixel    = 0
	staminaOuter.ZIndex             = 2
	staminaOuter.Parent             = sg

	local staminaOuterCorner       = Instance.new("UICorner")
	staminaOuterCorner.CornerRadius = UDim.new(0.5, 0)
	staminaOuterCorner.Parent       = staminaOuter

	local staminaFill              = Instance.new("Frame")
	staminaFill.Name               = "Fill"
	staminaFill.Size               = UDim2.fromScale(1, 1)
	staminaFill.BackgroundColor3   = Color3.fromRGB(60, 200, 60)
	staminaFill.BorderSizePixel    = 0
	staminaFill.ZIndex             = 3
	staminaFill.Parent             = staminaOuter

	local fillCorner       = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent       = staminaFill

	-- Bottom-right: Inventory + Menu buttons (stacked)
	local invBtn              = Instance.new("TextButton")
	invBtn.Name               = "InvBtn"
	invBtn.Size               = UDim2.new(0.10, 0, 0.052, 0)
	invBtn.AnchorPoint        = Vector2.new(1, 1)
	invBtn.Position           = UDim2.new(1, -8, 0.89, 0)
	invBtn.BackgroundColor3   = Color3.fromRGB(60, 100, 160)
	invBtn.BackgroundTransparency = 0.1
	invBtn.BorderSizePixel    = 0
	invBtn.Font               = Enum.Font.GothamBold
	invBtn.TextScaled         = true
	invBtn.TextColor3         = Color3.fromRGB(220, 220, 220)
	invBtn.Text               = "Tas"
	invBtn.ZIndex             = 2
	invBtn.Parent             = sg

	local invCorner       = Instance.new("UICorner")
	invCorner.CornerRadius = UDim.new(0, 6)
	invCorner.Parent       = invBtn

	local menuBtn              = Instance.new("TextButton")
	menuBtn.Name               = "MenuBtn"
	menuBtn.Size               = UDim2.new(0.10, 0, 0.052, 0)
	menuBtn.AnchorPoint        = Vector2.new(1, 1)
	menuBtn.Position           = UDim2.new(1, -8, 0.945, 0)
	menuBtn.BackgroundColor3   = Color3.fromRGB(50, 50, 60)
	menuBtn.BackgroundTransparency = 0.2
	menuBtn.BorderSizePixel    = 0
	menuBtn.Font               = Enum.Font.GothamBold
	menuBtn.TextScaled         = true
	menuBtn.TextColor3         = Color3.fromRGB(220, 220, 220)
	menuBtn.Text               = "Menu"
	menuBtn.ZIndex             = 2
	menuBtn.Parent             = sg

	local menuCorner       = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0, 6)
	menuCorner.Parent       = menuBtn

	-- ── Hotbar (full-width bottom) ─────────────────────────────
	local hotbarFrame              = Instance.new("Frame")
	hotbarFrame.Name               = "Hotbar"
	hotbarFrame.Size               = UDim2.new(1, 0, 0.075, 0)
	hotbarFrame.AnchorPoint        = Vector2.new(0.5, 1)
	hotbarFrame.Position           = UDim2.new(0.5, 0, 1, 0)
	hotbarFrame.BackgroundTransparency = 1
	hotbarFrame.ZIndex             = 2
	hotbarFrame.Parent             = sg

	local hotbarLayout              = Instance.new("UIListLayout")
	hotbarLayout.FillDirection      = Enum.FillDirection.Horizontal
	hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hotbarLayout.Padding            = UDim.new(0, 4)
	hotbarLayout.SortOrder          = Enum.SortOrder.LayoutOrder
	hotbarLayout.Parent             = hotbarFrame

	_hud = {
		sg             = sg,
		questLabel     = questLabel,
		questFrame     = questFrame,
		needle         = needle,
		currencyLabel  = currencyLabel,
		moralityLabel  = moralityLabel,
		staminaFill    = staminaFill,
		staminaLabel   = staminaLabel,
		menuBtn        = menuBtn,
		invBtn         = invBtn,
		hotbarFrame    = hotbarFrame,
	}

	return _hud
end

-- ── Hotbar slot management ────────────────────────────────────────

local function buildHotbarSlots(count)
	for _, btn in _hotbarSlots do
		btn:Destroy()
	end
	_hotbarSlots = {}
	_hotbarSize  = count

	for i = 1, count do
		local slot              = Instance.new("TextButton")
		slot.Name               = "Slot_" .. i
		slot.Size               = UDim2.new(0, 60, 1, -4)
		slot.BackgroundColor3   = Color3.fromRGB(40, 40, 50)
		slot.BackgroundTransparency = 0.2
		slot.BorderSizePixel    = 0
		slot.Text               = ""
		slot.LayoutOrder        = i
		slot.ZIndex             = 3
		slot.Parent             = _hud.hotbarFrame

		local slotCorner       = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 6)
		slotCorner.Parent       = slot

		local numLabel              = Instance.new("TextLabel")
		numLabel.Name               = "Num"
		numLabel.Size               = UDim2.new(0, 14, 0, 14)
		numLabel.Position           = UDim2.fromOffset(2, 2)
		numLabel.BackgroundTransparency = 1
		numLabel.Font               = Enum.Font.GothamBold
		numLabel.TextSize           = 10
		numLabel.TextColor3         = Color3.fromRGB(120, 120, 120)
		numLabel.Text               = tostring(i)
		numLabel.ZIndex             = 4
		numLabel.Parent             = slot

		local itemLabel              = Instance.new("TextLabel")
		itemLabel.Name               = "ItemLabel"
		itemLabel.Size               = UDim2.new(1, -4, 0.6, 0)
		itemLabel.Position           = UDim2.fromOffset(2, 16)
		itemLabel.BackgroundTransparency = 1
		itemLabel.Font               = Enum.Font.Gotham
		itemLabel.TextSize           = 9
		itemLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
		itemLabel.TextXAlignment     = Enum.TextXAlignment.Center
		itemLabel.TextWrapped        = true
		itemLabel.Text               = ""
		itemLabel.ZIndex             = 4
		itemLabel.Parent             = slot

		local countLabel              = Instance.new("TextLabel")
		countLabel.Name               = "Count"
		countLabel.Size               = UDim2.new(1, -4, 0, 14)
		countLabel.AnchorPoint        = Vector2.new(0, 1)
		countLabel.Position           = UDim2.new(0, 2, 1, -2)
		countLabel.BackgroundTransparency = 1
		countLabel.Font               = Enum.Font.GothamBold
		countLabel.TextSize           = 11
		countLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
		countLabel.TextXAlignment     = Enum.TextXAlignment.Right
		countLabel.Text               = ""
		countLabel.ZIndex             = 4
		countLabel.Parent             = slot

		local slotIndex = i
		slot.Activated:Connect(function()
			if _hotbarController then
				_hotbarController.HotbarSlotPressed:Fire(slotIndex)
			end
		end)

		_hotbarSlots[i] = slot
	end
end

-- ── Update functions ──────────────────────────────────────────────

local function updateStamina(value)
	if not _hud then
		return
	end
	local max  = AssetConfig.Stamina and AssetConfig.Stamina.Max or 100
	local frac = math.clamp(value / math.max(max, 1), 0, 1)
	local color
	if frac > 0.6 then
		color = Color3.fromRGB(60, 200, 60)
	elseif frac > 0.3 then
		color = Color3.fromRGB(240, 180, 30)
	else
		color = Color3.fromRGB(220, 50, 50)
	end
	_hud.staminaFill.Size             = UDim2.fromScale(frac, 1)
	_hud.staminaFill.BackgroundColor3 = color
	_hud.staminaLabel.Text            = tostring(math.floor(value)) .. " / " .. tostring(max)
end

local function updateMorality(tierLabel, tierColor)
	if not _hud then
		return
	end
	_hud.moralityLabel.Text       = tierLabel or "—"
	_hud.moralityLabel.TextColor3 = tierColor or Color3.fromRGB(180, 180, 180)
end

local function updateCurrency(currType, balance)
	if not _hud then
		return
	end
	if currType == "Rupiah" then
		_rupiah = balance
	elseif currType == "Gold" then
		_gold = balance
	end
	_hud.currencyLabel.Text = "Rp " .. tostring(_rupiah) .. "  ◆ " .. tostring(_gold)
end

local function updateQuestObjective(text)
	if not _hud then
		return
	end
	_hud.questLabel.Text = text or "—"
end

local function updateHotbarSlot(slotIndex, itemId, count, inventory)
	local slot = _hotbarSlots[slotIndex]
	if not slot then
		return
	end
	local itemLabel  = slot:FindFirstChild("ItemLabel")
	local countLabel = slot:FindFirstChild("Count")

	if itemId then
		local cfg = AssetConfig.getItem(itemId)
		if itemLabel then
			itemLabel.Text = cfg and cfg.nameKey or itemId
		end
		-- count from inventory
		local amt = 0
		for _, entry in (inventory or {}) do
			if entry.id == itemId then
				amt = entry.amount or 0
				break
			end
		end
		if countLabel then
			countLabel.Text = (amt > 1) and tostring(amt) or ""
		end
	else
		if itemLabel then
			itemLabel.Text = ""
		end
		if countLabel then
			countLabel.Text = ""
		end
	end
end

local function highlightSlot(slotIndex)
	for i, slot in _hotbarSlots do
		if i == slotIndex then
			slot.BackgroundColor3 = Color3.fromRGB(80, 120, 180)
		else
			slot.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		end
	end
end

-- ── Compass update (camera yaw tracking) ─────────────────────────

local function startCompassUpdate()
	RunService.RenderStepped:Connect(function()
		if not _hud then
			return
		end
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local _, yaw, _ = camera.CFrame:ToEulerAnglesYXZ()
		_hud.needle.Rotation = -math.deg(yaw)
	end)
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function HUDController:KnitInit()
	buildHUD()
end

function HUDController:KnitStart()
	_hotbarController    = Knit.GetController("HotbarController")
	_inventoryController = Knit.GetController("InventoryController")
	_questController     = Knit.GetController("QuestController")

	local staminaService   = Knit.GetService("StaminaService")
	local currencyService  = Knit.GetService("CurrencyService")
	local questService     = Knit.GetService("QuestService")
	local inventoryService = Knit.GetService("InventoryService")
	local dataService      = Knit.GetService("DataService")

	-- Build hotbar with default size, resize when data loads
	buildHotbarSlots(4)

	-- Initial data seed
	dataService:GetPlayerData():andThen(function(data)
		if not data then
			return
		end
		local newSize = data.hotbarSize or 4
		if newSize ~= _hotbarSize then
			buildHotbarSlots(newSize)
		end
		_rupiah = data.rupiah or 0
		_gold   = data.gold   or 0
		updateCurrency("Rupiah", _rupiah)
		local tier = AssetConfig.getMoralityTier(data.morality or 50)
		updateMorality(tier.labelKey, tier.color)
	end)

	-- Stamina
	staminaService.StaminaUpdate:Connect(function(value)
		updateStamina(value)
	end)

	-- Currency
	currencyService.CurrencyUpdate:Connect(function(currType, balance)
		updateCurrency(currType, balance)
	end)

	-- Morality (via RemoteEvent — same source as MoralityController)
	local moralityRE = ReplicatedStorage
		:WaitForChild("RemoteEvents")
		:WaitForChild("MoralityChanged")
	moralityRE.OnClientEvent:Connect(function(payload)
		if not payload then
			return
		end
		local tier = AssetConfig.getMoralityTier(payload.value or 50)
		updateMorality(tier.labelKey, tier.color)
	end)

	-- Quest objective
	questService.QuestUpdate:Connect(function(snapshot)
		local activeQuests = snapshot.activeQuests or {}
		if #activeQuests == 0 then
			updateQuestObjective("—")
			return
		end
		local firstId  = activeQuests[1]
		local qCfg     = AssetConfig.getQuest(firstId)
		local progress = (snapshot.questProgress or {})[firstId] or {}
		local objProg  = progress.objectiveProgress or {}

		if not qCfg then
			updateQuestObjective(firstId)
			return
		end

		local line = qCfg.titleKey or firstId
		for _, obj in (qCfg.objectives or {}) do
			local prog = objProg[obj.id] or 0
			local req  = obj.required or 1
			if prog < req then
				line = (qCfg.titleKey or firstId) .. "\n" .. (obj.descKey or obj.id)
				break
			end
		end
		updateQuestObjective(line)
	end)

	-- Hotbar slot content
	inventoryService.SyncInventory:Connect(function(inventory, hotbar)
		for slot = 1, _hotbarSize do
			local itemId = hotbar and hotbar[slot]
			updateHotbarSlot(slot, itemId, 0, inventory)
		end
	end)

	-- Hotbar highlight
	_hotbarController.ActiveSlotChanged.Event:Connect(function(slotIndex)
		highlightSlot(slotIndex)
	end)

	-- Inventory button
	_hud.invBtn.Activated:Connect(function()
		if _inventoryController then
			_inventoryController:toggleInventory()
		end
	end)

	-- Quest objective tap: open QuestGui
	_hud.questFrame.Activated:Connect(function()
		if _questController then
			_questController:openQuestGui()
		end
	end)

	startCompassUpdate()
end

-- ── Public API ────────────────────────────────────────────────────

function HUDController:updateStamina(value)
	updateStamina(value)
end

function HUDController:updateMorality(tierLabel, tierColor)
	updateMorality(tierLabel, tierColor)
end

function HUDController:updateCurrency(currType, balance)
	updateCurrency(currType, balance)
end

function HUDController:updateQuestObjective(text)
	updateQuestObjective(text)
end

return HUDController
