# Overkill 0.32.0 playtest — encounter polish

## What changed

- Enemy families now share the approved obsidian-and-ivory base, with jade feral/decay, amethyst arcane, spectral-rose apparition and blood-red Excess accents. Accent intensity rises with encounter danger; the Executioner's cyan/amber identity remains distinct.
- Relic art is presented as a floating transparent object with subtle, effect-colored light strokes instead of a square framed card. Names, mechanic text and actions remain explicit and readable. Relic art has a restrained reduced-motion-aware idle drift.
- The Keep & Sweep action is larger and more prominent during a full-clock replacement. Actionable controls gain a fine lightning contour on hover/focus, with quiet idle glints only on primary actions; circular map nodes keep circular highlights.
- A reachable map waystone now enters its destination directly. Treasure, rest, shop, event and encounter screens handle their own decisions; the redundant travel confirmation panel has been removed.
- The abandon confirmation hides the pause-menu choices behind it and restores them on Cancel. The pre-battle offer panels now contain only their decision title and action, over the existing cinematic background.
- Clock-pointer transitions are modestly quicker; attack resolution, damage, hit reactions and combat pacing are unchanged.

## Compatibility and verification

No damage values, enemy behavior, relic mechanics, turn order, progression rules or save schema were changed. Start or continue a run as normal; existing saves remain compatible.

Source checks: `map_ux_test.tscn`, `presentation_polish_test.tscn`, `clock_battle_smoke.tscn`, `crystalline_consistency_test.tscn`, and `crystalline_visual_test.tscn`. Rendered UI review covered map, treasure reveal, relic replacement/assembly, pre-battle offers and abandon confirmation. The exported Windows executable launched headlessly from `build/windows` with its exported PCK. The Windows installer compiled successfully. An isolated silent-install smoke attempt did not yield a reliable installer exit status or installed payload, so installation through the wizard remains unverified.

## Delivery status

This is an unsigned Windows playtest prerelease. Install or extract the full package before starting Overkill. The isolated installer run did not establish that the setup wizard and installed application work correctly; if setup fails, use the portable ZIP and report the failure with the log. Existing saves are schema-compatible, though a fresh run is recommended for reviewing the updated map flow and replacement screen.
