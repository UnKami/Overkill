# OVERKILL — Gap Analysis & Fix Plan

Consolidates every gap found across all spec documents to date. Pass 1 (items 1-18) covers everything found before and during the Gold-removal/Spillage redesign; every item there is resolved. Pass 2 (items 19-30) is a second independent audit done after that redesign landed — on the theory that a big mechanic change is exactly where a fresh gap is most likely to hide, and specifically checking the question the redesign's own handoff notes raised: does the targeting/preview system actually account for what Spillage needs? (It didn't. See #27.) Two genuine judgment calls remain open at the bottom — not spec-writing gaps, but decisions only a human should make.

---

## Tier 1 — Would block or corrupt core implementation if missed

| # | Issue | Resolution status |
|---|---|---|
| 1 | Block/Overkill formula interaction undefined | **Fixed** — data schema doc, Part 1.6. Block depletes first, OK computes off HP only. |
| 2 | AOE overkill summation undefined | **Fixed** — data schema doc, Part 1.6. Sums independently per enemy. |
| 3 | Damage-over-time kills' OK treatment undefined | **Fixed** — data schema doc, Part 1.6. Identical formula to card-source kills. |
| 4 | No `exhaust`/`retain` fields on CardData despite a design doc card requiring Retain | **Fixed** — data schema doc, Part 1.1. |
| 5 | No card-targeting / damage-preview system specced anywhere | **Fixed** — see `overkill-targeting-preview-system.md`. Also resolved the card-play interaction model (#7) and unplayable-card visual state (#8) as part of the same spec, since all three are one connected system. |

---

## Tier 2 — Missing systems that would surface as confusing or inconsistent once players reach them, but don't corrupt underlying logic

| # | Issue | Notes |
|---|---|---|
| 6 | No deck-viewing screen outside combat | **Fixed** — see `overkill-deck-view-screen.md`. Also resolved as one reusable component with contextual action modes (upgrade/removal/reference) rather than separate screens, and reuses the "unplayable"/dimmed visual treatment from the targeting-preview spec for a third context. |
| 7 | ~~Card-play interaction model~~ | **Fixed** — see targeting-preview spec, Section 2. |
| 8 | ~~Unplayable-card visual state~~ | **Fixed** — see targeting-preview spec, Section 5. |
| 9 | Enemy-turn presentation unspecified | **Fixed** — see `overkill-turn-presentation-tutorial-unlock.md`, Part 1. Sequential, left-to-right, reuses the existing intent "about-to-resolve" animation state. |
| 10 | First-time tutorial callout system | **Fixed** — same doc, Part 2. One consistent non-blocking format, fires once per player ever (not once per run) — introduces a small dependency on the still-open save/technical architecture item. |
| 11 | Excess-tier unlock celebration content | **Fixed** — same doc, Part 3. Explicitly names the reward and teases 1-2 newly-available cards rather than leaving discovery implicit. |

---

## Tier 3 — Supporting systems, lower implementation risk, needed for a complete game but not core-loop-critical

| # | Issue | Notes |
|---|---|---|
| 12 | No settings/pause menu, no game-speed option | **Fixed** — see `overkill-pause-settings-confirmation.md`, Parts 2-3. Fast mode compresses animation timing without hiding any feedback information. |
| 13 | No confirmation pattern for irreversible choices | **Fixed** — same doc, Part 1. Two tiers (lightweight inline vs. full modal) depending on how high-consequence and hard-to-undo the action is, plus a separate pattern for mutually-exclusive reward choices. |
| 14 | Title screen and event-node UI lightly specced | **Fixed** — see `overkill-map-generation-audio.md`, Part 3. Title screen reuses the pause menu's settings submenu rather than a separate one; events get a shared choice-presentation component and must trigger identical resource-gain feedback to combat, not a bespoke treatment. |
| 15 | Meta-progression across runs undecided | **Fixed** — see `overkill-technical-architecture-save.md`, Part 1. Recommendation: minimal for v1, only settings/tutorial flags persist, no cross-run unlocks yet — explicitly deferred rather than rejected, pending real playtesting data. |
| 16 | Map generation algorithm (node distribution/branching) | **Fixed** — see `overkill-map-generation-audio.md`, Part 1. Placement rules guarantee a rest site before the boss, no consecutive elites, and a minimum combat-node floor per path so routing choices stay meaningful without letting a path starve the player of OK generation. |
| 17 | Audio design language | **Fixed** — same doc, Part 2. Sound treated as a third encoding channel alongside icon shape and color, with the same attention-priority stagger rule as the visual system, and Overkill given its own scaling, unmistakable sound signature. |
| 18 | Technical architecture / save format | **Fixed** — see `overkill-technical-architecture-save.md`, Parts 2-4. Two-tier JSON save structure (RunSave/MetaSave), full folder structure, and autoload responsibility list. |

---

## Pass 2 — Second audit, after Gold removal / Spillage landed

### Fixed directly

| # | Issue | Resolution status |
|---|---|---|
| 19 | Damage modifier order (Strength/Weak/Vulnerable) and rounding were never defined, despite being the actual arithmetic players are asked to do every turn | **Fixed** — data schema doc, Part 1.6. Strength adds flat, then Weak and Vulnerable multiply in that order, each floored independently. |
| 20 | Multi-hit cards had no rule for what happens to remaining hits once the target dies mid-sequence | **Fixed** — data schema doc, Part 1.6. Hits resolve sequentially against current state; hits after death deal no damage and generate no OK. |
| 21 | `EnemyData.tempered` capped OK generation per its own description, but no field or rule said *what it capped OK to* | **Fixed** — data schema doc, Part 1.2 (`tempered_ok_cap` field) and Part 1.6 (per-hit cap, excess discarded not banked; Spillage checked first). |
| 22 | `EffectData.value` was a hardcoded int with no way to express a scaling value, despite the game design doc's own Trophy card ("150% of your last kill's OK") requiring one | **Fixed** — data schema doc, Part 1.1 (`value_source` / `value_multiplier`, a small closed enum rather than an open formula field). |
| 23 | `OKRunState` had no backing field for 3 of `CardData.excess_gate_type`'s 4 values (`TURN_TOTAL_OK`, `CARD_SOURCED_OK`) or for `value_source == LAST_KILL_OK` — the enum values existed with nothing to check them against | **Fixed** — data schema doc, Part 1.5 (`best_turn_total_ok_this_run`, `best_single_hit_ok_by_card`, `last_kill_ok`). |
| 24 | Dangling cross-reference: `EnemyData.tempered` pointed to "see Part 5," which doesn't exist in the data schema doc | **Fixed** — repointed to 1.6, where the cap rule now actually lives. |
| 25 | Status effect icons have no defined color language of their own — the icon system doc's buff=green/debuff=purple table was explicitly scoped to intent icons only, and the two status icons generated so far (Strength, Weak) invert it | **Rule fixed** — icon system doc, Part 3.1, now explicitly extends the intent color language to all status effects. Whether to regenerate the two existing icons or keep them as a documented exception is still open (see below). |
| 26 | Balance doc's section numbering skipped Section 6 entirely (jumped 5 → 7) | **Fixed** — renumbered 7/8/9 to 6/7/8. No cross-references elsewhere pointed at the old numbers, confirmed by search. |
| 27 | **The targeting/preview system doc had zero mention of Spillage** — it was written before Spillage existed and never updated, so the one system the whole game's skill expression depends on had no answer for "what does the preview show for a Spillage card" | **Fixed** — targeting-preview doc, new Section 3.7. Shows the full chain in deterministic order, an explicit "0 OK (Spillage)" tag on kills in the chain (never silence where a number would be), and an explicit "excess lost" tag if the chain runs out of targets. |
| 28 | No icon/badge exists anywhere for recognizing a Spillage-flagged card at a glance, despite the icon system doc's own "everything recognizable gets an icon" rule | **Fixed** — icon system doc, Part 1 (badge requirement + rationale); art requirements doc, Section C (added to inventory). |
| 29 | Screen composition's attention-priority table assigned "Overkill feedback" the top tier but never mentioned where a Spillage chain-kill's visual ranks | **Fixed** — screen composition doc, Part 1.2: Spillage shares the top tier, since it's the other branch of the same core-mechanic moment, not a lesser event. |
| 30 | The Spillage rule (data schema doc) never defined what makes an enemy "next," or how Spillage composes with AOE and multi-hit cards, or its interaction with Tempered's OK cap | **Fixed** — data schema doc, Part 1.6: deterministic left-to-right row order; one uniform per-hit check regardless of card shape; Spillage checked before the Tempered cap ever applies. |

### Open — genuine judgment calls, not mechanical fixes

| # | Issue | Notes |
|---|---|---|
| 31 | Excess-tier threshold act-gating is ambiguous | `best_single_hit_ok_this_run` is a running max with no act-scoping, so an unusually large Act 1 hit could cross the Act 3 or Act 4 threshold before the player has reached those acts. Is that intended (thresholds are pure OK-magnitude tiers; act numbers are just pacing labels/expectations, not gates), or should a threshold only be checkable once the player has actually reached that act? This changes how the Excess economy actually paces itself, not just how it's worded. |
| 32 | No input-locking policy during animated feedback | Combat animations (kill pops, Spillage chains, enemy-turn sequencing) now take real, specified time to play out. Nothing says whether the player can play — or start dragging, per the preview system — another card while a previous card's animation is still resolving. More load-bearing now than it would've been earlier, since the preview system depends on drag gestures that could overlap with in-flight animations from the previous play. |

---

## Recommended order of attack

Given what's actually blocking versus merely incomplete, as of both passes:

1. **The two open judgment calls (#31, #32)** — both sit directly underneath systems that are otherwise fully specced, so they're the highest-leverage decisions left: cheap to decide now, expensive to discover mid-implementation.
2. **The status-icon regeneration decision (#25)** — a production-cost call, not a spec-writing task; worth deciding before the remaining ~13-18 status icons are batch-generated, so it doesn't get more expensive to fix the longer it waits.
3. **Everything else is resolved.** With Pass 2 closed out, the full spec set — game design, art requirements, data schema, icon system, screen composition, balance baseline, targeting/preview, deck view, turn presentation/tutorial/unlock, pause/settings/confirmation, technical architecture, map generation, and audio — is internally consistent and cross-checked against the delivered art, pending only the two decisions above.

