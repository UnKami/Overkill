# Overkill 0.28.0 — Reliquary interface reconstruction

## Why this pass exists

The first 0.27 relic review image exposed a real presentation failure: a compact diagnostic component was stretched into five tall empty columns and shown as though it represented finished game UI. Strong object art was trapped inside flat developer panels, the archive environment and Executioner were absent, dual colors read as thin technical borders, and the screen had no meaningful visual hierarchy.

## What changed

- Rebuilt the shared relic card used by battle choices, rewards, shops and the Reliquary as a compact artifact frame.
- Relic objects now sit inside a dedicated illuminated display chamber and retain most of the card's visual weight.
- Primary and secondary essences form a split top rail; titles, rules plaques, borders and subtle glows inherit the same mechanical color language.
- Effects are condensed into short numerical statements instead of long paragraph blocks. Complete rules remain available in tooltips.
- Reconstructed the Reliquary around the approved cinematic archive hall. The interface occupies the darker left side while the full Executioner remains visible in the warm gallery on the right.
- Duplicate physical copies are grouped into one design card with an explicit owned count. The starter inventory therefore reads as four designs rather than twelve repetitive tiles, while the underlying twelve-copy inventory remains unchanged.
- Added a proper five-essence legend, inventory/design/socket/reserve summary, archive lore line and restrained navigation.
- Replacement choices inherit the same essence-colored metal/glass treatment instead of falling back to generic buttons.
- Rebuilt the visual review fixture so it is a cinematic composition rather than an oversized debugging contact sheet.

## Verified behavior

- `RELIC_COLOR_LANGUAGE_OK`: 26 relics, exact essence/mechanic mapping, real Overkill gain and dual-effect resolution remain unchanged.
- `BATTLE_ARRIVAL_OK`: collection navigation, battle entry and the existing 14-damage Heavy Hammer rules remain intact.
- `BATTLE_GUIDANCE_OK`: allocation, replacement and sweep previews remain non-mutating and accurate.
- `PRESENTATION_014_OK`: all 26 effects fit at normal and large text sizes; battle choices, replacement controls, 720p and ultrawide layouts remain within safe bounds.
- `RELIC_COLOR_VISUAL_OK`: the five-essence gallery, dual-bound gallery and real Reliquary were rendered at 1920×1080 and visually inspected.

The exported `Overkill.pck` independently passes `RELIC_COLOR_LANGUAGE_OK`, `BATTLE_ARRIVAL_OK`, `BATTLE_GUIDANCE_OK`, and `PRESENTATION_014_OK`. The packaged presentation test covers all 26 relics at normal and large text sizes, replacement controls, 720p and ultrawide layouts.

## Local Windows candidate

- Source commit: `d87fe7522e882e6a2b0974f68f0e289f193bc366` on `fix/yonatan-relic-ui-polish`.
- Installer: `installer/OverkillSetup-0.28.0.exe` — 277,075,828 bytes — SHA-256 `94fd0bed6309246bee2e1fc8d0e7a865da13f0703f13a3e734a967cf326dd462`.
- Portable ZIP: `installer/Overkill-0.28.0-Windows.zip` — 305,972,073 bytes — SHA-256 `89f0b6f7993c2d4c337b370a3203882726c1a09ce70c16474414a70dab854e38`.
- The ZIP contains exactly the tested executable, pack, license, delivery notes and launcher. Every entry hash matches the local build payload.
- This is an unsigned local candidate. It has not been pushed, tagged, uploaded or published on GitHub; the public 0.25.0 links remain unchanged.

## Scope and limitations

No relic values, starter counts, combat outcomes, clock rules or progression mechanics changed. No autoplay was added. This corrects the relic-facing presentation layer; it is not a claim that every unrelated screen in the game has reached final visual quality. Human full-run review and interactive installer-wizard testing remain separate gates. The build was made from the feature working tree at the source commit above while unrelated pre-existing audio/card import-metadata edits remained present and untouched.
