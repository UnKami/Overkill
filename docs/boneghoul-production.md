# Boneghoul 3D production study

Status: early, unreleased model study on `feat/yonatan-sentinel-production`. The published installer remains 0.20. This asset is not connected to production encounters and does not meet the final art target.

The production direction remains dark cinematic fantasy in 3D. `assets/enemies/act1/boneghoul_idle.png` supplies the existing silhouette reference: hood, exposed skeleton, armored extremities, clawed hands and restrained cyan light.

## Source and reproduction

Run Blender 4.5.9 in background mode with `art_source/characters/executioner-production.blend` and `--python scripts/art/build_boneghoul.py`. The script retains the shared skeleton, removes knight geometry and builds an original body. It saves `art_source/characters/boneghoul-production.blend` and exports `assets/characters/rigged/boneghoul.glb`.

The body has 34,271 Blender vertices and four material surfaces: aged bone, iron, dark cloth and a muted core. Geometry includes ribs, vertebrae, clavicles, pelvis, paired limb bones, articulated claw segments, connected palms, clawed feet, recessed skull sockets, a separate jaw, hood, mantle and torn cloth strips. Evaluated foot geometry rests 0.006 m above the model ground plane.

The original idle, claw-rake, claw-guard, claw-recoil and collapse studies are exported. Shared combat actions are retained as reference actions in the Blender source, excluded from the GLB because their sword performance is inappropriate for this enemy.

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

## Seated collapse study (unreleased)

Added a 1.6-second defeat clip: brief recoil/failing hold, pelvis drop, forward fold, settling beat and held seated slump. It is distinct from the Sentinel's armored kneel. Two-bone leg placement is baked at each of 48 export frames; both feet retain their original transforms. The first higher pose read as a crouch and was revised to a lower seated position with settled forearms.

Vulkan and headless BONEGHOUL_COLLAPSE_OK verify clip duration, foot drift below 2 mm at all 48 samples, body/head drop over 0.5 m, hand clearance and final held head position. Blender evaluates the final skinned mesh minimum at 0.00600004 m above the ground plane. Final render inspected. Existing attack/reaction/material/skin checks continue to pass. Evidence `.tools/044-build-final.log`, `.tools/044-import-final.log`, `.tools/044-final.log`, `.tools/044-final-errors.log`, `.tools/044-headless.log` and final collapse captures under `.tools/044-final/Godot/app_userdata/Overkill/boneghoul-036/`.

This remains authored motion blocking, not ragdoll or physically simulated cloth. Final mesh clearance does not establish collision-free motion at every intermediate pose. The model still has simplified anatomy/materials and shoulder/hood deformation issues. Opponent contact, gameplay interruptions, terminal state integration and encounter routing remain unverified. Published installer remains 0.20; these later animation studies are not shipped there.

## Opponent-space contact and interruption study (unreleased)

Added a dedicated BoneghoulActor with authored claw clips, manual animation advancement, a single contact event and terminal-state protection. Long frames split at the actual contact timestamp before emitting the event; any remaining time advances the resulting state. Guard/recoil cancel pending attacks, and late attack/hit/fall requests cannot restart a defeated actor. No sword equipment or normal encounter routing was added.

The opponent fixture exposed a 0.7679 m claw-to-chest-center miss at the existing arena transforms. A closer, pre-established stance at (0.505534, 0, -0.02731), yaw -1.064631, aligns the claw with the Executioner's lower chest surface within 0.0371 m. This is calibration against one static opponent pose, not a universal collision solution. The stance is set before the attack; no contact-time root teleport is used. Right-foot drift stays below 2 mm through the sampled attack.

Headless and Vulkan contact/interruption fixtures pass: normal/fast advancement, both reduced-motion settings, one contact per attack, guard/recoil cancellation, long-frame contact-pose precision, held death pose and a synchronous contact callback that starts collapse. Final headless evidence `.tools/045-verified.log`; Vulkan evidence `.tools/045-render.log` and `.tools/045-render-errors.log`. Rendered original miss and closer stance inspected under `.tools/045-render/Godot/app_userdata/Overkill/boneghoul-contact/`. No script/assertion/shader errors; existing certificate-store warning and headless exit leak warning remain.

The visual review still shows simplified bone surfaces, thin/angular cloth and stiff shoulder deformation. This fixture does not prove bidirectional weapon clearance, live-target contact, full battle timing, performance or AAA quality. No installer was rebuilt; published 0.20 is unchanged. Next: validate reciprocal Executioner strike clearance and integrate an opt-in encounter only after its scheduling and terminal delay respect these clips.

## Folded mantle and reciprocal strike audit (unreleased)

