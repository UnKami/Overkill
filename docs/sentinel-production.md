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

## Forged weapon material checkpoint

- Removed bright additive speckle from the shared forged-metal response. Scanned detail now contributes mainly to roughness with restrained albedo variation and stable metalness. Darkened weapon steel and brass to sit closer to the approved armor palette while retaining brighter blade bevels.
- Rebuilt the execution blade's broad face around a longitudinal ridge, preserving its outline and contact reach. Raised the existing inlays above that ridge. Separated broad-face/bevel normals so the hammer no longer shows artificial diagonal smoothing gradients across flat planes.
- This affects shared forged equipment/hero armor as well as the weapons; the Sentinel body's authored wear/cavity material remains separate. Four finishes per weapon and existing rigid batching are retained. Hand-painted damage, engraving, leather-wrap detail and final close-up production still remain open.

- Validation: rendered SENTINEL_PRODUCTION_OK / WEAPON_BATCH_OK / SENTINEL_RECOIL_OK plus modular SILHOUETTE_OK. Reviewed battle framing and warm-light close-up; broad hammer planes are now flat-shaded and blade contact reach is preserved. Four finishes per weapon and 351 full-battle draws retained. Evidence `.tools/029-final-render/`, `.tools/029-final-render.log`, `.tools/029-silhouette.log`; no frame-rate acceptance claim.

## Default-renderer validation and graphics settings

- Checked the current candidate on the project's default Vulkan Mobile renderer, rather than relying only on GL compatibility evidence. Fresh VSync-disabled idle diagnostics on Intel Graphics measured full-scene median 33-36 ms, p95 61-82 ms and p99 up to 235 ms, with 321 draws. Stage-only median was 24 ms. These stalls remain unresolved; older Vulkan timing claims do not establish performance for this candidate.
- Added persisted High / Balanced / Performance settings, limiting the battle's 3D viewport to 1600 / 1280 / 960 pixels wide respectively, capped by window width. High remains the default. Text, clocks, geometry and existing 2x MSAA are unchanged. Settings take effect immediately, and unrelated audio changes do not reallocate the viewport.
- Added a real GameFlow settings-overlay fixture verifying all three resolutions, saved/reloaded preferences, invalid-value fallback, unchanged clock layout, and 720p settings fit with normal and large text. Dynamic settings labels also receive the saved text scale on opening. Inspected the rendered large-text overlay; controls and Close remain visible.
- Made geometric reaction checks sample explicit animation timestamps after discovering that long Vulkan frames can move a wall-clock sample past the intended recoil pose. Live interruption/recovery checks remain. Deterministic pose checks do not prove smooth animation playback.
- Validation: Vulkan SENTINEL_PRODUCTION_OK / SENTINEL_RECOIL_OK and Vulkan/GL GRAPHICS_SETTINGS_OK. Logs `.tools/030-vulkan-final.log`, `.tools/030-graphics-final.log`, `.tools/030-graphics-gl.log`; profile `.tools/030-vulkan-profile.log`. No final script/assertion/shader errors; known Windows certificate-store warning remains. Large-text capture `.tools/030-graphics-gl/Godot/app_userdata/Overkill/graphics-030/settings-large-720.png`. No new installer or frame-rate acceptance claim.

## Authored Sentinel collapse

- Replaced the Sentinel's inherited death clip with a dedicated 1.1-second performance: initial stagger, failing hold, asymmetric knee drop, slight rebound and a held final pose. Analytic leg placement preserves the supporting foot as the trailing leg moves back. The off-hand lowers toward the supporting knee and the hammer arm folds inward. The hero keeps its existing death clip.
- Rejected the first pose because both knees were too low. Shifted the pelvis backward and extended the trailing leg. Final knee heights are approximately 7.2 and 39.6 cm in skeleton space; supporting-foot drift is below 1 mm in the tested outcomes. These are pose measurements, not a general collision solver.
- Rendered FINISH_SEQUENCE_OK on default Vulkan and GL compatibility, covering all eight win/loss, normal/fast and motion/reduced-motion combinations. Final-pose checks now enforce supporting-foot stability, asymmetric knee heights and visible head/body drop. Existing single-result handoff, terminal animation, emissive shutdown and late-event suppression remain covered. Headless SENTINEL_PRODUCTION_OK retains attack contact, guard/recoil and export geometry checks. No final script/assertion/shader errors; known certificate and headless ObjectDB exit warnings remain.
- Reviewed Vulkan victory framing and GL final stage capture. A late root-viewport capture was already black from the intended result fade; the final-pose fixture now captures the 3D stage explicitly, separate from live UI timing. Evidence `.tools/031-final.log`, `.tools/031-gl.log`, `.tools/031-regression.log` and `.tools/031-gl/Godot/app_userdata/Overkill/finish-027/sentinel-final-stage.png`. Reject `.tools/031-finish.log`, which contains the first pose's failed assertions.
- This adds one original death performance, not a complete animation set or AAA acceptance. The weapon remains hand-attached, with no ragdoll or dynamic body/cloth collision. Bespoke enemy roster, detailed materials, further animation variety and stable frame pacing remain unfinished. No installer release for this checkpoint.

