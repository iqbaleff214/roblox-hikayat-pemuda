# Game Design Document — Hikayat Pemuda

**Engine:** Roblox  
**Genre:** Open-World Narrative RPG  
**Platform:** Desktop, Mobile (all Roblox-supported platforms)  
**Localization:** Indonesian (primary), English  
**Version:** 0.1 (draft)

---

## 1. Overview

Hikayat Pemuda is a story-driven open-world RPG set across iconic Indonesian cities and islands. Inspired by Red Dead Redemption 2, the game emphasizes narrative depth, player morality, NPC relationship systems, and emergent exploration. Players take on the role of a young Indonesian man navigating life, community, and conflict through quests, trade, and social bonds.

A secondary mission of this game is **cultural education** — introducing players worldwide to Indonesian food, clothing, weapons, language, architecture, traditions, and regional identity through authentic, interactive storytelling.

---

## 2. Core Pillars

| Pillar | Description |
|---|---|
| **Story First** | Main quest drives narrative with cinematic pacing |
| **Moral Weight** | Every action shifts morality; world reacts accordingly |
| **Living World** | NPCs have routines, react to player reputation |
| **Social Play** | Player-to-player relationships enrich the experience |
| **Accessible** | Fully playable on mobile and desktop with native Roblox UI |
| **Cultural Pride** | Each zone authentically represents an Indonesian region's culture, food, and tradition |

---

## 3. Story & Narrative

### 3.1 Setting

The world spans multiple real Indonesian regions — each zone is a stylized, Roblox-scale representation of a distinct city or island, with authentic architecture, local culture, and regional identity. Time period is early modern (pre-internet, late-20th-century kampung life aesthetic).

### 3.2 Player Character

**The player IS the protagonist.** There is no fixed named main character. Each player uses their own Roblox avatar and inhabits the role of a *pemuda* (young person) from Jawa who sets out across the archipelago. Every player runs their own independent quest progress, morality score, and inventory while sharing the same open world with other players simultaneously.

- NPC dialog addresses the player as **"Kamu"** (you) — never a fixed name
- Cutscene narration uses second-person: *"Kamu menerima surat itu..."*
- The story's starting scenario (missing father-figure Arjuna, debt to moneylender) is the shared canon backstory all players begin with
- Player's Roblox avatar is their visual identity — cosmetics change appearance, not the base avatar
- Multiple players can be in the same zone, see each other, and interact via the relationship system

### 3.3 Themes

- Responsibility and coming-of-age
- Community vs. self-interest
- Consequence of reputation
- Pride and understanding of Indonesian cultural identity
- Unity in diversity (Bhinneka Tunggal Ika)

### 3.4 Cultural Mission

Every region the player visits is designed to teach something real:
- **Food**: authentic dishes with lore describing their origin region
- **Clothing**: traditional attire from each island with cultural context
- **Weapons**: traditional Indonesian weapons (no firearms)
- **Architecture**: each zone's buildings reflect the region's real architectural style
- **Language**: NPC dialog contains regional expressions and Bahasa Indonesia flavor text
- **Traditions**: world events tied to real Indonesian ceremonies and holidays

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

### 5.1 World Structure

The world is divided into two hierarchy levels:

```
Universe (Hikayat Pemuda)
└── Place (Island/Kepulauan)       ← separate Roblox Place, own PlaceId
    └── Zone (City / Province)     ← areas within the same Place, streaming enabled
```

**Place** = a major Indonesian island or island group. Each Place is a separate Roblox experience place connected via `TeleportService`. Players travel between Places using **Bandara (Airport)** or **Pelabuhan (Seaport)** — physical locations in-world with ProximityPrompt "Pesan Tiket."

**Zone** = a stylized city or province within a Place. Zones are distinct map areas within the same Place, loaded via Roblox Streaming Enabled as players move between them. Zone boundaries are marked by natural transitions (road, river, terrain change) or a simple checkpoint sign.

---

### 5.2 Places & Zones

#### 🌴 Jawa *(Starting Place)*

| Zone | Province | Cultural Highlight | Unlock |
|---|---|---|---|
| **Suroboyo** | Jawa Timur | Port city — rujak cingur, Jembatan Merah, Bugis mix | Default |
| **Kota Jogja** | DIY Yogyakarta | Kraton, Malioboro batik market, gudeg | Default |
| **Semarang** | Jawa Tengah | Lawang Sewu, lumpia, pecinan (Chinatown mix) | Chapter 1 |
| **Bandung** | Jawa Barat | Sunda culture — angklung, mie kocok, kujang | Chapter 1 |
| **Jakarta** | DKI Jakarta | Capital — Monas area, Betawi culture, kerak telor | Chapter 2 |
| **Serang** | Banten | Baduy enclave, debus tradition, golok Banten | Chapter 2 |

---

#### 🌋 Sumatera

| Zone | Province | Cultural Highlight | Unlock |
|---|---|---|---|
| **Banda Aceh** | Aceh | Islamic architecture — tari saman, mie aceh, rencong | Default |
| **Medan** | Sumatera Utara | Batak culture — ulos, bika ambon, Danau Toba proximity | Default |
| **Padang** | Sumatera Barat | Minangkabau — rumah gadang, rendang, randai dance | Chapter 1 |
| **Pekanbaru** | Riau | Melayu — lancang kuning, sagu | Chapter 1 |
| **Palembang** | Sumatera Selatan | Ampera Bridge, pempek, songket, Sungai Musi | Chapter 1 |
| **Bandar Lampung** | Lampung | Tapis cloth, gajah Sumatera, Way Kambas proximity | Chapter 2 |
| **Pangkal Pinang** | Bangka Belitung | Timah mining, mie belitung, pantai pasir putih | Chapter 2 |
| **Jambi** | Jambi | Batik Jambi, Candi Muaro Jambi, sungai | Chapter 2 |
| **Bengkulu** | Bengkulu | Rafflesia arnoldii, kain besurek, benteng Inggris | Chapter 3 |
| **Tanjung Pinang** | Kepulauan Riau | Melayu pesisir, seafood, pulau bintan proximity | Chapter 3 |

---

#### 🌿 Kalimantan

| Zone | Province | Cultural Highlight | Unlock |
|---|---|---|---|
| **Pontianak** | Kalimantan Barat | Equator monument — Melayu + Tionghoa mix, soto banjar | Default |
| **Banjarmasin** | Kalimantan Selatan | Floating market (pasar terapung), Banjar culture, sasirangan | Default |
| **Palangka Raya** | Kalimantan Tengah | Dayak Ngaju — betang longhouse, beads, sungai | Chapter 1 |
| **Samarinda** | Kalimantan Timur | Sarung samarinda, sungai Mahakam, near IKN | Chapter 2 |
| **Tanjung Selor** | Kalimantan Utara | Frontier zone — remote, rare forest drops, Tidung culture | Chapter 3 |

---

#### 🌊 Sulawesi

| Zone | Province | Cultural Highlight | Unlock |
|---|---|---|---|
| **Makassar** | Sulawesi Selatan | Bugis — Fort Rotterdam, coto makassar, pinisi boat | Default |
| **Tanah Toraja** | Sulawesi Selatan | Tongkonan, tau-tau, kopi Toraja, Rambu Solo' | Default |
| **Manado** | Sulawesi Utara | Minahasa — tinutuan, Bunaken proximity, woku | Chapter 1 |
| **Gorontalo** | Gorontalo | Gorontalo culture — karawo embroidery, nasi bihu | Chapter 2 |
| **Palu** | Sulawesi Tengah | Kaili culture — bawang goreng, ikan kaledo | Chapter 2 |
| **Kendari** | Sulawesi Tenggara | Tolaki — tenun Kendari, lasoani beach | Chapter 3 |
| **Mamuju** | Sulawesi Barat | Mandar — perahu Mandar, ikan bakar, remote feel | Chapter 3 |

