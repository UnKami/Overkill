# Overkill 0.22.0 — Character refinement and smoother relic decisions

On GitHub: **UnKami/Overkill → Releases → 0.22.0 → Assets → OverkillSetup-0.22.0.exe**. The repository homepage and **installer** folder provide the current installer and update log. After installing, choose **Play Boneghoul preview** or **Play Sentinel encounter** in the Start menu. Portable users: extract the entire ZIP and open **Play Boneghoul.cmd** or **Play Sentinel.cmd**. No Godot installation is required.

## Changes since 0.21

- Boneghoul: recessed nose and open mouth, revised jaw and teeth, segmented neck, restrained aged-bone material detail.
- Player and Sentinel: weapon handles follow the finger curl; less excessive wrist flexion at impact and recovery; eliminated sudden weapon-roll flips near overhead poses.
- Sword: swept forged crossguard, leather binding seams, metal collars and shaped pommel, retaining existing material batching.
- Relic decisions: stopped redundant shared font/theme changes that restyled the battle whenever choices appeared. In six matching Sentinel encounters on the development Intel integrated GPU, High decision-frame p95 fell from 165–173 ms to 25–28 ms. Occasional 116–163 ms stalls remain; this is not a stable-FPS guarantee.

The nine-hour clock, twelve-relic starter, persistent Block, enemy reveals and combat balance are unchanged. Preview launchers use separate local profiles. Overkill.exe opens the regular game; the wider enemy roster retains its existing presentation.

## Validation and limitations

Source checks cover Boneghoul model/motion/contact, player/Sentinel grips and swing continuity, combat contacts and guards, battle layout, settings and text-size changes. Real encounter profiling uses one muted Sentinel fight policy and one device; it does not establish whole-game performance or balance. Exported-build checks and uploaded asset hashes are verified before publication is reported.

**Still an unfinished playtest, not AAA quality.** Anatomy, hand/weapon coordination, richer motion, enemy variety, environments, sound and performance need substantial work. The Windows installer is unsigned; its interactive wizard has not been manually tested. Known certificate-store and occasional headless shutdown warnings remain.

Source tag: **v0.22.0-test**, branch **feat/yonatan-sentinel-production**. Gameplay stays on the feature branch pending review; main receives distribution documentation. Detailed evidence: `docs/sentinel-production.md`, `docs/boneghoul-production.md`, and `CHANGELOG_AI.md`.
