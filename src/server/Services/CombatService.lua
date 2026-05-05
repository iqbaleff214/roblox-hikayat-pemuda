-- ModuleScript: ServerScriptService/Server/Services/CombatService
-- Handles weapon equip/unequip, hitbox detection, damage, cooldown, and death logic.
-- Client fires AttackRequest; server validates everything — no client damage authority.

local Players           = game:GetService("Players")
local Debris            = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit       = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local AssetConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.AssetConfig)
local ItemModule  = require(ReplicatedStorage:WaitForChild("Shared").Modules.ItemModule)

-- Time (seconds) a client's direction vector is trusted after firing AttackRequest
local MAX_DIRECTION_AGE = 0.5
local PROJECTILE_LIFETIME = 5

local CombatService = Knit.CreateService {
	Name   = "CombatService",
	Client = {
		-- client → server (one-way): player requests to attack
		AttackRequest   = Knit.CreateSignal(), -- (weaponId: string, direction: Vector3)
		-- server → client: hit effects
		CombatHit       = Knit.CreateSignal(), -- (attackerUserId, hitPosition, weaponId)
		WeaponEquipped  = Knit.CreateSignal(), -- (weaponId: string | nil)
		StatusEffectApply = Knit.CreateSignal(), -- (targetUserId, effectType, duration)
		-- server → client: rejection feedback
		StaminaTooLow   = Knit.CreateSignal(), -- ()
		AttackRejected  = Knit.CreateSignal(), -- (reason: string)
	},

	_dataService     = nil,
	_staminaService  = nil,
	_inventoryService = nil,

	-- { [userId] = { [weaponId] = lastAttackTick } }
	_cooldowns = {},
	-- { [userId] = Humanoid.Died connection }
	_deathConns = {},
}

-- ── Private helpers ───────────────────────────────────────────────
local function getCharacter(player)
	return player.Character
end

local function getRootPart(player)
	local char = getCharacter(player)
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
	local char = getCharacter(player)
	return char and char:FindFirstChildOfClass("Humanoid")
end

-- Collect unique humanoids within radius of origin, excluding the attacker's character.
local function getHumanoidInRadius(origin, radius, excludeCharacter)
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = { excludeCharacter }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local parts = workspace:GetPartBoundsInRadius(origin, radius, params)
	local seen  = {}
	local results = {}

	for _, part in parts do
		local char     = part.Parent
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid and not seen[humanoid] and humanoid.Health > 0 then
			seen[humanoid] = true
			table.insert(results, { humanoid = humanoid, character = char })
		end
	end

	return results
end

-- Returns true if the character belongs to an NPC (not a player).
local function isNPCCharacter(character)
	return character:GetAttribute("NPCId") ~= nil
end

-- Returns true if the NPC is of enemy type (hostile). Innocent NPCs trigger morality penalty.
local function isEnemyNPC(character)
	local npcId = character:GetAttribute("NPCId")
	if not npcId then return false end
	local cfg = AssetConfig.NPCs[npcId]
	return cfg and cfg.npcType == "Enemy"
end

-- ── Melee attack ──────────────────────────────────────────────────
function CombatService:_meleeAttack(player, weapon)
	local rootPart  = getRootPart(player)
	local character = getCharacter(player)
	if not rootPart or not character then return end

	local data     = self._dataService:get(player)
	local morality = data and data.morality or 50

	local targets = getHumanoidInRadius(rootPart.Position, weapon.range, character)

	for _, target in targets do
		local damage = weapon.damage

		-- Morality bonus (e.g. Keris at 90+ morality)
		if weapon.moralityBonus and morality >= weapon.moralityBonus.minMorality then
			damage = damage * weapon.moralityBonus.damageMultiplier
		end

		target.humanoid:TakeDamage(damage)

		-- Morality penalty for hitting innocent NPCs
		if isNPCCharacter(target.character) and not isEnemyNPC(target.character) then
			-- MoralityService.apply(player, -15)  -- wired in Phase 5 (TASK-050)
			if data then
				data.morality = math.max(0, morality - 15)
				-- Broadcast morality change once Phase 5 is wired
			end
		end

		-- Broadcast hit VFX/SFX to all clients near the impact
		self.Client.CombatHit:FireAll(player.UserId, target.character.HumanoidRootPart.Position, weapon.id)
	end
end

-- ── Ranged attack ─────────────────────────────────────────────────
function CombatService:_rangedAttack(player, weapon, direction)
	local rootPart  = getRootPart(player)
	local character = getCharacter(player)
	if not rootPart or not character then return end

	local spawnCFrame = rootPart.CFrame * CFrame.new(0, 0, -2) -- spawn in front

	local projectile = Instance.new("Part")
	projectile.Name          = "Projectile"
	projectile.Size          = Vector3.new(0.4, 0.4, 0.4)
	projectile.Shape         = Enum.PartType.Ball
	projectile.Material      = Enum.Material.Neon
	projectile.BrickColor    = BrickColor.new("Bright yellow")
	projectile.CanCollide    = false
	projectile.Anchored      = false
	projectile.Massless      = true
	projectile.CastShadow    = false
	projectile.CFrame        = spawnCFrame
	projectile:SetAttribute("AttackerUserId", player.UserId)
	projectile:SetAttribute("WeaponId", weapon.id)
	projectile.Parent        = workspace

	-- Direction comes from the client's aim; normalise defensively
	local dir = direction.Unit
	projectile.AssemblyLinearVelocity = dir * (weapon.projectileSpeed or 80)

	local fired = false

	local conn
	conn = projectile.Touched:Connect(function(hit)
		if fired then return end

		local hitChar     = hit.Parent
		local hitHumanoid = hitChar and hitChar:FindFirstChildOfClass("Humanoid")

		-- Ignore: attacker's own character, already-dead humanoids, non-characters
		if not hitHumanoid then return end
		if hitChar == character then return end
		if hitHumanoid.Health <= 0 then return end

		fired = true
		conn:Disconnect()

		hitHumanoid:TakeDamage(weapon.damage)

		-- Sumpit slow effect
		if weapon.statusEffect then
			local targetPlayer = Players:GetPlayerFromCharacter(hitChar)
			local targetId = targetPlayer and targetPlayer.UserId
				or (hitChar:GetAttribute("NPCId") and hitChar.Name)
			self.Client.StatusEffectApply:FireAll(
				targetId,
				weapon.statusEffect.type,
				weapon.statusEffect.duration
			)
		end

		self.Client.CombatHit:FireAll(player.UserId, hit.Position, weapon.id)
		projectile:Destroy()
	end)

	Debris:AddItem(projectile, PROJECTILE_LIFETIME)
