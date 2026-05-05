-- LocalScript: StarterPlayerScripts/Client/Controllers/GaleriController
-- Renders the Galeri grid UI on GaleriData signal from GaleriService.
-- Own galeri: slot cells are clickable to assign collectibles via PlaceCollectible.
-- Visited galeri: read-only display.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local GaleriController = Knit.CreateController { Name = "GaleriController" }

-- ── State ─────────────────────────────────────────────────────────

local _galeriService  = nil
local _cachedLayouts  = {} -- [userId] = layout table
local _gui            = nil
local _currentOwnerId = nil
local _isOwner        = false

-- ── UI: close ─────────────────────────────────────────────────────

local function closeGui()
	if not _gui then
		return
	end
	_gui.sg.Enabled  = false
	_currentOwnerId  = nil
	_isOwner         = false
end

-- ── UI: slot cell ─────────────────────────────────────────────────

local function buildSlotCell(parent, slot, itemId, isOwner)
	local btn                 = Instance.new("TextButton")
	btn.Name                  = "Slot_" .. slot
	btn.Size                  = UDim2.fromOffset(80, 80)
	btn.BackgroundColor3      = Color3.fromRGB(30, 30, 48)
	btn.BorderSizePixel       = 0
	btn.Text                  = ""
	btn.LayoutOrder           = slot
	btn.ZIndex                = 4
	btn.Parent                = parent

	local btnCorner       = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent       = btn

	local rarityBar              = Instance.new("Frame")
	rarityBar.Size               = UDim2.new(1, 0, 0, 4)
	rarityBar.Position           = UDim2.new(0, 0, 1, -4)
	rarityBar.BorderSizePixel    = 0
	rarityBar.ZIndex             = 5
	rarityBar.Parent             = btn

	local nameLabel              = Instance.new("TextLabel")
	nameLabel.Size               = UDim2.new(1, -4, 1, -8)
	nameLabel.Position           = UDim2.fromOffset(2, 2)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font               = Enum.Font.Gotham
	nameLabel.TextSize           = 11
	nameLabel.TextWrapped        = true
	nameLabel.ZIndex             = 5
	nameLabel.Parent             = btn

	if itemId then
		local cfg = AssetConfig.getItem(itemId)
		if cfg then
			nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			nameLabel.Text       = cfg.nameKey

			local rarityInfo = AssetConfig.Rarity and AssetConfig.Rarity[cfg.rarity]
			if rarityInfo then
				rarityBar.BackgroundColor3 = rarityInfo.color
			else
				rarityBar.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
			end
		else
			nameLabel.TextColor3        = Color3.fromRGB(160, 160, 160)
			nameLabel.Text              = itemId
			rarityBar.BackgroundColor3  = Color3.fromRGB(180, 180, 180)
		end
	else
		nameLabel.TextColor3       = Color3.fromRGB(60, 60, 80)
		nameLabel.Text             = tostring(slot)
		rarityBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)

		if isOwner then
			btn.BackgroundColor3 = Color3.fromRGB(20, 20, 36)
		end
	end

	return btn
end

-- ── UI: build root GUI (lazy) ─────────────────────────────────────

