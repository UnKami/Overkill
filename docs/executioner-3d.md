# Executioner 3D pipeline — 0.47.0 local candidate

## Reference-fidelity refinement — 2026-10-08

Wardrobe version 9 adds the closed deeper hood, recessed mask, turned coat
lapels, longer curved coat panels and continuous greaves. Charcoal-teal woven
cloth, aged armor and warm undersuit materials use four 4K PBR maps plus an
isolated cloth-color atlas. Cloth has its own matte, non-emitting runtime
material. Atlas baking uses a disposable joined copy while preserving every
editable source mesh, coordinate and skin weight.

Idle now has planted weight transfer, opposing torso movement, watchful head
motion and relaxed fingers. Bypassing the causal filter only on this analytic
idle removes its loop discontinuity. All 15 active clips, all 16 durations and
contact markers, and the bind skeleton are unchanged.

See [current verification and remaining art gaps](verification-048-character.md).
Native and exported checks pass; the comparison remains a local art candidate,
not final illustration fidelity or a published gameplay release.

## Current production pass — 2026-10-07

### Forged armor borders and exposed chest relief

Wardrobe version 7 adds actual sloping brass chamfers around the shaped armor
plates. These replace round perimeter cords on pauldrons, hip/knee plates, palm
armor and the waist crest. Chest ornament follows the outermost overlapping
breastplate surface; the former fixed depth buried most of it under the plates.
The ornament shares the underlying plate's spine weights to stay seated in motion.

Brass/bronze retain their authored metal color through the material bake rather
than receiving the projected illustration. The four-map bake initializes unused
ORM texels to AO=1, roughness=1, metallic=0 so narrow cloth UV islands cannot
filter into an unintended mirror-like surface. Actual painted texels retain
their authored material channels. No bone, animation or contact data changes.

Current evidence is in `armor-matte-turns/`, `Armor-Relief-Before-After.png` and
`Executioner-Forged-Armor-Review.mp4`. Exported motion, preset and native-feedback
checks pass; verification scope and remaining gates are in `verification-047.md`.

### Melee weight transfer and leg articulation

The four Blender melee actions now use separate lead/trailing foot arcs and
ankle pitches, straighter knee tracking during compression, and smoothly
accelerated horizontal travel with unchanged total distance and phase markers.
Anticipation loads the legs before extension; impact compresses before the return.
Hammer support-hand release now retains these foot rotations and knee planes
instead of silently replanting them through the generic pose blend.

All 16 durations/contact marks and the rest skeleton remain identical; the 12
non-melee actions are exactly unchanged. Painted animation refresh verifies
identical geometry/weights/rest and retains all four material maps. These changes
are baked skeletal animation, with no added whole-image deformation.

Current native captures are in `weight-transfer-turns/`; the exported battle
recording is `Executioner-Weight-Transfer-Review.mp4`. See the verification
document for test scope and the remaining visual/performance/installer gates.

### Baked woven surface relief

The hood/scarf/cape's crossed-fiber bump is authored in Blender and baked into
a fourth 2048px tangent-space normal map. The painted runtime material retains
this map and the skin's tangent data across all three quality presets. Native
enabled/disabled comparisons use identical geometry, color and camera; the
effect is deliberately subtle at battle scale. Geometry, weights and all 16
actions/contact/anchor data remain unchanged in this material-only pass.

The current exported ten-sequence recording is
`Executioner-Woven-Character-Review.mp4`; verification and limits are recorded
in `verification-047.md`. This improves surface response, not final art acceptance.

### Anatomical boots and garment inertia

Wardrobe version 6 fits the boots around measured anatomical feet rather than
oversized rounded sections. D-shaped shoe sections retain a physical outsole,
shorter toe, fitted straps and sabatons; knee plates have lower relief. Dense
actual-skin enclosure sampling covers all 16 actions and exact movement markers.
`Boot-Proportions-Before-After.png` shows the native comparison.

