# CHANGELOG_AI.md — Multi-AI Handoff & Session Log

This file provides asynchronous context sharing between developers and their AI assistants. When finishing a session or merging a PR, add an entry at the top of this log.

---

### [2026-09-18] — Initial Collaboration Architecture & Full Game Upload
- **Author / AI**: Yonatan & Antigravity
- **Branch**: `main`
- **Key Changes**:
  - Configured repository ignore rules in `.gitignore` to prevent OS files and oversized build binaries from polluting Git.
  - Established universal AI context and multi-developer coordination protocols in `AGENTS.md` and `CLAUDE.md`.
  - Added live coordination and lock table in `ACTIVE_WORK.md`.
  - Added custom project skills in `.agents/skills/overkill-dev/`.
  - Staged and uploaded all core Godot 4 game systems, combat scenes, data resources, and documentation specs to GitHub.
- **Current State of the Game**:
  - Full dual-chronometer combat loop, enemy slot mechanics, cards, relics, and presentation screens implemented.
  - Autoloads configured: `GameFlow`, `RunManager`, `ContentDatabase`, `SaveManager`, `AudioManager`.
- **Handoff Notes for Incoming AI**:
  - The repo is now fully synchronized on GitHub.
  - Both partners can branch from `main`, check `ACTIVE_WORK.md` before claiming files, and develop features concurrently.

## 2026-09-18 | Yonatan's AI (Codex)
- **Branch / PR:** `feat/yonatan-starter-relic-overlays` (local source changes; no release export).
- **Completed:** New runs start with 16 independent copies: 6 Iron Strike (6 damage), 6 Guard Plate (6 Block), 2 Twin Blades (4 damage twice), 2 Reinforced Wall (8 Block). Existing inventories remain intact. Varied relics remain in the reward/shop catalog. Descriptions explicitly explain persistent Block; engine already retains Block until absorbed or battle ends.
- **Completed:** Reusable floating relic-choice panel replaces the visible bottom dock and its reserved arena height. Assembly presents three choices alongside the numbered, pulsing destination. Quadrant panel presents the drawn relic, three replacement buttons tied to the clock sockets, and Keep & Sweep. Existing pulsing guidance/preview and relic-flight animation are retained; panel hides during placement/resolution. Added hour-resolution banners. Directed Sentinel stage extends into the reclaimed space.
- **Files Modified / Added:** `scripts/run/clock_inventory.gd`; `data/clock_relics/starter/rel_02_twin_blades.tres`, `rel_04_guard_plate.tres`, `rel_06_reinforced_wall.tres`; `scripts/ui/relic_choice_overlay.gd`; `scripts/combat/combat_controller.gd`; `scenes/combat_scene.tscn`; `scripts/combat/starter_relic_test.gd`; `scenes/starter_relic_test.tscn`; existing battle guidance, smoke and polish integration tests; `overkill_master_gdd.md`.
- **Verification:** Godot 4.5.1: STARTER_RELIC_OK (composition, unique IDs/copy isolation, block retention/absorption/reset, two-hit damage); CLOCK_SMOKE_OK (12 hours, duplicate input, 4 quadrants, swap, wrap, single victory); POLISH_INTEGRATION_OK (inventory/save/legacy migration/removal/shop/encounter mechanics); rendered BATTLE_GUIDANCE_OK at 1920x1080 and 1280x720, including dispatch through the new replacement button and checking overlay hides during binding. Screenshots in `artifacts/battle-guidance/`. Windows root-certificate warning persists; some headless runs report ObjectDB shutdown warnings, without gameplay script errors in passing suites.
- **Balance findings / Handoff:** Existing greedy encounter policy wins boneghoul (69 HP) and act1 elite (29 HP), loses act1 boss (enemy 122 HP left) and act2 boss (65 HP left), and reaches its 60-turn assertion on act3 boss. This fixture gives later bosses upgraded starter relics without reward variety; it does not certify full-run balance. Revisit boss balance and realistic reward progression separately; enemy stats were not changed. Source is ready for review; existing packaged executables were not rebuilt. Start a new run to use the new composition.

