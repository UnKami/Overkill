# Hollow Custodian production study

Status: isolated full-body costume study, not a finished enemy or combat integration. Published 0.23 unchanged. The Act II elite currently uses the generic armored 3D fallback; this asset is not substituted into encounters yet.

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


## Split skirt checkpoint — 2026-09-19

Added two curved, folded coat shells with uneven hems, overlapping hip lames, fasteners/supports and a central pointed tabard. Front openings preserve the exposed-leg silhouette. Coat vertices blend from the pelvis into the corresponding thigh, rather than following a single rigid pelvis bone. This is skinned costume geometry, not simulated cloth.

First quarter/rear renders showed unsupported lames; added dark support rods behind the fasteners. The overall silhouette now reads as a robed automaton, but surfaces remain plain and the repeated plate shapes too regular. Torso rail attachments, material wear, authored motion, full-range costume/body clearance and encounter integration remain open. The inherited idle is only a fitting pose. Public 0.23 remains unchanged.

Final verification: 55,263 Blender vertices, one skinned mesh/four surfaces. Final 076 build/import/render logs passed; final rear capture inspected after support correction. Binding audit verifies each vertex's weights sum to one, all groups reference real bones and coordinates are finite. Logs: `.tools/076-build-final.log`, `076-import-final.log`, `076-study-final.log`, `076-bindings.log`. No Python/script/assertion/shader errors; known certificate warning remains. This does not validate cloth simulation, combat poses or performance.

## Metal look-development checkpoint — 2026-09-19

Builder now authors corner-domain wear masks: red marks beveled faces, green provides stable per-part variation, blue retains unoccluded AO. `CustodianMaterials.apply(model)` binds the existing tested metal shader to Iron/Bronze only, with cool steel and muted bronze palettes; recesses and visor retain imported materials. Requires active vertex-color export: the initial default MATERIAL mode exported white instead of the masks, caught by checking the actual Godot mesh color arrays. Builder now explicitly exports ACTIVE colors.

Reusable inspection scene: open `scenes/custodian_study.tscn` and run the current scene in Godot (F6). It applies the material binder, workshop reflections, cool key/warm rim and inherited idle. This is a look-development scene, not playable combat. The raw GLB contains shader-mask colors; use the binder for intended appearance. No production encounter changes or new installer.

Final verification: imported mesh arrays contain both face and bevel mask values on exactly two overridden metal surfaces; inherited idle is playing. The initial mask assertion failure was fixed through ACTIVE export, not weakened. Final `.tools/077-build-final.log`, `077-import-final.log`, `077-scene-check-final.log` pass; known certificate-store warning remains. Final rendered scene inspected after reducing excessive exposed-edge brightness. Capture: `.tools/070-profile/Godot/app_userdata/Overkill/custodian-study-scene.png`. Geometry count unchanged at 55,263. Surface variation is modest; no claim of finished wear, final art or performance acceptance.

## Authored idle checkpoint — 2026-09-19

Replaced the source knight's weapon-holding pose with an original Custodian idle: lowered arms, gently curled claws, planted leg transforms and restrained chest/head/arm motion. Builder removes all inherited NLA tracks and exports only `custodian_idle`; study scene explicitly enables looping. The original four-second export gained an extra leading frame because authoring began at frame 1; keyframes and NLA now begin at frame 0.

Earlier sections describing the inherited idle are historical checkpoints. The current study scene uses this authored clip. Attack, guard, hit and collapse are still absent; this asset is not integrated into encounters.

Final validation: exported clip is exactly 4.0 seconds; sampled all bone transforms at 0, 0.5, 1, 2, 3, 3.5 and 4 seconds. Endpoint position/rotation continuity passes, both foot transforms remain fixed, and peak sampled hand travel is 8.88 mm. Rendered pose inspected after export correction. Logs `.tools/078-build-final.log`, `078-import-final.log`, `078-idle-check-final.log` pass with known certificate warning only. A separate headless duration diagnostic outside the isolated profile crashed natively; its exact process was stopped, and isolated rendered diagnosis succeeded. This is not a performance or broad stability result. Costume clearance across combat actions remains unverified.

## Guard animation checkpoint — 2026-09-19

Added an authored one-second `custodian_guard`: lift at 0–0.3 s, hold through 0.6 s, recover by 1.0 s. The first pose raised open hands beside the mask and was rejected as an unclear defensive read. Revised pose brings both forearms inward over the chest, offsets their depth and curls the fingers more firmly. Start/end use the exact idle reference transforms; lower-body transforms remain unchanged.

Study controls: G plays guard; R returns to idle; guard completion automatically resumes idle. This is an isolated animation preview, not a combat event integration. Attack, hit, collapse, impact contact, interrupted-action handling in gameplay and costume clearance across those actions remain unfinished.

