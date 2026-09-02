# OVERKILL — Screen Composition Spec

Individual components (cards, intents, icons) have been specced already. This document is about how they sit together on one screen — zone hierarchy, spacing rules, and what earns visual priority. A screen with every individual component well-designed can still feel chaotic if there's no rule for how they compete for attention. This is that rule.

---

## PART 1 — Combat screen: zone map and attention hierarchy

### 1.1 Zones (top to bottom)

```
┌───────────────────────────────────────────┐
│  RELIC BAR (left) ── ── ── POTION BAR (right)  │  Zone A — passive, glanceable, never blocks action
├───────────────────────────────────────────┤
│                                             │
│         ENEMY ROW                          │  Zone B — primary decision-making focus
│    [enemy]  [enemy]  [enemy]                │  each with own intent icon + HP bar above
│                                             │
├───────────────────────────────────────────┤
│         PLAYER CHARACTER                    │  Zone C — secondary, reactive (shows Block/status)
├───────────────────────────────────────────┤
│  HP · BLOCK · ENERGY · OK COUNTER           │  Zone D — persistent stat bar, always visible, fixed position
├───────────────────────────────────────────┤
│                                             │
│         CARD HAND (fanned)                  │  Zone E — primary interaction focus, largest touch/click targets
│                                             │
├───────────────────────────────────────────┤
│  DRAW PILE · DISCARD PILE · END TURN         │  Zone F — secondary controls, corner-anchored, low visual weight
└───────────────────────────────────────────┘
```

### 1.2 Attention hierarchy — what wins when things compete

When multiple things animate or update simultaneously (common in this game — a single card play can trigger a damage number, an OK pop, a status icon change, and a relic trigger all at once), they need a resolved priority order so the eye isn't asked to look at four things at once:

1. **Overkill feedback** (Part 2.3 of the data schema doc) — always wins. If a kill generates OK, that animation takes visual priority over simultaneous relic triggers or status icon updates, since it's the core mechanic and the whole point of that moment. **A Spillage chain-kill shares this same top tier** — it's the other branch of the identical core-mechanic moment (spend now vs. bank), not a lesser event, so it never gets bumped down the priority order just because the outcome is 0 OK rather than a number.
2. **Enemy intent reveal / resolution** — second priority, since it affects the player's very next decision.
3. **Player stat changes** (HP loss, Block gain) — third, generally represented as fast, low-drama ticks unless a stat crosses a dangerous threshold (see 1.3).
4. **Relic/status triggers** — lowest priority visually; these should be quick, small, corner-of-eye confirmations, not competing for center-screen attention. A relic firing shouldn't visually upstage the kill that triggered it.

**Practical rule**: when two things happen in the same instant, stagger their animations by 100-150ms rather than firing simultaneously, in priority order above. This is cheap to implement and prevents the "everything flashes at once and I can't tell what happened" problem.

**This staggering is purely visual — it never locks player input.** The player can play or arm their next card immediately, even while a previous card's kill pop, Spillage chain, or relic flash is still animating; new feedback simply queues in behind whatever's already resolving, in the same priority order. This keeps the pace closer to Slay the Spire's than to a fully animation-gated game, and it's the deliberate choice over locking input until each card's feedback finishes — the tradeoff being a player who plays very fast may see several queued animations resolve in a short burst rather than one at a time, which is accepted as the cost of never adding play-to-play friction.

### 1.3 Danger-state escalation (avoiding both silence and alarm fatigue)

- **Player HP below ~25%**: the persistent stat bar (Zone D) should shift to a more urgent visual treatment (e.g., a subtle pulsing red edge on the HP number) — this is the one place breaking from "calm, consistent icons" is correct, because urgency is exactly the information being conveyed.
- **Don't escalate on every hit** — only on crossing the threshold, not every subsequent point of damage below it, or the urgency cue becomes noise and gets tuned out.

---

## PART 2 — Relic bar & potion bar

### 2.1 Relic bar (Zone A, left side)

- Horizontal row, icon-only by default (per icon system doc Part 1) — fixed icon size regardless of how many relics are held; if the row would overflow the screen width, wrap to a second row rather than shrinking icons below the legibility floor established in the intent icon spec.
- **Hover/tap reveals a tooltip** (see Part 3) with name + full effect text — never both icon and text visible simultaneously at rest.
- **On-trigger flash**: when a relic's condition fires, its icon gets a brief highlight pulse (distinct from, and lower-intensity than, the Overkill feedback pulse) so the player can attribute "why did that just happen" back to a specific relic without needing to open a log.
- Order: relics display in the order acquired, left to right — stable ordering matters more than any "smart" sort, since players build spatial memory of where their relics sit.

### 2.2 Potion bar (Zone A, right side)

