-- LocalScript: StarterPlayerScripts/Client/Controllers/MoralityController
-- Listens to the MoralityChanged RemoteEvent, caches morality state,
-- and shows a brief tier-change notification with a placeholder VFX hint.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local MoralityController = Knit.CreateController { Name = "MoralityController" }

-- ── State ─────────────────────────────────────────────────────────

local _morality   = 50
local _tierLabel  = ""
local _notifGui   = nil

-- ── UI helpers ────────────────────────────────────────────────────

local function ensureGui()
	if _notifGui then return _notifGui end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local sg = Instance.new("ScreenGui")
	sg.Name            = "MoralityNotif"
	sg.ResetOnSpawn    = false
	sg.IgnoreGuiInset  = true
	sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	sg.Parent          = playerGui

	local frame = Instance.new("Frame")
	frame.Name            = "NotifFrame"
	frame.Size            = UDim2.fromOffset(240, 48)
	frame.AnchorPoint     = Vector2.new(0.5, 0)
	frame.Position        = UDim2.new(0.5, 0, 0, -60)  -- starts above screen
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent          = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name            = "Label"
	label.Size            = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font            = Enum.Font.GothamBold
	label.TextSize        = 14
	label.TextColor3      = Color3.fromRGB(255, 255, 255)
	label.TextXAlignment  = Enum.TextXAlignment.Center
	label.Parent          = frame

	_notifGui = { sg = sg, frame = frame, label = label }
	return _notifGui
end

local _dismissTask = nil

local SLIDE_IN_Y  = UDim2.new(0.5, 0, 0, 12)
local SLIDE_OUT_Y = UDim2.new(0.5, 0, 0, -60)
local TWEEN_INFO  = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function showNotif(text, color)
	local gui = ensureGui()
	gui.label.Text      = text
	gui.label.TextColor3 = color or Color3.fromRGB(255, 255, 255)

	-- Cancel any pending dismiss
	if _dismissTask then
		task.cancel(_dismissTask)
		_dismissTask = nil
	end

	-- Slide in
	gui.frame.Position = SLIDE_OUT_Y
	TweenService:Create(gui.frame, TWEEN_INFO, { Position = SLIDE_IN_Y }):Play()

	-- Auto-dismiss after 3 seconds
	_dismissTask = task.delay(3, function()
		TweenService:Create(gui.frame, TWEEN_INFO, { Position = SLIDE_OUT_Y }):Play()
		_dismissTask = nil
	end)
end

-- ── MoralityChanged handler ───────────────────────────────────────

local function onMoralityChanged(payload)
	local prevLabel = _tierLabel
	_morality  = payload.value
	_tierLabel = payload.labelKey or ""

	-- Placeholder VFX tag (actual particles wired in Phase 7+)
	-- payload.delta > 0 → rise effect; < 0 → fall effect
	local arrow = payload.delta > 0 and "▲" or "▼"
	local color  = payload.delta > 0
		and Color3.fromRGB(100, 220, 100)
		or  Color3.fromRGB(220, 80, 80)

	local text = arrow .. " " .. (payload.delta > 0 and "+" or "") .. tostring(payload.delta)

	-- Only show tier badge if tier actually changed
	if _tierLabel ~= prevLabel and _tierLabel ~= "" then
		text = text .. "  |  " .. _tierLabel
	end

	showNotif(text, color)
end

-- ── KnitInit / KnitStart ─────────────────────────────────────────

function MoralityController:KnitInit()
end

function MoralityController:KnitStart()
	local re = ReplicatedStorage
		:WaitForChild("RemoteEvents")
		:WaitForChild("MoralityChanged")
	re.OnClientEvent:Connect(onMoralityChanged)
end

-- ── Public API ────────────────────────────────────────────────────

function MoralityController:get()
	return _morality
end

function MoralityController:getTierLabel()
	return _tierLabel
end

return MoralityController
