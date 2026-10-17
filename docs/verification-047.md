# 0.47 local verification

## Current character replacement — 2026-10-07, work in progress

The earlier wardrobe and its installer are superseded locally by a full-volume
sectional model. Evidence for the current source is in
`.test-artifacts/047/proper-character/`. Publication, push and merge are held.
This pass is not delivered or visually accepted.

### Forged armor and matte cloth seams — current local evidence

Wardrobe version 7 adds sloping brass bevel faces around pauldrons, hip/knee
plates, palm armor and waist crest. Chest ornament now follows the outermost
overlapping plate instead of a fixed buried depth. `armor-relief-visibility.log`
measures visible eligible front faces in a neutral frontal ray check: 89/742
(12%) before versus 999/1016 (98%) now. This is a geometric exposure check,
not visual acceptance across every pose. Five shaped metal batches pass closed
manifold checks with actual brass bevel faces.

Saved-source skin/pose/control validation passes 156178 checks; coverage passes
2240 animated mesh-bound samples. Exact all-16 action/anchor/contact/rest parity
passes in `armor-relief-motion-contract.log`. The material bake retains four
2048px maps and excludes physical brass/bronze and woven cloth from projection.
The initial atlas review found zero-roughness samples at cloth UV corners.
Initializing unused ORM texels to AO=1/roughness=1/metallic=0 fixes those gaps.
`armor-matte-cloth-texels.log` checks bilinear samples at all 41684 hood/scarf/
mantle UV corners: zero metallic/glossy samples; minimum roughness 0.941 for
hood/scarf and 0.843 for mantle. This tests texture filtering, not every GPU mip.

`armor-matte-turns/` contains 96 native views. Sampled front/side/rear idle,
impact, hammer return and chalice poses were inspected. `Armor-Relief-Before-After.png`
compares identical idle cameras with the earlier model on the left. Current
exported payload passes 280042 motion checks and 1917 checks across all three
quality presets, zero failures; native feedback passes 1991 checks, zero errors.
All three processes exit 0. High idle, Balanced impact and Performance block
captures were inspected; Performance retains visible aliasing with AA off.

`Executioner-Forged-Armor-Review.mp4` contains ten current exported sequences;
1591 frames/53.03s decode cleanly. All four one-second overview sheets and three
denser Twin Blades sheets were inspected. This remains sampled visual review,
not every-frame approval or measured FPS. Current source, material, payload and
media hashes are in `armor-relief-artifact-hashes.json` under the evidence directory.

Remaining relic volume/art review, overall character/motion acceptance, clean
performance and installer validation remain open. Installed session PID 62052
remains untouched, QA saves remain isolated, and publication/push/merge are held.
Earlier motion/normal evidence describes retained behavior; earlier payload
hashes and movies precede this armor/material pass.

### Melee weight transfer — current local evidence

The four melee clips now use separate lead/trailing foot arcs and ankle pitches,
straighter knee tracking during compression, smooth horizontal start/stop ramps,
and staged leg loading/landing compression. Hammer support-hand release preserves
the lower-body pose rather than resetting foot rotations through its generic blend.

`weight-transfer-contract.log` proves exact unchanged rest skeleton, all 16
durations/contact marks and all 12 non-melee clips. `weight-transfer-painted-refresh.log`
verifies exact unchanged geometry/weights/rest and retains the four PBR maps.
Saved-source validation passes 156790 checks. `weight-transfer-root-acceleration.log`
measures the baked horizontal root acceleration peak at 51.32m/s2 versus 105.79
before; this measures the authored curve, not realtime frame pacing.

`weight-transfer-sole-grounding.log` checks 389120 deformed boot vertex samples,
covering every 60Hz frame of all four melee clips. The lowest point stays within
the existing -2mm outsole offset (6mm rejection tolerance). Dense enclosure
checks pass 342016 actual deformed foot samples per side across all 16 actions,
including movement markers, with no exposure beyond 2mm.

Native `weight-transfer-turns/` contains 240 angle/pose views. Sampled anticipation,
flight, impact, compression, return and settled views were inspected, including
mirrored Twin Blades and rear hammer poses. The current exported payload passes
280042 motion checks with zero failures, complete catalog/fast/reduced recovery,
and 1406 native feedback checks with zero errors. All three processes exit 0.

