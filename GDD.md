# Game Design Document — Hikayat Pemuda

**Engine:** Roblox  
**Genre:** Open-World Narrative RPG  
**Platform:** Desktop, Mobile (all Roblox-supported platforms)  
**Localization:** Indonesian (primary), English  
**Version:** 0.1 (draft)

---

## 1. Overview

Hikayat Pemuda is a story-driven open-world RPG set in a fictionalized Indonesian countryside. Inspired by Red Dead Redemption 2, the game emphasizes narrative depth, player morality, NPC relationship systems, and emergent exploration. Players take on the role of a young Indonesian man navigating life, community, and conflict through quests, trade, and social bonds.

---

## 2. Core Pillars

| Pillar | Description |
|---|---|
| **Story First** | Main quest drives narrative with cinematic pacing |
| **Moral Weight** | Every action shifts morality; world reacts accordingly |
| **Living World** | NPCs have routines, react to player reputation |
| **Social Play** | Player-to-player relationships enrich the experience |
| **Accessible** | Fully playable on mobile and desktop with native Roblox UI |

---

## 3. Story & Narrative

### 3.1 Setting

A semi-open rural Indonesian world — villages, forests, rivers, markets, and sacred sites. Time period is early modern (pre-internet, kampung life aesthetic).

### 3.2 Main Character

The player character is a young man (pemuda) from a struggling family. He must navigate personal growth, community duty, and moral choices.

### 3.3 Themes

- Responsibility and coming-of-age
- Community vs. self-interest
- Consequence of reputation

---

## 4. Quest System

### 4.1 Main Quest (Kisah Utama)

- Linear story chapters unlocked sequentially
- Each chapter has objectives, cutscene triggers, and morality-affecting choices
- Completing main quests unlocks new world areas and NPCs
- Progress is saved per player (DataStore)

**Chapter structure:**
```
Chapter → Scene(s) → Objective(s) → Choice Point → Outcome → Next Chapter
```

### 4.2 Side Quests (Misi Sampingan)

- Available from NPCs scattered in the world
- Rewards: Rupiah, items, morality points, or relationship XP
- Types:
  - **Gather** — collect X items and return
  - **Deliver** — bring item from A to B
  - **Protect** — escort NPC to destination
  - **Trade** — buy specific item and sell to quest-giver
  - **Craft** — craft and deliver specific item

- Side quests do not gate main story progress
- Some side quests unlock only if morality threshold is met (good or bad)

### 4.3 Quest Tracker UI

- Native Roblox ScreenGui with quest log panel
- Active quest shown in HUD corner
- Mobile: collapsed by default, tap to expand
- Desktop: always visible, toggle with keybind

---

## 5. Open World

### 5.1 World Zones

| Zone | Description | Unlock Condition |
|---|---|---|
| Kampung Awal | Starting village, tutorial area | Default |
| Pasar Besar | Main market hub | Chapter 1 complete |
| Hutan Larangan | Dangerous forest, rare resources | Chapter 2 complete |
| Tepi Sungai | River area, fishing, hidden quests | Default |
| Bukit Tua | Remote hilltop, sacred site | Chapter 3 complete |

### 5.2 Exploration

- Players can roam freely within unlocked zones
- Hidden collectibles, lore items, and secret NPCs placed throughout
- No minimap by default; directional compass and landmark icons only (immersive)
- Optional: player can buy "Peta" (map item) from shop to reveal zone layout

### 5.3 World Events

Random world events spawn periodically:
- Merchant attacked by bandits (intervene = morality up)
- Rare ingredient spawn
- NPC in distress
- Festival event (time-limited, cosmetic rewards)

---

## 6. NPC System

### 6.1 NPC Types

| Type | Behavior |
|---|---|
| **Quest Giver** | Offers main/side quests |
| **Merchant** | Runs shops |
| **Ambient** | Gives lore, reacts to morality |
| **Enemy** | Hostile; spawns in specific zones |
| **Social** | Can form player relationships |

