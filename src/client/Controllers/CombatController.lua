-- ModuleScript: StarterPlayerScripts/Client/Controllers/CombatController
-- Handles client-side combat input: fires AttackRequest to server,
-- plays weapon animations locally (client-side prediction for feel),
-- and enforces cooldown display state.

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)

local LocalPlayer = Players.LocalPlayer

local CombatController = Knit.CreateController {
	Name = "CombatController",

	_combatService       = nil,
	_hotbarController    = nil,
	_inventoryController = nil,

	_equippedWeaponId  = nil,        -- synced from CombatService.WeaponEquipped
	_lastAttackTick    = 0,          -- client-side cooldown tracker (display only)
	_onCooldown        = false,

	-- Preloaded animation tracks: { [weaponId] = AnimationTrack }
	_animTracks = {},

	-- BindableEvent for HUD to show/hide cooldown overlay
	CooldownChanged = Instance.new("BindableEvent"), -- fires (onCooldown: bool, remaining: number)
}

-- ── Private: load animation for a weapon ─────────────────────────
function CombatController:_loadAnimation(weaponId)
	if self._animTracks[weaponId] then return self._animTracks[weaponId] end

	local weaponCfg = AssetConfig.Weapons[weaponId]
	if not weaponCfg or not weaponCfg.animationId then return nil end

	local char     = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local anim = Instance.new("Animation")
	anim.AnimationId = weaponCfg.animationId

	local ok, track = pcall(function()
		return humanoid:LoadAnimation(anim)
	end)

	if ok and track then
		self._animTracks[weaponId] = track
		return track
	end
	return nil
end

-- Reload all animation tracks when the character respawns (humanoid changes).
function CombatController:_onCharacterAdded(character)
	self._animTracks = {}  -- invalidate cached tracks; they belong to old humanoid
end

-- ── Private: get aim direction ────────────────────────────────────
-- Returns a normalised Vector3 from the player's camera direction.
-- For mobile, falls back to the character's look direction.
local function getAimDirection()
	local camera = workspace.CurrentCamera
	if camera then
		return camera.CFrame.LookVector
	end
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
end

-- ── Private: perform attack ───────────────────────────────────────
function CombatController:_attack()
	local weaponId = self._equippedWeaponId
	if not weaponId then return end

	local weaponCfg = AssetConfig.Weapons[weaponId]
	if not weaponCfg then return end

	-- Client-side cooldown gate (visual feedback only; server enforces too)
	local now = tick()
	if self._onCooldown or (now - self._lastAttackTick) < weaponCfg.cooldown then
		return
	end

	-- Fire request to server
	local direction = getAimDirection()
	self._combatService.AttackRequest:Fire(weaponId, direction)

	-- Play animation immediately (client-side prediction)
	local track = self:_loadAnimation(weaponId)
	if track then
		track:Play()
	end

	-- Start client cooldown display
	self._lastAttackTick = now
	self._onCooldown     = true
	self.CooldownChanged:Fire(true, weaponCfg.cooldown)

	task.delay(weaponCfg.cooldown, function()
		self._onCooldown = false
		self.CooldownChanged:Fire(false, 0)
	end)
end

-- ── KnitInit ─────────────────────────────────────────────────────
function CombatController:KnitInit()
	-- Listen for character respawns to invalidate animation cache
	LocalPlayer.CharacterAdded:Connect(function(character)
		self:_onCharacterAdded(character)
	end)
end

-- ── KnitStart ────────────────────────────────────────────────────
function CombatController:KnitStart()
	self._combatService       = Knit.GetService("CombatService")
	self._hotbarController    = Knit.GetController("HotbarController")
	self._inventoryController = Knit.GetController("InventoryController")

	-- Track equipped weapon from server confirmations
	self._combatService.WeaponEquipped:Connect(function(weaponId)
		self._equippedWeaponId = weaponId
		-- Preload animation for faster first strike
		if weaponId then
			task.spawn(function()
				self:_loadAnimation(weaponId)
			end)
		end
	end)

	-- Desktop: left mouse button
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:_attack()
		end
	end)

	-- Mobile: screen tap
	UserInputService.TouchTap:Connect(function(_positions, gameProcessed)
		if gameProcessed then return end
		self:_attack()
	end)
end

return CombatController
