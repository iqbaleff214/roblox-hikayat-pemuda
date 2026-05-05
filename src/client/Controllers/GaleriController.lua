-- LocalScript: StarterPlayerScripts/Client/Controllers/GaleriController
-- Phase 7: renders Galeri grid UI on GaleriData signal.
-- Phase 8: adds "Suka" button for visited galeris, shows owner name + collectible count.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local GaleriController = Knit.CreateController { Name = "GaleriController" }

-- ── State ─────────────────────────────────────────────────────────

local _galeriService  = nil
local _cachedLayouts  = {}
local _gui            = nil
local _currentOwnerId = nil
local _isOwner        = false

-- ── UI: close ─────────────────────────────────────────────────────

local function closeGui()
	if not _gui then return end
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
			nameLabel.TextColor3       = Color3.fromRGB(160, 160, 160)
			nameLabel.Text             = itemId
			rarityBar.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
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
	if _gui then return _gui end

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
	panel.Size                        = UDim2.fromOffset(480, 560)
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

	-- Title row (title + close button)
	local titleLabel             = Instance.new("TextLabel")
	titleLabel.Name              = "Title"
	titleLabel.Size              = UDim2.new(1, -96, 0, 36)
	titleLabel.Position          = UDim2.fromOffset(16, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font              = Enum.Font.GothamBold
	titleLabel.TextSize          = 17
	titleLabel.TextColor3        = Color3.fromRGB(255, 215, 0)
	titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
	titleLabel.Text              = "Galeri Koleksi"
	titleLabel.ZIndex            = 3
	titleLabel.Parent            = panel

	-- Suka button (only visible when visiting)
	local sukaBtn                = Instance.new("TextButton")
	sukaBtn.Name                 = "SukaBtn"
	sukaBtn.Size                 = UDim2.fromOffset(56, 28)
	sukaBtn.Position             = UDim2.new(1, -100, 0, 16)
	sukaBtn.BackgroundColor3     = Color3.fromRGB(200, 50, 100)
	sukaBtn.BorderSizePixel      = 0
	sukaBtn.Font                 = Enum.Font.GothamBold
	sukaBtn.TextSize             = 13
	sukaBtn.TextColor3           = Color3.fromRGB(255, 255, 255)
	sukaBtn.Text                 = "♥ Suka"
	sukaBtn.Visible              = false
	sukaBtn.ZIndex               = 3
	sukaBtn.Parent               = panel

	local sukaBtnCorner = Instance.new("UICorner")
	sukaBtnCorner.CornerRadius = UDim.new(0, 6)
	sukaBtnCorner.Parent       = sukaBtn

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

	-- Owner info bar (name + collectible count)
	local ownerBar               = Instance.new("Frame")
	ownerBar.Name                = "OwnerBar"
	ownerBar.Size                = UDim2.new(1, -32, 0, 24)
	ownerBar.Position            = UDim2.fromOffset(16, 50)
	ownerBar.BackgroundTransparency = 1
	ownerBar.ZIndex              = 3
	ownerBar.Parent              = panel

	local ownerNameLbl           = Instance.new("TextLabel")
	ownerNameLbl.Name            = "OwnerName"
	ownerNameLbl.Size            = UDim2.fromScale(0.6, 1)
	ownerNameLbl.BackgroundTransparency = 1
	ownerNameLbl.Font            = Enum.Font.Gotham
	ownerNameLbl.TextSize        = 12
	ownerNameLbl.TextColor3      = Color3.fromRGB(160, 200, 255)
	ownerNameLbl.TextXAlignment  = Enum.TextXAlignment.Left
	ownerNameLbl.Text            = ""
	ownerNameLbl.ZIndex          = 4
	ownerNameLbl.Parent          = ownerBar

	local collectibleCountLbl    = Instance.new("TextLabel")
	collectibleCountLbl.Name     = "CollectibleCount"
	collectibleCountLbl.Size     = UDim2.fromScale(0.4, 1)
	collectibleCountLbl.AnchorPoint = Vector2.new(1, 0)
	collectibleCountLbl.Position = UDim2.fromScale(1, 0)
	collectibleCountLbl.BackgroundTransparency = 1
	collectibleCountLbl.Font     = Enum.Font.Gotham
	collectibleCountLbl.TextSize = 12
	collectibleCountLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	collectibleCountLbl.TextXAlignment = Enum.TextXAlignment.Right
	collectibleCountLbl.Text     = ""
	collectibleCountLbl.ZIndex   = 4
	collectibleCountLbl.Parent   = ownerBar

	local scroll              = Instance.new("ScrollingFrame")
	scroll.Name               = "Scroll"
	scroll.Size               = UDim2.new(1, -32, 1, -86)
	scroll.Position           = UDim2.fromOffset(16, 78)
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
		sg                  = sg,
		backdrop            = backdrop,
		panel               = panel,
		titleLabel          = titleLabel,
		sukaBtn             = sukaBtn,
		scroll              = scroll,
		closeBtn            = closeBtn,
		ownerNameLbl        = ownerNameLbl,
		collectibleCountLbl = collectibleCountLbl,
	}
	return _gui
