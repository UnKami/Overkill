# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

0.45 focused map camera and refined landings are active. The 0.44 delivery remains available.

The prior 0.41 rows were coordination reservations required by this repository, not Windows/Godot file locks or technical release restrictions. They were cleared at Yonatan's request. Both divergent source histories and the cog-map work are preserved in the reviewed 0.42 integration.

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan / Codex | `feat/yonatan-045-follow-map-camera` | Focused tracking camera, draggable planning view, precise seat anchors and map transitions | `scripts/ui/cog_map_screen.gd`, `scenes/cog_map_screen.tscn`, `scripts/map/cog_navigation_generator.gd`, `scripts/map/cog_navigation_test.gd`, `scripts/map/cog_machine_review.gd`, `scripts/ui/release_screen_audit.gd`, `VERSION`, `project.godot`, `README.md`, `installer/README.md`, `UPDATE_LOG.md`, `CHANGELOG_AI.md`, `ACTIVE_WORK.md`, `docs/cog-machine-layout.md`, `docs/encounter-045.md` | 2026-10-04 |

Published playtest: [v0.44.0-test](https://github.com/UnKami/Overkill/releases/tag/v0.44.0-test), exact tested source `333954f87ccf948e0c0c90e6a664895b6eb1aac4`. Reviewed map integration is tracked in source PR [#30](https://github.com/UnKami/Overkill/pull/30); GitHub records its current merge status. The previous 0.42 and 0.43 source/documentation PRs (#26 through #29) are merged. All three 0.44 public downloads, sizes and SHA-256 digests passed verification.

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