## Phase-aware battle framing

- A permanently closer camera obscured the Sentinel's helmet behind the top choices and was rejected. The arena now uses a wider, lower composition while decisions are visible, and moves closer over 0.32 seconds when the overlay closes for an action or battlefield inspection. Returning to choices restores the wider composition. Large text receives additional vertical clearance. Actor world positions, clock layout and contact geometry are unchanged.
- The controller connects the real choice overlay's visibility to the stage composition. Position/vertical-offset motion is separate from existing impact FOV feedback; interrupted composition transitions replace the prior tween. Reduced-motion mode stays at the wider camera without composition travel.
- Added projected helmet/floor clearance checks, including actual instruction line count/font height, at 1080p/720p and large text. Tested real Inspect/Return toggles and reduced-motion position stability. Actor pose fixtures now hide choices during attacks and restore them for compact decision captures; they still do not simulate the entire combat UI state machine.
- Validation: Vulkan SENTINEL_PRODUCTION_OK and GL SENTINEL_PRODUCTION_OK with large-text/inspection checks. Reviewed action and compact decision captures. Headless CINEMATIC_FINISH_OK and FINISH_SEQUENCE_OK preserve damage accounting/contact and all eight finish combinations. No final script/assertion/shader errors; known certificate and headless ObjectDB warnings remain. Evidence `.tools/032-phase.log`, `.tools/032-large.log`, `.tools/032-contact.log`, `.tools/032-finish.log`. Discard `.tools/032-framing.log` (rejected permanent close-up). Short frame samples are not performance acceptance.
- This makes action framing more prominent while keeping decisions clear. It does not finish character quality, lighting, animation variety or frame pacing. No new installer was published for this development checkpoint.

## Enclosed helmet and neck armor (after 0.19)

- Replaced the open 300-degree bell shell with a continuous crown and closed top. Lowered the crest to follow the dome. A shallow recessed face now sits between separate brow/cheek plates; shorter dark breathing bars, a narrow eye slit and temple hinges replace the large front grille. Three overlapping neck lames cover more of the exposed mechanism.
- Retained the existing skeleton and authored clips. Reproducible Blender geometry increased from 30,322 to 31,840 vertices; the exported body still uses four surfaces and the existing wear/cavity masks. No new per-frame generation or material passes were added.
- Fixed the material inspection fixture: hiding the choice overlay starts a camera-composition tween, so it must finish before the fixture positions its close-up camera. The previous 0.19 close-up output was off-center for this reason; gameplay composition was unaffected. Compact/choice and action captures used for release review were independent of that fixture issue.
- Validation: default Vulkan SENTINEL_PRODUCTION_OK covers mesh, skin, contact, guard/recoil and normal/large/compact choice clearance. GL FINISH_SEQUENCE_OK retains all eight outcome/speed/motion combinations. Reviewed cool/warm centered close-ups and the final kneeling pose for crown and collar appearance. No script/assertion/shader failures; known certificate warning remains. Evidence `.tools/034-render.log`, `.tools/034-finish.log` and respective image folders.
- This improves helmet construction; it does not establish finished character production. Broad surface treatment, body proportions, hand/weapon detail, animation variety, roster and performance still need work. Public installer remains the verified 0.19 playtest; this art checkpoint is unreleased.

## Forged braziers and restrained fire (after 0.19)

