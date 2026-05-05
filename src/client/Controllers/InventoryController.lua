-- LocalScript: StarterPlayerScripts/Client/Controllers/InventoryController
-- Maintains inventory/hotbar cache. Also builds the full InventoryGui panel.
-- Filter tabs: All / Makanan / Kosmetik / Koleksi / Senjata / Bahan.
-- Item grid with tooltip (hover/long-press) and action menu.

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local InventoryController = Knit.CreateController {
	Name = "InventoryController",

	_inventory        = {},
	_hotbar           = {},
	_inventoryService = nil,
}

-- ── State ─────────────────────────────────────────────────────────

local _gui           = nil
local _activeFilter  = "All"
local _tooltipGui    = nil
local _actionGui     = nil
local _longPressTask = nil

local FILTER_TYPES = { "All", "Makanan", "Kosmetik", "Koleksi", "Senjata", "Bahan" }
local TYPE_ALIASES = { Makanan = "Food", Senjata = "Weapon", Bahan = "Material" }

-- ── Tooltip ───────────────────────────────────────────────────────

local function hideTooltip()
	if _tooltipGui then
		_tooltipGui:Destroy()
		_tooltipGui = nil
	end
end

local function showTooltip(itemCfg, screenPos)
	hideTooltip()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "ItemTooltip"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = true
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Parent             = playerGui
	_tooltipGui           = sg

	local frame              = Instance.new("Frame")
	frame.Size               = UDim2.fromOffset(200, 110)
	frame.Position           = UDim2.fromOffset(
		math.min(screenPos.X + 12, 1024 - 212),
		math.min(screenPos.Y + 8, 768 - 120)
	)
	frame.BackgroundColor3   = Color3.fromRGB(15, 15, 25)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel    = 0
	frame.ZIndex             = 20
	frame.Parent             = sg

	local fCorner       = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(0, 8)
	fCorner.Parent       = frame

	local rarityInfo  = AssetConfig.Rarity and AssetConfig.Rarity[itemCfg.rarity]
	local rarityColor = rarityInfo and rarityInfo.color or Color3.fromRGB(180, 180, 180)

	local stripe              = Instance.new("Frame")
	stripe.Size               = UDim2.new(1, 0, 0, 3)
	stripe.BackgroundColor3   = rarityColor
	stripe.BorderSizePixel    = 0
	stripe.ZIndex             = 21
	stripe.Parent             = frame

	local layout              = Instance.new("UIListLayout")
	layout.Padding            = UDim.new(0, 4)
	layout.SortOrder          = Enum.SortOrder.LayoutOrder
	layout.Parent             = frame

	local padding             = Instance.new("UIPadding")
	padding.PaddingLeft       = UDim.new(0, 8)
	padding.PaddingRight      = UDim.new(0, 8)
	padding.PaddingTop        = UDim.new(0, 8)
	padding.PaddingBottom     = UDim.new(0, 8)
	padding.Parent            = frame

	local lines = {
		{ text = itemCfg.nameKey or itemCfg.id, bold = true, color = rarityColor },
		{ text = (itemCfg.type or "") .. "  •  " .. (itemCfg.rarity or ""), bold = false, color = Color3.fromRGB(160, 160, 160) },
		{ text = itemCfg.descKey or "", bold = false, color = Color3.fromRGB(200, 200, 200) },
	}

	if itemCfg.staminaGain then
		lines[#lines + 1] = { text = "+  " .. tostring(itemCfg.staminaGain) .. " Stamina", bold = false, color = Color3.fromRGB(100, 220, 100) }
	end

	for i, line in lines do
		local lbl              = Instance.new("TextLabel")
		lbl.Size               = UDim2.new(1, 0, 0, 16)
		lbl.BackgroundTransparency = 1
		lbl.Font               = line.bold and Enum.Font.GothamBold or Enum.Font.Gotham
		lbl.TextSize           = 12
		lbl.TextColor3         = line.color
		lbl.TextXAlignment     = Enum.TextXAlignment.Left
		lbl.TextWrapped        = true
		lbl.Text               = line.text
		lbl.LayoutOrder        = i
		lbl.ZIndex             = 21
		lbl.Parent             = frame
	end
end

-- ── Action menu ───────────────────────────────────────────────────

local function hideActionMenu()
	if _actionGui then
		_actionGui:Destroy()
		_actionGui = nil
	end
end

local function showActionMenu(entry, itemCfg, screenPos, invController)
	hideActionMenu()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "ItemAction"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = true
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Parent             = playerGui
	_actionGui            = sg

	-- Dismiss on backdrop click
	local backdrop              = Instance.new("TextButton")
	backdrop.Size               = UDim2.fromScale(1, 1)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel    = 0
	backdrop.Text               = ""
	backdrop.ZIndex             = 14
	backdrop.Parent             = sg
	backdrop.Activated:Connect(hideActionMenu)

	local frame              = Instance.new("Frame")
	frame.Size               = UDim2.fromOffset(160, 0)
	frame.AutomaticSize      = Enum.AutomaticSize.Y
	frame.Position           = UDim2.fromOffset(
		math.min(screenPos.X, 1024 - 172),
		math.min(screenPos.Y, 768 - 200)
	)
	frame.BackgroundColor3   = Color3.fromRGB(20, 20, 30)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel    = 0
	frame.ZIndex             = 15
	frame.Parent             = sg

	local fCorner       = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(0, 8)
	fCorner.Parent       = frame

	local layout             = Instance.new("UIListLayout")
	layout.SortOrder         = Enum.SortOrder.LayoutOrder
	layout.Padding           = UDim.new(0, 2)
	layout.Parent            = frame

	local function makeBtn(label, order, color, action)
		local btn              = Instance.new("TextButton")
		btn.Size               = UDim2.new(1, 0, 0, 40)
		btn.BackgroundColor3   = color
		btn.BackgroundTransparency = 0.2
		btn.BorderSizePixel    = 0
		btn.Font               = Enum.Font.Gotham
		btn.TextSize           = 13
		btn.TextColor3         = Color3.fromRGB(220, 220, 220)
		btn.Text               = label
		btn.LayoutOrder        = order
		btn.ZIndex             = 16
		btn.Parent             = frame
		local c                = Instance.new("UICorner")
		c.CornerRadius         = UDim.new(0, 6)
		c.Parent               = btn
		btn.Activated:Connect(function()
			hideActionMenu()
			action()
		end)
	end

	local isConsumable  = itemCfg.staminaGain ~= nil
	local isEquippable  = itemCfg.type == "Weapon" or itemCfg.type == "Senjata"

	local btnIdx = 1

	if isConsumable then
		makeBtn("Gunakan", btnIdx, Color3.fromRGB(40, 120, 60), function()
			invController:useItem(entry.id)
		end)
		btnIdx += 1
	end

	if isEquippable then
		makeBtn("Pakai", btnIdx, Color3.fromRGB(60, 80, 140), function()
			invController:useItem(entry.id)
		end)
		btnIdx += 1
	end

	makeBtn("Hotbar", btnIdx, Color3.fromRGB(80, 60, 120), function()
		-- Show slot selector (1-8)
		local dataService = Knit.GetService("DataService")
		dataService:GetPlayerData():andThen(function(data)
			local hotbarSize = data and data.hotbarSize or 4
			for slot = 1, hotbarSize do
				invController:assignHotbar(slot, entry.id)
				break  -- assign to first available slot for simplicity
			end
		end)
	end)
	btnIdx += 1

	makeBtn("Buang", btnIdx, Color3.fromRGB(120, 40, 40), function()
		invController:dropItem(entry.id, 1)
	end)
end

-- ── Item cell builder ─────────────────────────────────────────────

local function buildItemCell(parent, entry, index, invController)
	local cfg = AssetConfig.getItem(entry.id)
	if not cfg then
		return nil
	end

	local rarityInfo  = AssetConfig.Rarity and AssetConfig.Rarity[cfg.rarity]
	local rarityColor = rarityInfo and rarityInfo.color or Color3.fromRGB(180, 180, 180)

	local cell              = Instance.new("ImageButton")
	cell.Name               = "Cell_" .. index
	cell.Size               = UDim2.fromOffset(80, 80)
	cell.BackgroundColor3   = Color3.fromRGB(30, 30, 48)
	cell.BorderSizePixel    = 3
	cell.BorderColor3       = rarityColor
	cell.Image              = cfg.imageId or "rbxassetid://0"
	cell.ImageTransparency  = 0.8
	cell.LayoutOrder        = index
	cell.ZIndex             = 5
	cell.Parent             = parent

	local cellCorner       = Instance.new("UICorner")
	cellCorner.CornerRadius = UDim.new(0, 6)
	cellCorner.Parent       = cell

	local nameLabel              = Instance.new("TextLabel")
	nameLabel.Size               = UDim2.new(1, -4, 0.5, 0)
	nameLabel.Position           = UDim2.fromOffset(2, 2)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font               = Enum.Font.Gotham
	nameLabel.TextSize           = 9
	nameLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
	nameLabel.TextXAlignment     = Enum.TextXAlignment.Center
	nameLabel.TextWrapped        = true
	nameLabel.Text               = cfg.nameKey or entry.id
	nameLabel.ZIndex             = 6
	nameLabel.Parent             = cell

	local countLabel              = Instance.new("TextLabel")
	countLabel.Size               = UDim2.new(1, -4, 0, 16)
	countLabel.AnchorPoint        = Vector2.new(0, 1)
	countLabel.Position           = UDim2.new(0, 2, 1, -2)
	countLabel.BackgroundTransparency = 1
	countLabel.Font               = Enum.Font.GothamBold
	countLabel.TextSize           = 12
	countLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
	countLabel.TextXAlignment     = Enum.TextXAlignment.Right
	countLabel.Text               = entry.amount > 1 and tostring(entry.amount) or ""
	countLabel.ZIndex             = 6
	countLabel.Parent             = cell

	-- Desktop: hover tooltip
	cell.MouseEnter:Connect(function()
		if not UserInputService.TouchEnabled then
			local mouse = Players.LocalPlayer:GetMouse()
			showTooltip(cfg, Vector2.new(mouse.X, mouse.Y))
		end
	end)
	cell.MouseLeave:Connect(function()
		if not UserInputService.TouchEnabled then
			hideTooltip()
		end
	end)

	-- Mobile: long-press tooltip (0.5s hold)
	cell.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			_longPressTask = task.delay(0.5, function()
				_longPressTask = nil
				showTooltip(cfg, Vector2.new(input.Position.X, input.Position.Y))
			end)
		end
	end)
	cell.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			if _longPressTask then
				task.cancel(_longPressTask)
				_longPressTask = nil
			end
		end
	end)

	-- Click: action menu
	cell.Activated:Connect(function()
		hideTooltip()
		local mouse = Players.LocalPlayer:GetMouse()
		showActionMenu(entry, cfg, Vector2.new(mouse.X, mouse.Y), invController)
	end)

	return cell
