-- ModuleScript: StarterPlayerScripts/Client/Controllers/HotbarController
-- Handles hotbar input (keyboard 1-8, F key, mobile tap).
-- Tracks selected slot and equipped weapon. Fires signals for HUD to react.

local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)

-- Slot-select key bindings (Enum.KeyCode → slot index)
local SLOT_KEYS = {
	[Enum.KeyCode.One]   = 1,
	[Enum.KeyCode.Two]   = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four]  = 4,
	[Enum.KeyCode.Five]  = 5,
	[Enum.KeyCode.Six]   = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
}

local HotbarController = Knit.CreateController {
	Name = "HotbarController",

	_inventoryController = nil,
	_combatController    = nil,  -- lazy ref (set in KnitStart)
	_dataService         = nil,

	_selectedSlot  = nil,  -- currently highlighted slot (number | nil)
	_hotbarSize    = 4,    -- updated on join and on HotbarUpgrade

	-- BindableEvent for mobile HUD buttons → this controller
	-- HUD creates the buttons; buttons fire this event with slotIndex.
	-- Connect in TASK-080 (HUD implementation).
	HotbarSlotPressed = Instance.new("BindableEvent"),

	-- BindableEvent this controller fires when selected slot changes.
	-- HotbarGui listens to update visual highlight.
	ActiveSlotChanged = Instance.new("BindableEvent"),
}

-- ── KnitInit ─────────────────────────────────────────────────────
function HotbarController:KnitInit()
end

-- ── KnitStart ────────────────────────────────────────────────────
function HotbarController:KnitStart()
	self._inventoryController = Knit.GetController("InventoryController")
	self._dataService         = Knit.GetService("DataService")

	-- Populate hotbar size from player data
	self._dataService:GetPlayerData():andThen(function(data)
		if data then
			self._hotbarSize = data.hotbarSize or 4
		end
	end)

	-- Listen for server-driven hotbar upgrades
	local combatService = Knit.GetService("CombatService")
	combatService.WeaponEquipped:Connect(function(weaponId)
		-- Notify CombatController (via BindableEvent) — avoids circular require
		-- CombatController connects to this in its own KnitStart
	end)

	-- Mobile: HUD buttons fire HotbarSlotPressed
	self.HotbarSlotPressed.Event:Connect(function(slotIndex)
		self:_activateSlot(slotIndex)
	end)

	-- Desktop: keyboard 1-8
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		local slot = SLOT_KEYS[input.KeyCode]
		if slot then
			if self._selectedSlot == slot then
				-- Same key pressed twice: use the item in this slot
				self:_useSlot(slot)
			else
				self:_selectSlot(slot)
			end
			return
		end

		-- F key: use currently selected slot
		if input.KeyCode == Enum.KeyCode.F and self._selectedSlot then
			self:_useSlot(self._selectedSlot)
		end
	end)

	-- HotbarUpgrade signal from InventoryService (upgrade slot count)
	local inventoryService = Knit.GetService("InventoryService")
	inventoryService.SyncInventory:Connect(function(_, hotbar)
		-- hotbarSize is embedded in data; re-fetch on next data sync
		-- (full hotbar resize handled via DataService.GetPlayerData)
	end)
end

-- ── Private ───────────────────────────────────────────────────────
function HotbarController:_selectSlot(slotIndex)
	if slotIndex < 1 or slotIndex > self._hotbarSize then return end
	self._selectedSlot = slotIndex
	self.ActiveSlotChanged:Fire(slotIndex)
end

function HotbarController:_useSlot(slotIndex)
	if slotIndex < 1 or slotIndex > self._hotbarSize then return end
	local itemId = self._inventoryController:getHotbarSlot(slotIndex)
	if not itemId then return end
	self._inventoryController:useItem(itemId)
end

function HotbarController:_activateSlot(slotIndex)
	if self._selectedSlot == slotIndex then
		self:_useSlot(slotIndex)
	else
		self:_selectSlot(slotIndex)
	end
end

-- ── Public API ────────────────────────────────────────────────────

-- Returns the currently selected slot index (may be nil).
function HotbarController:getSelectedSlot()
	return self._selectedSlot
end

-- Returns the current hotbar size (max unlocked slots).
function HotbarController:getHotbarSize()
	return self._hotbarSize
end

-- Called by server HotbarUpgrade signal to expand slot count.
function HotbarController:upgradeHotbar(newSize)
	self._hotbarSize = math.clamp(newSize, 4, 8)
	self.ActiveSlotChanged:Fire(self._selectedSlot)
end

-- Called by mobile HUD buttons (plugs into HotbarSlotPressed BindableEvent).
function HotbarController:onMobileSlotTapped(slotIndex)
	self.HotbarSlotPressed:Fire(slotIndex)
end

return HotbarController
