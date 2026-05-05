-- LocalScript: StarterPlayerScripts/Client/Controllers/TravelController
-- Listens to TravelService.OpenTravelMap and shows Indonesia archipelago map.
-- Phase 8: Full-screen map with island buttons at geographic positions.
-- Phase 10: Zone dots ≥ 30px (MobileUtil.MIN_MAP_DOT_PX) on all platforms.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)
local MobileUtil  = require(ReplicatedStorage:WaitForChild("Shared").Modules.MobileUtil)

local DOT_SIZE = math.max(MobileUtil.MIN_MAP_DOT_PX, MobileUtil.IS_MOBILE and 36 or 30)

local TravelController = Knit.CreateController { Name = "TravelController" }

-- ── State ─────────────────────────────────────────────────────────

local _gui           = nil
local _travelService = nil
local _selectedDest  = nil

-- ── Geographic island positions (UDim2.fromScale on map canvas) ───
-- Approximate positions on a 2:1 aspect-ratio Indonesia map image.
-- X=west-to-east (0=far west), Y=north-to-south (0=north).

local ISLAND_POSITIONS = {
	Sumatera     = Vector2.new(0.10, 0.38),
	Jawa         = Vector2.new(0.28, 0.58),
	Kalimantan   = Vector2.new(0.38, 0.28),
	Sulawesi     = Vector2.new(0.55, 0.35),
	NusaTenggara = Vector2.new(0.48, 0.68),
	Maluku       = Vector2.new(0.70, 0.42),
	Papua        = Vector2.new(0.85, 0.38),
}

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

	-- Full-screen backdrop (also close button)
	local backdrop = Instance.new("TextButton")
	backdrop.Name                   = "Backdrop"
	backdrop.Size                   = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3       = Color3.fromRGB(10, 10, 30)
	backdrop.BackgroundTransparency = 0.1
	backdrop.BorderSizePixel        = 0
	backdrop.Text                   = ""
	backdrop.ZIndex                 = 1
	backdrop.Parent                 = sg

	-- Map canvas: 2:1 aspect ratio centered
	local mapCanvas = Instance.new("Frame")
	mapCanvas.Name                   = "MapCanvas"
	mapCanvas.Size                   = UDim2.fromScale(0.92, 0)
	mapCanvas.AnchorPoint            = Vector2.new(0.5, 0.5)
	mapCanvas.Position               = UDim2.fromScale(0.5, 0.5)
	mapCanvas.BackgroundColor3       = Color3.fromRGB(30, 60, 100)
	mapCanvas.BackgroundTransparency = 0
	mapCanvas.BorderSizePixel        = 0
	mapCanvas.ZIndex                 = 2
	mapCanvas.Parent                 = sg

	-- Maintain 2:1 ratio via UIAspectRatioConstraint
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 2
	ratio.DominantAxis = Enum.DominantAxis.Width
	ratio.Parent       = mapCanvas

	local mapCorner = Instance.new("UICorner")
	mapCorner.CornerRadius = UDim.new(0, 10)
	mapCorner.Parent       = mapCanvas

	-- Map background image (Indonesia archipelago illustration)
	local mapImg = Instance.new("ImageLabel")
	mapImg.Name                  = "MapImage"
	mapImg.Size                  = UDim2.fromScale(1, 1)
	mapImg.BackgroundTransparency = 1
	mapImg.Image                 = "rbxassetid://0"  -- placeholder; fill in ASSETS §4.4
	mapImg.ScaleType             = Enum.ScaleType.Stretch
	mapImg.ZIndex                = 3
	mapImg.Parent                = mapCanvas

	-- Title bar at top of canvas
	local titleBar = Instance.new("Frame")
	titleBar.Name                   = "TitleBar"
	titleBar.Size                   = UDim2.new(1, 0, 0, 36)
	titleBar.Position               = UDim2.fromOffset(0, 0)
	titleBar.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	titleBar.BackgroundTransparency = 0.4
	titleBar.BorderSizePixel        = 0
	titleBar.ZIndex                 = 4
	titleBar.Parent                 = mapCanvas

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name              = "Title"
	titleLabel.Size              = UDim2.new(1, -48, 1, 0)
	titleLabel.Position          = UDim2.fromOffset(12, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font              = Enum.Font.GothamBold
	titleLabel.TextSize          = 16
	titleLabel.TextColor3        = Color3.fromRGB(255, 215, 0)
	titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
	titleLabel.Text              = "Peta Perjalanan Indonesia"
	titleLabel.ZIndex            = 5
	titleLabel.Parent            = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name                  = "Close"
	closeBtn.Size                  = UDim2.fromOffset(30, 30)
	closeBtn.Position              = UDim2.new(1, -34, 0, 3)
	closeBtn.BackgroundColor3      = Color3.fromRGB(180, 40, 40)
	closeBtn.BorderSizePixel       = 0
	closeBtn.Font                  = Enum.Font.GothamBold
	closeBtn.TextSize              = 14
	closeBtn.TextColor3            = Color3.fromRGB(255, 255, 255)
	closeBtn.Text                  = "✕"
	closeBtn.ZIndex                = 5
	closeBtn.Parent                = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 5)
	closeCorner.Parent       = closeBtn

	-- Bottom info bar
	local infoBar = Instance.new("Frame")
	infoBar.Name                   = "InfoBar"
	infoBar.Size                   = UDim2.new(1, 0, 0, 52)
	infoBar.Position               = UDim2.new(0, 0, 1, -52)
	infoBar.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	infoBar.BackgroundTransparency = 0.4
	infoBar.BorderSizePixel        = 0
	infoBar.ZIndex                 = 4
	infoBar.Parent                 = mapCanvas

	local balanceLabel = Instance.new("TextLabel")
	balanceLabel.Name              = "Balance"
	balanceLabel.Size              = UDim2.fromScale(0.45, 1)
	balanceLabel.Position          = UDim2.fromOffset(12, 0)
	balanceLabel.BackgroundTransparency = 1
	balanceLabel.Font              = Enum.Font.Gotham
	balanceLabel.TextSize          = 13
	balanceLabel.TextColor3        = Color3.fromRGB(180, 255, 180)
	balanceLabel.TextXAlignment    = Enum.TextXAlignment.Left
	balanceLabel.Text              = ""
	balanceLabel.ZIndex            = 5
	balanceLabel.Parent            = infoBar

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name                  = "Confirm"
	confirmBtn.Size                  = UDim2.fromOffset(160, 36)
	confirmBtn.AnchorPoint           = Vector2.new(1, 0.5)
	confirmBtn.Position              = UDim2.new(1, -12, 0.5, 0)
	confirmBtn.BackgroundColor3      = Color3.fromRGB(80, 80, 80)
	confirmBtn.BorderSizePixel       = 0
	confirmBtn.Font                  = Enum.Font.GothamBold
	confirmBtn.TextSize              = 14
	confirmBtn.TextColor3            = Color3.fromRGB(255, 255, 255)
	confirmBtn.Text                  = "Pilih Tujuan"
	confirmBtn.AutoButtonColor       = false
	confirmBtn.Active                = false
	confirmBtn.ZIndex                = 5
	confirmBtn.Parent                = infoBar

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 6)
	confirmCorner.Parent       = confirmBtn

	-- Island buttons container (inside mapCanvas, above mapImg)
	local islandLayer = Instance.new("Frame")
	islandLayer.Name                   = "IslandLayer"
	islandLayer.Size                   = UDim2.fromScale(1, 1)
	islandLayer.BackgroundTransparency = 1
	islandLayer.ZIndex                 = 6
	islandLayer.Parent                 = mapCanvas

	-- Zone dot container (shown when island selected)
	local zoneLayer = Instance.new("Frame")
	zoneLayer.Name                   = "ZoneLayer"
	zoneLayer.Size                   = UDim2.fromScale(1, 1)
	zoneLayer.BackgroundTransparency = 1
	zoneLayer.ZIndex                 = 7
	zoneLayer.Parent                 = mapCanvas

	_gui = {
		sg           = sg,
		backdrop     = backdrop,
		mapCanvas    = mapCanvas,
		balanceLabel = balanceLabel,
		confirmBtn   = confirmBtn,
		closeBtn     = closeBtn,
		islandLayer  = islandLayer,
		zoneLayer    = zoneLayer,
	}
	return _gui
