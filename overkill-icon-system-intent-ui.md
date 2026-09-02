# OVERKILL — Icon System & Intent UI Component Spec

Slay the Spire's core UX trick is that almost nothing requires reading once you know the game: relics are silhouettes, intents are shapes, statuses are stack-numbers on icons. Text exists for the things you genuinely need to read once (a new card, a new relic, the first time you see a status) and disappears from the moment-to-moment loop after that. This document sets the same rule for Overkill.

---

## PART 1 — The universal rule: every recognizable resource gets an icon

**If the player needs to recognize something faster than they can read it, it gets a unique icon. No exceptions, no "we'll add art later" placeholders that ship as text.**

Full list of things this applies to, cross-referenced to the art requirements doc:

| Category | Icon requirement | Reference |
|---|---|---|
| Currencies (Gold, Overkill) | Unique icon each, never confusable | Art doc Section E |
| Card types (Attack/Skill/Power) | Shape-coded badge, not a text label | Art doc Section E |
| Rarity tiers (Common/Uncommon/Rare/Excess) | Color + border treatment, not a printed word | Art doc Section C |
| Status effects (Vulnerable, Weak, Strength, etc.) | Unique icon per status, silhouette-distinct from every other status | Art doc Section E |
| Relics | Unique icon per relic, silhouette-distinct at 32px | Art doc Section D |
| Potions | Unique icon per potion | Art doc Section E |
| Enemy intents (Attack/Defend/Buff/Debuff/Unknown) | Small fixed shared icon set | Art doc Section E, detailed below |
| Map node types (combat/elite/rest/shop/event/boss/treasure) | Unique icon per node type | Art doc Section E |
| Excess-tier gate status (locked/unlocked) | Distinct lock treatment on the card itself | Established in card frame mockup |

**The test for "is this icon good enough": the silhouette test.** Strip the icon to pure black-and-white silhouette at 32px. If a player who already knows the game can't identify it without color or fine detail, the icon fails, regardless of how good it looks at full size in a portfolio. This is the exact failure mode Casey Yano called out with StS2's early relic icons ("if they're just red boxes, it conveys nothing") — test every icon at deployment size, not at generation size.

---

## PART 2 — Icon vs. text: the decision framework

Not everything should be iconified — StS still uses text for card rules and tooltips. The dividing line is **recognition frequency**, not "is this important."

| Checked how often? | Format | Examples |
|---|---|---|
| Every single turn, at a glance, mid-decision | Icon only, or icon + number | Enemy intent, Block amount, Energy remaining, OK counter |
| Every combat, but with a moment to look | Icon + number, tooltip has full text on hover | Status effect stacks, relic passive icons |
| Once per pickup / first encounter, then rarely again | Icon + short text acceptable | New relic pickup screen, new card reward screen, potion pickup |
| Needs exact precision the player must calculate against | Numeric text is mandatory, never abstracted | Enemy HP, incoming attack damage, OK generated per hit — Overkill's whole mechanic runs on exact arithmetic, so this category can never be replaced with a vague icon or tier |
| Narrative, flavor, one-time explanation | Full text, no icon substitute expected | Card flavor text, relic flavor text, tutorial popups, event story text |

**Practical rule of thumb**: if the player will see this specific piece of information more than, say, 20 times in a run, it needs to be recognizable without reading. If they'll see it once or twice, text is fine and often clearer.

**Never mix formats for the same category inconsistently** — if Strength shows as an icon+number, every stacking status must follow the same pattern (icon+number), not some as icons and others as sentences. Consistency of *pattern*, not just individual icon quality, is what makes a UI feel intuitive rather than memorized case-by-case.

---

## PART 3 — Intent Icon Component (detailed spec)

This is the highest-frequency, highest-stakes icon in the game — read incorrectly or too slowly, and every subsequent decision that turn is wrong. It gets the most rigorous spec.

### 3.1 Anatomy

```
        ┌─────────────┐
        │   [ICON]    │   <- shape-coded by intent type, color-coded as reinforcement
        │      18     │   <- value badge, bottom-right overlap, always exact number when numeric
        └─────────────┘
              ▲
     anchored above enemy sprite, fixed vertical offset
```

- **Icon shape** (primary identifier — must work in pure silhouette):
  - Attack → sword/blade icon
  - Defend → shield icon
  - Buff (self) → upward chevron/arrow icon
  - Debuff (targets player) → downward chevron/arrow icon
  - Attack + Defend combined → split icon (sword/shield divided diagonally), used when a single enemy move does both
  - Unknown/hidden intent → question mark icon (used sparingly — see 3.4)
  - Multi-hit attack → sword icon + small "×N" multiplier badge (see 3.3, this is Overkill-specific and important)

- **Color** (secondary reinforcement, never sole carrier of meaning — colorblind accessibility):
  - Attack: red family
  - Defend: blue family
  - Buff: green family
  - Debuff: pink/purple family
  - Unknown: neutral gray