The free lower cloak uses a softer damped response to body acceleration and a
delayed idle sway. Neck/hip attachments retain a firmer response. These are baked
Blender garment-bone channels. The non-garment skeleton, body/weapon anchors and
all action timings/contact marks remain exactly unchanged. The painted source's
animation refresh verifies identical static geometry, weights and rest skeleton
before retaining its baked materials and copying all 16 actions.

`cloth-inertia-turns/` captures the current native angles/poses. Current exported
checks and recording are tracked in `verification-047.md`; art acceptance and
performance/installer validation remain open.

### Woven drape and true hammer volume

Wardrobe version 5 adds broad cloak folds, shoulder gathering and sewn returns.
The hood/scarf/cape use restrained object-coordinate woven color at metre scale;
paint projection excludes those cloth materials so actual lighting describes
their folds. Geometry changes require the full character build and material bake.
All 16 character actions and contact/anchor data remain exactly unchanged.

The heavy hammer now uses modeled shaft, faceted twin molten cores, open
octagonal collars and a circumferential cage. Use
`build_relics_3d.py -- --replace-hammer` in Blender to replace only that relic in
the saved catalog while retaining other geometry and all actions. A full catalog
build also selects the modeled hammer. At full visibility, `Relic3DView` uses
opaque materials so internal surfaces cannot paint over outer cores. It retains
alpha blending during reveal and disappearance.

Current evidence is in `woven-drape-turns/`, `volume-hammer-depth-weapons/` and
`Hammer-Recovery-Before-After.png`. Exported motion, catalog and feedback checks
pass; see the current section in `verification-047.md`. This is not final art
approval. Other relics still use artwork-derived relief and require volume review.

### Hood proportion and persistent Siphon mesh

The hood shell is narrower and shorter in the latest geometry pass (radius
0.152m, height 0.360m), retaining its sewn return and recessed faceless mask.
Materials were fully rebaked from the new source rather than copying a stale
atlas. Saved-source skin/pose checks pass 155010 checks, closed-shell/coverage
validation passes 2240 animated bounds samples, and native motion passes
280038 checks with zero failures. `hood-fit-turns/` contains 48 native angle/pose
views; sampled front, profile, rear and impact views were inspected.

Siphon's tube now retains one indexed mesh (25 rings, 10 sides). The existing
Blender-authored extension/energy tracks control GPU vertex deformation using
the same curve, radius pulse and relic artwork coordinates. Live endpoint
bounds prevent shader displacement from being culled. The CPU no longer
constructs a SurfaceTool mesh or computes surface normals every frame.
The shader keeps the original diffuse/roughness/metal/emission treatment.
Godot's [spatial shader reference](https://docs.godotengine.org/en/4.5/tutorials/shaders/shader_reference/spatial_shader.html)
documents the vertex/normal mechanism used here.

`persistent-tether-feedback.log` passes 1303 native feedback checks with no
shader errors; `persistent-tether-catalog.log` passes the complete catalog,
fast/reduced motion and recovery, and verifies the mesh resource stays the same
through the actual transfer. `persistent-tether-native.png` shows the rendered
conduit and energy mass. This removes per-frame allocation work; clean FPS
evidence still requires the installed game session to close.

### Sustained body motion and viewport bounds

Idle now carries breathing through the spine, hips and resting hands. Chalice,
bell, crown, channel and block use distinct sustained hand/body poses with
small grounded breathing and weight shifts. Block fingers gradually close into
a brace and reopen on recovery. Siphon's tether hold retains a small body/palm
pulse rather than a frozen pose. These are baked Blender skeletal channels.
`ritual-life-contract.log` verifies the unchanged rest skeleton, all durations
and contact markers, and nine other clips. Saved-source validation passes
155010 checks; native motion validation passes 280038 checks, including seven
new sustained-torso articulation checks.