`Executioner-Weight-Transfer-Review.mp4` contains ten exported battle sequences;
1591 frames/53.03s decode cleanly. All four one-second overview sheets and three
denser Twin Blades sheets were inspected. This is sampled visual review, not
every-frame approval or measured FPS. Artifact hashes are in
`weight-transfer-artifact-hashes.json` under the evidence directory.

Armor/silhouette detail, remaining relic volume/art review, final motion acceptance,
clean performance and installer validation remain open. Installed game/session
PID 62052 remains untouched; all tests used isolated saves. Publication/push/merge
remain held. Prior woven-relief evidence still describes the retained materials;
its payload hashes and recording precede these motion changes.

### Woven normal relief — current local evidence

Blender rebuilt and baked the current cloth's crossed-fiber bump into a fourth
2048px tangent-space normal map. `woven-relief-normal-data.log` records 215067
meaningful relief texels and no black texels. `woven-relief-motion-contract.log`
proves exact unchanged motion/anchor/contact data. Saved-source validation passes
156790 checks. Native comparisons capture 96 enabled and 96 disabled angle/pose
views; sampled matching rear/idle views were inspected.

The current exported payload passes 280038 motion checks, 1375 native feedback
checks and 1917 quality checks with zero failures/errors; all exit 0. Quality
checks include the enabled normal texture and skin tangents across High,
Balanced and Performance. Idle captures at all three presets, High impact and
Performance block were inspected; Performance retains visible aliasing with AA off.

`Executioner-Woven-Character-Review.mp4` contains ten exported relic sequences,
1591 decoded frames/53.03s at fixed simulation 30FPS. The recorder now stops
pending JPG saves before fixture cleanup; the final frame remains the battle,
with no terminal gray fixture frame to trim. All four one-second overview sheets
and three denser Twin Blades sheets were inspected. This is sampled visual review,
not every-frame approval or realtime performance evidence. Current hashes are in
`woven-relief-artifact-hashes.json` under the evidence directory.

The hero's armor/silhouette still look simpler than the enemy artwork. Further
weight/follow-through review, remaining relic volume/art work, clean FPS and
installer validation remain open. Installed session PID 62052 remains untouched;
all QA used isolated saves. Current media supersedes the older fitted recording
for materials only. Publication, push and merge remain held.

### Anatomical boots and cloth inertia — ongoing

Blender measurement in `boot-anatomy-fit.log` found a roughly 106mm-wide foot
inside a 196mm-wide boot section. Wardrobe version 6 uses narrower D-shaped
shoe sections, a shorter toe, an actual outsole and fitted straps/sabatons.
The sole is at -2mm rather than the former +18mm support-plane offset. Knee
plates are slimmer, taller and shallower (18mm central relief, formerly 32mm).
`Boot-Proportions-Before-After.png` compares otherwise unchanged native poses.
Sampled idle, side and impact views in `anatomical-boots-turns/` were inspected.

`anatomical-boots-dense-enclosure.log` checks actual strongly foot-weighted
vertices below the shoe collar: 342016 samples per foot across all 16 actions,
including takeoff/contact/recovery times, with no exposure beyond the 2mm
tolerance. This tests the shoe-covered foot, not the leg above the collar.
The original boot-only motion contract proves exact unchanged motion data.

The subsequent Blender motion pass increases free-hem inertia and adds a
delayed lower-cloak idle sway while keeping attachments firmer. Lower-cloak
melee rotation rises from about 4.68 to 7.22 degrees; idle rises from 0.51 to
1.37 degrees. `cloth-inertia-motion-contract.log` proves exact unchanged
non-garment bones/anchors, rest skeleton, all 16 durations/contact markers and
bounded garment joint steps. `cloth-inertia-painted-refresh.log` verifies exact
unchanged geometry/skin/rest while copying all 16 actions into the painted source.

Saved-source validation passes 156790 checks, coverage passes 2240 animated
mesh bounds samples. `cloth-inertia-turns/` contains 96 native views; sampled
rear impact/recovery views were inspected. The refreshed local payload's motion
check passes 280038 checks with zero failures. The complete catalog, fast/reduced
motion and recovery pass; native feedback passes 1378 checks with zero errors.
All three payload runs exit 0. `Executioner-Fitted-Character-Review.mp4` contains
ten current exported sequences including Twin Blades' two contacts; capture exits
0 and the video decodes all 1592 gameplay frames (53.07s at fixed simulation
30FPS). Raw capture has 1593 frames; only the terminal fixture-cleanup frame was
trimmed. All four one-second overview sheets and three denser five-samples/second
Twin sheets were inspected. This is sampled visual review, not every-frame
approval or measured FPS. Current source/payload/video hashes are in
`fitted-character-artifact-hashes.json`. Final character
acceptance, surface detail, remaining relic volume review, clean performance and
installer validation remain open. Publication/push/merge remain held.

