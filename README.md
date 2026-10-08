# Overkill

## Latest character playtest - 0.50.0

**[Download the Windows installer - Meshy lighting playtest](https://github.com/UnKami/Overkill/releases/download/v0.50.0-test/OverkillSetup-0.50.0.exe)**

[Portable Windows ZIP](https://github.com/UnKami/Overkill/releases/download/v0.50.0-test/Overkill-0.50.0-Windows.zip) · [Release notes, screenshot and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.50.0-test) · [Editable Meshy assets](https://github.com/UnKami/Overkill/releases/download/v0.50.0-test/Overkill-0.50.0-Meshy-Assets.zip)

This **focused battle preview** adds the Meshy hero, clock entrance, directional cyan/fire lighting, metal reflections and grounding shadows. It opens directly into a playable battle and uses a separate install/save folder. Attack/hit/death gestures are still interim; this is not a full-campaign update. [Changes, verification and limits](docs/encounter-050.md).

The downloadable prerelease is built from [exact source 0b675b5](https://github.com/UnKami/Overkill/commit/0b675b5af4ddd7246637210d52f14af27d62bd65) on `feat/yonatan-meshy-character`, tagged `v0.50.0-test`. **Main has download documentation only; this experimental gameplay has not been merged.** Extract the editable asset ZIP into the tagged source checkout to reproduce the model import.

## Previous full-game release - 0.45.0

**[Download the Windows installer — 0.45.0 playtest](https://github.com/UnKami/Overkill/releases/download/v0.45.0-test/OverkillSetup-0.45.0.exe)**

[Portable Windows ZIP](https://github.com/UnKami/Overkill/releases/download/v0.45.0-test/Overkill-0.45.0-Windows.zip) · [44-second gameplay trailer (MP4)](https://github.com/UnKami/Overkill/releases/download/v0.35.0-test/Overkill_Cinematic_Gameplay_Trailer_2026-09-30.mp4) · [Release notes and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.45.0-test) · **[Update log](UPDATE_LOG.md)**

Play the **0.45.0 focused ascent playtest**: start close to the entrance wheel, choose a connected route, and follow the camera as you climb. Drag to inspect upcoming nodes and use Recenter to return to your decision. The player lands precisely inside the nearest wheel socket, with eased travel and a visible landing beat. Existing saves retain their current encounter sequence; the next act adopts the new layout. The shorter new-run pacing still needs human balance review. See [changes and testing limits](docs/encounter-045.md).

## Partner sync

Every delivered gameplay feature or update must have a versioned GitHub Release, downloadable Windows installer, and entry in the [update log](UPDATE_LOG.md). Release notes identify the exact source commit, test results, known issues, and save compatibility. Downloads live in Releases; the [installer folder](installer/README.md) provides direct links.

The 0.45.0 playtest is built from exact source `a6b060de43a5509796e3ad6acbb68c3aa07b5408` and tagged `v0.45.0-test`; reviewed source integration is recorded in [PR #32](https://github.com/UnKami/Overkill/pull/32). That immutable tag identifies the tested download even as `main` receives later reviewed changes. Previous releases remain available for rollback.

[AI collaboration instructions](AGENTS.md) · [Technical handoff log](CHANGELOG_AI.md) · [Active work](ACTIVE_WORK.md)