end

-- ── Weapon equip ──────────────────────────────────────────────────
function CombatService:equip(player, weaponId)
	local data = self._dataService:get(player)
	if not data then return false, "not_loaded" end

	local weaponCfg = AssetConfig.Weapons[weaponId]
	if not weaponCfg then return false, "invalid_weapon" end

	-- Must be in inventory
	if not self._inventoryService:hasItem(player, weaponId, 1) then
		return false, "not_in_inventory"
	end

	data.equippedWeapon = weaponId
	self.Client.WeaponEquipped:Fire(player, weaponId)
	return true
end

-- Unequips weapon (called when slot cleared or on death).
function CombatService:unequip(player)
	local data = self._dataService:get(player)
	if data then data.equippedWeapon = nil end
	self.Client.WeaponEquipped:Fire(player, nil)
end

-- ── Death handler ─────────────────────────────────────────────────
function CombatService:_onCharacterAdded(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid  = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	-- Disconnect previous death connection
	if self._deathConns[player.UserId] then
		self._deathConns[player.UserId]:Disconnect()
	end

	self._deathConns[player.UserId] = humanoid.Died:Connect(function()
		local data = self._dataService:get(player)
		if not data then return end

		-- Drop a random item if morality is below 40 (Nakal / Penjahat tier)
		if data.morality < 40 and #data.inventory > 0 then
			local idx   = math.random(1, #data.inventory)
			local entry = data.inventory[idx]
			if entry then
				self._inventoryService:_dropItem(player, entry.id, 1)
			end
		end

		-- Restore 50% stamina on next respawn
		task.delay(5, function()
			if player:IsDescendantOf(Players) then
				self._staminaService:set(player, math.floor(AssetConfig.Stamina.Max * 0.5))
			end
		end)
	end)
end

-- ── KnitInit ─────────────────────────────────────────────────────
function CombatService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
		self._cooldowns[player.UserId] = {}
		player.CharacterAdded:Connect(function()
			self:_onCharacterAdded(player)
		end)
		if player.Character then
			self:_onCharacterAdded(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._cooldowns[player.UserId] = nil
		if self._deathConns[player.UserId] then
			self._deathConns[player.UserId]:Disconnect()
			self._deathConns[player.UserId] = nil
		end
	end)

	for _, player in Players:GetPlayers() do
		self._cooldowns[player.UserId] = {}
		player.CharacterAdded:Connect(function()
			self:_onCharacterAdded(player)
		end)
		if player.Character then
			self:_onCharacterAdded(player)
		end
	end
end

-- ── KnitStart ────────────────────────────────────────────────────
function CombatService:KnitStart()
	self._dataService      = Knit.GetService("DataService")
	self._staminaService   = Knit.GetService("StaminaService")
	self._inventoryService = Knit.GetService("InventoryService")

	-- Listen to client attack requests
	self.Client.AttackRequest:Connect(function(player, weaponId, direction)
		self:_handleAttack(player, weaponId, direction)
	end)
end

-- ── Attack validation & dispatch ──────────────────────────────────
function CombatService:_handleAttack(player, weaponId, direction)
	-- 1. Validate equipped weapon matches request
	local data = self._dataService:get(player)
	if not data then return end
	if data.equippedWeapon ~= weaponId then
		self.Client.AttackRejected:Fire(player, "not_equipped")
		return
	end

	-- 2. Validate weapon config exists
	local weapon = AssetConfig.Weapons[weaponId]
	if not weapon then
		self.Client.AttackRejected:Fire(player, "invalid_weapon")
		return
	end

	-- 3. Server-side cooldown check
	local userId    = player.UserId
	local now       = tick()
	local cooldowns = self._cooldowns[userId]
	if cooldowns and cooldowns[weaponId] then
		if (now - cooldowns[weaponId]) < weapon.cooldown then
			self.Client.AttackRejected:Fire(player, "on_cooldown")
			return
		end
	end

	-- 4. Stamina check
	local ok = self._staminaService:spend(player, weapon.staminaCost)
	if not ok then
		-- StaminaService already fires StaminaTooLow to the client
		return
	end

	-- 5. Record cooldown timestamp
	if cooldowns then
		cooldowns[weaponId] = now
	end

	-- 6. Dispatch attack based on weapon type
	if ItemModule.isRanged(weaponId) then
		-- Validate direction is a unit-ish Vector3
		if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.01 then
			return
		end
		self:_rangedAttack(player, weapon, direction)
	else
		self:_meleeAttack(player, weapon)
	end
end

return CombatService
