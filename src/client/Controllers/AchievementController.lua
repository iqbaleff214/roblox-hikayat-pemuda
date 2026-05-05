-- LocalScript: StarterPlayerScripts/Client/Controllers/AchievementController
-- Phase 5: slide-in popup on AchievementUnlocked.
-- Phase 8: AchievementGui icon grid (6 columns), locked/unlocked states,
--          progress bars for count-based achievements. Public openAchievementGui().

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local AchievementController = Knit.CreateController { Name = "AchievementController" }

-- ── Popup (slide-in notification) ────────────────────────────────

local _popup = nil

local function ensurePopup()
	if _popup then return _popup end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg = Instance.new("ScreenGui")
	sg.Name           = "AchievementPopup"
	sg.ResetOnSpawn   = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent         = playerGui

	local card = Instance.new("Frame")
	card.Name                   = "Card"
	card.Size                   = UDim2.fromOffset(300, 72)
	card.AnchorPoint            = Vector2.new(1, 0)
	card.Position               = UDim2.new(1, 340, 0, 16)
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

	_popup = { sg = sg, card = card, nameLabel = nameLabel, descLabel = descLabel }
	return _popup
end

local _dismissTask = nil
local SHOW_POS     = UDim2.new(1, -16, 0, 16)
local HIDE_POS     = UDim2.new(1, 340,  0, 16)
local TWEEN_IN     = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_OUT    = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function showPopup(achConfig)
	local gui = ensurePopup()

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

-- ── Achievement GUI (icon grid) ───────────────────────────────────

local _gridGui = nil

local function buildGridGui()
	if _gridGui then return _gridGui end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg = Instance.new("ScreenGui")
	sg.Name           = "AchievementGui"
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
	panel.Size                   = UDim2.fromOffset(520, 540)
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
	titleLabel.Text              = "Pencapaian"
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

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name               = "Scroll"
	scroll.Size               = UDim2.new(1, -32, 1, -60)
	scroll.Position           = UDim2.fromOffset(16, 50)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel    = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
	scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
	scroll.CanvasSize           = UDim2.fromScale(0, 0)
	scroll.ZIndex               = 3
	scroll.Parent               = panel

	local grid = Instance.new("UIGridLayout")
	grid.CellSize    = UDim2.fromOffset(72, 88)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder   = Enum.SortOrder.LayoutOrder
	grid.Parent      = scroll

	-- Detail tooltip frame (shows on tap)
	local tooltip = Instance.new("Frame")
	tooltip.Name                   = "Tooltip"
	tooltip.Size                   = UDim2.fromOffset(240, 110)
	tooltip.AnchorPoint            = Vector2.new(0.5, 0)
	tooltip.Position               = UDim2.fromScale(0.5, 0)
	tooltip.BackgroundColor3       = Color3.fromRGB(30, 30, 50)
	tooltip.BackgroundTransparency = 0.05
	tooltip.BorderSizePixel        = 0
	tooltip.Visible                = false
	tooltip.ZIndex                 = 10
	tooltip.Parent                 = panel

	local tooltipCorner = Instance.new("UICorner")
	tooltipCorner.CornerRadius = UDim.new(0, 8)
	tooltipCorner.Parent       = tooltip

	local ttName = Instance.new("TextLabel")
	ttName.Name               = "Name"
	ttName.Size               = UDim2.new(1, -16, 0, 22)
	ttName.Position           = UDim2.fromOffset(8, 8)
	ttName.BackgroundTransparency = 1
	ttName.Font               = Enum.Font.GothamBold
	ttName.TextSize           = 14
	ttName.TextColor3         = Color3.fromRGB(255, 215, 0)
	ttName.TextXAlignment     = Enum.TextXAlignment.Left
	ttName.Text               = ""
	ttName.ZIndex             = 11
	ttName.Parent             = tooltip

	local ttDesc = Instance.new("TextLabel")
	ttDesc.Name               = "Desc"
	ttDesc.Size               = UDim2.new(1, -16, 0, 34)
	ttDesc.Position           = UDim2.fromOffset(8, 30)
	ttDesc.BackgroundTransparency = 1
	ttDesc.Font               = Enum.Font.Gotham
	ttDesc.TextSize           = 12
	ttDesc.TextColor3         = Color3.fromRGB(200, 200, 200)
	ttDesc.TextWrapped        = true
	ttDesc.TextXAlignment     = Enum.TextXAlignment.Left
	ttDesc.Text               = ""
	ttDesc.ZIndex             = 11
	ttDesc.Parent             = tooltip

	local ttProgress = Instance.new("TextLabel")
	ttProgress.Name               = "Progress"
	ttProgress.Size               = UDim2.new(1, -16, 0, 16)
	ttProgress.Position           = UDim2.fromOffset(8, 64)
	ttProgress.BackgroundTransparency = 1
	ttProgress.Font               = Enum.Font.Gotham
	ttProgress.TextSize           = 11
	ttProgress.TextColor3         = Color3.fromRGB(160, 255, 160)
	ttProgress.TextXAlignment     = Enum.TextXAlignment.Left
	ttProgress.Text               = ""
	ttProgress.ZIndex             = 11
	ttProgress.Parent             = tooltip

	local ttReward = Instance.new("TextLabel")
	ttReward.Name               = "Reward"
	ttReward.Size               = UDim2.new(1, -16, 0, 14)
	ttReward.Position           = UDim2.fromOffset(8, 90)
	ttReward.BackgroundTransparency = 1
	ttReward.Font               = Enum.Font.Gotham
	ttReward.TextSize           = 11
	ttReward.TextColor3         = Color3.fromRGB(255, 200, 80)
	ttReward.TextXAlignment     = Enum.TextXAlignment.Left
	ttReward.Text               = ""
	ttReward.ZIndex             = 11
	ttReward.Parent             = tooltip

	_gridGui = {
		sg        = sg,
		backdrop  = backdrop,
		panel     = panel,
		scroll    = scroll,
		closeBtn  = closeBtn,
		tooltip   = tooltip,
		ttName    = ttName,
		ttDesc    = ttDesc,
		ttProgress = ttProgress,
		ttReward  = ttReward,
	}
	return _gridGui
