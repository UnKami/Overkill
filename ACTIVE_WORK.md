# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan / Codex | `feat/yonatan-battle-arrival` | Screen vortex, first-battle offer, character-owned combat HUD, battle intro, Heavy Hammer presentation | `scripts/ui/class_select_screen.gd`; `scripts/ui/clock_collection_screen.gd`; `scripts/ui/card_view.gd`; `scripts/ui/screen_transition.gd` (new); `scripts/ui/pre_battle_offer.gd` (new); `scripts/ui/card_upgrade_selection.gd` (new); `scripts/autoload/game_flow.gd`; `scripts/autoload/run_manager.gd`; `scripts/ui/map_screen.gd`; `scripts/combat/combat_controller.gd`; `scripts/combat/clock_battle_presentation.gd`; `scripts/combat/battle_intro_sequence.gd` (new); `scripts/combat/attack_presentation.gd` (new); `scripts/combat/illustrated_actor.gd`; `scripts/combat/illustrated_stage.gd`; `scripts/combat/directed_arena.gd`; `scripts/combat/rigged_combatant.gd`; `assets/shaders/screen_vortex.gdshader` (new); `scenes/pre_battle_offer.tscn` (new); `scenes/card_upgrade_selection.tscn` (new); presentation tests/docs | 2026-09-23 |

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
| **Audio & SFX** | `scripts/art/build_executioner.py`, `assets/characters/rigged/executioner.glb`, `art_source/characters/executioner-production.blend`, `scripts/combat/forged_armor.gd`, `scripts/autoload/audio_manager.gd`, `assets/audio/` | Sound buses, event triggers, music switching |
