> Historical 0.46.1 rig evidence. The user rejected its motion polish; see [the 0.46.2 motion study](motion-polish-0462.md) for the current local revision.

# Character and relic rig review — 0.46.1 local candidate

2026-10-06. Publication is held at the user's request for visual review.
The prior local 0.46.0 installer does not contain this rig revision.

## Problems found and corrected

- The active arm used the IK bend that lifted its elbow above the casting arm.
  Its resting elbow joint and bend direction now follow the painted anatomy.
- Upper arms were attached directly to the spine. Added two collarbones and
  separately bound shoulder caps; lifting an arm no longer rotates its pauldron.
- The source bones all used short parallel axes. Bones now point to the actual
  limb joints, with connected elbow/knee chains. Explicit rest-basis conversion
  preserves the neutral-axis runtime transform contract.
- Some hand targets were too close to the shoulder or sharply overhead, forcing
  the IK clamp into awkward poses. Casting anticipation now follows lower,
  smoother trajectories, with parent-space shoulder and pelvis compensation.
- Characters returned to idle before their relics finished. Siphon, Chalice,
  Crown, Block and Bell now retain the appropriate activation pose and recover
  after the effect. Grounding and the existing melee contacts are retained.
- Most relics shared a hidden source preview and used generic runtime nodes.
  All 29 now have individual textured, rigidly weighted source meshes and grip
  metadata. Runtime prop, secondary and effect controls use a six-bone skeleton.
  The layered bell remains articulated; energy/tether deformation is procedural,
  driven by the exported tracks rather than simulated physics.
- Projectile release used the hand position on whichever frame crossed the
  release marker. It now samples the exact authored grip transform without
  changing the displayed skeleton. Weapon grips use their actual artwork pivots.
- Blender timeline markers still assumed 30 FPS. They now use the same 60 FPS
  basis as the action bake/export; Iron Strike contact is frame 133 at 2.2 seconds.

## Verification

- Saved Blender character: 20 bones, 18 weighted meshes, 16 actions.
- Saved Blender props: six bones, 29 individual relic model collections.
- Saved-source vertex comparison: 45,504 checks across all 16 actions,
  maximum Blender/Godot skin error 0.000505 pixel; weights normalized and rigid
  pauldrons bound only to their collarbones. Reproducible validator:
  `blender --background --python scripts/art/validate_relic_pipeline.py`.
- Bone-axis retarget comparison: all 50,720 bone samples, maximum position
  error 0.000112 pixel and angle error 0.0000064 radian.
- Source and exported-pack motion checks: 85,676 checks; maximum one-frame
  joint displacement 22.072 pixels, valid bend directions/limits, fixed limb
  lengths, planted anticipation and continuous recovery.
- Native close-up review: ten complete actions, 5,096 checks, zero failures;
  collarbones, rigid armor and held Siphon grip inspected with skeleton overlay.
- Full source relic catalog: all 29 effects completed; unchanged named relic
  damage, Block, Strength, Overkill, multipliers, lifesteal caps and cleanup.
- Final exported focused test: 4,403 checks, zero failures; retained forge
  browsing, independent dual-wield contacts, six-bone prop skeleton, status
  feedback and healing transfer timing.
- Actual 0.46.1 Windows executable, native Compatibility renderer: 1,800 checks,
  zero failures, exit code 0, no errors in the clean native payload log.
- An earlier capture request inside the read-only PCK could not save screenshots.
  It was replaced with a clean native run; capture evidence is from source-native
  renders. That failed capture is not counted as successful screenshot evidence.

## Review artifacts

- `.test-artifacts/046/rig-review-0461-final.mp4`: 34-second close-up character
  motion with the actual skeleton shown alongside the painted rig.
- `.test-artifacts/046/relic-activation-0461-final.mp4`: 45-second battle reel
  covering Iron Strike, Chalice, Block, Crown, Siphon, Piston, Bell, Hammer and Wedge.
- `.test-artifacts/046/rig-review/`: native PNGs, including cast anticipation,
  contacts and the held transfer pose. `.test-artifacts/046/feedback/` contains
  additional dual-wield and healing timing frames.
- Both movies are muted fixed-30-FPS review captures, not measured real-time FPS.
  MJPEG decode produced doubled-height frames; delivery MP4s were normalized
  back to the actual native 1280x720 view and visually checked.
- Skin/retarget evidence: `skin-pipeline-parity.json`, `rig-retarget-parity.json`.
- Logs: `rig-packaged-relic_feedback_test.log`, `rig-packaged-motion_quality_test.log`,
  `rig-native-clean.log`, `rig-review-film.log`, `rig-battle-film.log`.

## Local build

Installer: `installer/OverkillSetup-0.46.1.exe`, 342655873 bytes,
SHA-256 `062a868425af86b3059e162f9e15b48cd1e824a1db8112529509d0feadd64f03`.
Portable: `build/Overkill-0.46.1-Windows.zip`, 369753742 bytes,
SHA-256 `797b9e9b1dcbf0c19a60cf76f847c968b7143699ed490b2590dee621378f493c`.
Five-file portable allowlist and checksum manifest verified.

Combat rules, damage values, progression and save schema are unchanged. The user's
installed build and normal saves were not replaced; checks used disposable profiles.
Interactive installation, other display presets and a full human campaign were
not re-tested in this revision. Source movie runs still report the previously
observed shutdown ObjectDB warning; the clean native payload run did not.

This verifies the corrected illustrated rig and export pipeline. Cinematic quality
and natural feel remain a human visual acceptance gate. No source branch, PR,
tag or release was published during this revision.
