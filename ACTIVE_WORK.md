# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan / Codex | `feat/yonatan-tactical-inspection` | Unify Overkill around the supplied crystalline cyan/amber techno-fantasy canon; replace incompatible combat actors, enemies, relics, backgrounds, and event art; then complete the HUD, relic-card, pre-battle, and battlefield-inspection redesign | `ACTIVE_WORK.md`; `CHANGELOG_AI.md`; `UPDATE_LOG.md`; `VERSION`; `README.md`; `project.godot`; `export_presets.cfg`; `installer/README.md`; `installer/overkill.iss`; `docs/visual_canon.md`; `docs/encounter-025.md`; `assets/characters/**`; `assets/enemies/**`; `assets/environments/**`; `assets/relics/**`; `assets/screens/**`; `assets/cards/**`; `assets/ui/**`; `assets/vfx/**`; `art_source/**`; `scripts/combat/**`; `scripts/ui/**`; `scripts/map/**`; `scripts/release/**`; `scenes/combat/**`; `scenes/ui/**`; `scenes/*combat*`; `scenes/*showcase*`; `tests/**` | 2026-09-28 |

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
