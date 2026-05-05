-- LocalScript: StarterPlayerScripts/Client/Controllers/DialogController
-- Receives dialog nodes from NPCService, renders typewriter text and choice buttons.
-- Fires DialogChoice back to server when player selects an option.
-- Phase 8: NPC portrait, WalkSpeed disable during dialog, auto-close when no choices.
-- Phase 10: Mobile — ScrollingFrame for >3 choices; MobileUtil sizes.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit             = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig      = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)
local LocalizationUtil = require(ReplicatedStorage:WaitForChild("Shared").Modules.LocalizationUtil)
local MobileUtil       = require(ReplicatedStorage:WaitForChild("Shared").Modules.MobileUtil)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local CHAR_DELAY   = 0.03
local MIN_BTN_SIZE = MobileUtil.choiceButtonHeight()
local IS_MOBILE    = MobileUtil.IS_MOBILE

-- Panel height: ~30% on desktop, 40% on mobile (from MobileUtil)
local PANEL_HEIGHT = MobileUtil.dialogPanelSize()
local PANEL_POS    = MobileUtil.dialogPanelPos()

local DialogController = Knit.CreateController { Name = "DialogController" }

-- ── UI state ──────────────────────────────────────────────────────

local _gui           = nil
local _portrait      = nil
local _speakerLabel  = nil
local _textLabel     = nil
local _choiceFrame   = nil
local _skipConn      = nil
local _typeTask      = nil
local _autoCloseTask = nil

-- ── Humanoid walk control ─────────────────────────────────────────

local _savedWalkSpeed = nil

local function disableMovement()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	_savedWalkSpeed    = hum.WalkSpeed
	hum.WalkSpeed      = 0
	hum.JumpPower      = 0
end

local function restoreMovement()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if _savedWalkSpeed then
		hum.WalkSpeed = _savedWalkSpeed
		_savedWalkSpeed = nil
	end
	hum.JumpPower = 50
end

-- ── UI construction ───────────────────────────────────────────────

local function buildUI()
	local screenGui                  = Instance.new("ScreenGui")
	screenGui.Name                   = "DialogGui"
	screenGui.ResetOnSpawn           = false
	screenGui.ZIndexBehavior         = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled                = false
	screenGui.Parent                 = PlayerGui

	local frame                      = Instance.new("Frame")
	frame.Name                       = "DialogFrame"
	frame.Size                       = PANEL_HEIGHT
	frame.Position                   = PANEL_POS
	frame.BackgroundColor3           = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency     = 0.15
	frame.BorderSizePixel            = 0
	frame.Parent                     = screenGui

	local corner                     = Instance.new("UICorner")
	corner.CornerRadius              = UDim.new(0, 8)
	corner.Parent                    = frame

	-- Portrait area (left column)
	local portrait                   = Instance.new("ImageLabel")
	portrait.Name                    = "Portrait"
	portrait.Size                    = UDim2.fromOffset(96, 96)
	portrait.Position                = UDim2.fromOffset(12, 12)
	portrait.BackgroundColor3        = Color3.fromRGB(40, 40, 60)
	portrait.BackgroundTransparency  = 0
	portrait.BorderSizePixel         = 0
	portrait.Image                   = "rbxassetid://0"
	portrait.ScaleType               = Enum.ScaleType.Fit
	portrait.Parent                  = frame

	local portraitCorner             = Instance.new("UICorner")
	portraitCorner.CornerRadius      = UDim.new(0, 6)
	portraitCorner.Parent            = portrait

	-- Right side: speaker name
	local speaker                    = Instance.new("TextLabel")
	speaker.Name                     = "SpeakerLabel"
	speaker.Size                     = UDim2.new(1, -124, 0, 26)
	speaker.Position                 = UDim2.fromOffset(116, 10)
	speaker.BackgroundTransparency   = 1
	speaker.TextColor3               = Color3.fromRGB(255, 200, 80)
	speaker.Font                     = Enum.Font.GothamBold
	speaker.TextSize                 = 17
	speaker.TextXAlignment           = Enum.TextXAlignment.Left
	speaker.Text                     = ""
	speaker.Parent                   = frame

	-- Right side: dialog text
	local textLbl                    = Instance.new("TextLabel")
	textLbl.Name                     = "DialogText"
	textLbl.Size                     = UDim2.new(1, -124, 0, 72)
	textLbl.Position                 = UDim2.fromOffset(116, 40)
	textLbl.BackgroundTransparency   = 1
	textLbl.TextColor3               = Color3.new(1, 1, 1)
	textLbl.Font                     = Enum.Font.Gotham
	textLbl.TextSize                 = 15
	textLbl.TextWrapped              = true
	textLbl.TextXAlignment           = Enum.TextXAlignment.Left
	textLbl.TextYAlignment           = Enum.TextYAlignment.Top
	textLbl.Text                     = ""
	textLbl.Parent                   = frame

	-- Choice scroll (ScrollingFrame — scrolling toggled on when >3 choices on mobile)
	local choiceFr                      = Instance.new("ScrollingFrame")
	choiceFr.Name                       = "ChoiceFrame"
	choiceFr.Size                       = UDim2.new(1, -24, 0, 96)
	choiceFr.Position                   = UDim2.fromOffset(12, 116)
	choiceFr.BackgroundTransparency     = 1
	choiceFr.BorderSizePixel            = 0
	choiceFr.ScrollBarThickness         = 0  -- hidden by default; shown when scrollable
	choiceFr.ScrollBarImageTransparency = 1
	choiceFr.AutomaticCanvasSize        = Enum.AutomaticSize.None
	choiceFr.CanvasSize                 = UDim2.fromScale(0, 0)
	choiceFr.ClipsDescendants           = true
	choiceFr.Parent                     = frame

	local list                          = Instance.new("UIListLayout")
	list.SortOrder                      = Enum.SortOrder.LayoutOrder
	list.Padding                        = UDim.new(0, 4)
	list.Parent                         = choiceFr

	_gui          = screenGui
	_portrait     = portrait
	_speakerLabel = speaker
	_textLabel    = textLbl
	_choiceFrame  = choiceFr
