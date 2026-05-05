-- LocalScript: StarterPlayerScripts/Client/Controllers/QuestController
-- Caches quest state from QuestService. Shows offer popup on QuestOffer.
-- Provides getActiveQuests / isCompleted API for HUD and dialog systems.
-- Also builds QuestGui panel: scrollable list with Aktif and Selesai sections.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local QuestController = Knit.CreateController { Name = "QuestController" }

-- ── Local state ───────────────────────────────────────────────────

local _questService  = nil
local _questState    = { activeQuests = {}, completedQuests = {}, questProgress = {} }
local _offerGui      = nil
local _offerNameLbl  = nil
local _pendingOffer  = nil
local _questGui      = nil

-- ── Offer popup UI ────────────────────────────────────────────────

local function buildOfferUI()
	local screenGui              = Instance.new("ScreenGui")
	screenGui.Name               = "QuestOfferGui"
	screenGui.ResetOnSpawn       = false
	screenGui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled            = false
	screenGui.Parent             = PlayerGui

	local frame                  = Instance.new("Frame")
	frame.Size                   = UDim2.fromOffset(360, 165)
	frame.Position               = UDim2.new(0.5, -180, 0.5, -82)
	frame.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel        = 0
	frame.Parent                 = screenGui

	local corner                 = Instance.new("UICorner")
	corner.CornerRadius          = UDim.new(0, 10)
	corner.Parent                = frame

	local header                 = Instance.new("TextLabel")
	header.Size                  = UDim2.new(1, -20, 0, 28)
	header.Position              = UDim2.fromOffset(10, 10)
	header.BackgroundTransparency = 1
	header.TextColor3            = Color3.fromRGB(255, 215, 80)
	header.Font                  = Enum.Font.GothamBold
	header.TextSize              = 18
	header.TextXAlignment        = Enum.TextXAlignment.Left
	header.Text                  = "Tawaran Misi"
	header.Parent                = frame

	local nameLbl                = Instance.new("TextLabel")
	nameLbl.Size                 = UDim2.new(1, -20, 0, 55)
	nameLbl.Position             = UDim2.fromOffset(10, 44)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3           = Color3.new(1, 1, 1)
	nameLbl.Font                 = Enum.Font.Gotham
	nameLbl.TextSize             = 15
	nameLbl.TextWrapped          = true
	nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
	nameLbl.Parent               = frame

	local acceptBtn              = Instance.new("TextButton")
	acceptBtn.Size               = UDim2.fromOffset(155, 40)
	acceptBtn.Position           = UDim2.new(0, 10, 1, -50)
	acceptBtn.BackgroundColor3   = Color3.fromRGB(50, 180, 80)
	acceptBtn.BorderSizePixel    = 0
	acceptBtn.TextColor3         = Color3.new(1, 1, 1)
	acceptBtn.Font               = Enum.Font.GothamBold
	acceptBtn.TextSize           = 15
	acceptBtn.Text               = "Terima"
	acceptBtn.Parent             = frame

	local ca                     = Instance.new("UICorner")
	ca.CornerRadius              = UDim.new(0, 6)
	ca.Parent                    = acceptBtn

	local declineBtn             = Instance.new("TextButton")
	declineBtn.Size              = UDim2.fromOffset(155, 40)
	declineBtn.Position          = UDim2.new(1, -165, 1, -50)
	declineBtn.BackgroundColor3  = Color3.fromRGB(180, 60, 60)
	declineBtn.BorderSizePixel   = 0
	declineBtn.TextColor3        = Color3.new(1, 1, 1)
	declineBtn.Font              = Enum.Font.GothamBold
	declineBtn.TextSize          = 15
	declineBtn.Text              = "Tolak"
	declineBtn.Parent            = frame

	local cd                     = Instance.new("UICorner")
	cd.CornerRadius              = UDim.new(0, 6)
	cd.Parent                    = declineBtn

	return screenGui, nameLbl, acceptBtn, declineBtn
end

-- ── QuestGui ──────────────────────────────────────────────────────

local function buildQuestGui()
	if _questGui then
		return _questGui
	end

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "QuestGui"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = true
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Enabled            = false
	sg.Parent             = PlayerGui

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
	panel.Size                        = UDim2.fromOffset(440, 520)
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
	titleLabel.Text               = "Misi"
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

	local scroll              = Instance.new("ScrollingFrame")
	scroll.Name               = "Scroll"
	scroll.Size               = UDim2.new(1, -32, 1, -60)
	scroll.Position           = UDim2.fromOffset(16, 52)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel    = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
	scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
	scroll.CanvasSize           = UDim2.fromScale(0, 0)
	scroll.ZIndex               = 3
	scroll.Parent               = panel

	local listLayout              = Instance.new("UIListLayout")
	listLayout.SortOrder          = Enum.SortOrder.LayoutOrder
	listLayout.Padding            = UDim.new(0, 6)
	listLayout.Parent             = scroll

	_questGui = {
		sg       = sg,
		backdrop = backdrop,
		scroll   = scroll,
		closeBtn = closeBtn,
	}

	closeBtn.Activated:Connect(function()
		sg.Enabled = false
	end)
	backdrop.Activated:Connect(function()
		sg.Enabled = false
	end)

	return _questGui
