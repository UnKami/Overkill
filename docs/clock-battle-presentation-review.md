# Clock battle presentation and implementation review

This first-pass review is superseded by [the clock polish delivery](clock-polish-delivery.md), which implements the reserve inventory, enemy profiles, and character animation described here as gaps.

Updated 16 September 2026.

The new dual-clock battle exists in the native Godot project. This pass upgrades its presentation without replacing the 12-hour assembly and quadrant-sweep rules. The existing workspace contained extensive uncommitted Antigravity work; it was preserved.

## Implemented presentation

- New cathedral arena plate with cyan/amber lighting, haze, mechanical architecture and space for the battle controls.
- New clean bronze dial with no painted hands or numerals. The actual hand, ticks, hour focus, sockets and quadrant indicators are live game elements.
- Larger clocks, circular art masks, recessed metal sockets, forged hands and slow inner energy arcs.
- Larger relic choices, staged reveals, stable hover animation, visible role colors and readable descriptions.
- Full-width top HUD, live battle HP, combatant health tracks and status summaries.
- Relic-to-combatant energy relays, sequential attack anticipation/impact/recovery, existing slash/spark/overkill effects, and cached synthesized mechanical SFX honoring master/effects volume.
- Battle entrance fade, phase-change pulse, and victory/defeat fade-out.
- Keyboard activation for eligible clock sockets.

## Correctness changes made during the review

- Reject duplicate selections and overlapping sweeps while the authoritative resolution is running.
- Clock hands advance forward across 12-to-1 instead of rewinding through the clock.
- The HUD reads live combat HP rather than the previous run snapshot, and hides obsolete card-energy counters.
- Siphon references the actual `current_ok` property rather than the nonexistent `total_overkill` property.
- Recoil Piston now grants its declared block on overkill.
- Empty reserve decks display an explicit sweep instruction.
- Outcome presentation clears obsolete choices and stops socket input.

## Important remaining engine gaps

1. **Reserve deck:** `_init_player_deck()` creates exactly 12 starter relics. Assembly binds all 12, so the first quadrant turn has no relic available to draw. The UI now explains this, but adding reserve inventory or a different draft rule requires a design decision. No duplicate relics were invented here. The hot-swap test supplies an explicit reserve fixture.
2. **Enemy identity:** enemy intent arrays are generated from one fixed strike/shield/heavy-strike pattern. Enemy resources currently supply HP and art, not distinct clock behavior. The twin-hand and reverse-hand bosses in the new specification are not implemented.
3. **Encounter cardinality:** only the first enemy in the incoming encounter drives this battle. Multi-enemy encounter data is not represented by the new clock controller.
4. **Run progression:** the clock deck is rebuilt from starter files each combat. Existing card rewards, shop inventory, saved decks and upgrades need a deliberate migration to clock relics.
5. **Status coverage:** enemy bleed/vulnerability intent fields are not yet resolved, and socket modifiers need a complete assignment/balance audit.
6. **Production art and audio:** combatants still use existing static sprites with motion effects. Rigged character attacks, a scored soundtrack, authored sound design, distinct enemy telegraphs and an equivalent pass across every other screen remain outside this battle presentation pass.

This is a playable battle presentation upgrade, not a claim that the entire game meets AAA production standards.

## Verification

Godot 4.5.1 from the official godotengine/godot-builds release was used locally. `scenes/clock_battle_smoke.tscn` is the repeatable runtime fixture. It covers all 12 assembly hours, double-selection protection, all four quadrant sweeps, hot-swap with an explicit reserve, forward hand wrap, mute behavior and a single victory signal. Rendered screenshots are written to `artifacts/clock-battle/` at 1920×1080 and 1280×720. These use controlled high-health fixtures to reach later phases; they are not balance measurements.

The environment reports a Windows root-certificate-store warning at engine startup. Editor import also reports failure to save editor settings in the restricted profile. Neither is a battle script or shader failure. No installer was rebuilt and no hosted release was deployed.

## Generated artwork provenance

Generated with the built-in imagegen tool; selected outputs copied into the project. Original assets remain in place.

### `assets/environments/chronoforge_arena.png`

Final prompt:

> Use case: stylized-concept. Asset type: production background plate for an existing dark fantasy clockwork battle game, landscape 16:9. Create a lavish cinematic realistic 3D rendered subterranean chronomancer cathedral, weathered blackened bronze machinery, huge ancient clock mechanisms set into distant architectural arches, layered volumetric mist, tiny floating embers, restrained cyan light from left and amber fire from right, deep charcoal and antique gold palette. Composition must support UI: dark low-detail left and right middle areas for two large interactive circular clock faces, a subtly illuminated distant central altar, bottom quarter very dark for relic choice UI. Architectural depth, physically convincing stone and metal, dramatic sophisticated lighting, rich details at perimeter only. No characters, no foreground clock faces, no interface, no lettering, no numbers, no logo. This is an atmospheric environment plate, not a screenshot or mockup.

### `assets/ui/combat/chronometer_dial_clean.png`

Final prompt:

> Use case: stylized-concept. Asset type: isolated game clock mechanism texture, square. A perfectly circular ancient magitech clockwork dial photographed exactly front-on, orthographic, centered, fills 94 percent of square frame on pure black. Exquisite photoreal blackened bronze and antique brass concentric rings, fine machined bevels, subtly glowing cyan filaments, layered mechanical relief. Outer rim precision teeth, inner rings ornamental radial engraving and concentric tracks. Center 60 percent should be dark machined metal with subtle low contrast concentric engraving. CRITICAL no clock hands or pointers at all, no numerals, no readable writing, no symbols resembling numbers, no radial spokes across the center, no interface, no attached objects. The game adds its own moving hand, 12 item sockets and labels. Balanced sophisticated cinematic PBR material, restrained highlights, symmetrical circle suitable for masking to a circle.
