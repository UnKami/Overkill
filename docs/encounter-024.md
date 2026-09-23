# Overkill 0.24.0 — Battle arrival and combat readability

Partner navigation after publication: **UnKami/Overkill → Releases → 0.24.0 → Assets → OverkillSetup-0.24.0.exe**. Install and launch **Overkill** to play the normal campaign. The separate **Play Sentinel encounter** shortcut remains an experimental 3D development showcase; it is not the campaign's default boss presentation.

## Changes since 0.23

- Cleaned the Executioner entry screen and relic collection: the primary action is now **Standart Battle**, the introductory stat/explanation clutter is gone, and owned relic cards no longer display a redundant collection action.
- Added a reusable center-out vortex transition to map destinations and other scene changes, including reduced-motion fades.
- Added one optional three-choice offer before the first battle of each act. Choices currently upgrade a card, bank 10 Overkill, or grant 3 maximum Vitality. The selected option resolves visibly before combat.
- Added a dedicated card-upgrade selector with lift/hover feedback, transformation animation, gold treatment, and persistent `+` upgrade state.
- Added a short gated battle introduction: arena reveal, `BATTLE START`, clock reveal, player entry and HP fill, enemy entry and HP fill, then the first interactive choice.
- Moved HP, Block, Strength and other combat state from the clocks to panels owned by each combatant. Clocks sit farther outward and the middle of the arena has more room for attacks.
- Heavy Hammer (`REL-03`) now has reusable attack staging: anticipation, forward launch, authored glowing hammer sprite, swing, contact flash, particles, hit-stop, recoil, damage number and recovery. Its damage remains exactly 14.
- Normal campaign bosses now retain the illustrated Executioner and illustrated battle language. The unmatched 3D player model is kept in the explicit development showcase rather than silently replacing the campaign character.

## Validation and limitations

Source validation covers starter composition/effects, non-mutating battle guidance, 30 live resolution previews, encounter playthroughs, enemy intents, finish modes, 720p/1080p/ultrawide layouts, reduced motion, pre-battle save state, campaign boss presentation, and unchanged Heavy Hammer damage. Rendered review includes the cleaned entry/collection screens, all offer and upgrade states, vortex midpoint, every battle-intro phase, both target resolutions, and Heavy Hammer wind-up/contact/reaction frames.

Save compatibility is preserved. Older saves do not contain the per-act offer history, so their next battle in the current act may present the new offer once. The 3D Sentinel/Boneghoul scenes remain prototype showcases with visibly unfinished character art and frame pacing. The installer is unsigned, and a known development-machine certificate-store warning remains. No autoplay was added.

Intended source tag: **v0.24.0-test**, branch **feat/yonatan-battle-arrival**. Gameplay remains on the feature branch pending review; main receives distribution documentation only after uploaded assets are verified.