- **Value badge**: small circular or pill badge overlapping the icon's bottom-right corner, showing the exact numeric value (damage amount, block amount). Omit only for non-numeric buffs/debuffs where no single number applies (e.g., "applies Weak" with no stacking choice) — in that case the status icon itself appears in the badge position instead of a number.

### 3.2 States

| State | Trigger | Visual behavior |
|---|---|---|
| Revealed | Start of enemy's "thinking" phase, before player acts | Full icon + value visible, static |
| About to resolve | Enemy's turn begins execution | Brief pulse/scale-up animation (150-250ms) drawing eye to which enemy is acting now, especially important in multi-enemy fights |
| Resolved | After the move executes | Icon fades out over the enemy's action, next turn's intent doesn't appear until re-rolled for the following turn — never show a stale intent |

**Never skip the Revealed state, even for scripted/simple enemies.** The fairness contract from the data schema doc (2.2) requires this regardless of how "obvious" an enemy's pattern seems to the designer.

### 3.3 Multi-hit attacks — the Overkill-specific case

Because Overkill math depends on exact incoming and outgoing numbers, a multi-hit enemy attack (e.g., "hits 3 times for 4 each") needs to be legible as *3 separate 4-damage hits*, not a pre-summed "12 damage" — otherwise the player can't reason correctly about their own overkill math when planning a kill across multiple small hits versus one big one. Show this as: sword icon + "4" value badge + a small "×3" multiplier tag beneath or beside the main badge. Never collapse it to a single combined number.

### 3.4 Unknown intent — use sparingly, and mean it

An "unknown" intent (question mark icon) should be reserved for a specific, rare design tool (e.g., a boss with a genuinely randomized first-turn move, or an intentional mystery-enemy mechanic) — not a default state or a placeholder for enemies whose real intent just hasn't been implemented yet. If the fallback icon is showing up on more than a small handful of specific, deliberate enemies, that's a content gap being masked as a feature.

### 3.5 Positioning & scaling across multi-enemy fights

- Anchored at a fixed vertical offset above each enemy's sprite bounding box (not screen-relative), scaling with the enemy's own sprite tier (trash/elite/boss have different sprite canvas sizes per the art doc — offset should feel proportionally consistent across tiers, not identical pixel offset).
- **Intent icons do not shrink below a legibility floor** as enemy count increases. If more simultaneous enemies would force icons smaller than the floor size, that's a signal to cap simultaneous enemy count in encounter design, not to shrink the UI past readability.
- Icons must never overlap each other, the enemy's HP bar, or other enemies' sprites — reserve fixed screen-space slots per enemy position rather than freely floating them.

### 3.6 Suggested Godot component tree

```
IntentIcon (Control)
├── Background (Panel or NinePatchRect) — small rounded backing shape
├── IconTexture (TextureRect) — the shape-coded icon, bound to EnemyMoveData.intent_type
├── ValueBadge (Control)
│   ├── BadgeBackground (Panel, colored by intent type)
│   └── ValueLabel (Label) — bound to EnemyMoveData.intent_value, never hand-typed
├── MultiplierTag (Label, optional, visible only when hit_count > 1)
```

Bind every visible field here to the `EnemyMoveData` schema fields directly (`intent_type`, `intent_value`) — per the data schema doc's presentation contract, this component is the *only* place that data is allowed to reach the screen, so no other script should independently render intent information in a different format.

---

## PART 4 — Full icon frequency/format checklist

Quick-reference table combining Parts 1 and 2 for every icon category in one place, so Claude Code (or a human dev) can check any new UI element against it before building.

| Element | Recognition frequency | Format |
|---|---|---|
| Enemy intent | Every turn | Icon + exact number (Part 3) |
| HP / Block / Energy | Every turn | Icon + exact number |
| Overkill counter | Every kill | Icon + exact number, amber-coded |
| Status effect stacks | Every turn (while active) | Icon + stack number, full text on hover only |
| Card type badge | Every card view | Icon/shape only, no text |
| Rarity | Every card view | Border/color treatment only, no printed word |
| Relic (equipped) | Every glance at relic bar | Icon only, full text on hover/tap |
| Potion (held) | Every glance at potion slots | Icon only, full text on hover/tap |
| Map node type | Every map view | Icon only |
| New relic/card/potion pickup | Once per pickup | Icon + short text (name, effect) — this is the one place first-time text is expected and correct |
| Excess-tier lock status | Every shop visit while locked | Icon (lock) + short numeric requirement text ("25+ OK") — hybrid, since the requirement is a precise number the icon alone can't carry |

---

## PART 5 — Why this matters for "feels like Slay the Spire"

StS's intuitiveness doesn't come from having *less* information on screen than other deckbuilders — a full StS combat screen actually shows a lot: HP, block, energy, hand, draw/discard counts, multiple enemy intents, relic bar, potion slots. What makes it read as clean instead of cluttered is that **every one of those pieces of information has exactly one consistent visual form it always takes**, so the player's eye pattern-matches instantly instead of parsing text. The goal here isn't minimalism — it's consistency of encoding. A dashboard shows you numbers. A game shows you shapes and colors that happen to carry numbers when precision matters.
