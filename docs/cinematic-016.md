# Overkill 0.16.0 — Armor and Strike Timing Playtest

On GitHub: **UnKami/Overkill → Releases → 0.16.0 → Assets → OverkillSetup-0.16.0.exe**. The portable ZIP is beside it. Use **Play Sentinel** after installation or from the extracted portable folder to test the cinematic encounter directly in a separate profile.

- The Sentinel now has distinct layered shoulder armor, a dark breastplate, clockwork chest seal and greaves. Equipment follows the skeleton through attacks and reactions.
- The Executioner carries a broad, beveled execution blade. Refined stance spacing and a small weight shift make melee contact clearer.
- Fixed a real timing problem: the cinematic fight now waits for the attacking animation's contact pose before applying damage and playing impact effects. A brief contact hold makes the strike readable at lower frame rates. Combat rules and damage values are unchanged.
- Added a stepped rear dais and restrained braziers to give the arena more depth.
- Batched repeated architecture, simplified the metal shader, reused materials and reduced shadow passes for the fixed camera. Static clock engravings are cached; reduced-motion mode stops their continuous redraw.
- Retained the compact top choices, nine-hour clock, twelve-relic starter deck and gradual enemy reveals. Existing 0.14/0.15 saves remain compatible.

The character and environment changes target the rigged Sentinel encounter. Other encounters retain their illustrated presentation. Draw submissions in the measured scene fell from roughly 680 in 0.15 to 455; frame times remain variable, so this is not a 60 fps claim.

Validation: source and exported motion/attachment, cinematic combat, starter and clock-combat checks passed, plus rendered layout checks at 1080p, 720p large text and ultrawide. Contact checks cover normal/fast speed and reduced-motion combinations. Visual review covered idle, windup, contact and compact layouts.

Known limits: this remains a development playtest. Broader bespoke character/environment production, animation variety, frame-time consistency and human boss-balance testing remain. The unsigned installer compiles, but its interactive wizard has not been tested. Existing nonfatal Windows certificate-store and headless shutdown warnings remain.

Source: `v0.16.0-test`, branch `feat/yonatan-sentinel-silhouette`; gameplay awaits review before merging to main.