end

-- ── UI: populate grid from layout ─────────────────────────────────

local function countCollectibles(layout)
	local count = 0
	for _, itemId in layout do
		if itemId then
			count = count + 1
		end
	end
	return count
end

local function resolveOwnerName(targetUserId)
	local player = Players:GetPlayerByUserId(targetUserId)
	if player then
		return player.Name
	end
	local name = "[" .. tostring(targetUserId) .. "]"
	pcall(function()
		name = Players:GetNameFromUserIdAsync(targetUserId)
	end)
	return name
end

local function showGui(targetUserId, layout, isOwner)
	_currentOwnerId = targetUserId
	_isOwner        = isOwner

	local gui = buildGui()
	gui.sg.Enabled = true

	-- Title
	if isOwner then
		gui.titleLabel.Text = "Galeri Saya"
	else
		local ownerName = resolveOwnerName(targetUserId)
		gui.titleLabel.Text = "Galeri " .. ownerName
	end

	-- Owner info bar
	local ownerName = isOwner
		and Players.LocalPlayer.Name
		or  resolveOwnerName(targetUserId)

	gui.ownerNameLbl.Text        = "Kolektor: " .. ownerName
	gui.collectibleCountLbl.Text = tostring(countCollectibles(layout)) .. " koleksi"

	-- Suka button: visible only when visiting someone else
	gui.sukaBtn.Visible = not isOwner
	gui.sukaBtn.Text    = "♥ Suka"

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

		if isOwner and not itemId then
			local slotCapture = slot
			cell.Activated:Connect(function()
				-- Placeholder: open item picker to assign a collectible
				warn("[GaleriController] PlaceCollectible picker not yet implemented for slot " .. slotCapture)
			end)
		end
	end
end

-- ── Visit notification ─────────────────────────────────────────────

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

-- ── Liked notification (owner receives a "Suka") ──────────────────

local function showLikedNotif(likerName)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "GaleriLikedNotif"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = true
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Parent             = playerGui

	local label              = Instance.new("TextLabel")
	label.Size               = UDim2.fromOffset(270, 36)
	label.AnchorPoint        = Vector2.new(1, 0)
	label.Position           = UDim2.new(1, 16, 0, 124)
	label.BackgroundColor3   = Color3.fromRGB(60, 20, 40)
	label.BackgroundTransparency = 0.15
	label.BorderSizePixel    = 0
	label.Font               = Enum.Font.Gotham
	label.TextSize           = 13
	label.TextColor3         = Color3.fromRGB(255, 160, 200)
	label.Text               = "♥ " .. likerName .. " menyukai galeri Anda"
	label.Parent             = sg

	local labelCorner       = Instance.new("UICorner")
	labelCorner.CornerRadius = UDim.new(0, 8)
	labelCorner.Parent       = label

	TweenService:Create(
		label,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(1, -16, 0, 124) }
	):Play()

	task.delay(3.5, function()
		local out = TweenService:Create(
			label,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 16, 0, 124) }
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

	_galeriService.GaleriLiked:Connect(function(likerName)
		showLikedNotif(likerName)
	end)

	task.defer(function()
		local gui = buildGui()

		gui.closeBtn.Activated:Connect(closeGui)
		gui.backdrop.Activated:Connect(closeGui)

		gui.sukaBtn.Activated:Connect(function()
			if _currentOwnerId and not _isOwner then
				_galeriService.GaleriLike:Fire(_currentOwnerId)
				gui.sukaBtn.Text = "♥ Disukai!"
				gui.sukaBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 60)
				gui.sukaBtn.Active = false
			end
		end)
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function GaleriController:openGaleri(targetUserId)
	if not _galeriService then return end
	_galeriService.OpenGaleri:Fire(targetUserId)
end

function GaleriController:placeCollectible(itemId, slot)
	if not _galeriService then return end
	_galeriService.PlaceCollectible:Fire(itemId, slot)
end

function GaleriController:getGaleriLayout(userId)
	return _cachedLayouts[userId] or {}
end

return GaleriController
