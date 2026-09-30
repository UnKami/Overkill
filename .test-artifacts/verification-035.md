# 0.35.0 local verification report — 2026-09-30

- Source branch: `fix/yonatan-full-ui-polish`; exact source commit is supplied by the release workflow at publication time.
- Godot 4.5.1 project editor parse completed without script/scene errors.
- `clock_polish_test.tscn` passed: 12-copy cap, full reward replacement chooser with 12 distinct IDs, shop refusal at capacity, replacement and upgraded identity, legacy vitality migration, 100-HP bosses and existing shop/combat/rest integration.
- `battle_arrival_test.tscn`, `presentation_polish_test.tscn`, `crystalline_consistency_test.tscn`, `crystalline_visual_test.tscn`, and `clock_battle_smoke.tscn` passed their explicit success sentinels. Visual coverage instantiates production screens, three maps/transitions and all ten enemies; presentation checks relic/effect text sizing, replacement layouts, inspection and resolution bounds.
- The isolated headless runs emitted the known restricted-runner root-certificate-store warning and ObjectDB/resource shutdown notices. These are not gameplay test failures.
- Full interactive campaign, pixel-level desktop acceptance, human difficulty review and installed wizard testing are not claimed by these source tests.
- No combat damage formula, enemy AI/intent, turn order, relic effect or clock rule changed. Player HP and boss HP changed as explicitly requested; save loading scales health while preserving max-HP bonuses.
