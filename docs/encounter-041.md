# Overkill 0.41.0 — Crystalline Cogwork Playtest

This playtest adds four distinct run-wide Artifacts to the Clockwright's shop,
bringing the pool to eight. Artifacts are separate from the twelve relics bound
to the Chronometer; one may be purchased per shop visit. The new items trigger
on attacks, Block relic activations, kills, or incoming damage and have their
own crystalline art and combat activation cues.

The ascent map is now a deterministic lattice of 18 interlocking cogwheels.
Each gear exposes three event seats; after an event, choose one of two
connected forward gears, then time the arrival pointer. The nearest seat catches
a late input, so timing affects the landing without causing a dead-end miss.
Rest, shop and encounter seats are integrated into the existing destination
flows. Each guardian approach offers a rest seat before the act boss.
Legacy saves with a pre-cog map location continue on the original route screen;
new runs and cog-lattice saves use the new map. The saved cog and seat restore
after an event without changing the save schema.

Combat feedback has been tightened: pointer travel and between-tick pauses are
shorter, while attack travel and impact beats retain their deliberate weight.
The next enemy now fades out and enters with a brief handoff. Lethal Bleed and
Thorns hits correctly notify kill-trigger Artifacts. At full Vitality, Rest is
disabled and the Sanctuary focuses the useful alternatives instead of allowing
a no-op visit.

## Compatibility and playtest notes

- Existing saves remain compatible. Legacy in-progress maps are preserved; a
  new run is recommended to experience the cog lattice and inspect the full
  shop Artifact pool.
- The 12-relic bound roster, damage values, clock order, and existing relic
  effects are unchanged by the cadence pass and map implementation.
- This is an unsigned prerelease. Automated regression suites pass, but a full
  human campaign, timing usability review and broad balance acceptance are
  still needed.
- Godot may log the environment's root-certificate-store warning and selected
  non-fatal ObjectDB shutdown notices during headless test runs.
