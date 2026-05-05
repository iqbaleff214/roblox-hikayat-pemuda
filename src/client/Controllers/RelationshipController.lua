-- LocalScript: StarterPlayerScripts/Client/Controllers/RelationshipController
-- Phase 7: relationship request dialog, nameplate badges, formation notif.
-- Phase 8: SocialGui panel — list current relationships, search online players,
--          send request flow, Hapus button.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local RelationshipController = Knit.CreateController { Name = "RelationshipController" }

-- ── State ─────────────────────────────────────────────────────────

local _relService  = nil
local _requestGui  = nil
local _socialGui   = nil

-- ── Nameplate badges ──────────────────────────────────────────────

local function getCharacterHead(userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return nil end
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("Head")
end

local function applyNameplateBadge(head, relType)
	local existing = head:FindFirstChild("RelBadge")
	if existing then
		existing:Destroy()
	end
	if not relType then return end

	local relCfg = AssetConfig.Relationships[relType]
	if not relCfg then return end

	local billboard       = Instance.new("BillboardGui")
	billboard.Name        = "RelBadge"
	billboard.Size        = UDim2.fromOffset(88, 22)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent      = head

	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.fromScale(1, 1)
	label.BackgroundColor3       = Color3.fromRGB(40, 40, 60)
	label.BackgroundTransparency = 0.3
	label.BorderSizePixel        = 0
	label.Font                   = Enum.Font.GothamBold
	label.TextScaled             = true
	label.TextColor3             = Color3.fromRGB(255, 215, 0)
	label.Text                   = relType
	label.Parent                 = billboard

	local corner        = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent       = label
end

-- ── Request dialog ────────────────────────────────────────────────

local function buildRequestGui()
	if _requestGui then return _requestGui end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "RelRequestGui"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = true
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Enabled            = false
	sg.Parent             = playerGui

	local backdrop                    = Instance.new("Frame")
	backdrop.Size                     = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3         = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency   = 0.5
	backdrop.BorderSizePixel          = 0
	backdrop.ZIndex                   = 1
	backdrop.Parent                   = sg

	local panel                       = Instance.new("Frame")
	panel.Name                        = "Panel"
	panel.Size                        = UDim2.fromOffset(340, 180)
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

	local msgLabel               = Instance.new("TextLabel")
	msgLabel.Name                = "Msg"
	msgLabel.Size                = UDim2.new(1, -32, 0, 80)
	msgLabel.Position            = UDim2.fromOffset(16, 16)
	msgLabel.BackgroundTransparency = 1
	msgLabel.Font                = Enum.Font.Gotham
	msgLabel.TextSize            = 14
	msgLabel.TextColor3          = Color3.fromRGB(220, 220, 220)
	msgLabel.TextWrapped         = true
	msgLabel.Text                = ""
	msgLabel.ZIndex              = 3
	msgLabel.Parent              = panel

	local acceptBtn              = Instance.new("TextButton")
	acceptBtn.Name               = "Accept"
	acceptBtn.Size               = UDim2.new(0.5, -20, 0, 40)
	acceptBtn.Position           = UDim2.fromOffset(12, 124)
	acceptBtn.BackgroundColor3   = Color3.fromRGB(40, 150, 60)
	acceptBtn.BorderSizePixel    = 0
	acceptBtn.Font               = Enum.Font.GothamBold
	acceptBtn.TextSize           = 14
	acceptBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
	acceptBtn.Text               = "Terima"
	acceptBtn.ZIndex             = 3
	acceptBtn.Parent             = panel

	local aCorner       = Instance.new("UICorner")
	aCorner.CornerRadius = UDim.new(0, 8)
	aCorner.Parent       = acceptBtn

	local declineBtn             = Instance.new("TextButton")
	declineBtn.Name              = "Decline"
	declineBtn.Size              = UDim2.new(0.5, -20, 0, 40)
	declineBtn.Position          = UDim2.new(0.5, 8, 0, 124)
	declineBtn.BackgroundColor3  = Color3.fromRGB(180, 40, 40)
	declineBtn.BorderSizePixel   = 0
	declineBtn.Font              = Enum.Font.GothamBold
	declineBtn.TextSize          = 14
	declineBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
	declineBtn.Text              = "Tolak"
	declineBtn.ZIndex            = 3
	declineBtn.Parent            = panel

	local dCorner       = Instance.new("UICorner")
	dCorner.CornerRadius = UDim.new(0, 8)
	dCorner.Parent       = declineBtn

	_requestGui = {
		sg         = sg,
		msgLabel   = msgLabel,
		acceptBtn  = acceptBtn,
		declineBtn = declineBtn,
	}
	return _requestGui
end

local function showRequestDialog(_, fromName, relType)
	local gui = buildRequestGui()
	gui.msgLabel.Text = fromName .. " mengajak Anda menjalin hubungan: " .. relType
	gui.sg.Enabled    = true

	local acceptConn
	local declineConn

	acceptConn = gui.acceptBtn.Activated:Connect(function()
		acceptConn:Disconnect()
		declineConn:Disconnect()
		gui.sg.Enabled = false
		_relService.AcceptRequest:Fire()
	end)

	declineConn = gui.declineBtn.Activated:Connect(function()
		acceptConn:Disconnect()
		declineConn:Disconnect()
		gui.sg.Enabled = false
		_relService.DeclineRequest:Fire()
	end)
end

-- ── Formation notification ────────────────────────────────────────

local function showFormedNotif(withName, relType)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "RelNotifGui"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = true
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Parent             = playerGui

	local card                  = Instance.new("Frame")
	card.Name                   = "Card"
	card.Size                   = UDim2.fromOffset(280, 64)
	card.AnchorPoint            = Vector2.new(0.5, 0)
	card.Position               = UDim2.new(0.5, 0, 0, -70)
	card.BackgroundColor3       = Color3.fromRGB(40, 40, 60)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel        = 0
	card.ZIndex                 = 10
	card.Parent                 = sg

	local cardCorner       = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent       = card

	local label              = Instance.new("TextLabel")
	label.Size               = UDim2.new(1, -16, 1, 0)
	label.Position           = UDim2.fromOffset(8, 0)
	label.BackgroundTransparency = 1
	label.Font               = Enum.Font.GothamBold
	label.TextSize           = 14
	label.TextColor3         = Color3.fromRGB(255, 215, 0)
	label.TextWrapped        = true
	label.Text               = "Hubungan terbentuk!\n" .. relType .. " dengan " .. withName
	label.ZIndex             = 11
	label.Parent             = card

	local slideIn = TweenService:Create(
		card,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 16) }
	)
	slideIn:Play()

	task.delay(4, function()
		local slideOut = TweenService:Create(
			card,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -70) }
		)
		slideOut:Play()
		slideOut.Completed:Connect(function()
			sg:Destroy()
		end)
	end)
