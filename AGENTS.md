# AGENTS.md — Overkill Game Architecture & Multi-AI Collaboration Protocol

Welcome to the **Overkill** codebase. This file is the primary briefing document for any AI coding assistant (Antigravity, Claude Code, Cursor, Codex, Windsurf) working on this project.

---

## 1. Project Overview

**Overkill** is a fast-paced tactical roguelite deckbuilder built in **Godot 4**.
- **Core Hook**: Eliminates traditional mana/energy and hand-discard loops in favor of a **Dual-Chronometer Battle Engine** (a 12-hour circular array where relics act as active instructions executing deterministic clashes).
- **Economy**: All excess damage dealt beyond a target's lethal threshold is converted 1:1 into **Overkill Points**, the universal meta-currency for relic ascensions, card upgrades, and Zenith components.
- **Spillage**: An optional keyword allowing excess damage to carry directly into the next enemy in sequence.

### Key Documentation (Must Read for Feature Work)
- [overkill_master_gdd.md](overkill_master_gdd.md): Master Game Design Document & Architecture Spec.
- [overkill_implementation_spec.md](overkill_implementation_spec.md): Technical combat loop, phase transitions, state machines.
- [docs/](docs/): Detailed sub-system specs (Balance baseline, Data schemas, UI composition, Map generation, Audio).

---

## 2. Technical Architecture & Conventions

### Godot 4 & GDScript Standards
- **Engine**: Godot 4.5+ (Standard Desktop build).
- **Target Resolution**: 1920x1080 (Aspect ratio preserved, responsive canvas scaling).
- **Language**: Strict typed GDScript. Always annotate variable types and function returns:
  ```gdscript
  var current_overkill: int = 0
  func calculate_spillage(raw_damage: int, target_hp: int) -> int:
  ```
- **Autoload Singletons** (located in `scripts/autoload/`):
  - `GameFlow`: High-level scene transitions and state machine (`TITLE`, `MAP`, `COMBAT`, `SHOP`, `REST`, `GAME_OVER`).
  - `RunManager`: Active run state, deck composition, relic inventory, HP, current act, path history.
  - `ContentDatabase`: Static lookup registry for all cards (`.tres`), relics, enemies, and statuses.
  - `SaveManager`: Persistent serialization and meta-progression storage.
  - `AudioManager`: Global SFX, ambient tracks, and audio buses.

### Directory Layout
- `scenes/`: Godot scene files (`.tscn`). Keep scenes modular!
- `scripts/`: GDScript files (`.gd`).
  - `scripts/autoload/`: Engine singletons.
  - `scripts/combat/`: Dual-chronometer arena, combatants, VFX, actors.
  - `scripts/data/`: Resource data definitions and schemas.
  - `scripts/map/`: Procedural node graph and traversal.
  - `scripts/ui/`: Presentation layers, modal dialogs, HUD.
- `data/`: Custom Godot `.tres` resource files (cards, relics, enemies).
- `assets/`: 2D sprites, textures, environment art, UI badges, audio.

---

## 3. MULTI-AI COLLABORATION PROTOCOL (CRITICAL)

This project is actively developed by **two human partners**, each paired with their own AI assistant.
Because the two AIs run independently on separate machines, **Git and repository files are the shared coordination layer**.

Every AI working on this repository **MUST STRICTLY OBEY** the following 4 rules:

### Rule 1: Always Check & Update `ACTIVE_WORK.md`
Before generating code or planning modifications:
1. Open [`ACTIVE_WORK.md`](ACTIVE_WORK.md).
2. Check the **Active Lock Table**.
   - If the files you need to touch are currently **LOCKED** by the other partner's AI, **DO NOT EDIT THEM**.
   - Alert the user immediately and select an unblocked feature or orthogonal subsystem.
3. If your target files are free, **claim your lock** in `ACTIVE_WORK.md`:
   - Declare: Partner Name, Feature, Branch Name, and exact file paths locked.
   - Commit this lock or keep it updated.

### Rule 2: Godot Scene Conflict Prevention (`.tscn` / `.tres`)
Godot `.tscn` and `.tres` files use internal generated UIDs. If two AIs touch the same scene simultaneously, resolving the resulting Git merge conflict can corrupt node hierarchies.
- **Never edit monolithic shared scenes concurrently.**
- **Componentize Everything**: When creating UI or combat features, build them as self-contained sub-scenes (e.g. `relic_pedestal_view.tscn`, `enemy_slot.tscn`) and instance them dynamically or as separate nodes.

### Rule 3: Git Branching Isolation
- **NEVER push unreviewed experimental work directly to `main`.**
- Work exclusively in feature branches:
  - Format: `feat/<developer>-<feature-name>` or `fix/<developer>-<bug-name>`
  - Example: `feat/yonatan-sentinel-vfx` or `feat/partner-act2-events`
- Always pull the latest `main` (`git pull origin main`) before creating a new branch.

### Rule 4: Session Handoff Log (`CHANGELOG_AI.md`)
When you complete a task or conclude a coding session:
1. Append a structured entry to [`CHANGELOG_AI.md`](CHANGELOG_AI.md):
   - **Date & Author**: e.g., `2026-09-18 | Yonatan's AI`
   - **Branch / PR**: e.g., `feat/yonatan-clock-polish`
   - **Completed**: Bullet list of exact features and mechanics implemented.
   - **Files Modified / Added**: List of key paths.
   - **Verification**: How the change was tested (headless Godot run, scene smoke test, manual test).
   - **Next Steps / Handoff**: Notes for the other partner's AI on what is ready to be integrated or built next.
2. Release your file locks in [`ACTIVE_WORK.md`](ACTIVE_WORK.md).

### Rule 5: Deliver every gameplay update through GitHub

The partners require an easy installer and update log on GitHub for every delivered gameplay feature or update. A local build or source push alone is not a completed delivery.

1. Bump `VERSION` for a new playable build and build a Windows installer. Keep large binaries in GitHub Release assets, not Git history. A portable ZIP is useful as an additional option.
2. Test the exported payload, not only source scenes. Record exactly what passed and any untested areas or known balance issues.
3. Publish a versioned GitHub Release tied to the exact source commit. Mark unreviewed test builds as prereleases; do not merge experimental gameplay into main merely to publish a download.
4. Add an entry to `UPDATE_LOG.md`: date, version, changes, installer/release links, source commit/tag/branch, save compatibility, verification, and known issues. Keep `CHANGELOG_AI.md` for the detailed technical handoff.
5. Update the prominent links in root `README.md` and `installer/README.md`. Ensure these documentation links reach the default branch through a reviewed documentation PR, even when gameplay remains on a feature branch. Clearly distinguish the downloadable build from main's source state.
6. Verify published download URLs and remote asset sizes/hashes before calling the update delivered. Preserve previous releases for rollback and comparison.
7. Documentation-only changes reference the existing installer and receive a log entry; they do not require rebuilding unchanged gameplay. If publication is blocked, state the blocker and delivery status explicitly.

This is the standing repository workflow requested by Yonatan. It does not authorize unrelated communications, purchases, or unreviewed gameplay merges.
