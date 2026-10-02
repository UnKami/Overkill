# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan's Codex | `feat/yonatan-040-artifacts-block-balance` | v0.41 Artifact roster expansion, distinct passive implementation, and signature animation polish | `scripts/autoload/run_manager.gd`, `scripts/autoload/content_database.gd`, `scripts/combat/`, `scripts/ui/shop_screen.gd`, `scripts/ui/relic_art.gd`, `scripts/ui/relic_icon.gd`, `scripts/run/`, `scripts/data/`, `data/relics/`, `data/clock_relics/`, `data/run_artifacts/`, `scenes/run_artifact_test.tscn`, `docs/encounter-041.md`, `docs/`, `assets/relics/artifacts/`, `assets/vfx/`, `assets/screens/`, `VERSION`, `project.godot`, `UPDATE_LOG.md`, `CHANGELOG_AI.md`, `installer/overkill.iss`, `.test-artifacts/` | 2026-10-02 |

Published baseline: `v0.40.0-test` (source `fdee0ffb4ae217476610822d85fb7137cf21dc3a`) on `feat/yonatan-040-artifacts-block-balance`. Default-branch download links and verification notes are in documentation-only PR #24 awaiting review. The active v0.41 lock is listed above.

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
