# OVERKILL — Data Schema & Presentation Contract

This spec has a deliberate split, and the split is the point: **Part 1 is data** (what Claude Code stores), **Part 2 is presentation contract** (how that data is required to reach the screen). A game built from Part 1 alone will feel like a dashboard — accurate numbers, no legibility. Part 2 exists specifically so that never happens. Every resource in Part 1 links forward to a rule in Part 2; treat that linkage as load-bearing, not optional polish.

---

## PART 0 — The core anti-dashboard rule

State this explicitly to whoever (human or agent) builds the UI layer:

> **No raw data field is ever displayed directly. Every number on screen exists because a specific UI element was designed to show it, with an icon, a color, and — where the player needs to act on it — an animation that draws the eye to it at the moment it changes.**

Concretely this means: don't bind a Label's text directly to `enemy.current_hp`. Bind it through a HealthBar component that owns tween/flash/color logic. Don't print `card.effects` as a debug string in the card tooltip. Render each effect through the keyword system (Part 3) so a Vulnerable-inflicting card shows the Vulnerable icon + stack count, not the word "vulnerable" buried in a sentence.

If at any point the build has a screen where the player has to read more than they can glance at to make a decision (an enemy's full move history, a card's full raw JSON, an inventory list with no icons) — that's the failure mode this document exists to prevent.

---

## PART 1 — Core Data Schemas

All schemas below are written as Godot `Resource` class shapes (field name : type — description). Translate directly into `.gd` `class_name` resources or `.tres` data files; the exact serialization is Claude Code's call, but field names and types here should be treated as the contract other systems build against.

### 1.1 CardData

```
class_name CardData extends Resource

id: String                     # unique, matches art asset filename (see art doc naming convention)
display_name: String
card_type: enum(ATTACK, SKILL, POWER)
rarity: enum(COMMON, UNCOMMON, RARE, EXCESS)
energy_cost: int                # -1 reserved for "X cost" cards
target_type: enum(SELF, SINGLE_ENEMY, ALL_ENEMIES, NONE)

base_effects: Array[EffectData]     # what the unupgraded card does
upgraded_effects: Array[EffectData] # what it does at + level (null-safe: empty = "no change other than stated")
upgrade_level: int               # 0 = base, 1 = upgraded (extend if multi-upgrade is ever added)

excess_gate_threshold: int       # 0 for non-Excess cards. For Excess-tier: the single-hit OK value
                                  # required to unlock purchase (see 1.5 OKRunState)
excess_gate_type: enum(NONE, SINGLE_HIT_OK, TURN_TOTAL_OK, CARD_SOURCED_OK)

flavor_text: String              # short, optional, never load-bearing for understanding the card
rules_text_override: String      # ONLY used if a card's effect can't be expressed via keyword icons —
                                  # see Part 3 before reaching for this field. Should be near-empty in practice.

art_id: String                   # matches art requirements doc naming convention
```

**EffectData (sub-resource, used inside CardData, EnemyMoveData, RelicData):**
```
class_name EffectData extends Resource

effect_type: enum(DAMAGE, BLOCK, DRAW, ENERGY_GAIN, APPLY_STATUS, GAIN_OK, ...)
value: int
status_id: String              # only used if effect_type == APPLY_STATUS, refs StatusEffectData
keyword_icon_override: String  # almost never needed — see Part 3 keyword system first
```

**Why `rules_text_override` exists but should stay nearly empty**: every EffectData should be renderable through the shared keyword/icon system (Part 3). The override field is an escape hatch for genuinely novel one-off effects, not a default. If more than ~10% of cards need it, the keyword system is under-built, not the cards over-designed.

### 1.2 EnemyData

```
class_name EnemyData extends Resource

id: String
display_name: String
tier: enum(TRASH, ELITE, BOSS)
max_hp: int
hp_variance: Vector2i           # min/max roll range for slight per-run variation

move_pool: Array[EnemyMoveData]
move_pattern: enum(SEQUENTIAL, WEIGHTED_RANDOM, SCRIPTED)  # how move_pool is selected each turn

tempered: bool                  # if true, this enemy caps OK generation (see Part 5) — a design lever,
                                 # not a default. Most enemies should be false.
overkill_death_threshold: int   # OK amount above which this enemy uses the "shattered" death
                                 # animation instead of the standard one (see art doc Section G)

art_id: String
```

