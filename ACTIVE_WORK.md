# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan / Codex | feat/yonatan-sentinel-production | Relic thumbnail filtering | assets/cards/executioner/bloodprice.jpg.import; scripts/ui/relic_pedestal_view.gd; scripts/ui/clock_socket_view.gd; assets/relics/active/rel_01_iron_strike.jpg.import; assets/relics/active/rel_02_twin_blades.jpg.import; assets/relics/active/rel_03_heavy_hammer.jpg.import; assets/relics/active/rel_04_guard_plate.jpg.import; assets/relics/active/rel_05_spiked_buckler.jpg.import; assets/relics/active/rel_06_reinforced_wall.jpg.import; assets/relics/active/rel_07_rusting_spike.jpg.import; assets/relics/active/rel_08_momentum_spring.jpg.import; assets/relics/active/rel_09_corrosive_oil.jpg.import; assets/relics/active/rel_10_kinetic_battery.jpg.import; assets/relics/active/rel_11_execution_wedge.jpg.import; assets/relics/active/rel_12_recoil_piston.jpg.import | 2026-09-19 |

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
