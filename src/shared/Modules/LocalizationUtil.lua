-- ModuleScript: ReplicatedStorage/Shared/Modules/LocalizationUtil
-- Wraps LocalizationService for consistent string lookup across client and server.
-- Client: uses the player's locale. Server: falls back to "id" (Indonesian).
-- Usage everywhere: local L = require(LocalizationUtil).get

local LocalizationService = game:GetService("LocalizationService")
local RunService          = game:GetService("RunService")

local LocalizationUtil = {}

local _translator = nil

local function resolveTranslator()
	if _translator then
		return _translator
	end

	if RunService:IsClient() then
		local ok, result = pcall(function()
			return LocalizationService:GetTranslatorForLocalPlayer()
		end)
		if ok and result then
			_translator = result
			return _translator
		end
	end

	-- Server fallback or client fallback: Indonesian
	local ok, result = pcall(function()
		return LocalizationService:GetTranslatorForLocale("id")
	end)
	if ok and result then
		_translator = result
	end

	return _translator
end

-- Accepts a numeric LocalizationTable asset ID.
-- Call once per Place if a custom table is needed; no-op if tableAssetId is 0 or nil.
-- In practice all 7 Places share the same table, so this is optional.
function LocalizationUtil.init(tableAssetId)
	if not tableAssetId or tableAssetId == 0 then return end
	-- LocalizationTable assets are loaded by inserting them into
	-- LocalizationService. This is typically done via Studio's
	-- Localization editor; this hook exists for runtime loading if needed.
end

-- Main lookup. Returns the raw key string if translation is missing,
-- so missing entries are immediately visible during development.
function LocalizationUtil.get(key, substitutions)
	local t = resolveTranslator()
	if not t then
		return key
	end

	local ok, result = pcall(function()
		if substitutions then
			return t:FormatByKey(key, substitutions)
		else
			return t:FormatByKey(key)
		end
	end)

	if ok and result and result ~= "" then
		return result
	end
	return key
end

-- Returns the active locale string ("id", "en-us", etc.)
function LocalizationUtil.getLocale()
	if RunService:IsClient() then
		local ok, locale = pcall(function()
			return LocalizationService.RobloxLocaleId
		end)
		if ok and locale then
			return locale
		end
	end
	return "id"
end

return LocalizationUtil