end

-- ── SocialGui (Phase 8) ───────────────────────────────────────────

local function buildSocialGui()
	if _socialGui then return _socialGui end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg = Instance.new("ScreenGui")
	sg.Name           = "SocialGui"
	sg.ResetOnSpawn   = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Enabled        = false
	sg.Parent         = playerGui

	local backdrop = Instance.new("TextButton")
	backdrop.Name                   = "Backdrop"
	backdrop.Size                   = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel        = 0
	backdrop.Text                   = ""
	backdrop.ZIndex                 = 1
	backdrop.Parent                 = sg

	local panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.Size                   = UDim2.fromOffset(400, 540)
	panel.AnchorPoint            = Vector2.new(0.5, 0.5)
	panel.Position               = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3       = Color3.fromRGB(18, 18, 28)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel        = 0
	panel.ZIndex                 = 2
	panel.Parent                 = sg

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent       = panel

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name              = "Title"
	titleLabel.Size              = UDim2.new(1, -60, 0, 36)
	titleLabel.Position          = UDim2.fromOffset(16, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font              = Enum.Font.GothamBold
	titleLabel.TextSize          = 18
	titleLabel.TextColor3        = Color3.fromRGB(255, 215, 0)
	titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
	titleLabel.Text              = "Hubungan Sosial"
	titleLabel.ZIndex            = 3
	titleLabel.Parent            = panel

	local closeBtn = Instance.new("TextButton")
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

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 6)
	closeBtnCorner.Parent       = closeBtn

	-- Search bar
	local searchBox = Instance.new("TextBox")
	searchBox.Name               = "SearchBox"
	searchBox.Size               = UDim2.new(1, -100, 0, 34)
	searchBox.Position           = UDim2.fromOffset(12, 52)
	searchBox.BackgroundColor3   = Color3.fromRGB(30, 30, 50)
	searchBox.BorderSizePixel    = 0
	searchBox.Font               = Enum.Font.Gotham
	searchBox.TextSize           = 14
	searchBox.TextColor3         = Color3.fromRGB(220, 220, 220)
	searchBox.PlaceholderText    = "Cari pemain online..."
	searchBox.PlaceholderColor3  = Color3.fromRGB(100, 100, 120)
	searchBox.ClearTextOnFocus   = false
	searchBox.ZIndex             = 3
	searchBox.Parent             = panel

	local searchBoxCorner = Instance.new("UICorner")
	searchBoxCorner.CornerRadius = UDim.new(0, 6)
	searchBoxCorner.Parent       = searchBox

	local searchBtn = Instance.new("TextButton")
	searchBtn.Name                = "SearchBtn"
	searchBtn.Size                = UDim2.fromOffset(76, 34)
	searchBtn.Position            = UDim2.new(1, -88, 0, 52)
	searchBtn.BackgroundColor3    = Color3.fromRGB(60, 100, 180)
	searchBtn.BorderSizePixel     = 0
	searchBtn.Font                = Enum.Font.GothamBold
	searchBtn.TextSize            = 13
	searchBtn.TextColor3          = Color3.fromRGB(255, 255, 255)
	searchBtn.Text                = "Cari"
	searchBtn.ZIndex              = 3
	searchBtn.Parent              = panel

	local searchBtnCorner = Instance.new("UICorner")
	searchBtnCorner.CornerRadius = UDim.new(0, 6)
	searchBtnCorner.Parent       = searchBtn

	-- Send-request type dropdown placeholder (TextButton cycling)
	local relTypeSel = Instance.new("TextButton")
	relTypeSel.Name               = "RelTypeSel"
	relTypeSel.Size               = UDim2.new(1, -24, 0, 32)
	relTypeSel.Position           = UDim2.fromOffset(12, 94)
	relTypeSel.BackgroundColor3   = Color3.fromRGB(30, 30, 50)
	relTypeSel.BorderSizePixel    = 0
	relTypeSel.Font               = Enum.Font.Gotham
	relTypeSel.TextSize           = 13
	relTypeSel.TextColor3         = Color3.fromRGB(200, 200, 200)
	relTypeSel.Text               = "Jenis: Sahabat"
	relTypeSel.ZIndex             = 3
	relTypeSel.Visible            = false
	relTypeSel.Parent             = panel

	local relTypeSelCorner = Instance.new("UICorner")
	relTypeSelCorner.CornerRadius = UDim.new(0, 6)
	relTypeSelCorner.Parent       = relTypeSel

	local sendReqBtn = Instance.new("TextButton")
	sendReqBtn.Name               = "SendReq"
	sendReqBtn.Size               = UDim2.new(1, -24, 0, 36)
	sendReqBtn.Position           = UDim2.fromOffset(12, 134)
	sendReqBtn.BackgroundColor3   = Color3.fromRGB(40, 150, 60)
	sendReqBtn.BorderSizePixel    = 0
	sendReqBtn.Font               = Enum.Font.GothamBold
	sendReqBtn.TextSize           = 14
	sendReqBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
	sendReqBtn.Text               = "Kirim Permintaan"
	sendReqBtn.ZIndex             = 3
	sendReqBtn.Visible            = false
	sendReqBtn.Parent             = panel

	local sendReqCorner = Instance.new("UICorner")
	sendReqCorner.CornerRadius = UDim.new(0, 6)
	sendReqCorner.Parent       = sendReqBtn

	local searchResult = Instance.new("TextLabel")
	searchResult.Name               = "SearchResult"
	searchResult.Size               = UDim2.new(1, -24, 0, 22)
	searchResult.Position           = UDim2.fromOffset(12, 90)
	searchResult.BackgroundTransparency = 1
	searchResult.Font               = Enum.Font.Gotham
	searchResult.TextSize           = 13
	searchResult.TextColor3         = Color3.fromRGB(180, 180, 180)
	searchResult.TextXAlignment     = Enum.TextXAlignment.Left
	searchResult.Text               = ""
	searchResult.ZIndex             = 3
	searchResult.Parent             = panel

	-- Divider
	local divider = Instance.new("Frame")
	divider.Size              = UDim2.new(1, -24, 0, 1)
	divider.Position          = UDim2.fromOffset(12, 118)
	divider.BackgroundColor3  = Color3.fromRGB(50, 50, 80)
	divider.BorderSizePixel   = 0
	divider.ZIndex            = 3
	divider.Parent            = panel

	-- Section label
	local sectionLbl = Instance.new("TextLabel")
	sectionLbl.Name               = "Section"
	sectionLbl.Size               = UDim2.new(1, -24, 0, 20)
	sectionLbl.Position           = UDim2.fromOffset(12, 124)
	sectionLbl.BackgroundTransparency = 1
	sectionLbl.Font               = Enum.Font.GothamBold
	sectionLbl.TextSize           = 13
	sectionLbl.TextColor3         = Color3.fromRGB(160, 160, 180)
	sectionLbl.TextXAlignment     = Enum.TextXAlignment.Left
	sectionLbl.Text               = "Hubungan Aktif"
	sectionLbl.ZIndex             = 3
	sectionLbl.Parent             = panel

	-- Relationship list scroll
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name               = "Scroll"
	scroll.Size               = UDim2.new(1, -24, 1, -154)
	scroll.Position           = UDim2.fromOffset(12, 148)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel    = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
	scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
	scroll.CanvasSize           = UDim2.fromScale(0, 0)
	scroll.ZIndex               = 3
	scroll.Parent               = panel

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding    = UDim.new(0, 4)
	listLayout.SortOrder  = Enum.SortOrder.LayoutOrder
	listLayout.Parent     = scroll

	_socialGui = {
		sg            = sg,
		backdrop      = backdrop,
		panel         = panel,
		closeBtn      = closeBtn,
		searchBox     = searchBox,
		searchBtn     = searchBtn,
		searchResult  = searchResult,
		relTypeSel    = relTypeSel,
		sendReqBtn    = sendReqBtn,
		scroll        = scroll,
		divider       = divider,
	}
	return _socialGui