Final validation: exact 1.0-second duration, all-bone idle matching at guard start/end, fixed feet at five sampled times and automatic idle return pass. Peak sampled wrist rise 0.417 m. Revised raised and intermediate poses inspected, plus side view after increasing hand depth separation. Four-second idle regression still passes. Logs: `.tools/079-build-final.log`, `079-import-final.log`, `079-guard-check-final.log`, `079-side-check.log`, `079-idle-regression.log`; no script/assertion/shader/Python errors, certificate warning remains. Geometric collision clearance has not been exhaustively measured. Published installer unchanged.

## Hit reaction checkpoint — 2026-09-19

Added an original 0.8-second `custodian_hit`: peak recoil at 0.1 s, short damped counter-motion, then recovery. Spine/chest/head recoil, arms spread slightly and fingers loosen; hips/legs remain fixed. Start/end use the same authored idle reference as guard. H in the study scene plays the reaction, interrupts guard, restarts repeated hits and returns automatically to idle. This is animation-preview behavior, not combat event wiring.

Primary checks: exact 0.8-second duration, all-bone idle matching at start/end, fixed feet at six samples, guard interruption, repeated-hit restart and automatic idle return pass. Peak sampled head travel is 66.9 mm. Primary rendered recoil pose inspected. These state checks do not establish full geometric clearance or perceptual smoothness under every interruption. Attack, collapse, impact/contact synchronization, torso support refinement and final materials remain incomplete.

Final verification: primary and side recoil renders reviewed; guard and idle regression fixtures remain green. `.tools/080-build.log`, `080-import.log`, `080-hit-check.log`, `080-side-check.log`, `080-guard-regression.log`, `080-idle-regression.log` have no script/assertion/shader/Python errors. Known certificate warning remains. Geometry remains 55,263 vertices/four surfaces. No installer or performance change claimed.

## Attack animation checkpoint — 2026-09-19

Added an original 1.2-second `custodian_attack`: raised right-arm wind-up, anticipation hold through frame 10, fast forward extension at frame 14 (0.467 s), downward follow-through, recovery to idle by frame 36. Left arm remains in a protective pose. A in the study scene plays attack; completion resumes idle, and H can interrupt it with the hit reaction.

Primary validation: exact duration, all-bone idle-matched endpoints, fixed feet at seven samples, automatic idle return and hit interruption pass. Right wrist advances 0.519 m from idle at frame 14. This is an animation landmark, not validated opponent contact or a damage event. Wind-up and extension rendered poses inspected. Attack requires contact choreography, effects/sound synchronization and full clearance review before production use. Collapse and encounter integration remain absent; overall art finish still incomplete.

Final verification: side-view extension inspected; idle, guard and hit regression checks still pass. Final 081 logs show no script/assertion/shader/Python errors; known certificate warning remains. Geometry remains 55,263 vertices/four surfaces. This is a functional animation study, not final motion quality, combat-contact validation or AAA acceptance. Public installer unchanged.

## Torso rail attachment checkpoint — 2026-09-19

Replaced chest-only rail binding with dedicated lower/upper mount bones parented to hips/chest and constrained rail bones between them. Added four bearing joints. Stretch-to constraints bake into GLB animation; the runtime needs no constraint solver. This is a length-adjusting rail, not a detailed telescoping piston simulation. Geometry now 55,847 vertices/four surfaces; six auxiliary bones added.

The first exported check failed at 1.44 mm endpoint error. Blender's evaluated source remained within 0.000121 mm, and raw GLB contained the full sampled rotations/scales; Godot had reduced those tracks. Tightened the AnimationPlayer import optimizer to velocity/angular error 0.0001 and precision 6, retaining optimization. Settings verified against Godot 4.5.1 source: https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/editor/import/3d/resource_importer_scene.cpp . The model's .glb.import is part of this change and must remain tracked.

Final verification: 844 poses at 120 samples/second across all four exported clips, both endpoints/both rails, maximum separation 0.450 mm (threshold 1 mm). Attack side render inspected. Idle/guard/hit/attack regressions all pass. Logs `.tools/082-build.log`, `082-import-final.log`, `082-rail-dense.log`, and `082-*-regression.log` have no script/assertion/shader/Python errors; known certificate warning remains. The initial failing diagnostic is retained separately. No performance acceptance, collapse, encounter integration or new installer.

## Defeated-state checkpoint — 2026-09-19

Added a 1.6-second mechanical slump, `custodian_collapse`, with lowered pelvis, solved knee positions against fixed ankles, bowed torso/head and hanging arms. The first torso fold exposed too much armor separation and was reduced; the final intended pose shifts more of the slump into the knees. Unlike the other actions, completion holds the defeated pose. D previews it; R restores idle. The study duplicates the visor material per model and fades its emission/albedo during defeat; reset or another preview action restores it. This material fade is study behavior, not a baked GLB material animation.

