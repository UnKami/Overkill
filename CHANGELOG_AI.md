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


## 2026-09-19 | Yonatan's AI (Codex) — verified 0.16 distribution
- **Branch / PR:** `feat/yonatan-016-downloads`, documentation-only update to main.
- **Completed:** Published `v0.16.0-test` at `b2b0f76d85b6d1656af339e28522fc5d7d995b67`: distinct Sentinel armor, execution blade, arena depth, synchronized strike damage and reduced draw calls. Uploaded installer (230801163 bytes), portable ZIP (259439718 bytes), checksums; updated README, installer/README, install/README and UPDATE_LOG.
- **Verification:** Exported SILHOUETTE_OK, CINEMATIC_FINISH_OK, RIG_MOTION_OK, STARTER_RELIC_OK, CLOCK_SMOKE_OK and PRESENTATION_014_OK. Final exported combat passed four speed/reduced-motion combinations. Rendered poses/layout inspected. ZIP entries match tested export. All three published GitHub assets returned HTTP 200 and server SHA-256 digests match local files. Installer wizard untested.
- **Handoff:** Repository → Releases → 0.16.0 → Assets; use Play Sentinel for direct testing. Existing 0.14/0.15 saves remain compatible. Gameplay stays on `feat/yonatan-sentinel-silhouette` pending review. Performance improved in draw submission count, not a verified 60 fps result; visual production remains in progress.


## 2026-09-19 | Yonatan's AI — Publish verified 0.17.0 distribution
- **Branch / PR:** `feat/yonatan-017-downloads`; documentation-only PR, gameplay remains on `feat/yonatan-readable-cinematic`.
- **Completed:** Published `v0.17.0-test` from `0d1182cf9d64609d9facc82ab384c5444b5447f7`; updated homepage, installer/install folder instructions, checksum and update log.
- **Verification:** Installer 230817337 bytes and portable ZIP 258162235 bytes; both plus checksum are public HTTP 200 downloads with GitHub SHA-256 digests matching local artifacts. Exported gameplay/preview/typography/contact checks are recorded in the release notes. No gameplay merged to main.
- **Files:** `README.md`, `installer/README.md`, `install/README.md`, `installer/OverkillSetup-0.17.0.sha256`, `UPDATE_LOG.md`, `CHANGELOG_AI.md`.
- **Handoff:** Partner navigation is repository → Releases → 0.17.0 → Assets → installer; folders contain direct links. Downloadable gameplay differs from main's runtime source; use the exact release tag or feature branch.

## 2026-09-19 | Yonatan's AI — Publish verified 0.18.0 distribution
- **Branch / PR:** `feat/yonatan-018-downloads`; documentation-only PR. Gameplay remains on `feat/yonatan-cinematic-encounter`.
- **Completed:** Published `v0.18.0-test` from `fbb8055`; homepage, installer/install instructions, checksum and update log point to 0.18.
- **Files:** `README.md`, `installer/README.md`, `install/README.md`, `installer/OverkillSetup-0.18.0.sha256`, `UPDATE_LOG.md`, `CHANGELOG_AI.md`.
- **Verification:** Installer 230931689 bytes, ZIP 258282703 bytes. All three release assets verified HTTP 200 and GitHub SHA-256 matches against local files. Source/exported mechanics, preview, audio lifecycle and rendered contact checks passed; portable entries match export.
- **Handoff:** Partner navigation: repository → Releases → 0.18.0 → Assets. Play Sentinel opens the 3D slice. Gameplay is not merged to main; use the exact tag/feature branch. This remains an incremental playtest, not AAA completion.

## 2026-09-19 | Yonatan's AI — Verified 0.19 partner downloads
- **Branch / PR:** `feat/yonatan-019-downloads`; distribution documentation only.
- **Completed:** Published `v0.19.0-test` from source `2df0d09817f50bea863af4dd4d8e2c8a39f08454`. Updated homepage, installer/install folders, release notes, checksums and update log. Gameplay remains on `feat/yonatan-sentinel-production` pending review.
- **Files:** `README.md`, `install/README.md`, `installer/README.md`, `installer/OverkillSetup-0.19.0.sha256`, `docs/encounter-019.md`, `UPDATE_LOG.md`.
- **Verification:** All three published assets returned HTTP 200 and GitHub SHA-256 digests matched local files. Installer is 232253209 bytes; portable ZIP is 260925693 bytes. All five ZIP entries hash-match the tested payload. Exported mechanics, preview, contact, graphics-settings and terminal-finish tests pass; Vulkan rendered Sentinel/large-text/inspection checks pass. Installer wizard remains untested.
- **Handoff:** Tell partner: repository → Releases → 0.19.0 → Assets → OverkillSetup-0.19.0.exe, then Play Sentinel encounter. The installer folder also provides access. This remains a development playtest: broader character/animation production and frame pacing are unfinished. No experimental gameplay files are included in this documentation change.

## 2026-09-19 | Yonatan's AI — 0.20 partner download navigation
- **Branch:** `feat/yonatan-020-downloads`; documentation-only release update.
- **Completed:** Homepage, installer/install folders, update log, delivery notes and checksum file point to published `v0.20.0-test`.
- **Verified:** Installer 233448556 bytes, portable ZIP 262141678 bytes and checksum asset return HTTP 200; GitHub SHA-256 digests match local tested files. Release source is `c5650f121a5180b928432dfab3901bc49803dc56` on `feat/yonatan-sentinel-production`.
- **Handoff:** Repository → Releases → 0.20.0 → Assets → OverkillSetup-0.20.0.exe, then Play Sentinel encounter. Gameplay is not merged by this documentation PR. Not AAA completion; limits are in release notes. Locks released.

## 2026-09-19 | Yonatan / Codex — Verified 0.21 distribution documentation
- Branch: feat/yonatan-021-downloads; documentation-only publication PR.
- Completed: homepage, installer/install folders, update log, preview notes and checksum file point to v0.21.0-test. Partner path: Releases → 0.21.0 → Assets → OverkillSetup-0.21.0.exe; installed shortcut Play Boneghoul preview.
- Verification: GitHub release is public prerelease at source 758700f0e211e391c693a77d8112f270bed2a380. All three assets return HTTP 200 and match local SHA-256. Exported launcher/retry, eight rendered encounter modes, starter/clock/preview/settings checks passed. Interactive installer wizard untested; art/performance are not AAA acceptance.
- Handoff: gameplay remains on feat/yonatan-sentinel-production; this branch changes distribution documentation only. Locks released.

## 2026-09-19 | Yonatan / Codex — 0.22 distribution documentation prepared
- Branch: feat/yonatan-022-downloads, based on current main.
- Prepared: homepage, installer/install instructions, update log, detailed release notes and SHA-256 manifest for v0.22.0-test.
- Validation: packaged game checks and six portable payload hashes pass on the source branch. GitHub installer asset uploaded; portable ZIP still transferring on the measured slow connection. Do not merge these links into main until the release is published and all uploaded digests/downloads are verified.
- Scope: distribution documentation only; no gameplay merge. Publication handoff follows after verification.
