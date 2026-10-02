# Overkill 0.41.0 — Crystalline Playtest

This playtest adds four distinct run-wide Artifacts to the Clockwright's shop,
bringing the pool to eight. Artifacts are separate from the twelve relics bound
to the Chronometer; one may be purchased per shop visit. The new items trigger
on attacks, Block relic activations, kills, or incoming damage and have their
own crystalline art and combat activation cues.

Combat feedback has been tightened: pointer travel and between-tick pauses are
shorter, while attack travel and impact beats retain their deliberate weight.
The next enemy now fades out and enters with a brief handoff. Lethal Bleed and
Thorns hits correctly notify kill-trigger Artifacts. At full Vitality, Rest is
disabled and the Sanctuary focuses the useful alternatives instead of allowing
a no-op visit.

## Compatibility and playtest notes

- Existing saves remain compatible. A new run is recommended to inspect the
  full shop Artifact pool and its per-run acquisition rules.
- The 12-relic bound roster, damage values, clock order, and existing relic
  effects are unchanged by the cadence pass.
- This is an unsigned prerelease. Automated regression suites pass, but a full
  human campaign and broad balance acceptance are still needed.
- Godot may log the environment's root-certificate-store warning and selected
  non-fatal ObjectDB shutdown notices during headless test runs.