end

-- ── Section header ────────────────────────────────────────────────

local function buildSectionHeader(parent, text, order)
	local header              = Instance.new("TextLabel")
	header.Name               = "Header_" .. text
	header.Size               = UDim2.new(1, -4, 0, 24)
	header.BackgroundColor3   = Color3.fromRGB(50, 50, 80)
	header.BackgroundTransparency = 0.3
	header.BorderSizePixel    = 0
	header.Font               = Enum.Font.GothamBold
	header.TextSize           = 13
	header.TextColor3         = Color3.fromRGB(200, 200, 255)
	header.TextXAlignment     = Enum.TextXAlignment.Left
	header.Text               = "  " .. text
	header.LayoutOrder        = order
	header.ZIndex             = 4
	header.Parent             = parent

	local hCorner       = Instance.new("UICorner")
	hCorner.CornerRadius = UDim.new(0, 4)
	hCorner.Parent       = header
end

-- ── Quest entry builder ───────────────────────────────────────────

local function buildQuestEntry(parent, questId, order, isCompleted)
	local cfg      = AssetConfig.getQuest(questId)
	local progress = (_questState.questProgress or {})[questId] or {}
	local objProg  = progress.objectiveProgress or {}

	local row              = Instance.new("Frame")
	row.Name               = "Quest_" .. questId
	row.Size               = UDim2.new(1, -4, 0, 80)
	row.AutomaticSize      = Enum.AutomaticSize.Y
	row.BackgroundColor3   = isCompleted
		and Color3.fromRGB(25, 40, 25)
		or  Color3.fromRGB(28, 28, 42)
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel    = 0
	row.LayoutOrder        = order
	row.ZIndex             = 4
	row.Parent             = parent

	local rowCorner       = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent       = row

	-- Type badge
	local qType    = cfg and cfg.type or "Side"
	local badgeCol = qType == "Main" and Color3.fromRGB(220, 140, 30) or Color3.fromRGB(60, 120, 200)

	local typeBadge              = Instance.new("TextLabel")
	typeBadge.Size               = UDim2.fromOffset(40, 16)
	typeBadge.Position           = UDim2.fromOffset(8, 8)
	typeBadge.BackgroundColor3   = badgeCol
	typeBadge.BackgroundTransparency = 0.2
	typeBadge.BorderSizePixel    = 0
	typeBadge.Font               = Enum.Font.GothamBold
	typeBadge.TextSize           = 10
	typeBadge.TextColor3         = Color3.fromRGB(255, 255, 255)
	typeBadge.Text               = qType
	typeBadge.ZIndex             = 5
	typeBadge.Parent             = row

	local tbCorner       = Instance.new("UICorner")
	tbCorner.CornerRadius = UDim.new(0, 4)
	tbCorner.Parent       = typeBadge

	-- Title
	local titleLabel              = Instance.new("TextLabel")
	titleLabel.Size               = UDim2.new(1, -60, 0, 18)
	titleLabel.Position           = UDim2.fromOffset(54, 7)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font               = Enum.Font.GothamBold
	titleLabel.TextSize           = 13
	titleLabel.TextColor3         = isCompleted
		and Color3.fromRGB(100, 200, 100)
		or  Color3.fromRGB(220, 220, 220)
	titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
	titleLabel.Text               = (cfg and cfg.titleKey) or questId
	titleLabel.ZIndex             = 5
	titleLabel.Parent             = row

	if isCompleted then
		local doneLabel              = Instance.new("TextLabel")
		doneLabel.Size               = UDim2.new(1, -16, 0, 18)
		doneLabel.Position           = UDim2.fromOffset(8, 30)
		doneLabel.BackgroundTransparency = 1
		doneLabel.Font               = Enum.Font.Gotham
		doneLabel.TextSize           = 11
		doneLabel.TextColor3         = Color3.fromRGB(100, 180, 100)
		doneLabel.TextXAlignment     = Enum.TextXAlignment.Left
		doneLabel.Text               = "✓ Selesai"
		doneLabel.ZIndex             = 5
		doneLabel.Parent             = row
		row.Size                     = UDim2.new(1, -4, 0, 58)
		return row
	end

	-- First incomplete objective
	if cfg and cfg.objectives then
		for _, obj in cfg.objectives do
			local prog = objProg[obj.id] or 0
			local req  = obj.required or 1
			if prog < req then
				local objLabel              = Instance.new("TextLabel")
				objLabel.Size               = UDim2.new(1, -16, 0, 18)
				objLabel.Position           = UDim2.fromOffset(8, 30)
				objLabel.BackgroundTransparency = 1
				objLabel.Font               = Enum.Font.Gotham
				objLabel.TextSize           = 11
				objLabel.TextColor3         = Color3.fromRGB(180, 180, 180)
				objLabel.TextXAlignment     = Enum.TextXAlignment.Left
				objLabel.Text               = "→ " .. (obj.descKey or obj.id) .. "  " .. tostring(prog) .. "/" .. tostring(req)
				objLabel.ZIndex             = 5
				objLabel.Parent             = row
				break
			end
		end
	end

	-- Reward preview
	if cfg and cfg.rewards then
		local r    = cfg.rewards
		local rStr = ""
		if r.rupiah and r.rupiah > 0 then
			rStr = rStr .. "Rp " .. tostring(r.rupiah) .. "  "
		end
		if r.gold and r.gold > 0 then
			rStr = rStr .. "◆ " .. tostring(r.gold)
		end
		if rStr ~= "" then
			local rewardLabel              = Instance.new("TextLabel")
			rewardLabel.Size               = UDim2.new(1, -16, 0, 14)
			rewardLabel.Position           = UDim2.fromOffset(8, 52)
			rewardLabel.BackgroundTransparency = 1
			rewardLabel.Font               = Enum.Font.Gotham
			rewardLabel.TextSize           = 10
			rewardLabel.TextColor3         = Color3.fromRGB(255, 215, 0)
			rewardLabel.TextXAlignment     = Enum.TextXAlignment.Left
			rewardLabel.Text               = rStr
			rewardLabel.ZIndex             = 5
			rewardLabel.Parent             = row
			row.Size                       = UDim2.new(1, -4, 0, 72)
		end
	end

	return row