### Woven drape and modeled hammer — current local pass

The cloak has broader gravity folds, shoulder gathering and sewn returns.
Woven hood/scarf/cape materials now use restrained metre-scale fibers rather
than projecting large illustrated highlights over the folds. The first noisy
drape attempt is retained in `drape-turns/`; the current native render is in
`woven-drape-turns/` (96 angle/pose views, including heavy recovery and rituals).
Sampled front, side, rear, impact and heavy-recovery views were inspected.
Armor tint is neutral and slightly lighter; authored metal/roughness maps remain.

`woven-drape-source-check.log` passes 156534 skin/pose/control checks;
`woven-drape-coverage.log` passes 2240 animated mesh samples. The motion contract
proves exact unchanged skeletal samples, anchors, durations and contact marks.

The equipped review exposed the artwork-derived hammer flattening at recovery.
It now has a modeled shaft, faceted molten cores, open octagonal rings and a
circumferential forged cage. Fully visible props now render opaque, preserving
their depth; reveal/fade stages retain alpha blending. The earlier alpha-only
mode painted internal shafts over outer surfaces. The source comparator proves
all non-hammer geometry/UV/skin, six rest bones and all 29 actions unchanged.
`volume-hammer-open-source.log` passes the catalog/skin and physical-depth checks.
`volume-hammer-depth-weapons/` contains 36 equipped views; sampled summon,
contact and recovery poses were inspected. `Hammer-Recovery-Before-After.png`
compares the exact same recovery pose before and after this correction.

The refreshed local payload passes motion (280038 checks/zero failures), complete
relic catalog including fast/reduced recovery, and native rendered feedback
(1633 checks/zero errors). See `woven-hammer-payload-*.log`. All three runs exit
0, using separate QA saves. `Executioner-Current-Character-Review.mp4` is the
fresh exported recording: nine real sequences, 1359 frames/45.30 seconds at
fixed simulation 30FPS, clean exit and full successful decode. All three
`Current-Character-Overview-*.png` sheets were inspected (sampled one-second
views, not every-frame approval or measured FPS). Current source/payload hashes
are in `woven-hammer-artifact-hashes.json`.

This is a local improvement, not final art acceptance. Cloth still needs finer
surface detail; armor/boots and animation transitions need further visual work.
Other relics still retain artwork-derived relief meshes and need the same volume
review. Clean FPS, final visual acceptance and installer validation remain open;
publication/push/merge remain held. The installed user session is untouched.

### Latest hood fit and Siphon allocation pass

- `hood-fit-build.log` and `hood-fit-material-bake.log`: rebuilt volumetric
  hood and freshly baked PBR maps; no silhouette image extrusion.
- `hood-fit-source-check.log`: 155010 saved skin/pose/control checks pass.
- `hood-fit-coverage.log`: closed, outward-facing shell and 2240 animated
  mesh bounds samples pass.
- `hood-fit-motion-contract.log`: rest skeleton and all 16 durations/contact
  markers unchanged. `hood-fit-motion.log`: 280038 native checks, zero failures.
- `hood-fit-turns.log`: 48 native angle/pose views; front/profile/rear/impact
  samples inspected. `Hood-Fit-Before-After.png` compares the previous and
  current native silhouettes.
- `persistent-tether-feedback.log`: native shader compilation and actual
  feedback pass, 1303 checks/zero errors. Complete catalog and fast/reduced
  recovery pass in `persistent-tether-catalog.log`; real transfer verifies one
  retained mesh resource and bounds including the live hand.

The ignored local payload is refreshed. `hood-fit-payload-motion.log` passes
280038 checks/zero failures; `hood-fit-payload-feedback.log` passes 1395 native
rendered feedback checks/zero errors, including shader compilation, independent
melee contacts, statuses, lifesteal and thorns ordering. Both processes exit 0
without shutdown warnings. Prior packaged movies are stale
for these two changes. Final art/motion approval, clean FPS and installer
validation remain open. The installed game session is still untouched.

