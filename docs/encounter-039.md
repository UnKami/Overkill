# Overkill 0.39.0 — Relic execution and battle readability playtest

## What changed

- Multi-hit player relics now complete every printed hit against the chosen target even if an early hit kills it. Each later hit converts its full unblocked damage into Overkill, without redirecting to another enemy. If the player dies from recoil during the sequence, combat still ends immediately. Enemy attacks retain their existing stop-on-player-death behavior.
- Every damaging relic now animates its own artwork travelling through the arena before impact. Multi-hit executions show a separately numbered visual beat for each hit. Relic scale grows with the damage or effect magnitude; impact slashes and sparks are enlarged to match.
- Battle HP, Block and status chips have more room and larger icons/numerals. The combat decision heading uses the same display face and prominent scale as other screen identities.
- Shared screen breadcrumbs are larger and higher contrast wherever screens use the shared frame treatment.

No relic effects, enemy behavior, base damage values, turn order, progression values, save schema or game balance were intentionally changed. Existing saves remain compatible.

## Verification

- Godot 4.5.1 source suites passed: `starter_relic_test`, `clock_battle_smoke`, `clock_encounter_test`, `clock_polish_test`, `battle_guidance_test`, `battle_arrival_test`, `map_ux_test`, `presentation_polish_test`, `crystalline_consistency_test`, `crystalline_visual_test`, `relic_color_language_test`, `enemy_intent_readout_test`, `ux_017_test` and `cinematic_art_test`.
- The twin-hit regression test confirms a 1-HP target hit for 3 + 4 damage banks exactly 7 Overkill while keeping both relic-hit beats in the execution.
- Rendering/layout suites cover multiple window sizes and UI sizes, all 10 enemy presentations and all 30 cinematic art profiles. Headless suites are not a full human campaign playthrough or visual acceptance session.

The Windows runner logs a root-certificate-store warning, plus non-fatal Godot object/render-resource shutdown notices in selected UI tests. These test-runner notices did not fail the suites. The installer is unsigned; see the version-specific release verification report for exported-payload and download status.

## Release source

The `v0.39.0-test` prerelease identifies the exact feature-branch source commit and provides a Windows installer, portable ZIP and SHA-256 manifest. Gameplay remains on `fix/yonatan-full-ui-polish`; default-branch download links are published separately through a documentation-only PR.
