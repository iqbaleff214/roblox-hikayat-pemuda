# UI Guidelines

Visual design language for all procedurally-built UIs in this project.
Derived from reference screenshot (`.references/8a55fdee24ffd1f29cf4eb422e4cb98f847429fe_2_690x388.png`).

---

## Color Palette

| Role | Color | RGB |
|---|---|---|
| Panel background | Near-black navy | `(22, 22, 34)` |
| Header bar | Saturated red | `(210, 40, 40)` |
| Header text | Pure white | `(255, 255, 255)` |
| Featured banner bg | Teal / cyan | `(60, 200, 190)` |
| Premium card bg | Purple / violet | `(130, 90, 200)` |
| Currency card bg | Gold / amber | `(200, 160, 40)` |
| Promo banner bg | Saturated green | `(60, 190, 80)` |
| Price badge bg | Dark gold pill | `(170, 130, 20)` |
| XP bar fill | Bright green | `(80, 220, 80)` |
| XP bar track | Dark grey | `(50, 50, 50)` |
| Currency display bg | Dark navy | `(20, 20, 30)` |
| Sidebar button tints | Varies per category — blue `(40,100,200)`, red `(200,50,50)`, orange `(200,120,40)`, green `(40,170,70)` |

All backgrounds use `BackgroundTransparency = 0` (fully opaque).

---

## Corner Radius

| Element | Radius |
|---|---|
| Main panel | `8–12 px` |
| Section cards (featured, premium, currency) | `8 px` |
| Price badge pill | `6 px` |
| Header bar | `8 px` top corners only (achieved by making header a child frame inside rounded panel) |
| Sidebar icon buttons | `6–8 px` |
| XP bar | `UDim.new(0.5, 0)` (fully round caps) |
| Close (X) button | `4 px` |

Use `makeCorner(instance, radius)` consistently — never `BorderSizePixel > 0`.

---

## Typography

| Use | Font | Size | Color |
|---|---|---|---|
| Panel / section title | `GothamBold` | `16–18 px` | White `(255,255,255)` |
| Item name label | `GothamBold` | `11–13 px` | White |
| Item subtitle / description | `Gotham` | `9–10 px` | Light grey `(200,200,200)` |
| Price badge | `GothamBold` | `10–11 px` | White or dark gold `(50,30,0)` |
| Currency HUD | `GothamBold` | `TextScaled` | Gold `(255,215,50)` / Cyan `(100,200,255)` |
| Level label | `GothamBold` | `13 px` | White |
| Streak / secondary info | `Gotham` | `9–11 px` | `(190,190,190)` |

Never use `Font.Legacy` or `Font.Arial`. Default to `GothamBold` for anything interactive or prominent.

---

## Panel Structure

### Modal / shop panel

```
┌──────────────────────────────────┐
│  [HEADER BAR — red, bold title]  │  [X]
├──────────────────────────────────┤
│  [FEATURED BANNER — teal]        │  [price badge]
├──────────────────────────────────┤
│  [card]  [card]  [card]          │  ← premium row (purple)
├──────────────────────────────────┤
│  [card]  [card]  [card]          │  ← currency row (gold)
├──────────────────────────────────┤
│  [PROMO BANNER — full width]     │  ← green, optional
└──────────────────────────────────┘
```

- Panel width: `290–340 px` desktop; `UDim2.new(1,0,1,0)` on mobile.
- Internal padding: `8 px` on all sides.
- Section gaps: `4–8 px` between rows.
- Each section is a child `Frame` with its own background color and `UICorner`.

### Close button (X)

- Square, `32×32 px`, top-right corner of header bar.
- Background: slightly darker red or white at 20% transparency.
- Text: `"X"` or `ImageLabel` with `Assets.Icons.Close`.
- `CornerRadius = UDim.new(0, 4)`.

---

## Cards

### Featured card (teal banner)

- Full-width minus panel padding.
- Height: `~70–80 px`.
- Large icon/image on the left (~50% width), title + subtitle on the right.
- Price badge bottom-right corner (gold pill, `≥ 8 px` inset from edges).

### Item cards (3-column grid)

- Width: `(panelWidth - 2×padding - 2×gap) / 3`.
- Height: `~60–70 px`.
- Icon centered top half, name label bottom, price badge bottom-right or bottom-center.
- Background tint differentiates category (purple = premium/gamepass, gold = currency).

### Price badge

