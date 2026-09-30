# Windows installers

**[Download OverkillSetup-0.35.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/OverkillSetup-0.35.0.exe)**

[Portable game folder ZIP](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/Overkill-0.35.0-Windows.zip) · [Gameplay trailer MP4](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/Overkill_Cinematic_Gameplay_Trailer_2026-09-30.mp4) · [Release notes and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.35.0-test) · [Update log](../UPDATE_LOG.md)

Install, then start a new run. For the portable version, extract the entire ZIP and run Overkill.exe with Overkill.pck beside it. No Godot installation is required.

Compiled installers are attached to GitHub Releases rather than committed as large binary files. This folder always provides a direct link to the current delivered build, alongside the installer source and checksum files.


Launch **Overkill** for the 0.35.0 playtest: act guardians now lead to the boss-only Overkill Altar, where the banked currency can buy one of three Zenith relics. The build also includes 12-copy replacement, a larger Vitality pool, and clearer combat stats. See [detailed changes and limitations](../docs/encounter-035.md). The installer and installed app were verified in an isolated per-user test directory; the portable archive payload hashes match the export.

Exact gameplay source: `268873940b5fc96e261d1549686a6e25553bdaf1`, tag `v0.35.0-test`, feature branch `feat/yonatan-overkill-altar`. Main contains the download documentation, not the experimental gameplay merge. The installer is unsigned; prior releases remain available for rollback.