local function buildGui()
	if _gui then
		return _gui
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "GaleriGui"
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
	panel.Size                        = UDim2.fromOffset(480, 520)
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

	local titleLabel             = Instance.new("TextLabel")
	titleLabel.Name              = "Title"
	titleLabel.Size              = UDim2.new(1, -80, 0, 36)
	titleLabel.Position          = UDim2.fromOffset(16, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font              = Enum.Font.GothamBold
	titleLabel.TextSize          = 18
	titleLabel.TextColor3        = Color3.fromRGB(255, 215, 0)
	titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
	titleLabel.Text              = "Galeri Koleksi"
	titleLabel.ZIndex            = 3
	titleLabel.Parent            = panel

	local closeBtn               = Instance.new("TextButton")
	closeBtn.Name                = "Close"
	closeBtn.Size                = UDim2.fromOffset(32, 32)
	closeBtn.Position            = UDim2.new(1, -44, 0, 10)
	closeBtn.BackgroundColor3    = Color3.fromRGB(180, 40, 40)
	closeBtn.BorderSizePixel     = 0
	closeBtn.Font                = Enum.Font.GothamBold
	closeBtn.TextSize            = 16
	closeBtn.TextColor3          = Color3.fromRGB(255, 255, 255)
	closeBtn.Text                = "✕"
	closeBtn.ZIndex              = 3
	closeBtn.Parent              = panel

	local closeCorner       = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent       = closeBtn

	local scroll              = Instance.new("ScrollingFrame")
	scroll.Name               = "Scroll"
	scroll.Size               = UDim2.new(1, -32, 1, -64)
	scroll.Position           = UDim2.fromOffset(16, 56)
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

	_gui = {
		sg        = sg,
		backdrop  = backdrop,
		panel     = panel,
		titleLabel = titleLabel,
		scroll    = scroll,
		closeBtn  = closeBtn,
	}
	return _gui
end

-- ── UI: populate grid from layout ────────────────────────────────

local function showGui(targetUserId, layout, isOwner)
	_currentOwnerId = targetUserId
	_isOwner        = isOwner

	local gui = buildGui()
	gui.sg.Enabled = true

	if isOwner then
		gui.titleLabel.Text = "Galeri Saya"
	else
		gui.titleLabel.Text = "Galeri Kolektor #" .. tostring(targetUserId)
	end

	-- Clear existing slots
	for _, child in gui.scroll:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Render 20 slots
	for slot = 1, 20 do
		local itemId = layout[tostring(slot)]
		local cell   = buildSlotCell(gui.scroll, slot, itemId, isOwner)

		-- Owner: tap empty slot to assign a collectible (fires PlaceCollectible from inventory)
		if isOwner and not itemId then
			local slotCapture = slot
			cell.Activated:Connect(function()
				-- Placeholder: a full implementation would open an item picker overlay.
				-- For now the signal hook is wired but the picker is deferred to Phase 8 UI.
				warn("[GaleriController] PlaceCollectible picker not yet implemented for slot " .. slotCapture)
			end)
		end
	end
end

-- ── Visit notification ────────────────────────────────────────────

local function showVisitNotif(visitorName)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "GaleriVisitNotif"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = true
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Parent             = playerGui

	local label              = Instance.new("TextLabel")
	label.Size               = UDim2.fromOffset(260, 36)
	label.AnchorPoint        = Vector2.new(1, 0)
	label.Position           = UDim2.new(1, 16, 0, 80)
	label.BackgroundColor3   = Color3.fromRGB(40, 40, 60)
	label.BackgroundTransparency = 0.2
	label.BorderSizePixel    = 0
	label.Font               = Enum.Font.Gotham
	label.TextSize           = 13
	label.TextColor3         = Color3.fromRGB(200, 200, 255)
	label.Text               = visitorName .. " mengunjungi galeri Anda"
	label.Parent             = sg

	local labelCorner       = Instance.new("UICorner")
	labelCorner.CornerRadius = UDim.new(0, 8)
	labelCorner.Parent       = label

	TweenService:Create(
		label,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(1, -16, 0, 80) }
	):Play()

	task.delay(3, function()
		local out = TweenService:Create(
			label,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 16, 0, 80) }
		)
		out:Play()
		out.Completed:Connect(function()
			sg:Destroy()
		end)
	end)
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function GaleriController:KnitInit()
end

function GaleriController:KnitStart()
	_galeriService = Knit.GetService("GaleriService")

	_galeriService.GaleriData:Connect(function(targetUserId, layout, isOwner)
		_cachedLayouts[targetUserId] = layout
		showGui(targetUserId, layout, isOwner)
	end)

	_galeriService.GaleriVisited:Connect(function(visitorName)
		showVisitNotif(visitorName)
	end)

	-- Wire close/backdrop after GUI is lazily constructed
	task.defer(function()
		local gui = buildGui()
		gui.closeBtn.Activated:Connect(closeGui)
		gui.backdrop.Activated:Connect(closeGui)
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function GaleriController:openGaleri(targetUserId)
	if not _galeriService then
		return
	end
	_galeriService.OpenGaleri:Fire(targetUserId)
end

function GaleriController:placeCollectible(itemId, slot)
	if not _galeriService then
		return
	end
	_galeriService.PlaceCollectible:Fire(itemId, slot)
end

function GaleriController:getGaleriLayout(userId)
	return _cachedLayouts[userId] or {}
end

return GaleriController
