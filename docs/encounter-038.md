# Overkill 0.38.0 — Altar and battle-focus playtest

## What changed

- Recomposed **The Overkill Altar** around the center of the screen. The altar remains visible through a lighter, ceremonial offer surface; the Overkill balance, three Zenith choices and continue action share one clear, symmetrical focus.
- The forge now presents every physical relic copy separately, numbered within its design family, with an independent upgrade action and instance-specific preview. It no longer folds five copies into one `×5` relic.
- Upgrade confirmation now properly veils the unrelated forge beneath it, making the before/after relic comparison the only visual focus.
- Battle combatants are another 20% larger than the previous release. Relic choices are tightened and raised to preserve a clear silhouette gap, while retaining the relic artwork, effect copy and bind action.

No combat math, relic effects, turn order, map rules, progression values or save schema changed. Existing saves are compatible.

## Verification

- Godot 4.5.1 `presentation_polish_test.tscn` passed `PRESENTATION_014_OK`, including 720p/1080p/ultrawide bounds, normal/large text, readable relic rules, card art and in-bounds actions.
- Godot 4.5.1 `crystalline_visual_test.tscn` passed `CRYSTALLINE_VISUAL_OK`, covering the production screen collection, individual forge instances, the focused upgrade veil, centered altar composition, three acts/transitions and all ten enemy presentations.
- Package build, exported payload, portable ZIP, installer and public asset verification are recorded in the attached release verification report.

The installer is unsigned. Automated UI checks do not replace a complete human campaign playthrough or interactive installer-wizard testing. Restricted Windows runs can report a certificate-store warning; Godot may emit a non-fatal ObjectDB shutdown notice.

## Release source

The `v0.38.0-test` prerelease identifies the exact feature-branch source commit and provides the Windows installer, portable ZIP and SHA-256 manifest. Gameplay remains on its feature branch; default-branch download links are supplied through a documentation-only PR.
