# Overkill Visual Canon

This document is the art-direction gate for every playable character, enemy, battlefield, relic and event image. New art must look as though it belongs beside the approved reference set below; genre similarity alone is not enough.

## Core identity

Overkill is painterly-real cinematic techno-fantasy: tactile relics and architecture inside a continuous, character-led world of ruined gothic stone and industrial chronoforge machinery. The game keeps its luminous cyan/amber energy language, but crystal is one material in the world—not a mandatory surface for every relic. Objects should feel physically distinct, memorable and premium rather than like recolors of one crystal machine.

- Primary energy: luminous cyan and warm amber-orange.
- Secondary energy: restrained magenta, ruby or violet where the object identity requires it.
- Materials vary by relic identity: worn steel, cobalt ceramic, leather, cloth, bronze, bone, glass, stone and crystal may all appear where they make sense.
- Shapes vary too: blades, shields, springs, censers, bottles, tools and vessels should not all collapse into a floating crystal core.
- Lighting: cinematic volumetric shafts, crisp rim light, colored bounce light and deep navy negative space.
- Detail level: high-detail 3D-rendered illustration. Avoid flat comic art, painted-card brushwork on game objects, and low-detail placeholders.

## Preserve and extend

These files define the approved direction and must remain visually authoritative:

- `concept art/UnKami___GOE__3d_rendering_of_a_futuristic_magical_crystal_gaun_61944754-9889-43b7-8c64-8a68cb576497.png`
- `concept art/UnKami___GOE__a_light_emitting_key_with_hexagons_on_it_colorful_2be95a43-b032-4d0a-a4ff-4a8a426c6ac6-2-1.png`
- `concept art/UnKami___GOE__None_36ed6bb3-db53-4c8e-9265-2bc3516eee1f.png`
- `assets/characters/executioner/character image.png`
- `assets/characters/executioner/combat_sprite.png`
- `assets/characters/executioner/executioner_portrait.png`
- `assets/relics/relic_cracked_lens.png`
- `assets/relics/relic_greed_battery.png`
- The original isolated crystalline relic objects in `assets/relics/active/*_object.png` (not the retired `_v2` set). Their mechanic-coded colors and faceted materials are authoritative.
- The ten live enemy resources route to `*_crystalline.png` and `final_boss_crystal_warden.png`. The original `final_boss.png` is preserved as an art reference only, not a combatant resembling the player.
- The cinematic screen art under `assets/screens`, including act transitions, class select, event, loading, rest, shop, win and loss screens.
- Scenery illustrations belong to event and story pages. No active relic selection, shop or upgrade interface may show scenery cards.

## Asset rules by category

### Player character

The Executioner is one identity in every fight, including bosses: the hooded cyan/amber crystalline figure from the approved character set. Battle scale, pose and effects may change; the character design may not change into a conventional knight or another model.

### Enemies

Enemy art is a high-detail isolated figure with a transparent background. It shares the Executioner's crystalline fracture language while retaining a distinct silhouette and faction read. Its base palette is obsidian and ivory, not the player's cyan and amber, so combatants stay immediately distinguishable. Give each faction one restrained signature hue: jade for feral/decay, amethyst for arcane guardians, spectral rose for apparitions, and blood red for Excess. Keep the unique hue a thin ambient accent on ordinary foes; increase its area and brightness with encounter danger (common < elite < boss), while preserving the monochrome foundation. The tint identifies a family; stronger saturation/coverage warns of threat. A boss can be more elaborate or larger, but must not switch the game into another visual language.

Current family assignments: Boneghoul, Rustlurker, and Shattered Husk — jade; Gorged Sentinel, Hollow Custodian, and Cracked Reliquary — amethyst; Chained Wraith and Overflowing Choir — spectral rose; Excess Warden and The Undying Excess — blood red. Accent strength follows `EnemyData.tier`; final bosses remain the most conspicuous.

### Relics

A relic is one collectible physical object. It is centered, large, readable and isolated on transparent alpha. It must not contain a room, landscape, character scene, card frame, title or text. The object should occupy roughly 60–80 percent of its square canvas.

Relic color is a gameplay promise, not decorative rainbow lighting: attacks are orange, block is blue, buffs are purple, debuffs are green, and relics that directly grant Overkill are blood red. Mixed-color relics are reserved for genuinely mixed effects; a neutral metal base may support the essence color, but must not erase it. Art direction also varies by object material and silhouette so a relic lineup does not read as the same crystalline device repeated with different glows.

### Events and story pages

Events and story pages use full cinematic scenes to communicate a place, story beat or action. This is where scenery artwork belongs. Event options should add a contextual crop rather than an unrelated symbol floating in empty UI. Legacy card resources remain only for save compatibility and engine tests; they are not a UI design template.

### Backgrounds and transitions

Backgrounds are cinematic 16:9 environments or abstract transition compositions. They should use cyan/amber light, crystalline fracture motifs, monumental ruined or industrial-fantasy architecture and clear negative space for interface text.

## Retired direction

Do not reintroduce any of the following:

- Conventional medieval black-iron or brass clockwork objects as the dominant lineup style.
- Generic gothic knights, crusaders, skeleton atlases or unrelated rigged character models.
- Flat comic-style crypt environments.
- Full scenery paintings used as relic thumbnails.
- A separate 3D boss presentation with a different playable character.
- Ornate medieval filigree, dirty brown monochrome, steampunk gears or brass dials as the dominant visual language.

The retired rigged 3D combat pipeline, mismatched knight/skeleton atlases, medieval relic scenes, old clockwork arena and comic crypt background are not part of the active game direction. All combat now uses the same illustrated character system and approved Executioner identity. The obsolete arena plate containing baked-in fighters is removed; live combat uses character-free scenery beneath the separately rendered combatants.
