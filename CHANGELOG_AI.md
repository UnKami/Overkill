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

## 2026-09-19 | Yonatan's AI (Codex) — verified 0.14.1 distribution
- **Branch / PR:** `feat/yonatan-0141-downloads`, documentation-only update to main.
- **Completed:** Published `v0.14.1-test` at `241dbf05f83c31714aca2cacb2541b8cd68bc46a`: compact top relic choices without shared backdrop, pulsing option outlines, unchanged nine-hour combat. Uploaded installer, portable ZIP and checksums; updated homepage, installer instructions and UPDATE_LOG.
- **Verification:** Source/exported BATTLE_GUIDANCE_OK and PRESENTATION_014_OK; inspected 1080p and large-text 720p screenshots and ultrawide bounds. ZIP entries match tested payload. All three GitHub assets returned HTTP 200 and server SHA-256 digests match local files. Installer compiled; interactive wizard untested.
- **Handoff:** GitHub → Releases → 0.14.1 → Assets. Existing 0.14 saves remain compatible. Gameplay branch `feat/yonatan-top-relic-choices` awaits review; boss balance unchanged.


## 2026-09-19 | Yonatan's AI (Codex) — verified 0.15 distribution
- **Branch / PR:** `feat/yonatan-015-downloads`, documentation-only update to main.
- **Completed:** Published `v0.15.0-test` at `7b1de5ddc8d49f18663dc7e5e4428aaace3a0946`: cinematic Sentinel material/lighting finish and clearer combat feedback. Uploaded installer (230788384 bytes), portable ZIP (259426972 bytes), and checksums. Updated README, installer/README, install/README and UPDATE_LOG.
- **Verification:** Exported STARTER_RELIC_OK, CLOCK_SMOKE_OK, CINEMATIC_FINISH_OK and PRESENTATION_014_OK; inspected rendered output. ZIP entries match tested export. All three release assets returned HTTP 200 and server SHA-256 digests match local files. Interactive installer wizard untested.
- **Handoff:** Repository → Releases → 0.15.0 → Assets. Use Play Sentinel to inspect the rigged encounter directly. Existing 0.14 saves remain compatible. Gameplay remains on `feat/yonatan-cinematic-combat-finish` pending review; this is a visual playtest, not AAA completion.
