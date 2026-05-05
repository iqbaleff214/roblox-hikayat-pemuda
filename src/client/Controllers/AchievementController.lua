-- LocalScript: StarterPlayerScripts/Client/Controllers/AchievementController
-- Listens to AchievementUnlocked from AchievementService and shows a popup.
-- Popup auto-dismisses after 5 seconds or on tap/click.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local AchievementController = Knit.CreateController { Name = "AchievementController" }

-- ── UI ────────────────────────────────────────────────────────────

local _gui = nil

local function ensureGui()
	if _gui then return _gui end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg = Instance.new("ScreenGui")
	sg.Name           = "AchievementPopup"
	sg.ResetOnSpawn   = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent         = playerGui

	-- Card
	local card = Instance.new("Frame")
	card.Name                   = "Card"
	card.Size                   = UDim2.fromOffset(300, 72)
	card.AnchorPoint            = Vector2.new(1, 0)
	card.Position               = UDim2.new(1, 340, 0, 16)  -- starts off-screen right
	card.BackgroundColor3       = Color3.fromRGB(25, 25, 25)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel        = 0
	card.Parent                 = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent       = card

	local stripe = Instance.new("Frame")
	stripe.Name                   = "Stripe"
	stripe.Size                   = UDim2.new(0, 6, 1, 0)
	stripe.Position               = UDim2.fromOffset(0, 0)
	stripe.BackgroundColor3       = Color3.fromRGB(255, 215, 0)
	stripe.BorderSizePixel        = 0
	stripe.Parent                 = card

	local stripeCorner = Instance.new("UICorner")
	stripeCorner.CornerRadius = UDim.new(0, 10)
	stripeCorner.Parent       = stripe

	local icon = Instance.new("TextLabel")
	icon.Name                = "Icon"
	icon.Size                = UDim2.fromOffset(44, 44)
	icon.Position            = UDim2.fromOffset(14, 14)
	icon.BackgroundTransparency = 1
	icon.Font                = Enum.Font.GothamBold
	icon.TextSize            = 28
	icon.TextColor3          = Color3.fromRGB(255, 215, 0)
	icon.Text                = "🏅"
	icon.TextXAlignment      = Enum.TextXAlignment.Center
	icon.Parent              = card

	local title = Instance.new("TextLabel")
	title.Name               = "Title"
	title.Size               = UDim2.new(1, -70, 0, 20)
	title.Position           = UDim2.fromOffset(62, 10)
	title.BackgroundTransparency = 1
	title.Font               = Enum.Font.GothamBold
	title.TextSize           = 13
	title.TextColor3         = Color3.fromRGB(255, 215, 0)
	title.TextXAlignment     = Enum.TextXAlignment.Left
	title.Text               = "Pencapaian Baru!"
	title.Parent             = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name               = "AchName"
	nameLabel.Size               = UDim2.new(1, -70, 0, 20)
	nameLabel.Position           = UDim2.fromOffset(62, 30)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font               = Enum.Font.Gotham
	nameLabel.TextSize           = 13
	nameLabel.TextColor3         = Color3.fromRGB(230, 230, 230)
	nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
	nameLabel.Text               = ""
	nameLabel.Parent             = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Name               = "AchDesc"
	descLabel.Size               = UDim2.new(1, -70, 0, 16)
	descLabel.Position           = UDim2.fromOffset(62, 50)
	descLabel.BackgroundTransparency = 1
	descLabel.Font               = Enum.Font.Gotham
	descLabel.TextSize           = 11
	descLabel.TextColor3         = Color3.fromRGB(160, 160, 160)
	descLabel.TextXAlignment     = Enum.TextXAlignment.Left
	descLabel.Text               = ""
	descLabel.Parent             = card

	_gui = { sg = sg, card = card, nameLabel = nameLabel, descLabel = descLabel }
	return _gui
end

local _dismissTask = nil
local SHOW_POS    = UDim2.new(1, -16, 0, 16)
local HIDE_POS    = UDim2.new(1, 340,  0, 16)
local TWEEN_IN    = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_OUT   = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function showAchievement(achConfig)
	local gui = ensureGui()

	gui.nameLabel.Text = achConfig.nameKey or achConfig.id or "?"
	gui.descLabel.Text = achConfig.descKey or ""

	if _dismissTask then
		task.cancel(_dismissTask)
		_dismissTask = nil
	end

	gui.card.Position = HIDE_POS
	TweenService:Create(gui.card, TWEEN_IN, { Position = SHOW_POS }):Play()

	_dismissTask = task.delay(5, function()
		TweenService:Create(gui.card, TWEEN_OUT, { Position = HIDE_POS }):Play()
		_dismissTask = nil
	end)
end

-- Tap/click to dismiss early
local function connectDismiss(gui)
	gui.card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			if _dismissTask then
				task.cancel(_dismissTask)
				_dismissTask = nil
			end
			TweenService:Create(gui.card, TWEEN_OUT, { Position = HIDE_POS }):Play()
		end
	end)
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function AchievementController:KnitInit()
end

function AchievementController:KnitStart()
	local achievementService = Knit.GetService("AchievementService")
	achievementService.AchievementUnlocked:Connect(function(achConfig)
		showAchievement(achConfig)
	end)

	-- Wire dismiss gesture once UI exists
	task.defer(function()
		local gui = ensureGui()
		connectDismiss(gui)
	end)
end

return AchievementController