- Replaced flat orange ember discs and plain tapered stands with a separate `ArenaBrazier` prop: banded iron pedestal, forged basket ribs/rings, a nineteen-piece instanced coal bed and one small flame billboard. Metal pieces combine once into two finishes; no per-frame geometry is built.
- Flame shape uses a compact procedural shader with rising distortion and independent phase per prop. Its plane retains depth testing so basket bars occlude the fire. The two existing shadow-free warm lights keep their original color/range and base energy, with under five percent variation. Reduced motion freezes both flame shape and light energy.
- Default Vulkan and GL compatibility rendered checks cover shader compilation, metal batching, no extra local shadow passes and stable reduced-motion fire/light behavior, alongside existing contact/reaction/choice-framing checks. Reviewed action and compact scenes. Draw count remains 321 Vulkan / 351 GL in the diagnostic scene; no frame-rate improvement or full-fight acceptance is claimed. Evidence `.tools/035-render.log`, `.tools/035-gl.log` and capture folders; known certificate-store warning remains.
- Fire is a small camera-facing procedural surface, not volumetric simulation. Environment material transitions, wear, distant geometry, fuller character production and frame pacing remain unfinished. This development checkpoint is not included in the published 0.19 installer.

## Impact batching and fresh profiling (unreleased)

The arena now reuses one instanced spark mesh instead of allocating twelve SphereMesh/MeshInstance pairs per impact. Per-instance colors preserve warm damage and cyan block effects. Capacity starts at 32, grows for overlapping effects and is reused; no live particles are discarded. Gravity, initial velocity ranges, count, shrinking and 0.42-second lifetime are unchanged. Sparks no longer submit shadow passes. Empty batches are hidden to avoid an idle draw. Instance colors are interpreted as sRGB to match the previous material colors.

The diagnostic `arena_profile.tscn` accepts `--arena-profile-engraving` to hide/restore both engraving layers and `--arena-profile-actions` to replay stage attacks, impacts, reaction animations and effects in normal/fast/reduced-motion modes. It records peak draws and frames above 16.667 ms alongside existing timing percentiles. This is a presentation workload, not a complete gameplay simulation or performance acceptance test.

Fresh Vulkan/Intel 1600x813 stage, 1920x1080 UI, VSync off:
- Idle baseline: full median 13.32/13.35 ms before/after stage isolation; stage-only 10.73 ms.
- Engraving isolation: full 12.35 ms, hidden 12.20 ms, restored 12.44 ms; draws 321 -> 295 -> 321. No material timing improvement, so no engraving rewrite was made.
- Normal action baseline -> batched: median 12.54 -> 13.65 ms, p95 18.50 -> 18.28 ms, peak draws 321 -> 298.
- Fast action: median 12.30 -> 12.37 ms, p95 18.48 -> 18.16 ms, peak draws 321 -> 298.
- Reduced-motion action: median 12.40 -> 12.56 ms, p95 18.46 -> 17.73 ms, peak draws 320 -> 297.

The draw reduction is demonstrated; a consistent frame-time gain is not. Earlier much slower samples and these fresh samples show why a single short measurement is not stable-FPS evidence. Profiling runs were sequential without concurrent test rendering. Evidence: `.tools/039-before.log`, `.tools/039-isolate.log`, `.tools/039-actions.log`, `.tools/039-after.log`.

Vulkan initial batch checks and final GL SENTINEL_PRODUCTION_OK / IMPACT_BATCH_OK verify shared geometry, mixed color, overlapping capacity, cleanup, contact and UI framing. GL readback differs by under 0.001 per channel; checks allow one 8-bit step. Headless dummy rendering cannot read GPU instance colors, so that assertion is limited to rendered runs. Final GL mixed-impact capture inspected. Headless FINISH_SEQUENCE_OK covers all eight outcome/speed/motion combinations. Final logs have no script/assertion/shader failures; known certificate warning remains. Evidence `.tools/039-render.log`, `.tools/039-gl-final.log`, `.tools/039-gl-final-errors.log`, `.tools/039-finish.log`. Reject initial headless GPU-color and exact-precision GL assertion attempts.

This is an unreleased rendering improvement. It does not close the art, animation, roster, full-fight pacing or AAA-quality requirements.

## Decision clock readout clearance (unreleased)

