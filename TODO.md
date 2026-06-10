# Let Meow Cook — Team TODO

**Repo:** https://github.com/taltul7721/Let-Meow-Cook  
**Last synced:** `445c66c` — *added flashing to the fridge during tutorial*

Use this list in GitHub Issues or copy tasks into your tracker.  
Mark done with `[x]` when finished.

---

## Keeping this list updated (team workflow)

**A plain markdown file does not update itself** — but this repo has light automation so you do not have to remember every checkbox.

### Automatic (recommended)

When your **PR merges to `main`**, list completed tasks under **“TODO completed”** in the PR description:

```markdown
## TODO completed
- currency-panel-ui
- catnip-tea-order
- sfx-kettle-warm
```

Or put this in a **commit message**:

```text
todo:done:currency-panel-ui
```

A GitHub Action (`.github/workflows/sync-todo.yml`) will check off the matching lines in this file and push the update.

**Task ids** = slug of the **bold title** on each line, e.g.  
`- [ ] **Currency panel UI**` → `currency-panel-ui`  
`- [ ] **\`sfx_ui_tap.ogg\`**` → `sfx-ui-tap-ogg`

### Manual (always OK)

In the **same PR** as your work, change `[ ]` → `[x]` on the task you finished.

### GitHub Issues (optional, fully automatic status)

