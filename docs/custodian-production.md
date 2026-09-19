# Hollow Custodian production study

Status: isolated articulated bust study, not a finished enemy or combat integration. Published 0.23 unchanged. The Act II elite currently uses the generic armored 3D fallback; this asset is not substituted into encounters yet.

## Direction and source

Enemy identity: data/enemies/act2/act2_elite.tres, Hollow Custodian. Clock profile: bulwark, guard/strength/counterstrike. Existing visual reference: assets/enemies/act2/act2_elite_idle.png. Preserve its sealed elongated mask, narrow vertical amber visor, exposed machinery and fractured armor rather than making another broad Sentinel silhouette.

Builder: scripts/art/build_custodian.py, run with Blender against art_source/characters/executioner-production.blend. Removes source knight geometry and retains the shared skeleton. Current output: art_source/characters/custodian-study.blend and assets/characters/rigged/custodian-study.glb. Original mask shell has a real visor opening, dark socket and recessed amber lens; mechanical neck uses collars and paired pistons. Four material surfaces, 6,216 Blender vertices, one skinned mesh. Only the inherited reference idle clip is retained; no unvalidated combat clips exported.

## Inspection

First mask had a hard horizontal forehead band; rejected. Interpolated loft profiles soften the crown/cheek transition in the final study. Front and quarter views inspected in Vulkan; third rear-quarter capture also generated. Structural fixture verifies one skinned body, four surfaces and idle-only animation list. Final `.tools/071-build-final*`, `071-import-final.log`, `071-study-final*` clean of Python/script/assertion/shader errors; known certificate warning remains. Captures: `.tools/070-profile/Godot/app_userdata/Overkill/custodian-mask-*.png`.

## Torso checkpoint — 2026-09-19

Added exposed spinal couplings, side rails, three open clockwork wheels with spokes and bearings, split breastplate, raised collar, shoulder shards and pelvic arch. Initial thick flat armor was rejected after front/quarter/rear inspection. The revised shells have thinner walls and crowned faces; suspension pins moved forward to clear the new crown. Current output: 24,834 Blender vertices, one skinned mesh and four surfaces. The earlier 6,216 count describes the mask-only checkpoint.

Final Blender build/import and Vulkan study passed (`.tools/072-build-final.log`, `072-import-final.log`, `072-study-final.log`); structural fixture checks one skin, four surfaces and idle-only clips. Front/quarter/rear captures inspected, then final front checked after pin correction. Captures: `.tools/070-profile/Godot/app_userdata/Overkill/custodian-torso-*.png`. No Python, script, assertion or shader errors; known certificate-store warning remains.

This remains a proportion/material-blocking study. Limbs, hands, rear armor supports, authored surface detail, animation and combat contact are unfinished. Plates remain too regular and materials too clean for final art; gears are static, not a validated working mechanism. No gameplay, performance or AAA acceptance. User is playing Slay the Spire 2; controlled GPU benchmarking is deferred. Next: complete the slender body silhouette and grounded attachments, then motion/contact validation before encounter integration.

## Arm checkpoint — 2026-09-19

Added paired upper-arm and forearm assemblies anchored to actual skeleton pivots: dark spindles, twin piston rods, tapered open-backed armor, elbow bearings and wrist couplings. Shoulder armor now has a supporting bracket. Current build: 30,258 vertices, one skinned mesh, four surfaces, reference idle only.

Validation: Blender/import and rendered 073 study logs passed; front/quarter/rear rest captures generated, quarter/rear inspected, plus a rendered idle pose at 0.6 seconds inspected. No script/assertion/shader/Python errors; certificate-store warning remains. This proves export and a sampled pose, not combat articulation. Hands, lower body and bespoke motion remain absent. Elbow transitions, shoulder clearance and torso connections need review across authored combat poses. Materials and armor remain too uniform for final art. No installer update; 0.23 remains published.

## Hand checkpoint — 2026-09-19

Added open metacarpal frames that reach the actual finger roots, dorsal bronze tendons, wrist/knuckle bridges and thumb saddles. All five digits on each hand have three independently bone-bound segments, dark joint bearings, exposed hinge pins and closed tapered tips. Reduced the small-part bevels and cone resolution after image review; corrected pins that were submerged inside the spherical joints. Current model: 42,374 Blender vertices, four material surfaces, one skinned mesh.

Validation: final 074 Blender/import and rendered detail fixture passed. Whole upper-body idle and both hand close-ups inspected at reference idle time 0.6 seconds; final right-hand close-up reviewed after pin-depth correction. Captures under `.tools/070-profile/Godot/app_userdata/Overkill/custodian-hand-detail-*.png`. Logs: `.tools/074-build-final.log`, `074-import-final.log`, `074-detail-final.log`; no Python/script/assertion/shader errors, known certificate warning only. No combat-pose, full motion-range, gameplay or performance acceptance. Reference idle carries a weapon-grasp shape that must be replaced with Custodian-specific motion. Lower body, rear connections, worn surfaces and authored animation remain unfinished; public installer stays 0.23.

## Lower-body checkpoint — 2026-09-19

Added a pelvic crossmember, narrow thigh/shin mechanisms with paired pistons, crested armor shells, hip/knee/ankle bearings, and pointed feet connected to the foot bones. Current body has 49,238 Blender vertices, four surfaces and one skinned mesh. The whole silhouette is now available for proportion review; the split skirt/costume is still absent.

Verification: 075 Blender/import/render checks passed. Full-body front/quarter/rear captures generated at inherited idle time 0.6 seconds; quarter and rear inspected. Increased inspection camera distance after the first rear view clipped a foot. Binding audit verifies every vertex has exactly one full-weight bone assignment, every vertex group names an existing bone, and all coordinates are finite. Logs: `.tools/075-build.log`, `075-import.log`, `075-study-final.log`, `075-bindings.log`. Known certificate warning only. No ground-contact or full-motion acceptance: the reference pose is not a Custodian animation. Rear torso rails still need articulated lower connections, the foot forms remain simple, and material surfaces are uniform. Next: split skirt silhouette, torso attachment correction and authored poses. Public release unchanged.