While decision text is present, the mechanical pointer becomes an inward-facing perimeter marker outside the relic icons, and the center hub is hidden. The player returns to the full mechanical hand when guidance clears for resolution. Enemy intent keeps the center clear. Twin-hand geometry follows the same clearance mode. Marker geometry scales with the dial on resize. Placement/sweep text is centered, and the enemy intent uses a 210x150 center area without reducing its 24-point font.

Decision-time pointers now advance to the upcoming player/enemy hour, including enemy hour mapping; the opening pointer no longer contradicts the hour-one pulse by remaining at hour nine. Destination pulses and hover ghosts remain. A hovered-source connector is omitted when it would cross the caption, and the redundant center-origin connector is removed.

Vulkan and final GL SENTINEL_PRODUCTION_OK / CLOCK_READOUT_OK pass. Checks cover all nine marker angles against readout bounds, opening-hour agreement, full-hand restoration, and a three-hour Sentinel intent fitting the center. Normal/compact/large-text render captures inspected; final GL compact-large view confirms markers outside the icons and unobstructed text. Headless CLOCK_SMOKE_OK and all eight FINISH_SEQUENCE_OK cases pass. Evidence `.tools/040-final.log`, `.tools/040-gl.log`, their error logs, `.tools/040-smoke.log`, `.tools/040-finish.log`. No script/assertion/shader failures; existing certificate warning remains.

The sweep fixture changes only guidance state to inspect text layout; it is not a complete replacement-flow screenshot. Long combined-effect enemy intents beyond this Sentinel case still require roster-wide review. This addresses specific information collisions; overall art, animation and performance are still below the requested quality target. Installer remains 0.19.

## Roster-wide enemy intent panel (unreleased)

Detailed enemy actions now occupy a dedicated upper-right readout beside the choice row, leaving a short ordered-hour cue in the enemy clock center. The panel uses the unused side area above the enemy clock, retains a 24-point base font and honors the live large-text setting. Its height resets when descriptions change. Damage is explicitly labeled as base damage; this does not replace the exact allocation forecast.

Fixed a missing Siphon telegraph: the full intent description now includes the 25% Overkill drain on HP damage. In the compact panel, affected rows say Siphon and one shared rule explains it. Revealed second-hand actions are listed on the triggering third hour, including reverse-clock mapping; a non-attacking echo says No strike because the current resolution does not execute a block-only echo. Unknown primary/echo actions remain unrevealed.

New `enemy_intent_readout_test.tscn` checks ten enemy profiles across all three sweep sectors. Normal and large text pass 30 layouts each: panel bottom above clock title, no overlap with choices, Siphon/echo inclusion and hidden-information protection. Vulkan large-text Siphon and final-boss captures inspected at 1280x720. Final headless Sentinel suite also passes live text-size changes and existing contact/framing checks. All eight finish cases pass. Evidence `.tools/041-normal-verified.log`, `.tools/041-verified.log`, `.tools/041-verified-errors.log`, `.tools/041-regression-final.log`, `.tools/041-finish.log`; captures under `.tools/041-verified/Godot/app_userdata/Overkill/intent-041/`.

Rejected earlier Siphon overflow and a settings-signal argument mismatch; final logs contain no script/assertion/signal/shader failures. Existing certificate and headless ObjectDB exit warnings remain. Roster fixture swaps only enemy data/readout on the Sentinel stage; its screenshots are layout evidence, not those enemies' finished 3D encounters. The full AAA art/animation/performance target remains unmet. Installer remains 0.19.

## Finger-centered weapon attachment (unreleased)

Weapon translation now follows the average curl center of the index, middle and ring fingers instead of the back of the palm. Bone indices are cached at initialization. Target-aware weapon direction and attack timing remain intact. A dedicated `weapon_grip_test.tscn` captures five attack poses for both actors and checks that deferred skeleton updates do not displace the world-space attachment.

Vulkan close-ups show improved handle placement at player windup/contact. They also reveal unresolved wrist-axis mismatch and simplified finger geometry; this change does not certify a natural grip throughout the swing. Existing rendered Sentinel production checks and Boneghoul contact/guard/interruption checks pass. Evidence: `.tools/052-final*`, `.tools/052-sentinel*`, `.tools/052-contact*`. Boneghoul return-strike center separation is approximately 0.054 m; guarded blade meets the bracer with approximately 0.553 m torso clearance. Known certificate-store warning remains. No performance or AAA-quality acceptance. Published installer remains 0.21.

