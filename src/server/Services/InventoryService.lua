-- ModuleScript: ServerScriptService/Server/Services/InventoryService
-- Manages player inventory and hotbar server-side.
-- All add/remove/use/drop operations go through this service.
-- No client script may modify inventory data directly.

local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Debris            = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local ItemModule = require(ReplicatedStorage:WaitForChild("Shared").Modules.ItemModule)

local PICKUP_LIFETIME = 60 -- seconds before a dropped item despawns

local InventoryService = Knit.CreateService {
	Name   = "InventoryService",
	Client = {
		SyncInventory = Knit.CreateSignal(), -- server → client: (inventory, hotbar)
	},

	_dataService    = nil,
	_staminaService = nil,
	_combatService  = nil, -- set lazily to avoid circular require at init
}

-- ── Private helpers ───────────────────────────────────────────────
local function syncToClient(self, player)
	local data = self._dataService:get(player)
	if not data then return end
	self.Client.SyncInventory:Fire(player, data.inventory, data.hotbar)
end

-- ── KnitInit ─────────────────────────────────────────────────────
function InventoryService:KnitInit()
end

-- ── KnitStart ────────────────────────────────────────────────────
function InventoryService:KnitStart()
	self._dataService    = Knit.GetService("DataService")
	self._staminaService = Knit.GetService("StaminaService")

	-- Sync inventory to client on join (after data loads)
	Players.PlayerAdded:Connect(function(player)
		local loaded = self._dataService:waitForLoad(player, 10)
		if loaded then
			syncToClient(self, player)
		end
	end)
end

-- ── Public API (called by other server Services) ──────────────────

-- Adds `amount` of `itemId` to the player's inventory.
-- Respects inventorySize cap. Returns true on success, false if full.
function InventoryService:addItem(player, itemId, amount)
	amount = amount or 1
	local data = self._dataService:get(player)
	if not data then return false, "not_loaded" end

	local inventory = data.inventory
	local idx, entry = ItemModule.findInInventory(inventory, itemId)

	if entry then
		entry.amount = entry.amount + amount
	else
		if #inventory >= data.inventorySize then
			return false, "full"
		end
		table.insert(inventory, { id = itemId, amount = amount })
	end

	syncToClient(self, player)
	return true
end

-- Removes `amount` of `itemId` from the player's inventory.
-- Returns true on success, false if insufficient.
function InventoryService:removeItem(player, itemId, amount)
	amount = amount or 1
	local data = self._dataService:get(player)
	if not data then return false, "not_loaded" end

	local inventory = data.inventory
	local idx, entry = ItemModule.findInInventory(inventory, itemId)
	if not entry or entry.amount < amount then
		return false, "insufficient"
	end

	entry.amount = entry.amount - amount
	if entry.amount <= 0 then
		table.remove(inventory, idx)
		-- Clear hotbar slots that reference this item
		for slot, id in data.hotbar do
			if id == itemId then
				data.hotbar[slot] = nil
			end
		end
	end

	syncToClient(self, player)
	return true
end

-- Returns true if the player has at least `amount` of `itemId`.
function InventoryService:hasItem(player, itemId, amount)
	amount = amount or 1
	local data = self._dataService:get(player)
	if not data then return false end
	return ItemModule.countInInventory(data.inventory, itemId) >= amount
end

-- ── Internal: use logic (also called by Client:UseItem) ───────────
function InventoryService:_useItem(player, itemId)
	local data = self._dataService:get(player)
	if not data then return false, "not_loaded" end

	local _, entry = ItemModule.findInInventory(data.inventory, itemId)
	if not entry then return false, "not_in_inventory" end

	local cfg = ItemModule.getConfig(itemId)
	if not cfg then return false, "invalid_item" end

	if ItemModule.isConsumable(itemId) then
		-- Restore stamina
		if cfg.staminaGain then
			self._staminaService:restore(player, cfg.staminaGain)
		end
		-- Consume one unit
		return self:removeItem(player, itemId, 1)

	elseif ItemModule.isWeapon(itemId) then
		-- Delegate to CombatService (lazy-require to avoid circular dep)
		if not self._combatService then
			self._combatService = Knit.GetService("CombatService")
		end
		return self._combatService:equip(player, itemId)

	else
		return false, "not_usable"
	end
end

-- ── Internal: drop logic ──────────────────────────────────────────
function InventoryService:_dropItem(player, itemId, amount)
	amount = amount or 1
	local data = self._dataService:get(player)
	if not data then return false, "not_loaded" end

	local ok, reason = self:removeItem(player, itemId, amount)
	if not ok then return false, reason end

	-- Spawn a world pickup Part near the player
	local character = player.Character
	local rootPart  = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return true end -- removed from inventory, no world drop

	local pickup = Instance.new("Part")
	pickup.Name      = "ItemPickup_" .. itemId
	pickup.Size      = Vector3.new(1, 1, 1)
	pickup.Anchored  = false
	pickup.CanCollide = true
	pickup.CFrame    = rootPart.CFrame * CFrame.new(
		math.random(-2, 2), 0.5, math.random(-2, 2)
	)

	-- Store pickup data as attributes so the pickup handler can read them
	pickup:SetAttribute("ItemId", itemId)
	pickup:SetAttribute("Amount", amount)
	pickup:SetAttribute("DroppedBy", player.UserId)
	pickup.Parent = workspace

	CollectionService:AddTag(pickup, "ItemPickup")
	Debris:AddItem(pickup, PICKUP_LIFETIME)

	-- Handle pickup by any player (proximity)
	pickup.Touched:Connect(function(hit)
		local toucher = Players:GetPlayerFromCharacter(hit.Parent)
		if toucher and pickup.Parent then
			local added = self:addItem(toucher, itemId, amount)
			if added then
				pickup:Destroy()
			end
		end
	end)

	return true
end

-- ── Internal: hotbar assignment ───────────────────────────────────
function InventoryService:_assignHotbar(player, slotIndex, itemId)
	local data = self._dataService:get(player)
	if not data then return false, "not_loaded" end

	if slotIndex < 1 or slotIndex > data.hotbarSize then
		return false, "invalid_slot"
	end

	-- itemId nil = clear slot; otherwise must exist in inventory
	if itemId ~= nil then
		local _, entry = ItemModule.findInInventory(data.inventory, itemId)
		if not entry then return false, "not_in_inventory" end
	end

	data.hotbar[slotIndex] = itemId
	syncToClient(self, player)
	return true
end

-- ── Client-facing ─────────────────────────────────────────────────

function InventoryService.Client:UseItem(player, itemId)
	return self.Server:_useItem(player, itemId)
end

function InventoryService.Client:DropItem(player, itemId, amount)
	return self.Server:_dropItem(player, itemId, amount)
end

function InventoryService.Client:AssignHotbar(player, slotIndex, itemId)
	return self.Server:_assignHotbar(player, slotIndex, itemId)
end

return InventoryService
