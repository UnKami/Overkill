# Cinematic Worlds visual canon

## North star

Overkill uses painterly-real cinematic key art built around one continuous world: ruined gothic architecture colliding with a luminous industrial chronoforge. Cool cyan crystal and mist define the left/cold side; amber fire, furnaces and sparks define the right/hot side. Materials should feel tangible—wet stone, blackened steel, glassy crystal, smoke and volumetric light—not flat, comic or card-illustration-like.

The approved anchor references are:

- `assets/screens/shop_bg.jpg`: contextual industrial-gothic world building, controlled cyan/amber split, deep framing architecture.
- `assets/screens/rest_site_bg.jpg`: quiet character-led storytelling, readable negative space and cinematic depth.
- `assets/characters/executioner/combat_sprite.png`: canonical hooded Executioner identity, dark layered armor and cyan/amber fractured energy.

## Composition rule

Character presence is intentional, not universal:

- Narrative and navigation screens feature the Executioner inside the scene. The character supplies scale, purpose and emotional context to title, class, map, event, reward, collection, upgrade, transition and outcome art.
- Live battle backgrounds contain no baked-in player or enemy. Combat already renders the live Executioner and enemy over the plate; including either in the environment would duplicate the cast and break visual continuity.
- UI-safe negative space is authored into each composition. Text and controls remain separate Godot layers; generated art contains no lettering or interface elements.

## Authored library

The 30-scene library is centrally routed by `scripts/ui/cinematic_art.gd`.

### Character-led screen plates (18)

| Role | Asset |
| --- | --- |
| Title | `assets/screens/cinematic/title_last_bell.jpg` |
| Class selection | `assets/screens/cinematic/class_executioner_altar.jpg` |
| Act I map | `assets/screens/cinematic/map_act1_pilgrim_ruins.jpg` |
| Act II map | `assets/screens/cinematic/map_act2_luminous_refinery.jpg` |
| Act III map | `assets/screens/cinematic/map_act3_fractured_horizon.jpg` |
| Humming Shrine event | `assets/screens/cinematic/event_humming_shrine.jpg` |
| Overflowing Cache event | `assets/screens/cinematic/event_overflowing_cache.jpg` |
| Pre-battle offer | `assets/screens/cinematic/prebattle_forgemaster_offer.jpg` |
| Relic reward | `assets/screens/cinematic/reward_relic_vault.jpg` |
| Victory reward | `assets/screens/cinematic/reward_victory_cache.jpg` |
| Reliquary/collection | `assets/screens/cinematic/collection_archive_hall.jpg` |
| Card upgrade | `assets/screens/cinematic/upgrade_memory_forge.jpg` |
| Act I → II | `assets/screens/cinematic/transition_act1_act2.jpg` |
| Act II → III | `assets/screens/cinematic/transition_act2_act3.jpg` |
| Act III → final | `assets/screens/cinematic/transition_act3_final.jpg` |
| Victory | `assets/screens/cinematic/victory_balanced_clock.jpg` |
| Defeat | `assets/screens/cinematic/defeat_extinguished_clock.jpg` |
| Loading corridor | `assets/screens/cinematic/loading_shard_corridor.jpg` |

`loading_shard_corridor.png` is a lossless boot-splash derivative of the same authored loading scene because Godot accepts only PNG for project boot art.

### Character-free battle plates (12)

| Encounter role | Asset |
| --- | --- |
| Act I regular A | `assets/environments/cinematic/act1_fallen_nave.jpg` |
| Act I regular B | `assets/environments/cinematic/act1_crystal_cloister.jpg` |
| Act I elite | `assets/environments/cinematic/act1_execution_court.jpg` |
| Act I boss | `assets/environments/cinematic/act1_bell_sanctum.jpg` |
| Act II regular A | `assets/environments/cinematic/act2_refinery_floor.jpg` |
| Act II regular B | `assets/environments/cinematic/act2_furnace_bridge.jpg` |
| Act II elite | `assets/environments/cinematic/act2_pressure_chamber.jpg` |
| Act II boss | `assets/environments/cinematic/act2_chronoforge_core.jpg` |
| Act III regular A | `assets/environments/cinematic/act3_shattered_causeway.jpg` |
| Act III regular B | `assets/environments/cinematic/act3_void_cathedral.jpg` |
| Act III elite | `assets/environments/cinematic/act3_zenith_vault.jpg` |
| Act III/final boss | `assets/environments/cinematic/act3_final_convergence.jpg` |

Regular encounters select deterministically from two plates per act using the enemy ID. Elite, boss and final-boss routes use fixed authored plates so their escalation remains recognizable.

## Motion language

`AmbientMotion.apply_cinematic_backdrop()` adds restrained life without turning a still painting into distracting motion:

- a very slow 1.8–3.6% camera drift and scale breath;
- a subtle cyan-to-amber light veil;
- sparse, slow motes confined to their color side;
- unchanged interactive UI above the atmosphere layers.

Reduced-motion mode leaves the authored composition completely still. It also disables existing idle opacity, bob and ember motion. Gameplay timing and input never depend on ambient motion.

## Generation approach

The images were created with Codex's built-in image generation in reference-led mode, using the approved shop, rest-site and Executioner assets as visual anchors. Prompt families specified:

- painterly-real cinematic dark techno-fantasy, tangible materials and volumetric atmosphere;
- gothic ruins fused with industrial chronoforge machinery;
- controlled cyan-left / amber-right light grammar;
- the exact hooded Executioner identity on character-led pages;
- wide 16:9 compositions with task-specific negative space;
- no text, logos, frames, cards or UI;
- character-free symmetrical floor and silhouette space for battle plates.

This prompt grammar should be reused for future additions. Relics remain isolated transparent objects; full scenery belongs to screens and event pages.

## Verification contract

- `scenes/cinematic_art_test.tscn` asserts 30 unique routed resources and act/event/tier selection.
- `scenes/frontend_showcase.tscn` renders the real title-to-combat UI flow.
- `scenes/battle_arrival_visual_test.tscn` captures class, collection, pre-battle, upgrade and combat compositions at 1080p/720p plus ultrawide pre-battle.
- Visual acceptance is based on rendered frames, not resource presence alone.