---

#### 🦜 Papua

| Zone | Province | Cultural Highlight | Unlock |
|---|---|---|---|
| **Jayapura** | Papua | Sentani culture — tifa drum, ukiran Sentani, danau Sentani | Default |
| **Sorong** | Papua Barat Daya | Raja Ampat gateway — diving, cenderawasih bird | Chapter 1 |
| **Manokwari** | Papua Barat | Arfak mountains, cenderawasih display, forest | Chapter 2 |
| **Merauke** | Papua Selatan | Marind-Anim culture — savanna, kangguru, sagu | Chapter 3 |

---

#### 🌺 Nusa Tenggara *(includes Bali)*

| Zone | Province | Cultural Highlight | Unlock |
|---|---|---|---|
| **Denpasar** | Bali | Pura Besakih, kecak dance, gamelan Bali, lawar | Default |
| **Mataram** | NTB (Lombok) | Sasak culture — tenun Lombok, ayam taliwang, Rinjani | Default |
| **Kupang** | NTT (Timor) | Timor culture — tenun ikat, savanna, se'i babi | Chapter 1 |

---

#### 🌶️ Maluku

| Zone | Province | Cultural Highlight | Unlock |
|---|---|---|---|
| **Ambon** | Maluku | Rempah-rempah (spice islands) — tari cakalele, ikan kuah pala | Default |
| **Ternate** | Maluku Utara | Kesultanan Ternate — cengkeh, pala, benteng Oranje | Chapter 1 |

---

### 5.3 Travel System

#### 5.3.1 Bandara (Airport) — Inter-Island Travel

- Located in each Place (at least one per island, in the main/default zone)
- ProximityPrompt on ticket counter NPC: "Pesan Tiket Pesawat"
- Opens **Peta Perjalanan** UI — Indonesia map showing all Places
- Locked Places shown grayed out with lock icon and unlock hint
- Travel costs **Rupiah** (ticket price varies by distance)
- Triggers `TeleportService:TeleportToPlaceInstance()` — player loads into the destination Place's arrival zone (near that island's bandara)

**Ticket prices (approximate):**
| Route | Price |
|---|---|
| Within island (express) | Rp 2.000 |
| Jawa ↔ Sumatera | Rp 5.000 |
| Jawa ↔ Kalimantan | Rp 6.000 |
| Jawa ↔ Sulawesi | Rp 8.000 |
| Jawa ↔ Papua | Rp 15.000 |
| Jawa ↔ Maluku | Rp 12.000 |
| Jawa ↔ Nusa Tenggara | Rp 5.000 |

#### 5.3.2 Pelabuhan (Seaport) — Inter-Zone & Inter-Island Travel

- Located in coastal zones (most zones have one)
- Inter-zone within same Place: free or cheap (Rp 500), uses local teleport (no Place switch)
- Inter-island via sea: available for geographically close islands only (e.g., Jawa ↔ Bali, Sumatera ↔ Kepulauan Riau), costs Rupiah, uses TeleportService
- Slower "travel feel" — brief loading screen styled as a kapal ferry view

#### 5.3.3 Travel UI — Peta Perjalanan

- Full-screen Indonesia archipelago map
- Island groups clickable to zoom in
- Zones shown as dots — green = unlocked, gray = locked, yellow = current
- Bottom panel: selected destination name, ticket cost, "Berangkat" button
- Localized to Bahasa Indonesia / English
- Mobile: pinch-to-zoom supported

#### 5.3.4 Unlock Logic

- All **Default** zones within starting Place (Jawa) are available immediately
- Non-Jawa Places: **each island's Default zones** unlock when player first travels there (no quest gate for travel itself — freedom to explore)
- Locked zones within a Place: unlock via quest progression as noted in tables above
- Player cannot travel to a Place if they have never unlocked it (first visit requires completing Chapter 1 on Jawa)

---

### 5.4 Within-Zone Exploration

- Players roam freely within unlocked zones
- Hidden collectibles, lore items, and secret NPCs placed throughout each zone
- No minimap by default — directional compass + landmark icons (immersive)
- Player can buy **"Peta [Zone]"** (zone-specific map) from local shop to reveal that zone's layout
- Each zone has at least: 1 shop, 1 quest-giver NPC, 1 collectible, 1 ambient NPC

### 5.5 World Events

Random events spawn per zone, per server:
- Merchant attacked (intervene = morality +8)
- Rare ingredient spawn at fixed location
- NPC in distress (help = morality +5, Rupiah reward)
- Cultural festival procession (ambient, no action required — watching gives lore collectible)
- Poacher/bandit camp (defeat all = morality +10, loot drop)

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

No firearms. Traditional Indonesian weapons only — melee and ranged.

| Weapon | Origin | Type | Range | Damage Tier |
|---|---|---|---|---|
| Kepalan / Pencak Silat | Java/Sumatra | Melee | Very Short | Low |
| Tongkat (staff) | General Nusantara | Melee | Short | Medium |
| Golok | Betawi / Sunda | Melee | Short | Medium |
| Keris | Java / Bali | Melee | Short | Medium-High |
| Mandau | Kalimantan (Dayak) | Melee | Short | High |
| Ketapel | General Nusantara | Ranged | Medium | Low-Medium |
| Sumpit (blowpipe) | Kalimantan / Papua | Ranged | Long | Low (status effect) |

- **Keris**: ceremonial, high morality players get bonus damage (revered weapon)
- **Mandau**: only obtainable in Hutan Kalimantan zone
- **Sumpit**: darts apply slow effect on enemy for 3 seconds
- **Pencak Silat** punch style: unlock after completing a side quest in Desa Jawa — replaces default punch animation with silat moves

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

