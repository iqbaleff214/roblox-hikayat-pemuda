-- ModuleScript: ServerScriptService/Server/Services/DayNightService
-- Runs the compressed in-game day/night cycle on the server.
-- Advances Lighting.ClockTime each second; tweens Brightness and Ambient at dawn/dusk.
-- Broadcasts GameTimeUpdate to all clients every BroadcastIntervalSec seconds.

local Lighting      = game:GetService("Lighting")
local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local DayNightService = Knit.CreateService {
	Name   = "DayNightService",
	Client = {
		GameTimeUpdate = Knit.CreateSignal(), -- server → client: (gameHour: number)
	},
}

-- ── Constants derived from config ────────────────────────────────

local CFG = AssetConfig.DayNight
local HOURS_PER_SECOND = 24 / (CFG.RealMinutesPerDay * 60)

local TWEEN_INFO = TweenInfo.new(10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- ── Lighting transition helpers ───────────────────────────────────

-- Returns 0 (night) to 1 (day) blend based on hour.
-- Transitions happen over a 1-hour window around dawn and dusk.
local function daylightBlend(hour)
	local dawn = CFG.DawnHour
	local dusk = CFG.DuskHour
	if hour >= dawn and hour <= dusk then
		return 1
	elseif hour < dawn then
		return math.clamp((hour - (dawn - 1)) / 1, 0, 1)
	else
		return math.clamp(1 - (hour - dusk) / 1, 0, 1)
	end
end

local function lerpColor(c0, c1, t)
	return Color3.new(
		c0.R + (c1.R - c0.R) * t,
		c0.G + (c1.G - c0.G) * t,
		c0.B + (c1.B - c0.B) * t
	)
end

local _lastBlend    = -1
local _activeTween  = nil

local function applyLighting(hour)
	local blend = daylightBlend(hour)

	-- Only tween when blend changes noticeably (avoids constant tweening)
	if math.abs(blend - _lastBlend) < 0.01 then return end
	_lastBlend = blend

	if _activeTween then
		_activeTween:Cancel()
	end

	local targetBrightness = CFG.BrightnessNight + (CFG.BrightnessDay - CFG.BrightnessNight) * blend
	local targetAmbient    = lerpColor(CFG.AmbientNight,        CFG.AmbientDay,        blend)
	local targetOutdoor    = lerpColor(CFG.OutdoorAmbientNight,  CFG.OutdoorAmbientDay, blend)

	_activeTween = TweenService:Create(Lighting, TWEEN_INFO, {
		Brightness      = targetBrightness,
		Ambient         = targetAmbient,
		OutdoorAmbient  = targetOutdoor,
	})
	_activeTween:Play()
end

-- ── KnitInit / KnitStart ──────────────────────────────────────────

function DayNightService:KnitInit()
end

function DayNightService:KnitStart()
	local broadcastInterval = CFG.BroadcastIntervalSec
	local lastBroadcast     = 0

	task.spawn(function()
		while true do
			task.wait(1)

			-- Advance game clock
			local newTime = (Lighting.ClockTime + HOURS_PER_SECOND) % 24
			Lighting.ClockTime = newTime

			applyLighting(newTime)

			-- Broadcast to clients periodically
			local now = tick()
			if (now - lastBroadcast) >= broadcastInterval then
				lastBroadcast = now
				local gameHour = math.floor(newTime)
				self.Client.GameTimeUpdate:FireAll(gameHour)
			end
		end
	end)
end

return DayNightService