Rebuilt the shoulder mantle with expanding folds below a pinned collar, irregular broad hem tears, 9 mm cloth thickness and a worn edge. Shoulder vertices take up to 28% upper-arm influence while the collar remains chest-bound. The model now has 36,603 Blender vertices (+2,332), still four material surfaces. No shader or runtime material cost was added; performance impact has not been profiled.

The close-stance fixture now places the Executioner's sword against the Boneghoul, including idle, recoil and guard poses. At idle the blade segment comes within 0.0519 m of the chest center, and its grip remains outside the torso. Reaction poses remain within a 0.22 m torso envelope. These are geometric reach checks, not collision simulation or proof of convincing blocking.

Render review exposed an unresolved choreography problem: during guard the claws rise but the sword still aims into the ribcage. A future pre-contact guard/interception phase must change the contact destination and timing; merely passing the torso-envelope check is insufficient. The present fixture deliberately retains this evidence and does not route the study into normal encounters.

Verification: `.tools/046-build.log` BONEGHOUL_BUILD_OK; `.tools/046-import.log`; Vulkan `.tools/046-study.log` and `.tools/046-study-errors.log` (attack/reaction/collapse/material tests pass); `.tools/046-final.log` and `.tools/046-final-errors.log` (reciprocal reach and interruption tests pass). Inspected quarter, anticipation, collapse, sword contact, recoil and guard renders. No Python/script/assertion/shader errors. Existing certificate-store and occasional ObjectDB exit warnings remain. Published installer stays 0.20. The cloth silhouette is improved but sculpt, material detail, deformation and gameplay integration remain below the target.

## Pre-contact guard interception and weapon transform fix (unreleased)

BoneghoulActor can now prepare and hold its protective brace before impact. It stops at frame 7 until hit(true) releases the existing clip, without restarting the raise. Repeated preparation is idempotent; attack, unguarded hit and defeat cancel the hold. Defeated actors ignore preparation. The guarded sword destination is the armored right forearm rather than the ribcage.

Timed render inspection exposed a separate shared weapon transform defect: RiggedCombatant explicitly places equipment in world space, but a deferred BoneAttachment update could subsequently apply parent motion again. Equipment now uses top_level so _align_weapon remains its sole world-transform owner. A rendered assertion confirms that contact placement survives subsequent frame/bone updates. Existing generic targeting remains unchanged for actors without a guard destination.

The isolated sequence raises guard alongside the incoming attack, verifies forearm interception from the authored 0.32 s contact through 0.40 s, verifies torso clearance, releases at impact and recovers to idle. Runs at 1x/2x with reduced motion on/off. The earlier diagnostic at 0.30 s failed a contact threshold because the blade was still approaching (6.3 cm away); final contact assertions begin at the actual authored contact time, while torso clearance is checked earlier too. Static guarded torso separation is 0.555 m; bracer intersection is within floating-point tolerance.

Final evidence: `.tools/047-final-render.log` and errors log, timed-guard-contact render under `.tools/047-final-render/Godot/app_userdata/Overkill/boneghoul-contact/`; rendered Sentinel regression `.tools/047-sentinel.log` and errors log, player/enemy impact images inspected; `.tools/047-finish.log` verifies all eight victory/defeat speed/motion combinations. Final logs have no script/assertion/shader errors. Existing certificate-store and occasional ObjectDB exit warnings remain. The earlier `.tools/047-final-headless.log` failure and pre-transform `.tools/047-verified` render are rejected evidence.

This is isolated choreography and a shared transform correction, not a completed Boneghoul encounter. No live combat damage scheduling or encounter routing changed. Published installer remains 0.20. Art quality, wrist/weapon grip orientation, enemy-specific incoming guard behavior and full battle integration still need work.

## Opt-in battle integration (unreleased)

Run the source game with `-- --boneghoul-3d` to route Boneghoul encounters through DirectedArena and the authored claw actor. Default encounters keep their existing presentation. The close stance, attack contact/recovery protocol, pre-contact guard and terminal state now participate in the real CombatController. Full blocks prepare the bracer before the incoming sword; partial blocks still permit HP damage. Impact light/sparks and the smaller guard ring use the forearm intersection; incoming claw effects use the finger contact location.

The Boneghoul's 1.6-second collapse has a dedicated, speed-aware fade delay and handoff. Initial integration kept the old 1.15-second fade and hid the end of the collapse; corrected after render inspection. Final victory capture shows the settled pose before fade. Source changes do not change combat damage calculations or release contents.

The dedicated encounter fixture runs real controller attacks against the 16-HP Boneghoul: no early damage, full and partial block, claw damage, effect destination, and all eight victory/defeat x normal/fast x reduced-motion combinations. The initial rendered observer compared the claw after it had moved into recovery and failed in fast mode despite the helper's final marker. It now independently records the finger at contact_reached and compares the effect against that event sample. Initial `.tools/048-render*` logs are rejected. Final evidence is `.tools/048-verified.log` and `.tools/048-verified-errors.log`, with 720p choice/block/claw/terminal captures under `.tools/048-verified/Godot/app_userdata/Overkill/boneghoul-encounter/`.

