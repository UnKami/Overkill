# Overkill 0.37.0 — Battle and decision-screen clarity playtest

## What changed

- Enlarged illustrated battle combatants by 20% and restored character-owned vitality, Block and status readouts in a dedicated readable band.
- Removed the retired procedural relic spokes. The shared relic view and the replacement choices now use the dedicated color-matched crystalline sunburst artwork.
- The Reliquary lists each owned relic copy separately instead of folding duplicates into an owned count.
- Reworked the full-sector replacement alternative into a clear header action: keep the bound relics, discard the drawn relic, and resolve the displayed sweep. Replacement options remain individually selectable.
- Humming Shrine consequences and full-clock restrictions are explained inline. The Zenith altar's more transparent offer surface preserves the scenic background.
- Removed redundant phase banners that covered the combatants during relic decisions.

No combat math, relic effects, turn order, map rules, progression values or save schema changed. Existing saves remain compatible.

## Verification

- Godot 4.5.1 `presentation_polish_test.tscn` passed `PRESENTATION_014_OK`, including normal/large text and 720p/1080p/ultrawide checks.
- `crystalline_visual_test.tscn` passed `CRYSTALLINE_VISUAL_OK`, covering production screens, all three maps/transitions, all ten enemies, individual collection copies, shrine consequences, Zenith transparency and character/stat geometry.
- Rendered Reliquary, shrine, Zenith, combat assembly and sector replacement states were inspected.
- Exact package and published-asset verification is recorded in `.test-artifacts/verification-037.md`.

The installer is unsigned. Automated UI checks do not replace a complete human campaign playthrough or manual interactive installer-wizard testing. Restricted Windows runs report a root-certificate-store warning; Godot's crystalline fixture also emits a non-fatal shutdown ObjectDB notice.

## Release source

The `v0.37.0-test` prerelease identifies the exact feature-branch source commit and provides the Windows installer, portable ZIP and SHA-256 manifest. Gameplay remains on its feature branch; default-branch download links are supplied through a documentation-only PR.
