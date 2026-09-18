# CHANGELOG_AI.md — Multi-AI Handoff & Session Log

This file provides asynchronous context sharing between developers and their AI assistants. When finishing a session or merging a PR, add an entry at the top of this log.

---

### [2026-09-18] — Initial Collaboration Architecture & Full Game Upload
- **Author / AI**: Yonatan & Antigravity
- **Branch**: `main`
- **Key Changes**:
  - Configured repository ignore rules in `.gitignore` to prevent OS files and oversized build binaries from polluting Git.
  - Established universal AI context and multi-developer coordination protocols in `AGENTS.md` and `CLAUDE.md`.
  - Added live coordination and lock table in `ACTIVE_WORK.md`.
  - Added custom project skills in `.agents/skills/overkill-dev/`.
  - Staged and uploaded all core Godot 4 game systems, combat scenes, data resources, and documentation specs to GitHub.
- **Current State of the Game**:
  - Full dual-chronometer combat loop, enemy slot mechanics, cards, relics, and presentation screens implemented.
  - Autoloads configured: `GameFlow`, `RunManager`, `ContentDatabase`, `SaveManager`, `AudioManager`.
- **Handoff Notes for Incoming AI**:
  - The repo is now fully synchronized on GitHub.
  - Both partners can branch from `main`, check `ACTIVE_WORK.md` before claiming files, and develop features concurrently.

## 2026-09-18 | Yonatan's AI (Codex) — shared GitHub distribution
- **Branch:** `docs/yonatan-release-downloads`.
- **Completed:** Repository homepage and installer-folder download links, shared UPDATE_LOG, mandatory versioned installer/release handoff policy in AGENTS.md.
- **Files:** README.md, installer/README.md, UPDATE_LOG.md, AGENTS.md, ACTIVE_WORK.md, CHANGELOG_AI.md.
- **Verification:** Documentation review; links target the previously published 0.13.0 assets verified with HTTP 200 and matching hashes. No gameplay changes or binary rebuild.
- **Handoff:** Gameplay source remains on feat/yonatan-starter-relic-overlays at 07e1ce9; the current download is v0.13.0-test. Future gameplay deliveries must update installer links and UPDATE_LOG on GitHub.

## 2026-09-19 | Yonatan's AI (Codex) — verified 0.14 distribution
- **Branch / PR:** `feat/yonatan-014-downloads`, documentation-only PR to main.
- **Completed:** Published `v0.14.0-test` from `f2a331a741cd93be3c01f9f23919d0c186f04b38`. Uploaded Windows installer (228290291 bytes), portable ZIP (256882208 bytes), and SHA-256 manifest. Updated README, installer/README, install/README, checksums and UPDATE_LOG.
- **Verification:** All three GitHub assets returned HTTP 200; server SHA-256 digests match local packages. Portable entries match the exported payload tested with STARTER_RELIC_OK, CLOCK_SMOKE_OK and POLISH_INTEGRATION_OK. Exported game launched with Intel OpenGL. Installer wizard not tested.
- **Handoff:** Partner navigation: repository → Releases → 0.14.0 → Assets. Start a new run for the 12-relic deck and nine-hour clock. Gameplay remains on `feat/yonatan-014-presentation-polish` pending review. Boss balance needs human playtesting.
