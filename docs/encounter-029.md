# Overkill 0.29.0 — Full interface polish candidate

## Why this pass exists

The cinematic cyan/amber art direction is now strong enough that a single unfinished interface element becomes disproportionately visible. This pass audits the complete playable journey and replaces the remaining developer-looking layouts, native dialogs, repetitive inventories, weak transitions and unsafe text placement before the next player download.

## What changed

- Rebalanced the map around its scenery and route: one clear information column, readable illuminated nodes, compact navigation and no duplicated battle HUD.
- Reconstructed pause, settings, confirmation, tutorial and upgrade overlays in the same dark-glass, cyan, amber and blood-red hierarchy as the game world. Destructive actions are now unmistakably dangerous and explain exactly what is lost.
- Replaced native combat-log and how-to-play dialogs with branded battlefield overlays.
- Rebuilt battlefield inspection around the two enlarged chronometers and a numerical full-cycle forecast of attack, persistent Block, status accumulation and sequence.
- Stabilized battle relic choices so titles never ghost behind art, object renders occupy most of each card, effect plaques stay readable and the player/enemy vitality plates remain low and centered beneath their characters.
- Added stronger scenery and Executioner presence to events, rewards, the first-battle offer, the Reliquary, forge, character selection, run outcomes and act transitions.
- Consolidated duplicate card-upgrade and relic-tempering choices by design. Ownership and eligible-copy counts remain explicit while repetitive copies no longer fill the screen.
- Added a clear completed-state beat to card upgrading and corrected shared card-frame safe margins so rules text cannot sit beneath the decorative border.
- Reworked the Excess milestone as a blood-red rupture over the current scene instead of an isolated blank notification screen.
- Refined rest, shop, victory, defeat and responsive 720p layouts; large accessibility text remains supported.

## Preserved gameplay

Damage values, enemy AI, clock mechanics, relic mechanics, turn order, ability effects, stats, progression, battle outcomes and run rules are unchanged. The 12-copy starter chronometer is still twelve physical relics; grouping only changes how repeated designs are presented. No autoplay was added.

## Verification

- `BATTLE_ARRIVAL_OK`: clean entry, offer, card transformation, HUD placement, illustrated bosses and Heavy Hammer presentation.
- `STARTER_RELIC_OK`: starter composition, persistent Block, absorption, multi-hit, charge, lifesteal, concealed intents and battle reset.
- `ENEMY_INTENT_READOUT_OK`: 30 roster sweeps with bounded readable intent presentation.
- `UX_017_PREVIEW_OK`: 54 live-resolution forecast comparisons without mutating combat state.
- `PRESENTATION_014_OK`: all relic text bounds, replacement controls, 720p large text and ultrawide layout.
- `RELIC_COLOR_LANGUAGE_OK`: 26 unique relics and the five mechanic-bound color families, including genuine dual effects and blood-red Overkill.
- `POLISH_INTEGRATION_OK`: reserve inventory, persistent tempering, shop, enemy profiles, rest and defeat flow.
- `CINEMATIC_ART_TEST_OK`: all 30 canonical cinematic routes exist and are unique.
- `FRONTEND_FLOW_OK`: title, class selection, map, 1080p/720p responsiveness, pause, danger confirmation, Reliquary, forge, settings, rest, shop, event, reward, outcomes, act transition, Excess, continue and replacement confirmation were rendered end-to-end and visually inspected.

The Godot editor parse and all listed source suites exit successfully. The exported Windows runtime independently passes `BATTLE_ARRIVAL_OK`, `RELIC_COLOR_LANGUAGE_OK`, `PRESENTATION_014_OK`, `ENEMY_INTENT_READOUT_OK`, `UX_017_PREVIEW_OK`, `CINEMATIC_ART_TEST_OK` and `FRONTEND_FLOW_OK`. The packaged default executable also remained responsive during an eight-second launch smoke test. Godot still reports the existing ObjectDB/resource-in-use warning while some test scenes shut down; no script, resource or assertion failure accompanies it.

## Local Windows candidate

- Installer: `installer/OverkillSetup-0.29.0.exe` — 277,101,700 bytes — SHA-256 `7ff170a71e94867559aee75e44d31136bdbd3e2164886ecd5a0d6883f90c2c8c`.
- Portable ZIP: `installer/Overkill-0.29.0-Windows.zip` — 305,998,018 bytes — SHA-256 `57ab8ee0592a8dce6c92ab70fdfb1ab238af9bb19e7e159721c19f0047773746`.
- The ZIP contains exactly the tested executable, pack, Godot license, delivery notes and launcher. Every entry hash matches the local build payload.
- This is an unsigned local candidate. It has not been pushed, tagged, uploaded or published on GitHub; the public 0.25.0 links remain unchanged.

## Candidate status and limitations

Implementation source: `02f014d` on `fix/yonatan-full-ui-polish`. Save-compatible; starting a new run is recommended for visual review. Human full-run balance, audio listening and interactive installer-wizard testing remain separate acceptance gates. The build was made from the feature working tree while unrelated pre-existing audio/card import-metadata edits remained present and untouched. This candidate is prepared locally first and is not a public release until its repository publication is explicitly approved and the uploaded assets are re-verified.
