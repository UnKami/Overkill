# OVERKILL — Targeting & Damage Preview System

This closes the highest-priority gap from the fix plan. Everything else in this game — the archetypes, the Excess-tier gates, the whole "aim for excess" premise — assumes the player can calculate overkill *before* committing a card. If that calculation has to happen after the fact, from memory, the design's core skill expression doesn't actually exist in play. This system is what makes it exist.

---

## 1. The governing rule

**The preview must call the exact same resolution logic that actual combat uses — never a separate, approximate calculation.** This mirrors the OKRunState rule from the data schema doc (never let a UI script independently calculate whether a threshold was crossed): if preview math and real math live in two different places, they will drift, and a preview that's ever wrong is worse than no preview, because it actively teaches the player incorrect numbers. Implement the damage/OK calculation as one shared function; both the live combat resolver and the preview system call into it with a "dry run" flag rather than each having their own copy.

---

## 2. Interaction model (resolves fix-plan gap #7)

**Primary: drag-to-target.** Picking up a card and dragging it toward the enemy row naturally produces a live preview as the drag crosses different enemies — the gesture and the feedback are the same motion, which is why this is the primary model rather than an added feature on top of a different one.

**Accessible alternative: tap-to-arm, then tap-to-target.** Tapping a card once puts it in an "armed" state (visually lifted/highlighted, per 3.1 below) and highlights valid targets; tapping a valid enemy then plays it exactly as if it had been dragged there, showing the identical preview during the armed state as the player's focus/hover moves between candidate enemies (e.g., via a controller or accessibility cursor). Both paths must produce byte-identical preview output, since both call the same shared resolution function per Section 1.

**Cancel**: dragging back into the hand area, or tapping the armed card again, or tapping anywhere that isn't a valid target, cancels cleanly — card returns to hand, no preview, no partial state left behind.

---

## 3. What the preview shows

### 3.1 Non-targeted state (card in hand, not yet picked up)
No preview. Only the card's printed values are visible, per the icon system and screen composition docs already established.