### Sustained ritual motion and cropped character viewport — ongoing

- `ritual-life-source.log`: 155010 saved Blender skin/pose/control checks pass.
- `ritual-life-painted.log`: exact unchanged geometry/weights/rest verification,
  16 refreshed actions and retained PBR maps.
- `ritual-life-contract.log`: all durations/contact markers and rest bones
  unchanged; nine clips outside idle/ritual/siphon are unchanged.
- `ritual-life-motion.log`: 280038 native checks, zero failures, including
  continuing torso articulation during seven sustained actions.
- `cropped-quality-review.log`: 1899 checks, zero failures. New character
  budgets (1200x709, 900x532, 720x425) preserve five anchors relative to the
  former full-height projection. Separate relics keep original tall budgets
  and independent projection; held geometry retains the character's depth.
- `body-flow-performance-profile.log`: existing Performance preset, 584 wall
  frames, 32.11 FPS; invalid GPU aggregate discarded.
- `body-flow-render-isolation.log`: diagnostic character drawing disabled,
  skeleton/combat still running, 672 frames, 43.70 FPS. Disabled viewport
  measurements in this first diagnostic are stale; the fixture now excludes
  them from render measurements.
- `cropped-viewport-performance.log`: subsequent short diagnostic, 611 wall
  frames, 40.47 FPS, zero invalid GPU samples. Not a controlled improvement
  claim, complete-catalog benchmark or stable 60FPS result.

`ritual-life-catalog.log` passes the complete catalog, fast/reduced motion,
recovery and blocked-lifesteal checks. `ritual-life-film.log` completes all nine
signature/melee sequences; `Executioner-Sustained-Motion-Review.mp4` decodes
1359 frames/45.30s at fixed 30FPS. Three normal-scale overview sheets were
inspected, including full overhead bell/chalice and aligned Siphon endpoints.
This is sampled inspection, not every-frame visual acceptance or FPS proof.

An installed game process was discovered running concurrently (PID 62052,
`C:/Program Files/Overkill/Overkill.exe`, started 14:47). Today's short profiling
runs were not isolated and cannot establish clean frame pacing or the effect
of the viewport change. The installed session was not altered. A user request
to close it is pending; clean measurement requires verifying it has stopped.

The local current PCK/official-runtime payload is staged in
`.test-artifacts/047/proper-character/current-payload/`. Its native motion test
passes 280038 checks with zero failures in `ritual-life-payload-motion.log`.
Its verbose native feedback run passes 6416 checks with zero errors and no
object-leak warning (`ritual-life-payload-feedback.log`). The direct-frame
exported capture completes all nine sequences, exits cleanly and decodes every
1359 frames/45.30s in `Executioner-Payload-Review.mp4`; see
`ritual-life-payload-jpg.log` and `payload-video-decode.log`. Three exported
overview sheets were inspected. This is sampled visual verification, not final
human acceptance. `Preview Overkill.cmd` launches the local build with separate
saves under `.tools/042-audit-profile/047-character-preview/`.

The first built-in AVI recording reported an object-leak warning and produced
invalid JPEG packets. It is invalid media and is not the authoritative review.
The direct-frame replacement and verbose feedback run exit without that warning.
Installer, isolated performance and final art/motion acceptance remain open;
no publication or source-commit delivery claim is made.

### Continuous body mechanics — ongoing

The four melee actions now use time-aware cubic local rotations and pelvis
motion instead of easing to a stop at each intermediate key. A separate hip
drive pose precedes the cut, with a rearward preparation shift and forward
compression into impact. Feet are constrained after interpolation; the hammer
support hand remains constrained to its handle.

`body-flow-constraints.log` confirms unchanged rest bones, all 16 durations/contact
markers and the twelve non-melee actions. It checks 128 dense hammer hold
samples (maximum palm separation 0.00016m) and all melee local rotation steps
(largest 13.06 degrees). `body-flow-source-grip.log` passes 155010 saved-source
skin/pose/control checks. `body-flow-painted-grip.log` verifies exact geometry,
skin and rest skeleton while refreshing all 16 painted-source actions.
The initial native run exposed support-hand drift; a subsequent dense check
exposed an unreachable early grip and abrupt release. The corrected hold sits
closer to the chest, is enforced after filtering, and acquires/releases smoothly.
`body-flow-native-motion-grip.log` passes 280031 native checks with zero failures,
including the dense support grip, joint continuity, limb lengths, grounding,
native/source parity and actual weapon contact fitting. `body-flow-equipped.log`
passes 1845 checks and captures 36 equipped poses, including preparation, hip
drive and grip release. `body-flow-feedback.log` passes 6245 checks with zero
errors in real combat resolution: independent Twin Blades contacts, persistent
statuses, capped lifesteal, transfer timing and thorns ordering.

