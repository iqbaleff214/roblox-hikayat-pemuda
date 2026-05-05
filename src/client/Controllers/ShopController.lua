-- LocalScript: StarterPlayerScripts/Client/Controllers/ShopController
-- Listens to ShopService.OpenShop. Builds Buy/Sell tabs.
-- Buy: grid of stock with morality discount badges. Sell: player inventory filtered by acceptedTypes.
-- Confirm dialog before purchase/sale. Shows NPC rejection on low morality.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local ShopController = Knit.CreateController { Name = "ShopController" }

-- ── State ─────────────────────────────────────────────────────────

local _shopService       = nil
local _inventoryController = nil
local _gui               = nil
local _currentShopId     = nil
local _currentStockData  = {}
local _activeTab         = "Beli"

-- ── Helpers ───────────────────────────────────────────────────────

local function formatRupiah(n)
	return "Rp " .. tostring(n)
end

-- ── GUI construction ──────────────────────────────────────────────

local function buildGui()
	if _gui then
		return _gui
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "ShopGui"
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
	panel.Size                        = UDim2.fromOffset(440, 500)
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

	-- Title
	local titleLabel              = Instance.new("TextLabel")
	titleLabel.Name               = "Title"
	titleLabel.Size               = UDim2.new(1, -80, 0, 36)
	titleLabel.Position           = UDim2.fromOffset(16, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font               = Enum.Font.GothamBold
	titleLabel.TextSize           = 18
	titleLabel.TextColor3         = Color3.fromRGB(255, 215, 0)
	titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
	titleLabel.Text               = "Toko"
	titleLabel.ZIndex             = 3
	titleLabel.Parent             = panel

	-- Close button
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

	-- Tab bar
	local tabBar              = Instance.new("Frame")
	tabBar.Name               = "TabBar"
	tabBar.Size               = UDim2.new(1, -32, 0, 36)
	tabBar.Position           = UDim2.fromOffset(16, 50)
	tabBar.BackgroundColor3   = Color3.fromRGB(30, 30, 45)
	tabBar.BackgroundTransparency = 0.2
	tabBar.BorderSizePixel    = 0
	tabBar.ZIndex             = 3
	tabBar.Parent             = panel

	local tabCorner       = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 8)
	tabCorner.Parent       = tabBar

	local tabLayout              = Instance.new("UIListLayout")
	tabLayout.FillDirection      = Enum.FillDirection.Horizontal
	tabLayout.SortOrder          = Enum.SortOrder.LayoutOrder
	tabLayout.Padding            = UDim.new(0, 2)
	tabLayout.Parent             = tabBar

	local tabBeli              = Instance.new("TextButton")
	tabBeli.Name               = "TabBeli"
	tabBeli.Size               = UDim2.new(0.5, -2, 1, 0)
	tabBeli.BackgroundColor3   = Color3.fromRGB(60, 130, 60)
	tabBeli.BorderSizePixel    = 0
	tabBeli.Font               = Enum.Font.GothamBold
	tabBeli.TextSize           = 14
	tabBeli.TextColor3         = Color3.fromRGB(255, 255, 255)
	tabBeli.Text               = "Beli"
	tabBeli.LayoutOrder        = 1
	tabBeli.ZIndex             = 4
	tabBeli.Parent             = tabBar

	local tabBeliCorner       = Instance.new("UICorner")
	tabBeliCorner.CornerRadius = UDim.new(0, 6)
	tabBeliCorner.Parent       = tabBeli

	local tabJual              = Instance.new("TextButton")
	tabJual.Name               = "TabJual"
	tabJual.Size               = UDim2.new(0.5, -2, 1, 0)
	tabJual.BackgroundColor3   = Color3.fromRGB(50, 50, 70)
	tabJual.BorderSizePixel    = 0
	tabJual.Font               = Enum.Font.GothamBold
	tabJual.TextSize           = 14
	tabJual.TextColor3         = Color3.fromRGB(200, 200, 200)
	tabJual.Text               = "Jual"
	tabJual.LayoutOrder        = 2
	tabJual.ZIndex             = 4
	tabJual.Parent             = tabBar

	local tabJualCorner       = Instance.new("UICorner")
	tabJualCorner.CornerRadius = UDim.new(0, 6)
	tabJualCorner.Parent       = tabJual

	-- Scroll grid
	local scroll              = Instance.new("ScrollingFrame")
	scroll.Name               = "Scroll"
	scroll.Size               = UDim2.new(1, -32, 1, -110)
	scroll.Position           = UDim2.fromOffset(16, 96)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel    = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
	scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
	scroll.CanvasSize           = UDim2.fromScale(0, 0)
	scroll.ZIndex               = 3
	scroll.Parent               = panel

	local grid           = Instance.new("UIGridLayout")
	grid.CellSize        = UDim2.fromOffset(120, 130)
	grid.CellPadding     = UDim2.fromOffset(8, 8)
	grid.SortOrder       = Enum.SortOrder.LayoutOrder
	grid.Parent          = scroll

	-- Status/feedback label
	local statusLabel              = Instance.new("TextLabel")
	statusLabel.Name               = "Status"
	statusLabel.Size               = UDim2.new(1, -32, 0, 24)
	statusLabel.AnchorPoint        = Vector2.new(0, 1)
	statusLabel.Position           = UDim2.new(0, 16, 1, -8)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font               = Enum.Font.Gotham
	statusLabel.TextSize           = 13
	statusLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
	statusLabel.TextXAlignment     = Enum.TextXAlignment.Center
	statusLabel.Text               = ""
	statusLabel.ZIndex             = 3
	statusLabel.Parent             = panel

	_gui = {
		sg          = sg,
		backdrop    = backdrop,
		panel       = panel,
		titleLabel  = titleLabel,
		closeBtn    = closeBtn,
		tabBeli     = tabBeli,
		tabJual     = tabJual,
		scroll      = scroll,
		statusLabel = statusLabel,
	}
	return _gui
