# Overkill 0.33.0 — UI alignment and relic presentation playtest

## Player-facing changes

- The new-journey confirmation is aligned to the title screen's established content column. The underlying menu column is removed while the consequential choice is open and restored on Cancel.
- Map tiers have substantially more vertical breathing room. Long routes now scroll with an auto-visible scrollbar, and the screen explicitly tells players to scroll to survey the ascent.
- The three pre-battle offer choices retain their concise title/action copy while bringing back distinct context paintings: the Memory Forge for a relic upgrade, the overflowing cache for Overkill, and the humming shrine for Vitality.
- Relic objects no longer sit in broad square radial haze. Fine, bright broken-line rays carry the relic's essence color behind the isolated object, with subtle reduced-motion-aware drift. Relic names, effects and actions remain readable, and the square panel surfaces stay transparent.

## Compatibility and rules

No damage, enemy behavior, relic effects, turn order, clock rules, progression or save schema changed. Existing saves remain compatible. No autoplay was added.

## Verification

Godot 4.5.1 source suites passed: `map_ux_test.tscn`, `presentation_polish_test.tscn`, `crystalline_consistency_test.tscn`, `clock_battle_smoke.tscn`, and `crystalline_visual_test.tscn`. The latter instantiates the production pages, map/transition screens and all ten enemies, and checks title confirmation alignment/restore behavior; it was run headlessly, so it does not claim pixel-level screenshot acceptance. The exported Windows payload, portable archive, installer and published release are verified separately in the version-specific report below.

This is an unsigned Windows playtest prerelease. A new run is recommended for reviewing route scrolling and the three offer choices. Final human visual acceptance and a full campaign playthrough remain open.
