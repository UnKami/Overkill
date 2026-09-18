# Overkill 0.14.0 — Nine-Hour Clock Playtest

## Playing this update
On GitHub, open **UnKami/Overkill → Releases → 0.14.0 → Assets**. Run `OverkillSetup-0.14.0.exe`, or extract the portable ZIP and run `Overkill.exe`. The repository homepage and installer/README also point to this release. No Godot installation is needed.

Start a **new run** for the revised starter deck. Existing saved inventories are preserved; encounters now use nine sockets.

## Combat changes
- Nine hours, followed by three repeating three-hour sectors: 1–3, 4–6, 7–9.
- Twelve starter relics: five Iron Strikes (6 damage), five Guard Plates (5 Block), one Blood Siphon (3 damage; heals actual HP damage dealt), one Overdrive Piston (4 damage; doubles the next attacking relic).
- Three reserve relics remain after assembly. Removal keeps at least ten relics, preserving one reserve.
- Block lasts until absorbed or battle ends. Lifesteal excludes Block absorption and overkill, and cannot exceed maximum HP.
- The ×2 charge survives non-attacking hours, applies to every hit of the next attacking relic, then expires. A new Overdrive can consume a charge and arm the following attack; charges never stack to ×4.
- Enemy actions reveal before their corresponding placement and remain visible. Replacement decisions reveal the upcoming sector. New opponents start concealed. Reverse clocks use the matching reversed hour; twin enemies reveal their extra action before the relevant decision. With nine slots, their second hand is four slots ahead.

## Presentation and interaction
- Horizontal, floating relic choices and replacement targets; the arena keeps its full height.
- Larger effect text, consistent card styling, explicit Bind/Replace actions and stable preview positions.
- Numbered, pulsing destinations and animated relic placement; hidden enemy slots show question marks without leaking their effects through tooltips.
- Inspect Battlefield (I) temporarily hides choices without advancing combat.
- Health and Block remain outside the choice overlay. Reward cards, shop spacing, affordability messages, map connectors and footer placement are improved.
- Large-text and reduced-motion settings are respected by the revised controls.

## Validation and remaining work
Godot 4.5.1 integration checks cover deck composition, isolated copies, persistent Block, nine-hour assembly, reserve replacement, three-sector wrap, reveal progression, lifesteal caps, next-attack consumption, reverse clocks, reinforcement, inventory persistence and shop transactions. Rendered layout checks cover 1080p, 720p with large text, and ultrawide; frontend navigation and reward/shop screens were inspected.

This is a **playtest**, not a claim of finished AAA production. A deterministic basic policy wins the normal and elite Act I fixtures but loses boss fixtures; broader balance and human playtesting remain. The Windows installer is unsigned. The build is compiled and its exported game payload is tested; the interactive installer wizard has not been tested. Nonfatal Windows certificate-store and some headless shutdown warnings remain.

Source: tag `v0.14.0-test`, branch `feat/yonatan-014-presentation-polish`. Gameplay remains on the feature branch pending review; the release tag identifies its exact source commit.
