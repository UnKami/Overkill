# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

0.44 meshed cog-map correction is active. No 0.43 reservations remain.

The prior 0.41 rows were coordination reservations required by this repository, not Windows/Godot file locks or technical release restrictions. They were cleared at Yonatan's request. Both divergent source histories and the cog-map work are preserved in the reviewed 0.42 integration.

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan / Codex | `feat/yonatan-044-meshed-cog-map` | Concept-led bottom-to-top tooth-meshed machine, physical branches and synchronized motion | `scripts/map/cog_navigation_generator.gd`, `scripts/map/cog_navigation_test.gd`, `scripts/map/cog_machine_review.gd`, `scenes/cog_machine_review.tscn`, `scripts/ui/cog_map_screen.gd`, `scripts/ui/cog_gear_view.gd`, `scripts/ui/release_screen_audit.gd`, `scenes/cog_map_screen.tscn`, `scripts/autoload/game_flow.gd`, `scripts/autoload/run_manager.gd`, `scripts/run/resume_checkpoint_test.gd`, `VERSION`, `project.godot`, `README.md`, `installer/README.md`, `UPDATE_LOG.md`, `CHANGELOG_AI.md`, `ACTIVE_WORK.md`, `docs/encounter-044.md`, `docs/cog-machine-layout.md` | 2026-10-04 |

Published playtest: [v0.43.0-test](https://github.com/UnKami/Overkill/releases/tag/v0.43.0-test), exact tested source `45367f8991bec1e6f01ac9ca090d2b64a5474431`. Documentation PR [#29](https://github.com/UnKami/Overkill/pull/29) is merged. Reviewed motion integration is tracked in source PR [#28](https://github.com/UnKami/Overkill/pull/28); GitHub records its current merge status. The previous 0.42 source and documentation PRs (#26 and #27) are merged.

---
## 2. How to Claim a Task (Instructions for Developers & AIs)

When starting work on a feature:
1. Ensure your branch is updated: `git pull origin main`
2. Create your feature branch: `git checkout -b feat/<your-name>-<feature-description>`
3. Edit this file (`ACTIVE_WORK.md`):
   - Add your name / AI
   - Add your branch name
   - Add the specific folder or file paths you will be creating/modifying
4. Commit and push this file so the other partner's AI is immediately aware.
5. When work is merged into `main`, remove your row from the table and record your handoff notes in [`CHANGELOG_AI.md`](CHANGELOG_AI.md).

---

## 3. Recommended Feature Division (Collision Avoidance)

To minimize any possibility of merge conflicts in Godot, the following domains are naturally decoupled:

| Domain | Typical File Paths | Ideal For |
| :--- | :--- | :--- |
| **Combat Mechanics & Arena** | `scenes/combat/`, `scripts/combat/` | Dual-chronometer presentation, VFX, enemy patterns |
| **Map & Events** | `scenes/map_screen.tscn`, `scripts/map/`, `data/events/` | Procedural map nodes, random events, rest sites |
| **Cards & Content Data** | `data/cards/`, `data/relics/`, `data/enemies/` | Adding new cards, balance adjustments, new relic effects |
| **Frontend Menus & UI** | `scenes/title_screen.tscn`, `scenes/deck_view.tscn`, `scripts/ui/` | Screen polish, animations, settings, audio integration |
| **Audio & SFX** | `scripts/autoload/audio_manager.gd`, `assets/audio/` | Sound buses, event triggers, music switching |
