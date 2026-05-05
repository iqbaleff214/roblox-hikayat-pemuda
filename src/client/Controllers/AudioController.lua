-- LocalScript: StarterPlayerScripts/Client/Controllers/AudioController
-- Manages BGM (A/B crossfade), ambient loop, and SFX playback.
-- Zone change → new BGM/ambient via 2s crossfade.
-- Day (5–19) plays zone bgmId; Night plays AssetConfig.Audio.BGM.Night.
-- Exposes PlaySFX BindableEvent in ReplicatedStorage.Shared for cross-script calls.
-- Also exposes public Knit API: AudioController:playSFX(sfxId, position?)

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local SoundService  = game:GetService("SoundService")
local Workspace     = game:GetService("Workspace")
local Debris        = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local AudioController = Knit.CreateController { Name = "AudioController" }

-- ── Constants ─────────────────────────────────────────────────────

local BGM_VOLUME     = 0.5
local AMBIENT_VOLUME = 0.3
local CROSSFADE_TIME = 2
local AMBIENT_FADE   = 1
local DAY_START      = AssetConfig.DayNight and AssetConfig.DayNight.DawnHour or 5
local DAY_END        = AssetConfig.DayNight and AssetConfig.DayNight.DuskHour or 19

local TWEEN_FADE_OUT = TweenInfo.new(CROSSFADE_TIME, Enum.EasingStyle.Linear)
local TWEEN_FADE_IN  = TweenInfo.new(CROSSFADE_TIME, Enum.EasingStyle.Linear)
local TWEEN_AMB_OUT  = TweenInfo.new(AMBIENT_FADE, Enum.EasingStyle.Linear)
local TWEEN_AMB_IN   = TweenInfo.new(AMBIENT_FADE, Enum.EasingStyle.Linear)

-- ── Sound objects ─────────────────────────────────────────────────

local _bgmA    = nil
local _bgmB    = nil
local _ambA    = nil
local _ambB    = nil
local _activeBgm = "A"  -- which slot is currently playing BGM
local _activeAmb = "A"  -- which slot is currently playing ambient

local _currentBgmId  = ""
local _currentAmbId  = ""
local _isDay         = true

-- ── BindableEvent: PlaySFX ─────────────────────────────────────────
-- Stored in ReplicatedStorage.Shared so any LocalScript can fire it.
-- Payload: { sfxId: string, position?: Vector3 }

local _playSFXEvent = nil

-- ── Internal: Sound builders ──────────────────────────────────────

local function buildSounds()
	_bgmA          = Instance.new("Sound")
	_bgmA.Name     = "BGM_A"
	_bgmA.Looped   = true
	_bgmA.Volume   = BGM_VOLUME
	_bgmA.RollOffMode = Enum.RollOffMode.InverseTapered
	_bgmA.Parent   = SoundService

	_bgmB          = Instance.new("Sound")
	_bgmB.Name     = "BGM_B"
	_bgmB.Looped   = true
	_bgmB.Volume   = 0
	_bgmB.RollOffMode = Enum.RollOffMode.InverseTapered
	_bgmB.Parent   = SoundService

	_ambA          = Instance.new("Sound")
	_ambA.Name     = "Ambient_A"
	_ambA.Looped   = true
	_ambA.Volume   = AMBIENT_VOLUME
	_ambA.RollOffMode = Enum.RollOffMode.InverseTapered
	_ambA.Parent   = SoundService

	_ambB          = Instance.new("Sound")
	_ambB.Name     = "Ambient_B"
	_ambB.Looped   = true
	_ambB.Volume   = 0
	_ambB.RollOffMode = Enum.RollOffMode.InverseTapered
	_ambB.Parent   = SoundService
end

local function buildPlaySFXEvent()
	local shared = ReplicatedStorage:WaitForChild("Shared")
	local existing = shared:FindFirstChild("PlaySFX")
	if existing and existing:IsA("BindableEvent") then
		_playSFXEvent = existing
		return
	end
	_playSFXEvent      = Instance.new("BindableEvent")
	_playSFXEvent.Name = "PlaySFX"
	_playSFXEvent.Parent = shared
end

-- ── BGM crossfade ─────────────────────────────────────────────────

local function activeBgmSound()
	return _activeBgm == "A" and _bgmA or _bgmB
end

local function inactiveBgmSound()
	return _activeBgm == "A" and _bgmB or _bgmA
end

local function crossfadeBGM(newSoundId)
	if newSoundId == _currentBgmId then return end
	_currentBgmId = newSoundId

	local outgoing = activeBgmSound()
	local incoming = inactiveBgmSound()

	if newSoundId == "" then
		TweenService:Create(outgoing, TWEEN_FADE_OUT, { Volume = 0 }):Play()
		task.delay(CROSSFADE_TIME, function()
			outgoing:Stop()
		end)
		return
	end

	incoming.SoundId = newSoundId
	incoming.Volume  = 0
	incoming:Play()

	TweenService:Create(outgoing, TWEEN_FADE_OUT, { Volume = 0 }):Play()
	TweenService:Create(incoming, TWEEN_FADE_IN,  { Volume = BGM_VOLUME }):Play()

	task.delay(CROSSFADE_TIME, function()
		outgoing:Stop()
		outgoing.Volume = 0
		_activeBgm = _activeBgm == "A" and "B" or "A"
	end)
