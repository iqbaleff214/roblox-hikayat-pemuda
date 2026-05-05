-- LocalScript: StarterPlayerScripts/Client/Controllers/VFXController
-- Manages particle VFX and screen-feedback effects.
-- World VFX: clones prefabs from ReplicatedStorage/Prefabs/VFX/ (Studio-placed).
--   Falls back to a programmatic Part flash when prefab is missing.
-- Screen VFX: full-screen Frame tweens (stamina vignette, morality pulse).
-- Exposes PlayVFX BindableEvent in ReplicatedStorage.Shared for cross-script calls.
-- Also triggers on: CombatHit, MoralityChanged, AchievementUnlocked.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local Workspace     = game:GetService("Workspace")
local Debris        = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local VFXController = Knit.CreateController { Name = "VFXController" }

-- ── Screen GUI ────────────────────────────────────────────────────

local _screenGui    = nil
local _vignetteRed  = nil -- stamina depleted
local _pulseGold    = nil -- morality rise
local _pulseDark    = nil -- morality fall
local _achFlash     = nil -- achievement radiance

local TWEEN_FAST_IN  = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SLOW_OUT = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local TWEEN_MED_IN   = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED_OUT  = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local TWEEN_FLASH_IN  = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_FLASH_OUT = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function buildScreenGui()
	if _screenGui then return end

	local sg = Instance.new("ScreenGui")
	sg.Name           = "VFXGui"
	sg.ResetOnSpawn   = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder   = 100
	sg.Parent         = PlayerGui

	-- Red vignette (stamina depleted)
	local vignette            = Instance.new("Frame")
	vignette.Name             = "Vignette"
	vignette.Size             = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
	vignette.BackgroundTransparency = 1
	vignette.BorderSizePixel  = 0
	vignette.ZIndex           = 2
	vignette.Parent           = sg

	-- Gold pulse (morality rise)
	local pulseGold            = Instance.new("Frame")
	pulseGold.Name             = "PulseGold"
	pulseGold.Size             = UDim2.fromScale(1, 1)
	pulseGold.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	pulseGold.BackgroundTransparency = 1
	pulseGold.BorderSizePixel  = 0
	pulseGold.ZIndex           = 2
	pulseGold.Parent           = sg

	-- Dark pulse (morality fall)
	local pulseDark            = Instance.new("Frame")
	pulseDark.Name             = "PulseDark"
	pulseDark.Size             = UDim2.fromScale(1, 1)
	pulseDark.BackgroundColor3 = Color3.fromRGB(20, 0, 40)
	pulseDark.BackgroundTransparency = 1
	pulseDark.BorderSizePixel  = 0
	pulseDark.ZIndex           = 2
	pulseDark.Parent           = sg

	-- Achievement radiance (gold → transparent burst)
	local achFlash             = Instance.new("Frame")
	achFlash.Name              = "AchFlash"
	achFlash.Size              = UDim2.fromScale(1, 1)
	achFlash.BackgroundColor3  = Color3.fromRGB(255, 240, 150)
	achFlash.BackgroundTransparency = 1
	achFlash.BorderSizePixel   = 0
	achFlash.ZIndex            = 3
	achFlash.Parent            = sg

	_screenGui   = sg
	_vignetteRed = vignette
	_pulseGold   = pulseGold
	_pulseDark   = pulseDark
	_achFlash    = achFlash
end

-- ── Screen effect helpers ─────────────────────────────────────────

local function flashFrame(frame, peakTransparency, holdSec)
	frame.BackgroundTransparency = peakTransparency
	task.delay(holdSec, function()
		TweenService:Create(frame, TWEEN_SLOW_OUT,
			{ BackgroundTransparency = 1 }):Play()
	end)
end

local function pulseFrame(frame, peakTransparency)
	TweenService:Create(frame, TWEEN_FAST_IN,
		{ BackgroundTransparency = peakTransparency }):Play()
	task.delay(0.15, function()
		TweenService:Create(frame, TWEEN_MED_OUT,
			{ BackgroundTransparency = 1 }):Play()
	end)
end

-- ── World VFX helpers ─────────────────────────────────────────────

local _prefabFolder = nil

local function getPrefabFolder()
	if _prefabFolder then return _prefabFolder end
	local prefabs = ReplicatedStorage:FindFirstChild("Prefabs")
	if not prefabs then return nil end
	local vfx = prefabs:FindFirstChild("VFX")
	_prefabFolder = vfx
	return _prefabFolder
end