- Fixed number of slots (matches whatever slot-count the design settles on) shown even when empty — empty slots render as a dim outline, not blank space, so the player always knows their total capacity at a glance.
- Tap/click to use immediately (no separate "select then confirm" step) for time-sensitive combat use, but with a brief confirm-cancel window (e.g., tap-and-hold, or a quick second-tap-to-confirm) to prevent accidental waste — exact interaction model is a build-time UX call, but the requirement is: fast to use, hard to trigger by accident.

---

## PART 3 — Tooltip system (the one place text is allowed to expand)

Tooltips are where the "text only for things read rarely" rule from the icon doc gets its actual implementation.

### 3.1 Trigger and timing

- Desktop/mouse: hover after a short delay (~300-400ms) — long enough to avoid flickering tooltips as the cursor passes over icons en route elsewhere, short enough not to feel unresponsive.
- Touch/mobile: tap-and-hold, or a dedicated info-tap mode — never a tooltip that requires a hover state that doesn't exist on touch.
- Tooltip dismisses immediately on release/tap-away — never lingers or requires an explicit close action.

### 3.2 Content and rendering rule

- **Every tooltip renders from the same data source the game logic uses** — status tooltips from `description_template` (data schema doc, Part 2.5), relic tooltips from `condition_data` auto-rendered into text (data schema doc, Part 2.4). No hand-written tooltip string should ever exist separately from the value driving actual behavior — this is the single most important rule in this section, since a tooltip that says something different from what the game actually does is worse than no tooltip.
- **Card tooltips expand keyword icons inline** — if a card's rules text includes a keyword icon (e.g., the Vulnerable icon), hovering *that specific icon* within the card should show the keyword's full definition, rather than only the card having one big tooltip for everything at once. This lets an experienced player skip tooltips entirely (they recognize the icon) while a new player can drill into exactly the term they don't know yet.

### 3.3 Stacking / z-order

- Only one tooltip visible at a time — opening a new one closes any other, no tooltip pile-ups.
- Tooltips render above all other UI, including other panels/bars, but never above the Overkill feedback animation (Part 1.2's priority order extends here — nothing should visually block the game's core feedback moment, even a tooltip the player is mid-reading).

---

## PART 4 — Other screens: composition notes

Brief zone guidance for the remaining screens, following the same "what wins visual priority" logic as combat:

### 4.1 Map screen
- Node icons (Part 1 of icon doc) are the primary visual element — path lines connecting them are secondary/muted so they guide the eye without competing with the node icons themselves.
- Current position and available next-nodes should be the highest-contrast elements on screen; already-visited and unreachable nodes recede (lower opacity or desaturation), so the "what can I do right now" question is answerable without reading anything.

### 4.2 Shop screen
- With OK as the single currency (game design doc, Section 3.1), there's no currency-based zoning needed anymore — instead, zone the shop by **item category** (cards / relics / potions / services like removal), since those remain meaningfully different decision types even though they're paid from the same pool. A distinct background tint or section divider per category keeps the "what am I even looking at" question answerable at a glance, the same job the old currency-zoning rule was doing, just organized around category instead of currency.
- Locked Excess-tier cards (icon doc, Part 4) sit in their normal shop position rather than a separate "locked items" section — visibility of the goal matters more than tidy categorization.
- Every item's price should be visible at a glance against the player's current OK total — greyed out or marked unaffordable using the same dimmed "not available right now" treatment established in the targeting-preview and deck-view specs, extended here to a fourth context.

### 4.3 Reward / card-pick screen
- This is a "read carefully once" screen, not a glance screen — per the icon-vs-text framework, full text is expected and correct here, this is the exception zone, not a violation of the icon-first rule elsewhere.
- **This screen is never priced.** Cards here are picked freely, per the game design doc's Section 3 — no OK cost, no currency icon anywhere on this screen. This is a deliberate contrast with the shop screen: one is a gift, the other is a spend, and they should look and feel distinct from each other for exactly that reason.

### 4.4 Run-summary / defeat screen
- OK earned/spent this run deserves its own highlighted stat line, not buried in a generic stats list — reinforces the core mechanic even at the meta-level, consistent with the "OK gets the most feedback budget" principle established in the data schema doc.

---

## PART 5 — Cross-screen consistency rule

**Persistent elements never move screen to screen.** The OK counter, HP, Block, and Energy always occupy the same relative screen position whether the player is in combat, a shop, or a reward screen (hiding/graying out fields that don't apply in a given context, rather than relocating the ones that do). This is what lets a player's eye find "how much OK do I have" instantly without hunting, everywhere in the game — the single highest-leverage consistency rule in this whole document, since it's the one piece of UI checked constantly across every screen type.
