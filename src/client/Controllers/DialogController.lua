-- LocalScript (Knit Controller): StarterPlayerScripts/Client/Controllers/DialogController
-- Receives dialog nodes from NPCService, renders typewriter text and choice buttons.
-- Fires DialogChoice back to server when player selects an option.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit             = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local LocalizationUtil = require(ReplicatedStorage:WaitForChild("Shared").Modules.LocalizationUtil)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local CHAR_DELAY   = 0.03 -- seconds between typewriter characters
local MIN_BTN_SIZE = 44   -- minimum button height in px (mobile-friendly)

local DialogController = Knit.CreateController { Name = "DialogController" }

-- ── UI state ──────────────────────────────────────────────────────

local _gui           = nil
local _frame         = nil
local _speakerLabel  = nil
local _textLabel     = nil
local _choiceFrame   = nil
local _skipConn      = nil  -- InputBegan connection for typewriter skip
local _typeTask      = nil  -- task thread for active typewriter

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
	frame.Size                       = UDim2.new(1, -40, 0, 210)
	frame.Position                   = UDim2.new(0, 20, 1, -230)
	frame.BackgroundColor3           = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency     = 0.2
	frame.BorderSizePixel            = 0
	frame.Parent                     = screenGui

	local corner                     = Instance.new("UICorner")
	corner.CornerRadius              = UDim.new(0, 8)
	corner.Parent                    = frame

	local speaker                    = Instance.new("TextLabel")
	speaker.Name                     = "SpeakerLabel"
	speaker.Size                     = UDim2.new(1, -20, 0, 28)
	speaker.Position                 = UDim2.new(0, 10, 0, 8)
	speaker.BackgroundTransparency   = 1
	speaker.TextColor3               = Color3.fromRGB(255, 200, 80)
	speaker.Font                     = Enum.Font.GothamBold
	speaker.TextSize                 = 18
	speaker.TextXAlignment           = Enum.TextXAlignment.Left
	speaker.Text                     = ""
	speaker.Parent                   = frame

	local textLbl                    = Instance.new("TextLabel")
	textLbl.Name                     = "DialogText"
	textLbl.Size                     = UDim2.new(1, -20, 0, 85)
	textLbl.Position                 = UDim2.new(0, 10, 0, 40)
	textLbl.BackgroundTransparency   = 1
	textLbl.TextColor3               = Color3.new(1, 1, 1)
	textLbl.Font                     = Enum.Font.Gotham
	textLbl.TextSize                 = 16
	textLbl.TextWrapped              = true
	textLbl.TextXAlignment           = Enum.TextXAlignment.Left
	textLbl.TextYAlignment           = Enum.TextYAlignment.Top
	textLbl.Text                     = ""
	textLbl.Parent                   = frame

	local choiceFr                   = Instance.new("Frame")
	choiceFr.Name                    = "ChoiceFrame"
	choiceFr.Size                    = UDim2.new(1, -20, 0, 80)
	choiceFr.Position                = UDim2.new(0, 10, 0, 132)
	choiceFr.BackgroundTransparency  = 1
	choiceFr.ClipsDescendants        = false
	choiceFr.Parent                  = frame

	local list                       = Instance.new("UIListLayout")
	list.SortOrder                   = Enum.SortOrder.LayoutOrder
	list.Padding                     = UDim.new(0, 4)
	list.Parent                      = choiceFr

	_gui          = screenGui
	_frame        = frame
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

-- ── NPCService reference (set in KnitStart) ───────────────────────

local _npcService = nil

-- ── Dialog rendering ──────────────────────────────────────────────

local function showNode(npcId, nodeData)
	cancelTypewriter()
	clearChoices()

	_gui.Enabled       = true
	_speakerLabel.Text = nodeData.speaker or ""
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

	-- Skip typewriter on background click / tap
	_skipConn = _frame.InputBegan:Connect(function()
		if _typeTask then
			cancelTypewriter()
			_textLabel.Text = fullText
		end
	end)

	-- Choice buttons
	for order, choice in nodeData.choices do
		local btn                        = Instance.new("TextButton")
		btn.Name                         = "Choice_" .. tostring(choice.choiceIndex)
		btn.LayoutOrder                  = order
		btn.Size                         = UDim2.new(1, 0, 0, MIN_BTN_SIZE)
		btn.BackgroundColor3             = Color3.fromRGB(50, 50, 70)
		btn.BorderSizePixel              = 0
		btn.TextColor3                   = Color3.new(1, 1, 1)
		btn.Font                         = Enum.Font.Gotham
		btn.TextSize                     = 14
		btn.TextWrapped                  = true
		btn.Text                         = LocalizationUtil.get(choice.labelKey or "")
		btn.Parent                       = _choiceFrame

		local btnCorner                  = Instance.new("UICorner")
		btnCorner.CornerRadius           = UDim.new(0, 6)
		btnCorner.Parent                 = btn

		local idx = choice.choiceIndex
		btn.Activated:Connect(function()
			clearChoices()
			_npcService.DialogChoice:Fire(npcId, idx)
		end)
	end
end

local function closeDialog()
	cancelTypewriter()
	clearChoices()
	_gui.Enabled       = false
	_textLabel.Text    = ""
	_speakerLabel.Text = ""
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
