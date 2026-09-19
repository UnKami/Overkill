# Sentinel production checkpoint

## Objective and acceptance

The goal remains a cinematic, readable, polished 3D game in the approved dark fantasy direction: worn metal, dramatic lighting, restrained effects. The current work is not AAA completion. Passing a mechanics test does not establish art quality.

| Area | Evidence required for acceptance | Current state |
|---|---|---|
| Character production | Distinct authored models and material response for the full enemy roster; readable silhouettes at battle size; close-up topology/normal/skin review | New Sentinel body candidate; other enemies and hero still require production work |
| Animation | Intent, anticipation, contact, recoil, guard, recovery and death coherent through entire fights; variety appropriate to each enemy; no sliding or weapon misses | Shared five-clip rig; current contact tests; Sentinel guard-to-strike turn being validated |
| Material detail | Correct scale, convincing forged edges, cavities, wear and roughness under multiple lighting conditions | Sentinel now has geometry-authored edge wear and baked local cavity visibility; unique textures and broader material polish incomplete |
| Environment and staging | Cohesive finished arena composition, character separation, no UI obstruction at supported aspect ratios | Cathedral arena prototype with authored lighting; breadth and detail incomplete |
| Information and control | Readable 720p/1080p UI, keyboard/mouse parity, exact placement and outcome previews, staged reveals, no obscured choices | Existing 0.17/0.18 coverage; fresh broad visual audit still required |
| Sound and feel | Listened-to mix; distinct cues synchronized to actual events; clear levels, no fatigue or clipping | Event integration and waveform tests; listening review incomplete |
| Performance | Stable frame pacing through full fights on declared target hardware and quality levels, including impact and transition peaks | Intel profiling shows remaining frame-time spikes; no 60 fps acceptance |
| Gameplay and delivery | Human-reviewed pacing/balance, full run and transition verification, accessible controls, reliable installer/release/update log | 0.18 verified playtest remains published; boss balance and broad run validation incomplete |

## Current candidate

- `scripts/art/build_sentinel.py` authors a new clockwork body with recessed chest mechanism, curved bell helm, armor lames, exposed joints, articulated fingers and boots. It retains the existing licensed skeleton and five authored clips, but no source knight mesh geometry.
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