local function spawnWorldVFX(effectId, position, attachTo)
	local folder = getPrefabFolder()
	local prefab = folder and folder:FindFirstChild(effectId)

	if prefab then
		local clone   = prefab:Clone()
		clone.Parent  = Workspace

		if attachTo and attachTo:IsA("BasePart") then
			clone:PivotTo(attachTo.CFrame)
		elseif position then
			clone:PivotTo(CFrame.new(position))
		end

		-- Emit all ParticleEmitters once
		for _, pe in clone:GetDescendants() do
			if pe:IsA("ParticleEmitter") then
				pe:Emit(pe.Rate > 0 and math.ceil(pe.Rate * 0.5) or 20)
				pe.Enabled = false
			end
		end

		Debris:AddItem(clone, 3)
	else
		-- Fallback: brief Part flash at position
		if not position then return end

		local part             = Instance.new("Part")
		part.Name              = "VFX_" .. effectId
		part.Size              = Vector3.new(1.5, 1.5, 1.5)
		part.Position          = position + Vector3.new(0, 1, 0)
		part.Anchored          = true
		part.CanCollide        = false
		part.CastShadow        = false
		part.Shape             = Enum.PartType.Ball
		part.Material          = Enum.Material.Neon
		part.Transparency      = 0.2

		if effectId == AssetConfig.Audio.VFX.MoralityRise then
			part.BrickColor = BrickColor.new("Bright yellow")
		elseif effectId == AssetConfig.Audio.VFX.MoralityFall then
			part.BrickColor = BrickColor.new("Dark purple")
		else
			part.BrickColor = BrickColor.new("Bright orange")
		end

		part.Parent = Workspace

		TweenService:Create(part,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1, Size = Vector3.new(3, 3, 3) }
		):Play()

		Debris:AddItem(part, 1)
	end
end

-- ── PlayVFX BindableEvent ─────────────────────────────────────────

local _playVFXEvent = nil

local function buildPlayVFXEvent()
	local shared = ReplicatedStorage:WaitForChild("Shared")
	local existing = shared:FindFirstChild("PlayVFX")
	if existing and existing:IsA("BindableEvent") then
		_playVFXEvent = existing
		return
	end
	_playVFXEvent      = Instance.new("BindableEvent")
	_playVFXEvent.Name = "PlayVFX"
	_playVFXEvent.Parent = shared
end

-- ── Specific VFX triggers ─────────────────────────────────────────

local function onCombatHit(_, hitPosition, _weaponId)
	spawnWorldVFX(AssetConfig.Audio.VFX.HitSpark, hitPosition, nil)
end

local function onMoralityChanged(payload)
	if not payload then return end
	local delta = payload.delta or 0

	if delta > 0 then
		pulseFrame(_pulseGold, 0.55)
		local char = LocalPlayer.Character
		local pos  = char and char:FindFirstChild("HumanoidRootPart")
			and char.HumanoidRootPart.Position
		if pos then
			spawnWorldVFX(AssetConfig.Audio.VFX.MoralityRise, pos, nil)
		end
	elseif delta < 0 then
		pulseFrame(_pulseDark, 0.60)
		local char = LocalPlayer.Character
		local pos  = char and char:FindFirstChild("HumanoidRootPart")
			and char.HumanoidRootPart.Position
		if pos then
			spawnWorldVFX(AssetConfig.Audio.VFX.MoralityFall, pos, nil)
		end
	end
end

local function onAchievementUnlocked(_)
	-- Screen-space radiance burst (not world-space)
	TweenService:Create(_achFlash, TWEEN_FLASH_IN,
		{ BackgroundTransparency = 0.55 }):Play()
	task.delay(0.25, function()
		TweenService:Create(_achFlash, TWEEN_FLASH_OUT,
			{ BackgroundTransparency = 1 }):Play()
	end)
end

local function onStaminaDepleted()
	flashFrame(_vignetteRed, 0.45, 0.1)
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function VFXController:KnitInit()
	buildScreenGui()
	buildPlayVFXEvent()
end

function VFXController:KnitStart()
	-- Combat hit sparks
	local combatService = Knit.GetService("CombatService")
	combatService.CombatHit:Connect(function(attackerUserId, hitPosition, weaponId)
		onCombatHit(attackerUserId, hitPosition, weaponId)
	end)

	-- Morality pulse (RemoteEvent, not Knit signal)
	local moralityRE = ReplicatedStorage
		:WaitForChild("RemoteEvents")
		:WaitForChild("MoralityChanged")
	moralityRE.OnClientEvent:Connect(function(payload)
		onMoralityChanged(payload)
	end)

	-- Achievement radiance
	local achievementService = Knit.GetService("AchievementService")
	achievementService.AchievementUnlocked:Connect(function(achConfig)
		onAchievementUnlocked(achConfig)
	end)

	-- Stamina depleted (StaminaService signal)
	local staminaService = Knit.GetService("StaminaService")
	if staminaService.StaminaDepleted then
		staminaService.StaminaDepleted:Connect(function()
			onStaminaDepleted()
		end)
	end

	-- PlayVFX BindableEvent
	_playVFXEvent.Event:Connect(function(payload)
		if type(payload) ~= "table" then return end
		local effectId = payload.effectId
		if not effectId then return end
		spawnWorldVFX(effectId, payload.position, payload.attachTo)
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function VFXController:playVFX(effectId, position, attachTo)
	spawnWorldVFX(effectId, position, attachTo)
end

function VFXController:flashStaminaDepleted()
	onStaminaDepleted()
end

function VFXController:flashMorality(delta)
	onMoralityChanged({ delta = delta })
end

return VFXController
