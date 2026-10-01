# CHANGELOG_AI.md — Multi-AI Handoff & Session Log

This file provides asynchronous context sharing between developers and their AI assistants. When finishing a session or merging a PR, add an entry at the top of this log.

---

## 2026-10-01 | Yonatan / Codex — Overkill 0.37.0 battle and relic-screen polish
- **Branch / release source:** `fix/yonatan-full-ui-polish`; published [`v0.37.0-test`](https://github.com/UnKami/Overkill/releases/tag/v0.37.0-test), exact tested source `93ede9f5ce801b75049a29e6b0f6590034bd5017`.
- **Completed:** Enlarged the battle combatants by 20% and restored readable vitality/Block/status bands; replaced retired relic spokes with dedicated essence sunbursts on replacement choices; showed each owned relic copy separately; clarified Keep & Sweep consequences; made Humming Shrine constraints inline; and made the Zenith offer surface more transparent.
- **Files changed:** Combat presentation, relic collection/replacement, shrine and Zenith UI; 15 sunburst image assets; `VERSION`, project version, player notes and release docs.
- **Verification:** Godot 4.5.1 presentation fixture passed `PRESENTATION_014_OK`; crystalline consistency fixture passed `CRYSTALLINE_VISUAL_OK`. Installer compiled at 319,086,739 bytes; isolated silent install, launch and uninstall passed. Portable ZIP contains five files, all matching payload SHA-256; extracted portable game launched successfully. GitHub reports all three release assets with matching local size/SHA-256 and public URLs returned HTTP 200.
- **Downloads:** Installer SHA-256 `7d2613d13c70b2497edde2378e290bb32378267e0f5313aaa31c626b28b93909`; portable ZIP SHA-256 `ad2ddef9d94b238246e4b2bd858818b7fa4c1a460fccab207639e0d7cddea4da`; manifest SHA-256 `8c6f12be422939128591af3e2e16e969d1d548d6afe65366f0bfc56cafdcd0e2`.
- **Mechanics / compatibility:** No damage, enemy behavior, relic effects, turn order, clock rules, progression or save schema changed; existing saves remain compatible. Installer unsigned; interactive installer wizard and a full human campaign remain unverified.
- **Default-branch docs:** Documentation-only PR [#22](https://github.com/UnKami/Overkill/pull/22) updates the main-branch download links. Gameplay remains on its feature branch; release tag points to the tested commit above.
- **Locks / handoff:** Locks released. Source branch includes current `main` and the release commit; subsequent bookkeeping does not change the release tag.

## 2026-09-30 | Yonatan / Codex — Overkill 0.35.0 relic capacity and survivability
- **Branch / source:** `fix/yonatan-full-ui-polish`; gameplay source pushed as `7364b8da896f25cda30b9f4603014d61a3d721b8`.
- **Completed:** Caps active chronometer inventory at 12; full battle relic rewards prompt selection of a specific replacement copy, with identity and upgraded form visible. Blocks overflow from shop/event grants; adds stable copy identification; raises new-run Vitality to 500 with proportional legacy-save migration; tunes all progression bosses to 100 HP; replaces verbose combat stats with icon/value chips and hover descriptions; reduces event-choice copy clutter.
- **Files:** Reward/collection/event UI and inventory/run manager; combat HUD/introduction and class selection; four boss resources; integration test; balance baseline; `VERSION`; player-facing encounter notes and checksums.
- **Verification:** Godot 4.5.1 parse and six targeted integration/presentation/arrival/consistency/visual/combat suites passed. Final exported portable ZIP contains exactly five files matching payload hashes; extracted game launched headlessly with exit code 0. Installer compiled (294,072,188 bytes; SHA-256 `084083e8c83096d2f2690c7a11351233f1a98057ce8f024858c04731ce9f9b49`). ZIP is 321,157,929 bytes; SHA-256 `1f200452acd25ae566f9177475e953207b92503eb521f03339e1e4d47ef1b2bf`.
- **Delivery blocker:** The packaged files are local only. Release upload could not start because Git Credential Manager failed to provide an API credential (`Unable to persist credentials with the 'wincredman' credential store`); the 0.35.0 release/tag and default-branch download-docs PR are not published. Do not call this build downloadable from GitHub. Retry publication once authenticated GitHub API access is restored, using exact tested source `7364b8da896f25cda30b9f4603014d61a3d721b8` and the local artifacts above.
- **Known limits:** The interactive installer wizard and full human campaign are unverified; 500-vs-100 is an intentionally generous balance playtest. Headless runs still show restricted Windows certificate-store and Godot ObjectDB/resource shutdown notices. Unrelated user-modified `.import` sidecars were preserved.
- **Locks:** Released; source branch remains separate from `main`.

## 2026-09-30 | Yonatan / Codex — Overkill 0.33.0 UI polish
- **Branch / release:** `fix/yonatan-full-ui-polish`; published prerelease [v0.33.0-test](https://github.com/UnKami/Overkill/releases/tag/v0.33.0-test), exact tested source `39d28619a9d929fc17cabb15bea311482de373a2`.
- **Completed:** Re-aligns the title confirmation to its content column and hides the underlying menu until cancel/confirm; gives map tiers 164px spacing with vertical scroll when needed; restores distinct context paintings for upgrade, Overkill and Vitality choices; removes the broad radial relic haze and renders crisp, colored light rays behind relic art.
- **Files changed:** `scripts/ui/title_screen.gd`, `scripts/ui/modal_confirm_dialog.gd`, `scripts/ui/map_screen.gd`, `scripts/ui/map_ux_test.gd`, `scripts/ui/pre_battle_offer.gd`, `scripts/ui/relic_pedestal_view.gd`, `scripts/ui/relic_light_strokes.gd`, `scripts/combat/presentation_polish_test.gd`, `scripts/combat/crystalline_visual_test.gd`, `VERSION`, `docs/encounter-033.md`, `.test-artifacts/verification-033.md`, release/update docs.
- **Verification:** Godot 4.5.1 source map, presentation, consistency, clock-smoke and visual suites passed. Isolated installer test verified all five installed-file hashes, launched the app for an 8-second observation, and removed the test install. Portable ZIP contains exactly five export-matching files. Headless scene tests are not claimed for the exported windowed runtime; full campaign and pixel-level desktop acceptance remain open.
- **Assets:** Installer 294,058,204 bytes, SHA-256 `a426885dbe96c90dc967aa139d478fd064bef5edbbf44f32ecb40c593c012543`; ZIP 321,143,084 bytes, SHA-256 `ae3544c8bda397221b1da4cb7facff73277704a0ae08698c432e6812fccb7764`.
- **Mechanics:** No damage, enemy behavior, relic effects, turn order, clock rules, progression or save schema changed; no autoplay.
- **Public assets:** Installer and portable ZIP sizes/hashes are in `UPDATE_LOG.md`; all three remote asset records match the manifest and each download endpoint returned HTTP 200. Default-branch download docs merged via documentation-only [PR #18](https://github.com/UnKami/Overkill/pull/18), merge commit `cefb5a7da5048bb4e641b6b2523be37d45efd96`.
- **Next / handoff:** Users can install and test the prerelease. Human review of actual screens and a full campaign remain encouraged; computer-use desktop visual capture was unavailable in this session, so don't treat headless fixture coverage as pixel acceptance. Locks released.

## 2026-09-30 | Yonatan / Codex — Overkill 0.32.0 prerelease published
- **Branch / release:** `fix/yonatan-full-ui-polish`; exact source `211e7d96862ac6aa19c58ce5a59cffc12181fbe6`; tag [`v0.32.0-test`](https://github.com/UnKami/Overkill/releases/tag/v0.32.0-test).
- **Completed:** Published the threat-scaled enemy accents, floating relic presentation, Keep & Sweep emphasis, actionable-button/idle polish, direct map travel, cleaner abandon and pre-battle screens, and slightly faster clock-pointer transitions. Gameplay remains on the feature branch; no gameplay merge to `main`.
- **Verification:** Five Godot map/presentation/combat/crystalline suites passed. The final portable ZIP was extracted; its five files matched exported payload hashes, and the packaged game launched headlessly with isolated user data (exit 0). GitHub installer, ZIP and checksum-manifest sizes/digests matched, and all public download URLs returned HTTP 200. Installer: 294,056,249 bytes, SHA-256 `03d5aef1395f48d06d004bec3a63090315b06545545c724b08edc6a5b5ce723b`; ZIP: 321,141,315 bytes, SHA-256 `11fd6161feaf49fa7c2e7a336949df98212726637b178a37ee799df523f16e71`.
- **Known limits:** Installer compiled but its setup wizard/installed game remain unverified; use the portable ZIP if setup fails. Full human campaign and final visual acceptance remain open. The restricted runner logs a certificate-store warning and ObjectDB shutdown notice.
- **Documentation:** [PR #17](https://github.com/UnKami/Overkill/pull/17) merged as `922f9ed0c009dcd36cc1705808a5a66046b1e0e4`; `README.md`, `installer/README.md`, `UPDATE_LOG.md`, and `docs/encounter-032.md` were verified on `main`. File locks released.

## 2026-09-30 | Yonatan / Codex — threat palette and immersive UI polish
- **Branch / delivery:** `fix/yonatan-full-ui-polish`; local candidate `0.32.0`, not published. GitHub authentication was unavailable, so the public tested release remains `0.31.0-test`.
- **Completed:** Promoted the approved threat-scaled jade/amethyst/spectral-rose/blood-red enemy family accents over the shared obsidian-and-ivory foundation; added floating borderless relic presentation with color-matched light strokes; strengthened Keep & Sweep; added restrained electric focus/hover contours and reduced-motion-aware idle drift; made reachable map nodes route directly; hid pause choices behind abandon confirmation; simplified pre-battle offer choices to title/action; and modestly shortened clock-pointer transitions only. Combat math, turn order, impact timing, enemy behavior, relic mechanics and saves were not changed.
- **Files:** Ten active enemy illustrations and import sidecars; `scripts/ui/` shared button, relic light, map, pause, offer, relic, modal and chronometer presentation; presentation/map regression fixtures; visual/art canon; `VERSION`; `docs/encounter-032.md`.
- **Verification:** `map_ux_test.tscn`, `presentation_polish_test.tscn`, `clock_battle_smoke.tscn`, `crystalline_consistency_test.tscn`, and `crystalline_visual_test.tscn` passed. Rendered review covered map routing, treasure reveal, relic replacement/assembly, offer cards and abandon confirmation. Exported `build/windows/Overkill.exe` launched headlessly with its PCK. Installer compiled (294,056,097 bytes); isolated silent-install verification did not return a reliable exit status or installed payload, so wizard installation is not accepted. GitHub release/push and public asset verification remain blocked by unavailable authentication.
- **Next / handoff:** Restore repository authentication to publish the exact reviewed source as an explicitly marked prerelease, verify installer/portable artifacts and download hashes, then update default-branch download documentation through a reviewed PR. User visual acceptance and a normal interactive Windows install/playthrough remain outstanding. File lock released.

## 2026-09-30 | Yonatan / Codex — obsidian and ivory enemy palette study
- **Branch / delivery:** `fix/yonatan-full-ui-polish`; local art preview only, no new gameplay release. Existing installer remains [v0.31.0-test](https://github.com/UnKami/Overkill/releases/tag/v0.31.0-test).
- **Completed:** Used built-in image generation to repaint Boneghoul and Gorged Sentinel as dark obsidian crystal with luminous, slightly warm ivory cores/fissures and silver facets. Retained their existing creature identities and crystalline style; unchanged Executioner, scenery and relic palette.
- **Files:** Two transparent candidate PNGs, exact prompts (`prompts.json`), isolated Godot fixture (`preview.gd` / `preview.tscn`) and six original/candidate/warm-arena captures under ignored `.test-artifacts/enemy-palette-preview/`. Only coordination logs changed in tracked source; no production image, scene, data, script or VERSION change.
- **Verification:** `ENEMY_PALETTE_PREVIEW_OK`; true alpha asserted; both original/candidate pairs rendered in the actual combat scene at 1920x1080, plus both on the furnace background. Reviewed candidate renders for silhouette readability beside the hero. Compatibility renderer; isolated APPDATA, silent audio, reduced motion. Nonfatal Windows certificate-store warning remains. This is visual composition verification, not gameplay or animation acceptance.
- **Next / handoff:** The neutral samples established the obsidian/ivory foundation for the full-roster hue study below. Both passes remain isolated previews: no candidates have been packaged, uploaded or promoted, and original assets were preserved. File locks released.

## 2026-09-30 | Yonatan / Codex — enemy hue distinction variations
- **Scope:** Follow-up preview requested by user; local only, no production or release asset changes.
- **Completed:** Drafted an enemy-family color key and generated accent candidates for the full ten-enemy roster: jade feral/decay, amethyst constructs/relic guardians, spectral rose apparitions, blood red Excess. Black obsidian and ivory remain the shared foundation. Draft key and prompts are in `.test-artifacts/enemy-palette-preview/accent-prompts.md`.
- **Verification:** Isolated Godot fixture rendered all ten candidates in the real battle scene at 1920x1080; Boneghoul and Sentinel also passed a warm-furnace contrast review (`ENEMY_PALETTE_PREVIEW_OK`). All ten battle captures were visually checked; the final boss was specifically reviewed for matte/edge separation at combat scale. The known Windows certificate-store warning is nonfatal.
- **Next:** This four-family color key remains a proposal, not canon. Production assets and the published `v0.31.0-test` remain unchanged pending the user's review. No build or release was created for this concept-only pass.

## 2026-09-30 | Yonatan / Codex — complete crystalline continuity pass
- **Branch / release:** `fix/yonatan-full-ui-polish`; published [0.31.0 prerelease](https://github.com/UnKami/Overkill/releases/tag/v0.31.0-test), exact source/tag `5c2169b86002a82e6fbccaf391647f8c53d0f045` / `v0.31.0-test`.
- **Completed:** Restored 26 approved crystalline relic objects and the matching Heavy Hammer flight image; completed ten distinct non-player crystalline enemy silhouettes; replaced all seven map symbols; generated the Executioner-led crystalline passage used by startup/navigation; restored the three matching act-transition paintings and repaired title wrapping/continue placement. Removed 36 discarded images from the active tree, retaining recoverable local copies in Godot-excluded `.test-artifacts/retired-art-031/`.
- **Completed:** Rebuilt map hierarchy around route selection with compact utilities and preview-before-travel; fixed the actual icon offset caused by theme minimum button width; added a dedicated treasure reveal; made whole relic artwork selectable; replaced the remaining card-upgrade route with clock-relic upgrades; removed static duplicate fighters obscuring animated actors and centered HP beneath normalized silhouettes.
- **Mechanics:** Enemy/relic resource changes are art paths only; combat values, AI, clock order, status math and save schema preserved. The pre-battle upgrade now improves an actual clock relic rather than a legacy unused card. No autoplay.
- **Files modified / added:** `scripts/ui/{map_screen,treasure_screen,relic_pedestal_view,clock_collection_screen,card_upgrade_selection,pre_battle_offer,reward_screen,screen_transition,act_transition_screen,cinematic_art}.gd`; `scripts/autoload/game_flow.gd`; `scripts/combat/{combat_controller,illustrated_actor,illustrated_stage}.gd`; matching map/reward/treasure scenes; all 26 `data/clock_relics/` art paths and ten `data/enemies/` art paths; ten crystalline enemy assets, seven map icons and new loading painting; `project.godot`; `VERSION`; `docs/art/`; visual-canon documents; new consistency/map/visual test scenes and scripts; arrival/presentation regression updates; `.gitignore`; `installer/overkill.iss`; `scripts/release/publish_crystalline_release.ps1`; player notes.
- **Verification:** All 12 self-terminating suites passed both source and exported PCK. Packaged render fixtures passed for production pages, all ten enemies, three maps/transitions, treasure, upgrades, inspection and hammer motion. All 26 relic descriptions checked normal/large; 720p/1080p/ultrawide bounds; 54 forecasts; 30 enemy-intent sweeps. ZIP five-file hashes match. Final installer installed into isolated HKCU/test directory, matched payload hashes, launched, passed consistency, and uninstalled; existing HKLM 0.30.0 payload/registration unchanged. Explicit current-user installer override enabled; normal all-user default preserved.
- **Known limits:** Unsigned prerelease. Full human campaign, interactive installer wizard and sustained hardware FPS not accepted. Starter-only fixture loses four boss cases. Restricted certificate-store and some fixture ObjectDB/resource shutdown notices persist; no script/assertion failures in passing suites. Unrelated audio/card editor import metadata left untouched and unstaged.
- **Delivery:** Installer 296,588,151 bytes, SHA-256 `2968a8c2af0c3a9fad55db096254c9b7fd5281d2a548b5bdd636ad023dca6dd0`; ZIP 323,673,946 bytes, SHA-256 `4fc47571216f70dc3e7f8bb73907aef1a20ad971363833954d65d713b9829522`. All three GitHub assets' sizes/digests and public HTTP 200 verified. Tag resolves to tested source. Reviewed four-file documentation-only [PR #16](https://github.com/UnKami/Overkill/pull/16) merged as `d10661ca66c50edb1b1cf1344d35f5f35a3adcc0`; all four default-branch pages verified. Gameplay was not merged into main. Release-helper JSON-array scope handling corrected in the documentation follow-up; no runtime rebuild required.
- **Next steps / handoff:** File locks released. User can install and start a new run for visual/playability acceptance. Preserve `docs/art/crystalline-canon.md` for future art; do not reintroduce discarded v2 objects or generic knight enemies. Old release assets and recoverable retired-art copies remain available.

## 2026-09-29 | Yonatan / Codex — cinematic battle and relic presentation polish
- **Branch / release:** `fix/yonatan-full-ui-polish`; 0.30.0 candidate, prerelease publication in progress.
- **Completed:** Removed the baked-in combat fighters from the active battle background path; centered route-node emblems; moved Combat Log and How to Play into the Esc pause menu; removed the persistent Enemy Next readout and the extra in-battle inspect control while retaining the `I` battlefield-inspection shortcut. Increased relic-object prominence in battle cards and expanded the full-screen battlefield inspection with accumulated attack, Block, statuses, and relic-derived carryover values.
- **Completed:** Replaced the boot loading art with a character-led Executioner scene. Generated 26 transparent relic-object illustrations and mapped the active relic catalog to distinct silhouettes/materials and the agreed essence palette (orange attack, blue Block, purple buffs, green debuffs, blood-red direct Overkill; mixed hues for genuinely combined effects). Updated the visual canon accordingly.
- **Completed:** Slowed normal combat attack/contact/reaction/impact/Overkill pacing to 2x duration, preserving Fast Mode as the opt-in faster cadence. Renamed relic temper actions to Upgrade and added a 1.5-second old-to-new relic transition before the upgrade commits. Updated timing-oriented QA fixtures to accommodate the new pacing.
- **Mechanics preserved:** No combat values, turn order, enemy intent, clock rules, relic effects, run rules, or progression mechanics intentionally changed.
- **Files modified / added / removed:** `scripts/combat/combat_controller.gd`; `scripts/combat/attack_presentation.gd`; `scripts/combat/battle_arrival_visual_test.gd`; `scripts/combat/battle_intro_sequence.gd`; `scripts/combat/clock_battle_presentation.gd`; `scripts/combat/clock_battle_smoke.gd`; `scripts/combat/clock_polish_test.gd`; `scripts/combat/clockwork_actor.gd`; `scripts/combat/clockwork_stage.gd`; `scripts/combat/combat_vfx.gd`; `scripts/combat/enemy_intent_readout_test.gd`; `scripts/combat/enemy_slot.gd`; `scripts/combat/feedback_queue.gd`; `scripts/combat/illustrated_actor.gd`; `scripts/combat/illustrated_stage.gd`; `scripts/combat/presentation_polish_test.gd`; `scripts/autoload/audio_manager.gd`; `scripts/autoload/tutorial_callout.gd`; `scripts/ui/battlefield_inspection.gd`; `scripts/ui/chronometer_view.gd`; `scripts/ui/cinematic_art.gd`; `scripts/ui/clock_collection_screen.gd`; `scripts/ui/clock_socket_view.gd`; `scripts/ui/damage_number.gd`; `scripts/ui/map_screen.gd`; `scripts/ui/pause_menu.gd`; `scripts/ui/relic_choice_overlay.gd`; `scripts/ui/relic_pedestal_view.gd`; `scripts/ui/rest_site_screen.gd`; `scripts/ui/upgrade_preview_dialog.gd`; `project.godot`; `docs/visual_canon.md`; `docs/cinematic-worlds.md`; all 26 `assets/relics/active/*_v2_object.png` illustrations and their 26 resources in `data/clock_relics/{starter,common,rare}/`; `assets/screens/cinematic/loading_executioner_bell_foundry.png`. Removed `assets/environments/combat_arena_bg.jpg` and its import sidecar, and the retired `assets/screens/cinematic/loading_shard_corridor.{jpg,png}` files and sidecars.
- **Verification:** Godot 4.5.1 import/export-pack succeeded. All eleven self-terminating suites passed from source and again from the exported Windows executable/PCK, including full presentation bounds, all 26 relic descriptions at normal/large text, 54 forecasts, 30 cinematic routes, and upgrade animation integration. The packaged default game exits cleanly, the installer compiled, and all five portable-ZIP entries match their build-payload SHA-256. Public release-asset verification remains. The restricted runner prints certificate-store and ObjectDB shutdown notices. The balance fixture wins its trash/elite cases and loses four bosses; no balance changes were in scope.
- **Next steps / handoff:** Complete exported-payload checks, publish the exact tested commit as the 0.30.0 GitHub prerelease with installer/portable ZIP/checksums, update the default-branch download links through a docs-only PR, then release the active lock. The separate request for another 20–40 cinematic scene backgrounds remains outside this scoped polish pass; only the new loading scene is included.

## 2026-09-28 | Yonatan / Codex — 0.25 unified crystalline visual canon
- Branch / release: `feat/yonatan-tactical-inspection`; source `05639415e20682b2d8d152e8cf6df6ba046c3eb2`; prerelease https://github.com/UnKami/Overkill/releases/tag/v0.25.0-test.
- Completed: established the supplied cyan/amber crystalline techno-fantasy canon; preserved the approved Executioner, enemy illustrations, combat arena, screen family and supplied relic references; generated fourteen transparent active-relic objects, Hollow Coin, a clean clock face and a new center sigil in that direction.
- Removed: mismatched character/enemy atlases, flat Executioner portrait, comic crypt and blurred map backgrounds, brass/gothic clock art, medieval relic scenes, unused 3D models/materials/build pipeline, experimental showcase scenes and launchers.
- UI: relic art is centered and dominant; replacement choices include relic images; HP/status panels sit lower beneath characters; pre-battle choices use contextual scenery; Inspect Battlefield is an opaque two-clock tactical view with numerical accumulated attack, Block and other full-cycle stats while concealed enemy hours remain hidden.
- Mechanics preserved: damage, enemy AI, nine-hour clock and three-sector rules, relic effects, turn order, progression, outcomes and run rules. No autoplay.
- Key files: `docs/visual_canon.md`; `assets/relics/active/*_object.png`; `assets/ui/combat/chronometer_dial_clean.png`; `assets/ui/combat/nexus_sigil.png`; `scripts/ui/battlefield_inspection.gd`; `scripts/ui/relic_art.gd`; `scripts/combat/combat_controller.gd`; `scripts/combat/illustrated_stage.gd`; `scripts/ui/relic_pedestal_view.gd`; `scripts/ui/relic_choice_overlay.gd`; `scripts/ui/pre_battle_offer.gd`.
- Verification: clean Godot editor import; source and packaged starter, 30-case preview/hidden-intent, combat smoke, presentation and encounter suites pass; packaged default game launch passes with only the known forced-quit ObjectDB warning. 1080p assembly, replacement, inspection and pre-battle screenshots visually reviewed.
- Delivery: installer 206,705,256 bytes (`7c87607be8b48e1e2e6f5d6c9566a6d86304ea4c6dbb3e26705034c2a88245e0`); ZIP 233,800,988 bytes (`b49ae34a53f8ddae43282c2cfc7126e5971b9a531580aafef8faef1c6d1bebae`); checksum manifest SHA-256 `1294f385ef99ae7471c9f9cea986931a12acbc5b3dde25a6df3e3d01e584af8e`. Public GitHub sizes/hashes and HTTP 200 verified.
- Handoff: visual acceptance and human boss-balance review remain with the partners; installer is unsigned and the interactive wizard was not manually stepped through. Source changes remain on the feature branch pending review. Locks released.

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

## 2026-09-18 | Yonatan's AI (Codex)
- **Branch / PR:** `feat/yonatan-starter-relic-overlays` (local source changes; no release export).
- **Completed:** New runs start with 16 independent copies: 6 Iron Strike (6 damage), 6 Guard Plate (6 Block), 2 Twin Blades (4 damage twice), 2 Reinforced Wall (8 Block). Existing inventories remain intact. Varied relics remain in the reward/shop catalog. Descriptions explicitly explain persistent Block; engine already retains Block until absorbed or battle ends.
- **Completed:** Reusable floating relic-choice panel replaces the visible bottom dock and its reserved arena height. Assembly presents three choices alongside the numbered, pulsing destination. Quadrant panel presents the drawn relic, three replacement buttons tied to the clock sockets, and Keep & Sweep. Existing pulsing guidance/preview and relic-flight animation are retained; panel hides during placement/resolution. Added hour-resolution banners. Directed Sentinel stage extends into the reclaimed space.
- **Files Modified / Added:** `scripts/run/clock_inventory.gd`; `data/clock_relics/starter/rel_02_twin_blades.tres`, `rel_04_guard_plate.tres`, `rel_06_reinforced_wall.tres`; `scripts/ui/relic_choice_overlay.gd`; `scripts/combat/combat_controller.gd`; `scenes/combat_scene.tscn`; `scripts/combat/starter_relic_test.gd`; `scenes/starter_relic_test.tscn`; existing battle guidance, smoke and polish integration tests; `overkill_master_gdd.md`.
- **Verification:** Godot 4.5.1: STARTER_RELIC_OK (composition, unique IDs/copy isolation, block retention/absorption/reset, two-hit damage); CLOCK_SMOKE_OK (12 hours, duplicate input, 4 quadrants, swap, wrap, single victory); POLISH_INTEGRATION_OK (inventory/save/legacy migration/removal/shop/encounter mechanics); rendered BATTLE_GUIDANCE_OK at 1920x1080 and 1280x720, including dispatch through the new replacement button and checking overlay hides during binding. Screenshots in `artifacts/battle-guidance/`. Windows root-certificate warning persists; some headless runs report ObjectDB shutdown warnings, without gameplay script errors in passing suites.
- **Balance findings / Handoff:** Existing greedy encounter policy wins boneghoul (69 HP) and act1 elite (29 HP), loses act1 boss (enemy 122 HP left) and act2 boss (65 HP left), and reaches its 60-turn assertion on act3 boss. This fixture gives later bosses upgraded starter relics without reward variety; it does not certify full-run balance. Revisit boss balance and realistic reward progression separately; enemy stats were not changed. Source is ready for review; existing packaged executables were not rebuilt. Start a new run to use the new composition.

## 2026-09-18 | Yonatan's AI (Codex) — Windows test distribution
- **Branch / release:** `feat/yonatan-starter-relic-overlays`; prepared GitHub prerelease `v0.13.0-test`.
- **Completed:** Built Windows installer 0.13.0 and portable ZIP, added `install/README.md` with download links, updated installer delivery notes and VERSION, generated SHA-256 checksums. No merge to main.
- **Files:** `VERSION`, `scripts/release/build_installer.ps1`, `docs/starter-relic-release.md`, `install/README.md`, `installer/OverkillSetup-0.13.0.sha256`; prior starter deck/UI changes included.
- **Verification:** Exported executable launched from build/windows without source-project arguments using Intel OpenGL. Packaged STARTER_RELIC_OK, CLOCK_SMOKE_OK and POLISH_INTEGRATION_OK passed. Installer compiler completed successfully. The installer wizard itself was not run; packaged payload was tested directly. Known Windows certificate-store and headless ObjectDB exit warnings persist. Boss-balance limitations documented in release notes.
- **Handoff:** Download installer or extract the full portable folder. Start a new run to get the revised inventory. Release binaries belong in GitHub assets, not Git history.
## 2026-09-18 | Yonatan's AI (Codex) — shared GitHub distribution
- **Branch:** `docs/yonatan-release-downloads`.
- **Completed:** Repository homepage and installer-folder download links, shared UPDATE_LOG, mandatory versioned installer/release handoff policy in AGENTS.md.
- **Files:** README.md, installer/README.md, UPDATE_LOG.md, AGENTS.md, ACTIVE_WORK.md, CHANGELOG_AI.md.
- **Verification:** Documentation review; links target the previously published 0.13.0 assets verified with HTTP 200 and matching hashes. No gameplay changes or binary rebuild.
- **Handoff:** Gameplay source remains on feat/yonatan-starter-relic-overlays at 07e1ce9; the current download is v0.13.0-test. Future gameplay deliveries must update installer links and UPDATE_LOG on GitHub.

## 2026-09-19 | Yonatan's AI (Codex) — 0.14 nine-hour clock and presentation
- **Branch / PR:** `feat/yonatan-014-presentation-polish`; release tag `v0.14.0-test` identifies exact gameplay source. Main receives distribution documentation only until gameplay review.
- **Completed:** Nine-hour player/enemy clocks, three-sector sweeps, twelve-copy starter deck (5 attack, 5 guard, 1 lifesteal, 1 next-attack multiplier), persistent 5-Block Guard, three reserves, minimum ten-copy removal rule. Hidden enemy actions reveal before choices and remain visible; reverse and twin-hand patterns adapted.
- **Completed:** Horizontal floating choice/replacement panel, explicit commit controls, stable previews, battlefield inspection, health outside overlay, larger effect text, cleaner reward/shop layouts, map route layering and footer spacing.
- **Files:** `scripts/combat/combat_controller.gd`, `enemy_clock_pattern.gd`, combat regression tests; `scripts/data/clock_relic_data.gd`, `clock_socket_data.gd`; `scripts/run/clock_inventory.gd`; `scripts/ui/chronometer_view.gd`, `clock_socket_view.gd`, `clock_engraving.gd`, `relic_choice_overlay.gd`, `relic_pedestal_view.gd`, `clock_collection_screen.gd`, `class_select_screen.gd`, `reward_screen.gd`, `screen_design.gd`, `map_screen.gd`, `frontend_showcase.gd`; `scenes/combat_scene.tscn`; new presentation test scene/script; starter resources REL-04/13/14; VERSION, release build script, docs/spec override, README/installer links and UPDATE_LOG.
- **Verification:** Godot 4.5.1 STARTER_RELIC_OK, CLOCK_SMOKE_OK, POLISH_INTEGRATION_OK, BATTLE_GUIDANCE_OK, FRONTEND_FLOW_OK, PRESENTATION_014_OK. Rendered screenshot review at 1080p and large-text 720p; layout assertions also ultrawide. Exported installer payload passed starter, smoke and inventory tests. Exported rendered layout assertions passed, but its debug screenshot writer targets read-only res:// and cannot save images; source screenshots were reviewed. Installer compiled successfully; portable ZIP entries hash-match tested payload. Interactive installation wizard not tested.
- **Balance:** ENCOUNTER_PLAYTHROUGHS_OK: basic policy wins normal and elite Act I, loses four boss fixtures. No claim of finished boss balance or AAA production. Nonfatal certificate-store and headless ObjectDB warnings remain.
- **Handoff:** Start a new run for the twelve-copy deck. Existing inventories are preserved. Lifesteal heals actual enemy HP lost, capped at missing player HP; boost survives non-attacks, applies to the next attacking relic, does not compound. Review feature branch before gameplay merge. Maintain versioned installer, portable ZIP, checksums and update log on every delivered feature.

## 2026-09-19 | Yonatan's AI (Codex) — verified 0.14 distribution
- **Branch / PR:** `feat/yonatan-014-downloads`, documentation-only PR to main.
- **Completed:** Published `v0.14.0-test` from `f2a331a741cd93be3c01f9f23919d0c186f04b38`. Uploaded Windows installer (228290291 bytes), portable ZIP (256882208 bytes), and SHA-256 manifest. Updated README, installer/README, install/README, checksums and UPDATE_LOG.
- **Verification:** All three GitHub assets returned HTTP 200; server SHA-256 digests match local packages. Portable entries match the exported payload tested with STARTER_RELIC_OK, CLOCK_SMOKE_OK and POLISH_INTEGRATION_OK. Exported game launched with Intel OpenGL. Installer wizard not tested.
- **Handoff:** Partner navigation: repository → Releases → 0.14.0 → Assets. Start a new run for the 12-relic deck and nine-hour clock. Gameplay remains on `feat/yonatan-014-presentation-polish` pending review. Boss balance needs human playtesting.

## 2026-09-19 | Yonatan's AI (Codex) — 0.14.1 top relic choices
- **Branch / PR:** `feat/yonatan-top-relic-choices`; release tag `v0.14.1-test` pins the playable source.
- **Completed:** Compact horizontal choices at top, no shared panel backdrop or heading/instruction strip, pulsing available-option outlines with static reduced-motion highlight, compact top replacement controls, combat notices moved out of the chooser area. Preserved explicit bind/replace actions and pulsing numbered socket previews. Fixed compact button bounds. No combat-rule or save-format changes.
- **Files:** `scripts/ui/relic_choice_overlay.gd`, `relic_pedestal_view.gd`; `scripts/combat/combat_controller.gd`, `presentation_polish_test.gd`; VERSION, release builder, delivery notes, README/installer instructions, update log and checksums.
- **Verification:** Source and exported payload BATTLE_GUIDANCE_OK and PRESENTATION_014_OK. Rendered 1080p, large-text 720p and ultrawide checks; no overlap with clocks/health, buttons inside options, stable previews, inspection, locked slots and empty reserves. Portable ZIP contents hash-match the tested export. Screenshot harness now saves in user://, including packaged runs. Installer wizard remains untested; existing nonfatal certificate-store warning remains.
- **Handoff:** Install 0.14.1 from GitHub Releases. 0.14.0 saves remain compatible. Gameplay stays on the feature branch pending review; documentation-only PR updates main for partner access. Boss balance is unchanged.

## 2026-09-19 | Yonatan's AI (Codex) — verified 0.14.1 distribution
- **Branch / PR:** `feat/yonatan-0141-downloads`, documentation-only update to main.
- **Completed:** Published `v0.14.1-test` at `241dbf05f83c31714aca2cacb2541b8cd68bc46a`: compact top relic choices without shared backdrop, pulsing option outlines, unchanged nine-hour combat. Uploaded installer, portable ZIP and checksums; updated homepage, installer instructions and UPDATE_LOG.
- **Verification:** Source/exported BATTLE_GUIDANCE_OK and PRESENTATION_014_OK; inspected 1080p and large-text 720p screenshots and ultrawide bounds. ZIP entries match tested payload. All three GitHub assets returned HTTP 200 and server SHA-256 digests match local files. Installer compiled; interactive wizard untested.
- **Handoff:** GitHub → Releases → 0.14.1 → Assets. Existing 0.14 saves remain compatible. Gameplay branch `feat/yonatan-top-relic-choices` awaits review; boss balance unchanged.


## 2026-09-19 | Yonatan's AI (Codex) — 0.15 cinematic combat finish
- **Branch / PR:** `feat/yonatan-cinematic-combat-finish`; release tag `v0.15.0-test` pins the playable source.
- **Completed:** Worn-steel texture and roughness treatment, muted brass, darker floor/ambient light, restrained stage color grading, contact shadows and beveled Sentinel hammer. Explicit HP/BLOCK/BLOCKED/HEAL/BLEED/THORNS/RECOIL feedback, staggered number positions, relic-name activation notice, lethal HP separated from Overkill. World-space guard rings; removed duplicate 2D slash/spark layers and extra screen shake in DirectedArena. No combat-rule or save-format change.
- **Files:** `scripts/combat/{directed_arena,rigged_combatant,combat_controller,cinematic_finish_test}.gd`, `scripts/ui/damage_number.gd`, shader files, generated `assets/characters/rigged/worn_metal_015.png`, cinematic test scene, VERSION, release builder, delivery notes, README/installer instructions, update log/checksums.
- **Verification:** Source and exported CINEMATIC_FINISH_OK; exported STARTER_RELIC_OK, CLOCK_SMOKE_OK, PRESENTATION_014_OK. Rendered and inspected 1080p/720p images; layout checks include large text and ultrawide, inspection and replacements. ZIP entries hash-match tested export. Installer compiled; interactive wizard untested. Existing certificate-store warning remains.
- **Limitations:** Material/lighting work targets the rigged Sentinel encounter. Other encounters retain illustrated art. Not AAA completion: bespoke enemy models, animation and environment breadth remain. Full-stage benchmark median around 45 ms on this Intel environment, with empty-scene baseline around 32 ms; no 60 fps claim. Boss balance unchanged.
- **Handoff:** Use Play Sentinel for direct encounter testing in a separate profile. Publish installer, portable ZIP and SHA-256 assets, verify live downloads, then update main through a documentation-only PR. Gameplay awaits feature review.

## 2026-09-19 | Yonatan's AI (Codex) — verified 0.15 distribution
- **Branch / PR:** `feat/yonatan-015-downloads`, documentation-only update to main.
- **Completed:** Published `v0.15.0-test` at `7b1de5ddc8d49f18663dc7e5e4428aaace3a0946`: cinematic Sentinel material/lighting finish and clearer combat feedback. Uploaded installer (230788384 bytes), portable ZIP (259426972 bytes), and checksums. Updated README, installer/README, install/README and UPDATE_LOG.
- **Verification:** Exported STARTER_RELIC_OK, CLOCK_SMOKE_OK, CINEMATIC_FINISH_OK and PRESENTATION_014_OK; inspected rendered output. ZIP entries match tested export. All three release assets returned HTTP 200 and server SHA-256 digests match local files. Interactive installer wizard untested.
- **Handoff:** Repository → Releases → 0.15.0 → Assets. Use Play Sentinel to inspect the rigged encounter directly. Existing 0.14 saves remain compatible. Gameplay remains on `feat/yonatan-cinematic-combat-finish` pending review; this is a visual playtest, not AAA completion.


## 2026-09-19 | Yonatan's AI (Codex) — 0.16 armor and synchronized strikes
- **Branch / PR:** `feat/yonatan-sentinel-silhouette`; tag `v0.16.0-test` pins the playable source.
- **Completed:** Bone-mounted curved Sentinel pauldrons, breastplate, nine-mark chest seal and greaves; replaced the hero's primitive blade with a beveled execution blade. Refined melee spacing and bounded attack weight shift. Added rear dais/braziers. Batched columns/bands, reused metal materials, simplified metal fragment shading, single directional shadow pass for fixed camera, cached static clock engravings and stopped their continuous redraw under reduced motion.
- **Timing fix:** Discovered fixed 0.32-second damage timers could fire while the rig was still winding up on low-frame-rate runs. DirectedArena now awaits the attacking clip's contact window, sets the contact pose and aligns the weapon before damage/impact. Cleared obsolete trail samples at synchronization to avoid a large artificial triangle. Impact effects/numbers use the same target surface point. Balance/save schema unchanged.
- **Files:** `scripts/combat/{forged_armor,rigged_combatant,directed_arena,combat_controller,silhouette_test,cinematic_finish_test}.gd`; silhouette test scene; `scripts/ui/clock_engraving.gd`, metal shader; VERSION, release builder, delivery notes, download docs and checksums.
- **Verification:** Exported SILHOUETTE_OK, CINEMATIC_FINISH_OK, RIG_MOTION_OK, STARTER_RELIC_OK, CLOCK_SMOKE_OK and PRESENTATION_014_OK. Final exported cinematic test passed all four normal/fast × normal/reduced-motion combinations with exactly-once damage assertions. Inspected rendered idle/contact/compact shots; tested attachment bounds, outward face winding, root settling and effect cleanup. Layout checks cover 1080p, large-text 720p and ultrawide.
- **Performance / limits:** Comparable full-scene draw submissions fell from about 680 to 455. Median frame samples remained roughly 43–50 ms with variable spikes on this Intel environment; no 60 fps or measured frame-time improvement claim. Broader bespoke models, animation variety, environment production and boss balancing remain. Existing certificate-store and headless shutdown warnings persist. Interactive installer wizard not tested.
- **Handoff:** Publish 0.16 installer/ZIP/checksums, verify GitHub downloads, update main through documentation-only PR. Gameplay remains isolated for review. Use Play Sentinel to inspect the cinematic encounter directly; existing 0.14/0.15 saves are compatible.

## 2026-09-19 | Yonatan's AI (Codex) — verified 0.16 distribution
- **Branch / PR:** `feat/yonatan-016-downloads`, documentation-only update to main.
- **Completed:** Published `v0.16.0-test` at `b2b0f76d85b6d1656af339e28522fc5d7d995b67`: distinct Sentinel armor, execution blade, arena depth, synchronized strike damage and reduced draw calls. Uploaded installer (230801163 bytes), portable ZIP (259439718 bytes), checksums; updated README, installer/README, install/README and UPDATE_LOG.
- **Verification:** Exported SILHOUETTE_OK, CINEMATIC_FINISH_OK, RIG_MOTION_OK, STARTER_RELIC_OK, CLOCK_SMOKE_OK and PRESENTATION_014_OK. Final exported combat passed four speed/reduced-motion combinations. Rendered poses/layout inspected. ZIP entries match tested export. All three published GitHub assets returned HTTP 200 and server SHA-256 digests match local files. Installer wizard untested.
- **Handoff:** Repository → Releases → 0.16.0 → Assets; use Play Sentinel for direct testing. Existing 0.14/0.15 saves remain compatible. Gameplay stays on `feat/yonatan-sentinel-silhouette` pending review. Performance improved in draw submission count, not a verified 60 fps result; visual production remains in progress.


## 2026-09-19 | Yonatan's AI — Readable combat and cinematic clarity (0.17.0)
- **Branch / release:** `feat/yonatan-readable-cinematic`, `v0.17.0-test`; no experimental gameplay merged to main.
- **Completed:** Enlarged battle/shared relic typography and action targets; restored visible inspection/instructions; grouped replacement/keep decisions; added nonmutating HP/Block forecasts, revealed intent text and combat history. Improved clock information hierarchy, map labels/route inspection, prices and persistent-block/keyword help. Reframed/dulled rigged materials and lighting; enlarged/grounded illustrated fighters and synchronized their strike contact.
- **Files modified/added:** `scripts/combat/decision_preview.gd`, `scripts/combat/combat_controller.gd`, `scripts/combat/clock_battle_presentation.gd`, `scripts/combat/directed_arena.gd`, `scripts/combat/illustrated_actor.gd`, `scripts/combat/illustrated_stage.gd`, `scripts/combat/presentation_polish_test.gd`, `scripts/ui/relic_choice_overlay.gd`, `scripts/ui/relic_pedestal_view.gd`, `scripts/ui/clock_socket_view.gd`, `scripts/ui/chronometer_view.gd`, `scripts/ui/hud.gd`, `scripts/ui/map_screen.gd`, `scripts/ui/clock_collection_screen.gd`, `scripts/ui/ux_017_test.gd`, `scenes/ux_017_test.tscn`, `assets/shaders/forged_metal.gdshader`, `docs/ux-017.md`, version/release documentation and build script.
- **Verification:** Source/export preview parity passed 30 cases, including full sweeps and replacement without live-state mutation; starter mechanics and combat smoke passed. Rendered typography checks cover all 14 relics in normal/large modes and every replacement target. 1080p/720p-large/ultrawide layouts passed. Source frontend flow passed. Exported cinematic contact tests passed all fast/reduced-motion combinations. Final illustrated scale/grounding visually reviewed and exported combat smoke checked. The first test wrapper used an incorrect `CLOCK_BATTLE_SMOKE_OK` marker; the actual `CLOCK_SMOKE_OK` log was independently checked, with no script/assertion errors, and the wrapper was corrected.
- **Next steps / handoff:** Review the feature branch before main integration. Preview math deliberately mirrors the current tick implementation; keep parity tests updated whenever combat rules change. Forecasts cover HP/Block and stop at concealed actions or a defeated current enemy; they do not forecast subsequent enemies, spillage or currency. Long replacement names use ellipsis with full tooltip. Bespoke character art/animation, consistent art pipelines, frame-time stability and human balance review remain open; do not describe this release as AAA complete. Windows installer wizard remains untested.

## 2026-09-19 | Yonatan's AI — Publish verified 0.17.0 distribution
- **Branch / PR:** `feat/yonatan-017-downloads`; documentation-only PR, gameplay remains on `feat/yonatan-readable-cinematic`.
- **Completed:** Published `v0.17.0-test` from `0d1182cf9d64609d9facc82ab384c5444b5447f7`; updated homepage, installer/install folder instructions, checksum and update log.
- **Verification:** Installer 230817337 bytes and portable ZIP 258162235 bytes; both plus checksum are public HTTP 200 downloads with GitHub SHA-256 digests matching local artifacts. Exported gameplay/preview/typography/contact checks are recorded in the release notes. No gameplay merged to main.
- **Files:** `README.md`, `installer/README.md`, `install/README.md`, `installer/OverkillSetup-0.17.0.sha256`, `UPDATE_LOG.md`, `CHANGELOG_AI.md`.
- **Handoff:** Partner navigation is repository → Releases → 0.17.0 → Assets → installer; folders contain direct links. Downloadable gameplay differs from main's runtime source; use the exact release tag or feature branch.

## 2026-09-19 | Yonatan's AI — 3D character and combat sound pass
- **Branch / PR:** `feat/yonatan-cinematic-encounter`; intended tag `v0.18.0-test`.
- **Completed:** Kept 3D as the requested production target. Layered asymmetric Executioner armor, torso-led sword poses and protective off-hand guard; combined rigid plate meshes by bone/finish. Fixed one-frame-old weapon aim origin exposed by the rendered contact test. Original swing/strike/guard/break/heal/result cues, contact-driven triggering, music ducking, bounded combat voices and live volume control using private audio RNG.
- **Files:** `scripts/art/build_executioner.py`, source Blender model/exported GLB, `scripts/combat/forged_armor.gd`, `rigged_combatant.gd`, `combat_controller.gd`, `scripts/autoload/audio_manager.gd`, `scripts/audio/build_combat_audio.py`, `assets/audio/combat/`, `encounter_quality_test.gd` and scene, `docs/encounter-018.md`, version/build/distribution files.
- **Verification:** Source and exported ENCOUNTER_018_OK, STARTER_RELIC_OK, UX_017_PREVIEW_OK (30 comparisons), CINEMATIC_FINISH_OK; source and exported SILHOUETTE_OK. Rendered 1080p and 720p captures inspected. Corrected contact gaps 0.018 player / 0.176 enemy; plate batching reduced this pass from 503 to 467 draw calls. Source deterministic six-enemy playthrough completed: basic policy wins boneghoul/elite, loses bosses; not balance acceptance. Portable ZIP entries match the exported payload. WAV analysis: zero clipped samples. Sound listening review and interactive installer wizard remain unverified.
- **Handoff:** Main-game enemy art is still mixed; Sentinel is the current 3D slice. Need bespoke enemy topology/materials, animation variety and performance work before AAA claims. Local rendered frame time about 39 ms median on Intel graphics; not a clean hardware benchmark or 60 fps. Existing certificate-store and ObjectDB exit warnings remain. Review gameplay before main integration.

## 2026-09-19 | Yonatan's AI — Publish verified 0.18.0 distribution
- **Branch / PR:** `feat/yonatan-018-downloads`; documentation-only PR. Gameplay remains on `feat/yonatan-cinematic-encounter`.
- **Completed:** Published `v0.18.0-test` from `fbb8055`; homepage, installer/install instructions, checksum and update log point to 0.18.
- **Files:** `README.md`, `installer/README.md`, `install/README.md`, `installer/OverkillSetup-0.18.0.sha256`, `UPDATE_LOG.md`, `CHANGELOG_AI.md`.
- **Verification:** Installer 230931689 bytes, ZIP 258282703 bytes. All three release assets verified HTTP 200 and GitHub SHA-256 matches against local files. Source/exported mechanics, preview, audio lifecycle and rendered contact checks passed; portable entries match export.
- **Handoff:** Partner navigation: repository → Releases → 0.18.0 → Assets. Play Sentinel opens the 3D slice. Gameplay is not merged to main; use the exact tag/feature branch. This remains an incremental playtest, not AAA completion.

## 2026-09-19 | Yonatan's AI — Sentinel production checkpoint (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; development checkpoint, no new release/tag/installer. Verified public playtest remains 0.18.
- **Completed:** Authored a new skinned clockwork Sentinel body without source knight geometry; recessed chest clock, curved bell helm, articulated joints/fingers, armor lames and boots. Four material surfaces replace many attached armor meshes. Three-quarter guard staging turns into the hammer contact pose and recovers. Cached static clock engravings, invalidated by size/faction color while live indicators continue animating.
- **Files:** `scripts/art/build_sentinel.py`, `art_source/characters/sentinel-production.blend`, `assets/characters/rigged/sentinel.glb` and import, `scripts/combat/rigged_combatant.gd`, `directed_arena.gd`, `silhouette_test.gd`, `sentinel_production_test.gd`/scene, `scripts/ui/clock_engraving.gd`, `docs/sentinel-production.md`.
- **Verification:** Source ENCOUNTER_018_OK, CINEMATIC_FINISH_OK and modular Bulwark SILHOUETTE_OK. Rendered SENTINEL_PRODUCTION_OK at 1080p/720p: original skinned mesh/four surfaces, player gap 0.018 and enemy gap 0.192, recovery, reduced motion and cleanup. Cache pixel tests prove unchanged content without invalidation and changed content after faction-color invalidation. Initial model fixture counted weapon meshes; fixed to verify skinned body and absence of Knight meshes. Initial cache test assumed the node getter changed to disabled; Godot source shows it retains configured mode, so replaced with actual pixel behavior checks.
- **Performance evidence:** Same full-battle setup decreased from 467 draws (0.18) to 395 with new model, then 371 with cache. VSync median remains about 38 ms on Intel Graphics; no stable FPS claim. Short diagnostic no-VSync samples still show spikes. Tests and captures are under `.tools/019-*` locally.
- **Handoff / unfinished:** Model is a production candidate, not approved AAA art; proportions, surface materials and animation variety still need refinement. Most enemies still lack dedicated 3D models. Full goal acceptance ledger is in `docs/sentinel-production.md`. Continue long warmed-up performance profiling and full-fight visual review before packaging the next version. Current 0.18 installer is intentionally retained until the next release candidate passes its broader gates.

## 2026-09-19 | Yonatan's AI — Sentinel material authoring checkpoint (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; current installer remains verified 0.18.
- **Completed:** Geometry-authored bevel wear and per-part patina in vertex colors; 16-ray, 8 cm local cavity bake; Sentinel-specific metal response separates rough dark faces from polished edges. Explicit active-color GLB export fixes a uniform-mask export failure. Recalculated mirrored panel winding before beveling, correcting visible armor face orientation. Kept four body surfaces and unchanged detail-texture sample count.
- **Files:** `scripts/art/build_sentinel.py`, Sentinel source Blender/GLB, `assets/shaders/sentinel_metal.gdshader`, `scripts/combat/rigged_combatant.gd`, `scripts/combat/sentinel_production_test.gd`, `docs/sentinel-production.md`.
- **Verification:** Final rendered SENTINEL_PRODUCTION_OK with no script/assertion errors; imported wear/cavity channel ranges checked for both metal surfaces. 1080p/720p battle and cool/warm close-up captures reviewed; normal attack contact and reduced-motion recovery/cache tests still pass. Full-battle draw count remains 371. Test artifacts `.tools/020-final-render/`; build/import logs `.tools/020-*`. No FPS improvement claimed.
- **Handoff:** Continue animation variety and proportion/detail production. Material masks are useful groundwork, not proof of AAA art. Hammer texture scale and body material treatment still need consistency, broad surfaces lack bespoke detail, other enemies remain incomplete. Local cavity shading is baked in rest pose rather than dynamically solved. No new release until the broader candidate is ready.

## 2026-09-19 | Yonatan's AI — Heavy attack cadence checkpoint (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; public installer remains 0.18.
- **Completed:** Sentinel-only attack retiming: 0.46 s contact and 1.08 s settled recovery, compared with hero 0.32/0.76. Private animation libraries preserve shared hero assets. Body turn, weight transfer, weapon alignment and trail track the same authored phases. Sound start and recovery wait follow actor timing. Corrected hammer trail length; cached animation-name lookups and constant timing tables avoid repeated per-frame lookup/allocation.
- **Files:** `rigged_combatant.gd`, `directed_arena.gd`, `combat_controller.gd`, `encounter_quality_test.gd`, `sentinel_production_test.gd`, `docs/sentinel-production.md`.
- **Verification:** ENCOUNTER_018_OK checks isolated clip lengths, sorted key times, anticipation boundary and normal/fast contact. CINEMATIC_FINISH_OK passes player/enemy damage across fast/reduced-motion combinations. Final rendered SENTINEL_PRODUCTION_OK; player contact gap 0.018 at 0.32 s, enemy 0.199 at 0.46 s; four surfaces and 371 decision-state draws preserved. Fixed the pose capture fixture to suspend actor processing while paused, preventing an idle weapon reset during screenshots. Windup capture visually inspected; pose fixtures exercise the actor independently, not a complete live battle phase transition. Logs/captures `.tools/021-*`.
- **Handoff:** This differentiates cadence using existing poses; it does not complete attack variety or bespoke motion production. Next animation work should author distinct heavy poses and reactions, inspect full-fight sequencing, and continue material/roster/performance work. The AAA goal remains incomplete; no new release was advertised.

## 2026-09-19 | Yonatan's AI — Braced guard and character direction checkpoint (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; public installer stays 0.18.
- **Completed:** Authored a distinct Sentinel guard clip using forward torso bracing, protective off-hand and guarded weapon arm; preserves the original supporting-foot pose and returns to idle. Added a stronger grounded dark-fantasy modeling reference, generated with built-in imagegen, with exact prompt and critique saved beside the image.
- **Files:** `scripts/art/build_sentinel.py`, Sentinel Blender/GLB, `scripts/combat/sentinel_production_test.gd`, `art_source/concepts/sentinel-target-v1.png`/`.md`/`.gdignore`, `docs/sentinel-production.md`.
- **Verification:** Rendered SENTINEL_GUARD_OK and SENTINEL_PRODUCTION_OK; supporting foot displacement below 0.025 m, distinct hand displacement above 0.07 m, repeated guards return to idle. CINEMATIC_FINISH_OK passes normal/fast/reduced-motion damage checks. Guard screenshot inspected. Reference inspected: strong armor/proportion direction but clock marks inconsistent with nine-hour mechanics; explicitly retain nine in the actual model.
- **Handoff:** Current model remains below the reference and AAA target. Prioritize the larger construction/proportion gap: curved overlapping armor, covered joints, recessed helm, fluted greaves and believable cloth. The reference must guide actual 3D work, not replace it. No new game release was advertised.

## 2026-09-19 | Yonatan's AI — Curved armor construction checkpoint (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; verified public installer remains 0.18.
- **Completed:** Replaced rectangular shoulder slabs with layered curved shells, rolled rims and fasteners. Added tapered fluted forearm/shin armor, dark joint coverings, pointed knee plates and overlapping closed-toe sabatons. Reworked the helm into a crest and recessed grille with restrained slit light. Added a folded split tabard weighted between hips and thighs, preserving the visible nine-mark chest clock.
- **Files:** `scripts/art/build_sentinel.py`, `art_source/characters/sentinel-production.blend`, `assets/characters/rigged/sentinel.glb`, `docs/sentinel-production.md`.
- **Verification:** Rendered SENTINEL_GUARD_OK and SENTINEL_PRODUCTION_OK: skinning, four surfaces, vertex masks, repeated attacks/guards, contact, recovery, reduced motion and 1080p/720p framing. CINEMATIC_FINISH_OK checks damage across normal/fast/reduced-motion combinations. Close-up review caught open boot ends; closed those before the final export. Local evidence `.tools/023-final-*` and `.tools/023-damage.log`.
- **Cost / handoff:** Body increases from 17,062 to 30,322 Blender vertices while retaining four surfaces and 371 full-battle draws. Short final sample roughly 45 ms median / 52 ms p95; not a release performance benchmark. Cloth uses bone skinning, not simulation. The silhouette is improved but still below the modeling reference; anatomy/proportions, material detail, weapon consistency, broader animation and arena production remain open. No new installer/release is advertised for this unfinished candidate.

## 2026-09-19 | Yonatan's AI — Cathedral staging checkpoint (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; verified installer remains 0.18.
- **Completed:** Replaced smooth banded columns with instanced moulded stone piers and pointed ribs in a separate component. Reused existing stone textures; added world-aligned architectural mapping. Reworked unused arena-stone shader into a quieter matte floor/dais material, retaining visible relief after correcting an excessively dark first pass. Darkened brazier stands. Corrected floor clock marks from twelve to nine major hours with 27 subdivisions.
- **Files:** `scripts/combat/cathedral_architecture.gd`/UID, `scripts/combat/directed_arena.gd`, `assets/shaders/arena_stone.gdshader`, `scripts/combat/sentinel_production_test.gd`, `docs/sentinel-production.md`.
- **Verification:** Rendered CATHEDRAL_STAGE_OK checks nine-hour decoration, two architectural batches and outward mesh normals. SENTINEL_GUARD_OK and SENTINEL_PRODUCTION_OK retain contact/recovery, skinning/material-mask, cache and reduced-motion coverage. Inspected 1080p and 720p battle framing. No script/assertion/shader errors; known certificate-store warning remains. Local evidence `.tools/024-balanced-render/` and `.tools/024-balanced-render.log`.
- **Performance / handoff:** Full-battle draws remain 371; short sample median about 46 ms / p95 50 ms on Intel Graphics. No stable FPS or AAA claim. Simple braziers, hard shadows, painted distant architecture, character materials/proportions and broad animation production still require work. This is a development checkpoint, not a new installer release.

## 2026-09-19 | Yonatan's AI — Render isolation and weapon batching (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; public installer stays 0.18.
- **Completed:** Added repeatable rendered wall-clock profiler with warmed full/stage/UI/frozen-animation/resolution/MSAA isolation and beginning/end controls. GPU/CPU counters omitted for frozen stage to avoid stale measurements. Batched rigid weapon pieces into four finishes per weapon. Fixed shared helper's indexed/non-indexed concatenation failure by deindexing sources and reindexing the final surface.
- **Files:** `scripts/combat/arena_profile.gd`/UID, `scenes/arena_profile.tscn`, `forged_armor.gd`, `rigged_combatant.gd`, `sentinel_production_test.gd`, `docs/sentinel-production.md`.
- **Verification:** First batching candidate visibly lost the hammer head despite passing contact tests; rejected its profile. Added MIXED_GEOMETRY_OK fixture proving all thirteen mixed-source triangles and transformed extent survive. Corrected rendered capture inspected; WEAPON_BATCH_OK, SENTINEL_GUARD_OK and SENTINEL_PRODUCTION_OK pass, along with modular Bulwark SILHOUETTE_OK. No script/assertion errors; known certificate warning and headless exit ObjectDB warning remain. Valid artifacts `.tools/025-fixed-render/`, `.tools/025-fixed-profile.log`, `.tools/025-silhouette.log`.
- **Measured result:** Full-scene draws 371 -> 351; stage-only 145 -> 125. Corrected full-scene wall-clock median 20.7-21.4 ms, p95 65-70 ms on local Intel Graphics, overlapping prior results. No verified FPS improvement. Frozen-actor isolation changes little; frozen-stage UI is much faster. Lower resolution/MSAA improve medians but not spikes; production defaults unchanged. These idle scene diagnostics do not establish full-fight performance acceptance.
- **Handoff:** Continue GPU/frame-pacing investigation and broader art/animation production. Use `arena_profile.tscn` with GL compatibility; append `-- --arena-profile-short` for full/stage/full repeats. Do not use discarded `.tools/025-batch-profile.log` as performance evidence. Goal remains incomplete; no installer release for this candidate.

## 2026-09-19 | Yonatan's AI — Distinct Sentinel recoil (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; verified public installer remains 0.18.
- **Completed:** Authored a new Sentinel unguarded-hit reaction with backward/off-axis torso recoil, head response, opened arms, short settling hold and controlled half-second recovery. Forward guard remains protective and visibly distinct. Both clips use a shared reproducible reaction-authoring helper; model topology/material count unchanged.
- **Files:** `scripts/art/build_sentinel.py`, Sentinel source Blender/GLB, `scripts/combat/sentinel_production_test.gd`, `docs/sentinel-production.md`.
- **Verification:** Rendered SENTINEL_RECOIL_OK checks opposite guard/hit displacement, >5 cm upper-body recoil, <2.5 cm supporting-foot movement, interruption and recovery at normal/fast speed. Guard and recoil captures inspected. SENTINEL_PRODUCTION_OK and CINEMATIC_FINISH_OK retain geometry/contact/recovery and damage coverage, including reduced motion. No script/assertion errors; existing certificate warning and headless exit ObjectDB warning remain. Local evidence `.tools/026-render/`, `.tools/026-render.log`, `.tools/026-damage.log`.
- **Handoff:** Dedicated reaction is an animation improvement, not AAA acceptance. Heavy attack alternatives, death/finish production, full-fight motion review, broader character detail and frame pacing remain incomplete. Pose captures are actor fixtures; they do not demonstrate live battle UI sequencing. No new installer release was advertised.

## 2026-09-19 | Yonatan's AI — Defeat presentation and terminal UI (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; verified installer remains 0.18.
- **Completed:** Fixed stale NEXT SLOT/ENEMY NEXT prompts after victory/defeat. Finish clears clock highlights/interaction and placement guidance, and preserves a terminal enemy readout through refreshes. Defeated private core/weapon emissive materials power down over 0.48 seconds, scaled for fast mode, without affecting the survivor. Stage ignores late impacts and repeated/conflicting finish requests.
- **Files:** `combat_controller.gd`, `directed_arena.gd`, `rigged_combatant.gd`, new `finish_sequence_test.gd`/UID and scene, `docs/sentinel-production.md`.
- **Verification:** Rendered FINISH_SEQUENCE_OK covers all eight victory/defeat, normal/fast, normal/reduced-motion combinations through actual lethal damage and end-check paths. Checks single delayed result signal, persistent terminal animation state, no fresh impact effects, cleared guidance, isolated emissive fade and reduced-motion camera stability. Victory and defeat captures inspected. CINEMATIC_FINISH_OK retains damage accounting coverage. No script/assertion errors; existing certificate and headless exit ObjectDB warnings remain. Evidence `.tools/027-final-render/`, `.tools/027-final-render.log`, `.tools/027-damage.log`.
- **Handoff:** This verifies the finish/result signal, not the full reward scene or a complete run; the fixture initializes one-HP targets. Death poses remain shared, and broader bespoke animation/art/performance work is unfinished. No new installer was released for this candidate.

## 2026-09-19 | Yonatan's AI — Gravity-aware cloak drape (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; public installer remains 0.18.
- **Completed:** Added world-space cloak drape with pinned shoulder seam, gravity-directed lower cloth and floor constraint. Recomputed deformed normals, enlarged shader-displacement culling bounds, restrained flutter and filtered subpixel weave. Reduced motion disables flutter while retaining essential pose-dependent drape.
- **Files:** `assets/shaders/battle_cloth.gdshader`, `scripts/combat/rigged_combatant.gd`, `docs/sentinel-production.md`.
- **Verification:** Corrected a first shader compile failure by passing MODEL_MATRIX explicitly into the vertex helper. Final rendered FINISH_SEQUENCE_OK covers all eight outcome/speed/motion combinations; SENTINEL_PRODUCTION_OK and SENTINEL_RECOIL_OK retain combat/geometry checks. Reviewed victory, defeat and windup images; capes now hang behind kneeling actors instead of projecting rigidly outward. No final shader/script/assertion errors; existing certificate-store warning remains. Draw count 351 retained; no FPS improvement claim. Evidence `.tools/028-fixed-finish/`, `.tools/028-motion/` and matching logs.
- **Handoff:** This is a parametric drape approximation, not full cloth simulation: inertia and body/self-collision remain absent. Shader parameterization matches `_build_cloak`; keep dimensions coordinated. Broader character production, animation variety, environment finish and performance remain incomplete. No new installer release.

## 2026-09-19 | Yonatan's AI — Forged weapon look refinement (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; public installer remains 0.18.
- **Completed:** Removed bright additive scan speckle from shared forged metal; restrained albedo variation, moved detail emphasis to roughness and stabilized metalness. Darkened weapon steel/brass while retaining distinct cutting edges. Authored a longitudinal blade ridge and raised inlays to match. Separated broad-face/bevel normals to remove diagonal shading gradients on the hammer.
- **Files:** `assets/shaders/forged_metal.gdshader`, `scripts/combat/forged_armor.gd`, `scripts/combat/rigged_combatant.gd`, `docs/sentinel-production.md`.
- **Verification:** Rendered SENTINEL_PRODUCTION_OK, WEAPON_BATCH_OK, SENTINEL_RECOIL_OK; headless modular SILHOUETTE_OK. Reviewed battle-scale rendering and warm close-up. Geometry/contact/recovery tests pass; four weapon finishes and 351 full-battle draws retained. No script/shader/assertion errors; existing certificate and headless exit ObjectDB warnings remain. Evidence `.tools/029-final-render/`, `.tools/029-final-render.log`, `.tools/029-silhouette.log`.
- **Handoff:** Shared forged material also affects hero equipment/armor; Sentinel body wear/cavity shader remains separate. Bespoke damage/engraving, detailed grips, broader model production, animation variety and frame pacing still fall short of the target. This is an art-development checkpoint, not a new installer release or AAA acceptance.

## 2026-09-19 | Yonatan's AI — Renderer validation and saved graphics quality (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; public installer remains 0.18.
- **Completed:** Added saved High/Balanced/Performance 3D resolution controls (1600/1280/960 width caps), applied live while preserving full-resolution UI and default High. Avoided redundant viewport reallocations. Dynamic settings text honors saved large-text preference. Reaction geometry tests now sample authored animation timestamps instead of relying on delayed wall-clock poses.
- **Files:** `scripts/autoload/audio_manager.gd`, `save_manager.gd`, `scripts/ui/settings_panel.gd`, `scripts/combat/directed_arena.gd`, `sentinel_production_test.gd`, new `graphics_settings_test.gd`/UID and scene, `docs/sentinel-production.md`.
- **Verification:** Default Vulkan SENTINEL_PRODUCTION_OK / SENTINEL_RECOIL_OK; Vulkan and GL GRAPHICS_SETTINGS_OK verify live viewport sizing, persisted preferences, invalid fallback and unchanged clock layout. GL additionally verifies and captures normal/large-text settings at 720p through the actual GameFlow overlay. Captures inspected; no final script/assertion/shader errors. Known certificate-store warning remains. Evidence `.tools/030-vulkan-final.log`, `.tools/030-graphics-final.log`, `.tools/030-graphics-gl.log`.
- **Handoff:** Fresh Vulkan VSync-disabled full idle scene median 33-36 ms / p95 61-82 ms / p99 up to 235 ms on Intel Graphics. Frame pacing remains unacceptable; resolution options are not proof of stable performance. Pose fixtures do not replace full-fight motion review. Prior narrow Vulkan timing reports are not current-candidate acceptance. Continue bespoke art/animation production and performance investigation. No installer was published for this checkpoint.

## 2026-09-19 | Yonatan's AI — Original Sentinel collapse animation (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; public installer remains 0.18.
- **Completed:** Replaced Sentinel shared death animation with authored stagger, hold, asymmetric kneeling impact, rebound and final held pose. Supporting foot uses analytic placement; trailing leg moves back, off-hand lowers and weapon arm folds inward. Reproducible Blender build and exported GLB retain 30,322 vertices/four body surfaces. Hero death unchanged.
- **Files:** `scripts/art/build_sentinel.py`, `art_source/characters/sentinel-production.blend`, `assets/characters/rigged/sentinel.glb`, `scripts/combat/finish_sequence_test.gd`, `docs/sentinel-production.md`.
- **Verification:** First pose failed asymmetric-knee test and was corrected, not accepted. Final Vulkan and GL FINISH_SEQUENCE_OK across eight outcome/speed/motion combinations, supporting-foot drift below 1 mm, knee heights about 7.2/39.6 cm, visible body drop, single delayed result and terminal-state checks. Reviewed victory and final stage captures. Headless SENTINEL_PRODUCTION_OK preserves contact, guard, recoil and mesh checks; not a rendering benchmark. No final script/assertion/shader errors; known certificate and headless ObjectDB warnings remain. Evidence `.tools/031-final.log`, `.tools/031-gl.log`, `.tools/031-regression.log`; reject first `.tools/031-finish.log`.
- **Handoff:** Final stage capture intentionally bypasses the result fade for pose inspection; it does not validate reward-screen delivery. No ragdoll, weapon release or dynamic collision added. Broader art/animation/performance still require production work. No new installer was published.

## 2026-09-19 | Yonatan's AI — Phase-aware battle camera (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; public installer remains 0.18.
- **Completed:** Wider composition while choosing; closer framing during actions and battlefield inspection. Smooth 0.32-second transition, scaled in fast mode, follows actual overlay visibility and restores on Return. Large text receives extra head clearance. Reduced-motion mode retains a stationary wide composition. Character positions/contact and UI layout unchanged.
- **Files:** `scripts/combat/directed_arena.gd`, `combat_controller.gd`, `sentinel_production_test.gd`, `docs/sentinel-production.md`.
- **Verification:** Rejected first fixed close-up because helmet overlapped choices. Final Vulkan/GL SENTINEL_PRODUCTION_OK; GL adds large-text and real Inspect/Return controls. Projected helmet and floor checks include instruction text height at 1080p/720p. Reviewed action and compact decision captures. Headless CINEMATIC_FINISH_OK and FINISH_SEQUENCE_OK preserve damage/contact, normal/fast/reduced-motion and terminal handoff behavior. No final script/assertion/shader errors; existing certificate/ObjectDB warnings remain. Evidence `.tools/032-phase.log`, `.tools/032-large.log`, `.tools/032-contact.log`, `.tools/032-finish.log`; reject `.tools/032-framing.log`.
- **Handoff:** Action pose fixture hides choice cards but is not a full battle UI simulation. Composition tween owns position/vertical offset; existing impact tween owns FOV. Broader visual quality and stable frame pacing remain unfinished. No installer release or AAA acceptance for this checkpoint.

## 2026-09-19 | Yonatan's AI — 0.19 release candidate packaging
- **Branch / PR:** `feat/yonatan-sentinel-production`; candidate version 0.19.0.
- **Completed:** Packaged accumulated Sentinel model/material, reaction/death animation, cathedral/cloth, terminal UI, graphics settings and phase-aware camera work. Added matching delivery notes, installer/portable checksums and repository navigation updates. Build script selects the current minor-version delivery document instead of always shipping 0.18 notes.
- **Files:** `VERSION`, `project.godot`, `scripts/release/build_installer.ps1`, `docs/encounter-019.md`, root/install/installer READMEs, `UPDATE_LOG.md`, `installer/OverkillSetup-0.19.0.sha256`.
- **Verification:** Exported PCK passes starter, clock smoke, 30-preview parity, contact/motion modes, saved graphics and eight finish cases; exported Vulkan SENTINEL_PRODUCTION_OK includes normal/large text, compact framing and inspection. Rendered compact-large capture inspected. All five portable entries hash-match the tested files. Inno compiler completed successfully; interactive installer wizard remains untested. No exported script/assertion/shader failures; known certificate/headless exit warnings remain. Evidence `.tools/033-export-*.log`, `.tools/033-render.log`, `build/windows/installer-compile.log`.
- **Handoff:** This entry records local packaging only. Publish and verify assets, then update main's distribution docs before claiming delivery. Full AAA art, roster, motion and frame-pacing goals remain incomplete; detailed limitations accompany the package.

## 2026-09-19 | Yonatan's AI — 0.19 publication verified
- **Release:** https://github.com/UnKami/Overkill/releases/tag/v0.19.0-test ; source `2df0d09817f50bea863af4dd4d8e2c8a39f08454` on `feat/yonatan-sentinel-production`.
- **Completed:** Uploaded installer (232253209 bytes), portable ZIP (260925693 bytes) and checksum file. All three public downloads returned HTTP 200 and their GitHub SHA-256 digests matched local assets. Installer SHA-256 `eba9cc2e2b6c9e681d9b928ea2d9e389aa460809c60f19252dca1c8369e0dcaf`; ZIP `f969bd2ab0bba2b5e6e472c16ab62882c4dafebdec60cc12998c2ff8fd696bd7`.
- **Main documentation:** Reviewed documentation-only PR https://github.com/UnKami/Overkill/pull/8 merged as `a629462c6083b73c3f5e2ca49cc3d7c320831f01`. Main's homepage, installer README and update log were read back through GitHub and verified to contain 0.19. Gameplay remains on the feature branch.
- **Handoff:** Partner can use repository → Releases → 0.19.0 → Assets → OverkillSetup-0.19.0.exe, then Play Sentinel encounter. Installer folder also points there. This is a verified delivery of an incomplete production playtest, not AAA acceptance. Continue art/animation/roster and frame-pacing work; preserve the release's stated limitations. Locks released.

## 2026-09-19 | Yonatan's AI — Sentinel helmet construction (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; verified installer remains 0.19.
- **Completed:** Enclosed helmet crown/top, lower crest, separate brow and cheek plates, shallow recessed face, narrower light slit, shorter breathing grille, temple hinges and three neck lames. Fixed close-up fixture timing so overlay-driven camera motion completes before the inspection camera is positioned.
- **Files:** `scripts/art/build_sentinel.py`, Sentinel Blender source/GLB, `scripts/combat/sentinel_production_test.gd`, `docs/sentinel-production.md`.
- **Verification:** Vulkan SENTINEL_PRODUCTION_OK retains mesh/skin/material, weapon contact, guard/recoil, choice clearance and large-text/compact checks. GL FINISH_SEQUENCE_OK covers eight outcome/speed/motion combinations. Centered cool/warm close-ups and final kneel inspected. No final script/assertion/shader failures; existing certificate warning remains. Geometry 30,322 -> 31,840 Blender vertices; four body surfaces retained. Evidence `.tools/034-render.log`, `.tools/034-finish.log` and their capture folders.
- **Handoff:** Prior 0.19 material close-up fixture was off-center after phase-aware framing; production camera was unaffected. This is incremental model work, not AAA acceptance. Material specificity, anatomy/proportions, grips/hands, animation roster and frame pacing remain open. No new installer for this checkpoint.

## 2026-09-19 | Yonatan's AI — Forged braziers and fire (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; verified installer remains 0.19.
- **Completed:** Replaced placeholder glowing discs with reusable forged basket props, banded stems, instanced coals and a depth-tested flame billboard. Batched all metal into two finishes per prop. Retained two existing warm lights and shadow-free local lighting; added restrained variation. Reduced motion freezes flame and light.
- **Files:** New `scripts/combat/arena_brazier.gd`/UID, `assets/shaders/brazier_flame.gdshader`/UID; `directed_arena.gd`, `sentinel_production_test.gd`, `docs/sentinel-production.md`.
- **Verification:** Rendered Vulkan/GL SENTINEL_PRODUCTION_OK and BRAZIER_PRESENTATION_OK validate batching, absence of new local shadow passes, stable reduced-motion shader/light state, contact/reactions and choice framing. Action and compact captures reviewed. Diagnostic scene draw counts remain 321 Vulkan / 351 GL; no FPS acceptance claim. No script/assertion/shader failures; known certificate-store warning remains. Evidence `.tools/035-render.log`, `.tools/035-gl.log`.
- **Handoff:** Flame is a small procedural billboard, not volumetric fire. Metal geometry is generated once, not per frame. Remaining environment material/geometry finish, character roster, animation breadth and frame pacing are substantial. No new installer for this checkpoint.

## 2026-09-19 | Yonatan's AI — Original Boneghoul 3D study (unreleased)
- **Branch / PR:** `feat/yonatan-sentinel-production`; verified installer remains 0.19.
- **Completed:** Original skinned skeletal body, hood/mantle, claws, recessed skull sockets and muted core using the shared rig. Connected palm/shoulder anatomy and corrected a roughly four-centimeter sole gap. Authored a four-second idle; excluded unvalidated shared sword clips from the GLB.
- **Files:** `scripts/art/build_boneghoul.py`, Boneghoul Blender source/GLB/import, isolated `boneghoul_study.gd`/UID and scene, `docs/boneghoul-production.md`.
- **Verification:** 20,926 Blender vertices/four surfaces; Vulkan study captures reviewed after geometry correction. Final rebuild/import/headless BONEGHOUL_STUDY_OK verifies skin, finger rig, idle and absence of combat clips. Both evaluated soles approximately 0.00600004 m above ground. No final script/assertion/parse/shader failures; existing certificate warning remains. Evidence `.tools/036-grounded.log` and `.tools/036-*-clean.log` / `.tools/036-clean.log`.
- **Handoff:** Early model study, not production combat integration or AAA acceptance. Skull/anatomy, cloth and material finish need substantial refinement, followed by claw attacks, guard/recoil/death and contact/foot/interruption tests. No new installer for this checkpoint. Locks released.

## 2026-09-19 | Yonatan's AI — Boneghoul claw motion blocking (unreleased)
- **Branch:** `feat/yonatan-sentinel-production`; installer remains 0.19.
- **Completed:** Authored raised anticipation/hold, diagonal claw rake, follow-through and idle recovery. Explicit 30 fps corrects inherited timing; excluded reference sword clips remain excluded. Source action detached during pose authoring to prevent pose reevaluation.
- **Files:** Boneghoul builder, Blender source, GLB, isolated study script and production notes.
- **Verification:** Vulkan BONEGHOUL_CLAW_OK and BONEGHOUL_STUDY_OK; exact clip durations, planted feet under 2 mm drift, hand arc over 0.3 m, recovery under 2 mm. Corrected anticipation/contact renders inspected. Earlier timing/capture candidates rejected. Final `.tools/037-accepted.log` and error log contain no script/assertion/shader failures; known certificate warning remains.
- **Handoff:** Motion blocking only. Target contact, weight transfer, shoulder deformation, other combat clips and material/sculpt quality remain incomplete. No encounter integration or installer publication. Locks released.

## 2026-09-19 | Yonatan's AI — Boneghoul skull/material refinement (unreleased)
- **Branch:** `feat/yonatan-sentinel-production`; installer remains 0.19.
- **Completed:** Narrowed lower skull, deepened eye sockets with smaller recessed lights, fused brow/cheek structure, flatter dark backing and smaller incomplete tooth rows. Added exported baked color variation to bone/iron/cloth. Remeshed/reduced facial additions; 34,271 Blender vertices/four surfaces.
- **Files:** Boneghoul builder, Blender source/GLB, study script, production notes.
- **Verification:** Rendered Vulkan BONEGHOUL_CLAW_OK and BONEGHOUL_STUDY_OK retain skin, timing, foot and recovery checks. Added verification that imported materials use nonuniform vertex color. Final skull close-up inspected. `.tools/038-verified.log` and error log have no script/assertion/shader failures; existing certificate warning remains. Earlier unfused facial additions and unused-color export rejected.
- **Handoff:** Still simplified anatomy and unfinished material/cloth quality. Nasal aperture, jaw, sculpt detail, shoulder deformation and full combat integration remain open. No installer release or AAA acceptance. Locks released.

## 2026-09-19 | Yonatan's AI — Impact batching and action profiling (unreleased)
- **Branch:** `feat/yonatan-sentinel-production`; installer remains 0.19.
- **Completed:** Reusable instanced impact sparks replace per-hit mesh/node allocation. Mixed colors, overlap capacity, original count/trajectory/lifetime preserved; empty batch hidden and tiny particle shadow passes removed. Added engraving-isolation and presentation-action profile modes with peak draws and slow-frame percentage.
- **Files:** `scripts/combat/directed_arena.gd`, `arena_profile.gd`, `sentinel_production_test.gd`, `docs/sentinel-production.md`.
- **Verification:** Initial Vulkan batch validation; final GL IMPACT_BATCH_OK/SENTINEL_PRODUCTION_OK and inspected mixed-impact capture; headless FINISH_SEQUENCE_OK all eight cases. Final logs clean of script/assertion/shader errors; certificate warning remains. GPU color tests skip headless dummy renderer and allow one byte of GL quantization after observed readback differences.
- **Measured result:** Normal/fast action peak draws 321 -> 298; no consistent frame-time improvement. Engraving isolation removed 26 draws with negligible timing benefit, so engraving code was not changed. Detailed sequential baseline/after measurements and limitations in production notes. Evidence `.tools/039-*.log`.
- **Handoff:** Presentation replay is not a complete fight. Broader frame pacing, bespoke character art/animation and integration remain unfinished. No installer release or AAA acceptance. Locks released.

## 2026-09-19 | Yonatan's AI — Decision clock clarity (unreleased)
- **Branch:** `feat/yonatan-sentinel-production`; installer remains 0.19.
- **Completed:** Decision pointer moves to the perimeter outside relic icons; center hubs clear away from text. Full player hand restores for resolution. Centered placement/sweep caption, retained enemy font size, prevented hover connectors crossing captions. Upcoming-hour pointers now agree with the prompt/pulse instead of starting at hour nine.
- **Files:** `chronometer_view.gd`, `battle_guidance.gd`, `combat_controller.gd`, `sentinel_production_test.gd`, production notes.
- **Verification:** Vulkan/final GL SENTINEL_PRODUCTION_OK and CLOCK_READOUT_OK; nine-angle clearance, opening-hour consistency, full-hand restoration and Sentinel three-hour readout fit. Normal/compact/large captures reviewed. CLOCK_SMOKE_OK and eight FINISH_SEQUENCE_OK cases pass. Final `.tools/040-*` logs contain no script/assertion/shader failures; certificate warning remains.
- **Handoff:** Long combined-effect enemy intents still need roster-wide layout review. Sweep capture is an isolated guidance fixture, not full replacement-flow validation. AAA art/performance goals remain incomplete. No new installer. Locks released.

## 2026-09-19 | Yonatan's AI — Roster enemy intent readability (unreleased)
- **Branch:** `feat/yonatan-sentinel-production`; installer remains 0.19.
- **Completed:** Full enemy actions moved to upper-right readout, short ordered-hour cue retained in clock. Live normal/large text support. Added missing Siphon drain description and scheduled second-hand telegraph, including no-strike echo behavior and hidden-action protection.
- **Files:** `combat_controller.gd`, `decision_preview.gd`, `sentinel_production_test.gd`, new `enemy_intent_readout_test.gd`/UID and scene, production notes.
- **Verification:** 30 roster sweep layouts in each text mode, bounds/choice clearance, Siphon/echo/hidden checks. Vulkan large-text captures reviewed; final headless Sentinel regression covers live settings and contact/framing. Eight finish cases pass. Final `.tools/041-verified*`, `041-normal-verified.log`, `041-regression-final.log`, `041-finish.log` have no script/assertion/signal/shader failures; certificate/headless exit warnings remain. Earlier overflow and signal mismatch attempts rejected.
- **Handoff:** Fixture changes readout data on the Sentinel scene, not finished enemy encounters. Art, animation and frame pacing still need substantial work. No installer release or AAA acceptance. Locks released.

## 2026-09-19 | Yonatan's AI — 0.20 local release packaging
- **Branch:** `feat/yonatan-sentinel-production`; candidate 0.20.0.
- **Completed:** Packaged post-0.19 helmet/brazier, impact batching and clock/enemy-intent clarity improvements. Boneghoul remains a source art study outside normal encounters. Updated version, delivery notes, download navigation and checksums.
- **Verification:** Seven exported headless suites pass: starter, clock smoke, 30-preview parity, contact modes, saved graphics, eight finish modes and roster intent. Shipped executable passes rendered Sentinel normal/compact/large checks and 30 large-text roster sweeps; compact-large capture reviewed. All five ZIP entries hash-match payload. Inno compiler completed; interactive wizard untested. Final `.tools/042-*` logs contain no script/assertion/shader/signal failures; known certificate/headless exit warnings remain.
- **Handoff:** This records local packaging only. Verify publication and main navigation separately before claiming delivery. Full AAA art/animation/performance goals remain incomplete.

## 2026-09-19 | Yonatan's AI — 0.20 publication verified
- **Release:** https://github.com/UnKami/Overkill/releases/tag/v0.20.0-test ; source `c5650f121a5180b928432dfab3901bc49803dc56` on `feat/yonatan-sentinel-production`.
- **Assets:** Installer 233448556 bytes, portable ZIP 262141678 bytes, checksum file 187 bytes. All three download URLs returned HTTP 200 and GitHub SHA-256 digests matched local files. Installer SHA `de34117b9285e8af9b867f01dc907a20bced2443fa75da0e3185b69d997cec84`; ZIP SHA `e003550c7a62ddbb8228b32d001e340f2e5caf1c9ea8c71dd135bb2da56364d9`.
- **Main navigation:** Documentation-only PR https://github.com/UnKami/Overkill/pull/9 merged as `ef85c0a5487088d8d9c3c14f3805d84f48dc8105`. Main homepage, installer README and update log were read back through GitHub and verified to contain 0.20. Gameplay remains on the feature branch.
- **Partner handoff:** Repository → Releases → 0.20.0 → Assets → OverkillSetup-0.20.0.exe; after installation use Play Sentinel encounter. Full packaged/source validation and known limits in release notes. Interactive wizard still untested. This is an incomplete production playtest, not AAA acceptance. Continue bespoke art/animation/roster and frame-pacing work. Locks released.

## 2026-09-19 | Yonatan's AI — Boneghoul brace/recoil studies (unreleased)
- **Branch:** `feat/yonatan-sentinel-production`; published installer remains 0.20.
- **Completed:** Authored claw guard with forward brace/protective hands and separate backward unguarded recoil with settling beat. Retained planted pelvis/legs, return-to-idle endpoints, four surfaces and 34,271 vertices.
- **Files:** Boneghoul builder, Blender source/GLB, model-study script and production notes.
- **Verification:** Vulkan and headless BONEGHOUL_REACTION_OK plus existing claw/model checks. Guard hand rises over 0.1 m, head movement over 0.05 m, opposite response directions, foot drift and final head/hand error under 2 mm. Rendered peak poses inspected. Final `.tools/043-*final*` and `043-headless.log` clean of script/assertion/shader failures; known certificate/headless exit warnings remain. Failed first interpolation build/stale preview rejected.
- **Handoff:** Isolated motion studies; no production routing. Shoulder/cloth deformation, richer weight transfer, death and actual combat contact/interruption still need work. No new installer or AAA acceptance. Locks released.

## 2026-09-19 | Yonatan's AI — Boneghoul collapse study (unreleased)
- **Branch:** `feat/yonatan-sentinel-production`; installer remains 0.20.
- **Completed:** Authored failing hold, pelvis drop, folded seated slump and held final pose. Baked analytical leg placement at 48 frames to retain planted feet. Revised initial crouch-like pose after rendered review.
- **Files:** Boneghoul builder, Blender source/GLB, model-study script and production notes.
- **Verification:** Vulkan/headless BONEGHOUL_COLLAPSE_OK plus prior attack/reaction/model checks. Both feet under 2 mm drift across 48 samples; body drop over 0.5 m, held endpoint and hand clearance. Final evaluated mesh minimum 0.00600004 m above ground. Final collapse render inspected. Final `.tools/044-*` logs have no script/assertion/shader failures; known certificate/headless exit warnings remain.
- **Handoff:** Motion study only; actual combat contact, interruptions, terminal routing and better art/deformation remain. No ragdoll or full collision acceptance. No installer update or AAA acceptance. Locks released.

## 2026-09-19 | Yonatan / Codex — Boneghoul opponent contact study
- Branch: feat/yonatan-sentinel-production.
- Completed: dedicated claw actor with contact-time splitting, interruption cancellation and terminal protection; opponent fixture exposed existing-spacing miss and calibrated a planted close stance.
- Files: scripts/combat/boneghoul_actor.gd (+uid), scripts/combat/boneghoul_contact_test.gd (+uid), scenes/boneghoul_contact_test.tscn, docs/boneghoul-production.md.
- Verification: headless `.tools/045-verified.log`; Vulkan `.tools/045-render.log` and errors log; both contact captures inspected. 0.7679 m original center miss; calibrated surface gap 0.0371 m. Tests include synchronous contact-to-death callback and long-frame contact position. Known certificate/headless-exit warnings remain.
- Handoff: isolated study only, not normal encounter routing or an installer update. Reciprocal weapon clearance, moving targets, full-fight scheduling and art refinement remain. Published 0.20 unchanged; no AAA acceptance. Locks released.

## 2026-09-19 | Yonatan / Codex — Boneghoul mantle and return-strike audit
- Branch: feat/yonatan-sentinel-production.
- Completed: folded/thicker mantle with worn hem and restrained shoulder weights; reciprocal sword reach fixture at calibrated close stance.
- Files: scripts/art/build_boneghoul.py, art_source/characters/boneghoul-production.blend, assets/characters/rigged/boneghoul.glb, scripts/combat/boneghoul_contact_test.gd, docs/boneghoul-production.md.
- Verification: Blender build/import; Vulkan model study and contact fixture, final `.tools/046-study*` and `.tools/046-final*` logs. Rendered idle/attack/guard/recoil/collapse inspected. 36,603 vertices, four surfaces. No final script/assertion/shader errors; known certificate/ObjectDB warnings remain.
- Handoff: guard still aims incoming sword into ribs despite raised claws. Implement pre-contact interception before accepting battle choreography. Model remains isolated/unreleased; no installer or main gameplay change. Locks released.

## 2026-09-19 | Yonatan / Codex — Pre-contact guard and stable weapon placement
- Branch: feat/yonatan-sentinel-production.
- Completed: held pre-contact Boneghoul brace, forearm interception destination, release without animation restart; fixed shared weapon world transform being overwritten by deferred bone attachment movement.
- Files: scripts/combat/boneghoul_actor.gd, scripts/combat/rigged_combatant.gd, scripts/combat/boneghoul_contact_test.gd, docs/boneghoul-production.md.
- Verification: rendered `.tools/047-final-render*` guard sequence; `.tools/047-sentinel*` full Sentinel checks; `.tools/047-finish.log` eight terminal combinations. Timed guard and both Sentinel impact renders inspected. No final script/assertion/shader errors; known certificate/ObjectDB warnings remain.
- Handoff: Boneghoul remains isolated/unreleased. Actual battle scheduling must prepare guards before contact and use the new destination for impact effects. Broader model/material/grip and full encounter quality still below target. Installer unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Opt-in Boneghoul battle integration
- Branch: feat/yonatan-sentinel-production.
- Completed: --boneghoul-3d opt-in routing, close staging, actor contact/recovery protocol, guard anticipation and forearm VFX, finger-position claw impacts, speed-aware collapse fade/handoff.
- Files: scripts/combat/boneghoul_actor.gd, scripts/combat/directed_arena.gd, scripts/combat/combat_controller.gd, scripts/combat/boneghoul_encounter_test.gd (+uid), scenes/boneghoul_encounter_test.tscn, docs/boneghoul-production.md.
- Verification: `.tools/048-verified*` eight rendered modes and 720p captures; `.tools/048-regression.log`, `.tools/048-clock.log`, `.tools/048-playthrough.log`. Final logs scanned with no script/assertion/shader errors. Known certificate/ObjectDB warnings remain. The initial rendered observer failures are rejected evidence and documented.
- Handoff: package a labeled preview/installer and release notes next, then profile and refine art. Opt-in source behavior only; published 0.20 unchanged. No AAA acceptance. Locks released.

## 2026-09-19 | Yonatan / Codex — 0.21 preview release candidate
- Branch: feat/yonatan-sentinel-production.
- Completed: 0.21 version/notes; reusable encounter entry with Boneghoul result title/retry; dedicated Start-menu and portable launchers using an isolated profile; installer and six-file portable payload built.
- Files: VERSION, project.godot, scripts/combat/sentinel_encounter.gd, scenes/boneghoul_encounter.tscn, scripts/release/build_installer.ps1, installer/overkill.iss, docs/encounter-021.md, distribution README files, UPDATE_LOG.md, installer/OverkillSetup-0.21.0.sha256.
- Verification: shipped Overkill.exe with exported PCK passes rendered launcher/result/retry and eight Boneghoul battle modes, exported starter/clock/30-preview/settings suites. Logs `.tools/049-launcher-final*`, `.tools/049-encounter*`, `.tools/049-{starter_relic_test,clock_battle_smoke,ux_017_test,graphics_settings_test}*`. Final logs have no script/assertion/shader errors; known certificate/ObjectDB warnings remain. All six ZIP entries match payload SHA-256. Initial external CLI harness static-class compile error was fixed in the harness; initial launcher log is rejected. Installer compiled successfully; interactive wizard untested.
- Handoff: release candidate verified locally; GitHub publication and main documentation verification follow. Art and frame pacing are not AAA acceptance. Publication locks remain held until remote verification.

## 2026-09-19 | Yonatan / Codex — 0.21 publication verified
- Release: https://github.com/UnKami/Overkill/releases/tag/v0.21.0-test; public prerelease, source 758700f0e211e391c693a77d8112f270bed2a380.
- Assets: OverkillSetup-0.21.0.exe (233604946 bytes, SHA256 f8a392e610b8b1d8ee45936d1b6da4b88bac9d4dd971a8b6702ca0fc25ab92b3); Overkill-0.21.0-Windows.zip (262289627 bytes, SHA256 c9b8f28c60bd1bd2504fef32501e1788eb3142ee5f9e309fdcb93aca50e2dd2c); checksum file. All three GitHub asset digests match local files and return HTTP 200.
- Main distribution PR: https://github.com/UnKami/Overkill/pull/10, merged as 62cab6900306f3c8331eab9fb007a9ca96460729. Homepage, installer README and update log read back from main with 0.21.0. The first post-merge verification helper retained the old 0.20 regex; corrected read-only verification passed without repeating the merge.
- Partner path: repository → Releases → 0.21.0 → Assets → OverkillSetup-0.21.0.exe; Start menu → Play Boneghoul preview. Portable folder → Play Boneghoul.cmd.
- Handoff: release and distribution docs are live. Gameplay remains on feature branch. Model/material refinement, richer animation, performance profiling and full-game quality work continue. Interactive installer wizard remains untested. No AAA acceptance. Publication locks released.

## 2026-09-19 | Yonatan / Codex — Aged-bone surface and integrated cost comparison
- Branch: feat/yonatan-sentinel-production.
- Completed: restrained bone-only wear/roughness/normal detail with subpixel fade; reversible A/B material study; optional Boneghoul material mode in arena profiler. Existing model remains four surfaces.
- Files: assets/shaders/aged_bone.gdshader (+uid), scripts/combat/boneghoul_actor.gd, scripts/combat/boneghoul_material_test.gd (+uid), scenes/boneghoul_material_test.tscn, scripts/combat/arena_profile.gd, docs/boneghoul-production.md.
- Verification: Vulkan/GL close and wide renders; override/restoration structure; contact/interruption regression; sequential integrated idle comparison. Final `.tools/050-final*`, `050-gl*`, `050-structural.log`, `050-contact.log`, `050-arena*`. No final script/assertion/shader errors; known warnings remain. Draws unchanged at 308; approximately 14-15 ms medians / 20 ms p95, variable and not performance acceptance.
- Handoff: anatomy remains simplified; shader is an incremental surface treatment, not AAA finish. GL isolated lighting is darker even at baseline. Published 0.21 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Boneghoul facial structure refinement
- Branch: feat/yonatan-sentinel-production.
- Completed: recessed nasal opening with post-remesh depth checks; open front mouth and dental arch; curved thinner mandible, varied teeth and less exaggerated gape; segmented cervical forms. 39,232 vertices, four surfaces.
- Files: scripts/art/build_boneghoul.py, art_source/characters/boneghoul-production.blend, assets/characters/rigged/boneghoul.glb, docs/boneghoul-production.md.
- Verification: final `.tools/051-build-complete.log`, `051-import-complete.log`, `051-complete*`, `051-contact-complete.log`; rendered skull and animation review, planted collapse, contact/guard/interruption checks. No final Python/script/assertion/shader errors; known warnings remain. Rejected intermediate cutter-normal and wide-gape candidates documented.
- Handoff: stylized anatomy remains below target. Published installer stays 0.21. No AAA or performance acceptance. Locks released.

## 2026-09-19 | Yonatan / Codex — Finger-centered weapon attachment
- Branch: feat/yonatan-sentinel-production.
- Completed: move weapon anchor from dorsal palm into averaged finger curl; cache grip bone indices; add five-pose close-up study with deferred-transform stability assertion.
- Files: scripts/combat/rigged_combatant.gd, scripts/combat/weapon_grip_test.gd, scenes/weapon_grip_test.tscn, docs/sentinel-production.md.
- Verification: rendered Vulkan Sentinel production and Boneghoul contact/guard/interruption regressions; grip close-ups and stability check. Evidence `.tools/052-final*`, `052-sentinel*`, `052-contact*`. Full final logs checked for script/assertion/shader errors; existing certificate warning remains.
- Handoff: wrist orientation and finger posing still need authored animation correction. This is a source checkpoint, not a release or AAA acceptance. Published 0.21 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Authored wrist correction
- Branch: feat/yonatan-sentinel-production.
- Completed: reduced excessive strike/recovery wrist flexion in source animation; rebuilt Executioner and Sentinel production Blender/GLB assets; sampled wrist-angle assertions in the existing grip study.
- Files: scripts/art/build_executioner.py; art_source/characters/{executioner,sentinel}-production.blend; assets/characters/rigged/{executioner,sentinel}.glb; scripts/combat/weapon_grip_test.gd (+uid); docs/sentinel-production.md.
- Verification: both Blender build sentinels; Godot import; rendered five-pose grip, Boneghoul contact/guard/interruption, Sentinel production suites. Final `.tools/053-*` logs clean of script/assertion/shader/Python failures, known certificate warning remains. Player/Sentinel impact wrist bends approximately 17 degrees. Reviewed close-up captures.
- Handoff: finger/thumb wrapping, hand/weapon orientation through the whole swing, richer body motion and broader visual quality remain unfinished. Source checkpoint only; published 0.21 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Continuous weapon roll through overhead poses
- Branch: feat/yonatan-sentinel-production.
- Completed: replaced vertical-pose world-reference switch with actor-relative transverse basis; added 93-sample per actor swing continuity regression.
- Files: scripts/combat/rigged_combatant.gd; scripts/combat/weapon_grip_test.gd; docs/sentinel-production.md.
- Verification: baseline 124.81/132.00-degree adjacent orientation snaps reduced to 21.02/20.28 degrees during the strike. Rendered grip, Boneghoul contact/guard/interruption and Sentinel production checks pass; close-up reviewed. Evidence `.tools/054-*`; no final script/assertion/shader failures, known certificate warning remains.
- Handoff: continuous roll does not solve all finger/weapon alignment, choreography, art or performance needs. Not AAA acceptance. Published installer remains 0.21. Locks released.

## 2026-09-19 | Yonatan / Codex — Forged sword hilt refinement
- Branch: feat/yonatan-sentinel-production.
- Completed: swept tapered crossguard, leather wrap seams, grip collars and steel pommel using existing finishes and batching.
- Files: scripts/combat/forged_armor.gd; scripts/combat/rigged_combatant.gd; docs/sentinel-production.md.
- Verification: corrected initial inward guard winding; final zero-inward-normal audit, rendered grip/continuity and Sentinel production suites pass. Four weapon batches retained. Vulkan windup/impact close-ups reviewed. Evidence `.tools/055-normals-final.log`, `055-final-*`. First unisolated audit launch crashed; isolated rerun passed. Known warnings documented.
- Handoff: refinement remains below overall AAA target; broader anatomy, animation and performance work continues. Published 0.21 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Decision transition stutter reduction
- Branch: feat/yonatan-sentinel-production.
- Completed: prevent redundant shared-theme and font-override writes; real-controller encounter profiler separating decision/resolution/finish with High-Performance-High comparison and JSON export.
- Files: scripts/ui/screen_design.gd; scripts/combat/encounter_profile.gd; scenes/encounter_profile.tscn; docs/sentinel-production.md.
- Verification: six real Sentinel encounters with identical traces/end states. Decision p95 improved from 173/111/165 ms to 25/24/28 ms; large outliers remain. No-op signal check and normal-large-normal exact restoration; rendered graphics/settings regression and 720p large-text capture. `.tools/056-*` logs clean of script/assertion/shader errors, known certificate warning remains.
- Handoff: continue investigating residual transition spikes and broader art/animation. Single muted encounter/device is not full-game performance acceptance. Publish accumulated source/art fixes in the next playtest installer; current public version remains 0.21. Locks released.

## 2026-09-19 | Yonatan / Codex — 0.22 release validation
- Branch: feat/yonatan-sentinel-production. Build source: ef66b17f037f7e1ba9ae5d5eb8b7e8176daf3e09.
- Packaged executable passed starter rules, rendered graphics/settings, grip/continuity and eight Boneghoul terminal-mode checks. Direct preview result/retry passed; 720p retry capture inspected. All six ZIP entries match their build payload SHA-256 hashes.
- Evidence: `.tools/057-export-*`, `057-launcher.log`, `057-profile/Godot/app_userdata/Overkill/release022-retry.png`. No final script/assertion/shader failures; known warnings remain. Inno compiler launch needed escalation after sandbox access denial; approved compilation succeeded. Interactive installer wizard remains untested.
- GitHub publication verification and distribution handoff follow below. This release does not claim AAA completion.

## 2026-09-19 | Yonatan / Codex — 0.22 publication verified
- Release: https://github.com/UnKami/Overkill/releases/tag/v0.22.0-test. Source ef66b17f037f7e1ba9ae5d5eb8b7e8176daf3e09.
- Installer: 233683579 bytes, SHA256 09e38220ff76db408075576e688537700af9c9f6d85f66c1e9b9f0eb71c17c7f. Portable ZIP: 260864789 bytes, SHA256 53948cffed5bda07aedfc2c4d4ec90bc7a3c7a74e37bffd8df0fcfb46d100895. All three GitHub asset digests match local files and downloads return HTTP 200.
- Stronger lossless ZIP compression preserved all six payload hashes. Timed-out uploads were caused by approximately 238-252 KB/s throughput; a longer streaming upload completed. The same draft was retained throughout.
- Distribution PR https://github.com/UnKami/Overkill/pull/11 merged as 8171a0d460b3774c8140a76456d10943a3be3108. Homepage, installer README and update log read back from main with 0.22.0.
- Partner path: repository -> Releases -> 0.22.0 -> Assets -> OverkillSetup-0.22.0.exe; Start menu -> Play Boneghoul preview or Play Sentinel encounter.
- Published package does not include the subsequent thumbnail-filtering pass. Interactive installer wizard remains untested; broader AAA goal unfinished. Publication locks released.

## 2026-09-19 | Yonatan / Codex — Relic thumbnail filtering, unreleased
- Branch: feat/yonatan-sentinel-production.
- Completed: mipmaps for twelve active relic JPEGs plus Blood Siphon's fallback; explicit mipmapped linear filtering in choices and clock sockets.
- Files: scripts/ui/relic_pedestal_view.gd, scripts/ui/clock_socket_view.gd, assets/relics/active/*.jpg.import (12 files), assets/cards/executioner/bloodprice.jpg.import, docs/sentinel-production.md.
- Verification: source Vulkan battle capture at 1280x720 reviewed; reduced noisy edges on starter relic thumbnails. Import and source result/retry fixture pass; `.tools/059-final*` logs clean apart from known certificate warning. Reused fixture sentinel naming does not imply a packaged test for these changes.
- Handoff: published 0.22 remains unchanged. Include this follow-up in the next build. Broader art/animation/performance goal remains unfinished. Locks released.

## 2026-09-19 | Yonatan / Codex — Stone surface response, unreleased
- Branch: feat/yonatan-sentinel-production.
- Completed: use existing stone roughness texture; increase restrained relief and quiet mortar contrast on floor/stairs.
- Files: assets/shaders/arena_stone.gdshader; scripts/combat/directed_arena.gd; docs/sentinel-production.md.
- Verification: Vulkan/GL before-after images reviewed; both material instances, no final shader/script/assertion failures. Old/new/old shader comparison measured roughly 0.17-0.19 ms extra stage GPU cost in the short idle fixture. `.tools/060-profile-final*`, `060-render*`, `060-gl*`. Earlier temporary profiler scope typo rejected; final logs clean except certificate warning.
- Handoff: not a performance guarantee or AAA acceptance. Environment and character work remains. Published 0.22 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Sentinel articulated gauntlets
- Branch: feat/yonatan-sentinel-production.
- Completed: shallow palms spanning real knuckle roots, dark finger pivots, tighter metal plate bevels, closed fingertips and smaller pinky plates. 37,004 vertices / four surfaces.
- Files: scripts/art/build_sentinel.py; art_source/characters/sentinel-production.blend; assets/characters/rigged/sentinel.glb; docs/sentinel-production.md.
- Verification: final Blender build/import; Vulkan close-ups; grip, full-swing continuity and Sentinel production regressions. `.tools/061-*-final*` / `061-final-*` logs checked. Rejected initial palm gap caused by using hand-bone tail instead of knuckle positions. Known certificate warning only in final runtime logs.
- Handoff: thumb/grip animation and broader art remain unfinished; no performance or AAA acceptance. Published 0.22 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Sentinel reaction hand gestures
- Branch: feat/yonatan-sentinel-production.
- Completed: distinct left-hand finger curls for guarding and recoil; recoil finger splay; authored recovery using existing reaction timing. Weapon-hand pose preserved.
- Files: scripts/art/build_sentinel.py; art_source/characters/sentinel-production.blend; assets/characters/rigged/sentinel.glb; docs/sentinel-production.md.
- Verification: Blender build/import, rendered hand close-ups and full-stage recoil inspected; measured gesture separation and return to idle; Sentinel production regression passes normal/fast interruption, contact, reduced motion and framing. Final `.tools/062-*.log` scans clean except known certificate warning.
- Handoff: source-only checkpoint; published 0.22 unchanged. Thumb opposition and broader anatomy, animation, art and performance remain unfinished. No AAA acceptance. Locks released.

## 2026-09-19 | Yonatan / Codex — Rejected Sentinel finish study
- Branch: feat/yonatan-sentinel-production.
- Completed: evaluated two material candidates against explicit baseline at gameplay and torso close-up distance; rejected both and restored original shader.
- Files retained: docs/sentinel-production.md; CHANGELOG_AI.md; ACTIVE_WORK.md lock release. No runtime changes retained.
- Verification: rendered Vulkan material swaps, two materials/two views, no shader/script errors; known certificate warning. Visual rejection overrides passing compilation. Baseline restoration checked by hash and git diff.
- Handoff: prioritize shaped plate forms and authored surface detail; broad oxidation/sheens did not provide sufficient quality gain. Goal unfinished; published 0.22 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Sentinel shoulder forms
- Branch: feat/yonatan-sentinel-production.
- Completed: radial flutes on outer shoulder shells, softened crown transition; lower overlapping plates retain simpler shapes. Final 39,252 vertices / four surfaces, +2,248 vertices.
- Files: scripts/art/build_sentinel.py; assets/characters/rigged/sentinel.glb; art_source/characters/sentinel-production.blend; docs/sentinel-production.md.
- Verification: final Blender/import, close-up/gameplay visual inspection, two full Sentinel production regressions. Investigated unusually slow timing with old/new/old mesh swaps; revised geometry no slower in this noisy sample, no performance acceptance. Details and limitations in production notes.
- Handoff: source checkpoint only; published 0.22 unchanged. Requires next packaged release along with prior unreleased changes. Broader AAA target unfinished. Locks released.

## 2026-09-19 | Yonatan / Codex — GPU contention diagnosis
- Branch: feat/yonatan-sentinel-production.
- Completed: isolated 3D rendering vs UI, investigated shadow cost, identified competing game GPU workloads through Windows counters and process IDs after test exit.
- Files: docs/sentinel-production.md; CHANGELOG_AI.md. No production rendering change retained.
- Verification: three sequential diagnostic fixtures; final logs no script/shader/assertion errors. GPU counters showed SlayTheSpire2 ~69%, separate Overkill ~19%, ChatGPT ~8%; user processes left running.
- Handoff: do not optimize from noisy comparisons or claim a model regression; request user close competing games before fresh profiling. Previous art checks remain visual/functional evidence, not performance acceptance. Locks released; goal remains active.
- User follow-up: Overkill closed, Slay the Spire 2 remains in use; continue art work and defer controlled profiling.

## 2026-09-19 | Yonatan / Codex — Sentinel dished knee armor
- Branch: feat/yonatan-sentinel-production.
- Completed: shaped closed knee cups replace flat panels, with raised center and rim; 39,426 vertices / four surfaces.
- Files: scripts/art/build_sentinel.py; assets/characters/rigged/sentinel.glb; art_source/characters/sentinel-production.blend; docs/sentinel-production.md.
- Verification: Blender/import; idle, guard, hit and kneeling-death close-up visual checks. Final 066 pose fixture passes; initial wrong clip name corrected and failed test process cleaned up. No performance claim under competing GPU workload.
- Handoff: source-only, next release must include outstanding model/material/thumbnail changes. Published 0.22 unchanged; broader art goal active. Locks released.

## 2026-09-19 | Yonatan / Codex — Cloak folds and binding
- Branch: feat/yonatan-sentinel-production.
- Completed: twelve mesh samples per cloak fold, indexed vertices; narrower darker antialiased fabric border for both actors.
- Files: scripts/combat/rigged_combatant.gd; assets/shaders/battle_cloth.gdshader; docs/sentinel-production.md.
- Verification: rendered back views of both actors in Vulkan/OpenGL; Sentinel production regression including reduced motion and framing; 067 logs clean except certificate warning. Per cloak 1,127 vertices / 2,112 triangles. No performance acceptance under competing game workload.
- Handoff: procedural drape still needs richer animation/collision/art; source-only checkpoint, published 0.22 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Cloak movement response
- Branch: feat/yonatan-sentinel-production.
- Completed: capped, smoothed trailing movement at cape hems driven by chest motion; fixed shoulder seam; reset for reduced motion, spawn, teleport and long stalls.
- Files: scripts/combat/rigged_combatant.gd; assets/shaders/battle_cloth.gdshader; docs/sentinel-production.md.
- Verification: 30/60/120 Hz response agreement, rest settling, teleport/reduced-motion reset, actual attack bound; sampled rendered attack views; full Sentinel production regression. 068 logs clean except certificate warning.
- Handoff: procedural secondary motion, not physical cloth collision or AAA acceptance. Source checkpoint only; published 0.22 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — 0.23 package validation, publication pending
- Branch: feat/yonatan-sentinel-production. Frozen source a6fce5560dea25580ee01d03ff63eb3108832451; intended tag v0.23.0-test.
- Built: OverkillSetup-0.23.0.exe (237,658,862 bytes), Overkill-0.23.0-Windows.zip (264,839,595 bytes), checksum file. Release notes docs/encounter-023.md. Installer compiler required approved sandbox escalation; final compile succeeded.
- Verification: packaged runtime/PCK starter rules, Sentinel production, graphics settings, Boneghoul eight ending modes; explicit PCK preview/retry script asserts version 0.23.0. Six ZIP payload hashes match local source files. Final 069 package logs have no script/assertion/shader errors; known certificate warning only. Rendered Sentinel package frame reviewed.
- Installer SHA256: 82e6723f0e4a7c820edc98853ef1802f8df1e9a77eda6144dd78e386b25e37d5. ZIP SHA256: f3f018fd52ea9e78b7e3530a51844387708dcdcc5abe4c7446698afdc7acdb3d.
- Handoff: draft upload launched through .tools/069-upload.ps1; inspect current process/session and release before resuming. Do not duplicate uploads. Must verify three server asset digests, publish, verify HTTP access, then update main distribution docs. Public download remains 0.22 until verified. Publication locks retained. Interactive installer wizard and controlled performance remain unverified.

## 2026-09-19 | Yonatan / Codex — 0.23 published and verified
- Branch: feat/yonatan-sentinel-production. Release https://github.com/UnKami/Overkill/releases/tag/v0.23.0-test is public; tag independently resolves to a6fce5560dea25580ee01d03ff63eb3108832451.
- Verified: three GitHub asset digests equal local SHA256, uploaded states, public HTTP 200 for installer/ZIP/checksum. .tools/069-publish.ps1 and verify023.ps1 completed successfully. Upload session 29654 completed; do not restart.
- Distribution PR https://github.com/UnKami/Overkill/pull/12 merged as b2549ad560b3df54c96a9aedeca51df3941af945. Homepage, installer README and update log read back from main with 0.23.0.
- Partner navigation: Overkill -> Releases -> 0.23.0 -> Assets -> OverkillSetup-0.23.0.exe. After installing: Play Sentinel encounter; Boneghoul preview also available.
- Source branch documentation synchronized. Publication locks released. Interactive installer wizard and controlled performance remain unverified; overall AAA objective remains active.

## 2026-09-19 | Yonatan / Codex — Content-sized relic choices
- Branch: feat/yonatan-sentinel-production.
- Completed: battle description height follows content; starter cards 42 design pixels shorter; bottom-aligned action buttons and live text-size refit. Font sizes and destination labels retained.
- Files: scripts/ui/relic_pedestal_view.gd; docs/sentinel-production.md.
- Verification: 1080p and 720p large-text captures inspected; all-live-relic text fit, replacement/empty/locked states, safe inspection, bounds and ultrawide regression pass. 070 logs clean except known certificate warning.
- Handoff: source-only UI checkpoint, published 0.23 unchanged. Broader UX/art/animation goal remains active. Locks released.

## 2026-09-19 | Yonatan / Codex — Hollow Custodian mask study
- Branch: feat/yonatan-sentinel-production.
- Completed: original mask/neck asset based on existing Act II elite artwork; real vertical visor opening and recessed amber lens, neck collars/pistons; smoothed initial forehead seam. One skinned mesh, four surfaces, 6,216 vertices.
- Files: scripts/art/build_custodian.py; art_source/characters/custodian-study.blend; assets/characters/rigged/custodian-study.glb and import; docs/custodian-production.md.
- Verification: final Blender/import, Vulkan front/quarter image review; one skin/four materials/idle-only export checks. 071 final logs clean except certificate warning.
- Handoff: isolated incomplete study, no encounter wiring or combat acceptance. Next body/armor and authored motion. Published 0.23 unchanged. Locks released; AAA objective active.

## 2026-09-19 | Yonatan / Codex — Hollow Custodian torso study
- Branch: feat/yonatan-sentinel-production.
- Completed: exposed torso rails/spine, three spoked wheels, split breastplate, collar, shoulder shards and pelvic arch. Replaced thick flat plate extrusions with thinner crowned shells; corrected suspension-pin intersections.
- Files: scripts/art/build_custodian.py; art_source/characters/custodian-study.blend; assets/characters/rigged/custodian-study.glb; docs/custodian-production.md.
- Verification: Blender build 24,834 vertices/four surfaces; Godot import and rendered isolated study passed skin/material/idle checks. Front/quarter/rear visual review; final front review after pin correction. 072 final logs clean except known certificate warning.
- Handoff: unfinished bust only, no gameplay integration or new installer. Limbs, attachments, wear and motion still needed. Performance measurements deferred while user plays Slay the Spire 2. Published 0.23 unchanged. Locks released; AAA objective active.

## 2026-09-19 | Yonatan / Codex — Custodian arm study
- Branch: feat/yonatan-sentinel-production.
- Completed: bone-aligned upper arms/forearms, piston rods, open-backed tapered shells, shoulder support brackets, elbow bearings and wrist couplings.
- Files: scripts/art/build_custodian.py; art_source/characters/custodian-study.blend; assets/characters/rigged/custodian-study.glb; docs/custodian-production.md.
- Verification: 073 Blender/import/render logs passed; 30,258 vertices, four surfaces, one skin, idle-only clips. Quarter/rear rest and sampled 0.6-second idle image reviewed; no new runtime/script errors.
- Handoff: study remains incomplete and disconnected from gameplay. Hands/lower body/material wear/authored animation and combat pose clearances remain. No performance or AAA acceptance. Published 0.23 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Custodian mechanical hands
- Branch: feat/yonatan-sentinel-production.
- Completed: open metacarpal frames, thumb saddles, ten articulated three-segment digits, joint bearings/pins and closed claw tips; reduced excessive small-part bevels and corrected submerged pins.
- Files: scripts/art/build_custodian.py; art_source/characters/custodian-study.blend; assets/characters/rigged/custodian-study.glb; docs/custodian-production.md.
- Verification: final 074 Blender/import/render checks passed; 42,374 vertices, one skin/four surfaces. Upper-body idle and both hand close-ups inspected; final pin correction reviewed. No new script/shader/assertion errors.
- Handoff: incomplete source study only. Lower body, worn material detail, Custodian-specific poses and full articulation checks remain. No installer change or AAA acceptance. Locks released.

## 2026-09-19 | Yonatan / Codex — Custodian lower-body study
- Branch: feat/yonatan-sentinel-production.
- Completed: pelvic crossmember, thigh/shin mechanisms, narrow crested shells, hip/knee/ankle bearings and bone-bound pointed feet.
- Files: scripts/art/build_custodian.py; art_source/characters/custodian-study.blend; assets/characters/rigged/custodian-study.glb; docs/custodian-production.md.
- Verification: 075 Blender/import/render checks passed; 49,238 vertices, four surfaces, one skin. Full-body quarter/rear reviewed; valid full-weight bone assignment and finite coordinates for every vertex.
- Handoff: split costume, torso rail attachments, worn surfaces and bespoke animations remain; no combat/ground-contact/performance acceptance. Source study only, published 0.23 unchanged. Locks released; overall AAA goal active.

## 2026-09-19 | Yonatan / Codex — Custodian split skirt study
- Branch: feat/yonatan-sentinel-production.
- Completed: curved split coat shells, folded surfaces/uneven hems, overlapping hip lames with fasteners and support rods, central pointed tabard; pelvis/thigh blended skirt weights.
- Files: scripts/art/build_custodian.py; art_source/characters/custodian-study.blend; assets/characters/rigged/custodian-study.glb; docs/custodian-production.md.
- Verification: final 076 Blender/import/render pass; 55,263 vertices, four surfaces. Quarter/rear fitting-pose review; final rear support correction inspected. Bone-weight sums, bone-name references and finite coordinates pass.
- Handoff: incomplete costume study; no cloth simulation/full-motion/encounter/performance acceptance. Torso attachments, material wear and authored animation remain. Published 0.23 unchanged. Locks released; AAA objective active.

## 2026-09-19 | Yonatan / Codex — Custodian material study and reusable scene
- Branch: feat/yonatan-sentinel-production.
- Completed: geometry-authored bevel masks and stable per-part variation; cool steel/muted bronze material binder using shared metal shader; reusable scenes/custodian_study.tscn with lighting/reflections and inherited idle.
- Fixed: default Blender color export discarded wear masks. Explicit ACTIVE color export now preserves the full face/bevel range in Godot; reduced over-bright exposed-edge color after render inspection.
- Files: scripts/art/build_custodian.py; source Blend/GLB; scripts/combat/custodian_materials.gd and UID; scripts/art/custodian_study_view.gd and UID; scenes/custodian_study.tscn; docs/custodian-production.md.
- Verification: final 077 build/import/render checks passed; actual imported color-array ranges, exactly two metal overrides and playing idle verified. Final scene image reviewed. Geometry unchanged at 55,263 vertices.
- Handoff: run scenes/custodian_study.tscn with F6 in Godot. Study only; no encounter or installer change. Forms, wear, attachments and bespoke animation remain unfinished; performance and AAA acceptance open. Locks released.

## 2026-09-19 | Yonatan / Codex — Custodian authored idle
- Branch: feat/yonatan-sentinel-production.
- Completed: original four-second idle with lowered arms, relaxed claws, subtle chest/head/arm motion and fixed lower-body transforms. Removed inherited knight NLA tracks; study scene loops custodian_idle explicitly.
- Fixed: extra leading export frame by beginning authored keys/NLA at frame zero.
- Files: scripts/art/build_custodian.py; scripts/art/custodian_study_view.gd; source Blend/GLB; docs/custodian-production.md.
- Verification: final 078 build/import/render checks pass. Exact 4-second duration; all-bone loop endpoint continuity; fixed foot transforms across seven samples; 8.88 mm sampled hand travel. Final pose inspected. Separate non-isolated headless diagnostic crashed; isolated rendered checks passed.
- Handoff: no combat animations or encounter wiring yet. Costume clearance, torso connections, richer forms/material detail and controlled performance remain. Published 0.23 unchanged. Locks released; AAA goal active.

## 2026-09-19 | Yonatan / Codex — Custodian guard animation
- Branch: feat/yonatan-sentinel-production.
- Completed: original one-second guard lift/hold/recovery; revised unclear initial raised-hand pose to inward forearms, stronger finger curl and separated hand depths. Study G/R controls and automatic idle return added.
- Files: scripts/art/build_custodian.py; scripts/art/custodian_study_view.gd; source Blend/GLB; docs/custodian-production.md.
- Verification: final 079 build/import/render checks pass; exact duration, idle-matched all-bone endpoints, fixed feet, automatic return and 0.417 m sampled wrist rise. Revised front/intermediate/side views inspected. Prior idle regression passes.
- Handoff: study only, no gameplay integration or installer update. Attack/hit/collapse/contact and exhaustive clearance remain. Larger art/performance/AAA objective remains active. Locks released.

## 2026-09-19 | Yonatan / Codex — Custodian hit reaction
- Branch: feat/yonatan-sentinel-production.
- Completed: authored 0.8-second recoil/counter-motion/recovery with arm and finger response; H preview control, guard interruption, repeated-hit restart and automatic idle return.
- Files: scripts/art/build_custodian.py; scripts/art/custodian_study_view.gd; source Blend/GLB; docs/custodian-production.md.
- Verification: 080 build/import/render checks passed; exact duration, all-bone endpoint continuity, fixed feet, state interruption/restart/return. Head travel 66.9 mm. Primary/side poses inspected; guard and idle regressions passed.
- Handoff: isolated study, no encounter wiring or installer update. Attack/collapse/contact, torso support detail, full clearance and production finish remain open. Performance and AAA acceptance remain unproven. Locks released.

## 2026-09-19 | Yonatan / Codex — Custodian attack study
- Branch: feat/yonatan-sentinel-production.
- Completed: authored 1.2-second wind-up/extension/follow-through/recovery; A preview control and automatic idle return. Hit can interrupt attack in the study.
- Files: scripts/art/build_custodian.py; scripts/art/custodian_study_view.gd; source Blend/GLB; docs/custodian-production.md.
- Verification: 081 build/import/render checks pass; duration, all-bone endpoints, fixed feet, idle return and hit interruption; wrist advances 0.519 m at frame 14/30 s. Wind-up and extension reviewed from primary and side views. Idle/guard/hit regressions pass.
- Handoff: no target contact or damage synchronization yet. Collapse, encounter integration, attachment/clearance refinement and final art remain. Published 0.23 unchanged. Locks released; AAA objective active.

## 2026-09-19 | Yonatan / Codex — Custodian torso rail attachments
- Branch: feat/yonatan-sentinel-production.
- Completed: dedicated hips/chest mounts, baked constrained rail bones and four bearings; tightened this asset's animation import precision after proving importer track reduction caused attachment error.
- Files: scripts/art/build_custodian.py; source Blend/GLB and GLB import settings; docs/custodian-production.md.
- Verification: 082 source/export diagnosis, 844 exported pose samples at 120 Hz, maximum endpoint error 0.450 mm below 1 mm threshold. Attack side render reviewed; all four animation regressions pass. 55,847 vertices/four surfaces.
- Handoff: preserve tracked import settings. Rails now follow their mounts in current clips; collapse/contact/encounter and final visual finish still incomplete. No controlled performance or AAA acceptance. Published 0.23 unchanged. Locks released.

## 2026-09-19 | Yonatan / Codex — Custodian defeated-state study
- Branch: feat/yonatan-sentinel-production.
- Completed: 1.6-second lowered-pelvis mechanical slump with fixed-ankle knee solving; held terminal pose; D preview/R reset; per-instance visor fade and restoration.
- Files: scripts/art/build_custodian.py; scripts/art/custodian_study_view.gd; source Blend/GLB; docs/custodian-production.md.
- Verification: final 083 checks pass: held/reset pose and visor, six deformed-mesh ground samples (minimum 15.97 mm), 0.205 mm sampled foot drift, 0.314 m head drop. Rail audit 1,037 poses/0.450 mm max error. Existing four animation regressions pass. Primary/side renders reviewed.
- Handoff: side view reveals coat/knee deformation still needs refinement. Shutdown is not a ragdoll/floor-impact death. Encounter/contact integration and production art/performance remain open. Published 0.23 unchanged. Locks released; AAA objective active.

## 2026-09-19 | Yonatan / Codex — Custodian coat clearance
- Branch: feat/yonatan-sentinel-production.
- Completed: front-sensitive thigh weighting and gradual hem flare for split armored coat; regenerated source Blend and GLB.
- Files: scripts/art/build_custodian.py; art_source/characters/custodian-study.blend; assets/characters/rigged/custodian-study.glb; docs/custodian-production.md.
- Verification: 49 authored poses show minimum knee-center/coat distance 64.406 mm, approximately 13.8 mm beyond conservative axle/cap envelope. Godot 193-pose collapse audit: floor clearance 15.556 mm, foot drift 0.448 mm, held/reset state and visor pass. Side render inspected; idle/attack regressions pass. No script/shader/assertion/Python errors; known certificate warning remains.
- Handoff: focused knee check only, not exhaustive collision/cross-fade certification. 55,838 vertices/four surfaces. Isolated art study; encounter integration, production finish and controlled performance remain open. Published installer unchanged. Locks released; AAA objective active.

## 2026-09-19 | Yonatan / Codex — Custodian material separation
- Branch: feat/yonatan-sentinel-production.
- Completed: dedicated Custodian metal shader, separate steel/bronze roughness and oxide palettes, broad tarnish and restrained fine texture, irregular bevel exposure. Shared Sentinel shader unchanged.
- Files: assets/shaders/custodian_metal.gdshader and UID; scripts/combat/custodian_materials.gd; docs/custodian-production.md.
- Verification: same-camera close-up comparison and full-body Vulkan renders inspected; first noisy pass reduced. Material/mask study and collapse/visor reset pass. No script/shader/assertion/Python errors; known certificate warning remains.
- Handoff: six texture samples versus three previously; controlled performance and motion texture stability still unverified. Geometry silhouette/detail remains unfinished. Isolated study, published installer unchanged. Locks released; AAA objective active.

## 2026-09-19 | Yonatan / Codex — Custodian armor curvature
- Branch: feat/yonatan-sentinel-production.
- Completed: shallow three-ring armor crowns, perimeter-only angle bevels, smaller embedded chest fasteners; regenerated source Blend and GLB.
- Files: scripts/art/build_custodian.py; source Blend/GLB; docs/custodian-production.md.
- Verification: same-camera close-up and guard/attack renders inspected; material masks and guard/attack state checks pass. Collapse check passed before final pin resize. 54,534 vertices/four surfaces, down 1,304 vertices. Guard fixture shutdown warning cleared after explicit fixture cleanup; final verbose rerun has no leak warning. No script/shader/assertion/Python errors; known certificate warning remains.
- Handoff: repeated inner jewel-like borders removed, but fracture outlines and broader art finish still need work. No encounter or installer change, exhaustive collision/performance acceptance unproven. Locks released; AAA objective active.

## 2026-09-19 | Yonatan / Codex — Custodian encounter preview
- Branch: feat/yonatan-sentinel-production.
- Completed: opt-in Custodian actor with manual attack contact crossing, held guard, hit interruption and held shutdown/private visor fade; arena/controller routing and direct encounter entry using existing Act II elite rules.
- Files: scripts/combat/custodian_actor.gd and UID; directed_arena.gd; combat_controller.gd; scenes/custodian_encounter.tscn; custodian_encounter_test scene/script/UID; docs/custodian-production.md.
- Verification: eight real-controller combinations of win/loss, fast and reduced motion pass; actor interruption/contact/guard/terminal/material isolation checks pass. Initial fixture renderer/shutdown warnings resolved with proper render/teardown waits; final verbose actor run clean except certificate warning. Existing Sentinel production regression passes. Battle choice/impact/terminal captures inspected.
- Handoff: launch source scene with --custodian-3d; normal routing and public installer unchanged. Current staging shares Boneghoul coordinates and contact uses a bone landmark, so exact physical contact/choreography require dedicated calibration. Art, broader enemy coverage and controlled performance still unfinished. Locks released; AAA objective active.
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

## 2026-09-19 | Yonatan / Codex — 0.22 distribution ready for main
- Release: https://github.com/UnKami/Overkill/releases/tag/v0.22.0-test, source ef66b17f037f7e1ba9ae5d5eb8b7e8176daf3e09.
- Verified all three uploaded asset SHA-256 digests against local files and HTTP 200 downloads. Installer 233683579 bytes; portable ZIP 260864789 bytes. Stronger ZIP compression preserves all six payload hashes. Slow transfer required a longer upload timeout; publication succeeded without recreating the draft.
- Partner navigation: repository -> Releases -> 0.22.0 -> Assets -> OverkillSetup-0.22.0.exe; Start menu -> Play Boneghoul preview or Play Sentinel encounter.
- Main changes only distribution docs/checksums. Gameplay remains on the source feature branch. Published 0.22 does not include the later thumbnail filtering experiment. Locks released.

## 2026-09-19 | Yonatan / Codex — 0.23 distribution documentation
- Branch: feat/yonatan-023-downloads; distribution-only update prepared for main.
- Completed: homepage, installer/install folder instructions, update log, release notes and checksums for published v0.23.0-test. Gameplay source remains on feat/yonatan-sentinel-production at a6fce5560dea25580ee01d03ff63eb3108832451.
- Verification: installer, ZIP and checksum assets independently matched against local SHA256 and public HTTP 200. Packaged starter rules, Sentinel, graphics settings, Boneghoul terminal modes and preview/retry pass. All six ZIP files match build payload.
- Handoff: repository -> Releases -> 0.23.0 -> Assets -> OverkillSetup-0.23.0.exe; Start menu -> Play Sentinel encounter / Play Boneghoul preview. Source art and performance remain unfinished. Documentation lock released for reviewed integration.

## 2026-09-23 | Yonatan / Codex — Battle arrival and 0.24 distribution
- **Branch / release:** `feat/yonatan-battle-arrival`; source `8c4ec92152fe284e50ef15b641960bc278c44b09`; prerelease `v0.24.0-test` at https://github.com/UnKami/Overkill/releases/tag/v0.24.0-test.
- **Completed:** cleaned Executioner and collection entry screens; reusable vortex scene transitions; saved first-battle-per-act three-choice offers; dedicated card-upgrade resolution; gated `BATTLE START`, combatant and HP reveal; character-owned HP/Block/status UI; wider arena; reusable attack profiles and complete `REL-03` Heavy Hammer choreography. Campaign navigation now keeps bosses in the illustrated style so the player identity does not change; direct 3D showcases remain intact.
- **Files modified / added:** navigation/run state and map scripts; combat controller/presentation/stages/actors; new transition, offer, upgrade, intro and attack-presentation components/scenes; `assets/vfx/heavy_hammer_strike.png`; structural/render fixtures; `VERSION`, release notes, installer label and distribution documentation.
- **Verification:** `BATTLE_ARRIVAL_OK`, `STARTER_RELIC_OK`, `BATTLE_GUIDANCE_OK`, `PRESENTATION_014_OK`, `CLOCK_SMOKE_OK`, `POLISH_INTEGRATION_OK`, six encounter playthroughs, 30 enemy-intent sweeps, eight finish modes, cinematic/reduced-motion/720p checks, `SENTINEL_ENTRY_OK`, and `UX_017_PREVIEW_OK`. Rendered 1080p, 720p and ultrawide states reviewed. Exported `.pck` independently passes arrival, starter and guidance tests. Six portable files hash-match their build payload.
- **Distribution:** installer 241,106,934 bytes, ZIP 269,851,786 bytes. GitHub reports matching SHA-256 digests (`6b85cc1f...181c12`, `0e90ecff...06ede`) and all three public URLs return HTTP 200. Save-compatible; older saves may receive the new current-act offer once. Installer wizard remains untested; 3D art/performance remain unfinished. Locks released.

## 2026-09-28 | Yonatan / Codex — Five Essences relic lineup and local 0.27 candidate
- **Branch / source:** `feat/yonatan-cinematic-worlds`; `c25c710284a9b70395691bb28a2fc8ce6fb8c48c`.
- **Completed:** expanded the active chronometer lineup from 14 to 26 relics; bound Attack to orange, Block to blue, Buff to purple, Debuff to green, and direct Overkill gain to blood red. Added true dual-effect relics with matching two-color art and UI, real run-currency gain, forecast/HUD feedback, a permanent reliquary legend, color-aware sockets/cards/tooltips, and renamed Blood Siphon to Vital Siphon to protect the blood-red lore rule.
- **Art / files:** created and integrated 26 centered transparent single-object relic renders in the approved painterly-real crystalline magitech direction. Key paths include `assets/relics/active/`, `data/clock_relics/`, `scripts/data/clock_relic_data.gd`, combat/reliquary UI scripts, color-language test scenes, `docs/relic-color-language.md`, `docs/encounter-027.md`, and `VERSION` 0.27.0.
- **Verification:** source checks pass `RELIC_COLOR_LANGUAGE_OK`, `STARTER_RELIC_OK`, `BATTLE_GUIDANCE_OK`, `ENCOUNTER_PLAYTHROUGHS_OK`, `POLISH_INTEGRATION_OK`, and `PRESENTATION_014_OK`. Focused five-essence and dual-binding sheets were rendered and visually reviewed (`RELIC_COLOR_VISUAL_OK`). The exported `Overkill.pck` independently passes relic-color, starter, and guidance tests.
- **Local artifacts:** unsigned installer 277,067,677 bytes, SHA-256 `8e9909a5933c2b83b84bd8e57fc01dd3bd198fde9cb89fa0780298e6802fa1d9`; portable ZIP 305,963,253 bytes, SHA-256 `187dfb5f7c523dfbc53132b50c7a186b270bcb5c6ab4ab1ce7a7232d4026bee2`. All five ZIP entry hashes match the tested build payload.
- **Handoff:** local candidate only. No push, tag, GitHub release, or public-link change was made because repository publication authority was not established in this session. Human full-run balance and interactive installer-wizard testing remain open. Unrelated pre-existing audio/card `.import` edits and older untracked artifacts were preserved and not staged. Locks released.

## 2026-09-29 | Yonatan / Codex — Reliquary interface reconstruction and local 0.28 candidate
- **Branch / source:** `fix/yonatan-relic-ui-polish`; `d87fe7522e882e6a2b0974f68f0e289f193bc366`.
- **Completed:** replaced the stretched debug-style relic columns with compact illuminated artifact frames; rebuilt the Reliquary around the cinematic archive hall with the full Executioner visible; grouped duplicate starter copies into four readable design cards; added five-essence legend, owned counts, inventory/socket summaries, split dual-essence rails, concise numerical effect plaques and matching replacement controls. Relic mechanics and the 12-copy starter inventory are unchanged.
- **Files modified / added:** `scenes/relic_pedestal_view.tscn`; `scripts/ui/relic_pedestal_view.gd`; `scripts/ui/clock_collection_screen.gd`; `scripts/ui/relic_choice_overlay.gd`; `scripts/combat/relic_color_visual_test.gd`; `VERSION`; `project.godot`; `docs/encounter-028.md`; `UPDATE_LOG.md`; `installer/OverkillSetup-0.28.0.sha256`.
- **Verification:** source `RELIC_COLOR_LANGUAGE_OK`, `BATTLE_ARRIVAL_OK`, `BATTLE_GUIDANCE_OK`, `PRESENTATION_014_OK`, and `RELIC_COLOR_VISUAL_OK` pass. The exported `Overkill.pck` independently passes the first four checks, including all 26 relics, normal/large text, 720p and ultrawide layouts; the exported default executable also completes a short headless launch without script or resource errors. The 1080p five-essence, dual-binding and real Reliquary renders were visually inspected. Non-fatal ObjectDB leak warnings remain at test shutdown.
- **Local artifacts:** unsigned installer 277,075,828 bytes, SHA-256 `94fd0bed6309246bee2e1fc8d0e7a865da13f0703f13a3e734a967cf326dd462`; portable ZIP 305,972,073 bytes, SHA-256 `89f0b6f7993c2d4c337b370a3203882726c1a09ce70c16474414a70dab854e38`. Every ZIP entry hash matches the tested build payload.
- **Handoff:** local candidate only. No push, tag, GitHub release or public-link change was made because repository publication authority was not established in this session. Interactive installer-wizard testing and human play review remain open. Unrelated pre-existing audio/card `.import` edits and older untracked artifacts were preserved and not staged. Locks released.

## 2026-09-29 | Yonatan / Codex — Full interface polish and local 0.29 candidate
- **Branch / source:** `fix/yonatan-full-ui-polish`; implementation `02f014d`.
- **Completed:** audited the complete player journey and rebuilt the remaining developer-looking presentation: cinematic map, pause/settings/danger confirmation, tutorial, branded battle log/manual, clocks-only battlefield inspection with numerical full-cycle forecasts, battle relic cards and low centered vitality plates, event/reward/rest/outcome screens, first-battle offer, Reliquary, forge, class selection, act transitions and Excess milestone. Grouped repeated upgrade/tempering designs without changing physical inventory; repaired shared card-frame text margins and authored completion states.
- **Files modified / added:** presentation scripts under `scripts/ui/`; combat overlay integration; `scenes/battle_reference_overlay.tscn` and supporting interface scenes; shared card frame; `assets/ui/`; `VERSION`; `project.godot`; `docs/encounter-029.md`; `UPDATE_LOG.md`.
- **Verification:** source/editor parse plus `BATTLE_ARRIVAL_OK`, `STARTER_RELIC_OK`, `ENEMY_INTENT_READOUT_OK`, `UX_017_PREVIEW_OK`, `PRESENTATION_014_OK`, `RELIC_COLOR_LANGUAGE_OK`, `POLISH_INTEGRATION_OK`, `CINEMATIC_ART_TEST_OK` and `FRONTEND_FLOW_OK`. Exported runtime independently passes arrival, relic-color, presentation, enemy-intent, 54-preview, 30-route cinematic and full frontend-flow suites; its default executable remained responsive in an eight-second launch smoke. Rendered 1080p, large-text 720p and ultrawide states were visually inspected. Existing nonfatal ObjectDB shutdown warnings remain.
- **Local artifacts:** unsigned installer 277,101,700 bytes, SHA-256 `7ff170a71e94867559aee75e44d31136bdbd3e2164886ecd5a0d6883f90c2c8c`; portable ZIP 305,998,018 bytes, SHA-256 `57ab8ee0592a8dce6c92ab70fdfb1ab238af9bb19e7e159721c19f0047773746`. All five ZIP entry hashes match the tested payload.
- **Handoff:** local candidate only. No push, tag, GitHub release or public-link change was made without explicit publication approval. Interactive installer-wizard testing, audio listening and human full-run acceptance remain open. Unrelated pre-existing audio/card `.import` edits and older untracked artifacts were preserved and not staged. Locks released.

## 2026-09-29 | Yonatan / Codex — 0.30.0 battle-clarity playtest published
- **Branch / source / release:** `fix/yonatan-full-ui-polish`; source `cc0fab397663f04c8e67825a597b86c225d73d16`; prerelease [`v0.30.0-test`](https://github.com/UnKami/Overkill/releases/tag/v0.30.0-test).
- **Completed:** aligned regular/elite/boss encounters on one illustrated battle stage with character-free environment art; centered route icons; moved Combat Log/How to Play under Esc and simplified persistent HUD; expanded `I` inspection into two full-cycle clocks and numeric relic-derived output; slowed combat reactions; added relic Upgrade transition; added 26 essence-colored relic objects and Executioner-led loading art.
- **Verification:** eleven self-terminating suites pass from source and exported runtime. Packaged default launch passes. Silent installer installation, installed-game launch and uninstallation pass; ZIP payload entries match. GitHub asset sizes/digests equal local values and all three download URLs return HTTP 200. Source/export logs mention the Windows certificate-store read warning and non-fatal Godot ObjectDB shutdown notices.
- **Distribution:** installer 306,152,783 bytes, SHA-256 `dc6fad00a570dc190315b71c333b0aa41eeeccaa54fcb5144e58bf8ffcf0c131`; portable ZIP 333,244,009 bytes, SHA-256 `60e8080ed29224eff614412168d87fb3ed7b8b932253784bd0324ba27e71c93e`; checksum manifest included. Save-compatible. Unsigned installer; interactive wizard not manually exercised. Low-variety scripted starter setup loses all four boss examples; full-run balance remains unverified. The broader 20–40-background expansion is not part of this build.
- **Files:** battle/UI presentation scripts, clock relic resources, 26 relic object images/import sidecars, loading scene art, cinematic canon docs, release notes, version and distribution docs. Pre-existing unrelated audio/card `.import` edits and older ZIPs remain unstaged and preserved.
- **Next:** documentation-only PR [#15](https://github.com/UnKami/Overkill/pull/15) is open against `main`; gameplay remains on the feature branch. Release links are live now; await review/merge for the default-branch navigation update.

## 2026-09-30 | Yonatan / Codex — 0.34.0 battle rhythm playtest published
- **Branch / source / release:** `fix/yonatan-full-ui-polish`; `3b343d3679ed5748f8aeeb8e8f83344db89acdbd`; prerelease [`v0.34.0-test`](https://github.com/UnKami/Overkill/releases/tag/v0.34.0-test).
- **Completed:** decoupled clock travel timing from slow combat impacts; differentiated regular, multi-hit, high-damage and Executioner hammer animation profiles; added enemy strike/flurry/heavy tells, impact accents, recoil and threat-scaled shake. No combat math, hit counts, intent decisions, turn order or persistence rules changed.
- **Files modified / added:** `scripts/autoload/audio_manager.gd`, `scripts/ui/chronometer_view.gd`, `scripts/combat/attack_presentation.gd`, `scripts/combat/illustrated_actor.gd`, `scripts/combat/illustrated_stage.gd`, `scripts/combat/combat_controller.gd`, `scripts/combat/clock_battle_smoke.gd`, `VERSION`, `docs/encounter-034.md`, `.test-artifacts/verification-034.md`, `installer/OverkillSetup-0.34.0.sha256`.
- **Verification:** `CLOCK_SMOKE_OK`, `PRESENTATION_014_OK`, `CRYSTALLINE_CONSISTENCY_OK` and `BATTLE_ARRIVAL_OK` passed. Installer compilation, isolated current-user install, all five payload hash comparisons, 8-second default-app startup and uninstall passed. Portable ZIP shape and entry sizes matched. GitHub asset sizes and server SHA-256 digests matched local files; each public URL returned HTTP 200. Tests are headless; final visual acceptance/full campaign remain open. Nonfatal certificate-store and ObjectDB/CanvasItem leak warnings remain in runner output.
- **Distribution:** installer 294,061,660 bytes / SHA-256 `564f18bc009521ed2b4a82a9b53e08e3a4a8e02ab59f41678b7c2c56fa96c981`; portable ZIP 321,146,370 bytes / SHA-256 `8416dd2ac00e94659422adbd604dbe47e820060e0eadae204465ce32e8cfda79`; checksum manifest attached. Save-compatible unsigned prerelease.
- **Next / handoff:** gameplay stays on the feature branch. Default README download links and update log are live on `main` through documentation-only PR [#19](https://github.com/UnKami/Overkill/pull/19), verified and merged. Nine pre-existing `.import` sidecars remain unstaged and untouched by this release commit. Active lock released.
## 2026-10-01 | Yonatan / Codex — Essence-matched relic sunbursts
- **Branch / source:** `fix/yonatan-full-ui-polish`; `b45b52d5240f0eaf9ffceaf188864c3db0fc707f`; prerelease [`v0.36.0-test`](https://github.com/UnKami/Overkill/releases/tag/v0.36.0-test).
- **Completed:** Created a cohesive family of 15 transparent crystalline radial sunbursts—five single essence hues and all ten dual-essence combinations—and placed the matching halo behind relic artwork in the shared pedestal used by selection, reward, collection/shop, upgrade and combat views. The relic remains the focal object; no relic data or combat behavior changed.
- **Files modified / added:** `assets/relics/essence_sunbursts/` (15 PNGs and Godot import sidecars); `scripts/ui/relic_pedestal_view.gd`; `scripts/combat/crystalline_visual_test.gd`; `docs/art/crystalline-canon.md`.
- **Verification:** Godot 4.5.1 project import/parse, source and portable `crystalline_visual_test.tscn` runs passed. The fixture asserts all 15 signatures resolve to distinct transparent assets and captures the production reward screen. Silent per-user installer, installed payload fixture and uninstall passed. Final release verification is in `.test-artifacts/verification-036.md`.
- **Distribution:** installer 319,084,700 bytes / SHA-256 `c4c94278b335201077ae183d203906b064d8f29c8f1d0f99016d4df3fe70f5ae`; portable ZIP 346,173,706 bytes / SHA-256 `637d972a3cd837ef027f0e48c4c537a7dbd23715c89a1967ea09002c652c7cee`. GitHub confirmed all three asset sizes/digests and each public URL returned HTTP 200.
- **Next / handoff:** Release is live. Documentation-only PR [#21](https://github.com/UnKami/Overkill/pull/21) updates default-branch download links; it awaits review. Unrelated audio/card `.import` edits and untracked trailer metadata were preserved.

## 2026-10-01 | Yonatan / Codex — Battle and decision-screen clarity pass
- **Branch / source / release:** `fix/yonatan-full-ui-polish`; source commit and `v0.37.0-test` prerelease are recorded after the release is published.
- **Completed:** Removed the deprecated procedural relic spokes so the shared pedestal and replacement choices use the essence-matched transparent sunburst only. The Reliquary now shows every owned copy as its own identified relic. Enlarged illustrated combatants by 20%, moved HP/Block and status values into a readable character-owned lower band, and removed redundant phase banners that obscured combatants during decisions. The replacement screen now gives Keep & Sweep a prominent header action that explicitly says the drawn relic is discarded, with replacement choices using matching sunburst art. Humming Shrine choices explain their benefit/cost inline, and full-clock restrictions are explained inline rather than by an obstructive tooltip. Zenith presentation uses a more transparent offer panel so the altar illustration remains visible. Combat rules and relic effects unchanged.
- **Files modified:** `scripts/combat/clock_battle_presentation.gd`, `scripts/combat/combat_controller.gd`, `scripts/combat/illustrated_stage.gd`, `scripts/combat/crystalline_visual_test.gd`, `scripts/combat/presentation_polish_test.gd`, `scripts/ui/boss_overkill_altar.gd`, `scripts/ui/clock_collection_screen.gd`, `scripts/ui/event_screen.gd`, `scripts/ui/relic_choice_overlay.gd`, `scripts/ui/relic_pedestal_view.gd`.
- **Verification:** Godot 4.5.1 headless `presentation_polish_test.tscn` passes `PRESENTATION_014_OK`; `crystalline_visual_test.tscn` passes `CRYSTALLINE_VISUAL_OK` covering production screens, three maps/transitions, all ten enemies, collection copies, shrine consequences, Zenith transparency and combatant/stat geometry. `git diff --check` passes. Runner still reports the Windows root-certificate-store warning; the visual suite reports a nonfatal ObjectDB shutdown-leak notice.
- **Distribution / handoff:** Windows installer, portable ZIP and remote asset hashes/download URLs are recorded in the version-specific verification report after publication. Existing unrelated audio/card `.import`, trailer, installer-checksum and UID changes were preserved and not included in this release.

## 2026-10-01 | Yonatan / Codex — 0.38.0 altar focus and forge-instance pass
- **Branch / source / release:** `fix/yonatan-full-ui-polish`; the tested source SHA and prerelease tag are recorded after publication.
- **Completed:** Recentered The Overkill Altar and its heading, bank, three offer choices and continue action around a translucent ceremonial panel, exposing more of its shard-altar backdrop. The forge now renders every owned relic copy independently with visible per-design numbering and copy-specific targeting; the upgrade dialog adds a real full-screen dimmer. Battle combatants scale another 20% over 0.37.0; the choice strip is tighter and elevated, retaining relic effects and the bind action while clearing the enlarged silhouettes. No damage, enemy, relic, turn-order or save behavior changed.
- **Files modified:** `scripts/ui/boss_overkill_altar.gd`, `scripts/ui/clock_collection_screen.gd`, `scripts/ui/relic_choice_overlay.gd`, `scripts/ui/relic_pedestal_view.gd`, `scenes/upgrade_preview_dialog.tscn`, `scripts/combat/illustrated_stage.gd`, `scripts/combat/presentation_polish_test.gd`, `scripts/combat/crystalline_visual_test.gd`, `VERSION`, `project.godot`, `docs/encounter-038.md`, `README.md`, `installer/README.md`.
- **Verification:** Godot 4.5.1 `PRESENTATION_014_OK` passed with normal/large text and 720p, 1080p and ultrawide geometry. `CRYSTALLINE_VISUAL_OK` passed for production screens, three maps/transitions, all ten enemy presentations, individual forge copies, upgrade-modal dimming and centered altar layout. Installer and portable-payload evidence is recorded in `.test-artifacts/verification-038.md` after packaging.
- **Next / handoff:** Exact-source Windows installer and five-file portable ZIP are verified and published as `v0.38.0-test`; default-branch download links are supplied through a documentation-only PR. Full human-campaign and final user visual acceptance remain open. Unrelated audio/card `.import`, legacy installer checksum and trailer UID changes remain untouched and unstaged.