end

local function closeSocialGui()
	if not _socialGui then return end
	_socialGui.sg.Enabled = false
end

local function buildRelRow(userId, userName, relType, order)
	local gui = _socialGui
	if not gui then return end

	local relCfg = AssetConfig.Relationships[relType]
	local icon   = relCfg and relCfg.icon or "rbxassetid://0"

	local row = Instance.new("Frame")
	row.Name              = "Row_" .. tostring(userId)
	row.Size              = UDim2.new(1, -4, 0, 48)
	row.BackgroundColor3  = Color3.fromRGB(28, 28, 44)
	row.BorderSizePixel   = 0
	row.LayoutOrder       = order
	row.ZIndex            = 4
	row.Parent            = gui.scroll

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent       = row

	local relIcon = Instance.new("ImageLabel")
	relIcon.Size                  = UDim2.fromOffset(32, 32)
	relIcon.Position              = UDim2.fromOffset(8, 8)
	relIcon.BackgroundColor3      = Color3.fromRGB(40, 40, 60)
	relIcon.BackgroundTransparency = 0
	relIcon.BorderSizePixel       = 0
	relIcon.Image                 = icon
	relIcon.ZIndex                = 5
	relIcon.Parent                = row

	local relIconCorner = Instance.new("UICorner")
	relIconCorner.CornerRadius = UDim.new(0.5, 0)
	relIconCorner.Parent       = relIcon

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size               = UDim2.new(1, -130, 0, 22)
	nameLbl.Position           = UDim2.fromOffset(48, 4)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font               = Enum.Font.GothamBold
	nameLbl.TextSize           = 13
	nameLbl.TextColor3         = Color3.fromRGB(220, 220, 220)
	nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
	nameLbl.Text               = userName
	nameLbl.ZIndex             = 5
	nameLbl.Parent             = row

	local typeLbl = Instance.new("TextLabel")
	typeLbl.Size               = UDim2.new(1, -130, 0, 18)
	typeLbl.Position           = UDim2.fromOffset(48, 26)
	typeLbl.BackgroundTransparency = 1
	typeLbl.Font               = Enum.Font.Gotham
	typeLbl.TextSize           = 11
	typeLbl.TextColor3         = Color3.fromRGB(150, 200, 255)
	typeLbl.TextXAlignment     = Enum.TextXAlignment.Left
	typeLbl.Text               = relType
	typeLbl.ZIndex             = 5
	typeLbl.Parent             = row

	local hapusBtn = Instance.new("TextButton")
	hapusBtn.Name               = "Hapus"
	hapusBtn.Size               = UDim2.fromOffset(64, 30)
	hapusBtn.AnchorPoint        = Vector2.new(1, 0.5)
	hapusBtn.Position           = UDim2.new(1, -6, 0.5, 0)
	hapusBtn.BackgroundColor3   = Color3.fromRGB(160, 40, 40)
	hapusBtn.BorderSizePixel    = 0
	hapusBtn.Font               = Enum.Font.GothamBold
	hapusBtn.TextSize           = 12
	hapusBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
	hapusBtn.Text               = "Hapus"
	hapusBtn.ZIndex             = 5
	hapusBtn.Parent             = row

	local hapusCorner = Instance.new("UICorner")
	hapusCorner.CornerRadius = UDim.new(0, 6)
	hapusCorner.Parent       = hapusBtn

	local capId = userId
	hapusBtn.Activated:Connect(function()
		_relService.RemoveRelationship:Fire(capId)
		row:Destroy()
	end)
