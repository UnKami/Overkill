# Boneghoul 3D production study

Status: early, unreleased model study on `feat/yonatan-sentinel-production`. The published installer remains 0.19. This asset is not connected to production encounters and does not meet the final art target.

The production direction remains dark cinematic fantasy in 3D. `assets/enemies/act1/boneghoul_idle.png` supplies the existing silhouette reference: hood, exposed skeleton, armored extremities, clawed hands and restrained cyan light.

## Source and reproduction

Run Blender 4.5.9 in background mode with `art_source/characters/executioner-production.blend` and `--python scripts/art/build_boneghoul.py`. The script retains the shared skeleton, removes knight geometry and builds an original body. It saves `art_source/characters/boneghoul-production.blend` and exports `assets/characters/rigged/boneghoul.glb`.

The body has 20,926 Blender vertices and four material surfaces: aged bone, iron, dark cloth and a muted core. Geometry includes ribs, vertebrae, clavicles, pelvis, paired limb bones, articulated claw segments, connected palms, clawed feet, recessed skull sockets, a separate jaw, hood, mantle and torn cloth strips. Evaluated foot geometry rests 0.006 m above the model ground plane.

The original idle and an authored claw-rake study are exported. Shared combat actions are retained as reference actions in the Blender source, excluded from the GLB because their sword performance is inappropriate for this enemy.

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