end

-- ── Tab state management ──────────────────────────────────────────

local function setActiveTab(tabName)
	_activeTab = tabName
	local gui = buildGui()
	if tabName == "Beli" then
		gui.tabBeli.BackgroundColor3 = Color3.fromRGB(60, 130, 60)
		gui.tabBeli.TextColor3       = Color3.fromRGB(255, 255, 255)
		gui.tabJual.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		gui.tabJual.TextColor3       = Color3.fromRGB(200, 200, 200)
	else
		gui.tabJual.BackgroundColor3 = Color3.fromRGB(130, 80, 30)
		gui.tabJual.TextColor3       = Color3.fromRGB(255, 255, 255)
		gui.tabBeli.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		gui.tabBeli.TextColor3       = Color3.fromRGB(200, 200, 200)
	end
end

-- ── Confirm dialog ────────────────────────────────────────────────

local function showConfirm(message, onConfirm)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "ShopConfirm"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = true
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Parent             = playerGui

	local frame              = Instance.new("Frame")
	frame.Size               = UDim2.fromOffset(320, 160)
	frame.AnchorPoint        = Vector2.new(0.5, 0.5)
	frame.Position           = UDim2.fromScale(0.5, 0.5)
	frame.BackgroundColor3   = Color3.fromRGB(20, 20, 30)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel    = 0
	frame.ZIndex             = 10
	frame.Parent             = sg

	local fCorner       = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(0, 10)
	fCorner.Parent       = frame

	local msgLabel              = Instance.new("TextLabel")
	msgLabel.Size               = UDim2.new(1, -24, 0, 80)
	msgLabel.Position           = UDim2.fromOffset(12, 16)
	msgLabel.BackgroundTransparency = 1
	msgLabel.Font               = Enum.Font.Gotham
	msgLabel.TextSize           = 14
	msgLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
	msgLabel.TextWrapped        = true
	msgLabel.Text               = message
	msgLabel.ZIndex             = 11
	msgLabel.Parent             = frame

	local yesBtn              = Instance.new("TextButton")
	yesBtn.Size               = UDim2.new(0.45, 0, 0, 40)
	yesBtn.Position           = UDim2.fromOffset(12, 108)
	yesBtn.BackgroundColor3   = Color3.fromRGB(40, 150, 60)
	yesBtn.BorderSizePixel    = 0
	yesBtn.Font               = Enum.Font.GothamBold
	yesBtn.TextSize           = 14
	yesBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
	yesBtn.Text               = "Ya"
	yesBtn.ZIndex             = 11
	yesBtn.Parent             = frame

	local yCorner       = Instance.new("UICorner")
	yCorner.CornerRadius = UDim.new(0, 8)
	yCorner.Parent       = yesBtn

	local noBtn              = Instance.new("TextButton")
	noBtn.Size               = UDim2.new(0.45, 0, 0, 40)
	noBtn.Position           = UDim2.new(0.55, 0, 0, 108)
	noBtn.BackgroundColor3   = Color3.fromRGB(150, 40, 40)
	noBtn.BorderSizePixel    = 0
	noBtn.Font               = Enum.Font.GothamBold
	noBtn.TextSize           = 14
	noBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
	noBtn.Text               = "Batal"
	noBtn.ZIndex             = 11
	noBtn.Parent             = frame

	local nCorner       = Instance.new("UICorner")
	nCorner.CornerRadius = UDim.new(0, 8)
	nCorner.Parent       = noBtn

	local function destroy()
		sg:Destroy()
	end

	yesBtn.Activated:Connect(function()
		destroy()
		onConfirm()
	end)

	noBtn.Activated:Connect(destroy)