## 2026-09-18 | Yonatan's AI (Codex) — Windows test distribution
- **Branch / release:** `feat/yonatan-starter-relic-overlays`; prepared GitHub prerelease `v0.13.0-test`.
- **Completed:** Built Windows installer 0.13.0 and portable ZIP, added `install/README.md` with download links, updated installer delivery notes and VERSION, generated SHA-256 checksums. No merge to main.
- **Files:** `VERSION`, `scripts/release/build_installer.ps1`, `docs/starter-relic-release.md`, `install/README.md`, `installer/OverkillSetup-0.13.0.sha256`; prior starter deck/UI changes included.
- **Verification:** Exported executable launched from build/windows without source-project arguments using Intel OpenGL. Packaged STARTER_RELIC_OK, CLOCK_SMOKE_OK and POLISH_INTEGRATION_OK passed. Installer compiler completed successfully. The installer wizard itself was not run; packaged payload was tested directly. Known Windows certificate-store and headless ObjectDB exit warnings persist. Boss-balance limitations documented in release notes.
- **Handoff:** Download installer or extract the full portable folder. Start a new run to get the revised inventory. Release binaries belong in GitHub assets, not Git history.
## 2026-09-18 | Yonatan's AI (Codex) — shared GitHub distribution
- **Branch:** `docs/yonatan-release-downloads`.
- **Completed:** Repository homepage and installer-folder download links, shared UPDATE_LOG, mandatory versioned installer/release handoff policy in AGENTS.md.
- **Files:** README.md, installer/README.md, UPDATE_LOG.md, AGENTS.md, ACTIVE_WORK.md, CHANGELOG_AI.md.
- **Verification:** Documentation review; links target the previously published 0.13.0 assets verified with HTTP 200 and matching hashes. No gameplay changes or binary rebuild.
- **Handoff:** Gameplay source remains on feat/yonatan-starter-relic-overlays at 07e1ce9; the current download is v0.13.0-test. Future gameplay deliveries must update installer links and UPDATE_LOG on GitHub.

## 2026-09-19 | Yonatan's AI (Codex) — 0.14 nine-hour clock and presentation
- **Branch / PR:** `feat/yonatan-014-presentation-polish`; release tag `v0.14.0-test` identifies exact gameplay source. Main receives distribution documentation only until gameplay review.
- **Completed:** Nine-hour player/enemy clocks, three-sector sweeps, twelve-copy starter deck (5 attack, 5 guard, 1 lifesteal, 1 next-attack multiplier), persistent 5-Block Guard, three reserves, minimum ten-copy removal rule. Hidden enemy actions reveal before choices and remain visible; reverse and twin-hand patterns adapted.
- **Completed:** Horizontal floating choice/replacement panel, explicit commit controls, stable previews, battlefield inspection, health outside overlay, larger effect text, cleaner reward/shop layouts, map route layering and footer spacing.
- **Files:** `scripts/combat/combat_controller.gd`, `enemy_clock_pattern.gd`, combat regression tests; `scripts/data/clock_relic_data.gd`, `clock_socket_data.gd`; `scripts/run/clock_inventory.gd`; `scripts/ui/chronometer_view.gd`, `clock_socket_view.gd`, `clock_engraving.gd`, `relic_choice_overlay.gd`, `relic_pedestal_view.gd`, `clock_collection_screen.gd`, `class_select_screen.gd`, `reward_screen.gd`, `screen_design.gd`, `map_screen.gd`, `frontend_showcase.gd`; `scenes/combat_scene.tscn`; new presentation test scene/script; starter resources REL-04/13/14; VERSION, release build script, docs/spec override, README/installer links and UPDATE_LOG.
- **Verification:** Godot 4.5.1 STARTER_RELIC_OK, CLOCK_SMOKE_OK, POLISH_INTEGRATION_OK, BATTLE_GUIDANCE_OK, FRONTEND_FLOW_OK, PRESENTATION_014_OK. Rendered screenshot review at 1080p and large-text 720p; layout assertions also ultrawide. Exported installer payload passed starter, smoke and inventory tests. Exported rendered layout assertions passed, but its debug screenshot writer targets read-only res:// and cannot save images; source screenshots were reviewed. Installer compiled successfully; portable ZIP entries hash-match tested payload. Interactive installation wizard not tested.
- **Balance:** ENCOUNTER_PLAYTHROUGHS_OK: basic policy wins normal and elite Act I, loses four boss fixtures. No claim of finished boss balance or AAA production. Nonfatal certificate-store and headless ObjectDB warnings remain.
- **Handoff:** Start a new run for the twelve-copy deck. Existing inventories are preserved. Lifesteal heals actual enemy HP lost, capped at missing player HP; boost survives non-attacks, applies to the next attacking relic, does not compound. Review feature branch before gameplay merge. Maintain versioned installer, portable ZIP, checksums and update log on every delivered feature.