## Authored wrist correction (unreleased)

Reduced the inherited attack wrist offset from -75 to -25 degrees at strike and from -45 to -20 at recovery. Rebuilt both Executioner and Sentinel from their production sources; the Sentinel retains its authored guard, recoil and collapse clips. This corrects excessive hand flexion without adding a runtime bone override.

The five-pose rendered grip study now measures forearm-to-hand bend and rejects sampled attack poses above 35 degrees. Measured impact bend is 17.37 degrees for the player and 17.49 for Sentinel; recovery is 15.35 degrees. These are sampled poses, not proof of every interpolated frame or anatomical correctness. Vulkan close-ups reviewed. Rendered Boneghoul contact/guard/interruption and Sentinel production suites pass. Build sentinels, import and final logs contain no Python/script/assertion/shader failures; known certificate-store warning remains. Evidence: `.tools/053-build.log`, `053-sentinel-build.log`, `053-import-final.log`, `053-weapon_grip_test*`, `053-boneghoul_contact_test*`, `053-sentinel_production_test*`.

Remaining: fingers and thumb do not yet convincingly wrap all swing angles, weapon aim is still independent of authored hand orientation, and swing staging remains basic. No AAA or performance acceptance; published installer remains 0.21.

## Continuous weapon roll (unreleased)

The full swing audit exposed a world-up/world-forward reference switch when the weapon approached vertical. At 120 samples per authored second, the old reference caused adjacent orientation changes of 124.81 degrees for the player and 132.00 for Sentinel. Weapon orientation now projects the actor's lateral axis perpendicular to the aimed shaft, retaining continuous roll through overhead windup and recovery. A fallback handles a shaft parallel to that lateral axis; this degenerate pose is outside the current forward/up swing.

The grip study checks 93 samples per actor and rejects orientation steps above 30 degrees. Final maxima are 21.02 / 20.28 degrees, both during the fast strike, with no vertical-reference snap. This sampling gate is not proof of arbitrary future animation continuity or a natural finger grip. Vulkan close-ups inspected; rendered grip, Boneghoul contact/guard/interruption and Sentinel production suites pass. Final `.tools/054-weapon_grip_test*`, `054-boneghoul_contact_test*`, `054-sentinel_production_test*` logs have no script/assertion/shader errors. Baseline evidence `.tools/054-baseline.log`. Known certificate warning remains. Source checkpoint only; installer 0.21 unchanged. Broader art, animation and performance acceptance remain open.

## Forged sword hilt (unreleased)

Replaced the rectangular sword crossguard with swept, tapered octagonal quillons; added raised leather binding seams, metal grip collars and a rounded steel pommel. Existing grip center and blade reach stay unchanged. All pieces use the existing materials and enter the existing finish batching, retaining four weapon batches. Hammer geometry is unchanged.

Reviewed Vulkan windup and impact close-ups. A geometry audit caught inward guard winding in the first candidate; corrected shell and end-cap winding. Final audit reports zero inward shell normals across 960 sampled vertices. Rendered grip study and Sentinel production suite pass, including swing continuity, deferred attachment stability, contacts, reactions and layout. Evidence `.tools/055-normals-final.log`, `.tools/055-final-weapon_grip_test*`, `.tools/055-final-sentinel_production_test*`. Final logs have no script/assertion/shader errors. A first standalone audit launch outside the isolated profile crashed before startup; the isolated-profile rerun completed. Known certificate and standalone audit ObjectDB exit warnings remain. No FPS claim from this pass. Installer remains 0.21; no AAA acceptance.

## Real encounter profiling and shared-theme invalidation fix (unreleased)

Added `scenes/encounter_profile.tscn`: real Sentinel combat at 1920x1080, seed 1729, unchanged 80 HP starter run, first draft option then sector sweeps. It measures decision/resolution/ending wall time and stage CPU/GPU timings across High -> Performance -> High, with VSync disabled and four seconds warmup. No synthetic health, forced victory or presentation-only attacks. Muted audio, one encounter/policy/device; this is diagnostic, not broad performance acceptance. Every baseline and corrected trial reaches the same defeat after 17 decisions, with identical relic traces and final HP (-18 player / 121 enemy).

Found redundant shared-theme writes in `ScreenDesign.apply_text_size`: every relic bind and overlay presentation reissued unchanged font sizes. Each theme change notified all consumers. Shared settings and per-control font overrides now change only when the target differs. Normal -> large -> normal still restores exact base sizes.

