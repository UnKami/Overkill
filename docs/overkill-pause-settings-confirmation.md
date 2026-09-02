# OVERKILL — Pause Menu, Settings, and Confirmation Convention

Two related Tier 3 items grouped together: the pause menu is where most confirmation-requiring actions (abandon run, return to main menu) actually live, so the convention governing them needs to exist before the menu itself can be considered complete.

---

## PART 1 — Confirmation-dialog convention

Not every irreversible action deserves the same weight. Treating a small OK spend and abandoning a whole run identically would either make routine actions annoying or make a genuinely costly action feel too casual. Two tiers:

### 1.1 Lightweight inline confirm — for routine, low-individual-stakes actions
Used for: card upgrades, card removal (deck-view screen), single-card rewards. The card itself expands slightly in place and shows the exact cost/effect with a confirm/cancel pair, right where the player already is — no separate screen, no full-screen dimming. This is the pattern already established in the deck-view screen spec (Section 4) and should not change here; it's listed as the baseline this section defines, not a new addition.

### 1.2 Full modal warning — for genuinely high-consequence, hard-to-undo actions
Used for: abandoning a run, returning to the main menu mid-run, deleting a save. Characteristics:
- Full-screen dim behind the modal, focus fully on the decision.
- **Explicit consequence text**, not just a yes/no — e.g. "You will lose all progress this run" rather than a bare "Are you sure?" A player should never have to guess what confirming actually does.
- Two clearly differentiated buttons: **Cancel** styled neutrally and positioned as the default/expected action; **Confirm** styled in the game's established danger color (the same red family already used for HP/danger elsewhere) so the visual weight of the button matches the weight of the decision.
- Tapping outside the modal, or a back gesture, always acts as Cancel — never as Confirm. A player should never be able to accidentally confirm a high-stakes action through an ambiguous input.

### 1.3 Relic/reward choice among mutually exclusive options
Not quite the same shape as either tier above — the player is choosing one of several things, not confirming a single action. Recommend: tapping an option previews its full tooltip (this alone causes no commitment), and a separate, clearly distinct "Take this" action confirms the choice. This gives the player an implicit safety step (preview before commit) without a redundant modal on top of a screen that's already built for careful reading (per the icon-vs-text framework's stated exception for reward screens).

---

## PART 2 — Pause menu

### 2.1 Access
A persistent, small pause icon in a fixed screen corner during combat and map screens (extending Zone F from the screen composition doc), plus whatever platform-standard back/escape gesture is appropriate. Opening it freezes game state cleanly — no timers or enemy AI continue to tick in the background; resuming picks up exactly where it left off.

### 2.2 Contents

| Option | Behavior |
|---|---|
| Resume | Closes the menu, unpauses |
| Settings | Opens the settings submenu (Part 3) |
| View Deck | Opens the deck-view screen in reference mode (per that spec's access-point table) |
| Abandon Run | Opens the full modal confirmation (Part 1.2) |
| Return to Main Menu | Same, full modal confirmation if a run is in progress |

### 2.3 What it does not do
The pause menu is not where gameplay-relevant information (current OK, deck contents beyond the reference view, map position) gets re-explained — it's a control surface, not a second HUD. Keep it minimal.

---

## PART 3 — Settings submenu

| Setting | Notes |
|---|---|
| Audio volume (master / music / SFX sliders) | Standard three-slider baseline; ties into the still-open audio design doc for what's actually being adjusted |
| **Game speed / fast mode** | A global multiplier on animation and tween durations — compresses the enemy-turn timing (Part 1 of the turn-presentation doc) and general combat feedback animations for repeat players, without removing or skipping any of the information itself. This is explicitly about *speed*, not about hiding feedback — a fast-mode player should see the exact same OK pops and intent reveals, just faster, never abbreviated or cut. |
| Colorblind-safe mode reminder | Not a new system — the icon system's intent icons and status icons were already specced to be shape-coded, not color-only (icon system doc, Part 3.1), so this setting is really just confirming that guarantee is real, not adding new color-substitution logic. Worth a QA checklist item rather than new design work. |
| Text size | Standard accessibility option, larger scale for card/tooltip text |

**Persistence**: settings are account/device-level, not per-run — they should live in the same persistent save layer as the tutorial-callout flags (fix-plan gap #10's dependency), reinforcing that this technical architecture/save-format item now has three separate features waiting on it (tutorial flags, settings, and any eventual meta-progression per gap #15).
