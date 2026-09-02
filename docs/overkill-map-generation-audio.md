# OVERKILL — Map Generation & Audio Design Language

The final two Tier 3 items. Both are lower-risk than anything already specced, but audio in particular deserves real attention since it's the one sensory channel that's had zero design work so far, despite the rest of this project treating "read at a glance" as a first-class requirement.

---

## PART 1 — Map generation (resolves gap #16)

### 1.1 Structure
A branching node graph per act, StS-standard shape: multiple paths from a bottom entry point converging toward the act boss at the top, each node connecting upward to 1-3 nodes in the next row, giving the player a real (if constrained) choice of route rather than one fixed path.

### 1.2 Node count and type distribution per act
Per the balance doc's existing pacing numbers (16-17 nodes per act, ~8-10 combats, 2-3 elites, 1 boss): the remaining nodes split across rest sites, shops, events, and treasure, roughly in this baseline ratio:

| Node type | Approx. count per act |
|---|---|
| Combat | 8-10 |
| Elite | 2-3 |
| Rest site | 2-3 |
| Shop | 1-2 |
| Event | 2-3 |
| Treasure | 1 |
| Boss | 1 (fixed, end of act) |

### 1.3 Placement rules
- **A rest site is guaranteed on at least one path leading directly into the boss node** — arriving at the act boss with no opportunity to heal or upgrade beforehand would undercut the deliberate risk/reward tension the whole OK-spending economy is built around.
- **No two elites are directly consecutive on the same path** — back-to-back high-difficulty fights with no recovery node between them isn't a meaningful difficulty choice, it's just attrition.
- **Every path must contain a minimum number of combat nodes** (recommend at least 5 of the act's 8-10 combats reachable on any single path) — a path that lets a player avoid nearly all combat would starve them of the primary OK-generation opportunity the whole game is built around, undermining progression more than it rewards clever routing.
- **Shops and rest sites should not cluster on the same path** — spreading economic and recovery nodes across different paths is what makes the route choice a real tradeoff (a path might be combat-heavy-but-reward-empty vs. safer-but-thinner-on-loot) rather than there always being an obviously-correct path.

### 1.4 Seeding
The map is generated from a stored RNG seed (already present in RunSave, per the technical architecture doc) — the same seed should regenerate the identical map, which matters for debugging and for any future seeded/daily-run feature even though that's out of scope for v1.

---

## PART 2 — Audio design language (resolves gap #17)

### 2.1 The governing principle
Sound should reinforce the exact same encoding the visual system already establishes — one consistent sound per recurring event, functioning as a third channel alongside icon shape and color (particularly valuable for players who rely on audio more than color, reinforcing the accessibility intent already built into the colorblind-safe shape-coding rule).

### 2.2 Sound categories needing a distinct, consistent cue

| Event | Design note |
|---|---|
| Card play (per type: Attack/Skill/Power) | Three distinct sound families, not per-card unique sounds — mirrors the shape-coded card-type badge system, same principle applied to audio |
| Normal damage hit | One consistent hit sound |
| **Overkill generated** | Must be its own unique, unmistakable sound — and per the visual system's existing rule (screen composition doc, Part 1.2), this sound's **intensity scales with the OK amount generated**, exactly mirroring the visual pop's scaling. This is the single most important entry in this table, since it's the core mechanic's audio signature. |
| Enemy death (normal vs. Overkill-triggered "shattered") | Two distinct death sounds, matching the two distinct death animations already specced in the art doc |
| Block gained | Distinct from damage sounds |
| Status effect applied | One shared sound family for status application generally, not per-status unique sounds (mirrors the shared keyword/icon registry approach) |
| Enemy intent reveal | Subtle, non-intrusive — this happens constantly and shouldn't fatigue the ear |
| Currency gain (OK, including passive trickle) | One consistent sound, since it's the game's only currency — weightier/more significant than a generic pickup chime given its role as the core mechanic's earned reward |
| **Spillage triggering** (excess carries to next enemy instead of banking as OK) | A distinct "chain" sound, audibly different from the Overkill bank sound, reinforcing that the player made the opposite choice this time — tempo over currency |
| Relic trigger | Small, corner-of-ear confirmation — matches the visual priority rule that relic triggers sit lowest in the attention hierarchy |
| Excess-tier threshold crossed | A genuinely distinct fanfare-level sting, matching the full-screen celebration's visual weight (turn-presentation doc, Part 3) |
| UI navigation (menu taps, card hover) | Minimal, quiet, standard UI click language |
| Victory / defeat | Distinct run-ending stings |

### 2.3 Simultaneous-event handling — audio follows the same stagger rule as visuals
When multiple sounds would fire in the same instant (the same scenario the screen composition doc's Part 1.2 already addresses visually — a single card play can trigger a hit, an Overkill pop, a status change, and a relic trigger all at once), audio should **duck lower-priority sounds briefly** rather than layering everything at full volume, using the identical priority order already established: Overkill feedback > intent > player stats > relics/status. A big Overkill moment should audibly cut through everything else happening at that instant, not compete with it.

### 2.4 Music layers
- **Per-act ambient layer**, shifting with the same per-act palette changes already specced in the art doc — reinforces the "descending through the world" feeling on a second sensory channel.
- **Separate combat layer**, replacing or overlaying the ambient track during fights.
- **Intensity increase for elites and bosses** — a distinct musical escalation, not just a louder version of the same track, so the player's ear immediately registers "this fight is different" before even seeing the enemy's HP bar.

### 2.5 What this depends on
The `AudioManager` autoload flagged as a placeholder in the technical architecture doc (Part 4) is where all of this ultimately gets implemented — this document defines what that manager needs to own; the technical doc already reserved the slot for it.

---

## PART 3 — Title screen and event-node UI (resolves gap #14)

Both were flagged as lower-risk than anything else outstanding, but genuinely open. Quick resolution for each:

### 3.1 Title screen
Logo/key art (per art doc Section H), a "New Run" primary action, "Continue" appearing only when a RunSave exists (per the technical architecture doc's save structure — its presence/absence is the deciding factor, not a separate flag), and a Settings entry point reusing the exact same settings submenu specced in the pause menu doc rather than a separate title-screen-only settings screen. No other UI competes for attention here — this screen's whole job is getting the player into a run or back into their settings, nothing else.

### 3.2 Event nodes
Full text is correct and expected here, per the icon-vs-text framework's stated narrative exception — this isn't a gap in the "icons over text" sense. What was actually missing: a consistent **choice-presentation pattern** so events don't each invent their own layout. Recommend: event art/illustration at the top (per art doc Section F-adjacent scope), narrative text body, then 2-4 choice buttons rendered as a shared component (not custom per event) — each choice button showing a short summary of its likely consequence where that's fair to reveal (some events may deliberately hide the outcome for a genuine gamble, which is a valid design choice, not a UI gap). If an event choice grants OK, a relic, a card, or damages the player, the resulting change should trigger the exact same feedback animations already specced for that resource everywhere else it appears — an event granting OK should look and sound identical to an OK gain from combat.

---

## Closing note

With this, every item in the gap analysis and fix plan is resolved. The full spec set — game design, art requirements, data schema, icon system, screen composition, balance baseline, targeting/preview, deck view, turn presentation/tutorial/unlock, pause/settings/confirmation, technical architecture, and now map generation, audio, title screen, and event nodes — should give Claude Code a complete, internally-consistent picture to build from, with the connections between documents traceable rather than each one existing in isolation.