end

-- ── Item cell builder ─────────────────────────────────────────────

local function buildBuyCell(parent, stockEntry, index)
	local cell              = Instance.new("TextButton")
	cell.Name               = "Cell_" .. index
	cell.Size               = UDim2.fromOffset(120, 130)
	cell.BackgroundColor3   = Color3.fromRGB(30, 30, 48)
	cell.BorderSizePixel    = 0
	cell.Text               = ""
	cell.LayoutOrder        = index
	cell.ZIndex             = 4
	cell.Parent             = parent

	local cellCorner       = Instance.new("UICorner")
	cellCorner.CornerRadius = UDim.new(0, 8)
	cellCorner.Parent       = cell

	local iconLabel              = Instance.new("TextLabel")
	iconLabel.Size               = UDim2.new(1, 0, 0, 48)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font               = Enum.Font.GothamBold
	iconLabel.TextScaled         = true
	iconLabel.TextColor3         = Color3.fromRGB(255, 215, 0)
	iconLabel.Text               = "🛍"
	iconLabel.ZIndex             = 5
	iconLabel.Parent             = cell

	local nameLabel              = Instance.new("TextLabel")
	nameLabel.Size               = UDim2.new(1, -8, 0, 40)
	nameLabel.Position           = UDim2.fromOffset(4, 50)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font               = Enum.Font.Gotham
	nameLabel.TextSize           = 11
	nameLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
	nameLabel.TextXAlignment     = Enum.TextXAlignment.Center
	nameLabel.TextWrapped        = true
	nameLabel.Text               = stockEntry.nameKey or stockEntry.id
	nameLabel.ZIndex             = 5
	nameLabel.Parent             = cell

	local priceLabel              = Instance.new("TextLabel")
	priceLabel.Size               = UDim2.new(1, -8, 0, 20)
	priceLabel.Position           = UDim2.fromOffset(4, 92)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font               = Enum.Font.GothamBold
	priceLabel.TextSize           = 12
	priceLabel.TextColor3         = Color3.fromRGB(180, 255, 180)
	priceLabel.TextXAlignment     = Enum.TextXAlignment.Center
	priceLabel.Text               = formatRupiah(stockEntry.buyPrice or 0)
	priceLabel.ZIndex             = 5
	priceLabel.Parent             = cell

	local discBadge              = Instance.new("TextLabel")
	discBadge.Size               = UDim2.fromOffset(50, 16)
	discBadge.AnchorPoint        = Vector2.new(1, 0)
	discBadge.Position           = UDim2.new(1, -2, 0, 2)
	discBadge.BackgroundTransparency = 1
	discBadge.Font               = Enum.Font.Gotham
	discBadge.TextSize           = 10
	discBadge.TextColor3         = Color3.fromRGB(100, 220, 100)
	discBadge.TextXAlignment     = Enum.TextXAlignment.Right
	discBadge.Text               = ""
	discBadge.ZIndex             = 6
	discBadge.Parent             = cell

	local baseCfg = AssetConfig.getItem(stockEntry.id)
	if baseCfg and baseCfg.basePrice and (stockEntry.buyPrice or 0) < baseCfg.basePrice then
		discBadge.Text = "Diskon!"
	end

	cell.Activated:Connect(function()
		local msg = "Beli " .. (stockEntry.nameKey or stockEntry.id) .. " seharga " .. formatRupiah(stockEntry.buyPrice or 0) .. "?"
		showConfirm(msg, function()
			local gui = buildGui()
			_shopService:PurchaseItem(_currentShopId, stockEntry.id, 1):andThen(function(ok, reason)
				if ok then
					gui.statusLabel.Text       = "Berhasil dibeli!"
					gui.statusLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
				else
					local msg2 = "Gagal: " .. tostring(reason or "")
					if reason == "low_morality" then
						msg2 = "NPC menolakmu."
					end
					gui.statusLabel.Text       = msg2
					gui.statusLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
				end
			end)
		end)
	end)

	return cell