For bigger tasks, open a **[Task issue](https://github.com/taltul7721/Let-Meow-Cook/issues/new/choose)**.  
When your PR includes `Closes #12` in the description, GitHub **closes the issue automatically** on merge (issue board updates; TODO.md still needs the checkbox or PR list above).

### Before you start

```bash
git pull origin main   # get latest TODO.md + game
```

---

## How we work

| Role | Owns | Does not own |
|------|------|----------------|
| **Visual artist** | PNG/sprites, UI panels, VFX art, background | Godot scripts, scene wiring, game logic |
| **SFX artist** (Tal) | Sound effects, short loops, mix levels | Code, visual art |
| **Dev** | Scenes, scripts, tuning, wiring art + audio into game | Final pixel art / final mixes (uses placeholders until handoff) |

**Handoff rule:** Drop assets in the paths below → Dev wires them in scenes + updates `KitchenLayout` / asset loaders if sizes change.

**Pull before you start:** `git pull origin main`

---

## Planned meals (design target)

**Rule:** Every ingredient comes from the **fridge** first. No free-start stations.

| Order | Display name | Fridge ingredients | Prep flow | Served as |
|-------|--------------|-------------------|-----------|-----------|
| `sushi` | Sushi | Raw fish | Board (chop) → plate | Cut fish on plate |
| `cooked_fish` | Grilled | Raw fish | Board (chop) → grill → plate | Cooked fish on plate |
| `cat_salad` | Cat Salad | Lettuce + tomato (optional) | Board (chop/mix) → plate | Salad on plate |
| `catnip_tea` | Catnip tea | **Catnip** from fridge | Kettle (warm up) → pickup cup → customer | Cup full of catnip tea |

**Fridge UX (dev):** Opening the fridge should show **multiple pickable items** (not fish only). Player taps an ingredient, then follows hints to the right station.

### Catnip tea — intended flow (locked in)

> **Vision:** A **kettle of catnip** on the counter. Player brings catnip from the fridge, uses the kettle, it **gets warmer** while brewing, then **spawns a tea cup full of catnip** to pick up and serve.

1. **Fridge** — player takes **catnip** (leaves / pouch / sprig — artist picks readable shape)
2. **Kettle** — player interacts with the catnip kettle (place catnip in, or tap kettle while holding catnip — dev picks simplest feel)
3. **Warm up** — kettle **heats** (progress bar + steam/VFX; sprite can shift “cool → warm → steaming”)
4. **Spawn** — when done, a **pickup tea cup** appears (full of catnip tea) next to the kettle
5. **Serve** — player selects the cup and taps the customer (**no dinner plate** — cup is its own serve item)

**Artist notes:** Kettle is the hero prop — should read as *catnip tea kettle*, not generic water boiler. Cup icon in speech bubble = same full cup sprite.

**Dev notes:** Reuse `DrinkStation` / `CookingStation` pattern: click kettle → warm timer → spawn `SelectableSource` cup pickup. One brew at a time if kettle is busy (like grill).

**Open design questions** (quick team chat):
- Salad: one ingredient or two? Does salad use the grill at all? (default: **board only**)
- Catnip tea: must player **hold catnip from fridge** before kettle works, or is kettle always “stocked” and fridge step is skipped? (default: **catnip from fridge first** to match pantry rule)

---

## Planned economy & shop (design target)

**HUD today:** timer (top-left) works; top-right still uses the **timer sprite as a placeholder** for score — we want a real **currency UI** there instead.

| System | Purpose | Notes |
|--------|---------|--------|
| **Timer** | 2:00 countdown per run | Already in game (top-left) |
| **Currency** | Spendable money (e.g. meowcoins / fish coins) | Earned from serves (+bonus for fast serve?); **persists between runs** for shop |
| **Run score** | Optional session stat on game over | Can show on game-over screen only, or fold into currency — TBD |

**Shop flow (ideal):**
1. Player finishes a run (timer ends or manual end) → **shop screen** opens (or shop button from title / between runs)
2. Spend currency on **upgrades** (permanent unlocks)
3. Start next run with upgrades active

**Upgrade ideas** (dev implements logic; artist draws icons/cards):

| Upgrade | Effect (example) |
|---------|------------------|
| Faster chop | Board timer −15% |
| Hot grill | Grill timer −15% |
| Calm cats | Customer patience +3s |
| Extra plate | Third serving slot |
| Laser goggles | Shorter laser lock or warning only (no full freeze) |
| Tip jar | +10 currency per serve |
| Fridge stock | Faster ingredient refill |

**Open design questions:**
- Shop opens **only after run ends**, or also a **pause/shop button** mid-kitchen?
- One currency only, or currency + separate “stars” score?

---

## Visual artist — TODO

### P0 — HUD (timer exists — currency + shop entry needed)

> **Current HUD:** `Timer.png` top-left (done). Top-right is still the same timer art with a number — that slot should become **currency**, not a second clock.

- [ ] **Currency panel UI** — coin purse / fish-coin bar (top-right HUD)  
  - Path: `assets/ui/Currency.png` (panel, ~359×149 or match timer height)  
  - Include clear area for **number** (e.g. `1,250`)  
  - Optional: small **coin icon** sprite → `assets/ui/coin_icon.png`  
  - Dev replaces `ScorePanel` placeholder in `demo_kitchen.tscn`

- [ ] **Shop button** — opens upgrade shop (corner HUD or game-over screen)  
  - Path: `assets/ui/shop_button.png` (normal + pressed if separate)  
  - Cute cat-shop vibe (awning, paw, “SHOP” sign — your call)

- [ ] **Laser beam sprite** — horizontal sweep across kitchen  
  - Path: `assets/vfx/laser_beam.png`  
  - Replaces red `ColorRect` placeholder  
  - Tall strip, transparent edges, readable danger color

- [ ] **Laser warning UI** (optional but nice)  
  - Path: `assets/ui/laser_warning.png` or icon  
  - Short “danger” banner; dev can keep text “LASER!” on top

### P1 — New meals (ingredients + results)

All of these are **pulled from the fridge** in-game — art should read clearly at small size.

- [ ] **Fridge ingredient sprites**  
  - `assets/sprite/dish/lettuce.png` (raw)  
  - `assets/sprite/dish/lettuce_chopped.png` (after board)  
  - `assets/sprite/dish/tomato.png` (optional second salad ingredient)  
  - `assets/sprite/dish/catnip.png` — fridge pickup for tea

- [ ] **Finished dish icons** (shown in customer speech bubble)  
  - `assets/sprite/dish/salad_plated.png` — cat salad on plate  
  - `assets/sprite/dish/catnip_tea_cup.png` — **full cup** (same sprite used for pickup + bubble)  
  - Keep existing fish / cut / cooked for sushi & grilled

- [ ] **Fridge interior / picker UI** (if we want more than floating icons)  
  - `assets/ui/fridge_panel.png` — shelf layout for multiple items  
  - Or: individual icons only (dev arranges in bubble)

- [ ] **Catnip kettle station** (core tea prop)  
  - `assets/sprite/tools/kettle_catnip.png` — idle kettle (reads as catnip tea)  
  - `assets/sprite/tools/kettle_warming.png` (optional) — mid-heat frame  
  - `assets/sprite/tools/kettle_steaming.png` (optional) — hot / done frame  
  - `assets/vfx/kettle_steam.png` or particle sheet — while warming  
  - Brew progress can reuse progress bar art

- [ ] **Tea cup pickup** — spawned beside kettle when brew finishes  
  - `assets/sprite/dish/catnip_tea_cup.png` (match bubble icon above)  
  - Optional: slight steam on cup rim

### P2 — Game feel

- [ ] **Serve / success VFX** — sparkle or heart pop when cat is served  
  - Path: `assets/vfx/serve_sparkle.png`

- [ ] **Angry cat leave** — small puff or stomp when patience runs out  
  - Path: `assets/vfx/angry_puff.png`

- [ ] **Chop & sizzle particles** — simple 2–4 frame sprites (optional)  
  - Path: `assets/vfx/chop_*.png`, `assets/vfx/sizzle_*.png`  
  - **Salad chop** variant welcome (`chop_leaf_*.png`)

- [ ] **2nd / 3rd cat variant** — three customers all use `cat.png` today  
  - Path: `assets/sprite/cat_2.png`, `cat_3.png`

- [ ] **Game over / time’s up screen**  
  - Path: `assets/ui/game_over.png`

- [ ] **Title / menu screen** (if we want one before kitchen)  
  - Path: `assets/ui/title_screen.png`

### P1 — Shop UI (upgrades)

- [ ] **Shop background panel** — full overlay or centered window  
  - Path: `assets/ui/shop_panel.png`  
  - Room for title (“Cat upgrades”), currency display, scroll/list of items, close button

- [ ] **Upgrade card template** — one row/card per upgrade  
  - Path: `assets/ui/upgrade_card.png`  
  - Slots: **icon**, name, short description, **price**, buy button  
  - States (separate PNGs or one sheet): **available**, **owned/maxed**, **can’t afford** (greyed)

- [ ] **Upgrade icons** — one small icon per upgrade (64×64 or 96×96)  
  - Path: `assets/ui/upgrades/` e.g. `faster_chop.png`, `hot_grill.png`, `calm_cats.png`, `extra_plate.png`, `laser_goggles.png`, `tip_jar.png`, `fridge_stock.png`

- [ ] **Shop buttons**  
  - `assets/ui/btn_buy.png` / `btn_buy_disabled.png`  
  - `assets/ui/btn_close.png`  
  - `assets/ui/btn_play_again.png` (game over → kitchen or shop)

- [ ] **Currency fly VFX** (optional) — coin pops toward HUD when customer pays  
  - Path: `assets/vfx/coin_pop.png`

### P3 — Nice to have

- [ ] **App icon** — replace default `icon.svg`  
  - Export 128×128+ PNG → dev imports as project icon

### Optional — when you have time (not mandatory)

> Background feels a bit off right now — a pass would help a lot, but **no pressure** if you're busy on other games. We can ship with the current kitchen and revisit later.

- [ ] **Kitchen background refinement** — lighting, counter alignment, tool placement, color harmony  
  - Path: `assets/sprite/background.png` (keep viewport ~1152×648)  
  - Check alignment with `BackgroundBar.png` (cats sit behind bar, bubbles above)  
  - Note any moved hotspots for dev (fridge, board, stove zones)

---

## SFX artist (Tal) — TODO

Drop files in `assets/audio/sfx/` (create folder). Prefer **`.ogg`** for Godot (small + loops well).  
Naming: `sfx_<action>.ogg` — dev will wire in `KitchenFx` / stations.

### P0 — Core gameplay (need these first)

- [ ] **`sfx_ui_tap.ogg`** — light click when selecting fridge, food, plate, customer  
- [ ] **`sfx_fridge_open.ogg`** — pop / latch when fridge bubble opens  
- [ ] **`sfx_pickup.ogg`** — soft “lift” when taking ingredient from fridge  
- [ ] **`sfx_place.ogg`** — place item on board, grill, or plate  
- [ ] **`sfx_chop.ogg`** — 1–3 variants for knife on board (fish + salad)  
- [ ] **`sfx_grill_sizzle.ogg`** — looping sizzle while fish cooks (~2–4s loop)  
- [ ] **`sfx_serve_success.ogg`** — happy chime / ding when correct order served  
- [ ] **`sfx_serve_fail.ogg`** — short “nope” when wrong item to customer  
- [ ] **`sfx_customer_angry.ogg`** — grumpy meow / leave huff when patience runs out

### P1 — New meals

- [ ] **`sfx_kettle_warm.ogg`** — gentle heat / purr-boil loop while kettle warms up  
- [ ] **`sfx_kettle_done.ogg`** — soft ding when cup spawns (tea ready)  
- [ ] **`sfx_tea_cup_spawn.ogg`** (optional) — light clink when cup appears  
- [ ] **`sfx_salad_toss.ogg`** — quick rustle/chop for salad prep (board)  
- [ ] **`sfx_fridge_rummage.ogg`** (optional) — subtle shuffle when switching fridge items

### P2 — Pressure / juice

- [ ] **`sfx_laser_warning.ogg`** — alarm beep ~1s before laser fires  
- [ ] **`sfx_laser_sweep.ogg`** — zap / hum while beam crosses screen  
- [ ] **`sfx_timer_tick.ogg`** — last 10 seconds of countdown (soft tick or urgency)  
- [ ] **`sfx_game_over.ogg`** — time’s up sting  
- [ ] **`sfx_score_up.ogg`** — short blip when points added

### P1 — Shop & currency

- [ ] **`sfx_coin_collect.ogg`** — coin earned on serve (can layer with serve_success)  
- [ ] **`sfx_shop_open.ogg`** — shop panel opens  
- [ ] **`sfx_shop_buy.ogg`** — successful purchase  
- [ ] **`sfx_shop_cant_afford.ogg`** — short deny when not enough currency  
- [ ] **`sfx_upgrade_equip.ogg`** (optional) — subtle “power up” when upgrade applies next run

### P3 — Ambience (optional)

- [ ] **`amb_kitchen_loop.ogg`** — very quiet kitchen room tone (loop, −20dB-ish under SFX)  
- [ ] **`music_main_loop.ogg`** — cozy cat-café loop if we want music (separate from SFX bus)

### SFX notes for mix

- Keep SFX **short** (most under 1s; loops except sizzle/boil/ambience)  
- Cat-themed but not annoying on repeat — 3 customers + laser = lots of plays  
- Export **44.1kHz or 48kHz**, mono is fine for most one-shots

---

## Dev — TODO

### P0 — Core loop gaps

- [x] **Game over when timer hits 0:00**  
  - `RunTimer` emits `time_expired` — hook screen, freeze input, show score

- [ ] **Multi-item fridge** — all ingredients come from fridge  
  - Fridge bubble shows fish, lettuce, tomato, tea supplies, etc.  
  - Each item is a `SelectableSource` (or picker grid)  
  - Refill / cooldown rules per ingredient TBD

- [ ] **Cat salad order**  
  - Order id: `cat_salad`  
  - Accept chopped lettuce (+ tomato if we add it) on plate  
  - Update: `customer.gd`, `customer_spawner.gd`, `kitchen_guide.gd`, asset loader (rename `FishAssets` → `DishAssets`?)

- [ ] **Catnip tea order**  
  - Order id: `catnip_tea` (display: “Catnip tea”)  
  - Fridge → **catnip** → **catnip kettle** → press/warm (timer + steam FX)  
  - On complete: **spawn tea cup pickup** (`SelectableSource`) beside kettle  
  - Serve **cup directly to customer** — no plate slot (`DrinkStation` / `cooking_station.gd` pattern)  
  - Kettle busy = one brew at a time (like grill)

- [ ] **Currency system** — earn on serve, persist with `save` (file or `user://`)  
  - Replace score-only `customer_spawner` counter with `GameManager` / `CurrencyManager`  
  - HUD: `CurrencyPanel` + label (wire when `Currency.png` lands)

- [ ] **Shop scene** — `scenes/shop.tscn`  
  - List upgrades, prices, owned level, buy button  
  - Open after game over (and/or from shop button on title / HUD)  
  - Apply upgrades at run start (`demo_kitchen.gd` reads upgrade levels)

- [ ] **Upgrade data** — resource or JSON: id, name, max level, price per level, effect  
  - Hook into chop time, grill time, patience, plate count, laser behavior, serve payout

- [ ] **Wire currency + shop + laser art** when visual artist delivers assets

### P1 — Bugs & cleanup

- [ ] **Fix outline shader** — `return` in `fragment()` fails in Godot 4.4  
  - File: `shaders/outline_highlight.gdshader`

- [ ] **Fix duplicate signal connections** on `ServingPlate`

- [ ] **Remove accidental repo files** + gitignore `*.tmp`, `~*`

- [ ] **Tutorial hints** for new orders (fridge flash + text for salad / tea)

- [ ] **Wire SFX** as Tal drops files — central `AudioManager` or per-station hooks

### P2 — Gameplay

- [ ] **Expand `ORDER_OPTIONS`** — sushi, cooked_fish, cat_salad, catnip_tea (spawner avoids duplicate active orders)  
- [ ] **Laser tuning** with 4 order types + 2 min timer  
- [ ] **Customer patience variety** per order difficulty (tea faster? salad slower?)

### P3 — Ship

- [ ] **Web export + GitHub Pages**  
- [ ] **README** — controls, credits (visual art, SFX, dev)

---

## Shared / needs a quick chat

| Topic | Visual artist | SFX (Tal) | Dev |
|-------|---------------|-----------|-----|
| Salad recipe (1 vs 2 ingredients) | Sprite list | Chop/toss sounds | Board + plate logic |
| Catnip tea kettle | Kettle + cup + steam art | Warm loop + cup spawn | Kettle warm → spawn cup → serve |
| Fridge layout | Panel or icon grid | Open + rummage | Multi-select UI |
| Background refinement | Optional pass when free | Ambience mood? | Hotspot realignment |
| Laser fairness with more orders | — | Warning + sweep | Timing tuning |
| Currency vs run score | Currency panel art | Coin collect SFX | One wallet or two stats? |
| Shop when to open | Full shop UI + icons | Buy / deny sounds | After run only vs HUD button |
| Upgrade list & prices | Icon per upgrade | — | Balance + effect code |

---

## Done recently

- [x] Three cat customers, staggered spawn, mixed orders
- [x] 2-minute countdown timer + top-right HUD slot (placeholder — needs **currency** art)
- [x] Laser hazard — locks input during sweep
- [x] Fridge tutorial flash shader (`445c66c`)
- [x] Progress bars, speech bubbles, two plates, fish cooking loop (sushi + grilled)

---

## Asset map (current + planned)

```
assets/ui/Timer.png              → countdown (top-left) ✓
assets/ui/Timer.png              → top-right placeholder ← replace with Currency.png
assets/ui/Currency.png           → currency HUD panel + coin_icon.png (planned)
assets/ui/shop_*.png             → shop panel, button, upgrade cards (planned)
assets/ui/upgrades/*.png         → per-upgrade icons (planned)
assets/ui/Speech_Bubble.png      → customer orders
assets/ui/Progress_Bar*.png      → patience + cooking bars
assets/sprite/cat.png            → all 3 customers
assets/sprite/background.png     → kitchen BG (optional refine later)
assets/sprite/BackgroundBar.png  → counter overlay
assets/sprite/dish/*             → fish + plate (add salad, tea, fridge items)
assets/sprite/tools/*            → fridge, board, stove, kettle_catnip (+ warm/steam states)
assets/sprite/dish/catnip*.png   → fridge catnip + catnip_tea_cup (pickup + bubble icon)
assets/audio/sfx/*               → SFX (Tal) — folder to create
```

---

## Quick commands

```bash
git pull origin main
git status
git add -A && git commit -m "message" && git push
```

### Find a task id quickly

```bash
# Example: "Currency panel UI" -> currency-panel-ui
python3 .github/scripts/sync_todo.py --done currency-panel-ui   # local test only
```
