# Sentinel production checkpoint

## Objective and acceptance

The goal remains a cinematic, readable, polished 3D game in the approved dark fantasy direction: worn metal, dramatic lighting, restrained effects. The current work is not AAA completion. Passing a mechanics test does not establish art quality.

| Area | Evidence required for acceptance | Current state |
|---|---|---|
| Character production | Distinct authored models and material response for the full enemy roster; readable silhouettes at battle size; close-up topology/normal/skin review | New Sentinel body candidate; other enemies and hero still require production work |
| Animation | Intent, anticipation, contact, recoil, guard, recovery and death coherent through entire fights; variety appropriate to each enemy; no sliding or weapon misses | Shared five-clip rig with Sentinel-specific guard and recoil; contact tests pass, full-fight motion variety remains unfinished |
| Material detail | Correct scale, convincing forged edges, cavities, wear and roughness under multiple lighting conditions | Sentinel now has geometry-authored edge wear and baked local cavity visibility; unique textures and broader material polish incomplete |
| Environment and staging | Cohesive finished arena composition, character separation, no UI obstruction at supported aspect ratios | Cathedral arena prototype with authored lighting; breadth and detail incomplete |
| Information and control | Readable 720p/1080p UI, keyboard/mouse parity, exact placement and outcome previews, staged reveals, no obscured choices | Existing 0.17/0.18 coverage; fresh broad visual audit still required |
| Sound and feel | Listened-to mix; distinct cues synchronized to actual events; clear levels, no fatigue or clipping | Event integration and waveform tests; listening review incomplete |
| Performance | Stable frame pacing through full fights on declared target hardware and quality levels, including impact and transition peaks | Intel profiling shows remaining frame-time spikes; no 60 fps acceptance |
| Gameplay and delivery | Human-reviewed pacing/balance, full run and transition verification, accessible controls, reliable installer/release/update log | 0.18 verified playtest remains published; boss balance and broad run validation incomplete |

## Current candidate

- `scripts/art/build_sentinel.py` authors a new clockwork body with recessed chest mechanism, grille helm, curved layered pauldrons, covered joints, articulated fingers, split tabard and overlapping sabatons. It retains the existing licensed skeleton and five authored clips, but no source knight mesh geometry.
- Four material surfaces in one skinned body; equipment and cloak remain separate. The model is reproducible from the checked-in Executioner production skeleton.
- Guard staging turns the chest toward the camera; the body turns into the hammer attack and returns during recovery. Contact must be checked for both actors, both speeds and reduced motion.
- `sentinel_production_test` checks the new body/skin, material surfaces, weapon contact, recovery, particle cleanup and rendered framing. The older silhouette test now explicitly exercises the modular Bulwark assembly.

## Profiling evidence

Local Intel Graphics, OpenGL compatibility, 1920x1080 window. Short diagnostic samples, not release benchmarks:

- 0.18 scene: 467 draws; median approximately 39 ms with VSync. Hiding UI reduced the scene to 217 draws. Disabling shadows alone made only a small frame-time difference.
- New Sentinel candidate: 395 draws for the complete battle; 145 for the stage without UI. This is a measured draw-count reduction, not proof of proportionate speedup.
- With VSync disabled, a short sample measured about 23.5 ms median for the candidate battle, with substantial p95 spikes. Stage-only at 1200 pixels measured about 16.7 ms median but also spiked. Do not publish a stable FPS claim from these samples.

- Static clock engravings are now rendered into a cache refreshed on size/color change. The later full-battle draw count is 371. This reduces drawing work while keeping active indicators live; measured frame time remains roughly 39 ms with VSync, so frame pacing is still unresolved.

Next: inspect and refine the candidate silhouette/materials, validate the new body turn, measure longer warmed-up fights, isolate UI and animation costs, then continue roster and animation production. Keep the current verified 0.18 installer until a broader release candidate passes its gates.

## Source and cache behavior

The shared skeleton provenance is documented in `docs/directed-encounter-delivery.md` (crownjoshua CC0 knight). Sentinel body geometry in this pass is original procedural modeling; no knight body mesh is retained.