### 6.2 NPC Interaction

- Uses **Roblox ProximityPrompt** as primary interaction method
- On approach: prompt appears (e.g., "Bicara", "Beli", "Serang")
- Interaction opens dialog GUI or shop GUI

### 6.3 NPC Routine

- NPCs move between locations based on time-of-day (day/night cycle)
- Example: warung owner opens shop at morning, goes home at night

### 6.4 Morality Reaction

| Morality Level | NPC Reaction |
|---|---|
| Sangat Baik (90–100) | Warm greeting, discount offers, extra dialog |
| Baik (60–89) | Friendly, normal prices |
| Netral (40–59) | Cautious, neutral |
| Buruk (20–39) | Suspicious, may refuse service |
| Sangat Buruk (0–19) | Hostile, flee or attack, merchants refuse |

---

## 7. Morality System

### 7.1 Morality Scale

- Range: 0–100 (default start: 50)
- Displayed as label + icon in HUD (not raw number)

| Range | Label | Icon Color |
|---|---|---|
| 90–100 | Pahlawan | Gold |
| 60–89 | Baik Hati | Green |
| 40–59 | Biasa | Gray |
| 20–39 | Nakal | Orange |
| 0–19 | Penjahat | Red |

### 7.2 Morality Events

**Morality increases:**
- Help NPC in distress (+5 to +15)
- Complete good-aligned quests (+5 to +20)
- Donate to NPC (+2)
- Return stolen item (+10)

**Morality decreases:**
- Attack innocent NPC (−10 to −20)
- Steal from shop (−15)
- Abandon quest (−5)
- Complete bad-aligned quests (−5 to −20)

### 7.3 Persistent Effects

- Morality persists per player (DataStore)
- Changes unlock/lock quest options and NPC reactions
- Morality badge visible on player profile

---

## 8. Combat System

### 8.1 Weapons

No firearms. Melee and ranged only.

| Weapon | Type | Range | Damage Tier |
|---|---|---|---|
| Kepalan (Punch) | Melee | Very Short | Low |
| Kayu Balok | Melee | Short | Medium |
| Pisau | Melee | Short | Medium-High |
| Ketapel (Slingshot) | Ranged | Medium | Low-Medium |

### 8.2 Combat Mechanics

- Simple click-to-attack on desktop, tap-to-attack on mobile
- Each weapon has cooldown and stamina cost
- Attacking innocents triggers morality penalty
- Enemy NPCs have health bars (BillboardGui above head)
- Downed enemies drop loot (items, Rupiah)

### 8.3 Stamina

- Stamina pool depletes on: attack, sprint, heavy actions
- Stamina recovers over time or instantly with food/drink items
- Stamina bar shown in HUD

---

## 9. Inventory System

### 9.1 Item Types

| Type | Use | Example |
|---|---|---|
| **Makanan/Minuman** | Consume to restore stamina | Nasi Bungkus, Es Teh |
| **Kosmetik/UGC** | Equip to change appearance | Baju Batik, Peci |
| **Koleksi** | Display item, tradeable, show-off | Koin Langka, Foto Jadoel |
| **Senjata** | Equip to combat slot | Pisau, Kayu Balok |
| **Bahan** | Craft into other items | Beras, Benang, Kayu |

### 9.2 Inventory UI

- Grid-based panel, opens via button or keybind
- Filter tabs: All / Makanan / Kosmetik / Koleksi / Senjata / Bahan
- Item tooltip on hover/hold: name, type, description, stats
- Mobile: tap-and-hold for tooltip, tap for action menu
- Max inventory slots: base 20, expandable via upgrade (Rupiah cost)

### 9.3 Item Rarity

| Rarity | Color | Notes |
|---|---|---|
| Biasa | White | Common drops |
| Tidak Biasa | Green | Side quest rewards |
| Langka | Blue | Rare world spawn |
| Epik | Purple | Crafted or event |
| Legenda | Gold | Special quests, Gold currency |