Intel integrated graphics, Vulkan Mobile; High stage 1600x813, Performance 960x488. Measurements in milliseconds:

| Trial | Decision p95 before / after | Worst decision before / after | Resolution median before / after |
| --- | --- | --- | --- |
| High first | 172.890 / 24.611 | 247.616 / 156.244 | 16.374 / 16.276 |
| Performance | 111.278 / 24.264 | 288.687 / 116.411 | 10.971 / 10.678 |
| High repeat | 165.110 / 27.829 | 345.318 / 162.876 | 16.346 / 16.320 |

Evidence supports substantially reduced decision-transition stalls, not elimination: 116-163 ms outliers remain. Resolution p95 remains 21-22 ms on High, 16.59 ms on Performance. The unchanged combat traces protect the comparison from differing scripted choices. No claim of stable 60 FPS or AAA performance.

Evidence: `.tools/056-encounter*` baseline, `056-after*` corrected, `056-text.log` (zero shared-theme signals for 12 unchanged applications; label/rich-text normal-large-normal), `056-settings*` (rendered live presets, persistence, compact/large-text fit). Large-text 720p settings capture inspected. Final logs have no script/assertion/shader failures; certificate-store warning remains. Published installer is still 0.21.

## Relic thumbnail filtering (after 0.22; unreleased)

Enabled mipmap generation for the twelve active relic JPEGs and Blood Siphon's bloodprice JPEG fallback. Choice artwork and clock socket textures explicitly use linear filtering with mipmaps. This preserves the original art while filtering high-frequency detail appropriately when 1024-pixel paintings are reduced to small thumbnails. Other fallback art outside the current relic set is unchanged.

Source Vulkan 1280x720 battle captures reviewed before/after: Iron Strike, Guard Plate, Overdrive Piston and Blood Siphon now have less noisy silhouettes and highlights. Final import and source preview result/retry checks pass (`.tools/059-final-import.log`, `059-final-render*`); no script/assertion/shader failures, known certificate warning remains. Capture: `.tools/059-profile/Godot/app_userdata/Overkill/release022-retry.png`. The reused fixture's sentinel says PACKAGED but this pass explicitly runs the source project, not the frozen release PCK. No performance claim; mipmaps add texture storage. This change is NOT in the published 0.22 installer.

## Stone surface response (after 0.22; unreleased)

Connected the existing stone roughness map to the arena floor and duplicated stair material. The shader varies roughness across stone/mortar, increases restrained normal relief from 0.10 to 0.32 and darkens the high-roughness mortar response to keep seams from competing with combatants. A surface_detail control permits visual A/B comparison; it is not a player-facing quality setting.

Vulkan and OpenGL compatibility 1280x720 before/after captures reviewed. Material compiles and both floor/stair instances are present, with no final script/shader/assertion errors. Known certificate warning remains. Source-only evidence `.tools/060-render*`, `060-gl*`; the first temporary profiling script had an indentation/scope error and was corrected before measurement.

Sequential old-shader / new-shader / old-shader samples, six seconds each after two-second warmup, VSync off, actors paused, Intel integrated GPU: stage GPU medians 6.417 / 6.583 / 6.395 ms; wall medians 16.211 / 16.390 / 15.827 ms and p95 27.366 / 27.927 / 26.444 ms. Evidence `.tools/060-profile-final*`. Approximately 0.17-0.19 ms added stage GPU time in this short fixture; not a whole-game or cross-hardware acceptance result. The old shader is loaded explicitly for the performance baseline, rather than merely setting surface_detail to zero. GL lighting remains different from Vulkan. Published 0.22 unchanged; environment geometry, art and overall AAA target remain unfinished.

## Sentinel articulated gauntlets (after 0.22; unreleased)

Replaced pipe-shaped palms with shallow metacarpal housings aligned from wrist to the actual four knuckle roots. The hand bone tail ends before those roots, so the first candidate still exposed a gap; that candidate was rejected and the palm span now uses the knuckle centroid. Added dark finger pivots, tighter 2 mm finger-plate bevels, slightly smaller pinky plates and closed fingertips. Skeleton, skin assignments and attack/reaction clips stay intact. Final source mesh: 37,004 vertices, four surfaces (previous 31,840 vertices).

