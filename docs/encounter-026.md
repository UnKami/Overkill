# Overkill 0.26.0 — Cinematic Worlds playtest

## What changed

This update expands the approved painterly-real shop/rest direction into a coherent 30-scene visual library. Title, class selection, maps, events, rewards, relic collection, upgrades, act transitions, loading and run outcomes now use contextual character-led art featuring the canonical Executioner. Twelve separate character-free arena plates cover regular, elite and boss encounters across all three acts so live combatants remain the only characters in battle.

The original `shop_bg.jpg` and `rest_site_bg.jpg` remain preserved and active. They are the visual anchors for the expansion, not assets being replaced.

## Environmental motion

Full-screen art receives slow camera drift, restrained cyan/amber light breathing and sparse atmospheric motes. The treatment is deliberately subtle and lives below all UI. Reduced-motion mode disables it and leaves the still composition intact.

## Preserved gameplay

Damage values, enemy AI, clock mechanics, relic mechanics, turn order, ability effects, stats, progression, battle outcomes and run rules are unchanged. This update adds no autoplay and no balance changes.

## Verification

- Godot 4.5.1 clean script/import pass.
- `CINEMATIC_ART_TEST_OK paths=30 unique=30` verifies resource presence and deterministic map/event/encounter routing.
- `BATTLE_ARRIVAL_VISUAL_OK` passes with rendered 1080p/720p and ultrawide captures.
- The real frontend flow is rendered across title, class, map, settings, rest, shop, event, reward, victory and defeat; representative frames were manually reviewed for readability and composition.
- Source art was reviewed individually for character identity, negative space, text-free output and coherent cyan/amber world direction.

## Scope and limitations

This is a visual-acceptance playtest, not final art acceptance for every future act or event. The paintings use restrained 2.5D motion rather than skeletal animation or generated video. Broad hardware frame-time testing and human full-run/boss-balance testing remain open. The Windows installer is unsigned and its interactive wizard is not manually stepped through during automated packaging.

Start a new run to review the full art progression. Existing saves remain compatible.
