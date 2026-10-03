# Overkill 0.40.0 — Clockwright Artifacts and defensive relic playtest

## What changed

- The Clockwright now offers three unowned, unique run-wide Artifacts separately from its bound Chronometer relics. One Artifact may be bought per shop visit for 30 Overkill, with the existing per-run category escalation applied at later shops. Artifacts never occupy one of the twelve relic copies or the nine active hour sockets, and are excluded from ordinary relic rewards.
- Four new Artifacts have original transparent object artwork in the current crystalline-magitech direction: Aegis Seed (battle-start Block), Ashen Ledger (Overkill bonus), Deepwell Suture (conditional kill healing), and Verdigris Thorn (opening Weak). Their essence-specific light, slow idle bob and aura pulse are reduced-motion aware. Owned Artifacts appear as compact, inspectable battle HUD icons and briefly animate when their effects trigger.
- Guard Plate increases from 5 to 7 persistent Block; Reinforced Wall from 8 to 10. This is a deliberately modest early-value increase to make defensive blue relics less disposable without changing Block's persistence rules.
- The shop now exposes a visible scroll cue and more compact Artifact shelf so the purchase actions remain visible in the standard desktop layout. The page retains scrolling on smaller windows.

## Mechanics and saves

Run-wide Artifacts are separate from the Chronometer inventory and are saved through the existing run-relic list. Their unique IDs prevent duplicates; the current ordinary run relics keep their existing duplicate behavior. A capped HEAL effect is appended without changing existing serialized effect enum values. Existing saves remain compatible. No autoplay was added.

## Verification

- Godot 4.5.1 passed 15 source suites: `run_artifact_test`, `starter_relic_test`, `clock_battle_smoke`, `clock_encounter_test`, `clock_polish_test`, `battle_guidance_test`, `battle_arrival_test`, `map_ux_test`, `presentation_polish_test`, `crystalline_consistency_test`, `crystalline_visual_test`, `relic_color_language_test`, `enemy_intent_readout_test`, `ux_017_test`, and `cinematic_art_test`.
- The six-encounter automated playthrough won against all sampled encounters from the shipped new-run 500 Vitality baseline. It is an automated balance smoke pass, not a human full-campaign playtest.
- A rendered desktop shop capture was reviewed and prompted a visible-scroll and card-density correction; the final capture shows the Artifact shelf and shop scroll affordance. The in-game battle capture shows the new HUD objects, 500/500 player Vitality, Block, battle-intent panel and 100/100 enemy Vitality at readable 1920×1080 composition.
- The Windows installer compiled. The portable ZIP contains exactly five expected files, each matching the exported payload by SHA-256; its extracted executable passed both `RUN_ARTIFACTS_OK` and a clean headless startup. An isolated silent installer test could not get past Windows shell-folder discovery (`SHGetKnownFolderPath` error `0x80070002`), so wizard installation, installed-app launch and uninstall are explicitly unverified.
- Source tests emit a Windows root-certificate-store warning and some fixtures emit non-fatal Godot object/render-resource shutdown notices. These did not fail the tests.

## Release and limits

The `v0.40.0-test` GitHub prerelease points to the exact source commit identified in its release notes and contains a Windows installer, portable ZIP and SHA-256 manifest. Package and public-download verification are recorded in the release report attached to those notes. The installer is unsigned. Automated fixtures and captures are not a full human campaign or final user visual acceptance; the Artifact prices/effects and defensive balance still need playtesting.