Final Vulkan windup/impact close-ups reviewed; source grip stability, sampled wrist bend, full-swing orientation continuity and Sentinel production checks pass, including contact/reactions/reduced motion/layout. Evidence `.tools/061-build-final.log`, `061-import-final.log`, `061-final-weapon_grip_test*`, `061-final-sentinel_production_test*`; no final Python/script/assertion/shader failures, known certificate warning remains. Initial palm-gap candidate is not accepted evidence. Thumb opposition, natural grip at all angles, richer animation and material finish remain open. No performance acceptance for the added vertices. Published 0.22 unchanged.

## Sentinel reaction hand gestures (after 0.22; unreleased)

Authored separate off-hand finger poses in the existing guard and hit clips: guard tightens the fingers; recoil opens and slightly splays them before returning to idle. Right-hand weapon grip and reaction timing remain unchanged. No geometry or surface-count increase (37,004 vertices / four surfaces).

Rendered Vulkan close-ups and the full-stage recoil reviewed. A focused manual-animation fixture measures middle-finger root-to-distal reach at 0.0674 m guarding versus 0.0850 m recoiling, and checks both clips return within 4 mm of their initial finger position. Existing Sentinel production regression passes normal/fast reactions, interruption recovery, planted feet, contact, reduced motion and framing. Evidence: `.tools/062-build.log`, `062-import.log`, `062-hand*`, `062-production*`. Final logs have no Python/script/assertion/shader errors; known certificate-store warning remains. Hands still look mechanical, particularly thumb opposition; this is limited animation polish, not natural anatomy or AAA acceptance. Published 0.22 remains unchanged.

## Rejected plate-finish study (2026-09-19)

Compared the existing Sentinel metal shader with broad triplanar oxidation and lowered metallic response, then a revision restoring highlight contrast with lower face roughness. Identical paused-pose Vulkan gameplay and torso close-ups captured through `.tools/063-metal.gd`; both iron/bronze materials were swapped between an explicit baseline shader and the candidate. Both candidates compiled without script/shader failures, but visual acceptance failed: first flattened the armor, second mainly altered sheen while retaining simplistic broad forms. Three additional texture samples per fragment were not justified by the visible gain. Original shader restored byte-for-byte from the pre-study copy; no runtime change accepted.

Next art work should address intentionally shaped plate forms and placed surface detail rather than another global sheen adjustment. Reference captures are under `.tools/059-profile/Godot/app_userdata/Overkill/metal-*.png`; `.tools/063-render*` first candidate, `063-final*` revision logs. Published 0.22 unchanged. This evidence does not validate broader visual quality or performance.

## Sentinel fluted shoulder shells (after 0.22; unreleased)

Shaped six radial flutes into the outer shoulder shells, with smooth fade away from the crown and lower rolled lip. Retained simpler overlapping lower plates. The first candidate pinched the crown and used 53,350 vertices; revised fade and outer-layer-only tessellation reduce the final character to 39,252 vertices (previous 37,004), still four surfaces. Material shader, skeleton and animation are unchanged. Final torso close-up and gameplay captures inspected; subtle geometric highlight separation is retained, not a claim of finished character art.

Blender build/import and two rendered Sentinel production passes succeeded: contact, guard/recoil, recovery, reduced motion and framing. Final logs `.tools/064-build-accepted*`, `064-import-accepted*`, `064-close*`, `064-production*`; no Python/script/assertion/shader failures, known certificate warning remains. Reused material study fixture now swaps identical baseline/current shaders; it is a view capture only for this geometry pass.

Production timing was unstable (first median 100 ms, repeat 44.337 ms), so investigated with a sequential old/new/old mesh swap in one paused 1280x720 scene, VSync off, two-second warmup plus six-second samples. Old mesh loaded directly from the committed GLB with GLTFDocument; same existing actor skeleton and material overrides. Wall medians 31.284 / 30.156 / 32.229 ms; p95 47.179 / 46.404 / 56.588; stage GPU medians 16.660 / 16.357 / 19.501 ms. `.tools/064-profile*`. No observed regression attributable to the extra 2,248 vertices in this noisy fixture; neither a speedup claim nor performance acceptance. Published 0.22 unchanged. Broader authored detail, anatomy and frame pacing remain unfinished.
