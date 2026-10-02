# Windows installers

**[Download OverkillSetup-0.41.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.41.0-test/OverkillSetup-0.41.0.exe)**

[Portable game folder ZIP](https://github.com/UnKami/Overkill/releases/download/v0.41.0-test/Overkill-0.41.0-Windows.zip) · [Checksum manifest](https://github.com/UnKami/Overkill/releases/download/v0.41.0-test/OverkillSetup-0.41.0.sha256) · [Release notes and assets](https://github.com/UnKami/Overkill/releases/tag/v0.41.0-test) · [Update log](../UPDATE_LOG.md)

Install, then start a new run to explore the expanded run-wide Artifact pool. For the portable version, extract the entire ZIP and run Overkill.exe with Overkill.pck beside it. No Godot installation is required.

Compiled installers are attached to GitHub Releases rather than committed as large binary files. This folder always provides a direct link to the current delivered build, alongside the installer source and checksum files.

The 0.41.0 playtest adds four unique run-wide Artifacts to the Clockwright shop, distinct from the twelve bound Chronometer relics. It also improves combat transition pacing, lethal Bleed/Thorns kill triggers, and full-Vitality Sanctuary choices. See [detailed changes and limitations](../docs/encounter-041.md).

Exact gameplay source: `6e16d250e97162e78fe53d19c60374241a50bdc2`, tag `v0.41.0-test`, feature branch `feat/yonatan-040-artifacts-block-balance`. Main contains the download documentation, not the gameplay merge. The installer is unsigned; previous releases remain available for rollback. The installer compiled, but its interactive setup wizard and installed payload were not verified; the extracted portable payload did launch headlessly.