end

-- ── Ambient crossfade ──────────────────────────────────────────────

local function activeAmbSound()
	return _activeAmb == "A" and _ambA or _ambB
end

local function inactiveAmbSound()
	return _activeAmb == "A" and _ambB or _ambA
end

local function crossfadeAmbient(newSoundId)
	if newSoundId == _currentAmbId then return end
	_currentAmbId = newSoundId

	local outgoing = activeAmbSound()
	local incoming = inactiveAmbSound()

	if newSoundId == "" then
		TweenService:Create(outgoing, TWEEN_AMB_OUT, { Volume = 0 }):Play()
		task.delay(AMBIENT_FADE, function()
			outgoing:Stop()
		end)
		return
	end

	incoming.SoundId = newSoundId
	incoming.Volume  = 0
	incoming:Play()

	TweenService:Create(outgoing, TWEEN_AMB_OUT, { Volume = 0 }):Play()
	TweenService:Create(incoming, TWEEN_AMB_IN,  { Volume = AMBIENT_VOLUME }):Play()

	task.delay(AMBIENT_FADE, function()
		outgoing:Stop()
		outgoing.Volume = 0
		_activeAmb = _activeAmb == "A" and "B" or "A"
	end)
end

-- ── BGM selection (zone + day/night) ──────────────────────────────

local _currentZoneCfg = nil

local function updateBGM()
	if not _currentZoneCfg then return end

	local bgmId
	if _isDay then
		bgmId = _currentZoneCfg.bgmId or ""
	else
		bgmId = AssetConfig.Audio.BGM.Night or ""
	end

	crossfadeBGM(bgmId)
end

local function onZoneChanged(_, zoneCfg)
	_currentZoneCfg = zoneCfg

	local ambId = (zoneCfg and zoneCfg.ambientSound) or ""
	crossfadeAmbient(ambId)

	updateBGM()
end

local function onGameTimeUpdate(gameHour)
	local wasDay = _isDay
	_isDay = gameHour >= DAY_START and gameHour < DAY_END
	if _isDay ~= wasDay then
		updateBGM()
	end
end

-- ── SFX playback ──────────────────────────────────────────────────

local function playSFXAtPosition(soundId, position)
	local part            = Instance.new("Part")
	part.Name             = "SFX_Part"
	part.Size             = Vector3.new(0.1, 0.1, 0.1)
	part.Position         = position
	part.Anchored         = true
	part.CanCollide       = false
	part.Transparency     = 1
	part.CastShadow       = false
	part.Parent           = Workspace

	local snd             = Instance.new("Sound")
	snd.SoundId           = soundId
	snd.RollOffMaxDistance = 60
	snd.RollOffMinDistance = 2
	snd.Volume            = 0.8
	snd.Parent            = part
	snd:Play()

	snd.Ended:Connect(function()
		part:Destroy()
	end)

	-- Safety cleanup in case Ended never fires (e.g., rbxassetid://0)
	Debris:AddItem(part, 10)
end

local function playSFXGlobal(soundId)
	local snd         = Instance.new("Sound")
	snd.SoundId       = soundId
	snd.Volume        = 0.8
	snd.RollOffMode   = Enum.RollOffMode.InverseTapered
	snd.Parent        = SoundService
	snd:Play()

	snd.Ended:Connect(function()
		snd:Destroy()
	end)

	Debris:AddItem(snd, 10)
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function AudioController:KnitInit()
	buildSounds()
	buildPlaySFXEvent()
end

function AudioController:KnitStart()
	local zoneService     = Knit.GetService("ZoneService")
	local dayNightService = Knit.GetService("DayNightService")

	zoneService.ZoneChanged:Connect(function(zoneId, zoneCfg)
		onZoneChanged(zoneId, zoneCfg)
	end)

	dayNightService.GameTimeUpdate:Connect(function(gameHour)
		onGameTimeUpdate(gameHour)
	end)

	-- Seed initial zone from player data
	local dataService = Knit.GetService("DataService")
	task.spawn(function()
		local ok, data = pcall(function()
			return dataService:GetPlayerData()
		end)
		if ok and data and data.lastZone then
			local zoneCfg = AssetConfig.getZone(data.lastZone)
			if zoneCfg then
				onZoneChanged(data.lastZone, zoneCfg)
			end
		end
	end)

	-- Wire BindableEvent
	_playSFXEvent.Event:Connect(function(payload)
		if type(payload) ~= "table" then return end
		local soundId = payload.sfxId
		if not soundId or soundId == "" then return end
		if payload.position then
			playSFXAtPosition(soundId, payload.position)
		else
			playSFXGlobal(soundId)
		end
	end)
end

-- ── Public API ────────────────────────────────────────────────────

function AudioController:playSFX(sfxId, position)
	if not sfxId or sfxId == "" then return end
	if position then
		playSFXAtPosition(sfxId, position)
	else
		playSFXGlobal(sfxId)
	end
end

function AudioController:playBGM(bgmId)
	crossfadeBGM(bgmId or "")
end

function AudioController:stopBGM()
	crossfadeBGM("")
end

return AudioController
