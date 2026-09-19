# Boneghoul 3D production study

Status: early, unreleased model study on `feat/yonatan-sentinel-production`. The published installer remains 0.20. This asset is not connected to production encounters and does not meet the final art target.

The production direction remains dark cinematic fantasy in 3D. `assets/enemies/act1/boneghoul_idle.png` supplies the existing silhouette reference: hood, exposed skeleton, armored extremities, clawed hands and restrained cyan light.

## Source and reproduction

Run Blender 4.5.9 in background mode with `art_source/characters/executioner-production.blend` and `--python scripts/art/build_boneghoul.py`. The script retains the shared skeleton, removes knight geometry and builds an original body. It saves `art_source/characters/boneghoul-production.blend` and exports `assets/characters/rigged/boneghoul.glb`.

The body has 34,271 Blender vertices and four material surfaces: aged bone, iron, dark cloth and a muted core. Geometry includes ribs, vertebrae, clavicles, pelvis, paired limb bones, articulated claw segments, connected palms, clawed feet, recessed skull sockets, a separate jaw, hood, mantle and torn cloth strips. Evaluated foot geometry rests 0.006 m above the model ground plane.

The original idle, claw-rake, claw-guard and claw-recoil studies are exported. Shared combat actions are retained as reference actions in the Blender source, excluded from the GLB because their sword performance is inappropriate for this enemy.

## Verification

Run Godot with `res://scenes/boneghoul_study.tscn` for front, quarter and back captures. The isolated scene verifies one skinned body, four surfaces, articulated finger bones, an idle clip and absence of unvalidated combat clips.

- Vulkan study passed after geometry and grounding corrections; front, quarter and back captures inspected.
- Final Blender rebuild, Godot import and headless study passed after reference clips were removed. No script, assertion, parse or shader errors in final logs. The existing Windows certificate-store warning remains.
- Blender evaluated both sole heights at approximately 0.00600004 m.
- Evidence: `.tools/036-grounded.log`, `.tools/036-grounded/Godot/app_userdata/Overkill/boneghoul-036/`, `.tools/036-build-clean.log`, `.tools/036-import-clean.log`, `.tools/036-clean.log`.

These checks establish asset structure and isolated rendering, not combat readiness, animation quality or performance acceptance.

## Required next production work

Refine skull anatomy, silhouette, cloth thickness and wear, hand proportions, bone surface detail and material specificity. The current result still reads as a basic model study beside the painted reference. Author claw anticipation/contact/recovery, guard, recoil and death. Validate planted feet, fingertip contact, interruption and normal/fast/reduced-motion behavior before adding encounter routing. Do not attach the existing sword to make the generic combat path run. Full-fight visual review and performance profiling remain necessary.

## Claw motion study

The rake uses a raised open wind-up, brief hold, faster diagonal reach, crossing follow-through and return to idle. Legs retain the planted base. Authoring explicitly uses 30 fps; exported clips include frame zero, giving lengths 121/30 seconds (idle) and 40/30 seconds (rake). The previous idle inherited 60 fps despite its intended four-second duration; this build corrects that mismatch.

Rendered Vulkan BONEGHOUL_CLAW_OK verifies clip duration, foot drift below 2 mm, hand travel over 0.3 m and recovery within 2 mm. Anticipation and contact captures were inspected after fixing source-action evaluation during key authoring and the timebase. Evidence: `.tools/037-accepted.log`, `.tools/037-accepted-errors.log`, `.tools/037-accepted/Godot/app_userdata/Overkill/boneghoul-036/`. Earlier 037 captures are rejected. Final logs contain only the existing certificate-store warning.

This is motion blocking, not finished animation. A strong wind-up is visible, but weight transfer, shoulder deformation, follow-through, target contact and encounter timing still need work. Guard, hit and death remain unauthored. The isolated model still lacks the intended material and sculpt quality. No production encounter or installer changes are included.

## Skull and material refinement

Narrowed the lower cranium, deepened sockets and reduced/recessed cyan eye lights. Added brow and cheek structure, fused it into the cranium with voxel remeshing, then reduced the facial mesh for export. Replaced rounded dark socket inserts with flat recessed backing, reduced teeth and introduced missing teeth. Baked low-contrast material staining into vertex colors, explicitly connected to material albedo for glTF export. Four material surfaces remain; current complete body has 34,271 Blender vertices.

Vulkan study, clip duration, foot/recovery checks and material-color import checks pass. Each non-core surface must contain nonuniform color and use it as albedo. Final skull close-up inspected in `.tools/038-verified/Godot/app_userdata/Overkill/boneghoul-036/skull.png`; build/import/runtime evidence is `.tools/038-build-verified.log`, `.tools/038-import-verified.log`, `.tools/038-verified.log` and `.tools/038-verified-errors.log`. No final script/assertion/shader errors; existing certificate warning remains. First separate facial rods and unused-color export candidates were rejected.

The face still reads as simplified stylized anatomy. Jaw shape, nasal aperture, hood thickness/folds, sculpted damage, material microdetail and shoulder deformation remain below the target. Vertex staining is broad material variation, not a substitute for finished texture work. No performance or AAA acceptance is implied, and this study is not in the published installer.

## Protective brace and unguarded recoil (unreleased)

Added two authored reaction studies on the existing skinned body. The protective brace brings both claws up and inclines the torso forward. Unguarded recoil opens the arms and rocks the chest/head backward, followed by a restrained settling overshoot. Pelvis and legs remain in the planted stance. Exported durations include frame zero: guard 25/30 seconds, recoil 22/30 seconds. The body remains 34,271 Blender vertices and four surfaces.

Rendered Vulkan and headless BONEGHOUL_REACTION_OK validate both clips, protective hand rise above 0.1 m, visible head displacement above 0.05 m, opposing brace/recoil directions, less than 2 mm foot drift and idle hand/head endpoints within 2 mm. Existing rake, skin/material and timing checks remain passing. Guard and recoil captures inspected in `.tools/043-final/Godot/app_userdata/Overkill/boneghoul-036/`; logs `.tools/043-build-final.log`, `.tools/043-import-final.log`, `.tools/043-final.log`, `.tools/043-final-errors.log`, `.tools/043-headless.log`.

The first build rejected a negative quaternion-slerp factor for the settle; interpolation now uses a relative axis-angle rotation supporting the authored overshoot. That failed build and its stale-asset preview are not validation evidence. Final logs contain no build/script/assertion/shader failures; certificate-store and headless ObjectDB exit warnings remain.

These are motion-blocking studies. Shoulder/cloth deformation, convincing weight transfer, death, actual opponent contact, interruption during gameplay and encounter routing remain unfinished. The published 0.20 installer does not include these new reactions. This is not AAA acceptance.
