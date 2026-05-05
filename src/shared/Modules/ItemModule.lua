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
-- enhanced param:
--   nil  → first match regardless of enhanced state (default, backward-compatible)
--   true → only enhanced entries
--   false → only non-enhanced entries (entry.enhanced is nil or false)
function ItemModule.findInInventory(inventory, itemId, enhanced)
	for i, entry in inventory do
		if entry.id == itemId then
			if enhanced == nil then
				return i, entry
			end
			local entryEnhanced = entry.enhanced == true
			if entryEnhanced == (enhanced == true) then
				return i, entry
			end
		end
	end
	return nil, nil
end

-- Returns total amount of itemId in the inventory.
-- enhanced=nil counts all stacks; true/false counts only matching.
function ItemModule.countInInventory(inventory, itemId, enhanced)
	local total = 0
	for _, entry in inventory do
		if entry.id == itemId then
			if enhanced == nil then
				total += entry.amount
			else
				local entryEnhanced = entry.enhanced == true
				if entryEnhanced == (enhanced == true) then
					total += entry.amount
				end
			end
		end
	end
	return total
end

return ItemModule