end

local function closeGridGui()
	if not _gridGui then return end
	_gridGui.sg.Enabled = false
end

local function buildRewardText(reward)
	if not reward then return "" end
	local parts = {}
	if reward.rupiah and reward.rupiah > 0 then
		table.insert(parts, "Rp " .. tostring(reward.rupiah))
	end
	if reward.gold and reward.gold > 0 then
		table.insert(parts, "◆ " .. tostring(reward.gold))
	end
	if reward.items then
		for _, it in reward.items do
			table.insert(parts, it.id)
		end
	end
	if #parts == 0 then return "" end
	return "Hadiah: " .. table.concat(parts, " + ")
end

local function renderGrid(unlockedSet, progressMap)
	local gui = buildGridGui()

	-- Clear previous cells
	for _, child in gui.scroll:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end

	gui.tooltip.Visible = false

	for order, achCfg in AssetConfig.Achievements do
		local unlocked = unlockedSet[achCfg.id] or false
		local progress = progressMap[achCfg.id] or 0
		local total    = achCfg.count or 1

		local cell = Instance.new("TextButton")
		cell.Name            = "Ach_" .. achCfg.id
		cell.LayoutOrder     = order
		cell.Size            = UDim2.fromOffset(72, 88)
		cell.BackgroundColor3 = unlocked
			and Color3.fromRGB(35, 35, 55)
			or  Color3.fromRGB(22, 22, 30)
		cell.BorderSizePixel = 0
		cell.Text            = ""
		cell.ZIndex          = 4
		cell.Parent          = gui.scroll

		local cellCorner = Instance.new("UICorner")
		cellCorner.CornerRadius = UDim.new(0, 6)
		cellCorner.Parent       = cell

		-- Icon area
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size               = UDim2.fromOffset(48, 48)
		iconLbl.AnchorPoint        = Vector2.new(0.5, 0)
		iconLbl.Position           = UDim2.new(0.5, 0, 0, 4)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Font               = Enum.Font.GothamBold
		iconLbl.TextSize           = 28
		iconLbl.TextColor3         = unlocked
			and Color3.fromRGB(255, 215, 0)
			or  Color3.fromRGB(70, 70, 80)
		iconLbl.Text               = unlocked and "🏅" or "🔒"
		iconLbl.ZIndex             = 5
		iconLbl.Parent             = cell

		-- Name label
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size               = UDim2.new(1, -4, 0, 20)
		nameLbl.Position           = UDim2.fromOffset(2, 54)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font               = Enum.Font.Gotham
		nameLbl.TextSize           = 9
		nameLbl.TextWrapped        = true
		nameLbl.TextColor3         = unlocked
			and Color3.fromRGB(220, 220, 220)
			or  Color3.fromRGB(90, 90, 100)
		nameLbl.Text               = achCfg.nameKey or achCfg.id
		nameLbl.ZIndex             = 5
		nameLbl.Parent             = cell

		-- Progress bar (count-based, not yet unlocked)
		if total > 1 and not unlocked then
			local barBg = Instance.new("Frame")
			barBg.Size               = UDim2.new(1, -8, 0, 4)
			barBg.Position           = UDim2.fromOffset(4, 76)
			barBg.BackgroundColor3   = Color3.fromRGB(40, 40, 60)
			barBg.BorderSizePixel    = 0
			barBg.ZIndex             = 5
			barBg.Parent             = cell

			local barCorner = Instance.new("UICorner")
			barCorner.CornerRadius  = UDim.new(0, 2)
			barCorner.Parent        = barBg

			local frac = math.clamp(progress / total, 0, 1)

			local barFill = Instance.new("Frame")
			barFill.Size             = UDim2.fromScale(frac, 1)
			barFill.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
			barFill.BorderSizePixel  = 0
			barFill.ZIndex           = 6
			barFill.Parent           = barBg

			local fillCorner = Instance.new("UICorner")
			fillCorner.CornerRadius = UDim.new(0, 2)
			fillCorner.Parent       = barFill
		end

		-- Tap to show tooltip
		local capCfg      = achCfg
		local capUnlocked = unlocked
		local capProgress = progress

		cell.Activated:Connect(function()
			gui.tooltip.Visible = true
			gui.ttName.Text     = capCfg.nameKey or capCfg.id
			gui.ttDesc.Text     = capCfg.descKey or ""

			if capCfg.count and capCfg.count > 1 then
				gui.ttProgress.Text = tostring(capProgress) .. "/" .. tostring(capCfg.count)
					.. (capUnlocked and " ✓" or "")
			elseif capUnlocked then
				gui.ttProgress.Text = "Selesai ✓"
			else
				gui.ttProgress.Text = "Belum selesai"
			end

			gui.ttReward.Text = buildRewardText(capCfg.reward)
		end)
	end
