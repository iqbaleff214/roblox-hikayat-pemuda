-- ModuleScript: StarterPlayerScripts/Client/Controllers/InventoryController
-- Maintains a local cache of the player's inventory and hotbar.
-- Other client modules read from this cache — no direct server queries needed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

local InventoryController = Knit.CreateController {
	Name = "InventoryController",

	-- Local cache (updated on every SyncInventory signal from server)
	_inventory = {},  -- { { id, amount } }
	_hotbar    = {},  -- { [slotIndex] = itemId }

	-- Services (set in KnitStart)
	_inventoryService = nil,
}

-- ── KnitInit ─────────────────────────────────────────────────────
function InventoryController:KnitInit()
end

-- ── KnitStart ────────────────────────────────────────────────────
function InventoryController:KnitStart()
	self._inventoryService = Knit.GetService("InventoryService")

	-- Listen to server sync events
	self._inventoryService.SyncInventory:Connect(function(inventory, hotbar)
		self._inventory = inventory or {}
		self._hotbar    = hotbar    or {}
	end)
end

-- ── Public API (used by HotbarController, CombatController, GUIs) ─

-- Returns the current local inventory array.
function InventoryController:getInventory()
	return self._inventory
end

-- Returns the current local hotbar table { [slot] = itemId }.
function InventoryController:getHotbar()
	return self._hotbar
end

-- Returns the itemId in a given hotbar slot (1-indexed), or nil.
function InventoryController:getHotbarSlot(slotIndex)
	return self._hotbar[slotIndex]
end

-- Returns total amount of `itemId` in local inventory.
function InventoryController:count(itemId)
	for _, entry in self._inventory do
		if entry.id == itemId then return entry.amount end
	end
	return 0
end

-- Fires UseItem RF to server. Returns (ok, reason).
function InventoryController:useItem(itemId)
	return self._inventoryService:UseItem(itemId)
end

-- Fires DropItem RF to server.
function InventoryController:dropItem(itemId, amount)
	return self._inventoryService:DropItem(itemId, amount or 1)
end

-- Fires AssignHotbar RF to server. Updates local cache optimistically.
function InventoryController:assignHotbar(slotIndex, itemId)
	self._hotbar[slotIndex] = itemId  -- optimistic local update
	return self._inventoryService:AssignHotbar(slotIndex, itemId)
end

return InventoryController