`body-flow-film-clean.log` completes four real relic sequences, including both
Twin Blades contacts. `Executioner-Body-Flow-Review.mp4` decodes all 761 frames
at 1280x720, fixed 30 FPS (25.37 seconds), verified by
`body-flow-video-decode-clean.log`. The diagnostic lifecycle row is hidden
without changing the stress assertions. Both `Body-Flow-Clean` overview sheets
were inspected, along with a dense Iron Strike sequence and enlarged actual
equipped preparation/contact/release views. This is sampled visual inspection,
not a claim that every video frame has been visually approved. Sampled
normal battle images keep held weapons inside the game frame. These captures
do not establish real-time FPS, final art acceptance or installer readiness.
The prior overhead recording below is superseded for the four changed melee actions.

### Raised chamber and two-handed hammer pass

- `overhead-source-validation.log`: 155010 saved Blender skin/pose checks,
  all 54177 source vertex coordinates unchanged, three packed maps retained.
- `overhead-motion-test.log`: 279908 checks, zero failures, through the native
  imported animation. Includes above-head chamber, hammer support palm within
  3cm of its handle target, planted feet, joint continuity and recovery.
- `overhead-equipped.log`: 1830 checks, zero failures, 21 equipped poses.
- `overhead-painted-controls.log`: 72 editable-control checks, zero failures.
- All 16 durations/contact markers and bind-bone records are unchanged;
  the 12 non-melee frame arrays remain byte-for-byte equal after JSON parsing.
  Changes are limited to the four melee actions and animation-refresh pipeline.
- `overhead-film.log` completes nine native signature/melee sequences.
  `Executioner-Overhead-Motion-Review.mp4` has 1359 decoded frames, 45.30 seconds
  at fixed 30 FPS. Sampled normal battle frames keep the raised sword in view;
  enlarged review framing is a separate fixture. This is visual evidence for
  the previous overhead pass, not real-time performance evidence.

Existing payload, installer and previous movies remain stale for these actions.

### Latest material and garment pass

The subsequent painted bake is now the live model loaded by the actor:
`executioner_painted.glb`. `painted-source-validation.log` passes 155010 skin
and pose checks and verifies all 54177 source vertex positions unchanged.
`painted-native-poses.log` provides 48 angle/pose views in
`painted-study-toned/`. The complete native catalog passes in
`painted-native-benchmark.log`: first run 3340 frames, mean 34.89 FPS,
p95 36.08ms; character eight draw calls, CPU 2.111ms, GPU 5.761ms.
This does not establish stable frame pacing or improved overall FPS. The
previous 43.14 FPS run is a different model/run and is not a controlled A/B.
The painted diffuse source came from built-in ImageGen; its prompt is
`three_d/source/painted_front_prompt_v1.txt`. Blender baked it into the actual
mesh's packed PBR maps. No new character silhouette, geometry or animation
was inferred from the picture. Exported-pack/installer checks remain stale.

- `painted-default-equipped.log`: normal game model path, 1830 native checks,
  zero failures, 21 actual equipped poses.
- `painted-quality-review.log`: 1899 checks, zero failures. High, Balanced and
  Performance preserve five character screen anchors, held grip depth and
  separate-relic screen/world alignment. Nine native comparison screenshots
  are under `quality/`. Performance intentionally reduces anti-aliasing/shadows.
- `painted-balanced-benchmark.log`: complete catalog and fast/reduced recovery
  pass; 3798 frames, 39.60 mean FPS, p95 34.35ms at 1920x1080. Discard its GPU
  timings: a wrapped timestamp contaminated that aggregate.
- `painted-balanced-profile-valid.log`: subsequent three-sequence diagnostic
  after profiler correction, zero invalid GPU samples; 568 frames, 35.67 mean
  FPS. It does not replace the complete-catalog test. No stable 60 FPS claim.

- `model-material-v3-sewn.log`: rebuilt editable Blender source and playable
  GLB; 28 source meshes, two runtime meshes, 63 bones and 16 actions.
