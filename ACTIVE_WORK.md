# ACTIVE_WORK.md — Live AI Coordination & Lock Table

> **CRITICAL INSTRUCTION FOR ALL AI ASSISTANTS**:
> Before making changes, you **MUST inspect this table**.
> If any files or directories you plan to touch are listed under **Locked Files**, **STOP** and inform your developer. Do not touch locked files until the lock is released!

---

## 1. Active Locks


2026-10-08: Yonatan transferred the stopped lighter-model session's character work to Codex chat `01a1186a-dc80-7961-bab3-3ba8a3f2dc29`. The local reference-fidelity pass is recorded in `docs/verification-048-character.md` and `CHANGELOG_AI.md`. This chat has released all character, material, validation and documentation reservations. The source remains on `feat/yonatan-046-relic-feedback`; the pre-existing uncommitted work was preserved and no pull/reset/new branch was performed.

This remains an unpublished art candidate. Final illustration fidelity, relic refinement, stable-FPS review and installer/release delivery remain open. Existing publication/push/merge hold is unchanged. Character pre-pass backups and current exported review artifacts are under `.test-artifacts/048-character/`.

2026-10-17: Yonatan / Antigravity Multi-Agent has concluded the major 0.48.0 Archetype Synergy & Chronometer Depth Overhaul (4 relic archetypes, positional engine, Sector-First combo sweep, SmartHoverInspector, 80 Max HP economy rebalance, 6 events, free boss altar, and 3D relic choreography). All regression suites passed. All file reservations are released.

| Partner / AI | Branch Name | Current Feature / Scope | Locked Files / Paths (DO NOT TOUCH) | Timestamp |
| :--- | :--- | :--- | :--- | :--- |
| Yonatan / Antigravity | `feat/yonatan-global-leaderboard` | Firestore Global Run & Career Account Leaderboards | `firestore.rules`, `scripts/autoload/leaderboard_manager.gd`, `scripts/ui/leaderboard_view.gd`, `scenes/ui/leaderboard_view.tscn`, `scripts/ui/run_summary_screen.gd`, `scripts/ui/title_screen.gd` | 2026-10-17 |

Published playtest: [v0.48.0-test](https://github.com/UnKami/Overkill/releases/tag/v0.48.0-test), exact tested source `421bec75c13e418209e953bbe2ba18af272a0c2e`. All three 0.48 public downloads, sizes and SHA-256 digests passed verification. Previous releases remain available.

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


2026-10-08: User explicitly authorized publishing the polished Meshy release. The prior hold is lifted for this release only.