Additional evidence: `.tools/048-regression.log` existing cinematic/controller contact modes; `.tools/048-clock.log` nine-hour assembly/sectors/swap/single victory; `.tools/048-playthrough.log` deterministic actual-relic playthrough with the opt-in route (Boneghoul win in four choices, 69 HP remaining). The simple policy loses later bosses; this is not a balance acceptance claim. No performance profile or broader AAA acceptance is implied.

Next: package a clearly labeled preview with partner-accessible installer/release notes, profile the integrated encounter, refine sculpt/materials and grip poses, and validate broader play sessions. This art is still substantially below the intended production finish. Published 0.20 installer remains unchanged.

## Restrained aged-bone material (unreleased after 0.21)

Added a bone-only shader retaining authored vertex staining, with low-contrast mineral variation, nonmetallic roughness and shallow pore/grain normal relief. Detail uses rest-space coordinates so it follows the skinned mesh, and fades as its frequency becomes smaller than screen pixels. Cloth, iron and core surfaces remain untouched. No new mesh surfaces or texture assets; one private shader material per actor. The first stronger relief pass read as pitted stone and was reduced from 0.55 mm to 0.14 mm amplitude.

Same-camera close/wide comparisons inspected on Vulkan Mobile and GL Compatibility. The isolated GL setup is substantially darker than Vulkan in both base and detailed views; this is not accepted cross-backend lighting parity. The restrained final material adds subtle surface variation but cannot compensate for simplified skull, jaw, teeth and limb anatomy. These remain higher-priority art gaps.

Validation: `.tools/050-final*` and `.tools/050-gl*` rendered comparisons with animated sampling; `.tools/050-structural.log` verifies exactly one bone surface override and complete restoration across repeated toggles; `.tools/050-contact.log` retains contact, brace, interruption and terminal-state checks. No final script/assertion/shader errors; certificate-store and occasional headless exit warnings remain. Initial `.tools/050-material*` images are rejected as too pitted.

Integrated idle battle profile `.tools/050-arena.log`: Intel Vulkan, 1920x1080 UI / 1600x813 stage, VSync off, warmed 8-second samples, detailed → base → detailed. Medians 15.290 / 14.690 / 14.363 ms; p95 20.876 / 20.019 / 20.079 ms; stage GPU medians 9.829 / 9.520 / 9.625 ms. Draws stayed 308. Variation prevents a reliable frame-time gain/loss claim; this is not full-fight or broad-hardware acceptance, and slow frames remain above the 60 Hz budget. Isolated model timings are not gameplay performance evidence.

Published installer remains 0.21. No release binary was replaced. Next: more convincing anatomy and hand/weapon grips, integrated action profiling and broader environmental/material finish.

## Skull, dental arch and cervical shape refinement (unreleased after 0.21)

Replaced the flat triangular nasal insert with a recessed pear-shaped opening. Opened the front oral cavity while retaining the posterior skull, added an upper dental arch and rebuilt the mandible as one curved sweep with thinner rami and a rounded chin. Tooth crowns now vary in section/length, follow a curved arch and include distinct canine tips and existing missing teeth. Reduced the permanently open jaw gap. Replaced the cylindrical neck with seven vertebral forms around a narrow core.

The first nasal cutter had inconsistent face normals and did not produce the intended opening; corrected before accepting the model. Builder ray checks now verify nasal depth and the open front mouth after final remeshing, so a sealed surface cannot silently pass. The broad lower-skull cut was restricted to the front to preserve posterior attachment. This remains stylized geometry: vertebral forms, eye sockets and facial planes still need more anatomical sophistication.

Final mesh: 39,232 Blender vertices, four surfaces. Final collapse floor remains 0.00600004 m. Verification: `.tools/051-build-complete.log` includes FACE_CAVITIES_OK and BUILD_OK; `.tools/051-import-complete.log`; rendered `.tools/051-complete.log` and errors log retain skin/material, claw, guard/recoil and 48-frame planted collapse checks. Skull/pose images inspected under `.tools/051-complete/Godot/app_userdata/Overkill/boneghoul-036/`. `.tools/051-contact-complete.log` retains reciprocal reach, brace timing, interruption and terminal checks. No final Python/script/assertion/shader errors; existing certificate/headless-exit warnings remain.

Earlier 051 renders are intermediate revisions, not accepted final evidence. The neutral model study uses imported materials; the opt-in actor's aged-bone shader remains a separate surface treatment. No broad performance claim follows from the modest vertex increase. Published 0.21 installer is unchanged; full anatomy, grips, motion breadth, environment and performance work remain.
