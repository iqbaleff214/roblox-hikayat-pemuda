-- LocalScript: StarterPlayerScripts/Client/Controllers/TaskController
-- Caches daily/weekly task state from TaskService.
-- Builds TaskGui panel with Harian/Mingguan tabs, progress bars, Klaim/Reroll buttons,
-- and a countdown to next reset.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local TaskController = Knit.CreateController { Name = "TaskController" }

-- ── State ─────────────────────────────────────────────────────────

local _taskService = nil
local _taskState   = { dailyTasks = {}, weeklyTasks = {} }
local _gui         = nil
local _activeTab   = "Harian"

-- ── Helpers ───────────────────────────────────────────────────────

-- Returns "Reset dalam HH:MM" string counting down to next midnight WIB (UTC+7)
local function resetCountdown(isWeekly)
	local now      = os.time()
	local nowUtc   = now                         -- os.time() is UTC on Roblox server
	local wib      = nowUtc + 7 * 3600           -- WIB = UTC+7
	local dayStart = wib - (wib % 86400)         -- start of current WIB day

	local nextReset
	if isWeekly then
		-- next Monday midnight WIB (weekday 0=Sun in os.date)
		local weekday = tonumber(os.date("*t", wib).wday) or 1 -- 1=Sun
		local daysToMon = (9 - weekday) % 7
		if daysToMon == 0 then
			daysToMon = 7
		end
		nextReset = dayStart + daysToMon * 86400
	else
		nextReset = dayStart + 86400
	end

	local remaining = nextReset - wib
	if remaining < 0 then
		remaining = 0
	end

	local hours   = math.floor(remaining / 3600)
	local minutes = math.floor((remaining % 3600) / 60)
	return string.format("Reset dalam %02d:%02d", hours, minutes)
end