The character viewport crops unused vertical transparency: camera span 3.7m,
High 1200x709/4x AA, Balanced 900x532/2x AA, Performance 720x425/no AA. Width and
skin texel density are retained. Ritual/thrown overlays keep the original 4.7m
span and 1200x900, 900x675 or 720x540 budget; their independent projection keeps
tall effects aligned with the character. Held props still share its depth.
`cropped-quality-review.log` passes 1899 checks, comparing five anchors against
the previous full-height character projection as well as across presets.

Short diagnostic Performance runs measured 32.11 FPS before cropping, 43.70
with character drawing disabled and 40.47 with the cropped character target.
An installed game was subsequently found running alongside these QA processes.
These are not isolated runs, controlled improvement evidence or stable 60FPS
proof. The installed session is untouched; clean profiling waits for its closure.
The full catalog and nine-sequence source capture pass, with current sampled
visual evidence in `Executioner-Sustained-Motion-Review.mp4`. A local current
PCK/official-runtime payload passes 280038 native motion checks and 6416 verbose
feedback checks. Its direct-frame nine-sequence capture exits cleanly and is
verified in `Executioner-Payload-Review.mp4` (1359 decoded frames/45.30s).
The initial built-in AVI is invalid; use the MP4 made from direct JPEG frames.
Installer and final art/performance acceptance remain open. The ignored payload's
`Preview Overkill.cmd` uses a separate local save profile.

### Painted material bake

The live actor now loads `executioner_painted.glb`. The original sectional
`executioner.glb` remains the modeling and animation baseline. Build the base
with `build_executioner_3d.py`, then run `paint_executioner_materials.py` to
refresh the playable material bake and copy the same animations. The latter's
`--export-only` mode reexports its existing painted Blender source; it does not
pick up changes subsequently made to the unpainted source.

For animation-only changes, `--refresh-animation` verifies every source vertex,
skin weight and bind-bone matrix against the painted source before copying all
16 clips. It preserves the baked maps and editable control drivers. All
copied actions explicitly retain fake users so inactive clips survive saving.

The built-in ImageGen tool supplied an aligned painted surface source in
`materials/executioner_painted_front_v1.png`; the exact prompt is
`source/painted_front_prompt_v1.txt`. This is applied to visible neutral-pose
surfaces by UV projection and Blender baking, never used as silhouette geometry.
Occluded surfaces retain their existing materials. A shared UV atlas packs
diffuse color, roughness/metal and crystal emission into three 2048px maps;
a fourth 2048px tangent-space normal map retains the authored woven relief.
The editable source retains the original and projected UVs; runtime export
contains only the baked UV set. Its two meshes have three material surfaces.

`painted-source-validation.log` proves all 54177 source vertex coordinates
unchanged, 155010 skin/pose checks passing, normalized weights and the same
63 bones and 16 actions. `painted-native-poses.log` captures eight directions
across six poses using the toned material. `painted-native-benchmark.log`
passes the complete relic catalog, damage/block/lifesteal and fast/reduced
motion recovery. Its first run averaged 34.89 FPS over 3340 frames, p95 36.08ms;
character submission fell to eight draw calls, but frame pacing remains open.
These source results are not final art acceptance or exported installer proof.

The existing quality control applies to character and separate relic viewports;
the latest cropped/full-height budgets are listed above. Performance disables
character self-shadow. All preserve their world-to-screen anchors.
Held props continue to share the character's depth buffer. Settings changes
apply immediately. `painted-quality-review.log` passes 1899 checks, including
five fixed screen anchors and separate-prop projection across all three modes.
`painted-default-equipped.log` passes 1830 native checks and 21 equipped poses.

The full Balanced catalog run measured 3798 frames, mean 39.60 FPS and p95
34.35ms. Its GPU timer was invalid and must not be used; wall-clock frame
intervals remain recorded. The profiler now rejects wrapped/invalid GPU values
and starts character measurement after sizing the viewport. The following
three-sequence diagnostic reports zero invalid GPU samples; it is not another
full-catalog benchmark or a stable-FPS claim. Frame pacing remains unfinished.

