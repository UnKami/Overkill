# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

0.43 motion refinement is active. These reservations coordinate edits for this task.

The prior 0.41 rows were coordination reservations required by this repository, not Windows/Godot file locks or technical release restrictions. They were cleared at Yonatan's request. Both divergent source histories and the cog-map work are preserved in the reviewed 0.42 integration.

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan / Codex | `feat/yonatan-043-fluid-motion` | Natural joints, continuous poses, enemy and relic motion; verified playtest delivery | `scripts/art/build_relic_rig.py`, `scripts/art/build_relic_choreography.py`, `assets/characters/executioner/rigged/`, `assets/animations/relics/`, `scripts/combat/relic_rig_actor.gd`, `scripts/combat/illustrated_actor.gd`, `scripts/combat/relic_choreography.gd`, `scripts/combat/attack_presentation.gd`, `scripts/combat/relic_animation_test.gd`, `scripts/combat/illustrated_stage.gd`, `scripts/combat/combat_controller.gd`, `scripts/combat/motion_quality_test.gd`, `scenes/motion_quality_test.tscn`, `VERSION`, `project.godot`, `README.md`, `installer/README.md`, `UPDATE_LOG.md`, `CHANGELOG_AI.md`, `ACTIVE_WORK.md`, `docs/encounter-043.md` | 2026-10-04 |

Published playtest: [v0.42.0-test](https://github.com/UnKami/Overkill/releases/tag/v0.42.0-test), exact tested source `cb28d2851fc1dff235b87064ccedef1dad043b2f`. Documentation PR [#27](https://github.com/UnKami/Overkill/pull/27) is merged. Reviewed cumulative source integration is tracked in PR [#26](https://github.com/UnKami/Overkill/pull/26).

The same active motion scope also owns `scripts/art/build_enemy_motion.py`, `assets/animations/enemies/`, and `scripts/combat/enemy_rig_actor.gd` for the enemy deformation rig.

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
