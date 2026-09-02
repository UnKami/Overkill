# OVERKILL — Tutorial Callout & First-Time Onboarding Spec

This document specifies the **First-Time Tutorial Callout System**, directly resolving **Gap 1** and **Gap 2** identified in `overkill-user-journey.md` (Part 3, Step 3 & Step 12).

---

## PART 1 — Core Philosophy & Guardrails

1. **Teach by play, not by reading**: The core loop and arithmetic click through action and immediate visual feedback (the gray/amber split damage number, intent badges, Chain preview), not explanatory essays.
2. **Zero blocking modals**: No fullscreen popups, no "Press OK to continue" interruptions, no input locks. The player can always ignore a callout and continue playing immediately.
3. **One-time ever, then permanently silent**: Every callout fires exactly once per player profile. Once dismissed, it never renders again on future runs, preserving the pure steady-state loop (governed by `overkill-user-journey.md` Part 2).
4. **Visual non-interference**: Callouts sit in a dedicated floating layer that renders below the Overkill explosion animation (`overkill-screen-composition.md` Part 1.2) so the core feedback is never obscured.

---

## PART 2 — The First-Time Callout Catalog

There are only **5 deliberate callout moments** across the entire onboarding journey:

### 1. `TUTORIAL_FIRST_OK` (The Load-Bearing Moment)
- **Trigger**: The exact frame when a kill produces `ok_gained > 0` for the first time in Combat 1.
- **Anchor Position**: Floating pill anchored directly below the persistent HUD OK counter (Zone D).
- **Text**: *"Excess damage becomes Overkill (OK) — spend it between fights."*
- **Visuals**: Amber accent border (`#EF9F27`), warm dark-iron backing, tiny OK skull icon.
- **Dismissal**: Auto-fades after 4.0 seconds, or instantly upon the player touching/clicking any card or UI element.

### 2. `TUTORIAL_FIRST_INTENT`
- **Trigger**: Combat 1, Turn 1 start (before the player interacts with any card).
- **Anchor Position**: Floating pill anchored 24px above the first enemy's intent badge (Zone B).
- **Text**: *"Enemy intent is locked. Red = incoming damage next turn."*
- **Visuals**: Crimson accent border (`#E24B4A`), sword icon.
- **Dismissal**: Auto-fades when the player drags/taps their first card or after 5.0 seconds.

### 3. `TUTORIAL_FIRST_SPLIT_ADD` (Combo Clarification)
- **Trigger**: The first time a player plays a `Split` card into the combat resolution slot / Chain queue with an `Add` card currently in hand.
- **Anchor Position**: Anchored above the Chain preview area (Zone E/F).
- **Text**: *"Split divides current hit into instances. Add cards hit every instance."*
- **Visuals**: Clean neutral gray/white backing with kinetic slash icon.
- **Dismissal**: Fades when Chain resolves or player plays next card.

### 4. `TUTORIAL_FIRST_REST_UPGRADE`
- **Trigger**: First time entering a Rest Site (Node 8) and hovering/tapping the "Upgrade" option.
- **Anchor Position**: Anchored next to the Upgrade action button.
- **Text**: *"Upgrades cost OK earned from combat kills."*
- **Visuals**: Amber accent border (`#EF9F27`), anvil icon.
- **Dismissal**: On card selection or rest site completion.

### 5. `TUTORIAL_FIRST_EXCESS_GATE`
- **Trigger**: First time opening a Shop containing a locked Excess-tier card.
- **Anchor Position**: Anchored directly above the locked Excess card frame (Zone Shop).
- **Text**: *"Excess cards unlock permanently for this run when you land a single hit meeting their target."*
- **Visuals**: Radiant amber border with lock icon.
- **Dismissal**: On scrolling the shop or clicking away.

---

## PART 3 — Data & State Schema

### 3.1 TutorialState (Stored in Player Profile / Settings Autoload)

```gdscript
class_name TutorialState extends Resource

@export var seen_callouts: Dictionary = {
    "first_intent": false,
    "first_ok": false,
    "first_split_add": false,
    "first_rest_upgrade": false,
    "first_excess_gate": false
}

func should_show(callout_id: String) -> bool:
    return not seen_callouts.get(callout_id, false)

func mark_seen(callout_id: String) -> void:
    seen_callouts[callout_id] = true
    ResourceSaver.save(self, "user://tutorial_state.tres")
```

### 3.2 UI Component Tree

```
TutorialCallout (Control)
├── PanelContainer (NinePatchRect / StyleBoxFlat with ink border & rounded corners)
│   └── HBoxContainer
│       ├── Icon (TextureRect, 24x24)
│       └── MessageLabel (Label, 14pt, autowrap, max_width 280px)
└── AnimationPlayer (fade_in [150ms], idle_pulse, fade_out [200ms])
```

---

## PART 4 — Excess-Tier Unlock Celebration Spec (Resolving Gap 2)

When `excess_threshold_crossed(threshold)` fires (`overkill-data-schema.md` Part 1.5 & Part 2.3):

1. **Visual Presentation**:
   - Screen briefly pauses background battle ticks (300ms freeze-frame).
   - Fullscreen amber shockwave flash radiates outwards from the kill point.
   - Large banner text appears: **"EXCESS UNLOCKED: TIER {N}"** (Amber `#EF9F27` font with dark-iron contour).
   - Subtitle explicitly names the unlocked reward: *"Excess-tier cards now unlocked in upcoming Shops & Card Rewards."*
2. **Timing & Interaction**:
   - Total celebration duration: 1.8 seconds.
   - Any tap/click immediately fast-forwards the celebration to maintain combat flow.
   - Does NOT open a card pick screen mid-fight; simply confirms the unlocked status into `OKRunState.unlocked_excess_thresholds`.