### 3.2 Armed / mid-drag, no valid target under focus yet
Valid enemy targets highlight (a border glow or similar, distinct from the enemy's normal idle state) so the player immediately sees where they *can* target, before deciding *which* one.

### 3.3 Hovering/dragging over a specific valid target
This is the core of the system. Show, directly on or near that enemy:
- Current HP and current Block (if any) — the real, already-known numbers, unchanged formatting from normal combat display.
- **A ghost/preview outcome**, rendered in a visually distinct treatment from confirmed numbers (see 4.1) showing the result of this exact card resolving against this exact enemy right now: either "would take N damage, leaving X HP" if the enemy survives, or "would kill, generating **N OK**" if lethal — computed through the exact same Block-then-HP-then-OK sequence fixed in the data schema doc's combat resolution rules.
- The preview recalculates live and instantly if the drag moves to a different enemy, and disappears the instant the drag leaves all valid targets.

### 3.4 AOE cards — all targets previewed simultaneously
Since an AOE card doesn't need a specific target chosen, its preview appears the moment the card is armed (picked up or tapped), showing a ghost outcome over *every* affected enemy at once, not sequentially. This directly exercises the AOE-summation rule from the data schema doc — the player should be able to see, in one glance, that this AOE kills two enemies for a combined OK total while a third merely takes a clean hit.

### 3.5 X-cost cards
Preview recalculates against however much energy is currently available (X-cost cards spend all remaining energy per the original design), updating live if the player has played other cards this turn that changed their remaining energy before arming this one.

### 3.6 Cards that reference run/combat state (e.g., an Excess-tier card scaling off "150% of your last kill's OK")
These reference an already-known, fixed value at preview time (the last kill's OK total is a real number sitting in `OKRunState`, not a hypothetical) — so the preview for these is a straightforward exact number, no different in confidence from any other preview.

### 3.7 Spillage-flagged cards — this system had no coverage for Spillage until now
Spillage is fixed to the card, not a per-play toggle the player chooses — so the preview never asks "bank or spill," it always shows the Spillage outcome for a Spillage card. But per the user journey doc's Scenario B.5, showing only the chain result isn't enough: the player also needs to see what they're *giving up* by playing this card instead of a banking one, or the opportunity cost is invisible until after the fact.

Show, for a Spillage card targeting a lethal hit:
- The full chain, in the deterministic left-to-right order fixed in the data schema doc (Part 1.6) — a ghost outcome over each enemy the chain would pass through in sequence (ghost HP/death per enemy, same visual language as 3.4's AOE preview), stopping at the first enemy the chain wouldn't kill (that enemy shows a normal "would take N damage" ghost, not a further chain link).
- **An explicit "0 OK (Spillage)" tag** on the killing hits in the chain — never just silence where an OK number would otherwise appear. The whole point of 4.1's ghost/confirmed distinction is that a preview can't be misread as "nothing happens here"; a Spillage kill generating no OK is a result the player needs to see stated, not a number that's simply absent.
- If the card's target would die but no next enemy exists to receive the excess, the preview shows that explicitly too (e.g. a "no target — excess lost" tag) rather than silently showing a clean kill, since that's a real, worse-than-either-option outcome the player should be able to see coming per Section 1's exact-scenario rule (game design doc, Section 2.1).

This reuses the AOE preview's simultaneous-ghost pattern (3.4) rather than inventing a new visual language — a Spillage chain is a sequential special case of the same "show every affected enemy's outcome before commitment" principle, not a different system.

---

## 4. Visual treatment

### 4.1 Ghost/preview values must look distinct from confirmed values — this is a hard rule, not a style preference
A predicted number and an already-resolved number must never share the exact same visual treatment, or players will be unable to tell "this already happened" from "this would happen if I confirm." Preview numbers should use a lighter/semi-transparent version of the same color coding already established (gray for normal damage, amber for OK) — same hue family so the color-meaning mapping stays consistent, reduced opacity or a dashed/outlined number style so its provisional nature is unmistakable at a glance.

### 4.2 Threshold-crossing callout (recommended enhancement)
If the previewed hit would generate enough single-hit OK to cross an Excess-tier threshold not yet met this run, the preview should carry a small distinct highlight (e.g., the ghost OK number gets a brief glow or a small icon badge) — turning "I'm about to unlock something" into a visible, plannable moment rather than a surprise the player only learns about after confirming. This directly reinforces the goal-directed design intent behind the two-step Excess-tier gate.

### 4.3 Priority against the screen composition doc's attention hierarchy
The preview is a *pre-decision* visual, not a *feedback* visual — it should sit clearly below the Overkill-feedback tier in the attention hierarchy (screen composition doc, Part 1.2), since it appears before any commitment and must never be confused with, or visually compete with, the actual resolved-kill animation that fires after the card is played.

---

## 5. Unplayable cards (resolves fix-plan gap #8)

A card the player can't currently afford (insufficient energy) should never enter the armed/draggable state at all — attempting to pick it up should visibly resist (a small shake, or simply not lifting off the hand row) rather than allowing a pick-up that then fails at drop time. The card itself renders dimmed/desaturated while unplayable, using the same "greyed out" visual language already established for locked Excess-tier cards in the shop (icon system doc, Part 4) — one consistent pattern for "not available right now" across the whole game, rather than a separate treatment invented just for hand cards.

---

## 6. Edge cases

- **Buffs/debuffs applied earlier this turn must be reflected in the preview immediately.** If the player played a Strength card two plays ago, every subsequent card's preview must already include that Strength in its predicted damage — since the preview calls the same resolution function as real combat (Section 1), this should be automatic rather than something to separately remember to implement, but it's worth stating explicitly as a test case.
- **Enemy intent changes shown alongside the preview, not hidden by it.** The preview overlays near/on the enemy but must not visually obscure that enemy's already-visible intent icon (icon system doc, Part 3) — the player is often weighing "do I kill this enemy now to deny its incoming attack" and needs both pieces of information simultaneously.
- **Multiple simultaneous drags/inputs are not supported** — only one card can be armed at a time; arming a second card while one is already armed should cancel the first cleanly rather than allowing an ambiguous double-armed state.

---

## 7. What this spec depends on / feeds into

- Requires the shared damage/OK resolution function (Section 1) to exist as a single callable unit before either real combat or preview can be built — recommend building this function itself as the very first piece of combat code, before either consumer.
- Section 3.7's Spillage chain preview depends on the deterministic "next enemy" ordering rule (data schema doc, Part 1.6) — that rule has to exist before the chain preview can be built at all, since without it "next enemy" isn't a well-defined question to answer in a preview.
- Feeds directly into the deck-view and hand-interaction cluster (fix-plan gap #6, #7) — the armed-card visual state and unplayable-card dimming established here should be the same visual language used wherever cards are shown as interactive elsewhere.