---

## 10. Crafting System

### 10.1 Crafting UI

- Accessible from inventory panel or crafting station NPC/object
- Shows recipe list, required ingredients, output item
- "Buat" button grayed out if ingredients insufficient

### 10.2 Recipes

Defined in **AssetConfig** (see Section 17). Devs add recipes via config only.

Example recipe structure:
```lua
{
    output = "NasiBungkus",
    outputAmount = 1,
    ingredients = {
        { id = "Beras", amount = 2 },
        { id = "Daun_Pisang", amount = 1 },
    },
    craftTime = 3, -- seconds
}
```

### 10.3 Crafting Categories

- Food/Drink crafting
- Weapon crafting (basic repair/upgrade)
- Cosmetic crafting (requires special ingredients)

---

## 11. Hotbar System

### 11.1 Design

- Horizontal bar at bottom of screen
- Default: 4 slots
- Upgradable: up to 8 slots (paid with Rupiah or Gold)
- Each slot can hold any equippable/consumable item

### 11.2 Slot Behavior

- Click/tap slot to use item (consume food, equip weapon/cosmetic)
- Drag-and-drop from inventory to hotbar (desktop)
- Mobile: long-press inventory item → assign to slot
- Active weapon slot highlighted with border

### 11.3 Hotbar Keybinds (Desktop)

| Key | Action |
|---|---|
| 1–8 | Select hotbar slot |
| Q | Previous slot |
| E | Next slot |
| F | Use/equip selected |

### 11.4 Hotbar on Mobile

- Fixed at screen bottom with touch targets sized ≥ 44px
- Slot number shown as small label
- Swipe left/right to scroll if more than 4 visible

---

## 12. Currency System

### 12.1 Currencies

| Currency | Symbol | Source | Use |
|---|---|---|---|
| **Rupiah** | Rp | Quests, selling, looting | Most purchases, upgrades |
| **Gold** | ◆ | Special quests, rare drops, Robux exchange | Premium items, rare cosmetics, slot upgrades |

### 12.2 Wallet UI

- Shown in HUD top-right: `Rp 12.500  ◆ 3`
- Formatted with Indonesian number format (`.` as thousand separator)
- Tap/click to see transaction history (last 10 transactions)

### 12.3 Economy Balance

| Transaction | Amount |
|---|---|
| Basic side quest reward | Rp 500–2.000 |
| Main quest chapter reward | Rp 5.000–20.000 |
| Common item sell price | Rp 100–500 |
| Rare item sell price | Rp 1.000–10.000 |
| Hotbar slot upgrade (1 slot) | Rp 10.000 or ◆ 1 |
| Inventory slot upgrade (5 slots) | Rp 5.000 |

---

## 13. Shop System

### 13.1 Shop Types

| Type | Buy From Shop | Sell To Shop |
|---|---|---|
| Beli Saja | Yes | No |
| Jual Saja | No | Yes |
| Beli & Jual | Yes | Yes |

### 13.2 Shop Categories

| Category | Accepted Items |
|---|---|
| Warung Makan | Makanan/Minuman only |
| Toko Pakaian | Kosmetik/UGC only |
| Toko Senjata | Senjata + Bahan |
| Toko Umum | All item types |

### 13.3 Shop UI

- ProximityPrompt triggers shop open
- Tab layout: "Beli" tab / "Jual" tab (only show relevant tabs per shop type)
- Item grid with price labels
- Confirm dialog before purchase/sale
- NPC with Sangat Buruk morality reaction: shop closes, player refused

### 13.4 Dynamic Pricing

- Shops can have morality-based discounts (configured in AssetConfig)
- Example: Sangat Baik morality = 10% discount at certain shops

---

## 14. Relationship System

### 14.1 Player-to-Player Relationships

Relationships are social badges between two players (mutual opt-in).