The panel-derived wardrobe is superseded by `executioner_tailored_wardrobe.py`.
The editable character has 28 skinned mesh batches and 63 deformation joints.
The unpainted export combines its wardrobe into two meshes, retaining 14 material
surfaces, one shared skin, all geometry, UVs and joint weights.
The hood is an open, sewn shell around a recessed faceless mask; the cloak,
scarf, cuirass, shoulder lames, vambraces, split coat and armored boots have
modeled sections and returns. No character silhouette is extruded from an
alpha mask. Neutral fitted geometry is transformed back into the bind pose.
The human face under the mask is concealed, including rear-quarter views.

Melee actions now use authored sword mechanics: upright summon, overhead
chamber, hip-led cut, blade facing the enemy, staggered landing, knee
compression, planted follow-through and cushioned return. The right and left
hands use mirrored palm frames. `weapon_world()` is shared by displayed props
and contact fitting; a bone-only test previously missed a reversed blade.
Existing action lengths and contact markers remain unchanged. Recorded toss
motion remains the basis for throws. Cloak motion uses bounded damped channels
driven by movement, with native finger and foot articulation.

The current melee pass raises the chamber hand beside/above the head, extends
the sword arm into contact, and counterbalances with the other arm. Heavy Hammer
uses two palms on its handle from the summon through the strike. It keeps its
contact reach closer to the body so the second arm stays within anatomical
limits. `overhead-motion-test.log` passes 279908 native checks, including the
new chamber and support-grip requirements. Twelve other action sample arrays,
all 16 action durations/contact markers and the entire bind skeleton remain
identical to the prior pass. `overhead-equipped.log` passes 1830 checks and
21 actual equipped poses. `overhead-painted-controls.log` passes 72 editable
control checks. These do not replace real-time motion and payload review.

The subsequent body-flow pass replaces per-key smoothstep stops with time-aware
cubic local quaternion/pelvis curves. Quaternion hemispheres are aligned and
rotations normalized; support ankles are replanted after interpolation. Hip
drive precedes the cut, with a rearward preparation shift and forward impact
compression. Original durations/contact markers and twelve non-melee clips
remain unchanged. Hammer grip fitting runs after the rotation filter, rebuilds
its twist/finger descendants, and fades into/out of the support constraint.
The hold sits closer to the chest so both arms can reach without stretching.
`body-flow-constraints.log` verifies 128 dense hold samples and bounded local
rotation steps. `body-flow-native-motion-grip.log` passes 280031 native checks,
including dense handle contact; `body-flow-equipped.log` passes 1845 checks and
36 equipped captures. `body-flow-feedback.log` passes 6245 real-resolution
checks. A fresh four-relic battle recording includes both Twin Blades contacts.
Final continuous visual acceptance, real-time performance and exported payload
evidence remain open; the preceding overhead recording is older.

Normal playback now uses the imported Godot `AnimationPlayer` tracks. Import
sampling is 60 Hz and animation key optimization is disabled on this character,
because its defaults changed planted feet and small body movement. Blender frame
1 corresponds to combat time zero, recorded as `native_time_origin` in the
matching sample data. Reduced motion retains the existing quarter-amplitude
sampler. Native bones are compared against the Blender samples across all
actions. Held weapons share the character's depth buffer and lighting, allowing
the fingers to occlude the hilt. Thrown props retain an overlay pass for visible
contact with illustrated enemies. Approach fitting uses the held mesh's actual
support point; every cue releases its geometry and external model instance.

The diffuse material atlas was generated with the built-in ImageGen tool:
`assets/characters/executioner/three_d/materials/executioner_surface_atlas_v3.png`.
Its exact prompt is saved in `source/material_prompt_v3.txt`. It contains cloth,
leather and etched metal swatches, not a replacement character picture. Geometry,
weights, animation and lighting are authored in Blender/Godot. The generated
atlas is a visual source asset and has no gameplay logic.

