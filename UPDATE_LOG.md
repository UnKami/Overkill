# Update log

Every delivered gameplay update appears here with its installer and matching source. Playtest releases remain marked as such until reviewed. Documentation-only updates use the existing installer and do not imply a new game build.

## 0.44.0 playtest — 2026-10-04

- Rebuilds the map around the concept diamond: sixteen wheels in seven rows, bottom-to-top travel, physically meshed upward/downward teeth, two interior routes and one route on narrowing outer edges. Every wheel uses one shared drive angle with complementary counterrotation. Selection preserves the phase; timed landings move the Executioner along a smooth arc.
- Adds Overview/Follow framing, contact-facing arrival pointers, circular gear selection and direction/timing shortcuts. Keeps the canonical painted faceplates inside regular native tooth geometry. Same-row clearance avoids triangular external-gear loops.
- **Installer:** [OverkillSetup-0.44.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.44.0-test/OverkillSetup-0.44.0.exe). **Portable ZIP:** [Overkill-0.44.0-Windows.zip](https://github.com/UnKami/Overkill/releases/download/v0.44.0-test/Overkill-0.44.0-Windows.zip). [Release and verification](https://github.com/UnKami/Overkill/releases/tag/v0.44.0-test) · [SHA-256 manifest](https://github.com/UnKami/Overkill/releases/download/v0.44.0-test/OverkillSetup-0.44.0.sha256).
- **Source:** exact commit identified by immutable tag `v0.44.0-test`, branch `feat/yonatan-044-meshed-cog-map`. Download links become live only after the versioned release is published; source and documentation review links will be recorded at delivery.
- **Compatibility:** existing cog saves preserve their current eight-stage encounters and seat IDs, then adopt seven rows in the next act. New runs use seven stages. Legacy route saves remain on their prior map. Shared phase and layout version are additive save fields. Combat/relic values and the 0.43 Blender motion pipeline are unchanged.
- **Verification at source freeze:** 8,636 cog geometry/route/save checks, including 48 tooth-polygon collision samples, passed. Seven-stage production transfer fixture passed 156 headless checks and 173 native checks with 17 inspected captures. Four additional save/map/artifact/UI suites passed, including 153 checkpoint assertions. Native mouse entry reached the prebattle choice and battle transition. Export, screen-preset, installer and public-download verification remain required before delivery; their results appear in the release verification report.
- **Limits:** unsigned playtest; shortened new-run pacing needs human balance review. The transfer fixture marks encounters cleared without fighting; it is not a full campaign. Final human visual approval is not claimed. Selected fixture shutdowns retain a non-fatal ObjectDB notice. Previous releases remain available for rollback.

## 0.43.0 playtest — 2026-10-04

- Refines the Executioner's joints with continuous hand/ankle IK, bounded elbow flexion, planted anticipation, softer joint weights, smaller crouches and gradual recovery. Blender actions now export at 60 Hz. Weapons follow the wrist and thrown relics follow the hand until release.
- Adds connected Blender-authored surface motion to all ten illustrated enemies, with restrained body shifts, head counter-motion, appendage lag, grounded support and gentle floating idle. Repairs shadow lifetime handling during actor replacement. Enemy art remains a weighted surface rather than separately painted limbs.
- **Installer:** [OverkillSetup-0.43.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.43.0-test/OverkillSetup-0.43.0.exe). **Portable ZIP:** [Overkill-0.43.0-Windows.zip](https://github.com/UnKami/Overkill/releases/download/v0.43.0-test/Overkill-0.43.0-Windows.zip). [Release and verification](https://github.com/UnKami/Overkill/releases/tag/v0.43.0-test) · [SHA-256 manifest](https://github.com/UnKami/Overkill/releases/download/v0.43.0-test/OverkillSetup-0.43.0.sha256).
- **Source:** `45367f8991bec1e6f01ac9ca090d2b64a5474431`, immutable tag `v0.43.0-test`, branch `feat/yonatan-043-fluid-motion`, reviewed source PR [#28](https://github.com/UnKami/Overkill/pull/28). The tag identifies the exact tested download; later reviewed branch changes do not replace it.
- **Compatibility:** existing 0.42 saves remain compatible. Damage, Block, healing, turn order, progression and enemy rules are unchanged. Fast and reduced-motion options remain supported; no player-facing autoplay is added.
- **Verification:** eight source and eight packaged suites passed, including all 29 relics, 117 checkpoint checks and 59 forecast comparisons. Anatomical checks passed (44,490); 88 native studio poses and a 44.2-second exported animation movie were reviewed. Four screen presets passed 288 captures and 744 checks, with all contact sheets inspected. Installer installation, all five payload hashes, installed checkpoint regression and uninstall passed. Public downloads and remote asset digests are verified at publication. PNG capture costs are excluded from performance measurements.
- **Limits:** unsigned playtest; final human visual approval and a full human campaign are not claimed. Native measurements under current background load averaged about 35-37 FPS; no controlled performance uplift or locked 60 FPS is claimed. The movie fixture retains a shutdown-only ObjectDB warning. Separate painted enemy limbs remain future art work. Previous releases remain available for rollback.

## 0.42.0 playtest — 2026-10-03

- Integrates both 0.41 source histories while preserving the cogwheel map. Releases the obsolete coordination locks. Adds a Blender-authored Executioner with 18 bones, 16 weighted art parts and 11 character actions, plus authored prop tracks for all 29 relics. Iron Strike summons for 1.5 seconds; Bastion Bell rings for two seconds; Siphon shows actual damage-based healing; multiplier and Block labels travel to the status area.
- Fixes boss-node Continue softlocks, reward rerolls, posthumous Artifact healing and forecast discrepancies for lethal multi-hit attacks, conditional bonuses and enemy Siphon. Repairs tutorial/action overlap, duplicated gain text, cog-map paths, disabled gear plates, route-hint clearance, Forge modal stacking and its completed-state arrow. Uses the visually tested Compatibility renderer by default. Developer launch helper isolates writable save/cache folders and runs full scenes.
- **Installer:** [OverkillSetup-0.42.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.42.0-test/OverkillSetup-0.42.0.exe). **Portable ZIP:** [Overkill-0.42.0-Windows.zip](https://github.com/UnKami/Overkill/releases/download/v0.42.0-test/Overkill-0.42.0-Windows.zip). [Release and exact-source verification](https://github.com/UnKami/Overkill/releases/tag/v0.42.0-test) · [SHA-256 manifest](https://github.com/UnKami/Overkill/releases/download/v0.42.0-test/OverkillSetup-0.42.0.sha256).
- **Source:** exact commit resolved by tag `v0.42.0-test`, integration branch `feat/yonatan-042-rigged-relics`. The source history includes both divergent 0.41 branches; earlier releases are preserved.
- **Compatibility:** 0.41 saves remain readable. An optional checkpoint restores unfinished battles from their entry state, fixed reward offers, paid altars and boss departures; older phase-less boss saves conservatively replay the guardian. Legacy lattice maps now regenerate deterministically, so an older unstable layout can change once. Existing very-old-save health migration and twelve-copy limit still apply. No player-facing autoplay is introduced.
- **Verification:** 20 source/structural suites passed, including six deterministic encounter victories, plus 59 live forecast comparisons and 117 checkpoint assertions. The real resolver completed all 29 relics and tested blocked lifesteal, normal/Fast/reduced-motion recovery. The screen audit captured 72 states at each of 1080p/720p with normal/large text (288 images, 744 automated checks including 456 interaction/state checks); found issues received focused visual repairs. Exported-payload, installer and public asset results are recorded in the version-specific release report.
- **Limits:** unsigned playtest; enemies retain the existing illustrated motion. Twenty-nine prop tracks use shared body-action families. The work is a real skeletal-animation pipeline, not a claim of universal AAA quality or final human approval. Automated encounter policy is not a full human campaign or broad balance validation. Selected fixture shutdowns still emit ObjectDB notices; the fallback-icon CanvasItem leak was fixed and the exported redraw/lifecycle checks passed. Earlier auxiliary startup and bulk-import failures have no proven native cause; subsequent full-project and packaged launches using the recorded renderer/profile setup completed cleanly.

## 0.41.0 playtest — 2026-10-02

- Expanded the run-wide Artifact catalog to eight, added essence-colored activation effects, repaired Bleed/Thorns kill triggers and full-Vitality rest behavior, and refined Clockwright offer alignment and battle transitions. These changes are included in 0.42.
- **Downloads:** [Windows installer](https://github.com/UnKami/Overkill/releases/download/v0.41.0-test/OverkillSetup-0.41.0.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.41.0-test/Overkill-0.41.0-Windows.zip) · [Release and checksum manifest](https://github.com/UnKami/Overkill/releases/tag/v0.41.0-test).
- **Source:** `6e16d250e97162e78fe53d19c60374241a50bdc2`, tag `v0.41.0-test`, branch `feat/yonatan-040-artifacts-block-balance`. Save-compatible with 0.40.
- **Recorded verification:** six source suites, exported pack, five-file ZIP/hash comparison and extracted headless startup passed. The 0.41 handoff records remote asset size/digest checks. Its installer wizard and installed payload were not verified; 0.42 provides the new isolated installation check.
- **Rollback assets:** installer 327,598,650 bytes, SHA-256 `a41984ba7b512cdbc0e466dcb6d330ebc0bd3de3b583e6d7f1f97c495987ba02`; ZIP 354,687,424 bytes, SHA-256 `3c2972916916a114b03683e242f0963bf8090f773d789a58260dde5b57052d76`. Unsigned prerelease; no full human campaign or final visual acceptance was claimed.

## 0.40.0 playtest — 2026-10-02

- The Clockwright now offers three unique, run-wide Artifacts distinct from the 12-relic Chronometer roster. One may be purchased per shop visit; four new illustrated crystalline-magitech objects bring once-per-battle defensive, Overkill, healing and Weak effects. Idle motion/aura, battle trigger accents, reduced-motion support, and inspectable battle icons are included.
- Guard Plate now grants 7 persistent Block (was 5); Reinforced Wall grants 10 (was 8). Save format and the 12-copy limit are unchanged. Existing saves remain compatible; a new run is recommended for balance and art review.
- **Windows installer:** [OverkillSetup-0.40.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.40.0-test/OverkillSetup-0.40.0.exe), 322,803,959 bytes, SHA-256 `02d04fbbb9709a2d838eb6c1b56e626acd8c09cdc285e904991b22c0586fd332`.
- **Portable ZIP:** [Overkill-0.40.0-Windows.zip](https://github.com/UnKami/Overkill/releases/download/v0.40.0-test/Overkill-0.40.0-Windows.zip), 349,892,703 bytes, SHA-256 `d797ca574a1c22a9707ca6e1e1e7c561e59a79e83ffd45fd2804af83bcfdfa36`. [SHA-256 manifest](https://github.com/UnKami/Overkill/releases/download/v0.40.0-test/OverkillSetup-0.40.0.sha256), SHA-256 `f3557b66deb316e34a5837976e80c1715efae5f28203a9ca87d0e425ec8d1589`.
- **Source:** `fdee0ffb4ae217476610822d85fb7137cf21dc3a`, branch `feat/yonatan-040-artifacts-block-balance`, tag `v0.40.0-test`. Gameplay remains isolated from `main`; a docs-only PR updates default-branch download pointers.
- **Verification:** Godot 4.5.1 source suites, exported portable `RUN_ARTIFACTS_OK` integration fixture and startup passed. ZIP contains the five expected files with hashes matching export. Installer compiled; isolated installed-app validation could not pass Windows shell-folder resolution (`SHGetKnownFolderPath`, `0x80070002`). All three GitHub release assets match the local sizes and SHA-256 digests; public download URLs return HTTP 200. Full details: `.test-artifacts/verification-040.md`.
- **Limits:** unsigned playtest; installer wizard/installed app, final user visual acceptance and a human full campaign are not claimed. Automated six-encounter coverage is not proof of broad balance. The root-certificate-store warning and selected non-fatal engine shutdown notices remain.

## 0.39.0 playtest — 2026-10-02

- Multi-hit relics finish their complete attack sequence against the selected target after a lethal first hit, banking all remaining unblocked damage as Overkill. Every damaging relic now visibly travels through the arena; multi-hit attacks show distinct hit beats. Effect scale controls relic art and impact VFX size. Battle stat icons and values are enlarged, and shared screen identities have stronger contrast.
- No enemy behavior, relic effect definitions, turn order, progression or save schema changed. Existing saves remain compatible.
- **Windows installer:** [OverkillSetup-0.39.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.39.0-test/OverkillSetup-0.39.0.exe), 319,094,051 bytes, SHA-256 `9caef9ec520f82da96f73bf0774371ecd9af977ec25dcc9527eb401ce520daee`.
- **Portable ZIP:** [Overkill-0.39.0-Windows.zip](https://github.com/UnKami/Overkill/releases/download/v0.39.0-test/Overkill-0.39.0-Windows.zip), 346,183,390 bytes, SHA-256 `2b96dec36eea6b0724debdc5648848b4ec6750338c6cf1beae8f7fccc3b00943`. [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.39.0-test/OverkillSetup-0.39.0.sha256), SHA-256 `160f26f5263b9092214638ebe331e54eac4b316303b127e538611744ed0bed07`.
- **Source:** `87606327e909aadade1142f16cc4bfbf17ea425c`, tag [`v0.39.0-test`](https://github.com/UnKami/Overkill/releases/tag/v0.39.0-test), branch `fix/yonatan-full-ui-polish`. Save-compatible. Gameplay stays on the feature branch; a documentation-only PR updates main's download links.
- **Verification:** All 14 source suites passed. The portable ZIP contains exactly five expected payload files; extracted portable launch, per-user install, installed-game launch and uninstall returned exit code 0. All three GitHub asset sizes and SHA-256 digests matched local files and each public download URL returned HTTP 200. Full test details: `.test-artifacts/verification-039.md`.
- **Limits:** Installer is unsigned; interactive wizard, full human campaign and final user visual acceptance are not claimed. Test runs emitted the Windows certificate-store warning and selected non-fatal Godot resource/shutdown notices.

## 0.38.0 playtest candidate — 2026-10-01 — NOT PUBLISHED

- Re-centers the Overkill Altar around its relic choices and shows more of the cinematic altar backdrop through a lighter panel. The forge displays every relic instance separately with a visible copy number and per-copy upgrade. Upgrade confirmation now properly dims unrelated content. Combatants are 20% larger than 0.37.0, with the relic-choice strip tightened and raised without removing rules or actions.
- No combat math, relic effects, turn order, map rules, progression values or save schema changed. Existing saves are compatible.
- **Local installer:** `installer/OverkillSetup-0.38.0.exe`, 319,088,830 bytes, SHA-256 `277296e6a9ae20c576c6525ab8be8627356fcf1d0823da8c5109cbe80153e19b`.
- **Local portable ZIP:** `installer/Overkill-0.38.0-Windows.zip`, 346,177,974 bytes, SHA-256 `f20c912893078ade1d6089c5900ca07094c0a0fabda5bf86b607ad0c898908bc`. Local SHA-256 manifest: `installer/OverkillSetup-0.38.0.sha256`.
- **Source:** `4d2eb45443d75192d87d1ee5ebd25c605ed2788e`, branch `fix/yonatan-full-ui-polish`. No `v0.38.0-test` release/tag was published; GitHub release authentication failed before any release write. Do not use a release download URL yet.
- **Verification:** Godot 4.5.1 `PRESENTATION_014_OK` and `CRYSTALLINE_VISUAL_OK`; installer compiled; portable ZIP contains exactly five expected files, all five match the exported payload by SHA-256, and the extracted game launches headlessly with exit code 0. Remote sizes, hashes and HTTP download checks are therefore not verified.
- **Limits / delivery status:** prerelease publication and default-branch download-link PR are blocked pending working GitHub release authentication. Interactive installer wizard/installed app, full human campaign and final user visual acceptance are not claimed. Installer is unsigned; headless runtime emits a non-fatal ObjectDB shutdown notice.

## 0.37.0 playtest — 2026-10-01

- Enlarges battle combatants by 20% and restores readable vitality, Block and status indicators. Relic replacement now uses the dedicated color-matched sunburst artwork, the Reliquary lists individual copies, Keep & Sweep explains its outcome, Humming Shrine constraints are inline, and the Zenith offer background remains visible.
- No combat math, relic effects, turn order, progression or save schema changed; existing saves are compatible. Start a new run for visual review.
- **Installer:** [OverkillSetup-0.37.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.37.0-test/OverkillSetup-0.37.0.exe), 319,086,739 bytes, SHA-256 `7d2613d13c70b2497edde2378e290bb32378267e0f5313aaa31c626b28b93909`.
- **Portable ZIP:** [Overkill-0.37.0-Windows.zip](https://github.com/UnKami/Overkill/releases/download/v0.37.0-test/Overkill-0.37.0-Windows.zip), 346,175,816 bytes, SHA-256 `ad2ddef9d94b238246e4b2bd858818b7fa4c1a460fccab207639e0d7cddea4da`. [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.37.0-test/OverkillSetup-0.37.0.sha256), SHA-256 `8c6f12be422939128591af3e2e16e969d1d548d6afe65366f0bfc56cafdcd0e2`.
- **Source:** `93ede9f5ce801b75049a29e6b0f6590034bd5017`, tag [`v0.37.0-test`](https://github.com/UnKami/Overkill/releases/tag/v0.37.0-test), feature branch `fix/yonatan-full-ui-polish`. All three public asset sizes and hashes were verified; download endpoints returned HTTP 200.
- **Verification and limits:** Godot presentation and crystalline-visual suites passed. Portable ZIP's five files matched the tested payload; extracted and installed games launched headlessly. Silent isolated install/uninstall passed. Installer is unsigned; interactive installer wizard and full human campaign are unverified. Gameplay remains separate from main; documentation-only download PR [#22](https://github.com/UnKami/Overkill/pull/22) is open.

## 0.35.0 playtest — 2026-10-01

- The 12-copy chronometer cap now asks which exact relic to replace when a battle reward is claimed at capacity. Shop and event grants respect the cap; new runs have 500 Vitality, existing saves migrate proportionally, bosses have 100 HP, and combatant stats use compact icon/value chips.
- Act guardians now open **The Overkill Altar**. Banked Overkill can buy one boss-exclusive Zenith relic: The Last Bell (25 OK), The Debt Crown (35 OK), or Zenith Prism (45 OK). A full clock requires a specific replacement; leaving preserves the bank. The three relics use existing combat effects, and ordinary rewards and Clockwright stock exclude them.
- [Watch the cinematic gameplay trailer (44-second MP4)](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/Overkill_Cinematic_Gameplay_Trailer_2026-09-30.mp4). It uses actual Godot-rendered screens and motion, with staged combat/currency values for the edit rather than a continuous human run.
- **Installer:** [OverkillSetup-0.35.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/OverkillSetup-0.35.0.exe), 297,771,633 bytes, SHA-256 `76ce81ce9a8e25c1f192bee7edd03fb6884f72c73ae949ae9bd16dafd9433c9c`.
- **Portable ZIP:** [Overkill-0.35.0-Windows.zip](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/Overkill-0.35.0-Windows.zip), 324,844,930 bytes, SHA-256 `4c4c8689b85d58496bcafc86e65aa0968335911344bdf4823098053a616826f0`. [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/OverkillSetup-0.35.0.sha256).
- **Trailer:** 20,215,872 bytes, SHA-256 `0e290a3efed8370a776125bba266f2ccbcbe850fa89077c5da333b79c141d91b`.
- **Source:** `268873940b5fc96e261d1549686a6e25553bdaf1`, tag [`v0.35.0-test`](https://github.com/UnKami/Overkill/releases/tag/v0.35.0-test), feature branch `feat/yonatan-overkill-altar`. Gameplay remains separate from main's source.
- **Verification:** Godot 4.5.1 source, exported payload, extracted ZIP and installed executable passed `BOSS_ALTAR_OK`; source/export also passed `POLISH_INTEGRATION_OK`. The ZIP's five files and a silent per-user install matched the export by SHA-256, and the test install was removed. The MP4 decoded cleanly at 1920×1080, 30 fps, H.264/AAC; representative frames were reviewed. Remote asset sizes/digests matched and all four public URLs returned HTTP 200.
- **Compatibility and limits:** Existing run saves remain loadable with proportional Vitality migration; new runs are recommended for balance review. The installer is unsigned. The full human campaign, interactive installer wizard, and final visual acceptance remain open; 500 player HP against 100-HP bosses is intentionally generous for this playtest. Restricted Windows runs emit a certificate-store warning and occasional Godot shutdown-leak notices.

## 0.34.0 playtest — 2026-09-30

- Separates crisp clock-hand travel from deliberately weighty combat impacts. Player attacks now distinguish measured strikes, quick multi-hit combos, and heavy blows; the Executioner's hammer keeps its signature slam. Enemy single-hit danger gets a stronger tell and impact while multi-hit intents use a distinct flurry cadence. Defender recoil and accents track the incoming attack profile.
- Mechanics/save compatibility: presentation only; damage values, enemy decisions, hit counts, turn order, clock rules, relic effects, progression and save schema are unchanged. Existing saves remain compatible. No autoplay.
- Verified: Godot 4.5.1 source clock-combat, presentation, crystalline consistency and battle-arrival suites passed. Isolated installer install, five-file hash comparison, 8-second installed-app startup and uninstall passed. Portable ZIP has exactly five entries matching export sizes. Headless tests emit a root certificate-store warning and ObjectDB/CanvasItem shutdown leaks; pixel-level visual acceptance and a human full campaign remain open.
- Installer: 294,061,660 bytes, SHA-256 `564f18bc009521ed2b4a82a9b53e08e3a4a8e02ab59f41678b7c2c56fa96c981`. Portable ZIP: 321,146,370 bytes, SHA-256 `8416dd2ac00e94659422adbd604dbe47e820060e0eadae204465ce32e8cfda79`. [Release and checksum manifest](https://github.com/UnKami/Overkill/releases/tag/v0.34.0-test).
- Installer: [Download OverkillSetup-0.34.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.34.0-test/OverkillSetup-0.34.0.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.34.0-test/Overkill-0.34.0-Windows.zip) · [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.34.0-test/OverkillSetup-0.34.0.sha256). All three remote assets match local sizes/SHA-256 and returned HTTP 200.
- Exact source: `3b343d3679ed5748f8aeeb8e8f83344db89acdbd`, tag `v0.34.0-test`, feature branch `fix/yonatan-full-ui-polish`. [GitHub prerelease](https://github.com/UnKami/Overkill/releases/tag/v0.34.0-test). Gameplay remains on its feature branch; main receives download links through a documentation-only PR.

## 0.33.0 playtest — 2026-09-30

- Aligns the new-journey confirmation to the title content column and removes the menu behind it while open. Map tiers gain substantially more vertical breathing room and scroll when needed. Pre-battle choices regain distinct, context-relevant paintings for relic upgrade, Overkill and Vitality. Relic display drops the hazy radial square treatment for sharper essence-colored light lines behind each floating object.
- Mechanics/save compatibility: no damage, enemy behavior, relic effects, turn order, clock rules, progression or save schema changed. Existing saves remain compatible; a fresh run is recommended for reviewing map routes and offer art.
- Verified: source Godot 4.5.1 map UX, presentation, crystalline consistency, clock smoke and full-screen visual suites passed. The installer was tested in an isolated per-user directory; all five installed files matched the export, the app remained open after an 8-second startup check, then the test install was removed. Portable ZIP has exactly five hash-matched payload files. Pixel-level desktop screenshot acceptance and full human campaign remain open. The exported windowed runtime was not used to claim headless scene-suite passes.
- Installer: 294,058,204 bytes, SHA-256 `a426885dbe96c90dc967aa139d478fd064bef5edbbf44f32ecb40c593c012543`. Portable ZIP: 321,143,084 bytes, SHA-256 `ae3544c8bda397221b1da4cb7facff73277704a0ae08698c432e6812fccb7764`. [Release and checksum manifest](https://github.com/UnKami/Overkill/releases/tag/v0.33.0-test).
- Installer: [Download OverkillSetup-0.33.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.33.0-test/OverkillSetup-0.33.0.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.33.0-test/Overkill-0.33.0-Windows.zip) · [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.33.0-test/OverkillSetup-0.33.0.sha256). All three remote assets match the local byte sizes/SHA-256 values above and return HTTP 200.
- Exact source: `39d28619a9d929fc17cabb15bea311482de373a2`, tag `v0.33.0-test`, feature branch `fix/yonatan-full-ui-polish`. [GitHub prerelease](https://github.com/UnKami/Overkill/releases/tag/v0.33.0-test). Gameplay remains on its feature branch; main receives these download links through the reviewed documentation PR.

## 0.32.0 playtest — 2026-09-30

- Promotes the approved threat-scaled enemy-family hues over the obsidian-and-ivory base; replaces framed relic choices with floating object art and colored light strokes; emphasizes Keep & Sweep; adds restrained actionable-button contours and idle motion; routes reachable map nodes directly; fixes the abandon confirmation and simplifies pre-battle offers; slightly shortens clock-pointer transitions without changing combat-impact pacing.
- Mechanics/save compatibility: no damage, enemy behavior, relic effects, turn order, clock rules, progression or save schema changed. Existing saves remain compatible; a fresh run is recommended for review. No autoplay.
- Verified: Godot map UX, presentation, combat-smoke, crystalline consistency and rendered visual suites pass. The exported game launched from the final extracted portable ZIP with exit code 0. ZIP contains exactly five files whose hashes match the exported payload. GitHub release assets were checked for exact remote size/SHA-256 and public HTTP 200 download URLs.
- Known limits: unsigned prerelease; the Windows installer compiled but its setup wizard and installed app were not verified. Use the portable ZIP if setup fails. Full human campaign and final visual acceptance remain open. The restricted runner emits a Windows certificate-store warning and an ObjectDB shutdown notice during headless launch.
- Installer: 294,056,249 bytes, SHA-256 `03d5aef1395f48d06d004bec3a63090315b06545545c724b08edc6a5b5ce723b`. ZIP: 321,141,315 bytes, SHA-256 `11fd6161feaf49fa7c2e7a336949df98212726637b178a37ee799df523f16e71`. [Release, downloads and checksum manifest](https://github.com/UnKami/Overkill/releases/tag/v0.32.0-test).
- Exact source: `211e7d96862ac6aa19c58ce5a59cffc12181fbe6`, tag `v0.32.0-test`, feature branch `fix/yonatan-full-ui-polish`. Gameplay remains on the feature branch; main contains the reviewed download-documentation update only.

## 0.31.0 playtest — 2026-09-30

- Restores all 26 approved crystalline relic objects and consistent effect colors. Completes ten distinct crystalline enemy silhouettes, retaining the Executioner in every battle. Removes duplicate static fighters hiding actor animation; separates combatants from relic choices and centers HP beneath them.
- Rebuilds map hierarchy around route selection, compact utilities and destination preview before travel. Seven new crystalline symbols are centered on their drawn circles, including the theme minimum-size correction. Adds a dedicated treasure reveal and whole-object relic selection.
- Converts the last pre-battle card-upgrade route to actual clock relics. Connects the new Executioner-led crystalline passage to startup/navigation; restores three matching act-transition paintings and repairs title/continue placement. Preserves approved shop/rest/world art. Removes 36 discarded images from the active asset tree, with recoverable local copies outside Godot resources.
- Mechanics/save compatibility: art-path-only changes to enemy/relic resources; no combat values, AI, clock sequencing, damage, status rules or save schema rebalanced. Pre-battle upgrade now targets one actual clock relic. No autoplay. Existing saves remain compatible; start a new run for review.
- Verification: all 12 suites passed from source and exported executable/PCK. Packaged render fixtures cover production pages, all ten enemies, three maps/transitions, treasure, upgrades, inspection and hammer motion. All 26 relic descriptions at normal/large text; 720p/1080p/ultrawide bounds; 54 forecast comparisons; 30 enemy-intent sweeps. ZIP contains exactly five hash-matched files. Final installer passed isolated current-user installation, five-file hash verification, installed default launch, consistency test and scoped uninstall; existing all-user 0.30.0 payload and registry unchanged. Real saves untouched.
- Installer: [OverkillSetup-0.31.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.31.0-test/OverkillSetup-0.31.0.exe), 296,588,151 bytes, SHA-256 `2968a8c2af0c3a9fad55db096254c9b7fd5281d2a548b5bdd636ad023dca6dd0`. [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.31.0-test/Overkill-0.31.0-Windows.zip), 323,673,946 bytes, SHA-256 `4fc47571216f70dc3e7f8bb73907aef1a20ad971363833954d65d713b9829522`. [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.31.0-test/OverkillSetup-0.31.0.sha256).
- Source: `5c2169b86002a82e6fbccaf391647f8c53d0f045`, tag `v0.31.0-test`, branch `fix/yonatan-full-ui-polish`. [GitHub prerelease](https://github.com/UnKami/Overkill/releases/tag/v0.31.0-test). All three published GitHub asset sizes/digests match local files and public download URLs return HTTP 200. Gameplay remains separate from main; only reviewed download documentation is merged there.
- Known limits: unsigned; full human campaign, final visual acceptance, interactive installer wizard and sustained hardware FPS unverified. Starter-only fixture loses four bosses. Restricted certificate-store notices and some fixture ObjectDB/resource shutdown notices persist; passing suites contain no script/assertion failures. [Player notes](docs/encounter-031.md).
- This build supersedes the historical 0.27–0.30 candidates below. Previous releases are preserved for rollback.

## 0.30.0 playtest — 2026-09-29

- Unifies battle composition around character-free cinematic environments and the same illustrated combatants across regular fights, elites and bosses; recenters route-node art and removes duplicate battle HUD/readouts.
- Moves Combat Log and How to Play into the Esc pause menu; retains `I` for battlefield inspection. Inspection expands both clocks and reports full-cycle attack, Block, status and relic-derived carryover values without exposing hidden enemy intents.
- Slows combat attack, contact, hit, damage-number and Overkill presentation to roughly twice the prior duration. Adds the 1.5-second relic Upgrade transformation before effects commit; card Temper remains a separate card-upgrade system.
- Adds 26 transparent relic objects following the orange Attack, blue Block, purple Buff, green Debuff and blood-red Overkill palette, and a character-led loading scene. The larger request for 20–40 additional cinematic backgrounds remains separate and unfinished.
- Mechanics/save compatibility: no changes intended to damage, enemy AI, clock rules, relic effects, turn order, progression or run rules; existing saves remain compatible. A new run is recommended for visual review.
- Verification: all eleven self-terminating Godot suites pass from source and again from the exported Windows executable/PCK; the default packaged game exits cleanly. A silent current-user installation produced five files matching the exported payload; the installed game launched successfully and its uninstaller removed the test install cleanly. All five portable-ZIP entries match the payload. GitHub's three asset digests and sizes match the local files, and every public asset URL returns HTTP 200. The deterministic low-variety starter fixture loses its four boss examples; full-run balance remains unverified. Headless Windows certificate-store/ObjectDB shutdown notices are recorded in the player notes.
- Installer: `OverkillSetup-0.30.0.exe`, 306,152,783 bytes, SHA-256 `dc6fad00a570dc190315b71c333b0aa41eeeccaa54fcb5144e58bf8ffcf0c131`. Portable ZIP: `Overkill-0.30.0-Windows.zip`, 333,244,009 bytes, SHA-256 `60e8080ed29224eff614412168d87fb3ed7b8b932253784bd0324ba27e71c93e`. GitHub checksum manifest: [OverkillSetup-0.30.0.sha256](https://github.com/UnKami/Overkill/releases/download/v0.30.0-test/OverkillSetup-0.30.0.sha256).
- Source: `cc0fab397663f04c8e67825a597b86c225d73d16`, tag `v0.30.0-test`, branch `fix/yonatan-full-ui-polish`. [GitHub prerelease and downloads](https://github.com/UnKami/Overkill/releases/tag/v0.30.0-test). Save-compatible; start a new run for visual review. Installer is unsigned; the interactive wizard was not manually stepped through.

## 0.29.0 candidate — 2026-09-29 — not yet published

- Completes a screen-by-screen interface reconstruction around the approved painterly-real cyan/amber world, including map, pause, settings, confirmation, tutorial, battle reference, inspection, reward, event, rest, outcome and transition states.
- Enlarges and stabilizes battle relic art, keeps character vitality plates low and centered, and makes battlefield inspection an explicit two-clock full-cycle forecast.
- Consolidates repetitive upgrade/tempering copies by design, fixes shared card-frame text safety, adds authored completion states and preserves the Executioner in cinematic context.
- Keeps all combat, clock, relic, progression and outcome rules unchanged; no autoplay. Source/editor and exported-runtime coverage pass at 1080p, 720p large text and ultrawide, including 54 live-resolution forecasts, 30 enemy-intent sweeps, all 26 relics and all 30 cinematic routes.
- Local installer: 277,101,700 bytes, SHA-256 `7ff170a71e94867559aee75e44d31136bdbd3e2164886ecd5a0d6883f90c2c8c`. Local ZIP: 305,998,018 bytes, SHA-256 `57ab8ee0592a8dce6c92ab70fdfb1ab238af9bb19e7e159721c19f0047773746`. All five ZIP entries match the tested build payload; the packaged executable also passed a responsive launch smoke test.
- Source implementation: `02f014d` on `fix/yonatan-full-ui-polish`. Save-compatible; a new run is recommended for visual review. Public 0.25.0 links remain unchanged until repository publication is explicitly approved.
- Detailed scope: [Full interface polish candidate](https://github.com/UnKami/Overkill/blob/v0.31.0-test/docs/encounter-029.md).

## 0.28.0 candidate — 2026-09-29 — not yet published

- Reconstructs the relic-facing UI after the 0.27 review sheet exposed stretched developer panels, dead space and missing cinematic context.
- Adds compact illuminated artifact cards, split dual-essence rails, concise numerical effect plaques, grouped owned-copy counts and essence-aware replacement controls.
- Rebuilds the Reliquary around the cinematic archive hall and keeps the Executioner visibly present rather than hiding the scene behind a full-width grid.
- Replaces the debug-style relic review sheet with a cinematic five-essence and dual-binding presentation.
- Relic mechanics, the 12-copy starter inventory, clock rules, damage, progression and battle outcomes are unchanged. Source and exported-package relic-language, battle-arrival, guidance and responsive-presentation checks pass; rendered 1080p gallery and real Reliquary inspection pass.
- Local installer: 277,075,828 bytes, SHA-256 `94fd0bed6309246bee2e1fc8d0e7a865da13f0703f13a3e734a967cf326dd462`. Local ZIP: 305,972,073 bytes, SHA-256 `89f0b6f7993c2d4c337b370a3203882726c1a09ce70c16474414a70dab854e38`. All five ZIP entries match the tested build payload.
- Source: `d87fe7522e882e6a2b0974f68f0e289f193bc366` on `fix/yonatan-relic-ui-polish`. Save-compatible; no mechanics changes. Installer is unsigned and its interactive wizard remains untested. Public 0.25.0 links remain unchanged until repository publication is explicitly authorized.
- Detailed scope: [Reliquary interface reconstruction](https://github.com/UnKami/Overkill/blob/v0.31.0-test/docs/encounter-028.md).

## 0.27.0 candidate — 2026-09-28 — not yet published

- Defines five mechanic-bound relic essences: orange Attack, blue Block, purple Buff, green Debuff, and blood-red Overkill.
- Expands the active relic pool from 14 to 26 with newly generated transparent object art; dual-color objects always resolve both represented effects.
- Adds direct Overkill-generating relic mechanics, blood-red combat/HUD feedback, color-aware previews, a reliquary legend, and secondary-color card edges.
- Preserves the 12-copy starter composition and existing relic ids; renames Blood Siphon to Vital Siphon to reserve blood language for Overkill generation.
- Source, rendered, and exported-package validation pass. Local installer: 277,067,677 bytes, SHA-256 `8e9909a5933c2b83b84bd8e57fc01dd3bd198fde9cb89fa0780298e6802fa1d9`. Local ZIP: 305,963,253 bytes, SHA-256 `187dfb5f7c523dfbc53132b50c7a186b270bcb5c6ab4ab1ce7a7232d4026bee2`. Both remain unpublished; the existing 0.25.0 links are still the current public release until explicit repository publication approval is available.
- Source: `c25c710284a9b70395691bb28a2fc8ce6fb8c48c` on `feat/yonatan-cinematic-worlds`. Save-compatible; a new run is recommended for the expanded pool. No autoplay. Human full-run balance and interactive installer-wizard testing remain open.
- Detailed scope: [Five Essences playtest notes](https://github.com/UnKami/Overkill/blob/v0.31.0-test/docs/encounter-027.md) · [relic color language](https://github.com/UnKami/Overkill/blob/v0.31.0-test/docs/relic-color-language.md).

## 0.25.0 playtest — 2026-09-28

**GitHub navigation:** repository → Releases → 0.25.0 → Assets → `OverkillSetup-0.25.0.exe`. Launch **Overkill**; there are no separate 3D prototype shortcuts in this build.

[Release and assets](https://github.com/UnKami/Overkill/releases/tag/v0.25.0-test) · [Detailed changes and limitations](docs/encounter-025.md)

- Unified the playable character, enemies, battlefields, relics, clocks, event imagery and screen presentation around the supplied premium cyan/amber crystalline techno-fantasy direction.
- Retired mismatched flat/cartoon atlases, comic/blurred environments, brass/gothic clock art and the separate rigged 3D boss pipeline. Regular encounters and bosses now use the same approved Executioner identity and illustrated system.
- Replaced all fourteen active relic images and Hollow Coin with centered transparent object renders; enlarged relic art and added object imagery to replacement choices.
- Lowered HP/status panels beneath the combatants; rebuilt battlefield inspection around two enlarged clocks and explicit full-cycle attack, Block and accumulated-stat totals without revealing hidden enemy intents.
- Added contextual approved scenery to the first-battle offer and routed maps, rewards, collection and result screens through the approved screen-art family.
- Packaged starter, non-mutating preview, combat smoke, presentation and encounter suites pass; the default exported game launches without script or resource errors. Rendered 1080p assembly, replacement, inspection and first-battle screens were visually reviewed.
- Installer: 206,705,256 bytes, SHA-256 `7c87607be8b48e1e2e6f5d6c9566a6d86304ea4c6dbb3e26705034c2a88245e0`. ZIP: 233,800,988 bytes, SHA-256 `b49ae34a53f8ddae43282c2cfc7126e5971b9a531580aafef8faef1c6d1bebae`. All three GitHub assets match local hashes and return HTTP 200.
- Save-compatible; a new run is recommended for visual review. No autoplay or balance/mechanics changes. Human boss balance and interactive installer-wizard testing remain open; installer is unsigned.
- Source: `05639415e20682b2d8d152e8cf6df6ba046c3eb2`, tag `v0.25.0-test`, branch `feat/yonatan-tactical-inspection`.

## 0.36.0 playtest — 2026-10-01

- Added 15 transparent crystalline radial sunbursts for relic presentation: five single essence hues and all ten dual-essence combinations.
- The shared relic pedestal automatically places the matching halo behind relics in selection, reward, archive, shop, upgrade and battle views. No mechanics, balance or save data changed.
- **Installer:** [OverkillSetup-0.36.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.36.0-test/OverkillSetup-0.36.0.exe), 319,084,700 bytes, SHA-256 `c4c94278b335201077ae183d203906b064d8f29c8f1d0f99016d4df3fe70f5ae`.
- **Portable ZIP:** [Overkill-0.36.0-Windows.zip](https://github.com/UnKami/Overkill/releases/download/v0.36.0-test/Overkill-0.36.0-Windows.zip), 346,173,706 bytes, SHA-256 `637d972a3cd837ef027f0e48c4c537a7dbd23715c89a1967ea09002c652c7cee`. [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.36.0-test/OverkillSetup-0.36.0.sha256).
- **Source:** exact branch commit and tag are identified in the release notes. Save-compatible.
- **Verification:** Godot 4.5.1 source and portable exported payload pass the crystalline visual fixture. Silent per-user installer, installed payload fixture, and uninstall passed. See [verification-036.md](.test-artifacts/verification-036.md); remote asset hashes/URLs are verified during publication.
- **Known limits:** unsigned Windows installer; automated checks are not a full human campaign or manual installer-wizard acceptance.

## 0.35.0 playtest — 2026-10-01

- The 12-copy chronometer cap now asks which exact relic to replace when a battle reward is claimed at capacity. Shop and event grants respect the cap; new runs have 500 Vitality, existing saves migrate proportionally, bosses have 100 HP, and combatant stats use compact icon/value chips.
- Act guardians now open **The Overkill Altar**. Banked Overkill can buy one boss-exclusive Zenith relic: The Last Bell (25 OK), The Debt Crown (35 OK), or Zenith Prism (45 OK). A full clock requires a specific replacement; leaving preserves the bank. The three relics use existing combat effects, and ordinary rewards and Clockwright stock exclude them.
- [Watch the cinematic gameplay trailer (44-second MP4)](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/Overkill_Cinematic_Gameplay_Trailer_2026-09-30.mp4). It uses actual Godot-rendered screens and motion, with staged combat/currency values for the edit rather than a continuous human run.
- **Installer:** [OverkillSetup-0.35.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/OverkillSetup-0.35.0.exe), 297,771,633 bytes, SHA-256 `76ce81ce9a8e25c1f192bee7edd03fb6884f72c73ae949ae9bd16dafd9433c9c`.
- **Portable ZIP:** [Overkill-0.35.0-Windows.zip](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/Overkill-0.35.0-Windows.zip), 324,844,930 bytes, SHA-256 `4c4c8689b85d58496bcafc86e65aa0968335911344bdf4823098053a616826f0`. [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/OverkillSetup-0.35.0.sha256).
- **Trailer:** 20,215,872 bytes, SHA-256 `0e290a3efed8370a776125bba266f2ccbcbe850fa89077c5da333b79c141d91b`.
- **Source:** `268873940b5fc96e261d1549686a6e25553bdaf1`, tag [`v0.35.0-test`](https://github.com/UnKami/Overkill/releases/tag/v0.35.0-test), feature branch `feat/yonatan-overkill-altar`. Gameplay remains separate from main's source.
- **Verification:** Godot 4.5.1 source, exported payload, extracted ZIP and installed executable passed `BOSS_ALTAR_OK`; source/export also passed `POLISH_INTEGRATION_OK`. The ZIP's five files and a silent per-user install matched the export by SHA-256, and the test install was removed. The MP4 decoded cleanly at 1920×1080, 30 fps, H.264/AAC; representative frames were reviewed. Remote asset sizes/digests matched and all four public URLs returned HTTP 200.
- **Compatibility and limits:** Existing run saves remain loadable with proportional Vitality migration; new runs are recommended for balance review. The installer is unsigned. The full human campaign, interactive installer wizard, and final visual acceptance remain open; 500 player HP against 100-HP bosses is intentionally generous for this playtest. Restricted Windows runs emit a certificate-store warning and occasional Godot shutdown-leak notices.

## 0.34.0 playtest — 2026-09-30

- Separates crisp clock-hand travel from deliberately weighty combat impacts. Player attacks now distinguish measured strikes, quick multi-hit combos, and heavy blows; the Executioner's hammer keeps its signature slam. Enemy single-hit danger gets a stronger tell and impact while multi-hit intents use a distinct flurry cadence. Defender recoil and accents track the incoming attack profile.
- Mechanics/save compatibility: presentation only; damage values, enemy decisions, hit counts, turn order, clock rules, relic effects, progression and save schema are unchanged. Existing saves remain compatible. No autoplay.
- Verified: Godot 4.5.1 source clock-combat, presentation, crystalline consistency and battle-arrival suites passed. Isolated installer install, five-file hash comparison, 8-second installed-app startup and uninstall passed. Portable ZIP has exactly five entries matching export sizes. Headless tests emit a root certificate-store warning and ObjectDB/CanvasItem shutdown leaks; pixel-level visual acceptance and a human full campaign remain open.
- Installer: 294,061,660 bytes, SHA-256 `564f18bc009521ed2b4a82a9b53e08e3a4a8e02ab59f41678b7c2c56fa96c981`. Portable ZIP: 321,146,370 bytes, SHA-256 `8416dd2ac00e94659422adbd604dbe47e820060e0eadae204465ce32e8cfda79`. [Release and checksum manifest](https://github.com/UnKami/Overkill/releases/tag/v0.34.0-test).
- Installer: [Download OverkillSetup-0.34.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.34.0-test/OverkillSetup-0.34.0.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.34.0-test/Overkill-0.34.0-Windows.zip) · [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.34.0-test/OverkillSetup-0.34.0.sha256). All three remote assets match local sizes/SHA-256 and returned HTTP 200.
- Exact source: `3b343d3679ed5748f8aeeb8e8f83344db89acdbd`, tag `v0.34.0-test`, feature branch `fix/yonatan-full-ui-polish`. [GitHub prerelease](https://github.com/UnKami/Overkill/releases/tag/v0.34.0-test). Gameplay remains on its feature branch; main receives download links through a documentation-only PR.

## 0.33.0 playtest — 2026-09-30

- Aligns the new-journey confirmation to the title content column and removes the menu behind it while open. Map tiers gain substantially more vertical breathing room and scroll when needed. Pre-battle choices regain distinct, context-relevant paintings for relic upgrade, Overkill and Vitality. Relic display drops the hazy radial square treatment for sharper essence-colored light lines behind each floating object.
- Mechanics/save compatibility: no damage, enemy behavior, relic effects, turn order, clock rules, progression or save schema changed. Existing saves remain compatible; a fresh run is recommended for reviewing map routes and offer art.
- Verified: source Godot 4.5.1 map UX, presentation, crystalline consistency, clock smoke and full-screen visual suites passed. The installer was tested in an isolated per-user directory; all five installed files matched the export, the app remained open after an 8-second startup check, then the test install was removed. Portable ZIP has exactly five hash-matched payload files. Pixel-level desktop screenshot acceptance and full human campaign remain open. The exported windowed runtime was not used to claim headless scene-suite passes.
- Installer: 294,058,204 bytes, SHA-256 `a426885dbe96c90dc967aa139d478fd064bef5edbbf44f32ecb40c593c012543`. Portable ZIP: 321,143,084 bytes, SHA-256 `ae3544c8bda397221b1da4cb7facff73277704a0ae08698c432e6812fccb7764`. [Release and checksum manifest](https://github.com/UnKami/Overkill/releases/tag/v0.33.0-test).
- Installer: [Download OverkillSetup-0.33.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.33.0-test/OverkillSetup-0.33.0.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.33.0-test/Overkill-0.33.0-Windows.zip) · [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.33.0-test/OverkillSetup-0.33.0.sha256). All three remote assets match the local byte sizes/SHA-256 values above and return HTTP 200.
- Exact source: `39d28619a9d929fc17cabb15bea311482de373a2`, tag `v0.33.0-test`, feature branch `fix/yonatan-full-ui-polish`. [GitHub prerelease](https://github.com/UnKami/Overkill/releases/tag/v0.33.0-test). Gameplay remains on its feature branch; main receives these download links through the reviewed documentation PR.

## 0.32.0 playtest — 2026-09-30

- Promotes the approved threat-scaled enemy-family hues over the obsidian-and-ivory base; replaces framed relic choices with floating object art and colored light strokes; emphasizes Keep & Sweep; adds restrained actionable-button contours and idle motion; routes reachable map nodes directly; fixes the abandon confirmation and simplifies pre-battle offers; slightly shortens clock-pointer transitions without changing combat-impact pacing.
- Mechanics/save compatibility: no damage, enemy behavior, relic effects, turn order, clock rules, progression or save schema changed. Existing saves remain compatible; a fresh run is recommended for review. No autoplay.
- Verified: Godot map UX, presentation, combat-smoke, crystalline consistency and rendered visual suites pass. The exported game launched from the final extracted portable ZIP with exit code 0. ZIP contains exactly five files whose hashes match the exported payload. GitHub release assets were checked for exact remote size/SHA-256 and public HTTP 200 download URLs.
- Known limits: unsigned prerelease; the Windows installer compiled but its setup wizard and installed app were not verified. Use the portable ZIP if setup fails. Full human campaign and final visual acceptance remain open. The restricted runner emits a Windows certificate-store warning and an ObjectDB shutdown notice during headless launch.
- Installer: 294,056,249 bytes, SHA-256 `03d5aef1395f48d06d004bec3a63090315b06545545c724b08edc6a5b5ce723b`. ZIP: 321,141,315 bytes, SHA-256 `11fd6161feaf49fa7c2e7a336949df98212726637b178a37ee799df523f16e71`. [Release, downloads and checksum manifest](https://github.com/UnKami/Overkill/releases/tag/v0.32.0-test).
- Exact source: `211e7d96862ac6aa19c58ce5a59cffc12181fbe6`, tag `v0.32.0-test`, feature branch `fix/yonatan-full-ui-polish`. Gameplay remains on the feature branch; main contains the reviewed download-documentation update only.

## 0.31.0 playtest — 2026-09-30

- Restores all 26 approved crystalline relic objects and consistent effect colors. Completes ten distinct crystalline enemy silhouettes, retaining the Executioner in every battle. Removes duplicate static fighters hiding actor animation; separates combatants from relic choices and centers HP beneath them.
- Rebuilds map hierarchy around route selection, compact utilities and destination preview before travel. Seven new crystalline symbols are centered on their drawn circles, including the theme minimum-size correction. Adds a dedicated treasure reveal and whole-object relic selection.
- Converts the last pre-battle card-upgrade route to actual clock relics. Connects the new Executioner-led crystalline passage to startup/navigation; restores three matching act-transition paintings and repairs title/continue placement. Preserves approved shop/rest/world art. Removes 36 discarded images from the active asset tree, with recoverable local copies outside Godot resources.
- Mechanics/save compatibility: art-path-only changes to enemy/relic resources; no combat values, AI, clock sequencing, damage, status rules or save schema rebalanced. Pre-battle upgrade now targets one actual clock relic. No autoplay. Existing saves remain compatible; start a new run for review.
- Verification: all 12 suites passed from source and exported executable/PCK. Packaged render fixtures cover production pages, all ten enemies, three maps/transitions, treasure, upgrades, inspection and hammer motion. All 26 relic descriptions at normal/large text; 720p/1080p/ultrawide bounds; 54 forecast comparisons; 30 enemy-intent sweeps. ZIP contains exactly five hash-matched files. Final installer passed isolated current-user installation, five-file hash verification, installed default launch, consistency test and scoped uninstall; existing all-user 0.30.0 payload and registry unchanged. Real saves untouched.
- Installer: [OverkillSetup-0.31.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.31.0-test/OverkillSetup-0.31.0.exe), 296,588,151 bytes, SHA-256 `2968a8c2af0c3a9fad55db096254c9b7fd5281d2a548b5bdd636ad023dca6dd0`. [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.31.0-test/Overkill-0.31.0-Windows.zip), 323,673,946 bytes, SHA-256 `4fc47571216f70dc3e7f8bb73907aef1a20ad971363833954d65d713b9829522`. [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.31.0-test/OverkillSetup-0.31.0.sha256).
- Source: `5c2169b86002a82e6fbccaf391647f8c53d0f045`, tag `v0.31.0-test`, branch `fix/yonatan-full-ui-polish`. [GitHub prerelease](https://github.com/UnKami/Overkill/releases/tag/v0.31.0-test). All three published GitHub asset sizes/digests match local files and public download URLs return HTTP 200. Gameplay remains separate from main; only reviewed download documentation is merged there.
- Known limits: unsigned; full human campaign, final visual acceptance, interactive installer wizard and sustained hardware FPS unverified. Starter-only fixture loses four bosses. Restricted certificate-store notices and some fixture ObjectDB/resource shutdown notices persist; passing suites contain no script/assertion failures. [Player notes](docs/encounter-031.md).
- This build supersedes the historical 0.27–0.30 candidates below. Previous releases are preserved for rollback.

## 0.30.0 playtest — 2026-09-29

- Unifies battle composition around character-free cinematic environments and the same illustrated combatants across regular fights, elites and bosses; recenters route-node art and removes duplicate battle HUD/readouts.
- Moves Combat Log and How to Play into the Esc pause menu; retains `I` for battlefield inspection. Inspection expands both clocks and reports full-cycle attack, Block, status and relic-derived carryover values without exposing hidden enemy intents.
- Slows combat attack, contact, hit, damage-number and Overkill presentation to roughly twice the prior duration. Adds the 1.5-second relic Upgrade transformation before effects commit; card Temper remains a separate card-upgrade system.
- Adds 26 transparent relic objects following the orange Attack, blue Block, purple Buff, green Debuff and blood-red Overkill palette, and a character-led loading scene. The larger request for 20–40 additional cinematic backgrounds remains separate and unfinished.
- Mechanics/save compatibility: no changes intended to damage, enemy AI, clock rules, relic effects, turn order, progression or run rules; existing saves remain compatible. A new run is recommended for visual review.
- Verification: all eleven self-terminating Godot suites pass from source and again from the exported Windows executable/PCK; the default packaged game exits cleanly. A silent current-user installation produced five files matching the exported payload; the installed game launched successfully and its uninstaller removed the test install cleanly. All five portable-ZIP entries match the payload. GitHub's three asset digests and sizes match the local files, and every public asset URL returns HTTP 200. The deterministic low-variety starter fixture loses its four boss examples; full-run balance remains unverified. Headless Windows certificate-store/ObjectDB shutdown notices are recorded in the player notes.
- Installer: `OverkillSetup-0.30.0.exe`, 306,152,783 bytes, SHA-256 `dc6fad00a570dc190315b71c333b0aa41eeeccaa54fcb5144e58bf8ffcf0c131`. Portable ZIP: `Overkill-0.30.0-Windows.zip`, 333,244,009 bytes, SHA-256 `60e8080ed29224eff614412168d87fb3ed7b8b932253784bd0324ba27e71c93e`. GitHub checksum manifest: [OverkillSetup-0.30.0.sha256](https://github.com/UnKami/Overkill/releases/download/v0.30.0-test/OverkillSetup-0.30.0.sha256).
- Source: `cc0fab397663f04c8e67825a597b86c225d73d16`, tag `v0.30.0-test`, branch `fix/yonatan-full-ui-polish`. [GitHub prerelease and downloads](https://github.com/UnKami/Overkill/releases/tag/v0.30.0-test). Save-compatible; start a new run for visual review. Installer is unsigned; the interactive wizard was not manually stepped through.

## 0.29.0 candidate — 2026-09-29 — not yet published

- Completes a screen-by-screen interface reconstruction around the approved painterly-real cyan/amber world, including map, pause, settings, confirmation, tutorial, battle reference, inspection, reward, event, rest, outcome and transition states.
- Enlarges and stabilizes battle relic art, keeps character vitality plates low and centered, and makes battlefield inspection an explicit two-clock full-cycle forecast.
- Consolidates repetitive upgrade/tempering copies by design, fixes shared card-frame text safety, adds authored completion states and preserves the Executioner in cinematic context.
- Keeps all combat, clock, relic, progression and outcome rules unchanged; no autoplay. Source/editor and exported-runtime coverage pass at 1080p, 720p large text and ultrawide, including 54 live-resolution forecasts, 30 enemy-intent sweeps, all 26 relics and all 30 cinematic routes.
- Local installer: 277,101,700 bytes, SHA-256 `7ff170a71e94867559aee75e44d31136bdbd3e2164886ecd5a0d6883f90c2c8c`. Local ZIP: 305,998,018 bytes, SHA-256 `57ab8ee0592a8dce6c92ab70fdfb1ab238af9bb19e7e159721c19f0047773746`. All five ZIP entries match the tested build payload; the packaged executable also passed a responsive launch smoke test.
- Source implementation: `02f014d` on `fix/yonatan-full-ui-polish`. Save-compatible; a new run is recommended for visual review. Public 0.25.0 links remain unchanged until repository publication is explicitly approved.
- Detailed scope: [Full interface polish candidate](https://github.com/UnKami/Overkill/blob/v0.31.0-test/docs/encounter-029.md).

## 0.28.0 candidate — 2026-09-29 — not yet published

- Reconstructs the relic-facing UI after the 0.27 review sheet exposed stretched developer panels, dead space and missing cinematic context.
- Adds compact illuminated artifact cards, split dual-essence rails, concise numerical effect plaques, grouped owned-copy counts and essence-aware replacement controls.
- Rebuilds the Reliquary around the cinematic archive hall and keeps the Executioner visibly present rather than hiding the scene behind a full-width grid.
- Replaces the debug-style relic review sheet with a cinematic five-essence and dual-binding presentation.
- Relic mechanics, the 12-copy starter inventory, clock rules, damage, progression and battle outcomes are unchanged. Source and exported-package relic-language, battle-arrival, guidance and responsive-presentation checks pass; rendered 1080p gallery and real Reliquary inspection pass.
- Local installer: 277,075,828 bytes, SHA-256 `94fd0bed6309246bee2e1fc8d0e7a865da13f0703f13a3e734a967cf326dd462`. Local ZIP: 305,972,073 bytes, SHA-256 `89f0b6f7993c2d4c337b370a3203882726c1a09ce70c16474414a70dab854e38`. All five ZIP entries match the tested build payload.
- Source: `d87fe7522e882e6a2b0974f68f0e289f193bc366` on `fix/yonatan-relic-ui-polish`. Save-compatible; no mechanics changes. Installer is unsigned and its interactive wizard remains untested. Public 0.25.0 links remain unchanged until repository publication is explicitly authorized.
- Detailed scope: [Reliquary interface reconstruction](https://github.com/UnKami/Overkill/blob/v0.31.0-test/docs/encounter-028.md).

## 0.27.0 candidate — 2026-09-28 — not yet published

- Defines five mechanic-bound relic essences: orange Attack, blue Block, purple Buff, green Debuff, and blood-red Overkill.
- Expands the active relic pool from 14 to 26 with newly generated transparent object art; dual-color objects always resolve both represented effects.
- Adds direct Overkill-generating relic mechanics, blood-red combat/HUD feedback, color-aware previews, a reliquary legend, and secondary-color card edges.
- Preserves the 12-copy starter composition and existing relic ids; renames Blood Siphon to Vital Siphon to reserve blood language for Overkill generation.
- Source, rendered, and exported-package validation pass. Local installer: 277,067,677 bytes, SHA-256 `8e9909a5933c2b83b84bd8e57fc01dd3bd198fde9cb89fa0780298e6802fa1d9`. Local ZIP: 305,963,253 bytes, SHA-256 `187dfb5f7c523dfbc53132b50c7a186b270bcb5c6ab4ab1ce7a7232d4026bee2`. Both remain unpublished; the existing 0.25.0 links are still the current public release until explicit repository publication approval is available.
- Source: `c25c710284a9b70395691bb28a2fc8ce6fb8c48c` on `feat/yonatan-cinematic-worlds`. Save-compatible; a new run is recommended for the expanded pool. No autoplay. Human full-run balance and interactive installer-wizard testing remain open.
- Detailed scope: [Five Essences playtest notes](https://github.com/UnKami/Overkill/blob/v0.31.0-test/docs/encounter-027.md) · [relic color language](https://github.com/UnKami/Overkill/blob/v0.31.0-test/docs/relic-color-language.md).

## 0.25.0 playtest — 2026-09-28

**GitHub navigation:** repository → Releases → 0.25.0 → Assets → `OverkillSetup-0.25.0.exe`. Launch **Overkill**; there are no separate 3D prototype shortcuts in this build.

[Release and assets](https://github.com/UnKami/Overkill/releases/tag/v0.25.0-test) · [Detailed changes and limitations](docs/encounter-025.md)

- Unified the playable character, enemies, battlefields, relics, clocks, event imagery and screen presentation around the supplied premium cyan/amber crystalline techno-fantasy direction.
- Retired mismatched flat/cartoon atlases, comic/blurred environments, brass/gothic clock art and the separate rigged 3D boss pipeline. Regular encounters and bosses now use the same approved Executioner identity and illustrated system.
- Replaced all fourteen active relic images and Hollow Coin with centered transparent object renders; enlarged relic art and added object imagery to replacement choices.
- Lowered HP/status panels beneath the combatants; rebuilt battlefield inspection around two enlarged clocks and explicit full-cycle attack, Block and accumulated-stat totals without revealing hidden enemy intents.
- Added contextual approved scenery to the first-battle offer and routed maps, rewards, collection and result screens through the approved screen-art family.
- Packaged starter, non-mutating preview, combat smoke, presentation and encounter suites pass; the default exported game launches without script or resource errors. Rendered 1080p assembly, replacement, inspection and first-battle screens were visually reviewed.
- Installer: 206,705,256 bytes, SHA-256 `7c87607be8b48e1e2e6f5d6c9566a6d86304ea4c6dbb3e26705034c2a88245e0`. ZIP: 233,800,988 bytes, SHA-256 `b49ae34a53f8ddae43282c2cfc7126e5971b9a531580aafef8faef1c6d1bebae`. All three GitHub assets match local hashes and return HTTP 200.
- Save-compatible; a new run is recommended for visual review. No autoplay or balance/mechanics changes. Human boss balance and interactive installer-wizard testing remain open; installer is unsigned.
- Source: `05639415e20682b2d8d152e8cf6df6ba046c3eb2`, tag `v0.25.0-test`, branch `feat/yonatan-tactical-inspection`.

## 0.24.0 playtest — 2026-09-23

**GitHub navigation:** repository → Releases → 0.24.0 → Assets → `OverkillSetup-0.24.0.exe`. Launch **Overkill** for the campaign; the separately labeled 3D showcase remains experimental.

[Release and assets](https://github.com/UnKami/Overkill/releases/tag/v0.24.0-test) · [Detailed changes and limitations](docs/encounter-024.md)

- Cleaner Executioner/relic entry screens, reusable vortex navigation, and a three-choice offer before the first battle of each act.
- Dedicated animated card-upgrade resolution, staged `BATTLE START` and sequential player/enemy HP reveals.
- Character-owned HP/Block/status panels, outward clocks and wider central combat space.
- Heavy Hammer now visibly winds up, launches, strikes, triggers hit-stop/recoil, applies its unchanged 14 damage, and recovers through reusable attack profiles.
- Campaign bosses retain the illustrated Executioner instead of silently switching to the unmatched 3D player. Save-compatible; old saves may receive the new per-act offer once. No autoplay.
- Packaged integration/starter/guidance tests pass. Installer (241,106,934 bytes) and ZIP (269,851,786 bytes) match GitHub SHA-256 digests; all public asset URLs return HTTP 200.
- Source: `8c4ec92152fe284e50ef15b641960bc278c44b09`, tag `v0.24.0-test`, branch `feat/yonatan-battle-arrival`.

## 0.23.0 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.23.0 → Assets → `OverkillSetup-0.23.0.exe`. After installing, choose **Play Sentinel encounter** to inspect the armor and cloth refinements. **Play Boneghoul preview** remains available.

[Release and assets](https://github.com/UnKami/Overkill/releases/tag/v0.23.0-test) · [Detailed changes and limitations](docs/encounter-023.md)

- Sentinel: fitted gauntlets and closed fingertips, distinct guard/recoil hand poses, fluted shoulders and shaped knee armor.
- Both fighters: smoother capes, subdued edging and restrained follow-through driven by body movement; reduced-motion support retained.
- Varied stone surface response; cleaner filtering for small relic artwork.
- Rules and balance unchanged. Packaged combat/settings/retry checks pass and all three uploaded asset hashes verified. No performance improvement claim: recent profiling was affected by other running games. Still unfinished art and gameplay, not AAA quality.
- Source: `a6fce5560dea25580ee01d03ff63eb3108832451`, tag `v0.23.0-test`.

## 0.22.0 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.22.0 → Assets → `OverkillSetup-0.22.0.exe`. Choose **Play Boneghoul preview** or **Play Sentinel encounter** after installing. The homepage and installer folder point to this release.

[Release and assets](https://github.com/UnKami/Overkill/releases/tag/v0.22.0-test) · [Detailed changes and limitations](docs/encounter-022.md)

- Refined Boneghoul skull, jaw, neck and bone materials.
- Improved weapon grip placement and wrist poses; removed abrupt overhead weapon roll; refined sword hilt.
- Reduced redundant UI theme work when relic choices appear. Repeated real encounters show substantially lower decision-frame p95; intermittent stalls remain.
- Rules and balance unchanged. This remains unfinished art and gameplay, not AAA acceptance.

## 0.21.0 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.21.0 → Assets → `OverkillSetup-0.21.0.exe`. After installing, open **Play Boneghoul preview**. Portable folder: **Play Boneghoul.cmd**. The homepage and **installer** folder point to this release.

[Release, installer and portable ZIP](https://github.com/UnKami/Overkill/releases/tag/v0.21.0-test)

- Playable 3D Boneghoul preview with authored idle, claw attack, brace, recoil and collapse; separate local preview profile and retry flow.
- Guard anticipation and forearm interception, contact-synchronized damage and effects, full collapse before fade.
- Fixed shared weapon transform conflict affecting visible equipment placement.
- Clock/deck/block/reveal rules and balance unchanged. Source: `v0.21.0-test`, `feat/yonatan-sentinel-production`.
- **Not AAA completion:** model/material quality, animation breadth and frame pacing remain unfinished. [Detailed notes](docs/encounter-021.md).

## 0.20.0 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.20.0 → Assets → `OverkillSetup-0.20.0.exe`. Use **Play Sentinel encounter** after installing. The **installer** folder and homepage point to the release.

[Release, installer and portable ZIP](https://github.com/UnKami/Overkill/releases/tag/v0.20.0-test)

- Dedicated readable enemy-intent panel; includes Siphon and second-hand actions while respecting hidden information.
- Clear clock centers, upcoming-hour pointer consistency and hover connectors that avoid placement text.
- Refined Sentinel helmet and forged braziers with restrained fire; reduced-motion support.
- Reusable batched sparks reduce peak action draws; consistent frame-time improvement is not proven.
- Original Boneghoul art/animation study remains outside normal encounters.
- No balance or save-format changes. AAA art, animation, roster and performance goals remain unfinished. Unsigned installer; interactive wizard untested.
- Source: `v0.20.0-test`, `feat/yonatan-sentinel-production`. [Detailed notes](docs/encounter-020.md).
## 0.19.0 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.19.0 → Assets → `OverkillSetup-0.19.0.exe`. After installing, use **Play Sentinel encounter** to inspect the 3D work directly. The **installer** folder also points to this release.

[Release, installer and portable ZIP](https://github.com/UnKami/Overkill/releases/tag/v0.19.0-test)

- Original skinned Sentinel, layered armor and authored wear/cavity masks; distinct guard, recoil and stagger-to-kneel defeat.
- Cathedral piers/arches, quieter stone/metal, nine floor hours, blade ridge and gravity-aware cloak drape.
- Closer action and inspection camera, clear wider decision framing, terminal defeat guidance and isolated emissive shutdown.
- Saved High/Balanced/Performance 3D resolution settings; full-resolution UI and High default retained.
- No balance, starter, clock or save-format changes. Existing 0.14–0.18 saves remain compatible.
- Verification covers source/packaged mechanics, previews, contact, model/reaction checks, saved settings and finish modes, plus rendered Vulkan/GL review at 1080p/720p and large text. Published assets are checked against SHA-256 and HTTP availability.
- **Known limits:** not AAA completion; enemy roster, richer animation/materials, audio listening and full-run/balance review remain. Intel Vulkan diagnostics still show substantial frame-time spikes. Resolution presets are not performance acceptance. Unsigned installer; interactive wizard untested.
- Source: `v0.19.0-test`, `feat/yonatan-sentinel-production`; gameplay awaits review. [Detailed notes](docs/encounter-019.md).

## 0.18.0 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.18.0 → Assets → `OverkillSetup-0.18.0.exe`. Choose **Play Sentinel** to inspect the 3D encounter directly.

[Release, installer and portable ZIP](https://github.com/UnKami/Overkill/releases/tag/v0.18.0-test)

- Distinct layered Executioner armor with combined meshes; torso-led sword motion and a protective off-hand guard pose.
- Contact-synchronized swing, strike, block, block-break, healing and result cues; brief music ducking, bounded voices and live volume control.
- No balance, deck or save-format changes. Existing 0.14–0.17 saves remain compatible.
- Validation: source/exported mechanics, preview and contact tests; audio lifecycle tests; rendered mounted-armor, recovery and reduced-motion checks. Published assets checked for HTTP availability and SHA-256 match.
- Remaining: full enemy model production, animation variety, sound listening review, performance optimization and human balance testing. This remains a playtest, not AAA completion.
- Source: `v0.18.0-test`, `feat/yonatan-cinematic-encounter`; gameplay awaits review.

## 0.17.0 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.17.0 → Assets → `OverkillSetup-0.17.0.exe`.

[Windows installer](https://github.com/UnKami/Overkill/releases/download/v0.17.0-test/OverkillSetup-0.17.0.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.17.0-test/Overkill-0.17.0-Windows.zip) · [Release notes and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.17.0-test)

- Larger top choices, readable effects, grouped replacement/keep controls, visible inspection and discard instructions. All 14 relics checked in normal/large text, including replacement panels.
- Read-only HP/Block outcome previews, plain-language revealed enemy actions, clearer socket hours, recent combat log and corrected persistent-Block guidance. Hidden actions stay hidden; previews stop at an enemy defeat or unknown action.
- Labeled map destinations, route/encounter inspection and clearer shop prices/keyword explanations. Shared relic text is larger throughout rewards and collection screens.
- Larger grounded illustrated fighters and animation-synchronized contact; less glossy worn armor, restrained lighting and reframed Sentinel arena. Reduced 3D rendering resolution follows smaller windows without reducing UI resolution.
- **Compatibility:** Existing 0.14–0.16 saves remain compatible. No deck, balance or save-format changes.
- **Verification:** 30 preview comparisons against live resolution, starter/combat-flow checks, exported rendered layouts at 1080p/720p large text/ultrawide, all-relic text bounds and normal/fast/reduced-motion contact checks. Illustrated and rigged battles visually inspected. Portable files match the exported payload. All three GitHub assets returned HTTP 200 and matched local SHA-256 hashes.
- **Known limits:** This is not finished AAA production. Character/animation variety, consistent art production, broad hardware performance and human boss-balance testing remain. Long replacement names may ellipsize; full names/effects remain in tooltips. Installer wizard untested; existing certificate-store and headless shutdown warnings remain.
- **Source:** `v0.17.0-test`, branch `feat/yonatan-readable-cinematic`; gameplay awaits review.

## 0.16.0 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.16.0 → Assets → `OverkillSetup-0.16.0.exe`.

[Windows installer](https://github.com/UnKami/Overkill/releases/download/v0.16.0-test/OverkillSetup-0.16.0.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.16.0-test/Overkill-0.16.0-Windows.zip) · [Release notes and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.16.0-test)

- Distinct layered Sentinel armor and clockwork seal, broader Executioner blade, refined stances and a more grounded arena with steps/braziers.
- Cinematic damage waits for the strike pose, fixing early hits caused by a fixed timer. Contact effects use the same target point as the weapon.
- Batched architecture, fewer shadow passes, cheaper metal shading and cached static clock engraving. Measured draw calls fell from about 680 to 455; frame-time consistency still needs work.
- **Compatibility:** Existing 0.14/0.15 saves remain compatible. No balance or deck changes.
- **Verification:** Exported attachment/motion, cinematic combat, starter, clock-combat and presentation checks passed. Contact checks cover normal/fast and reduced-motion combinations. Portable files match the tested export; all GitHub assets returned HTTP 200 and matched local SHA-256 hashes.
- **Known limits:** Visual production remains in progress; illustrated encounters are unchanged. Boss balance, animation variety and frame-time consistency remain open. Installer wizard untested; existing certificate-store/shutdown warnings remain.
- **Source:** `v0.16.0-test`, branch `feat/yonatan-sentinel-silhouette`; gameplay awaits review.

## 0.15.0 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.15.0 → Assets → `OverkillSetup-0.15.0.exe`.

[Windows installer](https://github.com/UnKami/Overkill/releases/download/v0.15.0-test/OverkillSetup-0.15.0.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.15.0-test/Overkill-0.15.0-Windows.zip) · [Release notes and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.15.0-test)

- Darker lighting, worn metal, softer ground contact and a detailed beveled hammer in the rigged Sentinel encounter. Use **Play Sentinel** for direct access.
- Explicit HP, Block, blocked damage and healing labels throughout combat; named relic activation notices and less overlapping effects in the 3D encounter.
- **Compatibility:** No save-format, starter deck or balance changes from 0.14.1.
- **Verification:** Exported starter, clock-combat smoke, cinematic feedback and rendered presentation checks passed; inspected 1080p imagery, with 720p and ultrawide layout checks. ZIP entries match the tested payload. All three published GitHub assets returned HTTP 200 and matched local SHA-256 hashes.
- **Known limits:** Visual development playtest, not completed AAA production. Other encounters retain illustrated art. Boss balance and frame-time consistency need further work. Unsigned installer; interactive wizard not tested. Existing certificate-store/headless shutdown warnings remain.
- **Source:** `v0.15.0-test`, branch `feat/yonatan-cinematic-combat-finish`; gameplay awaits review.

## 0.14.1 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.14.1 → Assets → `OverkillSetup-0.14.1.exe`.

[Windows installer](https://github.com/UnKami/Overkill/releases/download/v0.14.1-test/OverkillSetup-0.14.1.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.14.1-test/Overkill-0.14.1-Windows.zip) · [Release notes and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.14.1-test)

- Compact relic choices at the top; removed the shared background and instruction/header strip.
- Available choices pulse gently; reduced-motion mode uses a steady highlight.
- Replacement choices follow the same compact layout. Clocks, health and central battle stay visible.
- **Compatibility:** No combat or save-format changes from 0.14.0.
- **Verification:** Rendered 1080p, large-text 720p and ultrawide layout checks; exported presentation and interaction tests passed. All GitHub assets returned HTTP 200 and matched local SHA-256 digests.
- **Known limits:** Boss balance still needs playtesting. Unsigned installer; installation wizard not tested. Existing nonfatal certificate-store/headless shutdown warnings remain.
- **Source:** `v0.14.1-test`, branch `feat/yonatan-top-relic-choices`; gameplay awaits review.

## 0.14.0 playtest — 2026-09-19

**GitHub navigation:** repository → Releases → 0.14.0 → Assets → `OverkillSetup-0.14.0.exe`.

[Windows installer](https://github.com/UnKami/Overkill/releases/download/v0.14.0-test/OverkillSetup-0.14.0.exe) · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.14.0-test/Overkill-0.14.0-Windows.zip) · [Release notes and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.14.0-test)

- Nine-hour clocks; three repeating three-hour sectors after assembly.
- Starter deck: 5 attacks (6 damage), 5 guards (5 persistent Block), 1 lifesteal (3 damage), 1 Overdrive (4 damage, next attack ×2). Three reserves remain.
- Enemy actions reveal before placement and stay visible; reverse and twin-hand rules adapted to nine hours.
- Horizontal floating choices, explicit commit buttons, pulsing destinations, battlefield inspection, larger readable cards, and cleaner reward/shop/map screens.
- **Save compatibility:** Start a new run for the deck. Existing inventories remain; battles use nine hours.
- **Verification:** Combat/inventory and frontend integration checks; rendered 1080p, large-text 720p and ultrawide layout checks. Packaged starter, combat smoke and inventory tests passed; exported game launched with Intel OpenGL. All three GitHub assets returned HTTP 200 and server SHA-256 digests matched local files.
- **Known limits:** Basic scripted policy wins the normal and elite Act I fixtures but loses bosses. Human balance testing remains. Unsigned installer; interactive wizard not tested. Certificate-store and headless shutdown warnings remain. This is a playtest, not final AAA production.
- **Source:** `v0.14.0-test`, branch `feat/yonatan-014-presentation-polish`; gameplay awaits merge review.

## 0.13.0 playtest — 2026-09-18

**[Windows installer](https://github.com/UnKami/Overkill/releases/download/v0.13.0-test/OverkillSetup-0.13.0.exe)** · [Portable ZIP](https://github.com/UnKami/Overkill/releases/download/v0.13.0-test/Overkill-0.13.0-Windows.zip) · [Release and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.13.0-test)

- Starter deck: 6 attacks (6 damage), 6 blocks (6 Block), 2 Twin Blades (4 damage twice), 2 Reinforced Walls (8 Block).
- Unused Block persists until absorbed or battle ends.
- Floating selection/replacement overlays replace the bottom bar. Pulsing numbered clock destinations and placement animation clarify each choice.
- **Save compatibility:** Start a new run for the new deck. Existing saved inventories are preserved.
- **Verification:** Packaged starter, combat smoke and inventory integration tests passed. Exported game launched using Intel OpenGL. GitHub downloads returned HTTP 200 and asset hashes matched the local builds. Installer compiled; installer wizard itself was not tested.
- **Known issues:** Scripted basic policy loses the first boss and can stall in later boss fixtures without varied reward relics. Balance needs playtesting. Windows certificate-store and headless shutdown warnings remain.
- **Source:** [`07e1ce9`](https://github.com/UnKami/Overkill/commit/07e1ce9512ba8de0fa0c5e9e42e3ab3e8a06a8b7), tag `v0.13.0-test`, branch `feat/yonatan-starter-relic-overlays`; gameplay changes not merged into main.

## Distribution documentation — 2026-09-18

Added prominent downloads on the repository homepage and inside `installer/`, this shared update log, and mandatory release handoff instructions for future assistants. Same 0.13.0 game binaries; no gameplay change.
