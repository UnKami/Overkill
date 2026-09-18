# Update log

Every delivered gameplay update appears here with its installer and matching source. Playtest releases remain marked as such until reviewed. Documentation-only updates use the existing installer and do not imply a new game build.

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
