-- LocalScript: StarterPlayerScripts/Client/Controllers/TravelController
-- Listens to TravelService.OpenTravelMap and shows destination list UI.
-- Player taps a destination → confirm dialog → fires TeleportToPlace or FerryTravel.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local TravelController = Knit.CreateController { Name = "TravelController" }

-- ── State ─────────────────────────────────────────────────────────

local _gui           = nil
local _travelService = nil
local _payload       = nil   -- current OpenTravelMap payload
local _selectedDest  = nil   -- currently highlighted destination

-- ── UI building ───────────────────────────────────────────────────

local function buildGui()
	if _gui then return _gui end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg = Instance.new("ScreenGui")
	sg.Name           = "TravelMapGui"
	sg.ResetOnSpawn   = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Enabled        = false
	sg.Parent         = playerGui

	-- Backdrop
	local backdrop = Instance.new("TextButton")
	backdrop.Name                   = "Backdrop"
	backdrop.Size                   = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel        = 0
	backdrop.Text                   = ""
	backdrop.ZIndex                 = 1
	backdrop.Parent                 = sg

	-- Main panel
	local panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.Size                   = UDim2.fromOffset(400, 480)
	panel.AnchorPoint            = Vector2.new(0.5, 0.5)
	panel.Position               = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3       = Color3.fromRGB(18, 18, 28)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel        = 0
	panel.ZIndex                 = 2
	panel.Parent                 = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent       = panel

	-- Title
	local title = Instance.new("TextLabel")
	title.Name               = "Title"
	title.Size               = UDim2.new(1, -48, 0, 36)
	title.Position           = UDim2.fromOffset(16, 12)
	title.BackgroundTransparency = 1
	title.Font               = Enum.Font.GothamBold
	title.TextSize           = 18
	title.TextColor3         = Color3.fromRGB(255, 215, 0)
	title.TextXAlignment     = Enum.TextXAlignment.Left
	title.Text               = "Peta Perjalanan"
	title.ZIndex             = 3
	title.Parent             = panel

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name                   = "Close"
	closeBtn.Size                   = UDim2.fromOffset(32, 32)
	closeBtn.Position               = UDim2.new(1, -44, 0, 10)
	closeBtn.BackgroundColor3       = Color3.fromRGB(180, 40, 40)
	closeBtn.BorderSizePixel        = 0
	closeBtn.Font                   = Enum.Font.GothamBold
	closeBtn.TextSize               = 16
	closeBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
	closeBtn.Text                   = "✕"
	closeBtn.ZIndex                 = 3
	closeBtn.Parent                 = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent       = closeBtn

	-- Balance label
	local balance = Instance.new("TextLabel")
	balance.Name               = "Balance"
	balance.Size               = UDim2.new(1, -32, 0, 22)
	balance.Position           = UDim2.fromOffset(16, 52)
	balance.BackgroundTransparency = 1
	balance.Font               = Enum.Font.Gotham
	balance.TextSize           = 13
	balance.TextColor3         = Color3.fromRGB(180, 255, 180)
	balance.TextXAlignment     = Enum.TextXAlignment.Left
	balance.Text               = ""
	balance.ZIndex             = 3
	balance.Parent             = panel

	-- Separator
	local sep = Instance.new("Frame")
	sep.Name                   = "Sep"
	sep.Size                   = UDim2.new(1, -32, 0, 1)
	sep.Position               = UDim2.fromOffset(16, 78)
	sep.BackgroundColor3       = Color3.fromRGB(60, 60, 80)
	sep.BorderSizePixel        = 0
	sep.ZIndex                 = 3
	sep.Parent                 = panel

	-- Destinations scroll
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name               = "Scroll"
	scroll.Size               = UDim2.new(1, -32, 1, -160)
	scroll.Position           = UDim2.fromOffset(16, 88)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel    = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
	scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
	scroll.CanvasSize           = UDim2.fromScale(0, 0)
	scroll.ZIndex               = 3
	scroll.Parent               = panel

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding         = UDim.new(0, 6)
	listLayout.SortOrder       = Enum.SortOrder.LayoutOrder
	listLayout.Parent          = scroll

	-- Confirm button (bottom)
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name                   = "Confirm"
	confirmBtn.Size                   = UDim2.new(1, -32, 0, 44)
	confirmBtn.Position               = UDim2.new(0, 16, 1, -56)
	confirmBtn.BackgroundColor3       = Color3.fromRGB(40, 150, 60)
	confirmBtn.BorderSizePixel        = 0
	confirmBtn.Font                   = Enum.Font.GothamBold
	confirmBtn.TextSize               = 15
	confirmBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
	confirmBtn.Text                   = "Berangkat"
	confirmBtn.AutoButtonColor        = false
	confirmBtn.ZIndex                 = 3
	confirmBtn.Active                 = false
	confirmBtn.Parent                 = panel

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 8)
	confirmCorner.Parent       = confirmBtn

	_gui = {
		sg         = sg,
		backdrop   = backdrop,
		panel      = panel,
		title      = title,
		balance    = balance,
		scroll     = scroll,
		confirmBtn = confirmBtn,
		closeBtn   = closeBtn,
	}
	return _gui
end

-- ── Destination row builder ───────────────────────────────────────