end

local function buildSellCell(parent, inventoryEntry, sellPrice, index)
	local cell              = Instance.new("TextButton")
	cell.Name               = "SellCell_" .. index
	cell.Size               = UDim2.fromOffset(120, 130)
	cell.BackgroundColor3   = Color3.fromRGB(30, 30, 48)
	cell.BorderSizePixel    = 0
	cell.Text               = ""
	cell.LayoutOrder        = index
	cell.ZIndex             = 4
	cell.Parent             = parent

	local cellCorner       = Instance.new("UICorner")
	cellCorner.CornerRadius = UDim.new(0, 8)
	cellCorner.Parent       = cell

	local cfg = AssetConfig.getItem(inventoryEntry.id)

	local iconLabel              = Instance.new("TextLabel")
	iconLabel.Size               = UDim2.new(1, 0, 0, 48)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font               = Enum.Font.GothamBold
	iconLabel.TextScaled         = true
	iconLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
	iconLabel.Text               = "📦"
	iconLabel.ZIndex             = 5
	iconLabel.Parent             = cell

	local nameLabel              = Instance.new("TextLabel")
	nameLabel.Size               = UDim2.new(1, -8, 0, 40)
	nameLabel.Position           = UDim2.fromOffset(4, 50)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font               = Enum.Font.Gotham
	nameLabel.TextSize           = 11
	nameLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
	nameLabel.TextXAlignment     = Enum.TextXAlignment.Center
	nameLabel.TextWrapped        = true
	nameLabel.Text               = (cfg and cfg.nameKey) or inventoryEntry.id
	nameLabel.ZIndex             = 5
	nameLabel.Parent             = cell

	local priceLabel              = Instance.new("TextLabel")
	priceLabel.Size               = UDim2.new(1, -8, 0, 20)
	priceLabel.Position           = UDim2.fromOffset(4, 92)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font               = Enum.Font.GothamBold
	priceLabel.TextSize           = 12
	priceLabel.TextColor3         = Color3.fromRGB(255, 215, 100)
	priceLabel.TextXAlignment     = Enum.TextXAlignment.Center
	priceLabel.Text               = formatRupiah(sellPrice)
	priceLabel.ZIndex             = 5
	priceLabel.Parent             = cell

	local countLabel              = Instance.new("TextLabel")
	countLabel.Size               = UDim2.fromOffset(28, 16)
	countLabel.AnchorPoint        = Vector2.new(1, 0)
	countLabel.Position           = UDim2.new(1, -2, 0, 2)
	countLabel.BackgroundTransparency = 1
	countLabel.Font               = Enum.Font.GothamBold
	countLabel.TextSize           = 10
	countLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
	countLabel.TextXAlignment     = Enum.TextXAlignment.Right
	countLabel.Text               = "x" .. tostring(inventoryEntry.amount or 1)
	countLabel.ZIndex             = 6
	countLabel.Parent             = cell

	cell.Activated:Connect(function()
		local itemName = (cfg and cfg.nameKey) or inventoryEntry.id
		local msg      = "Jual " .. itemName .. " seharga " .. formatRupiah(sellPrice) .. "?"
		showConfirm(msg, function()
			local gui = buildGui()
			_shopService:SellItem(_currentShopId, inventoryEntry.id, 1):andThen(function(ok, reason)
				if ok then
					gui.statusLabel.Text       = "Berhasil dijual!"
					gui.statusLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
				else
					local msg2 = "Gagal: " .. tostring(reason or "")
					if reason == "low_morality" then
						msg2 = "NPC menolakmu."
					end
					gui.statusLabel.Text       = msg2
					gui.statusLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
				end
			end)
		end)
	end)

	return cell