- `validation-material-v3-sewn.log`: 155010 saved-source skin/pose checks,
  2240 deformation-bound samples, nine actual idle chest-clearance rays;
  closed, manifold cowl with outward-facing cloth thickness. Clearance rays
  establish the idle central chest fit only, not all animated intersections.
- `turns-material-v3-sewn.log` and `material-v3-sewn/`: 48 native angle/pose
  views from eight directions and six poses. The finer cloth, engraved armor,
  continuous cowl and smooth obsidian mask replace the previous material pass.
- `native-material-v3-equipped.log`: 1830 native checks, zero failures,
  21 actual equipped poses. This predates only the cowl seam topology repair.
- `native-material-v3-feedback.log`: 1763 checks, zero errors in real native
  combat; Twin Blades contacts, capped lifesteal, transfer timing, persistent
  statuses and thorns ordering. Current in-game captures are under the
  fixture's existing `.test-artifacts/046/feedback/` output directory.
- ImageGen used its built-in mode for the consumed atlas at
  `assets/characters/executioner/three_d/materials/executioner_surface_atlas_v3.png`;
  the exact prompt is `three_d/source/material_prompt_v3.txt`.
- The short `assessment-foreground.log` recording was deliberately stopped
  after Iron Strike for diagnosis. Its 298 frames demonstrate attack draw
  order only; it is not a complete animation review or performance benchmark.

Motion refinement, final frame pacing, exported payload verification and visual
acceptance remain open. Older installer/video evidence below is stale.

- `validation-weighted-landing.log`: 154942 saved Blender skin/pose checks;
  28 meshes, 63 joints, 16 actions; 2240 evaluated mesh bounds; 72 control checks.
- `motion-weighted-landing.log`: 199155 native checks, zero failures, including
  equipped blade direction, upright summon, left-hand recovery, active-foot
  leading, knee compression and stationary feet through follow-through.
- `turns-weighted-landing.log` and `turn-*.png`: 48 native angle/pose renders
  across a full turn. Hood, faceless mask, armor and boots retain volume.
- `native-benchmark.log`: complete relic catalog, fast/reduced motion and
  recovery pass; 3406 measured frames, mean 35.11 FPS, p95 39.49 ms at 1920x1080
  on Intel graphics. This is below the smoothness target. Profiling continues.
- `motion-native-lossless.log`: 279899 native motion/pose checks, zero failures
  after preserving 60 Hz animation keys and aligning the exported frame origin.
- `native-final-parity.log`: 1809 native skin/rest/grip checks, zero failures.
- `native-final-equipped.log`: 21 equipped poses, 1830 checks, zero failures;
  held weapons now use the character's actual depth buffer.
- `native-final-benchmark.log`: complete catalog and fast/reduced motion pass;
  4203 measured frames, 43.14 mean FPS, p95 32.82 ms. This predates the latest
  geometry-derived reach change and is not a stable 60 FPS claim.
- `native-feedback.log`: 2598 feedback checks, zero errors, before the final
  geometry-derived reach change. New battle recording and payload checks remain.
- `Executioner-Grip-Corrected.mp4`: diagnostic battle recording after the
  blade-direction correction, before the latest staggered landing and armor.
  The AVI conversion yields 679 decoded frames over 45.2 seconds; this is not
  real-time FPS evidence or a final review of the current asset.

The previous local 0.47 installer/pack and videos below are stale for this model.
No normal-save writes, source push, merge or publication occurred in this pass.
The previous recording shutdown ObjectDB warning remains tracked.

The candidate preserves the original hero and relic artwork on closed curved, skinned geometry. Single-view references constrain hidden surfaces; visual acceptance remains open. No publication was performed.

- Saved Blender hero: 230217 checks, 17 skinned meshes, 63 deform joints, 16 actions.
- Saved Blender relics: 445111 checks, 29 relics, 34 meshes, six prop joints.
- Editable Blender controls: 72 checks over four poses, connected hands/feet, no stretching, movable target.
- Native motion: 194250 checks, zero failures, limb lengths, flexion, pose continuity and grip parity.
- Native hero review: 1824 checks, zero failures.
- Forge/status/lifesteal feedback fixture: 6233 checks, zero errors. Clock smoke passed.
- Test-profile guard: rejected an unisolated dummy workspace profile with exit 1 before starting a run.
- Rendered nine-sequence review: `.test-artifacts/047/Overkill-047-Canonical-3D.mp4`.
- Canonical prop comparison: `.test-artifacts/047/canonical-relics-3d.png`.