local function buildDestRow(dest, index, onSelect)
	local row = Instance.new("TextButton")
	row.Name                   = "Dest_" .. index
	row.Size                   = UDim2.new(1, -4, 0, 52)
	row.BackgroundColor3       = Color3.fromRGB(30, 30, 48)
	row.BorderSizePixel        = 0
	row.Text                   = ""
	row.LayoutOrder            = index
	row.ZIndex                 = 4

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent       = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size               = UDim2.new(1, -90, 0, 24)
	nameLabel.Position           = UDim2.fromOffset(10, 6)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font               = Enum.Font.GothamBold
	nameLabel.TextSize           = 14
	nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
	nameLabel.ZIndex             = 5
	nameLabel.Parent             = row

	local costLabel = Instance.new("TextLabel")
	costLabel.Size               = UDim2.new(1, -90, 0, 18)
	costLabel.Position           = UDim2.fromOffset(10, 28)
	costLabel.BackgroundTransparency = 1
	costLabel.Font               = Enum.Font.Gotham
	costLabel.TextSize           = 12
	costLabel.TextXAlignment     = Enum.TextXAlignment.Left
	costLabel.ZIndex             = 5
	costLabel.Parent             = row

	local badge = Instance.new("TextLabel")
	badge.Size               = UDim2.fromOffset(72, 26)
	badge.Position           = UDim2.new(1, -80, 0.5, -13)
	badge.BackgroundTransparency = 0
	badge.BorderSizePixel    = 0
	badge.Font               = Enum.Font.GothamBold
	badge.TextSize           = 11
	badge.TextColor3         = Color3.fromRGB(255, 255, 255)
	badge.TextXAlignment     = Enum.TextXAlignment.Center
	badge.ZIndex             = 5
	badge.Parent             = row

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 5)
	badgeCorner.Parent       = badge

	-- Populate content
	nameLabel.Text = dest.nameKey  -- placeholder until localization; GDD §17 maps keys

	local costText = "Rp " .. tostring(dest.cost)
	costLabel.Text = costText

	if not dest.canTravel then
		nameLabel.TextColor3  = Color3.fromRGB(100, 100, 100)
		costLabel.TextColor3  = Color3.fromRGB(100, 100, 100)
		badge.Text            = "Belum Tersedia"
		badge.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		row.Active            = false
	elseif dest.unlocked then
		nameLabel.TextColor3  = Color3.fromRGB(230, 230, 230)
		costLabel.TextColor3  = Color3.fromRGB(180, 180, 180)
		badge.Text            = "Tersedia"
		badge.BackgroundColor3 = Color3.fromRGB(40, 150, 60)
		row.Active            = true
		row.Activated:Connect(function()
			onSelect(dest, row)
		end)
	else
		nameLabel.TextColor3  = Color3.fromRGB(130, 110, 80)
		costLabel.TextColor3  = Color3.fromRGB(100, 90, 70)
		badge.Text            = "Terkunci"
		badge.BackgroundColor3 = Color3.fromRGB(120, 80, 20)
		row.Active            = false
	end

	return row
end

-- ── Show / hide ───────────────────────────────────────────────────

local function closeGui()
	if not _gui then return end
	_gui.sg.Enabled = false
	_selectedDest   = nil
end

local function showGui(payload)
	_payload      = payload
	_selectedDest = nil

	local gui = buildGui()
	gui.sg.Enabled = true

	-- Title
	local modeLabel = payload.mode == "Bandara" and "Bandara" or "Pelabuhan"
	gui.title.Text = "Peta Perjalanan — " .. modeLabel

	-- Balance
	gui.balance.Text = "Saldo: Rp " .. tostring(payload.rupiah or 0)

	-- Clear previous rows
	for _, child in gui.scroll:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	gui.confirmBtn.Active           = false
	gui.confirmBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	gui.confirmBtn.Text             = "Pilih Tujuan"

	local function onSelectDest(dest, row)
		-- Deselect previous
		for _, child in gui.scroll:GetChildren() do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
			end
		end

		_selectedDest = dest
		row.BackgroundColor3 = Color3.fromRGB(50, 50, 80)

		gui.confirmBtn.Active           = true
		gui.confirmBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 60)
		gui.confirmBtn.Text             = "Berangkat — Rp " .. tostring(dest.cost)
	end

	-- Build destination rows
	for i, dest in payload.destinations do
		local row = buildDestRow(dest, i, onSelectDest)
		row.Parent = gui.scroll
	end
end

-- ── Confirm handler ───────────────────────────────────────────────

local function onConfirm()
	local dest = _selectedDest
	if not dest then return end
	if not _travelService then return end

	closeGui()

	if dest.type == "Place" then
		_travelService.TeleportToPlace:Fire(dest.placeId, dest.zoneId)
	else
		_travelService.FerryTravel:Fire(dest.zoneId)
	end
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function TravelController:KnitInit()
end

function TravelController:KnitStart()
	_travelService = Knit.GetService("TravelService")

	_travelService.OpenTravelMap:Connect(function(payload)
		showGui(payload)
	end)

	-- Wire close / confirm after UI is built on first show
	task.defer(function()
		local gui = buildGui()

		gui.closeBtn.Activated:Connect(closeGui)
		gui.backdrop.Activated:Connect(closeGui)

		gui.confirmBtn.Activated:Connect(function()
			if gui.confirmBtn.Active then
				onConfirm()
			end
		end)
	end)
end

return TravelController