The engraving regression checks rendered pixels: changing a cached canvas item alone must not redraw the texture, while a faction-color invalidation must update it. This checks behavior instead of assuming the node getter mirrors the rendering server's one-shot state. Godot 4.5's [SubViewport implementation](https://github.com/godotengine/godot/blob/4.5/scene/main/viewport.cpp) retains the configured update mode in the node getter.

## Material authoring checkpoint

- Added a Sentinel-only material with darker rough plate faces, cleaner exposed bevels, per-part patina variation and baked short-range cavity visibility. It keeps four surfaces and the existing three detail-texture samples per metal fragment.
- Wear derives from actual bevel faces. Cavity visibility is baked with 16 hemisphere rays per vertex over an 8 cm radius, stored in the spare vertex-color channel. This is local rest-pose shading, not dynamic ambient occlusion or a complete texture-authoring pass.
- Explicitly export Blender's active color attribute. The default material-driven export produced a uniform mask in Godot; the new regression checks imported channel ranges so that failure cannot silently recur.
- Recalculate mirrored panel face orientation before beveling and baking.
- Model inspection includes cool and warm directional light close-ups, plus the existing 1080p/720p battle, cache invalidation, skinning and contact checks. Captures/logs: `.tools/020-*` locally. The drawing budget remains 371 for the full test battle; this pass does not establish a frame-rate improvement.
- Art review remains open: helmet/shoulder proportions, broad plain surfaces, hammer/body material consistency, bespoke engraving and richer animation still fall short of the target. Do not call this model AAA-ready based on the mask or contact tests.

## Heavy attack cadence checkpoint

- Sentinel timing now maps the source attack's anticipation, strike, contact and recovery into a longer heavy cadence: contact at 0.46 seconds, settled recovery at 1.08 seconds. Hero contact stays 0.32 seconds, with recovery at 0.76 seconds. Fast mode scales both through the existing animation-speed setting.
- The retimed animation library is private to the Sentinel; imported shared clips are not mutated. Weapon direction, body turn, root weight shift and trail use the inverse phase mapping, keeping the contact pose aligned with the longer clip.
- Controller sound delay and stage recovery follow the active actor's timing. The hammer trail now ends at the hammer head rather than a sword-length tip. Animation-name results are cached and timing tables are constants, avoiding new per-frame array allocation.
- Validation checks separate hero/enemy clip lengths, increasing key times, anticipation before the heavy contact point, weapon reach and recovery in normal/fast modes; damage accounting across normal/fast/reduced motion remains covered. Rendered pose captures accompany the numeric tests.
- This is cadence differentiation using the existing authored attack poses, not a new motion-captured performance or broad attack animation library. Unique heavy poses, attack alternatives, guard reactions and death production remain unfinished.

## Braced guard and visual target

- Authored a Sentinel-specific guard action: forward torso brace, off-hand protecting the clock core, guarded weapon arm, a short hold and controlled release. It preserves the existing foot placement and idle pose.
- Rendered tests check a visible off-hand displacement, planted supporting foot and recovery after consecutive blocked hits. Normal/fast/reduced-motion damage regressions remain covered. Capture: `.tools/022-render/Godot/app_userdata/Overkill/sentinel-019/sentinel-guard.png`.
- A new generated modeling reference is stored at `art_source/concepts/sentinel-target-v1.png`; its exact built-in imagegen prompt and critique are in the sibling Markdown file. It establishes a materially stronger target than the current blockout. It is not a 3D game render or proof of achieved quality.
- Next modeling work should adopt curved layered armor, a recessed helm/gorget, covered joints and articulated lower-leg armor while preserving the real model's nine clock marks. The generated clock-face marks are not mechanically authoritative. Avoid expanding the current blocky robot construction across the roster before closing this larger visual gap.

## Curved armor construction checkpoint

- Replaced rectangular shoulder stacks with curved overlapping shells, rolled bronze lips and restrained fasteners. Forearm and shin housings now have tapered oval sections and shallow longitudinal fluting.
- Darkened exposed joint coverings; added pointed knee plates and four overlapping arched courses per boot, replacing rectangular feet.
- Replaced the broad brow/horns with a central forged crest and vertical grille; narrowed the light behind it. A folded split tabard is skinned between hips and thighs without covering the chest clock. This is skinned cloth geometry, not cloth simulation.
- Source remains reproducible and the exported body retains four material surfaces. Geometry increased from 17,062 to 30,322 Blender vertices; this is a real cost even though battle draw count remains unchanged. Optimization/LOD and longer frame-pacing review remain necessary.
- Visual acceptance remains open: the character still has broad simple forms, generic surface detail and limited motion variety. The hammer and arena architecture remain noticeably less refined than the modeling target. The generated reference has not been matched.

- Final validation: rendered SENTINEL_GUARD_OK / SENTINEL_PRODUCTION_OK and headless CINEMATIC_FINISH_OK, with no script/assertion errors. Reviewed cool-light close-up, guard and compact framing; fixed the visible open boot ends before final export. Local evidence `.tools/023-final-*` and `.tools/023-damage.log`.

## Cathedral staging checkpoint

- Replaced smooth metal-banded columns with moulded stone bases, bundled shafts, stepped capitals and pointed arcade ribs. A separate `CathedralArchitecture` component builds two meshes once and instances eight piers/four ribs; no geometry generation occurs per frame.
- Reused the existing licensed stone textures with world-aligned projection on the architecture. Reworked the previously unused arena-stone shader for a matte, lower-contrast floor and dais; darkened the brazier stands to keep emphasis on characters and lights.
- Corrected the stage's stale twelve-hour floor decoration to nine major marks and 27 subdivisions. Live gameplay clock rules are unchanged.
- This improves environment coherence but does not finish environment art: braziers remain simple, the distant architecture is still a painted plane, contact shadows are hard and the architecture needs bespoke wear/debris/material transitions. Continue judging rendered composition, not just draw counts.

- Validation: CATHEDRAL_STAGE_OK, SENTINEL_GUARD_OK and SENTINEL_PRODUCTION_OK; final 1080p/720p captures inspected. Two architecture batches and 371 full-battle draws retained. Short Intel sample median 46 ms / p95 50 ms is diagnostic only. Evidence `.tools/024-balanced-render/` and `.tools/024-balanced-render.log`.

## Render isolation and rigid weapon batching

- Added `scenes/arena_profile.tscn`: a rendered diagnostic with VSync disabled, monotonic wall-clock samples, two-second phase warmups and eight-second sample windows. It separates full battle, stage only, UI with frozen stage, frozen actors, smaller stage resolution and disabled MSAA, then repeats the full scene. It reports medians/p95/p99 and stage CPU/GPU timing. Frozen viewport timing is reported as null because its counters are stale. `-- --arena-profile-short` repeats full/stage/full for comparison.
- Initial Intel Graphics / GL compatibility isolation at 1920x1080 (1600x813 3D viewport) measured full-scene median 19-21 ms with p95 62-69 ms; frozen-actor median 19 ms; frozen-stage UI median 9 ms with p95 14 ms. Lower resolution and disabled MSAA reduced median but did not remove spikes. These are idle decision-scene diagnostics, not full-fight or target-hardware acceptance. Default resolution and MSAA remain unchanged.
- Combined rigid sword/hammer pieces into one mesh per material, preserving four weapon finishes. Fixed the shared batching helper to normalize indexed/non-indexed source geometry before concatenating and re-index afterward. The first candidate dropped the authored hammer head; its profile was rejected. A regression fixture now proves twelve box triangles plus one authored triangle and its translated placement all survive.
- Final rendered capture confirms the hammer head and blade remain present; contact/recovery, guard, material and compact-framing tests pass. Full battle draw count falls from 371 to 351. This is a verified draw-count reduction, not proof of a stable frame-rate gain.

- Corrected post-batch profile: full median 20.7-21.4 ms / p95 65-70 ms; stage-only median 18.1 ms, 125 draws. This overlaps the earlier range and does not demonstrate a speedup. Evidence `.tools/025-profile.log`, `.tools/025-fixed-profile.log`, `.tools/025-fixed-render/`. Never cite the discarded `.tools/025-batch-profile.log` as a valid comparison.

## Distinct impact reaction checkpoint

- Authored a Sentinel-specific unguarded hit clip: rapid backward torso recoil with off-axis chest/head turn, opened arms, a short settling hold and controlled return. Guard remains a forward protective brace, giving blocked and damaging outcomes opposite readable body responses.
- Preserved the existing pelvis/leg stance and half-second hit duration. This adds authored reaction poses to the actual skinned 3D model; damage rules, clocks and production render defaults are unchanged.
- Guard and hit now share one explicit reaction-authoring helper in the reproducible Blender build. The exported body retains 30,322 vertices and four surfaces.
- Remaining motion work includes heavy attack pose variety, authored death/finish behavior, fuller weight transfer and complete-fight pacing review. One distinct reaction is not a complete animation-production pass.

- Validation: rendered SENTINEL_RECOIL_OK proves opposite head-displacement directions for brace/recoil, visible recoil, supporting-foot stability and guard-to-hit interruption recovery at normal/fast speed. Guard/recoil captures inspected side by side. CINEMATIC_FINISH_OK retains damage checks through normal/fast/reduced-motion combinations. Evidence `.tools/026-render/` and `.tools/026-damage.log`; pose captures remain actor fixtures rather than a full live battle sequence.

## Defeat state and handoff checkpoint

- A rendered lethal-action review found stale placement guidance and enemy-next-action text surviving the fight. Finish now clears placement/quadrant/hour highlights and locks clock interaction; the enemy readout becomes DEFEATED or BATTLE OVER and stays terminal if guidance refreshes.
- Defeated characters' private emissive materials fade to dark over 0.48 seconds (scaled in fast mode). The survivor's materials are unchanged. The stage ignores late impacts and duplicate finish requests, avoiding new effects or conflicting outcomes after death.
- `finish_sequence_test.tscn` uses real lethal-damage and controller end-check paths for all eight win/loss, normal/fast, normal/reduced-motion combinations. It verifies no early result signal, exactly one correct result signal, terminal actor state, quiet guidance, isolated power-down and reduced-motion camera stability. Captures show the actual finish presentation, though the fixture sets up one-HP targets rather than playing a full run.
- The result event is verified; a complete reward-screen/run transition still needs separate full-run coverage. Existing death poses remain shared animation work, not a newly authored bespoke death performance. Local evidence `.tools/027-final-render/` and `.tools/027-final-render.log`.

## Gravity-aware cloak checkpoint

- Replaced purely rigid cloak rotation with a world-space drape approximation. The shoulder seam stays attached; lower cloth progressively hangs toward gravity, with a ground constraint allowing the kneeling hem to gather behind the feet. This removes the conspicuous board-like cape projection in victory/defeat poses.
- Recompute surface normals from the deformed parametric surface so lighting follows the bend. Added culling margin for the shader displacement, restrained flutter and distance filtering for fine weave. Reduced-motion mode still disables flutter while preserving the pose-dependent drape.
- The shader surface matches `RiggedCombatant._build_cloak` UV parameterization; keep those dimensions coordinated. This is not a full cloth solver: inertia, body collision and self-collision remain absent. Full animation/environment acceptance still requires broader review.

- Validation: rendered FINISH_SEQUENCE_OK across eight outcome/speed/motion combinations, plus SENTINEL_PRODUCTION_OK / SENTINEL_RECOIL_OK. Victory, defeat and windup captures inspected. Draw count remains 351; short sample about 44 ms median with VSync, not a performance acceptance claim. Fixed shader compilation by passing the per-instance model transform explicitly into the helper. Final evidence `.tools/028-fixed-finish/`, `.tools/028-motion/` and matching logs.