| Relationship | How to Earn | Badge Display |
|---|---|---|
| Sahabat (Bestie) | Both players choose "Jadikan Sahabat" | 💛 |
| Rival | Both agree to rivalry status | ⚔️ |
| Menikah (Married) | Requires "Cincin" item + both consent | 💍 |
| Saudara (Sibling) | Mutual request | 🤝 |
| Musuh | One player flags, other accepts | 💀 |

### 14.2 Relationship UI

- Visible on player nameplate above character
- Viewable on player profile card
- Relationship list in social menu

### 14.3 Relationship Effects

- Sahabat: shared quest objective tracking (can see each other's active quest marker)
- Rival: PvP interaction unlocked between them in non-safe zones
- Menikah: shared inventory view (read-only), appear on each other's profile
- Musuh: enemy nameplate highlight

### 14.4 Relationship Management

- Max 1 marriage, unlimited others
- Remove relationship via social menu → confirm dialog
- Roblox moderation rules apply to all relationship naming/display

---

## 15. UI/UX Design

### 15.1 Design Principles

- Use native Roblox UI components as base (ScreenGui, Frame, TextLabel, ImageLabel, ProximityPrompt)
- Extend with custom styling layered on top
- All interactive elements must meet minimum touch target size (44×44px) for mobile
- Text minimum size 14px on all platforms
- UI scales using `UIScale` and `UISizeConstraint`

### 15.2 Screen Layout

```
┌─────────────────────────────────────────────────┐
│ [Quest]            [Compass]       [Rp]  [◆]    │
│                                                  │
│                  (Game World)                    │
│                                                  │
│ [Morality]  [Stamina]          [Menu] [Inventory]│
│         [1][2][3][4]  (Hotbar)                  │
└─────────────────────────────────────────────────┘
```

### 15.3 Mobile Adaptations

| Element | Desktop | Mobile |
|---|---|---|
| Hotbar | Bottom-center | Bottom-center, larger tap areas |
| Inventory | Click button or I key | Tap button |
| Quest log | Always visible toggle | Hidden, tap to show |
| Camera | Mouse look | Gyro or touch drag |
| Movement | WASD | Roblox default thumbstick |
| Interact | ProximityPrompt (E key) | ProximityPrompt (tap button) |

### 15.4 Dialog System

- Dialog box anchored bottom of screen
- NPC portrait on left, text on right
- Continue button / choice buttons
- Auto-scales text for mobile readability
- Animated text reveal (typewriter effect)

---

## 16. Localization

Roblox native localization system (`LocalizationService` + `LocalizationTable`).

### 16.1 Supported Languages

| Code | Language |
|---|---|
| `id` | Bahasa Indonesia (primary) |
| `en` | English |

### 16.2 Implementation

- All UI strings go through `LocalizationService:GetTranslatorForLocalPlayer()`
- String keys defined in `LocalizationTable` (CSV or Roblox Studio table editor)
- Default fallback: Bahasa Indonesia if key missing in English table
- NPC dialog lines stored as localization keys, not raw strings

### 16.3 Key Naming Convention

```
ui.hotbar.slot          -- UI element
quest.main.ch1.title    -- quest name
item.nasibanget.name    -- item name
npc.parmin.greeting     -- NPC dialog
shop.confirm.buy        -- shop dialog
```

---

## 17. Asset Configuration (AssetConfig)

Single source of truth for all configurable values. Stored in `ReplicatedStorage/Config/AssetConfig.lua`.

```lua
-- ReplicatedStorage/Config/AssetConfig.lua

local AssetConfig = {}

-- ============================================================
-- ITEMS
-- ============================================================
AssetConfig.Items = {
    NasiBungkus = {
        id          = "NasiBungkus",
        nameKey     = "item.nasibungkus.name",
        descKey     = "item.nasibungkus.desc",
        type        = "Food",
        rarity      = "Biasa",
        imageId     = "rbxassetid://000000001",
        staminaGain = 30,
        basePrice   = 200,
    },
    Pisau = {
        id          = "Pisau",
        nameKey     = "item.pisau.name",
        descKey     = "item.pisau.desc",
        type        = "Weapon",
        rarity      = "Tidak Biasa",
        imageId     = "rbxassetid://000000002",
        damage      = 20,
        cooldown    = 0.8,
        staminaCost = 10,
        basePrice   = 1500,
    },
    -- Add more items here
}

-- ============================================================
-- WEAPONS (equippable definitions, references Items)
-- ============================================================
AssetConfig.Weapons = {
    Punch = {
        id          = "Punch",
        nameKey     = "item.punch.name",
        damage      = 8,
        cooldown    = 0.5,
        staminaCost = 5,
        range       = 4,
        animationId = "rbxassetid://000000010",
    },
    KayuBalok = {
        id          = "KayuBalok",
        nameKey     = "item.kayubalok.name",
        damage      = 15,
        cooldown    = 0.9,
        staminaCost = 12,
        range       = 5,
        animationId = "rbxassetid://000000011",
        itemRef     = "KayuBalok",
    },
    Pisau = {
        id          = "Pisau",
        nameKey     = "item.pisau.name",
        damage      = 20,
        cooldown    = 0.8,
        staminaCost = 10,
        range       = 4,
        animationId = "rbxassetid://000000012",
        itemRef     = "Pisau",
    },
    Ketapel = {
        id          = "Ketapel",
        nameKey     = "item.ketapel.name",
        damage      = 12,
        cooldown    = 1.2,
        staminaCost = 8,
        range       = 20,
        projectileSpeed = 80,
        animationId = "rbxassetid://000000013",
        itemRef     = "Ketapel",
    },
}

-- ============================================================
-- CRAFTING RECIPES
-- ============================================================
AssetConfig.Recipes = {
    {
        output       = "NasiBungkus",
        outputAmount = 1,
        ingredients  = {
            { id = "Beras",      amount = 2 },
            { id = "DaunPisang", amount = 1 },
        },
        craftTime    = 3,
    },
    -- Add more recipes here
}

-- ============================================================
-- SHOPS
-- ============================================================
AssetConfig.Shops = {
    WarungParmin = {
        id              = "WarungParmin",
        nameKey         = "shop.warungparmin.name",
        type            = "BuySell",   -- "BuyOnly" | "SellOnly" | "BuySell"
        acceptedTypes   = { "Food" }, -- nil = accept all
        npcName         = "Parmin",
        sellMultiplier  = 0.6,        -- player sells at 60% of base price
        moralityDiscount = {
            threshold = 90,
            discount  = 0.10,
        },
        stock           = { "NasiBungkus", "EsTeh", "RotiBasah" },
    },
    -- Add more shops here
}

-- ============================================================
-- NPCS
-- ============================================================
AssetConfig.NPCs = {
    Parmin = {
        id          = "Parmin",
        nameKey     = "npc.parmin.name",
        modelId     = "rbxassetid://000000020",
        shopId      = "WarungParmin",
        quests      = { "SQ_CariKayu_01" },
        dialogTree  = "Parmin_Main",
        schedule    = {
            { from = 6,  to = 20, location = "WarungParmin_Counter" },
            { from = 20, to = 6,  location = "Parmin_Home" },
        },
    },
    -- Add more NPCs here
}

-- ============================================================
-- QUESTS
-- ============================================================
AssetConfig.Quests = {
    MQ_Ch1_Awal = {
        id          = "MQ_Ch1_Awal",
        type        = "Main",
        titleKey    = "quest.main.ch1.title",
        descKey     = "quest.main.ch1.desc",
        objectives  = {
            { type = "Talk",     target = "Parmin",    count = 1 },
            { type = "Deliver",  item   = "Surat",     target = "PakRT" },
        },
        rewards     = {
            rupiah  = 5000,
            items   = { { id = "KayuBalok", amount = 1 } },
            morality = 10,
        },
        nextQuest   = "MQ_Ch1_Konflik",
    },
    SQ_CariKayu_01 = {
        id          = "SQ_CariKayu_01",
        type        = "Side",
        titleKey    = "quest.side.carikayu01.title",
        descKey     = "quest.side.carikayu01.desc",
        giverNPC    = "Parmin",
        objectives  = {
            { type = "Gather", item = "Kayu", count = 5 },
        },
        rewards     = {
            rupiah  = 800,
            morality = 5,
        },
    },
    -- Add more quests here
}

-- ============================================================
-- RELATIONSHIPS
-- ============================================================
AssetConfig.Relationships = {
    Sahabat  = { nameKey = "rel.sahabat",  icon = "rbxassetid://000000030", mutual = true  },
    Rival    = { nameKey = "rel.rival",    icon = "rbxassetid://000000031", mutual = true  },
    Menikah  = { nameKey = "rel.menikah",  icon = "rbxassetid://000000032", mutual = true, maxPerPlayer = 1, requireItem = "Cincin" },
    Saudara  = { nameKey = "rel.saudara",  icon = "rbxassetid://000000033", mutual = true  },
    Musuh    = { nameKey = "rel.musuh",    icon = "rbxassetid://000000034", mutual = true  },
}

-- ============================================================
-- MORALITY
-- ============================================================
AssetConfig.Morality = {
    Default = 50,
    Tiers   = {
        { min = 90,  max = 100, labelKey = "morality.pahlawan",  color = Color3.fromRGB(255, 215, 0)   },
        { min = 60,  max = 89,  labelKey = "morality.baikhati",  color = Color3.fromRGB(0, 200, 80)    },
        { min = 40,  max = 59,  labelKey = "morality.biasa",     color = Color3.fromRGB(180, 180, 180) },
        { min = 20,  max = 39,  labelKey = "morality.nakal",     color = Color3.fromRGB(255, 140, 0)   },
        { min = 0,   max = 19,  labelKey = "morality.penjahat",  color = Color3.fromRGB(200, 0, 0)     },
    },
}

-- ============================================================
-- HOTBAR
-- ============================================================
AssetConfig.Hotbar = {
    DefaultSlots = 4,
    MaxSlots     = 8,
    UpgradeCost  = function(currentSlots)
        -- cost increases per slot
        return { rupiah = 10000 * (currentSlots - 3) }
    end,
}

-- ============================================================
-- STAMINA
-- ============================================================
AssetConfig.Stamina = {
    Max           = 100,
    RegenRate     = 5,    -- per second when idle
    SprintCost    = 10,   -- per second while sprinting
}

-- ============================================================
-- CURRENCY
-- ============================================================
AssetConfig.Currency = {
    Rupiah = { key = "Rupiah", symbol = "Rp",  formatLocale = "id-ID" },
    Gold   = { key = "Gold",   symbol = "◆",   formatLocale = nil     },
}

-- ============================================================
-- WORLD ZONES
-- ============================================================
AssetConfig.Zones = {
    KampungAwal   = { id = "KampungAwal",  nameKey = "zone.kampungawal",  unlockQuest = nil              },
    PasarBesar    = { id = "PasarBesar",   nameKey = "zone.pasarbesar",   unlockQuest = "MQ_Ch1_Awal"    },
    HutanLarangan = { id = "HutanLarangan",nameKey = "zone.hutanlarangan",unlockQuest = "MQ_Ch2_Hutan"   },
    TepiSungai    = { id = "TepiSungai",   nameKey = "zone.tepisungai",   unlockQuest = nil              },
    BukitTua      = { id = "BukitTua",     nameKey = "zone.bukittua",     unlockQuest = "MQ_Ch3_Bukit"   },
}

-- ============================================================
-- AUDIO
-- ============================================================
AssetConfig.Audio = {
    BGM = {
        KampungAwal   = "rbxassetid://000000100",
        PasarBesar    = "rbxassetid://000000101",
        HutanLarangan = "rbxassetid://000000102",
        Combat        = "rbxassetid://000000103",
    },
    SFX = {
        Punch         = "rbxassetid://000000110",
        KayuHit       = "rbxassetid://000000111",
        PisauHit      = "rbxassetid://000000112",
        KetapelShoot  = "rbxassetid://000000113",
        ItemPickup    = "rbxassetid://000000114",
        QuestComplete = "rbxassetid://000000115",
        ShopBuy       = "rbxassetid://000000116",
        ShopSell      = "rbxassetid://000000117",
    },
}

return AssetConfig
```

---

## 18. Data Persistence

All player data saved via `DataStoreService`.

### 18.1 Player Save Schema

```lua
{
    version    = 1,
    rupiah     = 0,
    gold       = 0,
    morality   = 50,
    inventory  = {},          -- { itemId, amount, slot }
    hotbar     = {},          -- { slotIndex, itemId }
    hotbarSize = 4,
    inventorySize = 20,
    questProgress = {},       -- { questId, status, objectiveProgress }
    relationships = {},       -- { targetUserId, type }
    unlockedZones = { "KampungAwal", "TepiSungai" },
    completedQuests = {},
}
```

### 18.2 Auto-Save

- Auto-save on: quest completion, shop transaction, logout (`Players.PlayerRemoving`)
- Retry on save failure (up to 3 attempts)

---

## 19. Folder Structure (Roblox Studio)

```
game
├── ReplicatedStorage
│   ├── Config
│   │   └── AssetConfig          (ModuleScript)
│   ├── Modules
│   │   ├── ItemModule           (ModuleScript)
│   │   ├── QuestModule          (ModuleScript)
│   │   ├── MoralityModule       (ModuleScript)
│   │   ├── CurrencyModule       (ModuleScript)
│   │   ├── RelationshipModule   (ModuleScript)
│   │   └── LocalizationUtil     (ModuleScript)
│   └── RemoteEvents
│       ├── UpdateHotbar
│       ├── OpenShop
│       ├── QuestUpdate
│       └── MoralityChanged
├── ServerScriptService
│   ├── GameManager              (Script)
│   ├── DataManager              (Script)
│   ├── QuestServer              (Script)
│   ├── ShopServer               (Script)
│   ├── CombatServer             (Script)
│   ├── NPCManager               (Script)
│   └── RelationshipServer       (Script)
├── StarterPlayerScripts
│   ├── HotbarController         (LocalScript)
│   ├── InventoryController      (LocalScript)
│   ├── QuestHUD                 (LocalScript)
│   ├── DialogController         (LocalScript)
│   └── CameraController         (LocalScript)
├── StarterGui
│   ├── HUDGui                   (ScreenGui)
│   ├── InventoryGui             (ScreenGui)
│   ├── ShopGui                  (ScreenGui)
│   ├── QuestGui                 (ScreenGui)
│   ├── DialogGui                (ScreenGui)
│   └── SocialGui                (ScreenGui)
└── Workspace
    ├── Map
    │   ├── KampungAwal
    │   ├── PasarBesar
    │   └── ...
    └── NPCs
```

---

## 20. Out of Scope (v1)

- Firearms or gun combat
- Player vs. Player combat outside rival relationship + non-safe zones
- Guild/clan system
- Auction house
- Fishing minigame (world exists, mechanic deferred)
- Pet system
- Housing

---

## 21. Open Questions

- [x] Day/night cycle speed (real-time ratio vs. compressed) compressed
- [x] PvP zone boundaries — which zones allow rival combat? all
- [x] Gold → Robux exchange rate (monetization decision) yes, player can topup gold with robux but gold also can be earned by quest
- [ ] Max active side quests per player
- [x] Marriage dissolution mechanic when both player agree or when the admin dissolve them
- [x] Collectible display — dedicated room/display case or profile card only? leaderboard or dedicated in-game