end

-- ── Render tabs ───────────────────────────────────────────────────

local function clearScroll()
	local gui = buildGui()
	for _, child in gui.scroll:GetChildren() do
		if child:IsA("TextButton") or child:IsA("Frame") then
			child:Destroy()
		end
	end
	gui.statusLabel.Text = ""
end

local function renderBeli()
	clearScroll()
	local gui = buildGui()
	for i, entry in _currentStockData do
		buildBuyCell(gui.scroll, entry, i)
	end
end

local function renderJual(shopCfg)
	clearScroll()
	local gui       = buildGui()
	local inventory = _inventoryController and _inventoryController:getInventory() or {}
	local idx = 1
	for _, entry in inventory do
		local cfg = AssetConfig.getItem(entry.id)
		if cfg then
			local accepted = false
			for _, t in (shopCfg.acceptedTypes or {}) do
				if t == cfg.type then
					accepted = true
					break
				end
			end
			if accepted then
				local sellPrice = math.floor((cfg.basePrice or 0) * (shopCfg.sellMultiplier or 0.6))
				buildSellCell(gui.scroll, entry, sellPrice, idx)
				idx = idx + 1
			end
		end
	end
end

-- ── Show / close ──────────────────────────────────────────────────

local function closeGui()
	if not _gui then
		return
	end
	_gui.sg.Enabled = false
	_currentShopId  = nil
end

local function showGui(shopId, stockData)
	_currentShopId    = shopId
	_currentStockData = stockData or {}

	local gui    = buildGui()
	gui.sg.Enabled = true

	local shopCfg = AssetConfig.getShop(shopId)
	if shopCfg then
		gui.titleLabel.Text = shopCfg.nameKey or shopId
	else
		gui.titleLabel.Text = shopId
	end

	-- Hide tabs that don't apply
	if shopCfg then
		gui.tabBeli.Visible = shopCfg.type ~= "SellOnly"
		gui.tabJual.Visible = shopCfg.type ~= "BuyOnly"
	end

	setActiveTab("Beli")
	renderBeli()
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function ShopController:KnitInit()
end

function ShopController:KnitStart()
	_shopService         = Knit.GetService("ShopService")
	_inventoryController = Knit.GetController("InventoryController")

	_shopService.OpenShop:Connect(function(shopId, stockData)
		showGui(shopId, stockData)
	end)

	task.defer(function()
		local gui = buildGui()

		gui.closeBtn.Activated:Connect(closeGui)
		gui.backdrop.Activated:Connect(closeGui)

		gui.tabBeli.Activated:Connect(function()
			local shopCfg = AssetConfig.getShop(_currentShopId)
			setActiveTab("Beli")
			renderBeli()
		end)

		gui.tabJual.Activated:Connect(function()
			local shopCfg = AssetConfig.getShop(_currentShopId)
			if shopCfg then
				setActiveTab("Jual")
				renderJual(shopCfg)
			end
		end)
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function ShopController:openShop(shopId)
	if not _shopService then
		return
	end
	_shopService.RequestOpenShop:Fire(shopId)
end

return ShopController
