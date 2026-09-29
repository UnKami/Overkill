# Overkill 0.30.0 — Battle Clarity and Cinematic Art Playtest

## Player-facing changes

- Regular encounters, elites and bosses now use one illustrated combat presentation; environment art remains character-free so the live Executioner and enemy are not duplicated in the background.
- The route-map's sword, treasure and other node artwork is explicitly centered inside each circular marker.
- Battle has less persistent HUD clutter. The redundant Enemy Next panel is gone; Combat Log and How to Play are in the Esc menu. Press **I** to open the dedicated two-clock battlefield inspection.
- Battlefield inspection emphasizes both chronometers and reports accumulated full-cycle attack, Block, Strength, Thorns, applied statuses and relic-derived carryover effects. Hidden enemy hours remain hidden; the forecast is explanatory, not a change to combat resolution.
- Battle relics use larger centered object art. The refreshed 26-piece lineup follows the agreed palette: orange Attack, blue Block, purple Buff, green Debuff, blood-red direct Overkill, and mixed hues only when a relic combines represented effects.
- Normal combat attack, contact, hit reaction, damage-number and Overkill animations use a more deliberate roughly 2× duration. Fast Mode remains available for players who prefer the faster cadence.
- Relic Temper actions are now labeled **Upgrade**. Confirming an upgrade plays a roughly 1.5-second transition from the current relic to its improved form before the upgrade is applied. Card Temper remains a separate card-upgrade feature.
- The loading scene now features the Executioner in the bell foundry, replacing the previous abstract loading image.

## Preserved rules and compatibility

No changes are intended to damage values, enemy AI, clock mechanics, relic effects, turn order, progression, battle outcomes or run rules. Existing save data remains compatible. Starting a new run is recommended for visual review. No autoplay was added.

## Verification

Godot 4.5.1 imported the changed assets and exported the Windows resource pack. Eleven self-terminating source suites passed with explicit success markers: clock combat, starter relics, battle arrival and guidance, enemy intent, 54 live forecast comparisons, responsive presentation, 26-relic color language, upgrade integration, 30 cinematic routes, and deterministic encounter playthroughs. The presentation suite checked all 26 relic descriptions in normal and large text, plus bounds at 720p, 1080p and ultrawide. The same eleven suites then passed from the standalone exported Windows executable and PCK; the packaged default game also launched with exit code 0. The installer compiled successfully, and all five portable-ZIP entries match their build-payload SHA-256 values. The silent current-user installer was tested end to end: all five installed files match the exported payload, the installed game launches successfully, and its own uninstaller removes the temporary installation. GitHub reports matching sizes and SHA-256 digests for all three assets; all public download URLs return HTTP 200.

The deterministic encounter fixture wins its trash and elite examples but loses its Act I, Act II, Act III and final-boss examples using a low-variety starter setup. That is a useful warning, not a human full-run balance assessment; this presentation release does not alter enemy or relic balance. The restricted headless runner reports a Windows certificate-store read error and some Godot ObjectDB shutdown notices, but the self-terminating suites return success and produce no script/assertion errors.

The installer is unsigned and its interactive wizard has not been manually stepped through. Human visual acceptance and a realistic full-run balance test remain with the playtester.

The 26 relic illustrations and new loading scene are included. The previously discussed broader batch of 20–40 additional cinematic background images is not included in this release candidate.

## Source and downloads

- Source commit: `cc0fab397663f04c8e67825a597b86c225d73d16`, branch `fix/yonatan-full-ui-polish`; tag `v0.30.0-test` pins the exact game-source commit.
- Playtest tag: `v0.30.0-test`.
- [Windows installer](https://github.com/UnKami/Overkill/releases/download/v0.30.0-test/OverkillSetup-0.30.0.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.30.0-test/Overkill-0.30.0-Windows.zip) · [GitHub release and checksum manifest](https://github.com/UnKami/Overkill/releases/tag/v0.30.0-test).
- This is a prerelease for partner testing. Gameplay remains on the feature branch, separate from the default branch's source state.
