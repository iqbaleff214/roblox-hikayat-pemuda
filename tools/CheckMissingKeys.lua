--[[
    tools/CheckMissingKeys.lua
    Run this in Roblox Studio's Command Bar (or as a Plugin Script) to detect
    any nameKey / descKey / labelKey values in AssetConfig that are missing
    from the LocalizationTable.

    Usage (Studio Command Bar):
        require(game.ReplicatedStorage.Shared.Config.AssetConfig)  -- warm the module
        loadstring(game.ServerScriptService.tools.CheckMissingKeys.Source)()

    Or run offline via Selene / roblox-ts toolchain by adapting the require path.
--]]

local AssetConfig = require(game:GetService("ReplicatedStorage")
    :WaitForChild("Shared")
    :WaitForChild("Config")
    :WaitForChild("AssetConfig"))

-- Collect all keys referenced in AssetConfig
local allKeys = {}
local function addKey(k)
    if type(k) == "string" and k ~= "" then
        allKeys[k] = true
    end
end

-- Items
for _, cfg in AssetConfig.Items do
    addKey(cfg.nameKey)
    addKey(cfg.descKey)
end

-- Weapons
for _, cfg in AssetConfig.Weapons do
    addKey(cfg.nameKey)
end

-- Shops
for _, cfg in AssetConfig.Shops do
    addKey(cfg.nameKey)
end

-- NPCs
for _, cfg in AssetConfig.NPCs do
    addKey(cfg.nameKey)
end

-- Quests
for _, cfg in AssetConfig.Quests do
    addKey(cfg.nameKey)
    addKey(cfg.descKey)
    if cfg.objectives then
        for _, obj in cfg.objectives do
            addKey(obj.descKey)
        end
    end
end

-- Tasks
if AssetConfig.Tasks then
    for _, cfg in AssetConfig.Tasks do
        addKey(cfg.nameKey)
        addKey(cfg.descKey)
    end
end

-- Zones
for _, cfg in AssetConfig.Zones do
    addKey(cfg.nameKey)
end

-- Places
for _, cfg in AssetConfig.Places do
    addKey(cfg.nameKey)
end

-- Relationships
for relType, cfg in AssetConfig.Relationships do
    addKey(cfg.nameKey)
    _ = relType  -- suppress unused
end

-- Morality tiers
for _, tier in AssetConfig.Morality.Tiers do
    addKey(tier.labelKey)
end

-- Achievements
for _, cfg in AssetConfig.Achievements do
    addKey(cfg.nameKey)
    addKey(cfg.descKey)
end

-- Events (festival)
for _, cfg in AssetConfig.Events do
    addKey(cfg.nameKey)
    if cfg.currency then
        addKey(cfg.currency.nameKey)
    end
end

-- WorldEvents
for _, cfg in AssetConfig.WorldEvents do
    addKey(cfg.nameKey)
end

-- Audio (no string keys for localization)

-- Build sorted list
local keyList = {}
for k in allKeys do
    keyList[#keyList + 1] = k
end
table.sort(keyList)

-- Try to fetch LocalizationTable entries
local locTable = nil
pcall(function()
    locTable = game:GetService("LocalizationService")
        :GetTableEntries(game:FindFirstChildOfClass("LocalizationTable"))
end)

local presentKeys = {}
if locTable then
    for _, entry in locTable do
        if entry.Key then
            presentKeys[entry.Key] = true
        end
    end
end

-- Report
local missing = {}
for _, k in keyList do
    if not presentKeys[k] then
        missing[#missing + 1] = k
    end
end

if #missing == 0 then
    print("[CheckMissingKeys] All " .. #keyList .. " keys are present in LocalizationTable.")
else
    warn("[CheckMissingKeys] " .. #missing .. " key(s) missing from LocalizationTable:")
    for _, k in missing do
        warn("  MISSING: " .. k)
    end
end

return missing