Source evidence logs reside in `.test-artifacts/047/`. Counts can vary with frame sampling. Source validation does not establish visual quality or packaged performance.

## Save incident
An earlier fixture ran against the normal automatically saved playthrough slot. The current run and metadata were copied as evidence without replacing them. No exact earlier run backup was found. Project code/artwork are intact. Current QA fixtures refuse profiles outside disposable `.tools` or `.test-artifacts` directories; normal saves have not been reset or substituted.

Native pre-particle benchmark: 4095 frames, mean 41.47 FPS, p95 frame 38.29 ms on Intel Graphics / GL compatibility. This is below a stable 60 FPS target. Final particle and shadow changes require the subsequent packaged check.


Final source review includes short-lived cyan/amber crystal fragments, reduced-motion suppression, explicit transparent viewport clearing and a softened hero ground shadow. No persistent afterimage was observed in the new captured sequences; the user's reported preview artifact still needs visual confirmation.


Final exported Windows EXE/PCK: feedback fixture 6369 checks, zero errors, exit 0; native graphics skeleton/skin/grip review 1824 checks, zero failures, exit 0.


## Continued afterimage investigation
The user clarified the symptom is a separate full-body copy staying behind, not a dark contour. A controlled native renderer test moved the model 2.8m out of its old pixels: CHARACTER_RENDER_HISTORY remnants=0. Saved before/after alpha images and log are in .test-artifacts/047. The separate-copy report remains unresolved and requires a screenshot or clip of the exact artifact. Model backing surfaces were made plain with reduced rear depth; this fixes duplicated painted backing outlines but is not proof of resolving the separate-copy symptom. The existing installer/review movie precede this source-only geometry adjustment.

## Screenshot-guided silhouette correction (supersedes prior open diagnosis)
The supplied screenshot guided a mesh-layer comparison. Oversized untextured extrusion/backing and the anatomical construction torso contributed the apparent dark second silhouette. Hood and torso clothing now use 8mm/12mm curved shells; limb armor remains volumetric with restrained depth. Covered torso polygons use the existing invisible construction material, while limbs and articulated hands remain rendered. This is a model geometry/material correction, not a temporal render-history fix.

Final saved Blender validation: 230217 checks. Body coverage: 5776 covered torso polygons hidden, 3142 hand polygons remain visible. Fresh nine-sequence battle capture passed; final recording is `.test-artifacts/047/Overkill-047-Silhouette-Fix.mp4`, superseding older review clips for this correction. Native exported EXE skin/rest/socket review: 1824 checks, zero failures. The 0.47 local installer is rebuilt with these assets. User visual acceptance remains open; publication remains held.

Corrected exported EXE/PCK relic feedback: 6418 checks, zero errors, exit 0; native graphics review exit 0.


## Rotation separation repair (supersedes torso masking)
The prior masked-torso/thin-panel approach exposed gaps during turns. Final construction restores the continuous anatomical skin as a canonically textured garment around the torso and limbs. Stable relief armor stays attached over it. The hood is one closed, tapered volume with matte cloth side shading; separate hood-core and experimental nearest-joint transfers are excluded.

Source validation: 230217 skin/pose checks; 5744 visible torso faces and 3142 visible hand faces; 1360 evaluated mesh samples across all 16 actions stay bounded. Native front/45/90/135-degree captures are in rotation-coverage.png. Nine fresh real relic sequences passed; current recording is Overkill-047-Rotation-Fix.mp4. Exported relic feedback passed 5516 checks, zero errors. No normal save access occurred. Side/back artwork remains simplified; this is not final art acceptance.

The fast exported structural-only fixture logged four material-null errors when freeing actors before its first drawn frame. The source fixture now waits for frame_post_draw before freeing actors. Full live exported review is used to verify the rendered lifecycle, separately from those fast diagnostic logs.

Diagnostic follow-up: anatomy-only actors now skip unused wardrobe material overrides. The source native review passes 1824 checks with no material-null warnings. This is a review-fixture lifetime fix; production actors retain normal styling.


Final exported native review: 1824 checks, zero failures, exit 0, no renderer warnings (rotation-clean-payload.log). Final local installer compilation succeeded. Rotation-Fix recording and final hashes supersede earlier experiments.


