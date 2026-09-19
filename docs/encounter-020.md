# Overkill 0.20.0 — Battle Clarity Playtest

On GitHub: **UnKami/Overkill → Releases → 0.20.0 → Assets → OverkillSetup-0.20.0.exe**. The homepage and **installer** folder also point to this release. After installing, use **Play Sentinel encounter** from the Start menu. For the portable ZIP, extract everything and run **Play Sentinel.cmd**. This encounter uses a separate profile; **Overkill.exe** opens the regular game.

## Changes since 0.19

- Enemy actions have a dedicated upper-right readout with normal/large text support. The clock keeps a short ordered-hour cue. Siphon's Overkill drain and scheduled second-hand actions are now explained, without exposing unrevealed actions.
- Decision pointers sit outside relic icons and leave clock-center text clear. Pointers agree with the upcoming hour; the full player hand returns during resolution. Hover connectors avoid crossing placement text.
- Sentinel helmet has an enclosed crown, clearer brow/cheek structure and articulated neck protection. Forged brazier baskets, coals and restrained animated fire replace the old glowing discs. Reduced motion freezes fire variation.
- Impact sparks reuse one instanced mesh, retaining mixed hit/block colors and overlapping effects. Local action diagnostics reduced peak draws from 321 to 298. This did not establish a consistent frame-time improvement.
- An original Boneghoul model and claw study are available in source for ongoing art development. They are **not integrated into normal encounters** and are not finished production art.

## Scope and limits

The nine-hour clock, twelve-relic starter, persistent Block, gradual enemy reveals and save format are unchanged. No balance changes are included. Source tag: **v0.20.0-test**, branch **feat/yonatan-sentinel-production**. Gameplay remains on the feature branch pending review; main's distribution documentation points to the released playtest.

**This is not AAA completion.** Character anatomy/materials, animation breadth, enemy roster, environment finish, audio listening review and full-run balance testing remain incomplete. The 3D Sentinel encounter is still a developing vertical slice.

Frame pacing is not accepted: fresh short Intel Vulkan presentation workloads showed roughly 12–14 ms medians and 18–19 ms slow frames, while older samples were substantially worse. These are not full-fight or broad-hardware guarantees. High/Balanced/Performance settings remain available. The installer is unsigned; its interactive wizard has not been manually tested. Known Windows certificate-store and headless exit warnings remain.

## Validation and partner sync

Release validation covers exported starter/clock rules, preview parity, contact, saved graphics settings, battle finish behavior and enemy-intent layout. Roster fixtures cover ten enemy types across three sectors in normal and large text; those fixtures do not represent finished 3D versions of every enemy. Rendered review checks the real exported game presentation.

The release includes the Windows installer, portable ZIP and SHA-256 checksums. Download availability and GitHub asset digests are checked after publication. Development evidence and limitations are recorded in `CHANGELOG_AI.md` and `docs/sentinel-production.md`.
