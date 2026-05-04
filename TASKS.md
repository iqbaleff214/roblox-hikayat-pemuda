# Development Task Breakdown — Hikayat Pemuda

> Goal: scripts do the heavy lifting. Studio work is limited to placing terrain, importing 3D models, and uploading assets. All game logic, NPC spawning, UI, ProximityPrompts, BillboardGuis, and system wiring are handled by Lua scripts.
>
> Each task includes: **Goal**, **Deliverable**, **Depends on**, and **Instructions**.
>
> **Architecture rule:** All scripts are shared across all 7 Places (islands). No script is duplicated per-Place. AssetConfig, all Modules, and DialogTrees live in one source and are referenced by asset ID from every Place. Only Studio-level assets (terrain, model placement anchors) differ per Place.

---

## Phase 0 — Foundation

---

### TASK-000 — Shared Source Code Architecture

**Goal:** Establish how one codebase serves all 7 Places (Sumatera, Jawa, Kalimantan, Sulawesi, Papua, Nusa Tenggara, Maluku) without duplicating scripts. This is the foundational architecture decision — all other tasks depend on this pattern.

**Deliverable:** Published Roblox Model asset for shared modules. Documented `require(assetId)` pattern. `SharedConfig.lua` reference table listing all shared asset IDs.

**Depends on:** Nothing — define this before writing any script.

**Instructions:**

**Understanding the problem:**
- Roblox Places in the same Universe are separate servers with separate `ReplicatedStorage`, `ServerScriptService`, etc.
- A script placed in Place A's `ReplicatedStorage` does NOT exist in Place B.
- Solution: publish shared modules as Roblox Model assets, then `require(assetId)` from any Place.

**Step 1 — Identify what is shared vs Place-specific:**

| Shared (all 7 Places) | Place-specific |
|---|---|
| `AssetConfig` (all game data) | Terrain (built per island in Studio) |
| All `ReplicatedStorage/Modules/*` | StarterGui layout tweaks (if any) |
| `DialogTrees` module | `ServerScriptService/Bootstrap` (same script, copied once at project start, then maintained via shared asset) |
| `LocalizationUtil` | Map folder contents in Workspace |
| `StaminaModule`, `MoralityModule`, etc. | NPC model placements in Workspace |
| `QuestEngine`, `TaskEngine` | Zone anchor Parts positions |
| `InventoryModule`, `CraftingModule` | |
| `DataManager` (same DataStore keys work across Universe automatically) | |
| `NPCManager`, `ZoneManager`, `TravelServer` | |
| All `LocalScript` logic in StarterPlayerScripts | |

**Step 2 — Publish AssetConfig as a Roblox Model:**
1. In Studio (any Place), right-click `AssetConfig` ModuleScript → **Save to Roblox** → publish as a Model.
2. Note the returned **Asset ID** (e.g., `1234567890`). Save this in the table below.
3. Repeat for every shared ModuleScript listed above.

