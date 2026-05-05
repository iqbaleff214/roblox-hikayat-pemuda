-- LocalScript (Knit Controller): StarterPlayerScripts/Client/Controllers/QuestController
-- Caches quest state from QuestService. Shows accept/decline popup on QuestOffer.
-- Provides getActiveQuests / isCompleted API for HUD and dialog systems.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local QuestController = Knit.CreateController { Name = "QuestController" }

-- ── Local state ───────────────────────────────────────────────────

local _questService  = nil
local _questState    = { activeQuests = {}, completedQuests = {}, questProgress = {} }
local _offerGui      = nil
local _offerNameLbl  = nil
local _pendingOffer  = nil  -- questId currently shown in offer popup

-- ── Offer popup UI ────────────────────────────────────────────────

local function buildOfferUI()
	local screenGui              = Instance.new("ScreenGui")
	screenGui.Name               = "QuestOfferGui"
	screenGui.ResetOnSpawn       = false
	screenGui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled            = false
	screenGui.Parent             = PlayerGui

	local frame                  = Instance.new("Frame")
	frame.Size                   = UDim2.new(0, 360, 0, 165)
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
	header.Position              = UDim2.new(0, 10, 0, 10)
	header.BackgroundTransparency = 1
	header.TextColor3            = Color3.fromRGB(255, 215, 80)
	header.Font                  = Enum.Font.GothamBold
	header.TextSize              = 18
	header.TextXAlignment        = Enum.TextXAlignment.Left
	header.Text                  = "Tawaran Misi"
	header.Parent                = frame

	local nameLbl                = Instance.new("TextLabel")
	nameLbl.Size                 = UDim2.new(1, -20, 0, 55)
	nameLbl.Position             = UDim2.new(0, 10, 0, 44)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3           = Color3.new(1, 1, 1)
	nameLbl.Font                 = Enum.Font.Gotham
	nameLbl.TextSize             = 15
	nameLbl.TextWrapped          = true
	nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
	nameLbl.Parent               = frame

	local acceptBtn              = Instance.new("TextButton")
	acceptBtn.Size               = UDim2.new(0, 155, 0, 40)
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
	declineBtn.Size              = UDim2.new(0, 155, 0, 40)
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

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function QuestController:KnitInit()
	local gui, nameLbl, acceptBtn, declineBtn = buildOfferUI()
	_offerGui     = gui
	_offerNameLbl = nameLbl

	acceptBtn.Activated:Connect(function()
		if _pendingOffer then
			_questService.QuestAccept:Fire(_pendingOffer)
			_pendingOffer    = nil
			_offerGui.Enabled = false
		end
	end)

	declineBtn.Activated:Connect(function()
		if _pendingOffer then
			_questService.QuestDecline:Fire(_pendingOffer)
			_pendingOffer    = nil
			_offerGui.Enabled = false
		end
	end)
end

function QuestController:KnitStart()
	_questService = Knit.GetService("QuestService")

	_questService.QuestUpdate:Connect(function(snapshot)
		_questState = snapshot
	end)

	_questService.QuestOffer:Connect(function(questId, questCfg)
		_pendingOffer         = questId
		_offerNameLbl.Text    = questCfg.titleKey or questId
		_offerGui.Enabled     = true
	end)
end

-- ── Public API (for HUD and other controllers) ────────────────────

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

return QuestController