### 2026-10-06 black hood backing correction (source only)
The prior rotation repair left wide near-black hood side walls, visible as a second silhouette. Reduced hood front/back depth and aperture recess; side walls now use the canonical hood texture rather than the plain unlit navy override. Native four-angle capture visually confirms the black backing is removed; side-view UV stretching remains an art limitation. Native movement-clear test: CHARACTER_RENDER_HISTORY remnants=0. Blender: ROTATION_COVERAGE_OK 1360 samples; EXECUTIONER_SAVED_SOURCE_OK 230217 checks, 17 meshes, 63 bones, 16 actions. Evidence: hood-backing-fixed.png, hood-backing-history.log, hood-backing-skin.log. Profiles isolated under .tools/047-hood-repair. Installer and previous video are older; no publication or normal-save writes.

## 2026-10-07 motion polish and rebuilt local candidate

This continuation supersedes the source-only installer status above. Branch
`feat/yonatan-046-relic-feedback` remains uncommitted and unpublished; base HEAD
is `fa915ef25a590ad01ecfdfc579bd12e5849b038a`. Public 0.45 is unchanged.

Melee recovery now spans the return movement, with bounded forearm pronation,
matching knee poles and finger relaxation. Cloth trails pelvis motion through
damped channels. The hood retains its original pointed front with a bowed
closed return, relaxed contour and cloth side shading; cuirass weights span
two spine joints. Detailed limb and boot silhouettes are retained after the
first smooth-shell experiment looked too bulky in native captures.

Current evidence is in `.test-artifacts/047/polish-20261007/`:

- `blender-final-validation.log`: saved-source parity and normalized skin,
  230217 checks; closed outward-facing hood; torso/hand coverage; 1360 evaluated
  mesh samples over all actions; 72 editable control checks. All sentinels pass.
- `motion-final.log`: 199068 checks, zero failures. Includes constant limb
  lengths, flexion/rotation bounds, planted support feet and near-neutral
  end-of-melee poses.
- `motion-comparison.json`: all 16 durations/contact markers and skeleton rest
  records unchanged. Iron Strike final wrist error from idle: 34.562 to 0.064
  degrees; mirrored strike: 34.562 to 0.063; Heavy: 6.313 to below 0.001.
- `native-turns-final.log` and `Turn-and-Action-Review.png`: 24 production-actor
  angle/pose views inspected at front, 45, 90 and 135 degrees.
- `native-movie.log`: nine real relic sequences passed damage, Block, lifesteal,
  timing and recovery assertions. `Overkill-047-Motion-Polish.mp4` is the current
  45-second battle preview. Reviewed frame sheet: `Relic-Motion-Contact-Sheet.png`.
- `047-polish-native-payload-clean.log`: exported EXE/PCK skin/rest/projected
  grip checks, 1824 checks, zero failures; full native action review exited 0.
  `Overkill-047-Exported-Motion-Closeup.mp4` is the 36-second exported review,
  with dressed and anatomical views. Its extracted pose sheet was inspected.
- `047-polish-feedback-payload.log`: exported production forge, twin contacts,
  reactive status, capped lifesteal, transfer timing and thorns fixture: 6417
  checks, zero errors, exit 0.
- `installer-build.log`: fresh local installer compiled successfully. Installer
  size 406784151 bytes, SHA-256
  `21be48392b93423856654638a8a4d764b127c011c9e5b0695710496faf72684a`.
  All source/payload/video sizes and digests are in `final-hashes.json`.

The first capture loaded an older cached GLB; it was rejected and Godot's editor
import was refreshed before final verification/export. The first exported
close-up fixture attempted PNG saves inside the read-only pack. Its assertions
passed but capture writes failed; the clean run uses external movie recording
and suppresses those internal PNG writes. AVI decoder field metadata stretched
the initial preview vertically; final MP4 files restore the native 1280x720
aspect and were inspected after encoding.

Review recordings still log the previously known ObjectDB shutdown warning;
clean final native review has no script/renderer errors. Fixed 30 FPS recording
does not establish real-time performance. The installer was compiled and its
exported runtime payload tested; the installation wizard was not reinstalled.
All runs used disposable `.tools/042-audit-profile/047-polish-*` profiles, with
no normal save writes. Side/rear hood and armor detail remain simplified;
enemies remain illustrated. Human visual acceptance and an all-screen release
gate remain open. No push, merge, tag or release was made.
