# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Codex | fix/yonatan-full-ui-polish | Cap battle reward relics at 12 with replacement UX; rebalance HP/bosses; compact combat stat UI and audit related screens | `scripts/ui/reward_screen.gd`, `scenes/reward_screen.tscn`, `scripts/run/clock_inventory.gd`, `scripts/autoload/run_manager.gd`, `scripts/ui/class_select_screen.gd`, `scripts/combat/player_state.gd`, `scripts/combat/combat_controller.gd`, `scenes/combat_scene.tscn`, `data/enemies/act1/act1_boss.tres`, `data/enemies/act2/act2_boss.tres`, `data/enemies/act3/act3_boss.tres`, `data/enemies/final_boss.tres`, targeted tests, `docs/overkill-balance-baseline.md`, `VERSION`, `CHANGELOG_AI.md`, `UPDATE_LOG.md` | 2026-09-30 |



Published baseline: `v0.34.0-test` (gameplay source `3b343d3679ed5748f8aeeb8e8f83344db89acdbd`). Gameplay remains on `fix/yonatan-full-ui-polish`; default-branch download links are live through documentation-only PR #19.

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
