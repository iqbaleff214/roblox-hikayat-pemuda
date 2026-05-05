-- LocalScript: StarterPlayerScripts/Client/Controllers/LoginStreakController
-- Listens to LoginStreakClaimed from LoginStreakService.
-- Shows a streak popup that auto-dismisses after 5 seconds or on tap/click.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local LoginStreakController = Knit.CreateController { Name = "LoginStreakController" }

-- ── UI ────────────────────────────────────────────────────────────

local _gui = nil

local function ensureGui()
	if _gui then return _gui end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg = Instance.new("ScreenGui")
	sg.Name           = "StreakPopup"
	sg.ResetOnSpawn   = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent         = playerGui

	-- Backdrop (full-screen, semi-transparent, dismissable)
	local backdrop = Instance.new("TextButton")
	backdrop.Name                   = "Backdrop"
	backdrop.Size                   = UDim2.fromScale(1, 1)
	backdrop.Position               = UDim2.fromScale(0, 0)
	backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.55
	backdrop.BorderSizePixel        = 0
	backdrop.Text                   = ""
	backdrop.ZIndex                 = 1
	backdrop.Visible                = false
	backdrop.Parent                 = sg

	-- Card
	local card = Instance.new("Frame")
	card.Name                   = "Card"
	card.Size                   = UDim2.fromOffset(320, 200)
	card.AnchorPoint            = Vector2.new(0.5, 0.5)
	card.Position               = UDim2.fromScale(0.5, 0.5)
	card.BackgroundColor3       = Color3.fromRGB(20, 20, 30)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel        = 0
	card.ZIndex                 = 2
	card.Visible                = false
	card.Parent                 = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent       = card

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name               = "Title"
	titleLabel.Size               = UDim2.new(1, -24, 0, 28)
	titleLabel.Position           = UDim2.fromOffset(12, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font               = Enum.Font.GothamBold
	titleLabel.TextSize           = 16
	titleLabel.TextColor3         = Color3.fromRGB(255, 215, 0)
	titleLabel.TextXAlignment     = Enum.TextXAlignment.Center
	titleLabel.Text               = "🔥 Login Streak!"
	titleLabel.ZIndex             = 3
	titleLabel.Parent             = card

	-- Streak day counter
	local dayLabel = Instance.new("TextLabel")
	dayLabel.Name               = "Day"
	dayLabel.Size               = UDim2.new(1, -24, 0, 48)
	dayLabel.Position           = UDim2.fromOffset(12, 44)
	dayLabel.BackgroundTransparency = 1
	dayLabel.Font               = Enum.Font.GothamBold
	dayLabel.TextSize            = 36
	dayLabel.TextColor3          = Color3.fromRGB(255, 255, 255)
	dayLabel.TextXAlignment      = Enum.TextXAlignment.Center
	dayLabel.Text                = "Hari 1"
	dayLabel.ZIndex              = 3
	dayLabel.Parent              = card

	-- Reward description
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Name               = "Reward"
	rewardLabel.Size               = UDim2.new(1, -24, 0, 40)
	rewardLabel.Position           = UDim2.fromOffset(12, 96)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Font               = Enum.Font.Gotham
	rewardLabel.TextSize           = 14
	rewardLabel.TextColor3         = Color3.fromRGB(200, 255, 180)
	rewardLabel.TextXAlignment     = Enum.TextXAlignment.Center
	rewardLabel.TextWrapped        = true
	rewardLabel.Text               = ""
	rewardLabel.ZIndex             = 3
	rewardLabel.Parent             = card

	-- Next milestone hint
	local nextLabel = Instance.new("TextLabel")
	nextLabel.Name               = "Next"
	nextLabel.Size               = UDim2.new(1, -24, 0, 24)
	nextLabel.Position           = UDim2.fromOffset(12, 140)
	nextLabel.BackgroundTransparency = 1
	nextLabel.Font               = Enum.Font.Gotham
	nextLabel.TextSize           = 12
	nextLabel.TextColor3         = Color3.fromRGB(150, 150, 170)
	nextLabel.TextXAlignment     = Enum.TextXAlignment.Center
	nextLabel.Text               = ""
	nextLabel.ZIndex             = 3
	nextLabel.Parent             = card

	-- Dismiss hint
	local dismissHint = Instance.new("TextLabel")
	dismissHint.Name               = "DismissHint"
	dismissHint.Size               = UDim2.new(1, -24, 0, 18)
	dismissHint.Position           = UDim2.fromOffset(12, 174)
	dismissHint.BackgroundTransparency = 1
	dismissHint.Font               = Enum.Font.Gotham
	dismissHint.TextSize           = 11
	dismissHint.TextColor3         = Color3.fromRGB(100, 100, 110)
	dismissHint.TextXAlignment     = Enum.TextXAlignment.Center
	dismissHint.Text               = "Ketuk untuk menutup"
	dismissHint.ZIndex             = 3
	dismissHint.Parent             = card

	_gui = {
		sg           = sg,
		backdrop     = backdrop,
		card         = card,
		dayLabel     = dayLabel,
		rewardLabel  = rewardLabel,
		nextLabel    = nextLabel,
	}
	return _gui
end

-- ── Reward summary builder ────────────────────────────────────────

local function rewardText(reward)
	if not reward then return "" end
	local parts = {}
	if reward.rupiah and reward.rupiah > 0 then
		parts[#parts + 1] = "Rp " .. tostring(reward.rupiah)
	end
	if reward.gold and reward.gold > 0 then
		parts[#parts + 1] = tostring(reward.gold) .. " Gold"
	end
	if reward.items then
		for _, it in reward.items do
			parts[#parts + 1] = "x" .. tostring(it.amount) .. " " .. tostring(it.id)
		end
	end
	return table.concat(parts, "  +  ")
end

-- ── Show/hide ─────────────────────────────────────────────────────

local _dismissTask = nil
local SCALE_IN  = TweenInfo.new(0.3, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local SCALE_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)

local function hidePopup(gui)
	TweenService:Create(gui.card, SCALE_OUT, { Size = UDim2.fromOffset(0, 0) }):Play()
	task.delay(0.25, function()
		gui.card.Visible    = false
		gui.backdrop.Visible = false
		gui.card.Size       = UDim2.fromOffset(320, 200)
	end)
end

local function showPopup(payload)
	local gui = ensureGui()

	gui.dayLabel.Text    = "Hari " .. tostring(payload.streak)
	gui.rewardLabel.Text = rewardText(payload.reward)

	if payload.nextDay then
		gui.nextLabel.Text = "Milestone berikutnya: Hari " .. tostring(payload.nextDay)
	else
		gui.nextLabel.Text = "Semua milestone telah dicapai!"
	end

	-- Reset card size for scale-in animation
	gui.card.Size    = UDim2.fromOffset(0, 0)
	gui.backdrop.Visible = true
	gui.card.Visible     = true

	TweenService:Create(gui.card, SCALE_IN, { Size = UDim2.fromOffset(320, 200) }):Play()

	if _dismissTask then
		task.cancel(_dismissTask)
		_dismissTask = nil
	end
	_dismissTask = task.delay(5, function()
		hidePopup(gui)
		_dismissTask = nil
	end)
end

local function connectDismiss(gui)
	local function dismiss()
		if _dismissTask then
			task.cancel(_dismissTask)
			_dismissTask = nil
		end
		hidePopup(gui)
	end
	gui.backdrop.Activated:Connect(dismiss)
	gui.card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			dismiss()
		end
	end)
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function LoginStreakController:KnitInit()
end

function LoginStreakController:KnitStart()
	local loginStreakService = Knit.GetService("LoginStreakService")
	loginStreakService.LoginStreakClaimed:Connect(function(payload)
		showPopup(payload)
	end)

	task.defer(function()
		local gui = ensureGui()
		connectDismiss(gui)
	end)
end

return LoginStreakController