local function rewardText(reward)
	if not reward then
		return ""
	end
	local parts = {}
	if reward.rupiah and reward.rupiah > 0 then
		parts[#parts + 1] = "Rp " .. tostring(reward.rupiah)
	end
	if reward.gold and reward.gold > 0 then
		parts[#parts + 1] = tostring(reward.gold) .. " Gold"
	end
	if reward.items then
		for _, it in reward.items do
			parts[#parts + 1] = "x" .. tostring(it.amount or 1) .. " " .. tostring(it.id)
		end
	end
	return table.concat(parts, " + ")
end

-- ── GUI construction ──────────────────────────────────────────────

local function buildGui()
	if _gui then
		return _gui
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg              = Instance.new("ScreenGui")
	sg.Name               = "TaskGui"
	sg.ResetOnSpawn       = false
	sg.IgnoreGuiInset     = true
	sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	sg.Enabled            = false
	sg.Parent             = playerGui

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
	titleLabel.Text               = "Tugas"
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

	-- Tab bar
	local tabBar              = Instance.new("Frame")
	tabBar.Name               = "TabBar"
	tabBar.Size               = UDim2.new(1, -32, 0, 34)
	tabBar.Position           = UDim2.fromOffset(16, 50)
	tabBar.BackgroundTransparency = 1
	tabBar.ZIndex             = 3
	tabBar.Parent             = panel

	local tabLayout              = Instance.new("UIListLayout")
	tabLayout.FillDirection      = Enum.FillDirection.Horizontal
	tabLayout.SortOrder          = Enum.SortOrder.LayoutOrder
	tabLayout.Padding            = UDim.new(0, 4)
	tabLayout.Parent             = tabBar

	local tabHarian              = Instance.new("TextButton")
	tabHarian.Name               = "TabHarian"
	tabHarian.Size               = UDim2.new(0.5, -2, 1, 0)
	tabHarian.BackgroundColor3   = Color3.fromRGB(70, 70, 120)
	tabHarian.BorderSizePixel    = 0
	tabHarian.Font               = Enum.Font.GothamBold
	tabHarian.TextSize           = 14
	tabHarian.TextColor3         = Color3.fromRGB(255, 255, 255)
	tabHarian.Text               = "Harian"
	tabHarian.LayoutOrder        = 1
	tabHarian.ZIndex             = 4
	tabHarian.Parent             = tabBar

	local thCorner       = Instance.new("UICorner")
	thCorner.CornerRadius = UDim.new(0, 6)
	thCorner.Parent       = tabHarian

	local tabMingguan              = Instance.new("TextButton")
	tabMingguan.Name               = "TabMingguan"
	tabMingguan.Size               = UDim2.new(0.5, -2, 1, 0)
	tabMingguan.BackgroundColor3   = Color3.fromRGB(40, 40, 60)
	tabMingguan.BorderSizePixel    = 0
	tabMingguan.Font               = Enum.Font.GothamBold
	tabMingguan.TextSize           = 14
	tabMingguan.TextColor3         = Color3.fromRGB(180, 180, 180)
	tabMingguan.Text               = "Mingguan"
	tabMingguan.LayoutOrder        = 2
	tabMingguan.ZIndex             = 4
	tabMingguan.Parent             = tabBar

	local tmCorner       = Instance.new("UICorner")
	tmCorner.CornerRadius = UDim.new(0, 6)
	tmCorner.Parent       = tabMingguan

	-- Countdown label
	local countdownLabel              = Instance.new("TextLabel")
	countdownLabel.Name               = "Countdown"
	countdownLabel.Size               = UDim2.new(1, -32, 0, 20)
	countdownLabel.Position           = UDim2.fromOffset(16, 88)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Font               = Enum.Font.Gotham
	countdownLabel.TextSize           = 12
	countdownLabel.TextColor3         = Color3.fromRGB(140, 140, 160)
	countdownLabel.TextXAlignment     = Enum.TextXAlignment.Left
	countdownLabel.Text               = ""
	countdownLabel.ZIndex             = 3
	countdownLabel.Parent             = panel

	-- Scroll list
	local scroll              = Instance.new("ScrollingFrame")
	scroll.Name               = "Scroll"
	scroll.Size               = UDim2.new(1, -32, 1, -126)
	scroll.Position           = UDim2.fromOffset(16, 112)
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

	_gui = {
		sg             = sg,
		backdrop       = backdrop,
		panel          = panel,
		scroll         = scroll,
		tabHarian      = tabHarian,
		tabMingguan    = tabMingguan,
		countdownLabel = countdownLabel,
		closeBtn       = closeBtn,
	}

	return _gui
end

-- ── Task row builder ──────────────────────────────────────────────

local function buildTaskRow(parent, task, taskIndex, isWeekly, taskController)
	local cfg = nil
	for _, t in (AssetConfig.Tasks or {}) do
		if t.id == task.templateId then
			cfg = t
			break
		end
	end

	local row              = Instance.new("Frame")
	row.Name               = "Task_" .. taskIndex
	row.Size               = UDim2.new(1, -4, 0, 80)
	row.BackgroundColor3   = Color3.fromRGB(28, 28, 42)
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel    = 0
	row.LayoutOrder        = taskIndex
	row.ZIndex             = 4
	row.Parent             = parent

	local rowCorner       = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent       = row

	local nameLabel              = Instance.new("TextLabel")
	nameLabel.Size               = UDim2.new(0.6, 0, 0, 20)
	nameLabel.Position           = UDim2.fromOffset(10, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font               = Enum.Font.GothamBold
	nameLabel.TextSize           = 13
	nameLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
	nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
	nameLabel.Text               = (cfg and cfg.titleKey) or task.templateId or "Tugas"
	nameLabel.ZIndex             = 5
	nameLabel.Parent             = row

	-- Progress text
	local progTotal = cfg and cfg.goal or 1
	local progCur   = task.progress or 0
	local progLabel              = Instance.new("TextLabel")
	progLabel.Size               = UDim2.new(0.55, 0, 0, 16)
	progLabel.Position           = UDim2.fromOffset(10, 30)
	progLabel.BackgroundTransparency = 1
	progLabel.Font               = Enum.Font.Gotham
	progLabel.TextSize           = 11
	progLabel.TextColor3         = Color3.fromRGB(160, 160, 160)
	progLabel.TextXAlignment     = Enum.TextXAlignment.Left
	progLabel.Text               = tostring(progCur) .. " / " .. tostring(progTotal)
	progLabel.ZIndex             = 5
	progLabel.Parent             = row

	-- Progress bar
	local barOuter              = Instance.new("Frame")
	barOuter.Size               = UDim2.new(0.55, 0, 0, 6)
	barOuter.Position           = UDim2.fromOffset(10, 50)
	barOuter.BackgroundColor3   = Color3.fromRGB(40, 40, 60)
	barOuter.BorderSizePixel    = 0
	barOuter.ZIndex             = 5
	barOuter.Parent             = row

	local barOutCorner       = Instance.new("UICorner")
	barOutCorner.CornerRadius = UDim.new(0.5, 0)
	barOutCorner.Parent       = barOuter

	local frac = math.clamp(progCur / math.max(progTotal, 1), 0, 1)

	local barFill              = Instance.new("Frame")
	barFill.Size               = UDim2.fromScale(frac, 1)
	barFill.BackgroundColor3   = task.completed and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(60, 120, 200)
	barFill.BorderSizePixel    = 0
	barFill.ZIndex             = 6
	barFill.Parent             = barOuter

	local barFillCorner       = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(0.5, 0)
	barFillCorner.Parent       = barFill

	-- Reward preview
	local rewardStr  = cfg and rewardText(cfg.reward) or ""
	local rewardLabel              = Instance.new("TextLabel")
	rewardLabel.Size               = UDim2.new(0.55, 0, 0, 14)
	rewardLabel.Position           = UDim2.fromOffset(10, 60)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Font               = Enum.Font.Gotham
	rewardLabel.TextSize           = 10
	rewardLabel.TextColor3         = Color3.fromRGB(255, 215, 0)
	rewardLabel.TextXAlignment     = Enum.TextXAlignment.Left
	rewardLabel.Text               = rewardStr
	rewardLabel.ZIndex             = 5
	rewardLabel.Parent             = row

	-- Claim / Reroll buttons
	local btnX = UDim2.new(0.6, 4, 0, 10)

	if task.completed and not task.claimed then
		local claimBtn              = Instance.new("TextButton")
		claimBtn.Size               = UDim2.new(0.38, 0, 0, 36)
		claimBtn.Position           = btnX
		claimBtn.BackgroundColor3   = Color3.fromRGB(40, 160, 60)
		claimBtn.BorderSizePixel    = 0
		claimBtn.Font               = Enum.Font.GothamBold
		claimBtn.TextSize           = 13
		claimBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
		claimBtn.Text               = "Klaim"
		claimBtn.ZIndex             = 5
		claimBtn.Parent             = row

		local cbCorner       = Instance.new("UICorner")
		cbCorner.CornerRadius = UDim.new(0, 6)
		cbCorner.Parent       = claimBtn

		claimBtn.Activated:Connect(function()
			taskController:claimTask(taskIndex, isWeekly)
			claimBtn.Active            = false
			claimBtn.BackgroundColor3  = Color3.fromRGB(80, 80, 80)
			claimBtn.Text              = "Diklaim"
		end)
	elseif task.claimed then
		local claimedLabel              = Instance.new("TextLabel")
		claimedLabel.Size               = UDim2.new(0.38, 0, 0, 36)
		claimedLabel.Position           = btnX
		claimedLabel.BackgroundTransparency = 1
		claimedLabel.Font               = Enum.Font.Gotham
		claimedLabel.TextSize           = 12
		claimedLabel.TextColor3         = Color3.fromRGB(100, 200, 100)
		claimedLabel.Text               = "✓ Diklaim"
		claimedLabel.ZIndex             = 5
		claimedLabel.Parent             = row
	end

	-- Reroll button (daily only)
	if not isWeekly then
		local rerollBtn              = Instance.new("TextButton")
		rerollBtn.Size               = UDim2.new(0.38, 0, 0, 28)
		rerollBtn.Position           = UDim2.new(0.6, 4, 0, 50)
		rerollBtn.BackgroundColor3   = Color3.fromRGB(100, 60, 160)
		rerollBtn.BackgroundTransparency = 0.2
		rerollBtn.BorderSizePixel    = 0
		rerollBtn.Font               = Enum.Font.Gotham
		rerollBtn.TextSize           = 11
		rerollBtn.TextColor3         = Color3.fromRGB(200, 200, 200)
		rerollBtn.Text               = "Ganti"
		rerollBtn.ZIndex             = 5
		rerollBtn.Parent             = row

		local rrCorner       = Instance.new("UICorner")
		rrCorner.CornerRadius = UDim.new(0, 6)
		rrCorner.Parent       = rerollBtn

		rerollBtn.Activated:Connect(function()
			taskController:rerollTask(taskIndex)
		end)
	end

	return row
end

-- ── Render task list ──────────────────────────────────────────────

local function renderTasks(taskController, isWeekly)
	local gui = buildGui()
	local scroll = gui.scroll

	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local tasks = isWeekly and _taskState.weeklyTasks or _taskState.dailyTasks
	if #tasks == 0 then
		local emptyLabel              = Instance.new("TextLabel")
		emptyLabel.Size               = UDim2.new(1, 0, 0, 40)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font               = Enum.Font.Gotham
		emptyLabel.TextSize           = 14
		emptyLabel.TextColor3         = Color3.fromRGB(140, 140, 160)
		emptyLabel.Text               = "Tidak ada tugas."
		emptyLabel.LayoutOrder        = 1
		emptyLabel.ZIndex             = 4
		emptyLabel.Parent             = scroll
		return
	end

	for i, task in tasks do
		buildTaskRow(scroll, task, i, isWeekly, taskController)
	end

	gui.countdownLabel.Text = resetCountdown(isWeekly)
end

local function setActiveTab(taskController, tabName)
	_activeTab = tabName
	local gui  = buildGui()

	if tabName == "Harian" then
		gui.tabHarian.BackgroundColor3  = Color3.fromRGB(70, 70, 120)
		gui.tabHarian.TextColor3        = Color3.fromRGB(255, 255, 255)
		gui.tabMingguan.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		gui.tabMingguan.TextColor3       = Color3.fromRGB(180, 180, 180)
		renderTasks(taskController, false)
	else
		gui.tabMingguan.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
		gui.tabMingguan.TextColor3       = Color3.fromRGB(255, 255, 255)
		gui.tabHarian.BackgroundColor3   = Color3.fromRGB(40, 40, 60)
		gui.tabHarian.TextColor3         = Color3.fromRGB(180, 180, 180)
		renderTasks(taskController, true)
	end
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function TaskController:KnitInit()
end

function TaskController:KnitStart()
	_taskService = Knit.GetService("TaskService")

	_taskService.TaskUpdate:Connect(function(taskData)
		_taskState = taskData
		if _gui and _gui.sg.Enabled then
			renderTasks(self, _activeTab == "Mingguan")
		end
	end)

	task.defer(function()
		local gui = buildGui()
		gui.closeBtn.Activated:Connect(function()
			gui.sg.Enabled = false
		end)
		gui.backdrop.Activated:Connect(function()
			gui.sg.Enabled = false
		end)
		gui.tabHarian.Activated:Connect(function()
			setActiveTab(self, "Harian")
		end)
		gui.tabMingguan.Activated:Connect(function()
			setActiveTab(self, "Mingguan")
		end)
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function TaskController:getDailyTasks()
	return _taskState.dailyTasks or {}
end

function TaskController:getWeeklyTasks()
	return _taskState.weeklyTasks or {}
end

function TaskController:claimTask(taskIndex, isWeekly)
	_taskService.ClaimTask:Fire(taskIndex, isWeekly == true)
end

function TaskController:rerollTask(taskIndex)
	_taskService.RerollTask:Fire(taskIndex)
end

function TaskController:openTaskGui()
	buildGui()
	_gui.sg.Enabled = true
	setActiveTab(self, _activeTab)
end

return TaskController