**Step 3 — Create `SharedConfig.lua` reference table (keep this file in all 7 Places locally as a plain script — it's tiny):**
```lua
-- ServerScriptService/SharedConfig (Script, tiny, NOT shared — just a reference table)
-- Update asset IDs here after each publish. Copy this file to all 7 Places.
return {
    AssetConfig     = 1234567890, -- replace with real asset ID after publish
    LocalizationUtil= 1234567891,
    StaminaModule   = 1234567892,
    MoralityModule  = 1234567893,
    QuestEngine     = 1234567894,
    TaskEngine      = 1234567895,
    InventoryModule = 1234567896,
    CraftingModule  = 1234567897,
    NPCManager      = 1234567898,
    ZoneManager     = 1234567899,
    TravelServer    = 1234567900,
    DialogTrees     = 1234567901,
    -- add more as created
}
```

**Step 4 — Require pattern for all scripts:**
```lua
-- At the top of any server Script or ModuleScript in any Place:
local SharedConfig = require(game.ServerScriptService.SharedConfig)
local AssetConfig  = require(SharedConfig.AssetConfig)  -- loads from Roblox asset
local ZoneManager  = require(SharedConfig.ZoneManager)

-- For LocalScripts (client side):
local SharedConfig = require(game.ReplicatedStorage.SharedConfig)  -- client copy
local AssetConfig  = require(SharedConfig.AssetConfig)
```

**Step 5 — Workflow for updating a shared module:**
1. Edit the ModuleScript in any Place's Studio.
2. Right-click → **Update Asset** (overwrites the published asset at the same ID).
3. All 7 Places pick up the change on next server start — no copy-paste.
4. Do NOT maintain 7 separate copies. There is one published asset, many requires.

**Step 6 — DataStore is Universe-wide by default:**
- `DataStoreService:GetDataStore("PlayerData")` returns the same store from all Places in the same Universe automatically.
- No extra setup needed. Keys written in Place Jawa are readable in Place Papua.
- The `"PlayerData_v2_" .. userId` key in TASK-004 works identically in all 7 Places.

**Step 7 — TeleportService context:**
- When a player teleports from Jawa to Sulawesi, they join a new server for the Sulawesi Place.
- Their data is already saved by DataManager before teleport fires.
- The Sulawesi server loads the same DataStore key on `PlayerAdded` — full state restored.
- Pass arrival zone ID via `TeleportService:TeleportToPlaceInstance(placeId, serverId, player, teleportData)` where `teleportData = {arrivalZone = "KotaMakassar"}`.

**Step 8 — Update SharedConfig in all Places when asset IDs change:**
- `SharedConfig` is the only file maintained separately per Place (because it just stores IDs, not logic).
- After any module is published/updated, update the ID in SharedConfig and copy to all 7 Places.
- Consider storing SharedConfig itself as a shared asset once all IDs are stable.

---

### TASK-001 — AssetConfig Module

**Goal:** Create the single source of truth for all game data. All 7 Places share this one module — no per-island copy. Devs add new items, quests, NPCs, weapons, zones by editing this one module only, then publishing once.

**Deliverable:** `ReplicatedStorage/Config/AssetConfig` (ModuleScript), published as Roblox asset, ID recorded in `SharedConfig`.

**Depends on:** TASK-000

**Instructions:**
1. Create `ModuleScript` at `ReplicatedStorage/Config/AssetConfig` in any one Place (e.g., Jawa Place as the dev master).
2. Define all tables as outlined in GDD §17: `Items`, `Weapons`, `Recipes`, `Shops`, `NPCs`, `Quests`, `Relationships`, `Morality`, `Hotbar`, `Stamina`, `Currency`, `Places`, `Zones`, `Travel`, `Tasks`, `Events`, `LoginStreak`, `Achievements`, `Audio`.
3. Populate with at least the Jawa zones, KotaJogja NPCs, Chapter 1 quest, and all 7 weapon definitions for MVP.
4. Every table entry must have `id` field matching its key (e.g., `AssetConfig.Items.NasiBungkus.id == "NasiBungkus"`). This is required for reliable lookup by all modules.
5. Add helper functions at the bottom:
   ```lua
   function AssetConfig.getItem(id) return AssetConfig.Items[id] end
   function AssetConfig.getZone(id) return AssetConfig.Zones[id] end
   function AssetConfig.getQuest(id) return AssetConfig.Quests[id] end
   function AssetConfig.getPlace(id) return AssetConfig.Places[id] end
   ```
   Each does a nil-safe return — callers must check for nil.
6. All asset IDs default to `"rbxassetid://0"` until actual uploads replace them.
7. `return AssetConfig` at end.
8. **After writing:** right-click AssetConfig in Studio → **Save to Roblox** → publish as Model. Record the returned Asset ID in `SharedConfig.AssetConfig`.
9. In all other 6 Places, do NOT paste AssetConfig. Instead use: `require(SharedConfig.AssetConfig)` — this loads the one published version.

---

### TASK-002 — Folder & RemoteEvent Bootstrap Script

**Goal:** On server start, ensure every required `RemoteEvent`, `RemoteFunction`, and `Folder` exists. Bootstrap also loads all shared modules via `SharedConfig` so every subsequent server script can require them without repeating the asset ID lookup.

**Deliverable:** `ServerScriptService/Bootstrap` (Script) — **copied to all 7 Places identically**

**Depends on:** TASK-000, TASK-001

**Instructions:**
1. Create a `Script` named `Bootstrap` in `ServerScriptService`. Copy this exact script to all 7 Places — it is identical in every Place.
2. First line: load shared config:
   ```lua
   local SharedConfig = require(game.ServerScriptService.SharedConfig)
   local AssetConfig  = require(SharedConfig.AssetConfig)
   ```
3. Bootstrap sets up `_G.Modules` table so other server scripts can access shared modules without re-requiring by asset ID each time:
   ```lua
   _G.Modules = {
       AssetConfig  = AssetConfig,
       ZoneManager  = require(SharedConfig.ZoneManager),
       NPCManager   = require(SharedConfig.NPCManager),
       QuestEngine  = require(SharedConfig.QuestEngine),
       TaskEngine   = require(SharedConfig.TaskEngine),
       MoralityModule = require(SharedConfig.MoralityModule),
       -- etc.
   }
   ```
4. Runs once at server start, before any other server script.
2. Define a list of all required `RemoteEvent` names (see GDD §19): `UpdateHotbar`, `OpenShop`, `QuestUpdate`, `TaskUpdate`, `MoralityChanged`, `AchievementUnlocked`, `LoginStreakClaimed`, `OpenGaleri`, `OpenTravelMap`, `TeleportToPlace`, `SyncInventory`, `DialogOpen`, `CombatHit`, `WorldEventSpawn`.
3. Define a list of required `RemoteFunction` names: `GetPlayerData`, `PurchaseItem`, `CraftItem`, `GetShopStock`.
4. For each, check if it already exists in `ReplicatedStorage/RemoteEvents`; if not, `Instance.new()` and parent it there.
5. Ensure `ReplicatedStorage/Config`, `ReplicatedStorage/Modules`, `ReplicatedStorage/RemoteEvents` folders exist — create them if missing.
6. Ensure `Workspace/Map/Zones` folder exists.
7. Print a confirmation log: `"[Bootstrap] All remotes and folders ready."` on success.

---

### TASK-003 — LocalizationUtil Module

**Goal:** Wrap Roblox's `LocalizationService` into a simple utility so all other scripts call `L("key")` instead of raw service calls. Supports Indonesian (id) and English (en) with Indonesian as default fallback.

**Deliverable:** `ReplicatedStorage/Modules/LocalizationUtil` (ModuleScript)

**Depends on:** TASK-001

**Instructions:**
1. Create `ModuleScript` at `ReplicatedStorage/Modules/LocalizationUtil`.
2. On require, get `LocalizationService:GetTranslatorForLocalPlayer()` (client) or `LocalizationService:GetTranslatorForLocale("id")` (server fallback).
3. Expose a single function: `LocalizationUtil.get(key, substitutions?)` → calls `translator:FormatByKey(key, substitutions)`. Return the key itself if translation not found, so missing strings are obvious.
4. Also expose `LocalizationUtil.getLocale()` → returns the player's locale string.
5. Add an `init` function that accepts a `LocalizationTable` asset ID to load (so each Place can load its own table if needed, but all share one in practice).
6. Usage pattern everywhere else: `local L = require(LocalizationUtil).get`.

---

### TASK-004 — DataManager

**Goal:** Handle all player data persistence via `DataStoreService`. Every other system reads/writes player data through DataManager only — no other script touches DataStore directly.

**Deliverable:** `ServerScriptService/DataManager` (Script)

**Depends on:** TASK-001, TASK-002

**Instructions:**
1. Create a `Script` in `ServerScriptService/DataManager`.
2. Use a single `DataStore` key per player: `"PlayerData_v2_" .. player.UserId`.
3. On `Players.PlayerAdded`: load data with `pcall`. If load fails, retry up to 3 times with 1s wait between. If all fail, use a fresh default schema (from GDD §18.1) and flag the session as `loadFailed = true` to prevent overwriting good data on save.
4. Store loaded data in a server-side table `PlayerData[player.UserId]`.
5. Expose module functions via a `BindableEvent`-based API or direct `require` on server: `DataManager.get(player, key)`, `DataManager.set(player, key, value)`, `DataManager.save(player)`.
6. On `Players.PlayerRemoving`: call `DataManager.save(player)`, then remove from `PlayerData` table.
7. Auto-save every 5 minutes for all active players using a `while true do` loop with `task.wait(300)`.
8. Default data schema must exactly match GDD §18.1. Implement a `migrate(data)` function that checks `data.version` and upgrades schema from v1 → v2 if needed.
9. Use `pcall` on every `DataStore` call. Log failures but never throw errors to caller.

---

### TASK-005 — GameManager

**Goal:** Central server orchestrator. Handles player join/leave lifecycle, distributes initial data to clients, and fires startup sequence for all other server systems.

**Deliverable:** `ServerScriptService/GameManager` (Script)

**Depends on:** TASK-002, TASK-004

**Instructions:**
1. Create `Script` in `ServerScriptService/GameManager`.
2. On `Players.PlayerAdded`:
   - Wait for `DataManager` to finish loading that player's data.
   - Fire `GetPlayerData` RemoteFunction response with the loaded data snapshot (client uses this to initialize its local state).
   - Assign the player to their last-known zone (from `data.unlockedZones`) or default starting zone.
   - Fire `MoralityChanged` RemoteEvent to sync morality tier UI on join.
   - Call `NPCManager.onPlayerJoin(player)` and `ZoneManager.onPlayerJoin(player)`.
3. On `Players.PlayerRemoving`: call cleanup functions on all managers.
4. Expose a server-side `GameManager.getZone(player)` that returns the player's current zone ID (updated by ZoneManager).

---

## Phase 1 — Core Mechanics

---

### TASK-010 — Stamina System

**Goal:** Track, deplete, and regenerate each player's stamina server-side. Broadcast changes to the owning client for HUD display. Other systems (combat, sprint) call StaminaModule to spend stamina.

**Deliverable:** `ReplicatedStorage/Modules/StaminaModule` (ModuleScript), integrated into `GameManager`

**Depends on:** TASK-004, TASK-005

**Instructions:**
1. Create `ModuleScript` at `ReplicatedStorage/Modules/StaminaModule`.
2. Values from `AssetConfig.Stamina`: `Max`, `RegenRate`, `SprintCost`.
3. Server maintains a table `Stamina[userId] = currentValue` (initialized to `Max` on join).
4. Expose: `StaminaModule.spend(player, amount)` → returns `true` if successful, `false` if insufficient. Deducts from table.
5. Expose: `StaminaModule.get(player)` → current value.
6. Regen loop: every 1 second, add `RegenRate` to all players not currently spending stamina, capped at `Max`. Fire a `RemoteEvent` ("StaminaUpdate") to each player with their new value.
7. When stamina hits 0: fire a "StaminaDepleted" event to client (triggers red vignette VFX).
8. Food consumption restores stamina: `StaminaModule.restore(player, amount)` — call this from ItemModule when food is consumed.

---

### TASK-011 — Inventory & Item System

**Goal:** Manage each player's inventory server-side. Items are stored as `{ id, amount }` entries. Client requests actions (use, equip, move to hotbar); server validates and updates.

**Deliverable:** `ReplicatedStorage/Modules/ItemModule` (ModuleScript), `ServerScriptService/InventoryServer` (Script), `StarterPlayerScripts/InventoryController` (LocalScript)

**Depends on:** TASK-001, TASK-004

**Instructions:**
1. **ItemModule** (shared): expose `ItemModule.getConfig(itemId)` → returns `AssetConfig.Items[itemId]`. Expose `ItemModule.isEquippable(itemId)` → type is Weapon or Kosmetik. Expose `ItemModule.isConsumable(itemId)` → type is Food/Drink.
2. **InventoryServer** (server Script):
   - Listen to RemoteFunction `UseItem(player, itemId)`: validate item exists in player's inventory; if Food → call `StaminaModule.restore()`; if Weapon → call `CombatServer.equip()`; reduce amount by 1; if amount = 0, remove entry; fire `SyncInventory` RemoteEvent back to player.
   - Listen to `DropItem(player, itemId, amount)`: remove from inventory, spawn a world pickup object near the player with a `CollectionService` tag for cleanup.
   - `InventoryServer.addItem(player, itemId, amount)`: adds to inventory, respects `inventorySize` cap, fires `SyncInventory`. Called by quest rewards, loot drops, shop purchases.
   - `InventoryServer.removeItem(player, itemId, amount)`: inverse. Called by shop sells, crafting.
3. **InventoryController** (client LocalScript):
   - On `SyncInventory` event: update local inventory cache.
   - Expose `InventoryController.getLocal()` → current local cache (used by InventoryGui to render).
   - Handle drag-to-hotbar locally, then fire `AssignHotbar(slotIndex, itemId)` RemoteEvent to server.
4. Max inventory slots enforced server-side from `data.inventorySize`.

---

### TASK-012 — Hotbar System

**Goal:** Allow players to assign up to 8 items to quick-access slots. Desktop uses keys 1–8; mobile uses tap. Equip/use is instant from hotbar.

**Deliverable:** `StarterPlayerScripts/HotbarController` (LocalScript)

**Depends on:** TASK-011

**Instructions:**
1. Create `LocalScript` at `StarterPlayerScripts/HotbarController`.
2. Maintain local `hotbar = {}` table: `hotbar[slotIndex] = itemId` (max slots from `data.hotbarSize`, default 4).
3. On join, populate from `data.hotbar` received via `GetPlayerData`.
4. Desktop: bind `UserInputService.InputBegan` for keys `1` through `8`. Pressing a number key selects that slot; pressing `F` or pressing the same number again uses/equips the item in that slot.
5. Mobile: HotbarGui buttons (built in TASK-030) fire a `BindableEvent` "HotbarSlotPressed" with `slotIndex`.
6. On slot activation: call `InventoryController` to trigger `UseItem` RemoteEvent for the item in that slot.
7. On `AssignHotbar` response from server: update local `hotbar` table and refresh HotbarGui display.
8. Upgrade slot: on `HotbarUpgrade` RemoteEvent from server (after purchase), increment local `hotbarSize` and re-render the hotbar.
9. Active slot (weapon equipped) maintains a visual highlight — fire a `BindableEvent` "ActiveSlotChanged" for HotbarGui to listen to.

---

### TASK-013 — Combat System

**Goal:** Handle weapon equip/unequip, hitbox detection, damage application, cooldown enforcement, and stamina cost. No client-side damage authority — server validates all hits.

**Deliverable:** `ServerScriptService/CombatServer` (Script), `StarterPlayerScripts/CombatController` (LocalScript)

**Depends on:** TASK-010, TASK-011

**Instructions:**
1. **CombatController** (client):
   - Track currently equipped weapon from `HotbarController`.
   - On `UserInputService.InputBegan` (mouse click / screen tap): fire `AttackRequest(weaponId)` RemoteEvent to server.
   - Play weapon animation locally immediately (client-side prediction for feel). Load animation from `AssetConfig.Weapons[weaponId].animationId`.
   - Enforce client-side cooldown display (gray out attack UI during cooldown) using `AssetConfig.Weapons[weaponId].cooldown`.
2. **CombatServer** (server):
   - On `AttackRequest(player, weaponId)`:
     a. Validate player has `weaponId` equipped.
     b. Validate cooldown has elapsed (track last attack time per player per weapon server-side).
     c. Check `StaminaModule.spend(player, weapon.staminaCost)` — if false, reject and fire "StaminaTooLow" event to client.
     d. Create a `Region3` or use `workspace:GetPartsInPart()` around the player's position with radius = `weapon.range`.
     e. For each humanoid found in range that is not the attacker: calculate damage. Apply `weapon.moralityBonus` multiplier if player morality ≥ threshold. Apply damage via `Humanoid:TakeDamage()`.
     f. If target is an innocent NPC (not Enemy type): call `MoralityModule.apply(player, -15)`.
     g. Fire `CombatHit` RemoteEvent to all clients in range for VFX/SFX.
   - Ranged weapons (Ketapel, Sumpit): on `AttackRequest`, spawn a server-side projectile `Part` with `BodyVelocity`, tagged with attacker userId. On `Part.Touched`, detect humanoid hit, apply damage, destroy part. Sumpit additionally fires `StatusEffectApply(target, "Slow", 3)`.
   - `CombatServer.equip(player, weaponId)`: validate weapon in inventory, set `data.equippedWeapon`, fire `WeaponEquipped` RemoteEvent to client.
   - On player death (Humanoid.Died): respawn after 5s, restore 50% stamina, drop a random item from inventory (if morality < 40).

---

### TASK-014 — Currency System

**Goal:** Manage Rupiah and Gold balances server-side. Provide formatted display strings (Indonesian number format). All currency changes go through CurrencyModule.

**Deliverable:** `ReplicatedStorage/Modules/CurrencyModule` (ModuleScript)

**Depends on:** TASK-004

**Instructions:**
1. Create `ModuleScript` at `ReplicatedStorage/Modules/CurrencyModule`.
2. Expose: `CurrencyModule.get(player, type)` → returns `data.rupiah` or `data.gold`.
3. Expose: `CurrencyModule.add(player, type, amount)` → adds to balance, saves via DataManager, fires `CurrencyUpdate` RemoteEvent to client.
4. Expose: `CurrencyModule.spend(player, type, amount)` → returns `false` if insufficient, otherwise deducts and fires event.
5. Expose: `CurrencyModule.format(amount)` → returns a string formatted as Indonesian number style (e.g., `"Rp 12.500"` using `.` as thousands separator). Implement this without external libraries: convert to string, insert dots every 3 digits from right.
6. Client-side: on `CurrencyUpdate` event, update HUD display immediately.

---

## Phase 2 — Economy

---

### TASK-020 — Shop System

**Goal:** Handle buy and sell transactions. Validate stock, morality-based pricing, accepted item types, and shop category restrictions — all server-side.

**Deliverable:** `ServerScriptService/ShopServer` (Script)

**Depends on:** TASK-001, TASK-011, TASK-014

**Instructions:**
1. Create `Script` in `ServerScriptService/ShopServer`.
2. On `PurchaseItem` RemoteFunction (player, shopId, itemId, quantity):
   a. Load shop config from `AssetConfig.Shops[shopId]`.
   b. Validate shop type is `"BuyOnly"` or `"BuySell"`.
   c. Validate `itemId` is in `shop.stock`.
   d. Validate `shop.acceptedTypes` — if set, item type must match.
   e. Calculate price: `item.basePrice`. Apply morality discount if player morality ≥ `shop.moralityDiscount.threshold`.
   f. Call `CurrencyModule.spend(player, "Rupiah", totalPrice)` — reject if false.
   g. Call `InventoryServer.addItem(player, itemId, quantity)`.
   h. Return `{ success = true }`.
3. On `SellItem` RemoteFunction (player, shopId, itemId, quantity):
   a. Validate shop type is `"SellOnly"` or `"BuySell"`.
   b. If `shop.acceptedTypes` set, validate item type.
   c. Check player morality — if `Sangat Buruk` (0–19), refuse: return `{ success = false, reason = "refused" }`.
   d. Calculate sell price: `item.basePrice * shop.sellMultiplier`. Apply lucky sale: 3% chance → multiply by 1.2.
   e. Call `InventoryServer.removeItem(player, itemId, quantity)` — reject if player doesn't have enough.
   f. Call `CurrencyModule.add(player, "Rupiah", totalPrice)`.
   g. Return `{ success = true, earned = totalPrice }`.
4. On `OpenShop` RemoteEvent (player, shopId): fire back shop config + current player morality so client can render correct tabs and prices.

---

### TASK-021 — Crafting System

**Goal:** Allow players to combine ingredients into output items. Server validates recipe, deducts ingredients, adds output, applies the 1% enhanced craft chance.

**Deliverable:** `ServerScriptService/CraftingServer` (Script)

**Depends on:** TASK-001, TASK-011

**Instructions:**
1. Create `Script` in `ServerScriptService/CraftingServer`.
2. On `CraftItem` RemoteFunction (player, recipeIndex):
   a. Load recipe from `AssetConfig.Recipes[recipeIndex]`.
   b. Validate player has all required ingredients at required amounts.
   c. Deduct all ingredients via `InventoryServer.removeItem()`.
   d. Wait `recipe.craftTime` seconds (use `task.wait`).
   e. Roll 1% enhanced chance: if `math.random() < 0.01`, output item gets `enhanced = true` tag (stored as `{ id, amount, enhanced = true }` in inventory).
   f. Add output via `InventoryServer.addItem()`.
   g. Fire `CraftComplete` RemoteEvent to client with result.
   h. Call `AchievementServer.check(player, "Craft")`.
3. On `GetRecipes` RemoteFunction (player): return all recipes from `AssetConfig.Recipes`. Client filters which ones the player can currently craft based on local inventory cache.

---

## Phase 3 — NPC & Dialog

---

### TASK-030 — NPC Manager

**Goal:** Spawn all NPCs from `AssetConfig.NPCs` into the correct zone at server start. Add ProximityPrompts by script. Run daily schedules (move NPCs between locations based on game time). No manual NPC placement in Studio.

**Deliverable:** `ServerScriptService/NPCManager` (Script)

**Depends on:** TASK-001, TASK-005

**Instructions:**
1. Create `Script` in `ServerScriptService/NPCManager`.
2. On server start, iterate `AssetConfig.NPCs`. For each NPC:
   a. Load the NPC model via `InsertService:LoadAsset(config.modelId)` or `game:GetService("InsertService"):LoadAsset()`. Parent it to `Workspace/NPCs/[zoneId]`.
   b. Name the model instance `config.id`.
   c. Position it at the first `schedule` entry's location: look for a `Part` or `Attachment` named `config.schedule[1].location` in the zone folder. If not found, use a fallback Vector3 from a config table `AssetConfig.NPCSpawns[npcId]`.
   d. Add a `BillboardGui` above the model's head with the NPC name (localized via `LocalizationUtil`).
   e. Add a `ProximityPrompt` to the model's `PrimaryPart`:
      - `ActionText` = "Bicara" (or "Beli" if NPC has a shop, or both via multiple prompts stacked with different `KeyboardKeyCode`).
      - `MaxActivationDistance` = 8.
      - On `ProximityPrompt.Triggered`: fire `DialogOpen` RemoteEvent to the triggering player with `npcId`.
   f. If NPC has a `shopId`: add a second `ProximityPrompt` with `ActionText` = "Beli", triggering `OpenShop` RemoteEvent.
3. Schedule loop: every in-game hour (compressed time), check `AssetConfig.NPCs[id].schedule` against current game hour. Move the NPC model to the matching location part using `TweenService` for smooth movement.
4. Track spawned NPC instances in a table `NPCInstances[npcId] = model`.
5. Expose `NPCManager.getNPC(npcId)` → returns the live model instance.

---

### TASK-031 — Dialog System

**Goal:** Drive branching NPC conversations from a data table. All dialog trees are defined in a config table (separate from AssetConfig for readability). Server sends the dialog node; client displays it and sends back player choice.

**Deliverable:** `ReplicatedStorage/Config/DialogTrees` (ModuleScript), `StarterPlayerScripts/DialogController` (LocalScript)

**Depends on:** TASK-030, TASK-003

**Instructions:**
1. **DialogTrees** ModuleScript: define all NPC dialog trees as nested tables.
   ```lua
   DialogTrees.Parmin_Main = {
       root = "greet",
       nodes = {
           greet = {
               speaker = "Parmin",
               textKey = "npc.parmin.greet",
               choices = {
                   { labelKey = "dialog.choice.ask_arjuna", next = "about_arjuna" },
                   { labelKey = "dialog.choice.bye",        next = nil },
               }
           },
           about_arjuna = {
               speaker = "Parmin",
               textKey = "npc.parmin.arjuna_story",
               choices = {
                   { labelKey = "dialog.choice.thanks", next = nil },
               },
               onEnter = "QuestServer.triggerCheck('MQ_Ch1_Awal', 'Talk', 'Parmin')",
           }
       }
   }
   ```
2. On `DialogOpen` RemoteEvent (server → client) with `{ npcId, nodeId }`:
   - Client looks up `DialogTrees[npc.dialogTree].nodes[nodeId]`.
   - Display NPC name, localized text, and choice buttons in `DialogGui`.
3. On player choice click: client fires `DialogChoice(npcId, choiceIndex)` RemoteEvent to server.
4. Server receives choice: advance to `next` node; if `onEnter` is set, evaluate it (use a safe dispatch table, not `loadstring`); fire `DialogOpen` back to client with new node. If `next == nil`, fire `DialogClose`.
5. Morality-gated choices: add `minMorality` or `maxMorality` fields to choice entries. Server omits choices the player doesn't qualify for before sending nodes.
6. `DialogController` (client LocalScript): manage typewriter text effect (reveal one character per `0.03s`). Skip on tap/click. Handle choice button layout — stack vertically, minimum 44px height each for mobile.

---

## Phase 4 — Quest & Task Systems

---

### TASK-040 — Quest System

**Goal:** Track each player's main and side quest progress server-side. Handle objective completion from other systems (combat, dialog, item collect). Deliver rewards on completion. Enforce 5 concurrent side quest cap.

**Deliverable:** `ReplicatedStorage/Modules/QuestModule` (ModuleScript), `ServerScriptService/QuestServer` (Script)

**Depends on:** TASK-001, TASK-004, TASK-011, TASK-014

**Instructions:**
1. **QuestModule** (shared): expose `QuestModule.getConfig(questId)`, `QuestModule.getObjectiveProgress(playerData, questId, objIndex)`.
2. **QuestServer** (Script):
   - On join: restore `data.questProgress` and `data.activeQuests` from DataManager.
   - `QuestServer.accept(player, questId)`: validate quest not already active/completed; if side quest, check active count < 5; add to `data.activeQuests`; fire `QuestUpdate` RemoteEvent to client.
   - `QuestServer.triggerCheck(player, type, target, amount?)`: called by other systems (CombatServer calls `triggerCheck(player, "Combat", nil, 1)` on kill; DialogController calls `triggerCheck(player, "Talk", npcId)`; InventoryServer calls `triggerCheck(player, "Gather", itemId, amount)`). For each active quest, find matching objectives and increment progress. If all objectives complete → call `complete(player, questId)`.
   - `QuestServer.complete(player, questId)`: mark as completed; grant rewards (currency via CurrencyModule, items via InventoryServer, morality via MoralityModule); fire `QuestUpdate` RemoteEvent; for main quests, unlock next quest and call `ZoneManager.unlockZone(player, nextZone)` if applicable; call `AchievementServer.check(player, "Quest")`.
   - Side quest acceptance flow: player talks to NPC → DialogTree `onEnter` fires `QuestServer.offerQuest(player, questId)` → server fires `QuestOffer` RemoteEvent → client shows accept/decline dialog → client fires `QuestAccept` or `QuestDecline`.
3. Fire `QuestUpdate` RemoteEvent to client on every state change. Payload: `{ activeQuests, completedQuests, questProgress }`.

---

### TASK-041 — Task System (Tugas Harian & Mingguan)

**Goal:** Generate daily (5) and weekly (3) tasks per player from template pool. Track progress. Reset on schedule. Award Bonus Peti on full daily completion.

**Deliverable:** `ReplicatedStorage/Modules/TaskModule` (ModuleScript), `ServerScriptService/TaskServer` (Script)

**Depends on:** TASK-001, TASK-004, TASK-014, TASK-011

**Instructions:**
1. **TaskModule** (shared): expose `TaskModule.getTemplate(templateId)`, `TaskModule.shouldReset(data, type)` — checks if `data.lastDailyReset` is before today's 17:00 UTC (= 00:00 WIB).
2. **TaskServer** (Script):
   - On player join: call `checkReset(player)` — compare `os.time()` to `data.lastDailyReset`. If past reset threshold, generate new daily tasks:
     a. Shuffle `AssetConfig.Tasks.Templates` filtered by difficulty.
     b. Pick 3 Easy + 2 Medium randomly (no repeats) → assign to `data.dailyTasks`.
     c. Update `data.lastDailyReset = os.time()`, reset `data.dailyRerollsUsed = 0`.
   - Same logic for weekly tasks (3 Medium + 1 Hard, compare `data.lastWeeklyReset` to last Monday 17:00 UTC).
   - `TaskServer.triggerCheck(player, type, target?, amount?)`: same pattern as QuestServer — called by other systems. Match against `data.dailyTasks` and `data.weeklyTasks`. Increment progress. On complete: mark `completed = true`, fire `TaskUpdate` RemoteEvent. Do NOT auto-claim — player must press Claim button.
   - On `ClaimTask` RemoteEvent (player, taskId, isWeekly): validate `completed == true` and `claimed == false`; grant reward; set `claimed = true`; check if all daily/weekly claimed → grant bonus (Bonus Peti or Gold); fire `TaskUpdate`.
   - `TaskServer.reroll(player, taskIndex)`: validate `data.dailyRerollsUsed < AssetConfig.Tasks.rerollsPerDay`; spend Rupiah; replace task at index with new random one of same difficulty (exclude current active templates); increment `rerollsUsed`.
3. Fire `TaskUpdate` to client on every state change. Payload: full `{ dailyTasks, weeklyTasks }`.

---

## Phase 5 — Morality & Progression

---

### TASK-050 — Morality System

**Goal:** Apply morality changes from all sources. Broadcast tier changes to client (for HUD icon, NPC behavior). Persist via DataManager.

**Deliverable:** `ReplicatedStorage/Modules/MoralityModule` (ModuleScript)

**Depends on:** TASK-004, TASK-003

**Instructions:**
1. Create `ModuleScript` at `ReplicatedStorage/Modules/MoralityModule`.
2. Expose: `MoralityModule.apply(player, delta)` → clamp result to 0–100; update `data.morality`; fire `MoralityChanged` RemoteEvent to client with `{ value, tier, labelKey, color }`. Save via DataManager.
3. Expose: `MoralityModule.getTier(value)` → iterates `AssetConfig.Morality.Tiers`, returns matching tier table.
4. Expose: `MoralityModule.get(player)` → returns `data.morality`.
5. Client on `MoralityChanged`: update HUD morality icon, label, color. Trigger VFX: if delta > 0, play "MoralityRise" particle; if delta < 0, play "MoralityFall" particle.
6. Other systems call `MoralityModule.apply()`:
   - `CombatServer`: on hit innocent NPC.
   - `QuestServer`: on quest complete with morality reward.
   - `ShopServer`: never directly (morality affects pricing, not vice versa).
   - `WorldEventServer`: on event resolution.

---

### TASK-051 — Achievement System

**Goal:** Track one-time milestone achievements. Check after relevant actions. Award badge + currency/item on first unlock.

**Deliverable:** `ReplicatedStorage/Modules/AchievementModule` (ModuleScript), `ServerScriptService/AchievementServer` (Script)

**Depends on:** TASK-004, TASK-014, TASK-011, TASK-050

**Instructions:**
1. **AchievementModule** (shared): expose `AchievementModule.isCompleted(data, achId)` → checks `data.achievements[achId].completed`.
2. **AchievementServer** (Script):
   - `AchievementServer.check(player, category)`: called after relevant actions with a category string (e.g., `"Combat"`, `"Craft"`, `"Explore"`, `"Morality"`, `"Relationship"`). Filter `AssetConfig.Achievements` by `type == category`. For each uncompleted achievement in that category, evaluate its condition against current data snapshot. If met → call `unlock(player, achId)`.
   - `unlock(player, achId)`: mark `data.achievements[achId] = { completed = true, claimedAt = os.time() }`; grant reward (CurrencyModule / InventoryServer); fire `AchievementUnlocked` RemoteEvent to client with full achievement config.
   - Special types: `ExplorePlace` checks `#data.unlockedPlaces >= count`. `ExploreZone` checks count of `data.unlockedZones` filtered by place. `Morality` checks `MoralityModule.getTier().labelKey == target`.
3. Call `AchievementServer.check(player, "Combat")` from CombatServer on kill. Call `check(player, "Craft")` from CraftingServer. Call `check(player, "Explore")` from ZoneManager on zone unlock. Etc.

---

### TASK-052 — Login Streak System

**Goal:** Award daily login rewards based on consecutive-day streak. Show streak popup on join.

**Deliverable:** `ServerScriptService/LoginStreakServer` (Script)

**Depends on:** TASK-004, TASK-014, TASK-011

**Instructions:**
1. Create `Script` in `ServerScriptService/LoginStreakServer`.
2. On `Players.PlayerAdded`:
   a. Get today's date as `"YYYY-MM-DD"` string using `os.date("!%Y-%m-%d")` (UTC, adjust for WIB +7 if needed).
   b. If `data.lastLoginDate == today` → already claimed today, do nothing.
   c. Else: check if `data.lastLoginDate` was yesterday → increment `data.loginStreak`. Else (missed a day) → reset `data.loginStreak = 1`.
   d. Update `data.lastLoginDate = today`.
   e. Find matching reward in `AssetConfig.LoginStreak` where `day <= data.loginStreak` — take the highest matching day. Grant reward.
   f. Fire `LoginStreakClaimed` RemoteEvent to client with `{ streak, reward, nextReward }`.
3. Client on `LoginStreakClaimed`: show `LoginStreakGui` popup (streak count, today's reward, next milestone preview). Auto-dismiss after 5s or on player tap.

---

## Phase 6 — World & Travel

---

### TASK-060 — Zone Manager

**Goal:** Detect which zone a player is currently in (via part overlap check). Unlock zones per player progress. Update server zone tracking. Call `AchievementServer` on first visit.

**Deliverable:** `ServerScriptService/ZoneManager` (Script)

**Depends on:** TASK-001, TASK-004, TASK-005

**Instructions:**
1. Create `Script` in `ServerScriptService/ZoneManager`.
2. Define zone boundary detection: each zone folder in `Workspace/Map/Zones/[zoneId]` must contain a `Part` named `"ZoneBoundary"` with `CanCollide = false`, `Transparency = 1`. Script adds these parts at startup using zone bounding box config from `AssetConfig.ZoneBounds` table (define a `ZoneBounds` config table with `{ center = Vector3, size = Vector3 }` per zoneId). This way no manual invisible parts are needed — script creates them.
3. Every 2 seconds, for each player: check which `ZoneBoundary` part the player's `HumanoidRootPart` overlaps (use `workspace:GetPartsInPart()` or magnitude check). Update `GameManager.playerZone[userId]`.
4. On zone change: fire `ZoneChanged` RemoteEvent to client with new zoneId; trigger audio zone crossfade; call `AchievementServer.check(player, "Explore")`.
5. `ZoneManager.unlockZone(player, zoneId)`: add zoneId to `data.unlockedZones` if not present. Fire `ZoneUnlocked` RemoteEvent to client (triggers zone unlock VFX + sound). Save.
6. `ZoneManager.isUnlocked(player, zoneId)` → boolean. Used by TravelServer to gate teleport.
7. On first ever visit to a Place (zoneId is default zone of that place): add the place to `data.unlockedPlaces`.

---

### TASK-061 — Travel System (Bandara & Pelabuhan)

**Goal:** Allow inter-island travel via TeleportService at Bandara locations and inter-zone ferry at Pelabuhan locations. Charge ticket price. Show Peta Perjalanan map UI.

**Deliverable:** `ServerScriptService/TravelServer` (Script), `StarterPlayerScripts/TravelController` (LocalScript)

**Depends on:** TASK-001, TASK-014, TASK-060, TASK-002

**Instructions:**
1. **TravelServer** (Script):
   - At server start: for each zone that has `hasBandara = true` in `AssetConfig.Zones`, find the `Part` named `"BandaraTicketCounter"` in that zone folder. Add a `ProximityPrompt` to it: `ActionText = "Pesan Tiket"`. On trigger: fire `OpenTravelMap` RemoteEvent to the triggering player with `{ mode = "Bandara", currentZone = zoneId }`.
   - Same for Pelabuhan zones: find `"PelabuhanTicketCounter"` Part, add prompt, fire with `{ mode = "Pelabuhan" }`.
   - On `TeleportToPlace` RemoteEvent (player, destinationPlaceId, destinationZoneId):
     a. Validate `destinationPlaceId` is a valid PlaceId from `AssetConfig.Places`.
     b. Validate `ZoneManager.isUnlocked(player, defaultZoneOfDestination)` — only if Chapter 1 complete.
     c. Calculate ticket cost from `AssetConfig.Travel`.
     d. `CurrencyModule.spend(player, "Rupiah", cost)` — reject if insufficient.
     e. Save player data before teleport.
     f. `TeleportService:TeleportToPlaceInstance(destinationPlaceId, game.JobId, player)` — passes `{destinationZoneId}` as teleport data so destination place spawns player at the right zone.
   - On `FerryTravel` RemoteEvent (player, destinationZoneId — same island):
     a. Validate same place. Charge ferry cost.
     b. Teleport player character to the destination zone's spawn point Part in `Workspace/Map/Zones/[zoneId]/SpawnPoint`.
2. **TravelController** (client LocalScript):
   - On `OpenTravelMap` event: open `TravelGui`, pass mode and currentZone.
   - On destination click in map UI: fire `TeleportToPlace` or `FerryTravel` RemoteEvent back to server.
3. On arriving at a new Place via teleport: read teleport data to know arrival zone; `ZoneManager` spawns player at that zone's `SpawnPoint`.

---

### TASK-062 — World Event System

**Goal:** Periodically spawn random world events in active zones. Each event has a trigger area, a timer, and a resolution outcome (morality change, loot drop).

**Deliverable:** `ServerScriptService/WorldEventServer` (Script)

**Depends on:** TASK-001, TASK-050, TASK-030

**Instructions:**
1. Create `Script` in `ServerScriptService/WorldEventServer`.
2. Define event templates in a config table (or extend `AssetConfig` with `AssetConfig.WorldEvents`):
   - `MerchantAttacked`: spawn 2 bandit NPCs near a merchant NPC. If player defeats bandits within 60s → morality +8, Rupiah reward. If timer expires → merchant "flees" (model removed), nothing.
   - `RareIngredientSpawn`: spawn a glowing part at a defined spawn point in the zone. First player to touch it gets the ingredient item. Auto-despawn after 120s.
   - `NPCDistress`: an ambient NPC starts playing a distress animation and a BillboardGui "!" appears. ProximityPrompt "Bantu" triggers help dialog → morality +5, Rupiah.
   - `PoacherCamp`: spawn 3 poacher enemy NPCs at a forest zone. Defeating all → morality +10, loot drop.
3. Every 5 minutes per zone: if fewer than 1 active event in the zone, roll a random event type (weighted) and spawn it.
4. Track active events in `ActiveEvents[zoneId] = eventInstance`. Clean up on resolution or timeout.
5. Fire `WorldEventSpawn` RemoteEvent to all players in the zone (client plays an ambient notification sound).

---

### TASK-063 — Day/Night Cycle

**Goal:** Run a compressed in-game day cycle (real-time minutes → in-game hours). Drive `Lighting` service properties. Update NPC schedules. Trigger ambient audio transitions.

**Deliverable:** `ServerScriptService/DayNightCycle` (Script)

**Depends on:** TASK-030

**Instructions:**
1. Create `Script` in `ServerScriptService/DayNightCycle`.
2. Define `REAL_MINUTES_PER_GAME_DAY = 30` (30 real minutes = 1 full in-game day). Expose this in `AssetConfig` so devs can tune without touching the script.
3. Use a `while true do task.wait(1)` loop. Each real second, advance `Lighting.TimeOfDay` by `(24 / (REAL_MINUTES_PER_GAME_DAY * 60))` hours.
4. Broadcast current game hour to all clients every 60 real seconds via `RemoteEvent "GameTimeUpdate"`.
5. Client uses game hour to trigger zone ambient audio switch (day → night BGM crossfade).
6. `NPCManager` listens to `GameTimeUpdate` and runs schedule checks.
7. Use `TweenService` on `Lighting.Brightness` and `Lighting.Ambient` Color3 for smooth dawn/dusk transitions.

---

## Phase 7 — Social Systems

---

### TASK-070 — Relationship System

**Goal:** Allow two players to mutually form, view, and remove relationships. Validate constraints (1 marriage max, require Cincin item). Display badge on player nameplate.

**Deliverable:** `ReplicatedStorage/Modules/RelationshipModule` (ModuleScript), `ServerScriptService/RelationshipServer` (Script)

**Depends on:** TASK-001, TASK-004, TASK-011

**Instructions:**
1. **RelationshipModule** (shared): expose `RelationshipModule.getRelationship(playerDataA, playerDataB)` → returns relationship type or nil.
2. **RelationshipServer** (Script):
   - On `SendRelationshipRequest` RemoteEvent (player, targetUserId, relationshipType):
     a. Validate target is in the same server (`Players:GetPlayerByUserId`).
     b. Validate `AssetConfig.Relationships[relationshipType]` exists.
     c. If `requireItem` set (e.g., Menikah requires Cincin): validate player has it in inventory; remove it.
     d. If `maxPerPlayer = 1` (Menikah): validate player has no existing marriage.
     e. Store a pending request in a server table `PendingRequests[targetUserId] = { from, type }`.
     f. Fire `RelationshipRequestReceived` RemoteEvent to target player.
   - On `AcceptRelationshipRequest` RemoteEvent (player):
     a. Check `PendingRequests[player.UserId]`.
     b. Add to both players' `data.relationships`.
     c. Fire `RelationshipFormed` RemoteEvent to both.
     d. Call `AchievementServer.check()` for both.
   - On `RemoveRelationship` RemoteEvent (player, targetUserId): remove from both players' data. Fire update to both.
3. Nameplate: after `RelationshipFormed`, fire `UpdateNameplate` to all players in server with the relationship icon to display above each involved player's head. Client uses `BillboardGui` on the character.

---

### TASK-071 — Leaderboard System

**Goal:** Maintain a server-side ordered leaderboard of top players by collectible count. Display top 3 on in-world billboard in KotaJogja. Update periodically.

**Deliverable:** `ServerScriptService/LeaderboardServer` (Script)

**Depends on:** TASK-004

**Instructions:**
1. Create `Script` in `ServerScriptService/LeaderboardServer`.
2. Every 5 minutes: collect `{ username, collectibleCount }` for all current players in server. Sort descending by count. Store top 10.
3. Also use `DataStoreService:GetOrderedDataStore("CollectibleLeaderboard")` to maintain a global leaderboard across servers. On player data save, update their entry: `orderedStore:SetAsync(player.UserId, data.collectibleCount)`.
4. Every 5 minutes, fetch top 10 from global ordered store. Update the `BillboardGui` SurfaceGui on the `Leaderboard` Part in `Workspace/Map/Zones/KotaJogja/Leaderboard`. Display: rank, username, count.
5. Expose `LeaderboardServer.getTop10()` for the GaleriGui to display.

---

### TASK-072 — Galeri System

**Goal:** Each player has a personal display room (Galeri) for collectible items. Other players can visit. Collectibles placed on pedestals, glow by rarity.

**Deliverable:** `ServerScriptService/GaleriServer` (Script), `StarterPlayerScripts/GaleriController` (LocalScript)

**Depends on:** TASK-004, TASK-011, TASK-061

**Instructions:**
1. **GaleriServer**:
   - Each player's Galeri is a private server-side folder `Workspace/Galeris/[userId]` containing cloned pedestal models (from a `ReplicatedStorage/Prefabs/GaleriPedestal` prefab).
   - Number of pedestals = number of distinct collectibles in `data.inventory` with type "Koleksi".
   - On `PlaceCollectible` RemoteEvent (player, itemId, pedestalSlot): validate item is Koleksi type; update `data.galeriLayout[pedestalSlot] = itemId`; update the visual pedestal model.
   - On `OpenGaleri` RemoteEvent (requestingPlayer, targetUserId): teleport requesting player to `data.galeriLayout` view. Fire `GaleriData` RemoteEvent to requesting player with layout. Fire `GaleriVisited` notification to target player.
2. Rarity glow: apply a `SelectionBox` or `PointLight` color to pedestal based on item rarity. Color values from `AssetConfig.Rarity` (add this table).
3. **GaleriController** (client): render `GaleriGui` showing the layout grid. Allow drag-to-assign for own Galeri. Read-only for visited Galeris.

---

## Phase 8 — All UI Systems

---

### TASK-080 — HUD (Main Heads-Up Display)

**Goal:** Always-visible HUD showing: stamina bar, morality icon/label, active quest objective, currency (Rp + Gold), compass, and hotbar. Responsive to both mobile and desktop.

**Deliverable:** `StarterGui/HUDGui` (ScreenGui, script-driven layout)

**Depends on:** TASK-010, TASK-012, TASK-014, TASK-050, TASK-040

**Instructions:**
1. Create `ScreenGui` named `HUDGui` in `StarterGui`. Set `ResetOnSpawn = false`.
2. Use a `LocalScript` inside it (or `HotbarController`) to build and update all elements.
3. **Layout zones** (all built by script via `Instance.new`):
   - Top-left: active quest name + first incomplete objective. Max 2 lines. Tap to expand QuestGui.
   - Top-center: directional compass (a `Frame` with a rotating inner `ImageLabel` using compass texture).
   - Top-right: `"Rp [formatted]  ◆ [gold]"` text. Tap to see transaction history.
   - Bottom-left: morality icon (ImageLabel) + tier label (TextLabel). Color matches tier.
   - Bottom-center: stamina bar (`Frame` with inner `Frame` scaled by stamina fraction). Color: green > yellow > red.
   - Bottom-right: `[Menu]` and `[Inventory]` buttons.
   - Bottom-full-width: hotbar (4–8 slots depending on `data.hotbarSize`). Each slot is a `TextButton` with `ImageLabel` for item icon, `TextLabel` for count.
4. All elements use `UDim2` with scale values (not offset) so they resize correctly across all screen sizes.
5. Mobile: hotbar slot size minimum 60px. All tap targets minimum 44px.
6. Update functions: `updateStamina(value)`, `updateMorality(tier)`, `updateCurrency(rp, gold)`, `updateQuestObjective(text)` — called by events from server.

---

### TASK-081 — Inventory GUI

**Goal:** Full inventory panel with filter tabs, item grid, tooltip on hover/hold, and action menu (use, equip, assign to hotbar, drop).

**Deliverable:** `StarterGui/InventoryGui` (ScreenGui)

**Depends on:** TASK-011, TASK-012, TASK-080

**Instructions:**
1. Create `ScreenGui/InventoryGui` in `StarterGui`. Hidden by default (`Enabled = false`). Toggle via Inventory button in HUD.
2. Build via `LocalScript` inside:
   - Filter tab bar: All / Makanan / Kosmetik / Koleksi / Senjata / Bahan. Clicking a tab re-renders grid filtered by type.
   - Item grid: `UIGridLayout` inside a `ScrollingFrame`. Each cell: 80×80 `ImageButton` with item icon, rarity color border, count label.
   - Desktop hover: show `TooltipFrame` near cursor with item name, type, rarity, description (localized), stats.
   - Mobile long-press (0.5s `TapGesture`): show same tooltip.
   - Click/tap item: show action menu `Frame` with buttons: "Gunakan" (if consumable), "Pakai" (if equippable), "Hotbar" (shows slot selector), "Buang".
3. On `SyncInventory` event: re-render grid from updated cache.
4. Slot counter footer: `"[used]/[max] slot — [Upgrade text if applicable]"`.

---

### TASK-082 — Shop GUI

**Goal:** Shop panel with Buy and Sell tabs. Shows items, prices (with morality discount applied), confirm dialog.

**Deliverable:** `StarterGui/ShopGui` (ScreenGui)

**Depends on:** TASK-020, TASK-080

**Instructions:**
1. Hidden by default. Opens on `OpenShop` RemoteEvent from server (which passes shop config + player morality).
2. Tab bar: show "Beli" tab only if `shop.type != "SellOnly"`. Show "Jual" tab only if `shop.type != "BuyOnly"`.
3. **Beli tab**: grid of `shop.stock` items. Each cell shows: icon, localized name, price (with discount badge if morality qualifies). Click → confirm dialog "Beli [item] seharga Rp [price]?" → fire `PurchaseItem` RemoteFunction.
4. **Jual tab**: grid of player's own inventory (filtered by `shop.acceptedTypes`). Each shows sell price (`basePrice * sellMultiplier`). Click → confirm dialog → fire `SellItem` RemoteFunction.
5. Show response from server: if success, play buy/sell SFX + update currency HUD. If refused (low morality), show "NPC menolakmu" message.
6. Close button + clicking outside closes the panel.

---

### TASK-083 — Dialog GUI

**Goal:** NPC conversation panel. Shows NPC portrait, name, localized text with typewriter effect, and choice buttons. Supports morality-gated choices.

**Deliverable:** `StarterGui/DialogGui` (ScreenGui)

**Depends on:** TASK-031, TASK-080

**Instructions:**
1. Hidden by default. Opens on `DialogOpen` RemoteEvent.
2. Panel anchored to screen bottom. Height ~30% of screen.
3. Left side: NPC portrait (`ImageLabel`, 128×128). Right side: NPC name (`TextLabel`, bold) + dialog text (`TextLabel`).
4. Typewriter effect: `LocalScript` reveals one character per `0.03s` using `string.sub`. Skip remaining on any tap/click.
5. Choice buttons: appear below text after typewriter completes. Vertical stack. Each button: `TextButton` min 44px height. Fire `DialogChoice` RemoteEvent on click.
6. No "Close" button during dialog — only choices drive flow. If `choices` is empty and text complete, auto-close after 2s or on tap.
7. Player movement disabled while dialog is open (`LocalScript` sets `Humanoid.WalkSpeed = 0`; restore on close).
8. Mobile: panel expands to 40% screen height; buttons larger.

---

### TASK-084 — Quest & Task GUI

**Goal:** Quest log panel listing active + completed quests. Task board panel showing daily and weekly tasks with progress bars and claim buttons.

**Deliverable:** `StarterGui/QuestGui` (ScreenGui), `StarterGui/TaskGui` (ScreenGui)

**Depends on:** TASK-040, TASK-041, TASK-080

**Instructions:**
1. **QuestGui**: scrollable list. Two sections: "Aktif" (active quests) and "Selesai" (completed). Each entry: quest title, type badge (Main/Side), first incomplete objective with progress fraction, reward preview icons.
2. On `QuestUpdate` event: re-render list.
3. **TaskGui**: two tabs: "Harian" and "Mingguan". Each task row: task name, progress bar (`[x]/[total]`), reward icon, "Klaim" button (active only if `completed == true` and `claimed == false`). Reroll button on harian tasks (shows cost, disabled if limit reached). Clicking "Klaim" fires `ClaimTask` RemoteEvent.
4. Both GUIs open from HUD buttons or dedicated tap zones.
5. Task reset countdown: show `"Reset dalam [HH:MM]"` using client-side `os.clock()` countdown to next reset time.

---

### TASK-085 — Travel GUI (Peta Perjalanan)

**Goal:** Full-screen Indonesia archipelago map for selecting travel destination. Show unlocked (green) vs locked (gray) zones. Display ticket cost and Berangkat button.

**Deliverable:** `StarterGui/TravelGui` (ScreenGui)

**Depends on:** TASK-061, TASK-014, TASK-080

**Instructions:**
1. Hidden by default. Opens on `OpenTravelMap` event from `TravelController`.
2. Background: the Indonesia archipelago 2D illustration (from ASSETS §4.4).
3. Each island group is a clickable `ImageButton` (use `AssetConfig.Places` to know all islands).
4. On island click: expand to show zone dots for that island. Each dot: green = unlocked, gray = locked, yellow = current zone.
5. On zone dot click: show bottom panel with zone name, region, ticket cost (Bandara or Ferry price from `AssetConfig.Travel`), cultural note blurb, "Berangkat" button. If locked, show instead "Selesaikan [questName] untuk membuka zona ini."
6. Pinch-to-zoom on mobile: use `UIS.TouchPinch` to scale the map `Frame`.
7. "Berangkat" fires `TeleportToPlace` or `FerryTravel` RemoteEvent → close GUI → show loading screen.

---

### TASK-086 — Social, Achievement, Galeri & Login Streak GUIs

**Goal:** Build the remaining player-facing panels: social/relationship panel, achievement grid, Galeri layout editor, and login streak popup.

**Deliverable:** `StarterGui/SocialGui`, `StarterGui/AchievementGui`, `StarterGui/GaleriGui`, `StarterGui/LoginStreakGui`

**Depends on:** TASK-070, TASK-051, TASK-072, TASK-052, TASK-080

**Instructions:**
1. **SocialGui**: list of current relationships with icon + type label + player username + "Hapus" button. "Cari Pemain" input to find online players and send requests. Pending requests notification badge.
2. **AchievementGui**: icon grid (6 columns). Locked = gray silhouette + lock icon. Unlocked = full color icon + completion date. Tap to see name, description, reward. Progress bar on partially-completed achievements (e.g., "67/100 musuh dikalahkan").
3. **GaleriGui**: grid of pedestal slots. Own Galeri: drag item from inventory to slot. Visited Galeri: read-only. Show player name + collectible count at top. "Suka" button fires `GaleriLike` RemoteEvent.
4. **LoginStreakGui**: popup on join. Shows streak number (large, animated count). Today's reward with icon. Next milestone preview ("Hari ke-7: ◆ 1 Gold"). "Klaim!" button → fires `ClaimLoginStreak` (server auto-granted, so this just closes the popup). Auto-dismiss 5s.

---

## Phase 9 — Audio & VFX

---

### TASK-090 — Audio Manager

**Goal:** Play zone BGM and ambient sounds, crossfade on zone change. Play SFX at correct positions. All audio asset IDs come from AssetConfig.

**Deliverable:** `StarterPlayerScripts/AudioManager` (LocalScript)

**Depends on:** TASK-001, TASK-060

**Instructions:**
1. Create `LocalScript` in `StarterPlayerScripts/AudioManager`.
2. Create two `Sound` objects in `SoundService` for BGM (A/B crossfade pattern): `BGM_A` and `BGM_B`. On zone change, play new track on the inactive one, `TweenService` fade the active one out over 2s and new one in, then swap.
3. Zone day/night: listen to `GameTimeUpdate` event. If hour 6–18 → play zone `bgmId`; else → play island night theme. Transition with crossfade.
4. Ambient loop: a third `Sound` object plays `zone.ambientSound` in looping mode. Swap on zone change with 1s crossfade.
5. SFX: expose `AudioManager.playSFX(sfxId, position?)`. If `position` given, create a temporary `Sound` parented to a `Part` at that position (spatial audio). Auto-destroy after sound ends. If no position, play from `SoundService` directly.
6. All SFX IDs referenced from `AssetConfig.Audio.SFX`. Other scripts call `AudioManager.playSFX(AssetConfig.Audio.SFX.QuestComplete)` etc. via a `BindableEvent`.
7. Respect `SoundService.RespectFilteringEnabled = true`.

---

### TASK-091 — VFX Manager

**Goal:** Trigger particle effects and screen feedback for combat, morality, UI events, and world events from a single managed system.

**Deliverable:** `StarterPlayerScripts/VFXManager` (LocalScript), `ReplicatedStorage/Prefabs/VFX/` folder with particle emitter templates

**Depends on:** TASK-013, TASK-050

**Instructions:**
1. Create `LocalScript` in `StarterPlayerScripts/VFXManager`.
2. Store `ParticleEmitter` template instances in `ReplicatedStorage/Prefabs/VFX/` (one `Part` per effect, with `ParticleEmitter` configured).
3. Expose via `BindableEvent` "PlayVFX": `{ effectId, position?, attachTo? }`.
4. `effectId` maps to prefab name. Clone the prefab, parent to `Workspace`, emit once (`ParticleEmitter:Emit(count)`), then `Debris:AddItem(clone, 3)`.
5. Screen effects (stamina depleted vignette, morality pulse): use a full-screen `Frame` in a `ScreenGui` with `BackgroundTransparency` tweened in/out. Red for stamina depleted, gold for morality rise, dark for morality fall.
6. On `CombatHit` RemoteEvent from server: play hit spark VFX at the hit part's position.
7. On `MoralityChanged` event (delta > 0): play MoralityRise VFX at player position. On delta < 0: MoralityFall.
8. On `AchievementUnlocked`: play achievement radiance VFX centered on screen (screen-space, not world).

---

## Phase 10 — Event System & Polish

---

### TASK-095 — Festival Event Manager

**Goal:** Detect real-world date ranges matching Indonesian holidays. Activate event-specific tasks, event currency, event shop stock, and zone decorations.

**Deliverable:** `ServerScriptService/EventManager` (Script)

**Depends on:** TASK-001, TASK-041, TASK-020

**Instructions:**
1. Create `Script` in `ServerScriptService/EventManager`.
2. On server start, check current real-world date `os.date("!*t")` (UTC).
3. Compare against `AssetConfig.Events` date ranges (add `startMonth`, `startDay`, `endMonth`, `endDay` fields to each event config).
4. If an event is active: set `ActiveEvent = eventConfig`. Fire `EventActive` RemoteEvent to all players with event name + currency info.
5. `TaskServer` checks `ActiveEvent` when generating daily tasks — adds event-specific task templates to the daily pool.
6. `ShopServer` checks `ActiveEvent` — adds event shop items to a special "Event" shop that appears during the event.
7. Zone decorations: event-specific `Model` instances in `ReplicatedStorage/Prefabs/EventDecor/[eventId]/` are cloned and placed in the relevant zones (defined in `AssetConfig.Events[id].decorZones`) at event start, removed at end.
8. Event currency (`eventCurrencies` in player data): `CurrencyModule` extended to handle event currency type.

---

### TASK-096 — Mobile Optimization Pass

**Goal:** Audit all GUIs and controllers for mobile usability. Ensure all tap targets meet 44px minimum, touch gestures work, no desktop-only controls block progression.

**Deliverable:** Updates across all LocalScripts and ScreenGuis

**Depends on:** TASK-080 through TASK-086, TASK-012

**Instructions:**
1. Use `UserInputService.TouchEnabled` to detect mobile. Store this in a shared `LocalScript` constant accessible by all controllers.
2. For mobile: hide desktop keybind hint labels. Show mobile gesture hints instead.
3. Audit every `TextButton` and `ImageButton` — if `AbsoluteSize.Y < 44` on a 360px-wide screen, increase size.
4. Hotbar: on mobile, each slot must be at minimum 60×60px. Verify with `GuiService:IsTenFootInterface()` for console detection too.
5. `CameraController`: on mobile, enable `UserInputService.TouchRotateSensitivity` for right-side drag camera rotation. Left side thumbstick handled by Roblox default. Ensure `CameraMode` is set correctly.
6. Dialog choices: on mobile, choice buttons stack vertically and ScrollingFrame is enabled if more than 3 choices.
7. Travel map: test pinch-to-zoom on mobile simulator. Dots must be at least 30px diameter.

---

### TASK-097 — Performance & Streaming Config

**Goal:** Configure Roblox Streaming Enabled correctly per Place. Ensure NPCs and props outside the player's stream area are not loaded client-side. Define stream radius.

**Deliverable:** Configuration in each Place's `Workspace` settings + `ZoneManager` adjustments

**Depends on:** TASK-060, TASK-030

**Instructions:**
1. In Roblox Studio for each Place: enable `Workspace.StreamingEnabled = true`. Set `StreamingMinRadius = 64` and `StreamingTargetRadius = 256`.
2. Zone folders in `Workspace/Map/Zones/` are naturally streamed in/out by Roblox based on proximity.
3. `NPCManager`: add a check — only run NPC schedule routines for zones where at least one player is present (`GameManager.playerZone` lookup). Pause tween updates for NPCs in empty zones to save server performance.
4. `WorldEventServer`: only spawn events in zones with at least 1 player.
5. In `ZoneManager`: when detecting player zone via part overlap, add a short debounce (0.5s) before firing zone change — prevents flicker at zone boundaries.
6. Debris cleanup: any dynamically spawned items (loot drops, event props, projectiles) must use `Debris:AddItem(instance, maxLifetime)` to prevent accumulation.

---

### TASK-098 — Localization Table Population

**Goal:** Fill the Roblox `LocalizationTable` CSV with all string keys used across the game. Indonesian as default, English as secondary. All keys used in code must be present.

**Deliverable:** `LocalizationTable` asset in Roblox Studio (can export/import as CSV)

**Depends on:** TASK-003, all UI tasks

**Instructions:**
1. Export the `LocalizationTable` CSV template from Studio (or create manually).
2. Required columns: `Key`, `id` (Indonesian), `en` (English).
3. Populate all keys referenced in scripts using pattern `"ui.*"`, `"quest.*"`, `"item.*"`, `"npc.*"`, `"shop.*"`, `"task.*"`, `"zone.*"`, `"rel.*"`, `"morality.*"`, `"ach.*"`, `"event.*"`, `"dialog.*"`.
4. For Jawa MVP: minimum required keys = all `AssetConfig` entries' `nameKey` and `descKey` values for Jawa zones + Chapter 1–4 quests + all items in Jawa shop stocks + all 7 weapons + all NPC names.
5. Write a helper script `tools/CheckMissingKeys.lua` that iterates all `AssetConfig` entries and prints any `nameKey` or `descKey` that is not found in the LocalizationTable. Run this after every content addition.
6. Import updated CSV back into Studio via `LocalizationTable > Import`.

---

## Task Summary by Phase

| Phase | Tasks | Focus |
|---|---|---|
| 0 — Foundation | TASK-001 to 005 | AssetConfig, bootstrap, data layer |
| 1 — Core Mechanics | TASK-010 to 014 | Stamina, inventory, hotbar, combat, currency |
| 2 — Economy | TASK-020 to 021 | Shop, crafting |
| 3 — NPC & Dialog | TASK-030 to 031 | NPC spawning by script, branching dialog |
| 4 — Quest & Task | TASK-040 to 041 | Quest progression, daily/weekly tasks |
| 5 — Progression | TASK-050 to 052 | Morality, achievements, login streak |
| 6 — World & Travel | TASK-060 to 063 | Zones, TeleportService, world events, day/night |
| 7 — Social | TASK-070 to 072 | Relationships, leaderboard, Galeri |
| 8 — UI | TASK-080 to 086 | All ScreenGuis, HUD, all panels |
| 9 — Audio & VFX | TASK-090 to 091 | BGM crossfade, SFX, particles |
| 10 — Polish | TASK-095 to 098 | Events, mobile audit, streaming, localization |

**Build order for Jawa MVP:**
`001 → 002 → 003 → 004 → 005 → 010 → 011 → 012 → 013 → 014 → 020 → 021 → 030 → 031 → 040 → 041 → 050 → 060 → 063 → 080 → 081 → 082 → 083 → 084 → 090 → 091 → 096 → 098`

**Recommended parallel work (can split between devs):**
- Dev A: TASK-001 → 005 → 010 → 011 → 013 → 014
- Dev B: TASK-030 → 031 → 040 → 050
- Dev C: TASK-080 → 081 → 082 → 083 (UI focus)
