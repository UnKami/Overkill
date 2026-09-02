# OVERKILL — Enemy Turn Presentation, Tutorial Callouts, Unlock Celebration

Three smaller items grouped together because each one is mostly confirming a default already implied by other docs, rather than designing something new from scratch.

---

## PART 1 — Enemy turn presentation

**Resolution order: sequential, left to right by enemy position**, not simultaneous and not hidden. This directly follows from the intent-reading philosophy already established (icon system doc, Part 3) — if the player learned to read intents so they could plan around them, resolving all enemies invisibly/instantly would waste that entire system.

- Each acting enemy gets a brief highlight/scale-pulse as it acts — this reuses the "about to resolve" intent state already specced (icon system doc, Part 3.2) rather than inventing a second animation for the same concept.
- **Multi-hit attacks resolve as visibly distinct hits**, not a single combined animation — consistent with the multi-hit intent display rule (icon doc, Part 3.3) that already requires showing "×3 hits of 4" rather than "12 damage." The resolution should honor what the intent promised, hit by hit.
- Default per-enemy action timing: roughly 0.5-1 second, enough to read what happened without feeling sluggish. This is the natural hook for the "fast mode" settings option flagged in the fix plan's Tier 3 (gap #12) — that toggle should compress this timing window, not remove the sequencing itself, since removing sequencing would undercut the intent system even for experienced players.
- **No player input during enemy turn** except pre-committed reactive effects (a relic/card explicitly described as triggering during enemy turn) — this matches the standard deckbuilder convention and avoids inventing a new interaction mode with no design need behind it.
- End of enemy turn transitions cleanly into the player's next turn: new hand drawn, all enemy intents re-rolled and revealed before the player can act — per the fairness contract (data schema doc, 2.2), there is no valid state where it's the player's turn and an enemy's intent isn't already visible.

---

## PART 2 — First-time tutorial callouts

### 2.1 Format (one consistent pattern for all of them)

A short, single-line, non-blocking text anchored near the specific HUD element it explains — never a modal, never something that pauses the game to be read. It fades after a few seconds or dismisses on the player's next input, whichever comes first. Every callout in the list below uses this exact same presentation; there is no case in this game that justifies a full-screen tutorial popup breaking that pattern.

### 2.2 The complete list of first-time moments that need one

| Moment | Anchored near |
|---|---|
| First enemy intent seen | The intent icon itself |
| First Overkill generated | The OK counter in the HUD |
| First Block gained | The Block icon in the HUD |
| First status effect applied (to either side) | The status icon |
| First time an Excess-tier locked card is seen in a shop | The locked card itself |
| First Excess-tier threshold crossed | Folded into the unlock celebration (Part 3) — no separate callout needed here, the celebration itself teaches it |
| First time OK is spent (rest site or shop) | The OK cost being shown |
| First card reward screen | Not needed — this screen is already full-text by design (icon-vs-text framework's stated exception), it doesn't need an additional callout on top of itself |
| First relic picked up | The relic icon once it lands in the relic bar |
| First potion used | The potion slot |

### 2.3 Persistence rule

**Each callout fires exactly once per player, ever — not once per run.** This needs a `tutorial_seen` flag set (a dictionary of moment-id → boolean) stored in whatever persistent save layer ends up covering cross-run data — this is a direct dependency on the still-open technical architecture / save format item (fix-plan Tier 3, gap #18), worth flagging so that work accounts for this small but real piece of persistent state.

---

## PART 3 — Excess-tier unlock celebration content

Resolves the recommendation flagged earlier: **the celebration explicitly names the reward, it doesn't leave discovery implicit.**

### 3.1 Content

- A full-screen (or near-full-screen) beat, distinct from and higher-priority than any other simultaneous animation, per the screen composition doc's attention hierarchy (Part 1.2) — this already sits at the top of that priority order as "Overkill feedback," and this is the single biggest instance of that category in the game.
- Text confirms what happened in plain terms (e.g., "Excess Unlocked" plus the threshold that was crossed) rather than only a numeric flourish.
- **Show a preview of 1-2 newly-available Excess-tier card silhouettes** — not the full card details (that's what the shop/reward screens are for), just enough of a teaser that the player has something concrete to look forward to seeing in the next shop, directly connecting this moment to its actual payoff instead of leaving the player to stumble onto it later and wonder why a card is suddenly purchasable.

### 3.2 Dismissal

Tap/input to dismiss, no fixed auto-timer forcing the player to wait through it — this is a rewarding moment, not an interruption, so it shouldn't feel like it's holding the player hostage. Combat (or whatever screen triggered it) resumes immediately after dismissal.

### 3.3 First-time vs. repeat crossings

Per the data schema doc's explicit note (Part 2.3): this celebration fires **every time a new threshold is crossed for the first time this run**, not muted after the player has seen it once in a previous run — it remains a meaningful in-run event regardless of player experience level, which is the one deliberate exception to the "experienced players see less" pattern established in the user journey's steady-state section.
