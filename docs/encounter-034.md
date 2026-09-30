# Overkill 0.34.0 — Battle rhythm and impact playtest

## Player-facing changes

- Clock hands now travel at a crisp connective pace in normal mode, independently of the deliberately weighty combat impacts. Fast Mode still accelerates both.
- Ordinary player attacks have a measured, readable motion; multi-hit relics use a quicker combo cadence; high-damage strikes have a longer wind-up, wider travel and stronger impact; the Executioner's heavy hammer keeps its signature extra-weighted slam.
- Enemy attacks now have their own motion and impact profiles. Dangerous single hits telegraph longer and land harder, while multi-hit intents move through a faster flurry rhythm.
- Defender recoil and recovery follow the incoming strike profile. Enemy impact accents and screen shake now match the strike's weight.

## Compatibility and rules

Presentation only. Damage values, hit counts, enemy decisions, turn order, clock rules, relic effects, progression and save schema are unchanged. Existing saves remain compatible. No autoplay was added.

## Verification

Godot 4.5.1 source suites passed: `clock_battle_smoke.tscn`, `presentation_polish_test.tscn`, `crystalline_consistency_test.tscn`, and `battle_arrival_test.tscn`. Each emitted its explicit success sentinel. Tests were headless; they do not claim pixel-level visual acceptance or replace a human playthrough. The exported Windows payload, installer and public release download are verified separately in the version-specific verification report.

This is an unsigned Windows playtest prerelease. Review the normal and Fast Mode battle cadence in-game; a full campaign playthrough and human visual acceptance remain open.
