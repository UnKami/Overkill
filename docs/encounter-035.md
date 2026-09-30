# Overkill 0.35.0 — relic capacity, survival balance and combat readability

## Player-facing changes

- The chronometer holds at most 12 relic copies. When a post-battle relic is claimed while full, choose the exact copy to replace; every target shows its copy number and current form. The replacement keeps the total at 12, and can be backed out of or skipped without losing the current lineup.
- Shop purchases cannot overfill a full chronometer, and full-capacity event rewards clearly explain why they are unavailable. Event choices now foreground the choice title; consequence detail appears on hover instead of crowding every button.
- Upgraded relic copies keep their own stable serial and visibly identify their upgraded form in copy-specific inspection. Identical base relics remain grouped in the archive, with all distinct copy IDs available in the tooltip.
- New runs begin at 500 Vitality, and all four progression bosses are tuned to 100 HP for this winnability playtest. Existing saves migrate proportionally to the new vitality baseline while preserving earned max-HP bonuses.
- Combatant readouts use compact HP/Block icons and numeric values. Active Strength, Bleed, Thorns, Weak and Vulnerable stacks appear as icon/value chips with short hover explanations, avoiding long status words wrapping under the fighters.
- Act guardians now open **The Overkill Altar** after defeat, replacing their ordinary relic reward. One of three boss-exclusive Zenith relics can be bought with the run's accumulated Overkill: The Last Bell (25), The Debt Crown (35), or Zenith Prism (45). Each uses supported combat effects; a full 12-copy chronometer requires choosing a specific copy to replace. Leaving keeps the bank, and the established next-act/final-boss transitions still follow.
- The new altar has its own cinematic background and three transparent relic objects. Generic Clockwright stock and ordinary battle rewards exclude these Zenith offers. A 44-second 1080p H.264/AAC cinematic gameplay trailer is generated locally in `trailer/`; the MP4 is not included in the installer.

## Compatibility and verification

- Existing run saves remain loadable. Legacy HP and max HP are scaled proportionally from the previous 75-HP baseline; existing max-HP gains are preserved. Clock relic IDs, levels and owned copies remain intact.
- Godot 4.5.1 source checks passed for `clock_polish_test.tscn`, `battle_arrival_test.tscn`, `presentation_polish_test.tscn`, and `crystalline_consistency_test.tscn`. The tests cover 12-copy reward replacement, shop capacity, unique upgraded copy IDs, HP migration, the 100-HP boss roster, combat icon/status behavior, and surrounding screen regressions.
- `trailer/altar_test.tscn` passed for Zenith exclusivity, replacement, exact currency debit and one-purchase limit; native 1080p before/after captures were visually reviewed. The trailer capture uses staged values for a deterministic montage rather than a continuous playthrough.
- Headless runs emit the known restricted Windows certificate-store warning and ObjectDB/resource shutdown notices. The full campaign and pixel-level interactive visual acceptance still require a human playthrough; this is a balance playtest.
- **Known balance risk:** 500 player HP against 100-HP bosses is intentionally generous. Evaluate the feel in a fresh full run before treating these values as final.