This remains an isolated character study. The defeated state still needs encounter wiring, actual battle framing and interaction with combat effects. It is a mechanical shutdown/slump rather than a ragdoll or floor-impact collapse.

Final primary check: 1.6-second duration, held terminal pose, explicit reset and visor fade/reset pass. Across six deformed-mesh samples the minimum vertex height is 15.97 mm above the study ground plane; maximum sampled foot drift is 0.205 mm; head lowers 0.314 m. Rail attachment audit now covers 1,037 poses across five clips, maximum endpoint error 0.450 mm. This does not prove collision clearance at every interpolated time or during cross-fades.

Final review: primary and side terminal renders inspected; side view still exposes rough coat/knee behavior that needs costume deformation refinement before final art acceptance. Idle/guard/hit/attack regressions remain green. Final 083 build/import, collapse, side, rail and regression logs have no script/assertion/shader/Python errors; known certificate warning remains. Geometry unchanged at 55,847 vertices/four surfaces. Published installer unchanged.

## Coat deformation checkpoint — 2026-09-19

Reweighted the split coat so front panels follow the thighs below the waist while rear panels remain looser. Added a gradual 15 mm lateral / 12 mm depth flare toward the hem without moving the waistband. This addresses knee penetration during the mechanical slump; it remains skinned geometry, not cloth simulation.

Blender audit across all 49 authored collapse frames measures a minimum 64.406 mm from either knee center to the coat surface, versus 21.032 mm at a previously sampled failing pose. This exceeds the conservative 50.6 mm knee axle/cap envelope by approximately 13.8 mm. It is a focused knee-envelope check, not exhaustive whole-body collision detection or cross-fade validation.

Exported Godot collapse checked at 120 Hz (193 samples): minimum deformed vertex height 15.556 mm, maximum foot drift 0.448 mm; held terminal state, visor fade and explicit reset pass. Side terminal render inspected. Final geometry 55,838 Blender vertices / four surfaces. Logs: `.tools/084-build-final.log`, `084-coat-final.log`, `084-import-final.log`, `084-collapse-dense.log`, `084-side-final.log`. No script, shader, assertion or Python errors; known certificate warning remains. Art finish, encounter integration and controlled performance acceptance remain open. Public installer unchanged.

Idle and attack regression fixtures pass after the coat rebuild (084 logs), including idle loop endpoints, planted feet, attack recovery and hit interruption.

## Material separation checkpoint — 2026-09-19

Custodian now uses a dedicated metal shader, leaving Sentinel unchanged. Darker blue steel and warmer bronze use separate roughness and oxidation settings. Two triplanar texture scales provide broad tarnish and restrained fine variation; the geometry-authored bevel mask still controls exposed edges, with broken coverage instead of identical bright borders. Existing scanned metal texture is reused; no new texture allocation or geometry. This shader uses six texture samples versus the shared shader's three; controlled GPU cost has not been benchmarked.

The first high-contrast grain pass was rejected after close-up comparison. Reduced detail contrast and scale before final review. Identical-camera before/after close-ups and the full-body study were inspected. Surface separation improves, but repeated polygonal plate forms, sparse machinery and the smooth mask still read as an unfinished model. This is not production art acceptance.

Verification: isolated Vulkan study loads both material overrides with intact vertex wear masks; close-up/full-body renders and collapse/visor reset checks pass. Logs `.tools/085-import.log`, `085-after-final.log`, `085-fullbody.log`, `085-collapse.log` have no script/shader/assertion/Python errors; known certificate-store warning remains. No encounter wiring or installer change. Full motion texture stability and controlled performance remain unverified.

## Armor curvature checkpoint — 2026-09-19

Replaced the raised inset-center construction on armor plates with a shallower three-ring crown. Angle-limited perimeter bevels remove the repeated bright internal borders that made chest, shoulder and hip armor resemble inset gems. Reduced chest suspension-pin radius and projection while extending the embedded end into the shallower plate. This is a construction refinement; fracture silhouettes remain regular and require further art direction.

Initial close-up and defeated-pose renders show cleaner continuous faces and less repeated internal outlining. The model remains an unfinished art study, not production acceptance. Final verification follows below.

Final verification: 54,534 Blender vertices/four surfaces (1,304 fewer vertices than the preceding asset). Final close-up, guard and attack poses reviewed; study material masks, guard endpoints/fixed feet/idle return and attack recovery/hit interruption pass. Collapse checks passed on the shell revision before the final chest-pin size adjustment. Initial guard fixture reported an ObjectDB shutdown leak; the fixture was updated to free the study and wait two frames before exit, then rerun with verbose diagnostics. No leak warning on that rerun. Final 086 build/import/render logs contain no script/shader/assertion/Python errors; certificate-store warning remains. This does not establish exhaustive collision clearance, performance gain or final art quality. Installer unchanged.