end

-- ── GUI construction ──────────────────────────────────────────────

local function buildGui(invController)
	if _gui then
		return _gui
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "InventoryGui"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = true
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Enabled            = false
	sg.Parent             = playerGui

	local backdrop                    = Instance.new("TextButton")
	backdrop.Name                     = "Backdrop"
	backdrop.Size                     = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3         = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency   = 0.5
	backdrop.BorderSizePixel          = 0
	backdrop.Text                     = ""
	backdrop.ZIndex                   = 1
	backdrop.Parent                   = sg

	local panel                       = Instance.new("Frame")
	panel.Name                        = "Panel"
	panel.Size                        = UDim2.fromOffset(500, 560)
	panel.AnchorPoint                 = Vector2.new(0.5, 0.5)
	panel.Position                    = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3            = Color3.fromRGB(18, 18, 28)
	panel.BackgroundTransparency      = 0.05
	panel.BorderSizePixel             = 0
	panel.ZIndex                      = 2
	panel.Parent                      = sg

	local panelCorner       = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent       = panel

	local titleLabel              = Instance.new("TextLabel")
	titleLabel.Name               = "Title"
	titleLabel.Size               = UDim2.new(1, -80, 0, 36)
	titleLabel.Position           = UDim2.fromOffset(16, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font               = Enum.Font.GothamBold
	titleLabel.TextSize           = 18
	titleLabel.TextColor3         = Color3.fromRGB(255, 215, 0)
	titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
	titleLabel.Text               = "Inventaris"
	titleLabel.ZIndex             = 3
	titleLabel.Parent             = panel

	local closeBtn              = Instance.new("TextButton")
	closeBtn.Name               = "Close"
	closeBtn.Size               = UDim2.fromOffset(32, 32)
	closeBtn.Position           = UDim2.new(1, -44, 0, 10)
	closeBtn.BackgroundColor3   = Color3.fromRGB(180, 40, 40)
	closeBtn.BorderSizePixel    = 0
	closeBtn.Font               = Enum.Font.GothamBold
	closeBtn.TextSize           = 16
	closeBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
	closeBtn.Text               = "✕"
	closeBtn.ZIndex             = 3
	closeBtn.Parent             = panel

	local closeCorner       = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent       = closeBtn

	-- Filter tabs
	local tabBar              = Instance.new("Frame")
	tabBar.Name               = "TabBar"
	tabBar.Size               = UDim2.new(1, -32, 0, 32)
	tabBar.Position           = UDim2.fromOffset(16, 50)
	tabBar.BackgroundTransparency = 1
	tabBar.ZIndex             = 3
	tabBar.Parent             = panel

	local tabLayout              = Instance.new("UIListLayout")
	tabLayout.FillDirection      = Enum.FillDirection.Horizontal
	tabLayout.SortOrder          = Enum.SortOrder.LayoutOrder
	tabLayout.Padding            = UDim.new(0, 4)
	tabLayout.Parent             = tabBar

	local tabBtns = {}
	for i, filterName in FILTER_TYPES do
		local tb              = Instance.new("TextButton")
		tb.Name               = "Tab_" .. filterName
		tb.Size               = UDim2.new(0, 72, 1, 0)
		tb.BackgroundColor3   = Color3.fromRGB(40, 40, 60)
		tb.BackgroundTransparency = 0.2
		tb.BorderSizePixel    = 0
		tb.Font               = Enum.Font.Gotham
		tb.TextSize           = 11
		tb.TextColor3         = Color3.fromRGB(180, 180, 180)
		tb.Text               = filterName
		tb.LayoutOrder        = i
		tb.ZIndex             = 4
		tb.Parent             = tabBar

		local tc       = Instance.new("UICorner")
		tc.CornerRadius = UDim.new(0, 6)
		tc.Parent       = tb

		tabBtns[filterName] = tb
	end

	-- Grid scroll
	local scroll              = Instance.new("ScrollingFrame")
	scroll.Name               = "Scroll"
	scroll.Size               = UDim2.new(1, -32, 1, -130)
	scroll.Position           = UDim2.fromOffset(16, 90)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel    = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
	scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
	scroll.CanvasSize           = UDim2.fromScale(0, 0)
	scroll.ZIndex               = 3
	scroll.Parent               = panel

	local grid           = Instance.new("UIGridLayout")
	grid.CellSize        = UDim2.fromOffset(80, 80)
	grid.CellPadding     = UDim2.fromOffset(8, 8)
	grid.SortOrder       = Enum.SortOrder.LayoutOrder
	grid.Parent          = scroll

	-- Footer: slot counter
	local footerLabel              = Instance.new("TextLabel")
	footerLabel.Name               = "Footer"
	footerLabel.Size               = UDim2.new(1, -32, 0, 28)
	footerLabel.AnchorPoint        = Vector2.new(0, 1)
	footerLabel.Position           = UDim2.new(0, 16, 1, -8)
	footerLabel.BackgroundTransparency = 1
	footerLabel.Font               = Enum.Font.Gotham
	footerLabel.TextSize           = 12
	footerLabel.TextColor3         = Color3.fromRGB(160, 160, 160)
	footerLabel.TextXAlignment     = Enum.TextXAlignment.Center
	footerLabel.Text               = "0 / 20 slot"
	footerLabel.ZIndex             = 3
	footerLabel.Parent             = panel

	_gui = {
		sg          = sg,
		backdrop    = backdrop,
		panel       = panel,
		scroll      = scroll,
		tabBtns     = tabBtns,
		footerLabel = footerLabel,
		closeBtn    = closeBtn,
	}

	-- Wire tabs
	for _, filterName in FILTER_TYPES do
		local btn = tabBtns[filterName]
		local capture = filterName
		btn.Activated:Connect(function()
			_activeFilter = capture
			-- Highlight active tab
			for _, name2 in FILTER_TYPES do
				local tb2 = tabBtns[name2]
				if name2 == capture then
					tb2.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
					tb2.TextColor3       = Color3.fromRGB(255, 255, 255)
				else
					tb2.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
					tb2.TextColor3       = Color3.fromRGB(180, 180, 180)
				end
			end
			-- Re-render grid
			invController:_renderGrid()
		end)
	end

	closeBtn.Activated:Connect(function()
		sg.Enabled = false
	end)
	backdrop.Activated:Connect(function()
		sg.Enabled = false
	end)

	return _gui
end

-- ── Grid rendering ────────────────────────────────────────────────

function InventoryController:_renderGrid()
	if not _gui then
		return
	end
	local scroll = _gui.scroll

	-- Clear existing cells
	for _, child in scroll:GetChildren() do
		if child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local idx = 1
	for _, entry in self._inventory do
		local cfg = AssetConfig.getItem(entry.id)
		if not cfg then
			continue
		end

		local passFilter = (_activeFilter == "All")
		if not passFilter then
			local aliased = TYPE_ALIASES[_activeFilter] or _activeFilter
			passFilter = (cfg.type == aliased or cfg.type == _activeFilter)
		end

		if passFilter then
			buildItemCell(scroll, entry, idx, self)
			idx += 1
		end
	end

	-- Update footer
	local maxSlots = 20
	local dataService = Knit.GetService("DataService")
	dataService:GetPlayerData():andThen(function(data)
		if data then
			maxSlots = data.inventorySize or 20
			local used = #self._inventory
			local upgradeText = used >= maxSlots and " — Upgrade untuk lebih banyak slot" or ""
			_gui.footerLabel.Text = used .. " / " .. maxSlots .. " slot" .. upgradeText
		end
	end)
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function InventoryController:KnitInit()
end

function InventoryController:KnitStart()
	self._inventoryService = Knit.GetService("InventoryService")

	self._inventoryService.SyncInventory:Connect(function(inventory, hotbar)
		self._inventory = inventory or {}
		self._hotbar    = hotbar    or {}
		if _gui and _gui.sg.Enabled then
			self:_renderGrid()
		end
	end)

	-- Build GUI lazily (captures self for _renderGrid)
	task.defer(function()
		buildGui(self)
		-- Highlight "All" tab by default
		local allTab = _gui.tabBtns["All"]
		if allTab then
			allTab.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
			allTab.TextColor3       = Color3.fromRGB(255, 255, 255)
		end
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function InventoryController:getInventory()
	return self._inventory
end

function InventoryController:getHotbar()
	return self._hotbar
end

function InventoryController:getHotbarSlot(slotIndex)
	return self._hotbar[slotIndex]
end

function InventoryController:count(itemId)
	for _, entry in self._inventory do
		if entry.id == itemId then
			return entry.amount
		end
	end
	return 0
end

function InventoryController:useItem(itemId)
	return self._inventoryService:UseItem(itemId)
end

function InventoryController:dropItem(itemId, amount)
	return self._inventoryService:DropItem(itemId, amount or 1)
end

function InventoryController:assignHotbar(slotIndex, itemId)
	self._hotbar[slotIndex] = itemId
	return self._inventoryService:AssignHotbar(slotIndex, itemId)
end

function InventoryController:openInventory()
	buildGui(self)
	_gui.sg.Enabled = true
	self:_renderGrid()
end

function InventoryController:closeInventory()
	if _gui then
		_gui.sg.Enabled = false
	end
end

function InventoryController:toggleInventory()
	buildGui(self)
	if _gui.sg.Enabled then
		_gui.sg.Enabled = false
	else
		_gui.sg.Enabled = true
		self:_renderGrid()
	end
end

return InventoryController