## 2026-09-19 | Yonatan's AI (Codex) — verified 0.14 distribution
- **Branch / PR:** `feat/yonatan-014-downloads`, documentation-only PR to main.
- **Completed:** Published `v0.14.0-test` from `f2a331a741cd93be3c01f9f23919d0c186f04b38`. Uploaded Windows installer (228290291 bytes), portable ZIP (256882208 bytes), and SHA-256 manifest. Updated README, installer/README, install/README, checksums and UPDATE_LOG.
- **Verification:** All three GitHub assets returned HTTP 200; server SHA-256 digests match local packages. Portable entries match the exported payload tested with STARTER_RELIC_OK, CLOCK_SMOKE_OK and POLISH_INTEGRATION_OK. Exported game launched with Intel OpenGL. Installer wizard not tested.
- **Handoff:** Partner navigation: repository → Releases → 0.14.0 → Assets. Start a new run for the 12-relic deck and nine-hour clock. Gameplay remains on `feat/yonatan-014-presentation-polish` pending review. Boss balance needs human playtesting.

## 2026-09-19 | Yonatan's AI (Codex) — 0.14.1 top relic choices
- **Branch / PR:** `feat/yonatan-top-relic-choices`; release tag `v0.14.1-test` pins the playable source.
- **Completed:** Compact horizontal choices at top, no shared panel backdrop or heading/instruction strip, pulsing available-option outlines with static reduced-motion highlight, compact top replacement controls, combat notices moved out of the chooser area. Preserved explicit bind/replace actions and pulsing numbered socket previews. Fixed compact button bounds. No combat-rule or save-format changes.
- **Files:** `scripts/ui/relic_choice_overlay.gd`, `relic_pedestal_view.gd`; `scripts/combat/combat_controller.gd`, `presentation_polish_test.gd`; VERSION, release builder, delivery notes, README/installer instructions, update log and checksums.
- **Verification:** Source and exported payload BATTLE_GUIDANCE_OK and PRESENTATION_014_OK. Rendered 1080p, large-text 720p and ultrawide checks; no overlap with clocks/health, buttons inside options, stable previews, inspection, locked slots and empty reserves. Portable ZIP contents hash-match the tested export. Screenshot harness now saves in user://, including packaged runs. Installer wizard remains untested; existing nonfatal certificate-store warning remains.
- **Handoff:** Install 0.14.1 from GitHub Releases. 0.14.0 saves remain compatible. Gameplay stays on the feature branch pending review; documentation-only PR updates main for partner access. Boss balance is unchanged.

## 2026-09-19 | Yonatan's AI (Codex) — verified 0.14.1 distribution
- **Branch / PR:** `feat/yonatan-0141-downloads`, documentation-only update to main.
- **Completed:** Published `v0.14.1-test` at `241dbf05f83c31714aca2cacb2541b8cd68bc46a`: compact top relic choices without shared backdrop, pulsing option outlines, unchanged nine-hour combat. Uploaded installer, portable ZIP and checksums; updated homepage, installer instructions and UPDATE_LOG.
- **Verification:** Source/exported BATTLE_GUIDANCE_OK and PRESENTATION_014_OK; inspected 1080p and large-text 720p screenshots and ultrawide bounds. ZIP entries match tested payload. All three GitHub assets returned HTTP 200 and server SHA-256 digests match local files. Installer compiled; interactive wizard untested.
- **Handoff:** GitHub → Releases → 0.14.1 → Assets. Existing 0.14 saves remain compatible. Gameplay branch `feat/yonatan-top-relic-choices` awaits review; boss balance unchanged.


## 2026-09-19 | Yonatan's AI (Codex) — 0.15 cinematic combat finish
- **Branch / PR:** `feat/yonatan-cinematic-combat-finish`; release tag `v0.15.0-test` pins the playable source.
- **Completed:** Worn-steel texture and roughness treatment, muted brass, darker floor/ambient light, restrained stage color grading, contact shadows and beveled Sentinel hammer. Explicit HP/BLOCK/BLOCKED/HEAL/BLEED/THORNS/RECOIL feedback, staggered number positions, relic-name activation notice, lethal HP separated from Overkill. World-space guard rings; removed duplicate 2D slash/spark layers and extra screen shake in DirectedArena. No combat-rule or save-format change.
- **Files:** `scripts/combat/{directed_arena,rigged_combatant,combat_controller,cinematic_finish_test}.gd`, `scripts/ui/damage_number.gd`, shader files, generated `assets/characters/rigged/worn_metal_015.png`, cinematic test scene, VERSION, release builder, delivery notes, README/installer instructions, update log/checksums.
- **Verification:** Source and exported CINEMATIC_FINISH_OK; exported STARTER_RELIC_OK, CLOCK_SMOKE_OK, PRESENTATION_014_OK. Rendered and inspected 1080p/720p images; layout checks include large text and ultrawide, inspection and replacements. ZIP entries hash-match tested export. Installer compiled; interactive wizard untested. Existing certificate-store warning remains.
- **Limitations:** Material/lighting work targets the rigged Sentinel encounter. Other encounters retain illustrated art. Not AAA completion: bespoke enemy models, animation and environment breadth remain. Full-stage benchmark median around 45 ms on this Intel environment, with empty-scene baseline around 32 ms; no 60 fps claim. Boss balance unchanged.
- **Handoff:** Use Play Sentinel for direct encounter testing in a separate profile. Publish installer, portable ZIP and SHA-256 assets, verify live downloads, then update main through a documentation-only PR. Gameplay awaits feature review.