end

-- ── Render quest list ─────────────────────────────────────────────

local function renderQuestGui()
	if not _questGui then
		return
	end
	local scroll = _questGui.scroll

	for _, child in scroll:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local order = 1
	local activeQuests    = _questState.activeQuests or {}
	local completedQuests = _questState.completedQuests or {}

	buildSectionHeader(scroll, "Aktif (" .. tostring(#activeQuests) .. ")", order)
	order += 1

	if #activeQuests == 0 then
		local emptyLabel              = Instance.new("TextLabel")
		emptyLabel.Size               = UDim2.new(1, 0, 0, 32)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font               = Enum.Font.Gotham
		emptyLabel.TextSize           = 13
		emptyLabel.TextColor3         = Color3.fromRGB(120, 120, 140)
		emptyLabel.Text               = "Tidak ada misi aktif."
		emptyLabel.LayoutOrder        = order
		emptyLabel.ZIndex             = 4
		emptyLabel.Parent             = scroll
		order += 1
	else
		for _, qId in activeQuests do
			buildQuestEntry(scroll, qId, order, false)
			order += 1
		end
	end

	local completedCount = 0
	for _ in completedQuests do
		completedCount += 1
	end

	buildSectionHeader(scroll, "Selesai (" .. tostring(completedCount) .. ")", order)
	order += 1

	for qId in completedQuests do
		buildQuestEntry(scroll, qId, order, true)
		order += 1
	end
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function QuestController:KnitInit()
	local gui, nameLbl, acceptBtn, declineBtn = buildOfferUI()
	_offerGui     = gui
	_offerNameLbl = nameLbl

	acceptBtn.Activated:Connect(function()
		if _pendingOffer then
			_questService.QuestAccept:Fire(_pendingOffer)
			_pendingOffer     = nil
			_offerGui.Enabled = false
		end
	end)

	declineBtn.Activated:Connect(function()
		if _pendingOffer then
			_questService.QuestDecline:Fire(_pendingOffer)
			_pendingOffer     = nil
			_offerGui.Enabled = false
		end
	end)
end

function QuestController:KnitStart()
	_questService = Knit.GetService("QuestService")

	_questService.QuestUpdate:Connect(function(snapshot)
		_questState = snapshot
		if _questGui and _questGui.sg.Enabled then
			renderQuestGui()
		end
	end)

	_questService.QuestOffer:Connect(function(questId, questCfg)
		_pendingOffer         = questId
		_offerNameLbl.Text    = questCfg.titleKey or questId
		_offerGui.Enabled     = true
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function QuestController:getActiveQuests()
	return _questState.activeQuests or {}
end

function QuestController:getCompletedQuests()
	return _questState.completedQuests or {}
end

function QuestController:isActive(questId)
	return table.find(_questState.activeQuests or {}, questId) ~= nil
end

function QuestController:isCompleted(questId)
	return (_questState.completedQuests or {})[questId] == true
end

function QuestController:getProgress(questId)
	local qp = _questState.questProgress or {}
	return qp[questId]
end

function QuestController:openQuestGui()
	buildQuestGui()
	_questGui.sg.Enabled = true
	renderQuestGui()
end

return QuestController