end

-- ── Island button builder ─────────────────────────────────────────

local function buildIslandButton(islandId, placeCfg, unlocked, isCurrent, geoPct)
	local btn = Instance.new("TextButton")
	btn.Name            = "Island_" .. islandId
	btn.Size            = UDim2.fromOffset(72, 30)
	btn.AnchorPoint     = Vector2.new(0.5, 0.5)
	btn.Position        = UDim2.fromScale(geoPct.X, geoPct.Y)
	btn.BorderSizePixel = 0
	btn.Font            = Enum.Font.GothamBold
	btn.TextSize        = 11
	btn.TextColor3      = Color3.fromRGB(255, 255, 255)
	btn.Text            = placeCfg.nameKey
	btn.ZIndex          = 8

	if isCurrent then
		btn.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
	elseif unlocked then
		btn.BackgroundColor3 = Color3.fromRGB(40, 150, 60)
	else
		btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	end

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent       = btn

	-- Pulse indicator for current island
	if isCurrent then
		local dot = Instance.new("Frame")
		dot.Size            = UDim2.fromOffset(8, 8)
		dot.AnchorPoint     = Vector2.new(1, 0)
		dot.Position        = UDim2.fromScale(1, 0)
		dot.BackgroundColor3 = Color3.fromRGB(255, 220, 50)
		dot.BorderSizePixel  = 0
		dot.ZIndex           = 9
		dot.Parent           = btn
		local dotCorner      = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(0.5, 0)
		dotCorner.Parent     = dot
	end

	return btn
end

-- ── Zone dot builder ──────────────────────────────────────────────

