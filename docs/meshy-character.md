# Meshy character preparation - 2026-10-08

Status: local editable asset and motion-review candidate. This is not an installed gameplay update, completed animation catalog, or published release. The existing combat actor, damage, clocks, relic effects, and saves are unchanged.

## Deliverables

The user-facing package is in `character 3d concept image - meshi/Prepared_Meshy_Character/` in Yonatan's original checkout. It contains `Meshy_Character.glb`, packed editable `Source/Meshy_Character.blend`, a ten-second `Meshy_Motion_Review.mp4`, and `Preview Character.cmd`. The launcher uses the repository's existing Godot 4.5.1 executable. The preview is a separate project with no gameplay autoloads or save access.

This branch contains the preparation/validation scripts, isolated review scene/script, and source provenance/validation JSON. Large generated GLBs, Blender files, and review media are local outputs excluded from Git. Preserve the three original Meshy downloads; the script requires the rigged and remeshed inputs and records all three hashes.

## Changes

- Compared canonical per-triangle UV sets; rigged and remeshed layouts match despite reordered indices. Restored the remeshed base-color and packed metallic/roughness maps. Removed the rig export's whole-body emission and custom specular multiplier. Geometry, skin, animation metadata, and node transforms remain unchanged during this direct GLB material repair.
- Corrected oversized Blender bone display lengths. Maximum rest-matrix element difference: 0.000007629 in source armature units. Kept all 23 original joints and skinning.
- Added four hand/foot IK targets, four elbow/knee poles, and two foot-orientation constraints to the Blender source. Six constraint drivers use the armature's `controls_enabled` property (default zero). Disable the active action before editing with these controls. Their neutral pole-fit errors are 0.62-2.39 mm.
- Preserved the supplied Walking and Running limb motion, normalized each to a one-second clip, and adjusted Hips translation to remove floor penetration. Maximum upward adjustment: Walking 3.43 cm; Running 5.38 cm. Original downloads remain unchanged.
- Added a three-second breathing Idle with exact loop closure, plus initial Jump_Down (1.8 seconds) and Guard_Raise (1.2 seconds) motion studies. Jump_Down is a vertical drop/landing test from 1.2 m, not the complete clock-top entrance sequence. Guard_Raise is a body pose, with no shield prop or gameplay Block effect attached.
- The GLB contains five baked clips and does not require Blender IK targets in Godot.

## Verification

- Saved-source validation passes 149 checks: five clips, 23 joints, packed material maps, six control drivers, no whole-body emission, finite evaluated vertices, sampled deformation bounds, exact idle loop closure, landing contact, and actual guard hand movement.
- Guard foot drift is at most 0.114 mm; hand travel reaches 37.5 cm. Sampled Walking/Running floor minima are +0.34/+0.46 mm after correction; sampled Jump_Down minimum is -1.92 mm.
- Native Godot 4.5.1 OpenGL review reports `MESHY_NATIVE_ASSET_OK` with all five expected durations and 23 bones. The final sequence completes with `MESHY_NATIVE_CAPTURE_OK frames=300`; stderr is empty. Front, locomotion, landing, and guard frames were inspected.
- The ten-second 1100x720 30-FPS MP4 encodes and fully decodes without errors. This is fixed-step capture, not evidence of real-time FPS.
- The exact user-facing package is separately imported and startup-checked. Original download hashes are compared to the preparation manifest.

## Remaining production work

The model is now an editable animation base. Individual finger articulation, independent coat/scarf rigging, joint/garment self-intersection cleanup, hand grips, complete entrance choreography, attacks, hit reactions, relic-specific motion, and live combat integration remain. The high-poly normal map uses a different UV layout and must be baked before it can be transferred. Bounds tests do not prove that all self-intersections are absent. Visual quality and complete motion acceptance remain open.

No gameplay release was built or published. Existing public installer: [v0.45.0-test](https://github.com/UnKami/Overkill/releases/tag/v0.45.0-test). Existing publication/push/merge hold is preserved.
## In-game preview integration (2026-10-08)
The isolated branch now substitutes MeshyBattleActor for the player in IllustratedStage.
The real CombatController, nine-socket clocks, relic choices, enemies and combat math remain unchanged.
The preview boots directly into a disposable seeded encounter; choices remain user controlled.
The title is Overkill Meshy Preview and user data is isolated in Overkill-Meshy-Preview.
The older dirty working checkout and reserved relic scripts are not integration inputs.

The actor uses a transparent 960px SubViewport, original 23-joint skin and prepared material maps.
Idle, Walking and Jump_Down provide the perch/drop/walk entrance. The intro waits for the
actor to settle before opening choices; reduced motion skips the entrance.
Hand/chest/head anchors project actual skeleton joints into the existing effect canvas.
The prepared Guard_Raise clip and small bone overlays provide interim combat gestures.
Attack contact and recovery use existing relic markers. Hit feedback cannot cancel outgoing contact.

Limitations: this is the first in-game visual preview, not a completed combat animation library.
Specific weapon grips, fingers, cloth, polished recovery blends, death animation and relic-specific
motion still need authored work. Relic props retain the baseline 2D choreography.
The preview is based on clean main plus the character branch, not the other unpublished 0.46-0.48 work.
Existing publication/push/merge hold remains in force; no public release is claimed.

Run source: Godot --path <worktree> (main scene opens the battle).
Native verification: add -- --qa (test-only, exits after assertions and captures).
Local installer recipe: export the Windows Desktop pack to build/windows/Overkill.pck,
copy the tested Godot 4.5.1 runtime to build/windows/Overkill.exe, then compile
installer/meshy-preview.iss with Inno Setup 6. The installer has a separate AppId and user directory.


Verification: final exported Windows runtime exited 0 with MESHY_BATTLE_QA_OK; stderr empty. Controlled guard offer exercised the actual selection/resolution path (75 HP unchanged, 7 Block absorbed 4, leaving 3; turn advanced to 2). The strike applied exactly 6 enemy HP damage. All 29 markers/recoveries, simultaneous hits at both speeds, actual hand anchors, reduced-motion entrance skip and death completion passed. Native 1440x810 captures of perch, drop, ready battlefield, guard result and replay panel were inspected. Installer compilation and packaged hashes are recorded with the local delivery; no installer installation, full campaign or stable FPS claim.

## Lighting release 0.50.0
The user authorized publication on 2026-10-08. The hold no longer applies to this release.
The transparent 3D world now supplies a cyan/warm reflection sky for metal, three directional lights with self-shadowing, reduced ambient fill, and a soft canvas contact shadow. No material map or combat rule changed.
The battle remains a focused preview with separate saves. See encounter-050.md for release scope and unfinished animation work.

Final 0.50.0 source and exported native checks passed with empty stderr. Native lighting captures were inspected at 1280x720 and 1920x1080. The 29-profile timing suite, actual guard choice, 6-damage strike, hand anchors, both speeds, reduced-motion entrance skip, death completion and replay remained correct.