## 2026-09-19 | Yonatan's AI (Codex) — verified 0.15 distribution
- **Branch / PR:** `feat/yonatan-015-downloads`, documentation-only update to main.
- **Completed:** Published `v0.15.0-test` at `7b1de5ddc8d49f18663dc7e5e4428aaace3a0946`: cinematic Sentinel material/lighting finish and clearer combat feedback. Uploaded installer (230788384 bytes), portable ZIP (259426972 bytes), and checksums. Updated README, installer/README, install/README and UPDATE_LOG.
- **Verification:** Exported STARTER_RELIC_OK, CLOCK_SMOKE_OK, CINEMATIC_FINISH_OK and PRESENTATION_014_OK; inspected rendered output. ZIP entries match tested export. All three release assets returned HTTP 200 and server SHA-256 digests match local files. Interactive installer wizard untested.
- **Handoff:** Repository → Releases → 0.15.0 → Assets. Use Play Sentinel to inspect the rigged encounter directly. Existing 0.14 saves remain compatible. Gameplay remains on `feat/yonatan-cinematic-combat-finish` pending review; this is a visual playtest, not AAA completion.


## 2026-09-19 | Yonatan's AI (Codex) — 0.16 armor and synchronized strikes
- **Branch / PR:** `feat/yonatan-sentinel-silhouette`; tag `v0.16.0-test` pins the playable source.
- **Completed:** Bone-mounted curved Sentinel pauldrons, breastplate, nine-mark chest seal and greaves; replaced the hero's primitive blade with a beveled execution blade. Refined melee spacing and bounded attack weight shift. Added rear dais/braziers. Batched columns/bands, reused metal materials, simplified metal fragment shading, single directional shadow pass for fixed camera, cached static clock engravings and stopped their continuous redraw under reduced motion.
- **Timing fix:** Discovered fixed 0.32-second damage timers could fire while the rig was still winding up on low-frame-rate runs. DirectedArena now awaits the attacking clip's contact window, sets the contact pose and aligns the weapon before damage/impact. Cleared obsolete trail samples at synchronization to avoid a large artificial triangle. Impact effects/numbers use the same target surface point. Balance/save schema unchanged.
- **Files:** `scripts/combat/{forged_armor,rigged_combatant,directed_arena,combat_controller,silhouette_test,cinematic_finish_test}.gd`; silhouette test scene; `scripts/ui/clock_engraving.gd`, metal shader; VERSION, release builder, delivery notes, download docs and checksums.
- **Verification:** Exported SILHOUETTE_OK, CINEMATIC_FINISH_OK, RIG_MOTION_OK, STARTER_RELIC_OK, CLOCK_SMOKE_OK and PRESENTATION_014_OK. Final exported cinematic test passed all four normal/fast × normal/reduced-motion combinations with exactly-once damage assertions. Inspected rendered idle/contact/compact shots; tested attachment bounds, outward face winding, root settling and effect cleanup. Layout checks cover 1080p, large-text 720p and ultrawide.
- **Performance / limits:** Comparable full-scene draw submissions fell from about 680 to 455. Median frame samples remained roughly 43–50 ms with variable spikes on this Intel environment; no 60 fps or measured frame-time improvement claim. Broader bespoke models, animation variety, environment production and boss balancing remain. Existing certificate-store and headless shutdown warnings persist. Interactive installer wizard not tested.
- **Handoff:** Publish 0.16 installer/ZIP/checksums, verify GitHub downloads, update main through documentation-only PR. Gameplay remains isolated for review. Use Play Sentinel to inspect the cinematic encounter directly; existing 0.14/0.15 saves are compatible.
