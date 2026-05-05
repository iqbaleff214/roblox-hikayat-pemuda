-- ModuleScript: ReplicatedStorage/Shared/Modules/ItemModule
-- Pure utility — no service dependencies. Safe to require from client or server.
-- All data comes from AssetConfig. Callers check nil returns.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local EQUIPPABLE_TYPES  = { Weapon = true, Kosmetik = true }
local CONSUMABLE_TYPES  = { Food = true, Drink = true }

local ItemModule = {}

-- Returns the full config entry for an item id, or nil if not found.
function ItemModule.getConfig(itemId)
	return AssetConfig.Items[itemId] or AssetConfig.Weapons[itemId]
end

-- Returns true if the item can be assigned to the hotbar and used as equipment.
function ItemModule.isEquippable(itemId)
	local cfg = ItemModule.getConfig(itemId)
	return cfg ~= nil and EQUIPPABLE_TYPES[cfg.type] == true
end

-- Returns true if using the item consumes it (food / drink).
function ItemModule.isConsumable(itemId)
	local cfg = ItemModule.getConfig(itemId)
	return cfg ~= nil and CONSUMABLE_TYPES[cfg.type] == true
end

-- Returns true if the item is a weapon (melee or ranged).
function ItemModule.isWeapon(itemId)
	return AssetConfig.Weapons[itemId] ~= nil
end

-- Returns true if the weapon fires a projectile.
function ItemModule.isRanged(itemId)
	local cfg = AssetConfig.Weapons[itemId]
	return cfg ~= nil and cfg.projectileSpeed ~= nil
end

-- Linear search through an inventory array: returns (index, entry) or (nil, nil).
function ItemModule.findInInventory(inventory, itemId)
	for i, entry in inventory do
		if entry.id == itemId then
			return i, entry
		end
	end
	return nil, nil
end

-- Returns total amount of itemId across the entire inventory array.
function ItemModule.countInInventory(inventory, itemId)
	local _, entry = ItemModule.findInInventory(inventory, itemId)
	return entry and entry.amount or 0
end

return ItemModule