**EnemyMoveData (sub-resource):**
```
class_name EnemyMoveData extends Resource

move_id: String
intent_type: enum(ATTACK, DEFEND, BUFF, DEBUFF, ATTACK_DEFEND, UNKNOWN)
intent_value: int                # the number shown on the intent icon (e.g. attack damage) — see Part 2.2,
                                  # this MUST be player-visible before the move resolves, no exceptions
effects: Array[EffectData]
```

**The `intent_value` field is not optional and not a "nice to have."** Slay the Spire's entire fairness model rests on the player always seeing what's coming before they commit cards — Overkill inherits that contract. An enemy move without a resolved, displayed intent is a design bug, not a valid state, even during prototyping.

### 1.3 RelicData

```
class_name RelicData extends Resource

id: String
display_name: String
trigger: enum(ON_KILL, ON_OVERKILL, ON_TURN_START, ON_TURN_END, ON_COMBAT_START,
              ON_CARD_PLAYED, PASSIVE_MODIFIER)
effects: Array[EffectData]
condition_data: Dictionary       # trigger-specific params, e.g. { "min_ok": 15 } for a
                                  # "if overkill >= 15" relic — keep this a flat dict, not nested logic,
                                  # so it stays inspectable/debuggable
flavor_text: String
art_id: String
```

### 1.4 StatusEffectData

```
class_name StatusEffectData extends Resource

id: String                       # e.g. "vulnerable", "weak", "strength"
display_name: String
stack_behavior: enum(INTENSITY, DURATION, BOTH)  # Strength = intensity-stacking, Vulnerable = duration
icon_id: String                  # shared icon set, see art doc Section E
description_template: String     # short templated text, e.g. "Takes {value}% more damage" —
                                  # filled at render time, never hand-written per-instance
```

### 1.5 OKRunState (persistent, not a Resource — lives in an autoload singleton)

This is the one piece of state that must survive across the whole run, not per-combat. Keep it centralized in a single autoload (`OKManager` or similar) rather than letting individual scenes track their own copies — the biggest source of "dashboard-feeling" bugs is UI elements drifting out of sync with the real number because three different scripts each cached their own copy.

```
# Autoload singleton, not a per-scene Resource
current_ok: int
best_single_hit_ok_this_run: int      # drives Excess-tier unlock checks
unlocked_excess_thresholds: Array[int] # thresholds already crossed, so re-crossing isn't re-announced
ok_spent_log: Array[Dictionary]        # for a run-summary screen later — optional but cheap to log now

signal ok_gained(amount: int, source: String)      # emitted every time, even small amounts
signal excess_threshold_crossed(threshold: int)     # emitted once per new threshold, ever, this run
```

**Emit both signals from one place only** (wherever damage resolution actually computes OK) — never let a UI script independently calculate "did we cross a threshold." That kind of duplicated logic is exactly how a data layer quietly drifts from what's on screen.

---

## PART 2 — Presentation Contract

Every data structure above has a matching rule here for how it's allowed to reach the player. This section is what keeps the game from feeling like a dashboard.

### 2.1 Cards — read-at-a-glance rule

- **Card rules text, once rendered through the keyword system, should read in under 3 seconds** — roughly one short sentence plus 1-2 keyword icons. If a card needs a paragraph, it's two cards.
- **Numbers on a card face must be the actual current numbers** (post-upgrade, post-relic-modifier if any global modifiers exist) — never a base value the player has to mentally adjust. If Strength adds +3 to an attack card's damage, the card should visually reflect the adjusted number in combat, not the printed base.
- **Excess-tier cards must be visually locked, not hidden**, when their gate is unmet — greyed out with the threshold requirement shown ("requires a 25+ OK kill"), sitting visibly in the shop so the player has a concrete goal, rather than a card that mysteriously doesn't appear until unlocked.

### 2.2 Enemy intents — the fairness contract

