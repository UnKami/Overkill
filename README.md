# Overkill

## Download and test

**[Download the Windows installer — 0.41.0 playtest](https://github.com/UnKami/Overkill/releases/download/v0.41.0-test/OverkillSetup-0.41.0.exe)**

[Portable Windows ZIP](https://github.com/UnKami/Overkill/releases/download/v0.41.0-test/Overkill-0.41.0-Windows.zip) · [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.41.0-test/OverkillSetup-0.41.0.sha256) · [Release notes and assets](https://github.com/UnKami/Overkill/releases/tag/v0.41.0-test) · **[Update log](UPDATE_LOG.md)**

Start a new run to explore four new run-wide Artifacts in the Clockwright's shop. These are separate from the twelve bound Chronometer relics. This build also improves combat transition pacing, lethal Bleed/Thorns kill triggers, and the full-Vitality Sanctuary choice. [Detailed changes and testing limits](docs/encounter-041.md).

This is an unsigned prerelease. Six Godot 4.5.1 suites, the exported portable payload, and an extracted headless launch passed. The installer compiled, but its interactive setup wizard and installed payload were not verified. Full human-campaign balance and final visual acceptance remain open.

## Partner sync

Every delivered gameplay feature or update has a versioned GitHub Release, downloadable Windows installer, and entry in the [update log](UPDATE_LOG.md). Release notes identify the exact source commit, test results, known issues, and save compatibility. Downloads live in Releases; the [installer folder](installer/README.md) provides direct links.

The 0.41.0 playtest was built from source `6e16d250e97162e78fe53d19c60374241a50bdc2`, tagged `v0.41.0-test`, on `feat/yonatan-040-artifacts-block-balance`. Gameplay remains on a feature branch; these default-branch links identify the tested build separately from main's source state. Previous releases remain available for rollback.

[AI collaboration instructions](AGENTS.md) · [Technical handoff log](CHANGELOG_AI.md) · [Active work](ACTIVE_WORK.md)
