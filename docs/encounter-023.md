# Overkill 0.23.0 — Armor, cloth and battle surface refinement

Partner navigation after publication: **UnKami/Overkill → Releases → 0.23.0 → Assets → OverkillSetup-0.23.0.exe**. Install, then open **Play Sentinel encounter** or **Play Boneghoul preview** from the Start menu. Portable users: extract the entire ZIP and run **Play Sentinel.cmd** or **Play Boneghoul.cmd**. No Godot installation required.

## Changes since 0.22

- Sentinel: fitted palms, articulated finger plates and closed fingertips; distinct guarding and recoil hand gestures; fluted shoulder shells and shaped knee cups.
- Both rigged fighters: smoother cape folds, restrained woven edging and bounded cloth follow-through driven by body movement. Reduced motion disables the added movement.
- Arena: varied stone roughness and restrained normal relief on the floor and stairs.
- Relics: mipmapped choice and clock artwork reduces noisy edges at small display sizes.

The nine-hour clock, twelve-relic starter, persistent Block, enemy reveal rules and balance are unchanged. Preview launchers use separate local profiles. Overkill.exe opens the regular game. The wider enemy roster retains its existing presentation.

## Validation and limitations

Source checks include rendered armor and cloth inspection, reaction and weapon-contact regressions, reduced-motion/layout checks, Vulkan/OpenGL material checks, and cape response at simulated 30/60/120 Hz. Packaged-build checks and uploaded hashes must pass before publication is reported.

**Still an unfinished playtest, not AAA quality.** Anatomy, natural hand/weapon coordination, authored textures, animation breadth, environments, sound and performance need further work. Cloth uses procedural drape and bounded lag, not physical collision simulation. Recent performance measurements were affected by concurrently running games; this release makes no performance improvement claim. The installer is unsigned and its interactive wizard has not been manually tested. A known development-machine certificate-store warning remains.

Intended source tag: **v0.23.0-test**, branch **feat/yonatan-sentinel-production**. Gameplay source remains on the feature branch pending review; main receives distribution documentation after asset publication is verified. Detailed evidence: docs/sentinel-production.md and CHANGELOG_AI.md.
