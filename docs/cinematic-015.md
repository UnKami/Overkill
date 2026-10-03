# Overkill 0.15.0 — Dark Cinematic Combat Playtest

On GitHub: **UnKami/Overkill → Releases → 0.15.0 → Assets → OverkillSetup-0.15.0.exe**. A portable ZIP is beside the installer; extract all files before launching. Use **Play Sentinel** to enter the cinematic encounter directly with a separate test profile, or play a normal run to reach it.

- Worn steel and muted brass surfaces, using a new generated metal-detail texture on the rigged characters.
- Darker arena floor and ambient lighting, restrained color grading, soft contact shadows and a beveled Sentinel hammer with inset details.
- HP loss, absorbed damage, gained Block and healing now have explicit labels and signs. Simultaneous results use staggered positions.
- The activating relic name and hour appear during resolution. Lethal hits distinguish actual HP damage from excess Overkill.
- World-space guard rings and impact sparks in the cinematic encounter; removed duplicate screen slashes and additional Overkill screen shake there. Reduced-motion support remains.
- Preserved the three compact choices at the top, nine-hour clocks, twelve-relic starter deck and gradual enemy reveals. No save-format or balance changes from 0.14.1.

The material, lighting and weapon improvements apply to the rigged Sentinel encounter; other encounters retain their illustrated presentation. Labeled combat feedback applies throughout combat.

This is a visual development playtest, not completed AAA production. Bespoke enemy models, richer animation and broader environment work remain. Boss balance needs human testing. This machine did not achieve a consistent 60 fps in the cinematic scene. The installer is unsigned; its interactive wizard has not been tested. Existing nonfatal certificate-store and headless shutdown warnings remain.

Validation: exported starter mechanics, full clock-combat smoke, cinematic feedback and rendered presentation checks passed. Inspected exported 1080p imagery; checks cover 720p large text and ultrawide bounds. Portable ZIP entries match the tested exported payload.

Source tag: `v0.15.0-test`; feature branch: `feat/yonatan-cinematic-combat-finish`. Gameplay awaits review before merging to main.