end

-- ── Public API ────────────────────────────────────────────────────

function AchievementController:openAchievementGui()
	local gui = buildGridGui()
	gui.sg.Enabled     = true
	gui.tooltip.Visible = false

	-- Request fresh data from service
	local achievementService = Knit.GetService("AchievementService")
	achievementService:getPlayerAchievements():andThen(function(data)
		local unlockedSet = {}
		local progressMap = {}
		if data then
			for _, entry in data do
				if entry.unlocked then
					unlockedSet[entry.id] = true
				end
				if entry.progress then
					progressMap[entry.id] = entry.progress
				end
			end
		end
		renderGrid(unlockedSet, progressMap)
	end):catch(function()
		renderGrid({}, {})
	end)
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function AchievementController:KnitInit()
end

function AchievementController:KnitStart()
	local achievementService = Knit.GetService("AchievementService")

	achievementService.AchievementUnlocked:Connect(function(achConfig)
		showPopup(achConfig)
		-- Re-render grid if open
		if _gridGui and _gridGui.sg.Enabled then
			self:openAchievementGui()
		end
	end)

	task.defer(function()
		local gui = ensurePopup()
		connectDismiss(gui)

		local gridGui = buildGridGui()
		gridGui.closeBtn.Activated:Connect(closeGridGui)
		gridGui.backdrop.Activated:Connect(closeGridGui)
		gridGui.panel.InputBegan:Connect(function()
			if gridGui.tooltip.Visible then
				gridGui.tooltip.Visible = false
			end
		end)
	end)
end

return AchievementController