```lua
-- Gold pill badge, bottom-right of card
local badge = Instance.new("Frame")
badge.Size = UDim2.fromOffset(44, 18)
badge.AnchorPoint = Vector2.new(1, 1)
badge.Position = UDim2.new(1, -4, 1, -4)
badge.BackgroundColor3 = Color3.fromRGB(170, 130, 20)
badge.BorderSizePixel = 0
makeCorner(badge, 6)
-- Icon (coin symbol) left; price number right
```

---

## HUD Layout (top-right cluster)

All HUD elements anchor from the top-right corner using `UDim2.new(1, -X, 0, Y)`.

```
top-right corner
│
├── Stats panel  (204×60 px)   @ (1, -214, 0, 10)
│     ├── Stamina bar  full-width strip, 10 px tall, top of panel
│     ├── Gold label   left half, below bar
│     └── Diamond label  right half, below bar
│
├── Vibe Level badge  (110×60 px)  @ (1, -332, 0, 10)
│     ├── "Lv.X"  centered, GothamBold 13 px, gold color
│     └── "Vibe Level"  centered, 9 px, muted gold
│
└── Button grid  (44×44 px buttons, 8 px gap)  @ Y = 78
      slot 1 (leftmost)  Journal   @ (1, -158, 0, 78)
      slot 2 (middle)    Wardrobe  @ (1, -106, 0, 78)
      slot 3 (rightmost) Quest     @ (1, -54,  0, 78)
```

Button grid slot formula (N buttons, 44 px wide, 8 px gap, 10 px edge pad):
```
slotX(i) = -(10 + (N - i) * (44 + 8) + 44)   -- i = 1..N from left
```

---

## Sidebar Icon Buttons

Reference shows a vertical strip of small square buttons on the left edge of the viewport.

- Size: `44×44 px` (same as top-right grid buttons).
- Position: `UDim2.new(0, 8, 0.5, -(N/2)*(44+8))` for vertical centering.
- Each button has a distinct saturated background color matching its category.
- Contains a single `ImageLabel` (icon) centered at `UDim2.fromScale(0.175, 0.175)` size `0.65×0.65`.
- `CornerRadius = UDim.new(0, 8)`.

This pattern is reserved for future expansion; the current project uses a top-right horizontal grid instead.

---

## Bottom HUD Bar

Reference shows a persistent bottom strip:

| Element | Style |
|---|---|
| Level ("LvL 0") | `GothamBold`, white, left-aligned |
| XP bar | Full-width green fill on dark track, round caps, labeled "0/100" |
| Currency ("$0") | Large `GothamBold`, white, centered or right |

Not yet implemented. When added, anchor with `AnchorPoint = Vector2.new(0,1)` at `UDim2.new(0,0,1,0)` and use `IgnoreGuiInset = false`.

---

## Tween Conventions

| Action | Style | Duration |
|---|---|---|
| Panel open/close | Slide + fade, `Quad Out` | `0.25 s` |
| Bar fill update | `Quad Out` | `0.3 s` |
| Completion popup fade | `Quad Out` | `0.5 s` (after 3 s hold) |
| Button pulse (attention) | `Back Out` grow then shrink | `0.15 s` each |
| Earn-gold float-up | `Quad Out`, opacity 1→0 + upward drift | `1.0 s` |

Always destroy tweened labels in `Completed` callback. Never leave floating labels as permanent children.

---

## Accessibility & Platform Notes

- Minimum touch target: `44×44 px` (matches button grid size).
- On mobile (`Platform.isMobile()`): panels go full-screen `UDim2.new(1,0,1,0)`.
- On desktop: panels are fixed pixel size, centered or corner-anchored.
- `SelectionGroup = true` on panels that should receive gamepad focus.
- `GuiService:Select(firstButton)` when opening any panel to support gamepad navigation.
- `TextWrapped = true` on all description labels.

---

## Checklist for New UI Elements

- [ ] `ResetOnSpawn = false` on `ScreenGui`
- [ ] `ZIndexBehavior = Enum.ZIndexBehavior.Sibling`
- [ ] All backgrounds use `makeCorner` — no `BorderSizePixel`
- [ ] Colors sourced from palette table above
- [ ] Icons from `Assets.Icons` — no Unicode emoji
- [ ] Mobile layout branch via `Platform.isMobile()`
- [ ] Tween dismissals clean up with `:Destroy()` in `Completed` callback
- [ ] Price badges follow gold-pill convention
- [ ] Close button at top-right of every modal, fires `hidePanel()`
