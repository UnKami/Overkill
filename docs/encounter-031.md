# Overkill 0.31.0 — Crystalline continuity

A Windows playtest correcting the remaining art-direction and interface inconsistencies. Start a new run for the clearest comparison.

## Changed

- Restored all 26 approved crystalline relic objects and their five mechanic-bound colors. Removed the discarded v2 set from live resources; Heavy Hammer now uses the same object in inventory and animation.
- Completed the ten-enemy crystalline roster: hound, spectral chain-manta, golem, scavenger, scarab, floating choir, mantis, shield-crab, orbiting reliquary and final crystalline beast. The Executioner stays the same in regular, elite and boss battles.
- Removed the duplicate static fighter layer that was covering actor motion. Normalized silhouettes, centered HP beneath each fighter, and separated combatants from relic choices.
- Rebuilt the map around route selection, compact utilities and destination preview before explicit travel. New crystalline symbols are centered on their drawn circles, including after theme minimum-size changes.
- Added the dedicated sealed-cache reward reveal.
- Whole relic objects are selectable, not just their action buttons.
- Converted the remaining pre-battle card-upgrade route to the real relic inventory, with before/after preview and the existing 1.5-second upgrade transformation.
- Connected a new Executioner-led crystalline bridge painting to startup and scene changes. Restored the three crystalline act-transition paintings and fixed their title wrapping/continue cue.
- Preserved the approved shop, rest, character and cinematic world art. Removed 36 discarded images from the active asset tree; recoverable local copies remain outside Godot's resource tree.

## Rules and compatibility

Enemy numbers, AI patterns, clock sequencing, relic values, damage and status rules were not rebalanced. Resource changes only select art. The pre-battle upgrade now improves one actual clock relic instead of an unused legacy card. Existing save schema remains compatible; no player saves were touched during isolated testing. No autoplay was added.

## Verification and limits

Source and packaged verification results are recorded in the GitHub release body and UPDATE_LOG.md. Coverage includes resource consistency, map/treasure interactions, normal and large text, 720p/1080p/ultrawide layouts, full-cycle forecasts, enemy patterns, relic upgrades, rendered screens and all ten combatants.

This is an unsigned prerelease. Final visual acceptance and a complete human campaign playthrough remain open. The deterministic low-variety starter fixture is not a balance acceptance test. Headless Godot may emit Windows certificate-store and ObjectDB shutdown notices; these are reported separately from script/assertion failures.

Press **I** in battle for expanded clock inspection. Press **Esc** for pause, Combat Log and How to Play.