The current material pass replaces the coarse grain with finer cloth and
engraved bronze ornament. The cowl is now one folded, closed cloth shell with
a shared seam instead of four separate tubular rings. The cuirass is fitted
outside the undersuit, and the narrow breastplates sample narrow atlas regions
to preserve the proportions of their engraving. The mask has a smoother
obsidian surface and additional fine veins; the hood has a deeper brow.
No action duration, contact marker or combat rule changed in this material pass.

Current material source validation is `validation-material-v3-sewn.log`:
155010 skin/pose checks, 2240 deformation-bound samples, nine idle chest
clearance rays and a manifold, outward-facing cowl pass. Native turn images
are in `material-v3-sewn/` (eight angles, six sampled poses). The equipped
review `native-material-v3-equipped.log` passes 1830 checks and 21 poses;
it precedes only the cowl seam topology correction. These are source review
results, not exported-payload or final visual approval.

Current evidence is in `.test-artifacts/047/proper-character/`:
154942 saved-source checks, 2240 evaluated mesh samples, 72 editable-control
checks, 279899 native motion/pose checks, and 48 rendered angle/pose views pass.
Native skin/grip review passes 1809 checks and 21 equipped poses pass 1830 checks.
The complete relic catalog passes in the native source game. The first native
1920x1080 benchmark averaged 35.11 FPS on Intel graphics, with a 39.49 ms p95
frame interval. After batching, shared weapon depth and native playback, the
complete run averaged 43.14 FPS over 4203 frames, with a 32.82 ms p95 frame
interval. This does not establish stable 60 FPS. The latest changes to physical
weapon reach still require the final battle recording and exported-payload
checks. These structural
checks do not establish final art acceptance or stable 60 FPS.

The local installer and exported pack from the previous continuation are stale
for this replacement. Publication, push and merge remain held. Normal saves
are not used by QA. Historical evidence below describes earlier models and
must not be treated as verification of this production pass.

## Source and runtime

- `scripts/art/build_executioner_3d.py`: fitted 1.91 m human topology, 63 deform
  joints, 28 skinned volume meshes, normalized four-influence weights and 16
  actions sampled at 60 Hz. Armor, hood, mask, trim, crystals and cloak are
  authored sectional geometry with material swatches and modeled relief.
  Neutral-pose fitting is inverted into the bind pose to keep garments aligned after skinning.
- `assets/characters/executioner/three_d/source/executioner_human_3d.blend`:
  editable source. `Executioner_Animator_Controls` is hidden by default; run its
  embedded `ALIGN_CONTROLS.py` at the desired frame to enable editing. Set the
  deform rig's `controls_enabled` to zero to restore baked motion. Hand/foot
  targets and elbow/knee poles use two-joint IK with stretching disabled.
- `executioner.glb` contains the actual skin, joints, materials and animation
  tracks. `motion_data.gd` contains matching full parent-relative transforms;
  Godot's Skeleton3D poses use full local transforms, not rest-relative deltas.
  Root coordinates convert once from Blender Z-up to Godot Y-up.
- `scripts/art/build_relics_3d.py` creates 29 volumetric relics, 34 skinned
  meshes and a six-joint root/prop/secondary/flow/aura/tether skeleton. Its saved
  source is `assets/animations/relics/three_d/source/relics_3d.blend`.
- `executioner_3d_actor.gd` renders the real skin in a transparent 3D viewport.
  `relic_3d_view.gd` renders matching-camera prop geometry above both battle
  actors. Melee uses full 3D palm transforms; thrown props and rituals use the
  existing timing contract. Siphon tube and energy are runtime geometry driven
  by the exported prop tracks. Aura includes a real light on the character.

The main character and relics are 3D. Background and enemies remain illustrated.
An illustrated enemy has no 3D collision surface; impact fitting uses its visible
chest anchor. Gameplay math and save schemas are unchanged. An earlier QA fixture wrote to the normal run slot; no exact pre-test copy has been recovered. Current QA scenes require an isolated profile.

These meshes prioritize the established battle-camera silhouette. Hidden surfaces are approximated from single-view artwork; this is not a complete hand-sculpted 360-degree character production. Visual acceptance remains open.