end

local _selectedUserId = nil
local _selectedRelType = "Sahabat"
local REL_TYPES = { "Sahabat", "Rival", "Saudara", "Musuh" }
local _relTypeIndex = 1

local function refreshRelList(relationships)
	local gui = buildSocialGui()

	for _, child in gui.scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local order = 1
	for userId, relType in relationships do
		local uid = tonumber(userId)
		local name = "[id:" .. userId .. "]"
		pcall(function()
			name = Players:GetNameFromUserIdAsync(uid)
		end)
		buildRelRow(uid, name, relType, order)
		order = order + 1
	end
end

local function openSocialGui(relationships)
	local gui = buildSocialGui()
	gui.sg.Enabled = true
	_selectedUserId = nil

	gui.searchBox.Text      = ""
	gui.searchResult.Text   = ""
	gui.relTypeSel.Visible  = false
	gui.sendReqBtn.Visible  = false

	refreshRelList(relationships or {})
end

-- ── SocialGui: search + send request wiring ───────────────────────

local function wireSocialGui()
	local gui = buildSocialGui()

	gui.closeBtn.Activated:Connect(closeSocialGui)
	gui.backdrop.Activated:Connect(closeSocialGui)

	-- Cycle relationship type
	gui.relTypeSel.Activated:Connect(function()
		_relTypeIndex = (_relTypeIndex % #REL_TYPES) + 1
		_selectedRelType = REL_TYPES[_relTypeIndex]
		gui.relTypeSel.Text = "Jenis: " .. _selectedRelType
	end)

	-- Search button
	gui.searchBtn.Activated:Connect(function()
		local query = gui.searchBox.Text
		if query == "" then return end

		_selectedUserId = nil
		gui.relTypeSel.Visible = false
		gui.sendReqBtn.Visible = false
		gui.searchResult.Text  = "Mencari..."

		-- Find matching online player by name
		for _, player in Players:GetPlayers() do
			if string.lower(player.Name):find(string.lower(query), 1, true) then
				_selectedUserId = player.UserId
				gui.searchResult.Text   = "Ditemukan: " .. player.Name
				gui.relTypeSel.Visible  = true
				gui.sendReqBtn.Visible  = true
				break
			end
		end

		if not _selectedUserId then
			gui.searchResult.Text = "Pemain tidak ditemukan."
		end
	end)

	-- Send request
	gui.sendReqBtn.Activated:Connect(function()
		if not _selectedUserId then return end
		_relService.SendRequest:Fire(_selectedUserId, _selectedRelType)
		gui.searchResult.Text   = "Permintaan terkirim!"
		gui.relTypeSel.Visible  = false
		gui.sendReqBtn.Visible  = false
		_selectedUserId = nil
	end)
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function RelationshipController:KnitInit()
end

function RelationshipController:KnitStart()
	_relService = Knit.GetService("RelationshipService")

	_relService.RelationshipRequestReceived:Connect(function(fromUserId, fromName, relType)
		showRequestDialog(fromUserId, fromName, relType)
	end)

	_relService.RelationshipFormed:Connect(function(withUserId, withName, relType)
		showFormedNotif(withName, relType)
		local localId = Players.LocalPlayer.UserId
		local localHead = getCharacterHead(localId)
		if localHead then
			applyNameplateBadge(localHead, relType)
		end
		local otherHead = getCharacterHead(withUserId)
		if otherHead then
			applyNameplateBadge(otherHead, relType)
		end
		-- Refresh social panel if open
		if _socialGui and _socialGui.sg.Enabled then
			self:openSocialGui()
		end
	end)

	_relService.RelationshipRemoved:Connect(function(withUserId)
		local localId = Players.LocalPlayer.UserId
		local localHead = getCharacterHead(localId)
		if localHead then
			applyNameplateBadge(localHead, nil)
		end
		local otherHead = getCharacterHead(withUserId)
		if otherHead then
			applyNameplateBadge(otherHead, nil)
		end
	end)

	_relService.UpdateNameplate:Connect(function(userId, relType)
		local head = getCharacterHead(userId)
		if head then
			applyNameplateBadge(head, relType)
		end
	end)

	task.defer(function()
		wireSocialGui()
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function RelationshipController:sendRequest(targetUserId, relType)
	if not _relService then return end
	_relService.SendRequest:Fire(targetUserId, relType)
end

function RelationshipController:removeRelationship(targetUserId)
	if not _relService then return end
	_relService.RemoveRelationship:Fire(targetUserId)
end

function RelationshipController:openSocialGui()
	if not _relService then return end
	local dataService = Knit.GetService("DataService")
	dataService:GetPlayerData():andThen(function(data)
		openSocialGui(data and data.relationships or {})
	end):catch(function()
		openSocialGui({})
	end)
end

function RelationshipController:closeSocialGui()
	closeSocialGui()
end

return RelationshipController