- **Every enemy must show an intent icon + value the instant their turn-order slot is determined**, before the player acts. This is non-negotiable per 1.2's note — build the intent UI before building enemy AI variety, so there's never a window where enemies have moves but no visible intent.
- **Intent icons are a small, fixed shared set** (attack/defend/buff/debuff/attack+defend/unknown) — never a bespoke icon per enemy move. Consistency here is what lets players learn the language once and read any new enemy immediately.
- **Damage-type intents show the actual number**, not a vague danger tier ("high/medium/low") — Overkill specifically depends on players doing exact-lethal-vs-overkill math, so approximate intents would actively break the core mechanic.

### 2.3 Overkill feedback — this is the mechanic, so it gets the most feedback budget

- **Normal damage and OK damage are never displayed as a single combined number.** Always two visually distinct numbers (established in the visual-language mockup: gray for base, amber for OK) so the split — the entire point of the game — is legible on every single kill, not just large ones.
- **OK-gain scales its own animation intensity with the amount gained** — a 3 OK kill gets a small pop, a 40 OK kill gets a bigger, longer, screen-reactive moment (per the art doc's VFX section). This is what teaches the player "bigger overkill = more exciting" without a tutorial popup saying so.
- **`excess_threshold_crossed` must trigger a distinct, one-time full-screen beat**, not just a toast notification — this is a run-defining moment (a new card tier just became available) and should feel like one.
- **The OK counter in the HUD must visibly tick up in real time as it's earned**, not silently update between combats. If the player doesn't see the number move at the moment of the kill, the currency stops feeling earned.

### 2.4 Relics — silhouette-first, tooltip-second

- Relic bar shows icon only by default (per art doc's legibility requirement) — full text only on hover/tap, never both at once cluttering the same space.
- **`condition_data` params must be rendered into the tooltip text automatically** from the dictionary (e.g. `{"min_ok": 15}` → "Triggers when you Overkill by 15 or more") — never hand-write relic tooltip strings separately from the data that drives the actual logic. Divergence between what a relic says and what it does is one of the fastest ways a game stops feeling trustworthy.

### 2.5 Status effects — one glossary, everywhere

- All status tooltips render from `description_template` with `{value}` filled in live — never hardcode "Takes 50% more damage" as static text anywhere in the UI. One template, one source of truth, referenced from card previews, status icons, and the end-of-combat summary alike.

---

## PART 3 — Keyword / Icon System (what keeps card text short)

Maintain a single shared lookup (`KeywordRegistry` autoload or a `.tres` table) mapping `status_id` / common effect patterns to `(icon, short_label)`. Any EffectData or StatusEffectData renders through this lookup by default. Concretely:

```
KeywordRegistry:
  "vulnerable" -> (icon: vulnerable_icon, label: "Vulnerable")
  "weak"       -> (icon: weak_icon, label: "Weak")
  "strength"   -> (icon: strength_icon, label: "Strength")
  "block"      -> (icon: block_icon, label: "Block")
  "overkill"   -> (icon: ok_icon, label: "Overkill")   # reserved, amber-coded per style guide
```

New status effects added later should be added here first, before being wired into any card — this ordering keeps the keyword system authoritative rather than catching up to ad hoc card text after the fact.

---

## PART 4 — Build Order for Claude Code

Matches the vertical-slice recommendation from before, now scoped to this schema:

1. `OKRunState` autoload + its two signals — the spine everything else hangs off.
2. `CardData` / `EffectData` + a minimal `KeywordRegistry` (5-6 keywords) — enough to render one real card correctly, text and all.
3. `EnemyData` / `EnemyMoveData` + the intent UI (2.2) — build this before AI variety, per the fairness-contract note.
4. Combat loop wiring card → effect → OK calculation → `ok_gained` signal → HUD response (2.3) — this is the moment to verify the whole chain feels right before adding content volume.
5. `RelicData` + tooltip auto-render from `condition_data` (2.4).
6. `StatusEffectData` beyond the initial 5-6, plus remaining cards/enemies — now that the presentation contract is proven, content scales safely.

Building in this order means the "does it feel like a game" question gets answered at step 4, with almost no content built yet — much cheaper to fix the feel there than after 150 cards exist.
