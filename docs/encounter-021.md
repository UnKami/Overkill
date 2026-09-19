# Overkill 0.21.0 — Boneghoul 3D Preview

On GitHub: **UnKami/Overkill → Releases → 0.21.0 → Assets → OverkillSetup-0.21.0.exe**. The repository homepage and **installer** folder also point here. After installing, open **Play Boneghoul preview** from the Start menu. For the portable ZIP, extract the entire folder and open **Play Boneghoul.cmd**. No Godot installation is required.

The Boneghoul launcher uses a separate local profile. **Play Sentinel encounter** remains available, and **Overkill.exe** opens the regular game. The preview has a Fight again button after victory or defeat. Regular encounters retain their existing presentation unless launched with the Boneghoul preview option.

## Changes since 0.20

- Original skinned 3D Boneghoul, with exposed skeleton, recessed eyes, folded mantle, articulated claws and four material surfaces.
- Authored idle, claw anticipation/contact/recovery, protective brace, recoil and seated collapse.
- Full blocks raise the forearm before impact; the sword, sparks and small guard pulse meet that defense. Partial blocks still allow HP damage.
- Claw impacts use the finger contact position. Damage remains synchronized with the animation at normal and fast speed.
- Collapse finishes before the fade and result screen. Reduced-motion settings are supported.
- Fixed a shared weapon transform conflict that could move a sword or hammer after its contact position had been calculated.

## What this preview is for

Compare attack readability, block timing and the complete fight/result/retry loop. The nine-hour clock, twelve-relic starter, persistent Block, enemy reveals, damage rules and save format are unchanged. The Boneghoul has its normal 16 HP. This is an early encounter, not a long boss fight.

**This is not AAA completion.** Anatomy, material detail, cloth deformation, hand/weapon grips, animation variety, the wider enemy roster, environments, audio review and balance need further production work. The model remains a visible art study. Frame pacing has not been accepted across hardware; use High/Balanced/Performance settings as appropriate. This release does not claim a measured performance improvement.

## Validation and limits

Source validation includes eight rendered victory/defeat x normal/fast x reduced-motion combinations; full/partial block, damage-at-contact, world-space effects and collapse timing; 720p presentation review; a relic-choice playthrough; and existing clock/contact regressions. Exported-build checks are performed before publication. These checks do not establish complete game quality or full-run balance.

The Windows installer is unsigned. Its interactive installation wizard has not been manually tested. Known certificate-store and occasional headless exit warnings remain. Installer, portable ZIP and SHA-256 checksums are attached to the release; uploaded digests and download availability are verified after publication.

Source tag: **v0.21.0-test**, branch **feat/yonatan-sentinel-production**. Gameplay stays on the feature branch pending review; main receives distribution documentation. Development details: `CHANGELOG_AI.md` and `docs/boneghoul-production.md`.