## Provenance

Human mesh, initial joint landmarks, skin weights and averaged adult male macro
morphs come from the official MakeHuman repository's CC0 asset data:
https://github.com/makehumancommunity/makehuman/tree/master/makehuman/data
License: https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.ASSETS.md
The bundled `source/vendor/MAKEHUMAN-LICENSE.txt` preserves that asset license;
MakeHuman application code is not included in the game.

Recorded strokes come from Carnegie Mellon's free-for-all-uses motion database:
https://mocap.cs.cmu.edu/ . Used clips are subject 02 trial 05 (strike), subject
124 trial 07 (swing), and subject 124 trial 12 (underhand toss). Original ASF/AMC
data and a reproducible importer are retained under `source/vendor/`. Retiming,
anatomical fitting, torso distribution, grip/fingers, summon, foot planting,
launch, return and ritual poses are authored for this character. Source-only
vendor files and Blender files are excluded from the packaged game by `.gdignore`.

## Validation scope

`validate_executioner_3d.py` audits the saved Blender file: 230,217 checks cover
skin bindings, normalized weights, all action local transforms and the presence
of editable IK controls. `motion_quality_test.tscn` checks every 60 Hz frame:
199,068 checks pass for constant limb lengths, bounded knee/elbow flexion,
planted support feet, end-of-melee recovery and wrist speed below 12 m/s.
The speed bound catches discontinuities; it is not a
claim that every fast strike is aesthetically ideal. Blender IK controls are an
editing aid; final runtime motion uses the tested baked poses.

Native close-up rest/skin/grip checks, full relic outcomes, forge/status/lifesteal
regression, Windows payload checks and rendered review evidence are recorded in
`.test-artifacts/047/`. Test scenes automate verification only and add no player
autoplay. The rendered motion needs human visual acceptance; technical checks
cannot establish perfect human motion or cinematic quality. Native review exits
may report ObjectDB resources remaining at shutdown; this is tracked separately
from gameplay outcome and skin checks.


The screenshot-guided silhouette revision masks the covered anatomical torso, retains articulated hands, uses thin curved shells for hood/torso cloth and restrained depth for volumetric limb armor. See verification-047.md and the newer Silhouette-Fix recording.


Rotation correction supersedes covered-torso masking: the anatomical skin now forms a continuous canonically textured garment, with opaque torso/limbs and a closed tapered hood. Stable relief armor remains attached over that surface. Side/oblique views and all-action deformation bounds are reviewed; no source bitmap is modified.


The final hood is one tapered closed volume with matte cloth side shading. No separate hood-core mesh or nearest-joint transfer experiment is included. The continuous garment uses the existing normalized anatomical skin; armor details retain their stable attachment.

### 2026-10-07 motion and wardrobe continuation

The melee upper body starts settling at 2.58 seconds (2.68 for Heavy), during
the return flight. Pronation stays within 90 degrees and eases off before the
end of the clip; fingers relax into idle. The return knee poles match the
neutral stance. Small breathing motion keeps the 1.5-second sword summon hold
alive without moving the support ankles. The cloak and tassets use damped
rotation driven by pelvis acceleration and velocity, with smaller seamless
idle sway. These channels are baked in Blender and exported with the skin.

The pointed hood front follows the existing reference silhouette over a bowed,
closed cloth volume. Its pixel-contour steps are relaxed before export; side
and rear faces use cloth shading. The cuirass distributes skin weights between
the middle and upper spine. Generic capsule armor was rejected during native
review; the detailed canonical limb and boot silhouettes are retained.

All 16 action durations and contact markers, skeleton rest transforms, gameplay
rules and save formats remain unchanged. The measured final sword-wrist
rotation difference from neutral went from 34.562 degrees to 0.064 degrees for
Iron Strike and 0.063 for the mirrored strike. This measures recovery, not
overall animation quality. See verification-047.md for current payload evidence.


