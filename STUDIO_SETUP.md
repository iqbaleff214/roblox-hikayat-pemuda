# Studio Setup Guide — Hikayat Pemuda

This document covers everything you must configure in Roblox Studio before the scripts can run correctly. Follow sections in order for each Place you set up.

---

## 1. Prerequisites

| Requirement | Version / Notes |
|---|---|
| Roblox Studio | Latest stable |
| Rojo | 7.x — sync via `rojo serve` |
| Wally | Run `wally install` in project root before first sync |
| Selene | For local linting (`selene src/`) |

Run once in project root before opening Studio:

```bash
wally install
rojo serve
```

Keep `rojo serve` running while Studio is open. Rojo syncs `src/` into the DataModel automatically.

---

## 2. Experience Structure (Universe)

1. Create a **Universe** in Roblox Creator Hub.
2. Create **7 Places** inside it — one per island:

| Place Name | Island | Starting Place? |
|---|---|---|
| Jawa | Jawa | **Yes** |
| Sumatera | Sumatera | No |
| Kalimantan | Kalimantan | No |
| Sulawesi | Sulawesi | No |
| Papua | Papua | No |
| NusaTenggara | Nusa Tenggara | No |
| Maluku | Maluku | No |

3. After publishing each Place, copy its **Place ID** into `AssetConfig.Places`:

```lua
-- src/shared/Config/AssetConfig.lua
AssetConfig.Places = {
    Jawa       = { ..., placeId = 123456789 },
    Sumatera   = { ..., placeId = 123456790 },
    -- etc.
}
```

---

## 3. Workspace Settings (per Place)

In Studio → **Home → Game Settings → World** (or set via Properties panel on Workspace):

| Setting | Value |
|---|---|
| `StreamingEnabled` | **true** |
| `StreamingMinRadius` | `64` |
| `StreamingTargetRadius` | `256` |
| `Gravity` | `196.2` (default) |
| `GlobalShadows` | **true** |

> StreamingEnabled is required for zone-based NPC and prop streaming to work correctly. The ZoneService and NPCService rely on zone folders being present or absent based on player proximity.

---

## 4. Required DataStore Setup

In Studio → **Home → Game Settings → Security**:

- Enable **Allow HTTP Requests** — needed for DataService (ProfileService).
- Enable **Enable Studio Access to API Services** — so DataStore works in local test.

> Without this, DataService will fail silently and every player will start with default data.

---

## 5. Rojo File Mapping

After `rojo serve`, the following paths are automatically synced:

