# Overkill 0.18.0 — 3D Character and Combat Sound Pass

On GitHub: **UnKami/Overkill → Releases → 0.18.0 → Assets → OverkillSetup-0.18.0.exe**. Use **Play Sentinel** from the installed shortcuts or portable folder to inspect the 3D encounter in a separate profile.

## Changes

- 3D remains the production target. The Executioner now wears asymmetric layered pauldrons, overlapping waist armor and a distinct breastplate. Plates sharing a bone and finish are combined to limit draw calls.
- Reauthored the rig's sword windup and strike with torso counter-rotation and an active balancing off-hand. Blocks raise the off-hand toward the face. The existing planted-foot solution and contact timing remain intact.
- Separate original sound cues for swings, metal strikes, blocked hits, broken block, lifesteal healing and victory/defeat. Impact cues fire at animation contact. Music briefly ducks for impacts.
- Combat sound voices are capped at eight, release after playback, honor live volume changes, and allocate nothing when muted. Pitch variation uses a private random generator independent of combat randomness.

## Scope

The nine-hour clock, twelve-relic starter, gradual enemy reveals, top choices and outcome previews are unchanged. Saves from 0.14–0.17 remain compatible. Source: `v0.18.0-test`, branch `feat/yonatan-cinematic-encounter`; gameplay awaits review before main integration.

This is an incremental development playtest, not finished AAA production. The 3D encounter is still a vertical slice: other enemies retain illustrated presentation, and distinct enemy models, bespoke topology/textures, broader animation coverage, sound listening review and hardware optimization remain. The installer wizard is not interactively tested. Existing certificate-store/headless shutdown warnings remain.

## Validation

Source and exported tests cover audio mute/allocation, bounded voices, live SFX changes and cleanup; planted feet; normal/fast weapon contact; starter mechanics; preview-versus-resolution comparisons; and cinematic damage timing. Rendered Sentinel checks cover mounted armor, contact, recovery, reduced motion and 720p/1080p framing. Release assets are verified against local SHA-256 and HTTP availability before delivery. These checks do not establish AAA quality or boss balance.
