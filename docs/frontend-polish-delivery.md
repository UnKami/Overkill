# Screen presentation pass — 0.12.0

17 September 2026. This is an intermediate playable build toward the user's whole-game quality target, not a claim of AAA readiness.

## Changes

- Main menu, character selection and victory/defeat screens share the real-time chronoforge chamber, lit character model and continuous idle animation used by the Sentinel presentation. Titles use a restrained serif face, supported by cyan labels, brass rules and dark readable controls.
- Character selection explains the actual 75 HP, 12 sockets and six reserves. New runs retain their existing starting inventory and gameplay. Repeated start input is guarded. Back navigation and focus are provided.
- Continue is present only with a saved journey. Starting over asks before advancing to character selection; the save is actually replaced when the new run begins.
- A shared theme covers navigation, dialogs, settings, pause, map, sanctuary, merchant, inventory, event choices, rewards and combat reached through GameFlow. The map has chapter framing and more visible route markers. Sanctuary choices have a dedicated reading area.
- Fixed settings, pause, event and outcome panels so their backgrounds size to their contents. Added coherent checkbox and slider graphics. Large text now updates shared control text and explicit small labels instead of merely saving an unused option. Existing rich-text content and arbitrary runtime-generated controls still need a complete accessibility audit.
- Hid stale card-energy text outside combat. Screen fades briefly absorb pointer input. Escape returns from character selection and does not open a combat pause menu over the title. Reduced motion suppresses background zoom and entrance scale punches.

## Verification

Rendered title, character selection, 720p character selection, map, settings, large-text settings, sanctuary, merchant, event, rewards, victory and defeat on the development machine. Automated navigation exercised a new journey, 18-relic inventory, 75 starting HP, save continuation, replacement confirmation, settings text changes, map-to-combat navigation and the first resolved combat hour.

Inventory/economy integration passed. Scripted first-act and boss encounter fixtures passed; later bosses still use explicitly upgraded inventories, so these checks do not certify full-campaign balance. Rig motion checks remain separate from manual animation-quality assessment.

## Remaining production work

The new screens reuse the existing knight model, whose anatomy, equipment, facial silhouette, materials and motion still need bespoke refinement. Most combat enemies retain the illustrated stage. Some older narrative backgrounds show the earlier hooded character. The presentation is more coherent, but the entire game is not yet visually uniform or AAA quality. Broader hardware testing, longer campaign playtesting, additional event content, controller coverage and a full accessibility review remain outstanding.

The system Georgia/Times font is requested at runtime; no proprietary font file is redistributed. No new raster images were generated in this pass. Prior asset credits are in the directed encounter delivery notes.

The engine's local root-certificate warning remains. Some headless checks report ObjectDB cleanup leaks; these are recorded limitations rather than silently treated as clean shutdowns.