| Local path | Roblox path |
|---|---|
| `src/server/` | `ServerScriptService.Server` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared/` | `ReplicatedStorage.Shared` |
| `Packages/` | `ReplicatedStorage.Packages` |
| `ServerPackages/` | `ServerScriptService.ServerPackages` |

> Never manually move or rename these scripts in Studio — Rojo owns the file tree. Any manual edits in Studio will be overwritten on the next sync.

---

## 6. ReplicatedStorage — Manual Folders

`Main.server.lua` creates these automatically at runtime, but you can pre-create them in Studio for cleaner organization:

```
ReplicatedStorage
├── Packages/          ← Rojo-synced (Knit, ProfileService, etc.)
├── Shared/            ← Rojo-synced (Config, Modules)
├── RemoteEvents/      ← Auto-created by Main.server.lua
├── Prefabs/
│   ├── VFX/           ← Place VFX ParticleEmitter models here
│   │   ├── HitSpark
│   │   ├── MoralityRise
│   │   ├── MoralityFall
│   │   └── AchRadiance
│   ├── EventDecor/    ← Place event decoration models here
│   │   ├── Lebaran
│   │   ├── Natal
│   │   └── Kemerdekaan
│   └── GaleriPedestal ← Model used by GaleriService for collectible display stands
└── Assets/            ← Rojo-synced (if you add src/assets/)
```

**VFX Prefabs:** Each child under `VFX/` is a Model containing one or more `ParticleEmitter` parts. VFXController clones these, calls `ParticleEmitter:Emit()`, then auto-destroys via `Debris:AddItem(clone, 3)`. If a prefab is missing, VFXController falls back to a neon Part tween — no error.

**EventDecor Prefabs:** Each child under `EventDecor/` is a Model that EventService clones into zone folders during active festival events. If the folder is missing, decoration placement is silently skipped.

**GaleriPedestal:** A single `Model` used as the display stand template in every player's Galeri. GaleriService clones it into `Workspace/Galeris/[userId]/` at runtime. The model should contain a `Part` to which a `SelectionBox` or `PointLight` is applied for rarity glow. If the prefab is missing, GaleriService will error on collectible placement.

---

## 7. Workspace — Map Hierarchy

`Main.server.lua` auto-creates the top-level folders, but each zone's interior must be built manually in Studio:

```
Workspace
├── Map/
│   ├── Zones/
│   │   └── [ZoneId]/               ← e.g., KotaJogja, Suroboyo
│   │       ├── ZoneBoundary        ← (optional) Part — auto-created from AssetConfig.ZoneBounds if absent
│   │       ├── SpawnPoint          ← Part — player spawn for ferry travel + teleport arrivals
│   │       ├── BandaraTicketCounter  ← Part — required if zone.hasBandara = true
│   │       ├── PelabuhanTicketCounter ← Part — required if zone.hasPelabuhan = true
│   │       ├── [NPC location Parts]  ← one Part per NPC schedule entry (see 7.3)
│   │       └── ... (terrain, buildings, props)
│   ├── NPCs/                       ← NPCService places NPC models here at runtime
│   └── Props/                      ← World props, loot spawns, crafting stations
└── Galeris/                        ← Auto-created by GaleriService (per-player folders)
```

### 7.1 Zone Folder Names

Zone folder names **must exactly match** the keys in `AssetConfig.Zones`:

```
KotaJogja, Suroboyo, Semarang, Bandung, Jakarta, Serang,
BandaAceh, Medan, Padang, Pekanbaru, Palembang, BandarLampung,
PangkalPinang, Jambi, Bengkulu, TanjungPinang,
Pontianak, Banjarmasin, PalangkaRaya, Samarinda, TanjungSelor,
Makassar, TanahToraja, Manado, Gorontalo, Palu, Kendari, Mamuju,
Jayapura, Sorong, Manokwari, Merauke,
Denpasar, Mataram, Kupang,
Ambon, Ternate
```

Each Place only needs the zones for its island. Example for the Jawa Place: create only `KotaJogja`, `Suroboyo`, `Semarang`, `Bandung`, `Jakarta`, `Serang`.

### 7.2 ZoneBoundary Parts

ZoneService checks for an existing `Part` named `ZoneBoundary` inside each zone folder. If found, it uses that part's Size and CFrame directly. If not found, it creates one automatically using `AssetConfig.ZoneBounds[zoneId].center` and `.size`.

**Option A (recommended):** Let ZoneService auto-create boundaries. Add entries to `AssetConfig.ZoneBounds`:

```lua
-- src/shared/Config/AssetConfig.lua
AssetConfig.ZoneBounds = {
    KotaJogja = { center = Vector3.new(0, 0, 0), size = Vector3.new(500, 100, 500) },
    Suroboyo  = { center = Vector3.new(800, 0, 0), size = Vector3.new(600, 100, 600) },
    -- ... one entry per zone in this Place
}
```

**Option B:** Place a transparent `Part` named `ZoneBoundary` manually inside each zone folder in Studio. Set `CanCollide = false`, `Anchored = true`, `Transparency = 1`.

### 7.3 SpawnPoint Parts

Each zone folder needs a `Part` named `SpawnPoint`. TravelService teleports players to this Part when they arrive via ferry or inter-island teleport:

```
Workspace/Map/Zones/KotaJogja/
└── SpawnPoint   ← Part (Anchored=true, CanCollide=false, Transparency=1)
```

If `SpawnPoint` is missing, TravelService falls back to the zone origin — players may spawn inside terrain.

### 7.4 Bandara and Pelabuhan Anchor Parts

TravelService scans zones at startup and adds `ProximityPrompt` objects to these named Parts:

| Part name | Required when |
|---|---|
| `BandaraTicketCounter` | `AssetConfig.Zones[id].hasBandara == true` |
| `PelabuhanTicketCounter` | `AssetConfig.Zones[id].hasPelabuhan == true` |

Place each as a visible desk/counter prop inside the matching zone folder. Set `Anchored = true`. TravelService attaches the prompt at runtime — no manual prompt needed.

Zones that need these Parts (Jawa Place):

| Zone | BandaraTicketCounter | PelabuhanTicketCounter |
|---|---|---|
| Suroboyo | Yes | Yes |
| Semarang | Yes | Yes |
| Bandung | Yes | — |
| Jakarta | Yes | Yes |
| Serang | — | Yes |
| KotaJogja | — | — |

### 7.5 NPC Location Parts

NPCService reads `AssetConfig.NPCs[id].schedule[n].location` and looks for a Part or Attachment with that name inside `Workspace/Map/Zones/[zone]/`. Each NPC needs one Part per schedule entry.

Example for Parmin in KotaJogja:

```
Workspace/Map/Zones/KotaJogja/
├── WarungParmin_Counter   ← Part (Anchored, CanCollide=false) — daytime position
└── Parmin_Home            ← Part (Anchored, CanCollide=false) — nighttime position
```

Required location parts from `AssetConfig.NPCs`:

| NPC | Zone | Location parts needed |
|---|---|---|
| Parmin | KotaJogja | `WarungParmin_Counter`, `Parmin_Home` |
| PakRT | KotaJogja | `PakRT_Office` |
| MbokSari | KotaJogja | `MbokSari_House` |
| PakToha | Suroboyo | `PakToha_Warehouse` |

> If a location part is missing, NPCService spawns the NPC at a random offset near the origin. Acceptable for development, fix before release.

---

## 8. Lighting Service

DayNightService drives `Lighting` automatically via `Lighting.TimeOfDay` each server tick. No manual keyframing in Studio is needed, but the **initial** Lighting properties should be set as a reasonable day baseline so the Place looks correct before the first server tick:

| Lighting property | Recommended starting value |
|---|---|
| `TimeOfDay` | `"12:00:00"` |
| `Brightness` | `2` |
| `Ambient` | `Color3.fromRGB(100, 100, 100)` |
| `OutdoorAmbient` | `Color3.fromRGB(120, 120, 120)` |
| `GlobalShadows` | `true` |
| `FogEnd` | `1000` (or higher for open zones) |

DayNightService tweens `Brightness` and `Ambient` smoothly through dawn/dusk transitions using `TweenService`. The cycle runs at 30 real minutes per full in-game day (`REAL_MINUTES_PER_GAME_DAY = 30`). You can adjust this constant in `AssetConfig` without touching the script.

---

## 9. SoundService Setup

`AudioController` creates BGM and Ambient Sound objects inside `SoundService` at runtime. No manual setup is required.

However, for ambient BGM to work, each zone config must have a valid `bgmId`:

```lua
-- In AssetConfig.Zones:
KotaJogja = {
    bgmId       = "rbxassetid://XXXXXXXX",  -- replace with real asset ID
    ambientSound = "rbxassetid://XXXXXXXX", -- ambient loop (market, birds, etc.)
    ...
}
```

A `Night` BGM must also be set:

```lua
AssetConfig.Audio = {
    BGM = {
        Night = "rbxassetid://XXXXXXXX",  -- shared night theme
    },
    SFX = {
        DialogOpen   = "rbxassetid://XXXXXXXX",
        ZoneEnter    = "rbxassetid://XXXXXXXX",
        MoralityRise = "rbxassetid://XXXXXXXX",
        MoralityFall = "rbxassetid://XXXXXXXX",
    }
}
```

Until real IDs are added, audio plays silence — no errors are thrown.

---

## 10. LocalizationTable Setup

1. In Studio → **View → Asset Manager → LocalizationTable**, create a new `LocalizationTable` directly under the `DataModel` (not inside any service).
2. In the LocalizationTable editor, click **Import** and load `tools/localization.csv`.
3. Set the **Source Language** to `id` (Indonesian) and add `en` (English) as a secondary locale.

> The CSV is at `tools/localization.csv`. It contains all ~140 keys used by AssetConfig and all UI controllers. Re-import after adding new keys.

To check for missing keys, run `tools/CheckMissingKeys.lua` in the Studio Command Bar:

```lua
loadstring(game.ServerScriptService.Server.tools.CheckMissingKeys.Source)()
```

This prints any keys referenced in AssetConfig that are absent from the LocalizationTable.

---

## 11. NPC Model IDs

All `AssetConfig.NPCs[id].modelId` values are currently `"rbxassetid://0"`. NPCService falls back to a blue placeholder block when the ID is 0. To use real models:

1. Upload the NPC model to Roblox.
2. Copy the asset ID.
3. Set it in `AssetConfig.NPCs`:

```lua
Parmin = {
    modelId = "rbxassetid://XXXXXXXX",
    ...
}
```

For portrait images shown in the dialog UI, add a `portrait` field:

```lua
Parmin = {
    portrait = "rbxassetid://XXXXXXXX",  -- 512×512 bust illustration
    ...
}
```

---

## 12. Item & Weapon Image IDs

All `imageId` fields in `AssetConfig.Items` and `AssetConfig.Weapons` are `"rbxassetid://0"`. Replace each once the icon is uploaded. The inventory and shop UIs display a blank square until a real ID is set.

---

## 13. DataStore Keys

DataService uses ProfileService with the key prefix `"HikayatPemuda_v1_"`. If you wipe all player data during development:

1. Change the version suffix (e.g., `"HikayatPemuda_v2_"`) in `DataService.lua`.
2. All players start fresh — previous data is abandoned, not deleted.

> Never change the key prefix in production unless you intend to reset all player progress.

---

## 14. Publishing Workflow

1. Run `wally install` if `Packages/` or `ServerPackages/` changed.
2. Run `rojo serve` and connect Studio.
3. Test locally using **Play Solo** or **Start Server + 2 Players**.
4. Publish via **File → Publish to Roblox** for each Place individually.
5. Update `AssetConfig.Places[id].placeId` for any newly published Place.

---

## 15. Expanding to Other Islands

After the Jawa MVP is stable, add each additional island as a separate Place in the same Universe. **Zero additional scripting is required** — all logic loads automatically from AssetConfig.

1. Duplicate the Jawa Place in Studio: **File → Publish As → New Place in same Universe**.
2. In the new Place, keep only: terrain geometry, model anchor Parts, and any Place-specific props. All scripts sync from the same `src/` via Rojo.
3. Delete or replace Jawa-specific zone folders. Create zone folders for the new island only.
4. Place the required anchor Parts in each new zone (SpawnPoint, BandaraTicketCounter, PelabuhanTicketCounter, NPC location Parts).
5. After publishing the new Place, add its Place ID to `AssetConfig.Places[id].placeId` and re-sync.
6. The shared systems (NPCService, ZoneService, TravelService, QuestService, etc.) handle the new island automatically by reading AssetConfig data for those zones.

**Build order for Jawa MVP** (from TASKS.md):
```
000 → 001 → 002 → 003 → 004 → 005 → 010 → 011 → 012 → 013 → 014
→ 020 → 021 → 030 → 031 → 040 → 041 → 050 → 060 → 063
→ 080 → 081 → 082 → 083 → 084 → 090 → 091 → 096 → 098
```

---

## 16. Per-Place Checklist

Before publishing each Place, verify:

**Workspace / Settings**
- [ ] `Workspace.StreamingEnabled = true`, `StreamingMinRadius = 64`, `StreamingTargetRadius = 256`
- [ ] Initial Lighting properties set (TimeOfDay, Brightness, Ambient, GlobalShadows)
- [ ] DataStore API access enabled in Game Settings → Security

**Zone structure**
- [ ] Zone folders exist with names exactly matching `AssetConfig.Zones` keys
- [ ] `AssetConfig.ZoneBounds` has an entry for each zone in this Place
- [ ] Each zone folder has a `SpawnPoint` Part
- [ ] Zones with `hasBandara = true` have a `BandaraTicketCounter` Part
- [ ] Zones with `hasPelabuhan = true` have a `PelabuhanTicketCounter` Part
- [ ] NPC schedule location Parts placed inside each zone folder

**Assets & Config**
- [ ] `AssetConfig.Places[id].placeId` updated with published Place ID
- [ ] LocalizationTable imported from `tools/localization.csv`
- [ ] `ReplicatedStorage/Prefabs/VFX/` populated (or fallback accepted for dev)
- [ ] `ReplicatedStorage/Prefabs/GaleriPedestal` model present
- [ ] `ReplicatedStorage/Prefabs/EventDecor/` folders present (or skipped silently)
- [ ] NPC `modelId` and `portrait` fields updated (or placeholder blocks accepted for dev)
- [ ] Zone `bgmId` and `ambientSound` fields updated (or silence accepted for dev)

---

## 17. Common Issues

| Symptom | Cause | Fix |
|---|---|---|
| NPCs spawn at random positions | NPC schedule location Part missing | Add Part with matching name inside zone folder |
| Zone never changes | ZoneBoundary too small, wrong center, or ZoneBounds missing | Verify `AssetConfig.ZoneBounds` center/size, or place Part manually |
| Player falls through world on teleport | SpawnPoint Part missing in destination zone | Add `SpawnPoint` Part to that zone folder |
| Proximity prompt not appearing at Bandara/Pelabuhan | Counter Part missing or named incorrectly | Add `BandaraTicketCounter` / `PelabuhanTicketCounter` Part with exact name |
| No audio plays | `bgmId` is `rbxassetid://0` | Replace with real asset ID; silence is not an error |
| Day/Night cycle stuck | DayNightService not loaded | Check Output; ensure `DayNightService` is required in `Main.server.lua` |
| DataStore fails in Studio | API access disabled | Enable in Game Settings → Security |
| Teleport between Places fails | `placeId = 0` | Publish the destination Place and set its ID in AssetConfig |
| VFX shows neon block instead of particles | Prefab missing from `ReplicatedStorage/Prefabs/VFX/` | Add prefab Model or accept fallback during development |
| Galeri collectibles don't appear | `GaleriPedestal` prefab missing | Add Model to `ReplicatedStorage/Prefabs/GaleriPedestal` |
| Missing localization keys | CSV not imported, or new keys added since last import | Re-import `tools/localization.csv`; run CheckMissingKeys tool |
| Knit fails to start | Service require error or missing Packages | Run `wally install`, reconnect Rojo, check Output for the specific error |
