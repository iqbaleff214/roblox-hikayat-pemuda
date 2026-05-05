-- LocalScript: StarterPlayerScripts/Client/Controllers/RelationshipController
-- Handles incoming relationship requests (shows accept/decline dialog).
-- On RelationshipFormed: shows notification and applies nameplate badge.
-- On UpdateNameplate: adds/removes BillboardGui badge above the player's head.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local RelationshipController = Knit.CreateController { Name = "RelationshipController" }

-- ── State ─────────────────────────────────────────────────────────

local _relService  = nil
local _requestGui  = nil

-- ── Nameplate badges ──────────────────────────────────────────────

local function getCharacterHead(userId)
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return nil
	end
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("Head")
end

local function applyNameplateBadge(head, relType)
	local existing = head:FindFirstChild("RelBadge")
	if existing then
		existing:Destroy()
	end

	if not relType then
		return
	end

	local relCfg = AssetConfig.Relationships[relType]
	if not relCfg then
		return
	end

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
	if _requestGui then
		return _requestGui
	end

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

local function showRequestDialog(fromUserId, fromName, relType)
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
end

-- ── Public API ────────────────────────────────────────────────────

function RelationshipController:sendRequest(targetUserId, relType)
	if not _relService then
		return
	end
	_relService.SendRequest:Fire(targetUserId, relType)
end

function RelationshipController:removeRelationship(targetUserId)
	if not _relService then
		return
	end
	_relService.RemoveRelationship:Fire(targetUserId)
end

return RelationshipController