| Type | Use | Example (Indonesian) |
|---|---|---|
| **Makanan/Minuman** | Consume to restore stamina | Nasi Gudeg, Pempek, Bakpia, Kopi Toraja, Es Teh |
| **Kosmetik/UGC** | Equip to change appearance | Batik Yogya, Blangkon, Tanjak, Baju Pokko', Songket |
| **Koleksi** | Display item, tradeable, show-off | Wayang Kulit mini, Tau-Tau figurine, Batik Scroll, Mandau mini |
| **Senjata** | Equip to combat slot | Keris, Golok, Mandau, Tongkat, Ketapel, Sumpit |
| **Bahan** | Craft into other items | Beras, Benang Emas, Rotan, Getah Karet, Daun Pisang, Kayu Ulin |

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
-- WEAPONS (equippable definitions — all traditional Indonesian)
-- ============================================================
AssetConfig.Weapons = {
    PencakSilat = {
        id          = "PencakSilat",
        nameKey     = "item.pencaksilat.name",
        origin      = "Java / Sumatra",
        damage      = 10,
        cooldown    = 0.45,
        staminaCost = 5,
        range       = 4,
        animationId = "rbxassetid://000000010",
        unlockQuest = "SQ_SilatMaster",  -- replaces default punch
    },
    Tongkat = {
        id          = "Tongkat",
        nameKey     = "item.tongkat.name",
        origin      = "Nusantara",
        damage      = 14,
        cooldown    = 0.85,
        staminaCost = 10,
        range       = 6,
        animationId = "rbxassetid://000000011",
        itemRef     = "Tongkat",
    },
    Golok = {
        id          = "Golok",
        nameKey     = "item.golok.name",
        origin      = "Betawi / Sunda",
        damage      = 18,
        cooldown    = 0.8,
        staminaCost = 12,
        range       = 5,
        animationId = "rbxassetid://000000012",
        itemRef     = "Golok",
    },
    Keris = {
        id          = "Keris",
        nameKey     = "item.keris.name",
        origin      = "Java / Bali",
        damage      = 22,
        cooldown    = 0.75,
        staminaCost = 10,
        range       = 4,
        animationId = "rbxassetid://000000013",
        itemRef     = "Keris",
        moralityBonus = { minMorality = 90, damageMultiplier = 1.25 },
    },
    Mandau = {
        id          = "Mandau",
        nameKey     = "item.mandau.name",
        origin      = "Kalimantan (Dayak)",
        damage      = 28,
        cooldown    = 0.95,
        staminaCost = 15,
        range       = 5,
        animationId = "rbxassetid://000000014",
        itemRef     = "Mandau",
        zoneRestricted = "HutanKalimantan",  -- only obtainable in this zone
    },
    Ketapel = {
        id          = "Ketapel",
        nameKey     = "item.ketapel.name",
        origin      = "Nusantara",
        damage      = 12,
        cooldown    = 1.2,
        staminaCost = 8,
        range       = 20,
        projectileSpeed = 80,
        animationId = "rbxassetid://000000015",
        itemRef     = "Ketapel",
    },
    Sumpit = {
        id          = "Sumpit",
        nameKey     = "item.sumpit.name",
        origin      = "Kalimantan / Papua",
        damage      = 8,
        cooldown    = 1.5,
        staminaCost = 6,
        range       = 35,
        projectileSpeed = 120,
        statusEffect = { type = "Slow", duration = 3, multiplier = 0.5 },
        animationId = "rbxassetid://000000016",
        itemRef     = "Sumpit",
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
-- PLACES (Islands) — each maps to a Roblox PlaceId
-- ============================================================
AssetConfig.Places = {
    Jawa = {
        id          = "Jawa",
        nameKey     = "place.jawa",
        placeId     = 0,            -- fill with actual Roblox PlaceId
        isStarting  = true,
        bandaraZone = "Suroboyo",
        pelabuhanZone = "Suroboyo",
    },
    Sumatera = {
        id          = "Sumatera",
        nameKey     = "place.sumatera",
        placeId     = 0,
        bandaraZone = "Medan",
        pelabuhanZone = "Palembang",
    },
    Kalimantan = {
        id          = "Kalimantan",
        nameKey     = "place.kalimantan",
        placeId     = 0,
        bandaraZone = "Banjarmasin",
        pelabuhanZone = "Pontianak",
    },
    Sulawesi = {
        id          = "Sulawesi",
        nameKey     = "place.sulawesi",
        placeId     = 0,
        bandaraZone = "Makassar",
        pelabuhanZone = "Makassar",
    },
    Papua = {
        id          = "Papua",
        nameKey     = "place.papua",
        placeId     = 0,
        bandaraZone = "Jayapura",
        pelabuhanZone = "Sorong",
    },
    NusaTenggara = {
        id          = "NusaTenggara",
        nameKey     = "place.nusatenggara",
        placeId     = 0,
        bandaraZone = "Denpasar",
        pelabuhanZone = "Denpasar",
    },
    Maluku = {
        id          = "Maluku",
        nameKey     = "place.maluku",
        placeId     = 0,
        bandaraZone = "Ambon",
        pelabuhanZone = "Ambon",
    },
}

-- ============================================================
-- TRAVEL (Ticket Prices in Rupiah)
-- ============================================================
AssetConfig.Travel = {
    -- Bandara (Airport) — inter-island via TeleportService
    airTickets = {
        SameIsland     = 2000,
        JawaToSumatera = 5000,
        JawaToKalimantan = 6000,
        JawaToSulawesi = 8000,
        JawaToNusaTenggara = 5000,
        JawaToMaluku   = 12000,
        JawaToPapua    = 15000,
    },
    -- Pelabuhan (Seaport) — inter-zone within same island
    ferryTickets = {
        WithinIsland   = 500,
        -- Cross-sea short routes (Jawa <-> Bali, Jawa <-> Sumatera via Selat Sunda)
        ShortCrossSea  = 1500,
    },
}

-- ============================================================
-- WORLD ZONES (organized by Place)
-- ============================================================
AssetConfig.Zones = {

    -- JAWA
    Suroboyo = {
        id = "Suroboyo", place = "Jawa", nameKey = "zone.suroboyo",
        region = "Jawa Timur", unlockQuest = nil,
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000100", ambientSound = "rbxassetid://000000150",
        culturalNote = "Betawi-Jawa port city, rujak cingur, Jembatan Merah",
    },
    KotaJogja = {
        id = "KotaJogja", place = "Jawa", nameKey = "zone.kotajogja",
        region = "DIY Yogyakarta", unlockQuest = nil,
        hasBandara = false, hasPelabuhan = false,
        bgmId = "rbxassetid://000000101", ambientSound = "rbxassetid://000000151",
        culturalNote = "Kraton, Malioboro, batik parang/kawung, gudeg, keris",
    },
    Semarang = {
        id = "Semarang", place = "Jawa", nameKey = "zone.semarang",
        region = "Jawa Tengah", unlockQuest = "MQ_Ch1_Awal",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000102", ambientSound = "rbxassetid://000000152",
        culturalNote = "Lawang Sewu, lumpia, pecinan, Jawa-Tionghoa mix",
    },
    Bandung = {
        id = "Bandung", place = "Jawa", nameKey = "zone.bandung",
        region = "Jawa Barat", unlockQuest = "MQ_Ch1_Awal",
        hasBandara = true, hasPelabuhan = false,
        bgmId = "rbxassetid://000000103", ambientSound = "rbxassetid://000000153",
        culturalNote = "Sunda — angklung, mie kocok, kujang, Gedung Sate",
    },
    Jakarta = {
        id = "Jakarta", place = "Jawa", nameKey = "zone.jakarta",
        region = "DKI Jakarta", unlockQuest = "MQ_Ch2_Jakarta",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000104", ambientSound = "rbxassetid://000000154",
        culturalNote = "Betawi — Monas, kerak telor, ondel-ondel, kota tua",
    },
    Serang = {
        id = "Serang", place = "Jawa", nameKey = "zone.serang",
        region = "Banten", unlockQuest = "MQ_Ch2_Jakarta",
        hasBandara = false, hasPelabuhan = true,
        bgmId = "rbxassetid://000000105", ambientSound = "rbxassetid://000000155",
        culturalNote = "Baduy enclave, debus tradition, golok Banten",
    },

    -- SUMATERA
    BandaAceh = {
        id = "BandaAceh", place = "Sumatera", nameKey = "zone.bandaaceh",
        region = "Aceh", unlockQuest = nil,
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000110", ambientSound = "rbxassetid://000000160",
        culturalNote = "Islamic architecture, tari saman, mie aceh, rencong dagger",
    },
    Medan = {
        id = "Medan", place = "Sumatera", nameKey = "zone.medan",
        region = "Sumatera Utara", unlockQuest = nil,
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000111", ambientSound = "rbxassetid://000000161",
        culturalNote = "Batak — ulos, bika ambon, Danau Toba, tor-tor dance",
    },
    Padang = {
        id = "Padang", place = "Sumatera", nameKey = "zone.padang",
        region = "Sumatera Barat", unlockQuest = "MQ_Ch1_Awal",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000112", ambientSound = "rbxassetid://000000162",
        culturalNote = "Minangkabau — rumah gadang, rendang, randai, saluang",
    },
    Pekanbaru = {
        id = "Pekanbaru", place = "Sumatera", nameKey = "zone.pekanbaru",
        region = "Riau", unlockQuest = "MQ_Ch1_Awal",
        hasBandara = true, hasPelabuhan = false,
        bgmId = "rbxassetid://000000113", ambientSound = "rbxassetid://000000163",
        culturalNote = "Melayu Riau — lancang kuning, sagu, tepak sirih",
    },
    Palembang = {
        id = "Palembang", place = "Sumatera", nameKey = "zone.palembang",
        region = "Sumatera Selatan", unlockQuest = "MQ_Ch1_Awal",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000114", ambientSound = "rbxassetid://000000164",
        culturalNote = "Ampera Bridge, pempek, songket, Sungai Musi, Sriwijaya legacy",
    },
    BandarLampung = {
        id = "BandarLampung", place = "Sumatera", nameKey = "zone.bandarlampung",
        region = "Lampung", unlockQuest = "MQ_Ch2_Sumatera",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000115", ambientSound = "rbxassetid://000000165",
        culturalNote = "Tapis cloth, gajah Sumatera, Way Kambas, tari sigeh pengunten",
    },
    PangkalPinang = {
        id = "PangkalPinang", place = "Sumatera", nameKey = "zone.pangkalpinang",
        region = "Bangka Belitung", unlockQuest = "MQ_Ch2_Sumatera",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000116", ambientSound = "rbxassetid://000000166",
        culturalNote = "Timah (tin) mining heritage, mie belitung, pantai pasir putih",
    },
    Jambi = {
        id = "Jambi", place = "Sumatera", nameKey = "zone.jambi",
        region = "Jambi", unlockQuest = "MQ_Ch2_Sumatera",
        hasBandara = true, hasPelabuhan = false,
        bgmId = "rbxassetid://000000117", ambientSound = "rbxassetid://000000167",
        culturalNote = "Batik Jambi, Candi Muaro Jambi ruins, sungai Batanghari",
    },
    Bengkulu = {
        id = "Bengkulu", place = "Sumatera", nameKey = "zone.bengkulu",
        region = "Bengkulu", unlockQuest = "MQ_Ch3_Sumatera",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000118", ambientSound = "rbxassetid://000000168",
        culturalNote = "Rafflesia arnoldii, kain besurek, benteng Inggris (Fort Marlborough)",
    },
    TanjungPinang = {
        id = "TanjungPinang", place = "Sumatera", nameKey = "zone.tanjungpinang",
        region = "Kepulauan Riau", unlockQuest = "MQ_Ch3_Sumatera",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000119", ambientSound = "rbxassetid://000000169",
        culturalNote = "Melayu pesisir, seafood, Pulau Penyengat royal ruins",
    },

    -- KALIMANTAN
    Pontianak = {
        id = "Pontianak", place = "Kalimantan", nameKey = "zone.pontianak",
        region = "Kalimantan Barat", unlockQuest = nil,
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000120", ambientSound = "rbxassetid://000000170",
        culturalNote = "Equator monument, Melayu-Tionghoa mix, soto banjar",
    },
    Banjarmasin = {
        id = "Banjarmasin", place = "Kalimantan", nameKey = "zone.banjarmasin",
        region = "Kalimantan Selatan", unlockQuest = nil,
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000121", ambientSound = "rbxassetid://000000171",
        culturalNote = "Pasar terapung (floating market), sasirangan cloth, Banjar culture",
    },
    PalangkaRaya = {
        id = "PalangkaRaya", place = "Kalimantan", nameKey = "zone.palangkaraya",
        region = "Kalimantan Tengah", unlockQuest = "MQ_Ch1_Kalimantan",
        hasBandara = true, hasPelabuhan = false,
        bgmId = "rbxassetid://000000122", ambientSound = "rbxassetid://000000172",
        culturalNote = "Dayak Ngaju — betang longhouse, manik-manik, mandau, sungai Kahayan",
    },
    Samarinda = {
        id = "Samarinda", place = "Kalimantan", nameKey = "zone.samarinda",
        region = "Kalimantan Timur", unlockQuest = "MQ_Ch2_Kalimantan",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000123", ambientSound = "rbxassetid://000000173",
        culturalNote = "Sarung samarinda weaving, sungai Mahakam, Kutai kingdom legacy",
    },
    TanjungSelor = {
        id = "TanjungSelor", place = "Kalimantan", nameKey = "zone.tanjungselor",
        region = "Kalimantan Utara", unlockQuest = "MQ_Ch3_Kalimantan",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000124", ambientSound = "rbxassetid://000000174",
        culturalNote = "Tidung culture, frontier remote feel, rare forest drops",
    },

    -- SULAWESI
    Makassar = {
        id = "Makassar", place = "Sulawesi", nameKey = "zone.makassar",
        region = "Sulawesi Selatan", unlockQuest = nil,
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000130", ambientSound = "rbxassetid://000000180",
        culturalNote = "Bugis — Fort Rotterdam, coto makassar, pinisi boat, andi nobility",
    },
    TanahToraja = {
        id = "TanahToraja", place = "Sulawesi", nameKey = "zone.tanahtoraja",
        region = "Sulawesi Selatan", unlockQuest = nil,
        hasBandara = false, hasPelabuhan = false,
        bgmId = "rbxassetid://000000131", ambientSound = "rbxassetid://000000181",
        culturalNote = "Tongkonan, tau-tau, kopi Toraja, Rambu Solo' procession",
    },
    Manado = {
        id = "Manado", place = "Sulawesi", nameKey = "zone.manado",
        region = "Sulawesi Utara", unlockQuest = "MQ_Ch1_Sulawesi",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000132", ambientSound = "rbxassetid://000000182",
        culturalNote = "Minahasa — tinutuan bubur, Bunaken sea, woku spice, cakalang",
    },
    Gorontalo = {
        id = "Gorontalo", place = "Sulawesi", nameKey = "zone.gorontalo",
        region = "Gorontalo", unlockQuest = "MQ_Ch2_Sulawesi",
        hasBandara = true, hasPelabuhan = false,
        bgmId = "rbxassetid://000000133", ambientSound = "rbxassetid://000000183",
        culturalNote = "Karawo embroidery, nasi bihu, binde biluhuta soup",
    },
    Palu = {
        id = "Palu", place = "Sulawesi", nameKey = "zone.palu",
        region = "Sulawesi Tengah", unlockQuest = "MQ_Ch2_Sulawesi",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000134", ambientSound = "rbxassetid://000000184",
        culturalNote = "Kaili culture, bawang goreng Palu, ikan kaledo, teluk Palu",
    },
    Kendari = {
        id = "Kendari", place = "Sulawesi", nameKey = "zone.kendari",
        region = "Sulawesi Tenggara", unlockQuest = "MQ_Ch3_Sulawesi",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000135", ambientSound = "rbxassetid://000000185",
        culturalNote = "Tolaki — tenun Kendari silver filigree, sinonggi sagu",
    },
    Mamuju = {
        id = "Mamuju", place = "Sulawesi", nameKey = "zone.mamuju",
        region = "Sulawesi Barat", unlockQuest = "MQ_Ch3_Sulawesi",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000136", ambientSound = "rbxassetid://000000186",
        culturalNote = "Mandar — perahu Mandar, ikan bakar, remote frontier vibe",
    },

    -- PAPUA
    Jayapura = {
        id = "Jayapura", place = "Papua", nameKey = "zone.jayapura",
        region = "Papua", unlockQuest = nil,
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000140", ambientSound = "rbxassetid://000000190",
        culturalNote = "Sentani — tifa drum, ukiran Sentani, danau Sentani, noken bag",
    },
    Sorong = {
        id = "Sorong", place = "Papua", nameKey = "zone.sorong",
        region = "Papua Barat Daya", unlockQuest = "MQ_Ch1_Papua",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000141", ambientSound = "rbxassetid://000000191",
        culturalNote = "Raja Ampat gateway, cenderawasih bird, diving, bahari culture",
    },
    Manokwari = {
        id = "Manokwari", place = "Papua", nameKey = "zone.manokwari",
        region = "Papua Barat", unlockQuest = "MQ_Ch2_Papua",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000142", ambientSound = "rbxassetid://000000192",
        culturalNote = "Arfak mountains, cenderawasih display, hutan hujan Papua",
    },
    Merauke = {
        id = "Merauke", place = "Papua", nameKey = "zone.merauke",
        region = "Papua Selatan", unlockQuest = "MQ_Ch3_Papua",
        hasBandara = true, hasPelabuhan = false,
        bgmId = "rbxassetid://000000143", ambientSound = "rbxassetid://000000193",
        culturalNote = "Marind-Anim — savanna, kangguru Papua, sagu, tari wutukala",
    },

    -- NUSA TENGGARA (+ Bali)
    Denpasar = {
        id = "Denpasar", place = "NusaTenggara", nameKey = "zone.denpasar",
        region = "Bali", unlockQuest = nil,
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000150", ambientSound = "rbxassetid://000000200",
        culturalNote = "Pura Besakih, kecak dance, gamelan Bali, lawar, ogoh-ogoh",
    },
    Mataram = {
        id = "Mataram", place = "NusaTenggara", nameKey = "zone.mataram",
        region = "NTB (Lombok)", unlockQuest = nil,
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000151", ambientSound = "rbxassetid://000000201",
        culturalNote = "Sasak — tenun Lombok, ayam taliwang, Rinjani, gendang beleq",
    },
    Kupang = {
        id = "Kupang", place = "NusaTenggara", nameKey = "zone.kupang",
        region = "NTT (Timor)", unlockQuest = "MQ_Ch1_NusaTenggara",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000152", ambientSound = "rbxassetid://000000202",
        culturalNote = "Timor — tenun ikat NTT, se'i babi, savanna, flobamora culture",
    },

    -- MALUKU
    Ambon = {
        id = "Ambon", place = "Maluku", nameKey = "zone.ambon",
        region = "Maluku", unlockQuest = nil,
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000160", ambientSound = "rbxassetid://000000210",
        culturalNote = "Rempah-rempah (spice islands), tari cakalele, ikan kuah pala, sagu",
    },
    Ternate = {
        id = "Ternate", place = "Maluku", nameKey = "zone.ternate",
        region = "Maluku Utara", unlockQuest = "MQ_Ch1_Maluku",
        hasBandara = true, hasPelabuhan = true,
        bgmId = "rbxassetid://000000161", ambientSound = "rbxassetid://000000211",
        culturalNote = "Kesultanan Ternate, cengkeh, pala, Benteng Oranje, kie raha",
    },
}

-- ============================================================
-- TASKS
-- ============================================================
AssetConfig.Tasks = {
    dailyQuota    = { easy = 3, medium = 2 },
    weeklyQuota   = { medium = 2, hard = 1 },
    rerollCost    = { rupiah = 500 },
    rerollsPerDay = 1,
    resetHourUTC  = 17, -- 00:00 WIB = 17:00 UTC

    allDailyBonus = {
        rupiah   = { min = 2000, max = 5000 },
        itemDrop = { chance = 0.4, rarityMin = "TidakBiasa" },
        morality = 3,
    },
    allWeeklyBonus = {
        gold     = 2,
        itemDrop = { chance = 1.0, rarityMin = "Epik" },
    },

    Templates = {
        {
            id         = "T_Explore",
            difficulty = "Easy",
            type       = "Explore",
            titleKey   = "task.explore.title",
            descKey    = "task.explore.desc",
            target     = "any",
            count      = 1,
            reward     = { rupiah = 400 },
        },
        {
            id         = "T_Gather_Kayu",
            difficulty = "Easy",
            type       = "Gather",
            titleKey   = "task.gather.kayu.title",
            descKey    = "task.gather.kayu.desc",
            item       = "Kayu",
            count      = 3,
            reward     = { rupiah = 350 },
        },
        {
            id         = "T_Talk_NPCs",
            difficulty = "Easy",
            type       = "Talk",
            titleKey   = "task.talk.title",
            descKey    = "task.talk.desc",
            count      = 2,
            reward     = { rupiah = 300 },
        },
        {
            id         = "T_Craft_Any",
            difficulty = "Easy",
            type       = "Craft",
            titleKey   = "task.craft.title",
            descKey    = "task.craft.desc",
            count      = 1,
            reward     = { rupiah = 350 },
        },
        {
            id         = "T_Sell_Value",
            difficulty = "Easy",
            type       = "SellValue",
            titleKey   = "task.sell.title",
            descKey    = "task.sell.desc",
            targetRupiah = 1000,
            reward     = { rupiah = 500 },
        },
        {
            id         = "T_Combat",
            difficulty = "Medium",
            type       = "Combat",
            titleKey   = "task.combat.title",
            descKey    = "task.combat.desc",
            count      = 3,
            reward     = { rupiah = 1000 },
        },
        {
            id         = "T_SideQuest",
            difficulty = "Medium",
            type       = "CompleteQuest",
            titleKey   = "task.sidequest.title",
            descKey    = "task.sidequest.desc",
            questType  = "Side",
            count      = 1,
            reward     = { rupiah = 1200 },
        },
        {
            id         = "T_Collect",
            difficulty = "Medium",
            type       = "Collect",
            titleKey   = "task.collect.title",
            descKey    = "task.collect.desc",
            itemType   = "Koleksi",
            count      = 1,
            reward     = { rupiah = 900 },
        },
        -- Weekly hard examples
        {
            id         = "T_W_Combat_Hard",
            difficulty = "Hard",
            type       = "Combat",
            titleKey   = "task.weekly.combat.title",
            descKey    = "task.weekly.combat.desc",
            count      = 15,
            reward     = { rupiah = 5000 },
        },
        {
            id         = "T_W_Craft_Variety",
            difficulty = "Hard",
            type       = "CraftVariety",
            titleKey   = "task.weekly.craft.title",
            descKey    = "task.weekly.craft.desc",
            count      = 5,
            reward     = { rupiah = 4000 },
        },
        -- Add more task templates here
    },
}

-- ============================================================
-- EVENTS (Festival)
-- ============================================================
AssetConfig.Events = {
    Lebaran = {
        id         = "Lebaran",
        nameKey    = "event.lebaran.name",
        currency   = { id = "KoinLebaran", symbol = "🪙", nameKey = "event.lebaran.currency" },
        durationDays = 14,
        taskBonus  = true,
        shopItems  = { "BajuKoko", "KetupatlDisplay" },
        eventTasks = {
            { type = "Talk", count = 5, reward = { eventCurrency = 2 } },
            { type = "Craft", item = "Ketupat", count = 3, reward = { eventCurrency = 5 } },
        },
    },
    -- Add more events here
}

-- ============================================================
-- LOGIN STREAK
-- ============================================================
AssetConfig.LoginStreak = {
    {  day = 1,  reward = { rupiah = 500 } },
    {  day = 2,  reward = { rupiah = 800 } },
    {  day = 3,  reward = { rupiah = 1000, items = { { id = "NasiBungkus", amount = 2 } } } },
    {  day = 5,  reward = { rupiah = 2000, items = { { id = "RandomTidakBiasa", amount = 1 } } } },
    {  day = 7,  reward = { rupiah = 3000, gold = 1 } },
    {  day = 14, reward = { rupiah = 5000, gold = 2, items = { { id = "RandomEpik", amount = 1 } } } },
    {  day = 30, reward = { rupiah = 10000, gold = 5, items = { { id = "RandomLegenda", amount = 1 } } } },
}

-- ============================================================
-- ACHIEVEMENTS
-- ============================================================
AssetConfig.Achievements = {
    {
        id      = "ACH_FirstMarriage",
        nameKey = "ach.firstmarriage.name",
        descKey = "ach.firstmarriage.desc",
        type    = "Relationship",
        target  = "Menikah",
        count   = 1,
        reward  = { gold = 1 },
    },
    {
        id      = "ACH_Defeat100",
        nameKey = "ach.defeat100.name",
        descKey = "ach.defeat100.desc",
        type    = "Combat",
        count   = 100,
        reward  = { rupiah = 5000 },
    },
    {
        id      = "ACH_AllPlaces",
        nameKey = "ach.allplaces.name",
        descKey = "ach.allplaces.desc",
        type    = "ExplorePlace",
        count   = 7,          -- all 7 islands
        reward  = { gold = 5, items = { { id = "TitlePenjelajahNusantara", amount = 1 } } },
    },
    {
        id      = "ACH_AllZonesJawa",
        nameKey = "ach.allzonesjawa.name",
        descKey = "ach.allzonesjawa.desc",
        type    = "ExploreZone",
        place   = "Jawa",
        count   = 6,
        reward  = { gold = 1 },
    },
    {
        id      = "ACH_Pahlawan",
        nameKey = "ach.pahlawan.name",
        descKey = "ach.pahlawan.desc",
        type    = "Morality",
        target  = "Pahlawan",
        reward  = { items = { { id = "LegendaCosmeticGood", amount = 1 } } },
    },
    {
        id      = "ACH_Penjahat",
        nameKey = "ach.penjahat.name",
        descKey = "ach.penjahat.desc",
        type    = "Morality",
        target  = "Penjahat",
        reward  = { items = { { id = "LegendaCosmeticBad", amount = 1 } } },
    },
    -- Add more achievements here
}

-- ============================================================
-- AUDIO
-- Note: zone BGM and ambientSound IDs live in AssetConfig.Zones above.
-- This section covers global/shared audio only.
-- ============================================================
AssetConfig.Audio = {
    BGM = {
        Combat        = "rbxassetid://000000103",
        MainMenu      = "rbxassetid://000000104",
        QuestComplete = "rbxassetid://000000105",
        TravelScreen  = "rbxassetid://000000106",
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
    version       = 2,
    rupiah        = 0,
    gold          = 0,
    morality      = 50,
    inventory     = {},             -- { itemId, amount, slot }
    hotbar        = {},             -- { slotIndex, itemId }
    hotbarSize    = 4,
    inventorySize = 20,

    questProgress    = {},          -- { questId, status, objectiveProgress }
    completedQuests  = {},
    activeQuests     = {},          -- max 5 concurrent side quests

    relationships    = {},          -- { targetUserId, type }
    unlockedPlaces   = { "Jawa" },          -- islands visited at least once
    unlockedZones    = { "Suroboyo", "KotaJogja" },  -- zones within places

    -- Task system
    dailyTasks       = {},          -- { taskId, progress, completed, claimed } — reset daily
    weeklyTasks      = {},          -- { taskId, progress, completed, claimed } — reset weekly
    lastDailyReset   = 0,           -- Unix timestamp of last daily reset
    lastWeeklyReset  = 0,           -- Unix timestamp of last weekly reset
    dailyRerollsUsed = 0,           -- reset with daily

    -- Retention
    loginStreak      = 0,
    lastLoginDate    = "",          -- "YYYY-MM-DD" in WIB
    streakRewardsClaimed = {},      -- { day = true/false }

    achievements     = {},          -- { achId, completed, claimedAt }
    collectibleCount = 0,

    -- Galeri
    galeriLayout     = {},          -- { itemId, pedestalSlot }

    -- Event currencies
    eventCurrencies  = {},          -- { eventId, amount }
}
```

### 18.2 Auto-Save

- Auto-save on: quest completion, shop transaction, logout (`Players.PlayerRemoving`)
- Retry on save failure (up to 3 attempts)

---

## 19. Folder Structure (Roblox Studio)

### 19.0 Roblox Universe Layout

The game is a **Roblox Universe** (one game, many Places). Each island is a separate Place:

```
Universe: Hikayat Pemuda
├── Place: Jawa          (starting place, PlaceId filled in AssetConfig.Places.Jawa.placeId)
├── Place: Sumatera
├── Place: Kalimantan
├── Place: Sulawesi
├── Place: Papua
├── Place: NusaTenggara
└── Place: Maluku
```

- `AssetConfig` is published to **each** Place via Roblox package or `require(assetId)` so all Places share one config
- `DataStoreService` keys are shared across all Places in same Universe automatically
- `TeleportService:TeleportToPlaceInstance()` handles inter-island travel

### 19.1 Per-Place Folder Structure (same structure replicated in each Place)

```
game
├── ReplicatedStorage
│   ├── Config
│   │   └── AssetConfig          (ModuleScript)  ← single source of truth
│   ├── Modules
│   │   ├── ItemModule           (ModuleScript)
│   │   ├── QuestModule          (ModuleScript)
│   │   ├── TaskModule           (ModuleScript)
│   │   ├── MoralityModule       (ModuleScript)
│   │   ├── CurrencyModule       (ModuleScript)
│   │   ├── RelationshipModule   (ModuleScript)
│   │   ├── AchievementModule    (ModuleScript)
│   │   ├── LoginStreakModule     (ModuleScript)
│   │   └── LocalizationUtil     (ModuleScript)
│   └── RemoteEvents
│       ├── UpdateHotbar
│       ├── OpenShop
│       ├── QuestUpdate
│       ├── TaskUpdate
│       ├── MoralityChanged
│       ├── AchievementUnlocked
│       ├── LoginStreakClaimed
│       ├── OpenGaleri
│       ├── OpenTravelMap
│       └── TeleportToPlace
├── ServerScriptService
│   ├── GameManager              (Script)
│   ├── DataManager              (Script)
│   ├── QuestServer              (Script)
│   ├── TaskServer               (Script)
│   ├── ShopServer               (Script)
│   ├── CombatServer             (Script)
│   ├── NPCManager               (Script)
│   ├── RelationshipServer       (Script)
│   ├── AchievementServer        (Script)
│   ├── LoginStreakServer         (Script)
│   ├── TravelServer             (Script)  ← handles TeleportService, ticket purchase
│   ├── ZoneManager              (Script)  ← streaming, zone boundary detection
│   ├── EventManager             (Script)
│   └── LeaderboardServer        (Script)
├── StarterPlayerScripts
│   ├── HotbarController         (LocalScript)
│   ├── InventoryController      (LocalScript)
│   ├── QuestHUD                 (LocalScript)
│   ├── TaskHUD                  (LocalScript)
│   ├── DialogController         (LocalScript)
│   └── CameraController         (LocalScript)
├── StarterGui
│   ├── HUDGui                   (ScreenGui)
│   ├── InventoryGui             (ScreenGui)
│   ├── ShopGui                  (ScreenGui)
│   ├── QuestGui                 (ScreenGui)
│   ├── TaskGui                  (ScreenGui)
│   ├── DialogGui                (ScreenGui)
│   ├── SocialGui                (ScreenGui)
│   ├── AchievementGui           (ScreenGui)
│   ├── GaleriGui                (ScreenGui)
│   ├── LoginStreakGui           (ScreenGui)
│   └── TravelGui                (ScreenGui)  ← Peta Perjalanan, ticket purchase
└── Workspace
    ├── Map
    │   ├── Zones                (folders per zone, streamed in/out)
    │   │   ├── Suroboyo
    │   │   ├── KotaJogja
    │   │   │   └── Leaderboard  (BillboardGui NPC)
    │   │   ├── Semarang
    │   │   ├── Bandung
    │   │   ├── Jakarta
    │   │   └── Serang
    │   ├── Bandara              (airport building model, shared prefab)
    │   └── Pelabuhan            (seaport building model, shared prefab)
    └── NPCs
```

---

## 20. Indonesian Culture System

### 20.1 Cultural Lore Cards

Every food, clothing, collectible, and weapon item has an optional **Lore Card** — a short info panel (2–3 sentences) explaining its real-world cultural origin.

- Accessible by long-pressing/hovering an item → tap "Tentang Item"
- Written in both Bahasa Indonesia and English (localization key)
- Example (Keris): *"Keris adalah senjata tradisional Jawa yang juga merupakan benda pusaka. Keris diakui UNESCO sebagai Warisan Budaya Tak Benda Dunia sejak 2005."*

### 20.2 Budaya (Culture) Collectible Category

A dedicated sub-type within Koleksi items: **Budaya** collectibles are cultural artifacts, each tied to a specific region.

| Collectible | Region | Rarity |
|---|---|---|
| Wayang Kulit (Arjuna) | Jawa Tengah | Tidak Biasa |
| Batik Parang Scroll | Yogyakarta | Tidak Biasa |
| Perisai Dayak Ukir | Kalimantan | Langka |
| Songket Palembang | Sumatera Selatan | Langka |
| Tau-Tau Toraja | Sulawesi Selatan | Epik |
| Keris Pusaka | Jawa / Bali | Legenda |

All Budaya collectibles show in the Galeri Pribadi. A completion % per region is tracked ("Koleksi Jawa: 2/5").

### 20.3 Regional NPC Flavor

NPCs in each zone speak with regional expressions as flavor (not replacing Bahasa Indonesia — just as natural dialog additions):

| Zone | Flavor expression | Meaning |
|---|---|---|
| Desa Jawa | "Monggo, Mas." | "Please, come in." (Javanese polite) |
| Kota Jogja | "Nuwun sewu, nggih." | "Excuse me, please." |
| Hutan Kalimantan | "Eh, iko datang!" | Greeting (Banjar Malay) |
| Tepi Sungai Musi | "Apo kabar, kawan?" | "How are you, friend?" (Palembang) |
| Tanah Toraja | "Melo' ko?" | "How are you?" (Toraja) |

### 20.4 Traditional Architecture per Zone

Each zone's buildings are built using Roblox parts styled after real regional architecture. Reference assets defined in `AssetConfig.Architecture` (image IDs, part colors, roof style).

| Zone | Roof style | Key material | Distinctive feature |
|---|---|---|---|
| Desa Jawa | Joglo (pyramid) | Kayu jati (teak) | Pendopo open pavilion |
| Kota Jogja | Limasan | Brick + kapur | Gapura / gateway arches |
| Hutan Kalimantan | Betang (longhouse) | Kayu ulin | Elevated on stilts, long |
| Tepi Sungai Musi | Panggung (stilt) | Papan kayu | Built over/beside river |
| Tanah Toraja | Tongkonan | Kayu + bambu | Curved boat-shaped roof |

---

## 21. Out of Scope (v1)

- Firearms or gun combat
- Player vs. Player combat outside rival relationship + non-safe zones
- Guild/clan system
- Auction house
- Fishing minigame (world exists, mechanic deferred)
- Pet system
- Housing

---

## 21. Open Questions

- [x] Day/night cycle: **compressed** — game day ≠ real day; exact ratio TBD by feel-test
- [x] PvP zone: **all zones** allow rival combat
- [x] Gold monetization: player can **topup Gold with Robux**, but Gold also earnable via quests (non-pay-to-win)
- [x] Max active side quests: **5 concurrent** (keeps backlog manageable; enforced server-side)
- [x] Marriage dissolution: **both players agree** OR **admin force-dissolve** (moderation tool)
- [x] Collectible display: **in-game leaderboard** + **dedicated Galeri in-game** room per player

---

## 22. Task System (Tugas)

**Definition:** Tasks are objectives auto-generated by the game system — not from NPCs. Players do not "accept" tasks; they are always active and refresh on schedule. This is separate from Quests (NPC-offered, optional, narrative).

| Concept | Source | Player choice | Resets |
|---|---|---|---|
| **Quest** | NPC dialog | Must accept/decline | Never (per player) |
| **Task** | Game system | Always active | Daily / Weekly |

### 22.1 Daily Tasks (Tugas Harian)

- 5 tasks generated per player per day
- Distribution: 3 Easy + 2 Medium
- Reset at **00:00 WIB (UTC+7)**
- Player can reroll **1 task per day** (costs Rp 500)
- Complete all 5 = **Bonus Peti** (chest: Rp 2.000–5.000 + rare item chance)

**Task types:**
| Type | Example | Difficulty |
|---|---|---|
| Explore | Visit Hutan Larangan | Easy |
| Gather | Collect 3 Kayu | Easy |
| Talk | Talk to 2 NPCs | Easy |
| Craft | Craft any 1 item | Easy |
| Sell | Sell items worth Rp 1.000 total | Easy |
| Buy | Buy from any shop | Easy |
| Combat | Defeat 3 enemies | Medium |
| Deliver | Complete 1 side quest | Medium |
| Collect | Find 1 collectible item | Medium |
| Social | Check a Sahabat's active quest | Medium |

**Rewards per task:**
| Difficulty | Rupiah | Bonus |
|---|---|---|
| Easy | Rp 300–600 | — |
| Medium | Rp 800–1.500 | Small item drop chance |
| All 5 complete | Rp 2.000–5.000 | Rare item chance + morality +3 |

### 22.2 Weekly Tasks (Tugas Mingguan)

- 3 tasks generated per player per week
- Distribution: 2 Medium + 1 Hard
- Reset every **Monday 00:00 WIB**
- No reroll
- Complete all 3 = **◆ 2 Gold + Epik item drop**

**Hard task examples:**
- Complete 3 side quests in one week
- Craft 5 different items
- Defeat 15 enemies
- Earn Rp 20.000 total from selling

### 22.3 Task UI

- **Task Board** panel in HUD (bottom-left by default), toggle with keybind / tap button
- Shows: task name, progress bar (e.g. 2/5), reward preview
- Completed tasks show checkmark + greyed out
- "Claim" button appears when task complete — player must tap/click to collect reward
- Unclaimed rewards persist for 48h before expiring
- Mobile: compact card list; desktop: expandable panel

### 22.4 Task Config in AssetConfig

Task templates defined in `AssetConfig.Tasks` (see Section 17). Server picks randomly from pool, weighted by difficulty quota.

```lua
AssetConfig.Tasks = {
    dailyQuota   = { easy = 3, medium = 2 },
    weeklyQuota  = { medium = 2, hard = 1 },
    rerollCost   = { rupiah = 500 },
    rerollsPerDay = 1,

    allDailyBonus = {
        rupiah = { min = 2000, max = 5000 },
        itemDrop = { chance = 0.4, rarityMin = "TidakBiasa" },
        morality = 3,
    },
    allWeeklyBonus = {
        gold  = 2,
        itemDrop = { chance = 1.0, rarityMin = "Epik" },
    },

    Templates = {
        {
            id         = "T_Explore",
            difficulty = "Easy",
            type       = "Explore",
            titleKey   = "task.explore.title",
            descKey    = "task.explore.desc",
            target     = "any",
            count      = 1,
            reward     = { rupiah = 400 },
        },
        {
            id         = "T_Gather_Kayu",
            difficulty = "Easy",
            type       = "Gather",
            titleKey   = "task.gather.kayu.title",
            descKey    = "task.gather.kayu.desc",
            item       = "Kayu",
            count      = 3,
            reward     = { rupiah = 350 },
        },
        {
            id         = "T_Combat",
            difficulty = "Medium",
            type       = "Combat",
            titleKey   = "task.combat.title",
            descKey    = "task.combat.desc",
            count      = 3,
            reward     = { rupiah = 1000 },
        },
        -- Add more task templates here
    },
}
```

---

## 23. Retention & Engagement Mechanics

These mechanics create habit loops and long-term goals that keep players returning daily.

### 23.1 Login Streak

Daily login tracked per player. Consecutive days = escalating reward.

| Streak Day | Reward |
|---|---|
| Day 1 | Rp 500 |
| Day 2 | Rp 800 |
| Day 3 | Rp 1.000 + Makanan item |
| Day 5 | Rp 2.000 + Tidak Biasa item |
| Day 7 | Rp 3.000 + ◆ 1 Gold |
| Day 14 | Rp 5.000 + ◆ 2 Gold + Epik item |
| Day 30 | Rp 10.000 + ◆ 5 Gold + Legenda item |

- Missing a day resets streak to 1
- Reward popup shown immediately on join if not yet claimed today
- Streak count shown on player profile

### 23.2 Achievement System (Pencapaian)

One-time milestones. Each awards: badge on profile + Rupiah or Gold.

| Category | Example Achievement | Reward |
|---|---|---|
| Social | First marriage | ◆ 1 |
| Social | Have 5 Sahabat | Badge |
| Combat | Defeat 100 enemies | Rp 5.000 |
| Exploration | Visit all zones | ◆ 1 |
| Craft | Craft 10 different items | Rp 3.000 |
| Collection | Collect 50 collectibles | Legenda item |
| Economy | Earn Rp 100.000 total | ◆ 2 |
| Morality | Reach Pahlawan tier | Legenda cosmetic |
| Morality | Reach Penjahat tier | Legenda cosmetic (alt) |
| Quest | Complete all side quests | ◆ 3 + title badge |

Achievements visible on player profile card. Shown as icon grid.

### 23.3 Collectible Leaderboard & Galeri

- **Leaderboard**: top players by collectible count, shown in Pasar Besar zone on a billboard NPC
- **Galeri Pribadi**: each player has an in-game display room (small instanced area) — accessible via profile card or dedicated location in their home zone
- Galeri shows collected items on pedestals/shelves
- Other players can visit and react (like/compliment)
- Rare collectibles glow with rarity color

### 23.4 Variable Reward Loop

Surprise rewards on routine actions to create dopamine variance:

- Enemy defeat: **5% chance** of rare item drop (on top of base loot)
- Shop sell: **rare "lucky sale"** — random +20% bonus Rupiah (3% chance)
- Daily task complete: **random bonus Rupiah** within range (never fixed)
- Crafting: **1% chance** of crafting an "enhanced" version (higher stats/rarity)
- Opening Bonus Peti: animated chest opening, rarity revealed with fanfare

### 23.5 Progress Visibility (Always Show Next Goal)

Players always see what's next:
- Hotbar upgrade progress shown even when not in menu
- Inventory slot counter (e.g., "18/20 — Upgrade Available")
- Quest log shows next main chapter title (locked, grayed out) to create anticipation
- Achievement progress bars (e.g., "Defeated 67/100 enemies")
- Morality bar with next tier threshold shown

### 23.6 Time-Limited Festival Events

Recurring seasonal events with exclusive cosmetic rewards (not pay-walled):

| Event | Season | Zone Spotlight | Exclusive Reward |
|---|---|---|---|
| Lebaran / Idul Fitri | Eid al-Fitr | Desa Jawa + Kota Jogja | Baju Koko, Ketupat display, Sarung batik |
| HUT Kemerdekaan RI | August 17 | All zones (flag decorations) | Pita merah-putih, lomba 17-an emote |
| Tahun Baru Islam | Islamic New Year | Desa Jawa | Sorban, kaligrafi collectible |
| Panen Raya | Mid-year harvest | Desa Jawa + TepiSungaiMusi | Caping (farmer hat), ani-ani tool cosmetic |
| Nyepi Awareness | Bali/Hindu New Year | Tanah Toraja (sacred vibe) | Ogoh-ogoh miniature collectible |
| Festival Danau Toba | Mid-year | (future Sumatra zone preview) | Ulos Batak cosmetic |

- Events last 7–14 days
- Event-exclusive tasks added to daily pool during event
- Event currency (e.g., "Koin Lebaran") earned via event tasks, spent at event shop
- Countdown timer shown in HUD during active events

### 23.7 Social Pull Mechanics

- **Sahabat quest sharing**: see friend's active quest marker on compass — natural co-op incentive
- **Rival notification**: rival enters your zone → subtle HUD ping
- **Galeri visit**: notification when another player visits your Galeri
- **Relationship milestones**: "You and [Player] have been Sahabat for 7 days!" — badge upgrade
- **Leaderboard FOMO**: top 3 collectible holders shown by name in Pasar Besar

### 23.8 Progression Sinks (Rupiah/Gold Drain)

Prevents currency inflation, gives spending goals:
- Hotbar slot upgrades (Rp scaling)
- Inventory expansion (Rp)
- Galeri decoration items (Rp + Gold)
- Peta (map) purchase (Rp)
- Daily task reroll (Rp)
- Cosmetic crafting ingredients (Rupiah-expensive)
- Galeri theme unlocks (Gold)

---

## 24. Game Loop Summary

```
[Daily Login]
    ↓
[Login Streak Reward claimed]
    ↓
[Check Daily Tasks + Weekly Tasks]
    ↓
[Core Loop]
    ├── Explore world → find collectibles, lore, world events
    ├── Fight enemies → loot drops, morality shift
    ├── Gather ingredients → Craft items
    ├── Visit shops → Buy/Sell
    ├── Talk to NPCs → Accept/Decline side quests
    ├── Progress main quest
    └── Interact with players → Relationships, Galeri visits
    ↓
[Complete Tasks → Claim rewards → Peti opened]
    ↓
[Progress visible: next tier, next upgrade, next achievement]
    ↓
[FOMO hook: festival timer, rival in zone, Sahabat quest]
    ↓
[Session end — streak maintained — return tomorrow]
```

**Short session (5–10 min):** Login → claim streak → complete 2 easy tasks → done  
**Medium session (20–30 min):** Full daily tasks + 1–2 side quests + shop run  
**Long session (1h+):** Main quest chapter + full weekly task + Galeri decoration + social

---

## 25. Resolved Design Decisions

| Decision | Resolution |
|---|---|
| Day/night cycle | Compressed (game day faster than real time) |
| PvP zones | All zones allow rival combat |
| Gold monetization | Topup via Robux + earnable via quests |
| Max concurrent side quests | 5 per player |
| Marriage dissolution | Both players consent OR admin force-dissolve |
| Collectible display | In-game leaderboard (Pasar Besar) + Galeri Pribadi room |
