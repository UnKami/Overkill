# Sentinel 3D encounter — 17 September 2026

## Play

Open `build/directed/Play Sentinel.cmd` for the standalone encounter. This launcher stores its saves in `build/directed/profile`, separate from ordinary game progress. `Overkill.exe` opens the full game; the act-one Sentinel boss automatically uses the new stage. Other encounters retain their illustrated presentation. Keep the executable and PCK together.

`Play Sentinel Compatibility.cmd` selects OpenGL for machines without working Vulkan support. It was substantially slower on the development machine; use the normal launcher first. The previous `build/polished` snapshot is retained.

## Implemented

- Imported and rebuilt a CC0 knight into a clean game skeleton with continuously interpolated idle, attack, guard, hit and death clips. Both fighters currently share this base mesh, with different materials and equipment. These are authored keyframe animations, not motion capture.
- Reproducible Blender conversion in `scripts/art/build_executioner.py`, editable production source in `art_source/characters/executioner-production.blend`, exported runtime asset in `assets/characters/rigged/executioner.glb`.
- Planted-foot attack animation, forward body weight shift, skeletal equipment attachments, opponent-directed weapon alignment, short weapon trails, wind-driven cloaks and impact sparks.
- Lit 3D floor and columns, scanned stone surfaces, HDR reflections, cyan/amber character lighting and a distant illustrated cathedral backdrop. It is a hybrid environment, not a fully modeled cathedral.
- Camera framing and attack/impact/death transitions, projected damage indicators, smaller side clocks and horizontal draft choices. Reduced-motion setting keeps camera motion disabled.
- Vulkan Mobile renderer, native stage resolution up to 1920 pixels wide, 4x multisample antialiasing and mipmapped anisotropic floor textures.

## Verification

Godot 4.5.1 imported the project and rendered the stage on Intel(R) Graphics with Vulkan 1.4.348. A short 1920x1080 idle sample reported median 16.67 ms and p95 17.07 ms across 174 samples. This is a narrow local sample, not a minimum-hardware or full-game performance certification. Screenshots cover idle, anticipation, impact, guard, death and a 1280x720 window.

Passed: clock battle smoke with the directed stage (12 assembly hours, duplicate input, quadrant sweeps, reserve swap, wrap and single victory); persistent inventory/economy integration with the directed stage; rig motion (five clips, planted-foot drift below 3.3 mm at sampled attack times, contact reach, reduced camera motion, particle cleanup and death); direct encounter entry, victory, retry and defeat.

The engine reports a local Windows root-certificate-store warning. Some headless rig/integration exits also report leaked ObjectDB instances; these remain a cleanup issue and are not counted as a clean shutdown. No script assertion failures occurred in the listed passing checks.

The portable executable launched its exported Sentinel scene using Vulkan from the build folder without a source-project path. Packaged battle smoke and encounter entry/retry/defeat checks passed. After the final palm-grip adjustment, the rebuilt package also passed the rig motion check. Logs are included in `build/directed/packaged-*.log`.

## Production boundary

This is a playable first 3D encounter, not completed AAA production. The shared base model, procedural equipment, cloth silhouettes, hand/weapon animation, scenery detail, transitions and lighting still need an art and animation refinement pass. Other enemy families still require their own modeled, rigged and animated assets. Full campaign, input accessibility, longer performance runs and broader GPU coverage remain unverified. No public installer or online release was updated.

## Asset provenance

- Knight source: **crownjoshua**, [Knight Rigged Mid Poly](https://opengameart.org/content/knight-rigged-mid-poly), CC0. Downloaded `Knight_0.blend`; adapted skeleton, materials and animation. Original source remains locally in `.tools/knight-source.blend`.
- Stone Tiles: **Christopher Melani**, [Poly Haven](https://polyhaven.com/a/stone_tiles), CC0. 2K diffuse, OpenGL normal and roughness maps.
- Abandoned workshop: **Sergej Majboroda**, [Poly Haven](https://polyhaven.com/a/abandoned_workshop), CC0. 1K HDR environment reflection map.
- CC0 terms: https://creativecommons.org/publicdomain/zero/1.0/
- Godot: MIT license included alongside the executable. Existing project illustrations and audio retain their earlier provenance.
