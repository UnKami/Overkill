# Overkill 0.50.0 - Meshy hero lighting playtest

A focused, playable battle preview of the imported Meshy hero in the real Overkill arena.

## Visual changes
- Cyan directional light from the crystalline side and warm rim light from the firelit side.
- Environment reflections for the metal surfaces, lower ambient fill and self-shadowing for clearer form.
- Soft contact shadow beneath the feet, following entrance height and actor visibility.
- Left-clock perch, drop and walk to the battle position; player relic choices follow the entrance.
- Original prepared mesh, material textures and 23-joint skeleton retained.

## Play
Install OverkillSetup-0.50.0.exe, or extract the portable ZIP and run Overkill.exe.
The application is named Overkill Meshy Preview and opens directly into a battle.
Select relics normally. Restart battle preview replays the entrance; victory and defeat offer Play again.
This is a focused battle playtest, not a replacement full-campaign release.

## Saves and source
The independent Overkill-Meshy-Preview save directory leaves existing Overkill saves untouched.
Gameplay code remains on feat/yonatan-meshy-character; the release tag identifies the exact tested commit.
The Meshy asset ZIP contains the runtime GLB and editable Blender source. To reproduce the build,
extract that ZIP into the tagged source checkout before Godot imports the project.
Large generated assets are distributed here rather than stored in Git history.
The prior 0.45.0 full-game installer remains available for rollback and campaign play.

## Verification and limits
Native source and exported Windows checks cover all 29 relic contact/recovery profiles,
actual hand anchors, simultaneous hit handling at both speeds, reduced-motion entrance skip,
guard selection/resolution, a 6-damage strike, death completion and replay rendering.
The final release verification report records resolution checks and installer/payload results.
Combat math, relic balance, enemy logic and clock rules are unchanged.
Attack, hit and death gestures remain interim; individual weapon grips, finger/cloth animation,
and a complete authored combat library are not finished. Enemy art and relic props retain baseline presentation.
The installer is unsigned. A full human campaign and stable-FPS certification are not claimed.

## Published build
Release: https://github.com/UnKami/Overkill/releases/tag/v0.50.0-test
Exact tested source: 0b675b5af4ddd7246637210d52f14af27d62bd65.
All five public download endpoints returned HTTP 200 and GitHub asset sizes/SHA-256 digests matched the local packages. Portable executable and PCK archive entries also matched the tested files.
Source review is draft PR #34; experimental gameplay is not merged into main.
