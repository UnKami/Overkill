# Overkill 0.42.0 — Articulated Relic Playtest

This playtest combines the cogwheel navigation work with the published 0.41
Artifact and interface work. The previous releases remain available for rollback.
The exact source is tagged `v0.42.0-test`, assembled on
`feat/yonatan-042-rigged-relics`. Later reviewed changes on `main` do not alter
that downloadable build.

The Executioner now has separate illustrated head, torso, cloak, arms, hands,
thighs, shins and feet on a real skeleton. Editable Blender armatures and actions
are kept with the source. Godot plays the exported bone animation at runtime.
This replaces the player's single-image attack translation with articulated
anticipation, crouch, launch, contact and recovery.

- Iron Strike summons its sword for 1.5 seconds before the attack.
- Oath Chalice tips above the character and pours purple energy.
- Guard Plate surrounds the character in blue defensive light.
- War Crown settles above the head and casts purple strengthening light.
- Vital Siphon is thrown, embeds at the enemy and returns energy along a purple
  tether. Healing reflects actual damage to Vitality and missing player health.
- Overdrive Piston throws toward the enemy and carries the next-attack multiplier
  to the combatant's status area.
- Bastion Bell rings for two seconds, then shows defensive energy and the actual
  Block gained, including the base +10 Block.

The rest of the relic catalog uses matching melee, thrown, defensive, channel,
status and draining choreography. Fast Mode accelerates the authored sequence;
reduced motion keeps effect identity and outcome feedback with less movement.

The cog map adds 18 connected gears per act, three encounter seats per gear,
two forward route choices and a timing pointer. Late arrival catches the nearest
seat. Old in-progress route saves retain the legacy map; cog saves restore their
gear and seat. The existing shop Artifacts, altar replacement choice, upgrade
preview and full-Vitality rest fix are included.

## Compatibility and verification

The animation work preserves damage, relic effects, turn order, enemy rules,
progression and the twelve-copy inventory. Integration review also repairs a
healing Artifact reviving a player after lethal damage: healing now requires
the player to be alive.

An optional checkpoint field makes Continue restore unfinished encounters,
reward offers, altar purchases and boss departures. Combat restarts at its entry
state, restoring health and currency together. Old saves remain readable; an
older save stranded on a boss node conservatively replays that guardian because
the old format did not record whether the fight or altar had finished.
Legacy node-map regeneration now uses only the run's seeded random generator.
Its layout can change once from an older build, whose routes were not reliably
reproducible. Cog-map generation is unchanged. Very old saves still use the
existing proportional health migration and twelve-copy inventory limit.

Forecasts now retain lethal multi-hit Overkill, queued conditional-strike bonuses
and enemy Siphon deductions. When run Artifacts are held, the forecast explicitly
identifies its estimates as excluding Artifact triggers.
No player-facing autoplay is added. Automated fixtures use isolated save folders.

Development verification uses `scripts/dev/run_godot.ps1`: full project scenes,
the Compatibility renderer and writable, isolated APPDATA/LOCALAPPDATA. Two
auxiliary standalone engine checks crashed during startup in the restricted
automation environment. Subsequent full-project native launches completed with
exit code zero; this does not establish the exact cause of the earlier crash.
The shipped project now defaults to the same tested Compatibility renderer.
Asset import uses one thread after a bulk reimport terminated in the clean-build
environment. This changes editor import scheduling, not gameplay threading.

Source, rendered-screen, exported-payload and download checks are recorded in
the version-specific verification report attached to the release. This is an unsigned
playtest, and no final human visual approval or full human campaign is claimed.
