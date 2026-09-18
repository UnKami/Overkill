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
