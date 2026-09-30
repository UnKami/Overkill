# Crystalline consistency pass — 0.31.0

The approved Executioner, shop and sanctuary references remain authoritative. This pass restores crystalline facets, luminous fractures and tangible painterly-real materials across the live game, without changing combat data values or enemy patterns.

## Live asset contracts

- 26 clock relics use their original transparent crystalline object art. Orange = attack, blue = block, purple = buff, green = debuff, blood red = direct Overkill. Dual colors require dual mechanical effects.
- Heavy Hammer's inventory object and thrown weapon use the same image.
- All ten enemies have distinct non-player silhouettes and share one illustrated combat pipeline. Nine new transparent images complete the roster; the corrected final crystalline beast is retained.
- Seven new crystalline map symbols are centered on their visible alpha bounds. Their button centers are explicitly aligned to the drawn waypoint circles even when the project theme changes minimum button size.
- Startup and scene changes share a new Executioner-led crystalline bridge painting. All three act transitions use the approved cinematic crystalline illustrations.
- Pre-battle, rest and inventory upgrades all present actual clock relics, never scenery cards.
- The static portrait controls are telemetry/VFX anchors only. They must not draw duplicate fighters over the animated IllustratedStage.
- Screens, story options and events use scenery; relics use transparent objects. Legacy cards stay only for engine/save compatibility.

## Preserved

Original user-selected concept art, Executioner images, original final-boss reference, cracked lens, greed battery, shop and rest backgrounds were not replaced. Existing matching cinematic environments and story paintings remain.

## Retired

26 v2 relic objects, six discarded painterly enemies, three discarded painterly transitions and the old bell-foundry loading painting were removed from the active asset tree. A recoverable local copy and import sidecars are in the ignored, Godot-excluded `.test-artifacts/retired-art-031/`. Tracked retired images also remain recoverable from Git history. Original references are not cleanup targets.

## Verification

- `crystalline_consistency_test.tscn`: live resource routing, object alpha, distinct enemy assets, matching hammer, loading consistency, relic-only compatibility upgrade.
- `map_ux_test.tscn`: circle / hit target / visible artwork centers, direct reachable-path entry, unobstructed abandon confirmation, whole-object relic selection, dedicated treasure reveal.
- `presentation_polish_test.tscn`: all 26 relic effects at normal/large text, replacement states, inspection, 720p and ultrawide.
- `crystalline_visual_test.tscn`: rendered production screens, three maps and act transitions, all ten enemies, no duplicate actors, fighter/choice separation and centered HP.
- `battle_arrival_visual_test.tscn`: arrival choreography, loading transition, upgrade before/after, inspection/manual/log, hammer motion.

Presence and structural tests are not substitutes for visual review. Release notes record the actual source and packaged verification results, and any remaining limits.

