# Overkill 0.36.0 — Essence Sunburst Presentation Playtest

## What changed

Relic presentation now uses 15 transparent crystalline radial sunbursts behind the relic object: one each for Attack (orange), Block (blue), Buff (purple), Debuff (green), and Overkill (blood red), plus all ten two-essence combinations. The shared pedestal resolves artwork from primary and secondary essence so selection, reward, archive, shop, upgrade and battle displays stay consistent. The relic silhouette remains in front of the halo.

No combat math, relic effects, turn order, map rules, save schema or progression values changed. Existing saves remain compatible.

## Verification

- Godot 4.5.1 imports the full image family and project scripts.
- `crystalline_visual_test.tscn` checks relic signatures resolve to the correct transparent assets and renders the production reward UI.
- Release verification report: [verification-036.md](../.test-artifacts/verification-036.md).

The installer is unsigned. Automated export/install checks do not substitute for a complete human campaign playthrough or manually exercising the installer wizard.

## Release source

The `v0.36.0-test` prerelease identifies the exact feature-branch source commit and provides the Windows installer, portable ZIP, and SHA-256 manifest. Main carries the reviewed download documentation; experimental gameplay remains on the feature branch.