local function buildZoneDot(dest, onSelect)
	local dot = Instance.new("TextButton")
	dot.Name            = "Zone_" .. (dest.zoneId or dest.nameKey)
	dot.Size            = UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
	dot.AnchorPoint     = Vector2.new(0.5, 0.5)
	dot.BorderSizePixel = 0
	dot.Text            = ""
	dot.ZIndex          = 10

	-- Position based on zone bounds center (if available), else near island center
	local zoneCfg = dest.zoneId and AssetConfig.getZone(dest.zoneId)
	local bounds  = zoneCfg and AssetConfig.ZoneBounds[dest.zoneId]
	if bounds then
		local cx = (bounds.xMin + bounds.xMax) * 0.5
		local cz = (bounds.zMin + bounds.zMax) * 0.5
		-- Normalize cx, cz to [0,1] over a rough -2000..2000 world range
		local nx = math.clamp((cx + 2000) / 4000, 0.02, 0.98)
		local nz = math.clamp((cz + 2000) / 4000, 0.02, 0.98)
		dot.Position = UDim2.fromScale(nx, nz)
	else
		dot.Position = UDim2.fromScale(0.5, 0.5)
	end

	if not dest.canTravel then
		dot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	elseif dest.unlocked then
		dot.BackgroundColor3 = Color3.fromRGB(80, 220, 100)
	else
		dot.BackgroundColor3 = Color3.fromRGB(200, 140, 40)
	end

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent       = dot

	-- Label
	local lbl = Instance.new("TextLabel")
	lbl.Size                 = UDim2.fromOffset(80, 16)
	lbl.AnchorPoint          = Vector2.new(0.5, 1)
	lbl.Position             = UDim2.fromScale(0.5, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font                 = Enum.Font.Gotham
	lbl.TextSize             = 9
	lbl.TextColor3           = Color3.fromRGB(220, 220, 220)
	lbl.Text                 = dest.nameKey
	lbl.ZIndex               = 11
	lbl.Parent               = dot

	if dest.canTravel and dest.unlocked then
		dot.Activated:Connect(function()
			onSelect(dest, dot)
		end)
	end

	return dot
end

-- ── Show / hide ───────────────────────────────────────────────────

local function closeGui()
	if not _gui then return end
	_gui.sg.Enabled = false
	_selectedDest   = nil
end

local function clearLayer(layer)
	for _, child in layer:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function showGui(payload)
	_selectedDest = nil

	local gui = buildGui()
	gui.sg.Enabled = true

	gui.balanceLabel.Text  = "Saldo: Rp " .. tostring(payload.rupiah or 0)
	gui.confirmBtn.Active  = false
	gui.confirmBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	gui.confirmBtn.Text    = "Pilih Tujuan"

	clearLayer(gui.islandLayer)
	clearLayer(gui.zoneLayer)

	-- Group destinations by place
	local byPlace = {}
	for _, dest in payload.destinations do
		local placeId = dest.placeId or "Jawa"
		if not byPlace[placeId] then
			byPlace[placeId] = {}
		end
		table.insert(byPlace[placeId], dest)
	end

	local currentPlace = payload.currentPlace or "Jawa"

	local function onSelectDest(dest, _)
		-- Reset dot colors
		for _, child in gui.zoneLayer:GetChildren() do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = Color3.fromRGB(80, 220, 100)
			end
		end

		_selectedDest = dest
		gui.confirmBtn.Active           = true
		gui.confirmBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 60)
		gui.confirmBtn.Text             = "Berangkat — Rp " .. tostring(dest.cost)
	end

	-- Build island buttons
	for islandId, placeCfg in AssetConfig.Places do
		local geoPct  = ISLAND_POSITIONS[islandId]
		if not geoPct then continue end

		local isCurrent = (islandId == currentPlace)
		local hasZones  = byPlace[islandId] ~= nil
		local unlocked  = hasZones

		local islandBtn = buildIslandButton(islandId, placeCfg, unlocked, isCurrent, geoPct)
		islandBtn.Parent = gui.islandLayer

		if hasZones then
			islandBtn.Activated:Connect(function()
				-- Highlight island button
				for _, ib in gui.islandLayer:GetChildren() do
					if ib:IsA("TextButton") then
						local isCur = ib.Name == ("Island_" .. currentPlace)
						if ib.Name == islandBtn.Name then
							ib.BackgroundColor3 = Color3.fromRGB(60, 160, 220)
						elseif isCur then
							ib.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
						else
							ib.BackgroundColor3 = Color3.fromRGB(40, 150, 60)
						end
					end
				end

				-- Rebuild zone dots for this island
				clearLayer(gui.zoneLayer)

				-- Position zone layer near island
				gui.zoneLayer.Position = UDim2.fromOffset(0, 0)

				for _, dest in byPlace[islandId] do
					local dot = buildZoneDot(dest, onSelectDest)
					dot.Parent = gui.zoneLayer
				end
			end)
		end
	end

	-- If only one destination or current place, auto-expand current island
	if byPlace[currentPlace] then
		for _, dest in byPlace[currentPlace] do
			local dot = buildZoneDot(dest, onSelectDest)
			dot.Parent = gui.zoneLayer
		end
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

-- ── Public API ────────────────────────────────────────────────────

function TravelController:openTravelMap()
	if not _travelService then return end
	_travelService.OpenTravelMap:Fire()
end

return TravelController
