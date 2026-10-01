# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan's AI (Codex) | fix/yonatan-full-ui-polish | 0.39.0 multi-hit overkill, cinematic relic activations, readable battle telemetry, screen-state clarity, Godot launch diagnosis, and verified Windows release | `scripts/ui/clock_collection_screen.gd`; `scripts/ui/upgrade_preview_dialog.gd`; `scenes/upgrade_preview_dialog.tscn`; `scripts/ui/relic_pedestal_view.gd`; `scripts/ui/relic_choice_overlay.gd`; `scripts/ui/boss_overkill_altar.gd`; `scenes/boss_overkill_altar.tscn`; `scripts/combat/illustrated_stage.gd`; `scripts/combat/clock_battle_presentation.gd`; `scripts/combat/presentation_polish_test.gd`; `scripts/combat/crystalline_visual_test.gd`; `scripts/combat/attack_presentation.gd`; `scripts/combat/combat_controller.gd`; `scripts/combat/combat_vfx.gd`; `scripts/combat/starter_relic_test.gd`; `scripts/ui/screen_design.gd`; `docs/overkill-data-schema.md`; `docs/encounter-039.md`; `VERSION`; `project.godot`; `README.md`; `installer/README.md`; `UPDATE_LOG.md`; `CHANGELOG_AI.md`; `ACTIVE_WORK.md`; `installer/OverkillSetup-0.39.0.sha256` | 2026-10-01 |



Published baseline: `v0.37.0-test` (gameplay source `93ede9f5ce801b75049a29e6b0f6590034bd5017`). Gameplay remains on `fix/yonatan-full-ui-polish`; default-branch download links are pending documentation-only PR #22. All locks are released.

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
