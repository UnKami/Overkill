# Sentinel production checkpoint

## Objective and acceptance

The goal remains a cinematic, readable, polished 3D game in the approved dark fantasy direction: worn metal, dramatic lighting, restrained effects. The current work is not AAA completion. Passing a mechanics test does not establish art quality.

| Area | Evidence required for acceptance | Current state |
|---|---|---|
| Character production | Distinct authored models and material response for the full enemy roster; readable silhouettes at battle size; close-up topology/normal/skin review | New Sentinel body candidate; other enemies and hero still require production work |
| Animation | Intent, anticipation, contact, recoil, guard, recovery and death coherent through entire fights; variety appropriate to each enemy; no sliding or weapon misses | Shared five-clip rig; current contact tests; Sentinel guard-to-strike turn being validated |
| Material detail | Correct scale, convincing forged edges, cavities, wear and roughness under multiple lighting conditions | Shared triplanar metal remains; bespoke material authoring incomplete |
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
