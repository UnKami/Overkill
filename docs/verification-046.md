> Superseded local candidate: the 0.46.0 evidence below remains historical.
> Review the revised [0.46.1 rig/pipeline evidence](rig-review-046.md), built
> 2026-10-06. Publication is held for the user's visual review.

# 0.46 relic feedback verification — 2026-10-05

Status: locally implemented and packaged; GitHub publication awaits explicit
approval after automatic approval review rejected the combined commit/push command.
No remote source branch, pull request, tag, or release was created in this session.
The existing published 0.45 installer remains the public download.

## Checks

- Blender 5.2.2 generated the editable Executioner rig: 18 bones, 16 weighted
  meshes and 13 actions at 60 Hz, including twin_right and twin_left.
- Blender regenerated all 29 six-bone relic cues. Twin Blades uses hand-bound
  Iron Strike swords; calibrated prop rotations align the blades at contact.
- Source full-catalog scene: RELIC_ANIMATION_OK, all 29 relics, unchanged named
  damage/Block/Strength/Overkill/multiplier results, full Block lifesteal, fast
  and reduced-motion cases, temporary effect cleanup and recovery.
- Final source motion check: MOTION_QUALITY_OK, 56,114 checks, maximum joint
  step 31.877 pixels. Fixed limb lengths, valid elbow bends, planted anticipation,
  continuous recovery and all enemy rigs passed.
- Final focused source native-render test: RELIC_FEEDBACK_OK, 1,751 checks,
  zero failed checks. Forge retains scroll position, reflects the upgraded
  instance, permits inspection, prevents a second free upgrade, and only
  continues the journey through the separate action.
- Exported-pack focused check: RELIC_FEEDBACK_OK, 4,395 checks, zero failures.
  Partial Block, full Block, enemy HP cap, missing HP cap, Strength, Weak,
  Vulnerable, Reduced Motion and heal-before-thorns ordering passed. Each Twin
  Blades hit independently resolved Block and HP at its own contact. Status
  redraws preserved node identity and did not retrigger unchanged gains.
- Actual build/windows/Overkill.exe native-render focused check: 1,442 checks,
  zero failures and exit code 0. Verbose shutdown log had no leak warning.
- Actual Windows executable upgrade-popup check: UI_OVERLAYS_OK, exit code 0.
- Exported-pack motion check: 56,114 checks; artifact interactions:
  RUN_ARTIFACTS_OK, including no posthumous healing; saved-run check:
  RESUME_CHECKPOINT_OK, 153 disk/title-round-trip assertions.
- Windows installer compiled successfully. Portable ZIP verified against the
  five-file allowlist, and SHA-256 digests generated for both deliverables.

## Visual evidence

Reviewed native 1280x720 frames: forge comparison, forge after upgrade, purple
Strength and Block gains, both sword wind-ups and contacts, single green orb
in the bulging conduit, and +3 HEAL appearing on arrival with HP rising 40→43.
Local captures: `.test-artifacts/046/feedback/`.

Preview: `.test-artifacts/046/relic-feedback-preview.mp4`, 15 seconds at 30 FPS,
from Godot's movie capture of the production test scene. It covers the forge,
dual-wield attacks and the first Siphon transfer. Twin Blades uses normal timing;
the Siphon regression segment uses Fast Mode. Fixed-FPS movie capture is animation
review evidence, not real-time gameplay performance evidence.

Logs: `.test-artifacts/046/packaged-feedback-output.log`, `payload-native.log`,
`payload-ui-final.log`, `packaged-motion_quality_test.log`,
`packaged-run_artifact_test.log`, `packaged-save-final.log`.

## Deliverables and limits

- Local installer: installer/OverkillSetup-0.46.0.exe, 342506689 bytes,
  SHA-256 18440b64d21676bfbe1caaa201cf853b52e7fba7969ba4fd106349b6a671475a.
- Local portable ZIP: build/Overkill-0.46.0-Windows.zip, 369595998 bytes,
  SHA-256 3c0212717561eb67aeae4406c0dd082dd5c6cbb096fc248694975bd735c4c41b.
- Manifest: installer/OverkillSetup-0.46.0.sha256.
- Existing save schema and authoritative combat order retained. Prebattle
  checkpoints still roll unfinished offers back rather than duplicating upgrades.
- Tests used disposable APPDATA/LOCALAPPDATA profiles. The user's installed
  Desktop/Overkill build and normal saves were not replaced.
- Installer compilation and exported payload were verified; interactive
  installation/uninstallation were not run. Full human campaign playtesting,
  other display presets and final visual acceptance remain open.
- Some source/native movie runs emitted an intermittent ObjectDB shutdown
  warning. Final exported-pack verbose and actual Windows native verbose runs
  exited cleanly. No persistent status-node orphan growth was found.
- Pre-existing unrelated working-tree files and imports were retained, and are
  excluded from staging. This is a local candidate, not a published delivery.
