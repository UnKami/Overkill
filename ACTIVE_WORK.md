# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks

The prior v0.41 release and rest-site locks were released on 2026-10-03 at Yonatan's explicit request. They were coordination reservations, not technical release restrictions. The divergent source histories are being reconciled on `feat/yonatan-042-rigged-relics`; existing cog-map work is preserved.

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan / Codex root | `feat/yonatan-042-rigged-relics` | Integrated release and visual verification | `ACTIVE_WORK.md`, `CHANGELOG_AI.md`, `VERSION`, `README.md`, `UPDATE_LOG.md`, `installer/README.md`, `docs/encounter-042.md`, `scripts/combat/relic_animation_test.gd`, `scenes/relic_animation_test.tscn`, `scripts/combat/combat_controller.gd`, `scripts/combat/illustrated_stage.gd`, `project.godot`, `scenes/upgrade_preview_dialog.tscn`, `scripts/ui/upgrade_preview_dialog.gd`, `scripts/dev/run_godot.ps1`, `scripts/release/publish_crystalline_release.ps1`, `.test-artifacts/042/animations/` | 2026-10-03 |
| Yonatan / Codex merge_audit (same team) | `feat/yonatan-042-rigged-relics` | Screen coverage and regression audit (merge complete) | `scripts/autoload/run_manager.gd`, `scripts/autoload/game_flow.gd`, `scripts/ui/title_screen.gd`, `scripts/ui/boss_overkill_altar.gd`, `scripts/ui/reward_screen.gd`, `scripts/ui/pause_menu.gd`, `scripts/run/resume_checkpoint_test.gd`, `scenes/resume_checkpoint_test.tscn`, `scripts/ui/release_screen_audit.gd`, `scenes/release_screen_audit.tscn`, `scripts/combat/clock_battle_smoke.gd`, `scripts/combat/crystalline_visual_test.gd`, `.test-artifacts/042/screens/`, `.test-artifacts/042/regression/` | 2026-10-03 |
| Yonatan / Codex blender_rig (same team) | `feat/yonatan-042-rigged-relics` | Blender authored character skeleton and runtime actor | `scripts/art/build_relic_rig.py`, `assets/characters/executioner/rigged/`, `scripts/combat/relic_rig_actor.gd`, `scripts/ui/cog_map_screen.gd`, `scenes/cog_map_screen.tscn`, `scripts/map/map_generator.gd`, `scripts/map/map_determinism_test.gd`, `scenes/map_determinism_test.tscn` | 2026-10-03 |
| Yonatan / Codex relic_choreography (same team) | `feat/yonatan-042-rigged-relics` | Blender authored relic timelines and runtime effects | `scripts/art/build_relic_choreography.py`, `assets/animations/relics/`, `scripts/combat/relic_choreography.gd`, `scripts/combat/attack_presentation.gd`, `scripts/combat/run_artifact_test.gd`, `scripts/combat/decision_preview.gd`, `scripts/ui/ux_017_test.gd` | 2026-10-03 |

Additional live scope: `scripts/ui/act_transition_screen.gd` belongs to `merge_audit` for the reviewed early-input recovery fix.

No old lock blocks publication. These narrow, live ownership rows prevent this team's parallel edits from colliding and will be released at handoff.

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
