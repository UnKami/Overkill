# Overkill 0.27.0 — Five Essences relic playtest

## What changed

The chronometer now has a consistent five-color relic language. Orange means attack, blue means persistent Block, purple means a beneficial buff, green means an enemy debuff, and blood red is reserved for relics that directly generate Overkill. Dual-color relics always perform both effects they advertise.

The lineup expands from fourteen to twenty-six active relics. Every relic has a newly generated, centered transparent object render in the approved painterly-real crystalline magitech direction. The existing starter composition remains unchanged, while the additional common and rare objects enter normal content pools for shops and rewards.

Blood Tithe, Butcher's Abacus, Crimson Reservoir, Oath Chalice, and Debt Leech introduce direct Overkill generation. This is real run currency: the gain updates the HUD, appears in battlefield forecasts, can be spent normally, and is visually identified by blood red. The former Blood Siphon is now Vital Siphon so blood terminology remains exclusive to the Overkill essence.

## Readability and lore

- The reliquary teaches all five colors with a permanent legend.
- Cards and clock sockets inherit their primary essence color.
- Dual-bound cards add a visible secondary-color edge.
- Tooltips name the complete binding and retain numerical effects.
- Damage, Bleed, Thorns, and Overkill feedback now follow the same orange, green, purple, and blood-red meanings.

The complete lore, lineup, and mechanical contract are documented in [relic-color-language.md](relic-color-language.md).

## Verification

- `RELIC_COLOR_LANGUAGE_OK`: 26 unique relic resources, five primary essences, exact mechanic-to-color validation, complete object art, direct Overkill resolution, and representative dual-effect combat ticks.
- `STARTER_RELIC_OK`: the 12-copy starter composition and prior block, attack, charge, lifesteal, intent, and battle-reset rules remain intact.
- `ENCOUNTER_PLAYTHROUGHS_OK`: the deterministic encounter suite completes with its established outcomes.
- `PRESENTATION_014_OK`: choice layout, text metrics, previews, inspection, 720p large text, and ultrawide checks pass with all 26 relics loaded.
- `RELIC_COLOR_VISUAL_OK`: focused five-essence and dual-binding card sheets were rendered and reviewed; compact badges no longer collide and the secondary edge is readable.

## Scope and limitations

This is a playtest balance expansion. The color contract and mechanics are verified, but the twelve new relic values still need human full-run balance review. The update is save-compatible because existing relic ids and starter composition are preserved; a new run is recommended to encounter the expanded pool. No autoplay is added.

The local Windows candidate is unsigned. Interactive installer-wizard testing and GitHub publication remain separate delivery gates.
