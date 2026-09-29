# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan's Codex | `fix/yonatan-full-ui-polish` | Map navigation, treasure screen, relic selection hit targets, transition presentation, distinct enemy art, release verification | `ACTIVE_WORK.md`; `scenes/map_screen.tscn`; `scripts/ui/map_screen.gd`; `scenes/relic_pedestal_view.tscn`; `scripts/ui/relic_pedestal_view.gd`; `scenes/reward_screen.tscn`; `scripts/ui/reward_screen.gd`; `scenes/treasure_screen.tscn`; `scripts/ui/treasure_screen.gd`; `scripts/autoload/game_flow.gd`; `scripts/ui/screen_transition.gd`; `scripts/ui/cinematic_art.gd`; `scripts/combat/combat_controller.gd`; `scripts/combat/illustrated_stage.gd`; `scripts/combat/battle_arrival_visual_test.gd`; `scripts/combat/battle_arrival_test.gd`; `scripts/combat/presentation_polish_test.gd`; `assets/enemies/act1/`; `assets/enemies/act2/`; `assets/enemies/act3/`; `assets/enemies/final_boss_painterly.png`; `assets/screens/cinematic/transition_act1_act2_painterly.png`; `assets/screens/cinematic/transition_act2_act3_painterly.png`; `assets/screens/cinematic/transition_act3_final_painterly.png`; `data/enemies/act1/boneghoul.tres`; `data/enemies/act1/act1_elite.tres`; `data/enemies/act2/act2_elite.tres`; `data/enemies/act3/act3_trash.tres`; `data/enemies/act3/act3_elite.tres`; `data/enemies/act3/act3_boss.tres`; `data/enemies/final_boss.tres`; `scripts/ui/map_ux_test.gd`; `scenes/map_ux_test.tscn`; `VERSION`; `UPDATE_LOG.md`; `CHANGELOG_AI.md`; `README.md`; `installer/README.md` | 2026-09-30 |

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