end

local function clearChoices()
	for _, child in _choiceFrame:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function cancelTypewriter()
	if _typeTask then
		task.cancel(_typeTask)
		_typeTask = nil
	end
	if _skipConn then
		_skipConn:Disconnect()
		_skipConn = nil
	end
end

local function cancelAutoClose()
	if _autoCloseTask then
		task.cancel(_autoCloseTask)
		_autoCloseTask = nil
	end
end

-- ── NPCService reference (set in KnitStart) ───────────────────────

local _npcService = nil

-- ── Dialog rendering ──────────────────────────────────────────────

local function closeDialog()
	cancelTypewriter()
	cancelAutoClose()
	clearChoices()
	if _gui then
		_gui.Enabled = false
	end
	if _textLabel then
		_textLabel.Text = ""
	end
	if _speakerLabel then
		_speakerLabel.Text = ""
	end
	restoreMovement()
end

local function showNode(npcId, nodeData)
	cancelTypewriter()
	cancelAutoClose()
	clearChoices()

	_gui.Enabled       = true
	disableMovement()

	-- Update portrait from NPC config
	local npcCfg = AssetConfig.getNPC(npcId)
	if npcCfg and npcCfg.portrait then
		_portrait.Image = npcCfg.portrait
	else
		_portrait.Image = "rbxassetid://0"
	end

	_speakerLabel.Text = nodeData.speaker or (npcCfg and npcCfg.nameKey) or ""
	_textLabel.Text    = ""

	local fullText = LocalizationUtil.get(nodeData.textKey or "")

	-- Typewriter
	_typeTask = task.spawn(function()
		for i = 1, #fullText do
			_textLabel.Text = string.sub(fullText, 1, i)
			task.wait(CHAR_DELAY)
		end
		_typeTask = nil
	end)

	-- Skip typewriter on frame click/tap
	local frame = _gui:FindFirstChildOfClass("Frame")
	if frame then
		_skipConn = frame.InputBegan:Connect(function()
			if _typeTask then
				cancelTypewriter()
				_textLabel.Text = fullText
			end
		end)
	end

	-- Build choice buttons
	local choiceCount = 0
	for order, choice in nodeData.choices do
		choiceCount = choiceCount + 1

		local disabled = false
		if choice.requiredMoralityMin then
			-- Will be checked at render time; server enforces hard-gate
			disabled = false
		end

		local btn                    = Instance.new("TextButton")
		btn.Name                     = "Choice_" .. tostring(choice.choiceIndex)
		btn.LayoutOrder              = order
		btn.Size                     = UDim2.new(1, 0, 0, MIN_BTN_SIZE)
		btn.BackgroundColor3         = disabled
			and Color3.fromRGB(50, 50, 50)
			or  Color3.fromRGB(50, 50, 70)
		btn.BorderSizePixel          = 0
		btn.TextColor3               = disabled
			and Color3.fromRGB(100, 100, 100)
			or  Color3.new(1, 1, 1)
		btn.Font                     = Enum.Font.Gotham
		btn.TextSize                 = 14
		btn.TextWrapped              = true
		btn.Text                     = LocalizationUtil.get(choice.labelKey or "")
		btn.Active                   = not disabled
		btn.Parent                   = _choiceFrame

		local btnCorner              = Instance.new("UICorner")
		btnCorner.CornerRadius       = UDim.new(0, 6)
		btnCorner.Parent             = btn

		if not disabled then
			local idx = choice.choiceIndex
			btn.Activated:Connect(function()
				clearChoices()
				_npcService.DialogChoice:Fire(npcId, idx)
			end)
		end
	end

	-- On mobile with >3 choices: enable ScrollingFrame so all choices are reachable
	if IS_MOBILE and choiceCount > 3 then
		local rowH   = MIN_BTN_SIZE + 4
		local maxH   = rowH * 3          -- show 3 rows, scroll for the rest
		_choiceFrame.Size                = UDim2.new(1, -24, 0, maxH)
		_choiceFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		_choiceFrame.CanvasSize          = UDim2.fromScale(0, 0)
		_choiceFrame.ScrollBarThickness  = 4
		_choiceFrame.ScrollBarImageTransparency = 0
	else
		_choiceFrame.Size                = UDim2.new(1, -24, 0, MIN_BTN_SIZE * math.max(choiceCount, 1) + 4 * math.max(choiceCount - 1, 0))
		_choiceFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
		_choiceFrame.ScrollBarThickness  = 0
	end

	-- Auto-close 2s after typewriter finishes when no choices
	if choiceCount == 0 then
		_autoCloseTask = task.delay(#fullText * CHAR_DELAY + 2, function()
			_autoCloseTask = nil
			closeDialog()
		end)
	end
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function DialogController:KnitInit()
	buildUI()
end

function DialogController:KnitStart()
	_npcService = Knit.GetService("NPCService")

	_npcService.DialogOpen:Connect(function(npcId, nodeData)
		showNode(npcId, nodeData)
	end)

	_npcService.DialogClose:Connect(function()
		closeDialog()
	end)
end

return DialogController
