# Overkill 0.46.2 — character/relic rig review candidate

This candidate is local and is not yet published to GitHub. It is on
`feat/yonatan-046-relic-feedback`. The published 0.45 playtest remains available.

- Twin Blades equips the Iron Strike sword in each hand. Blender-baked,
  connected arm and leg actions perform the right and left melee hits separately;
  each hit still deals its existing damage at its own contact marker. Both weapons
  remain equipped between strikes. Their painted blade axes are calibrated to the wrists.
- Vital Siphon throws and embeds its enemy end, extends the purple conduit,
  and transfers one green life mass back to the hero. The hose bulges around
  the mass. Healing number, sound, HP display and healing glow wait for arrival.
- Actual lifesteal retains the existing post-Block, remaining-enemy-HP and
  missing-player-HP caps. Authoritative healing still precedes thorns; this
  preserves lethal interactions while synchronizing the presentation.
- Forge completion returns to the inventory at the same scroll position and
  refreshes the upgraded copy. Other copies remain inspectable. One free upgrade
  per visit remains enforced; Enter Battle / Return to Map is a separate action.
- Status symbols are larger. Strength retains its arm symbol, rendered purple.
  Strength, Block, Overdrive and other gains pulse without recreating their chips
  during stat redraws. Reduced Motion uses a color flash without enlargement.
- Iron Strike's existing 1.5-second summon and articulated swing are retained,
  with the sword orientation calibrated to contact. Existing Chalice, Crown,
  basic Block, Piston and two-second Bell choreography is preserved.

No relic stats, combat order, enemy rules, clock rules, currency, save schema,
run progression or player-facing autoplay are changed.

Verification and limitations are recorded in [verification-046.md](verification-046.md).
The installer is unsigned. Full human campaign playtesting and final animation
acceptance remain open. Source and generated Blender assets are included.


## 2026-10-06 rig revision

The 0.46.0 local installer predates this revision. Review 0.46.2 instead.
The active arm's elbow branch and resting joint were corrected; two collarbones
and separate rigid shoulder caps now keep armor from rolling with the arm.
The Blender source bones point along the actual limb joints with connected
elbow/knee chains. Its neutral-axis Godot retargeting was checked across all
50,720 bone samples. Casting anticipation is lower and smoother, and Siphon,
Chalice, Crown, Block and Bell hold their poses through activation and recover.

All 29 relics have individual textured/weighted Blender source meshes with
explicit grip metadata, and runtime relics now use a six-bone Skeleton2D.
Projectile release samples the exact authored hand transform. Blender timeline
markers now use the same 60 FPS basis as exported actions.

Publication remains on hold at the user's request for visual review.
See [rig review evidence and limits](rig-review-046.md).

## Casting performance revision, 0.46.2

The 0.46.1 rig was technically consistent but the user rejected its motion quality.
Casting was reauthored with a lower curved wind-up, planted lateral weight shift,
release aligned to 0.76 seconds, trailing head/cloth, and a slower settle. Ritual
casts use quieter asymmetric poses and restrained breathing during effect holds.
The elbow stays short of its near-straight singularity. All original contacts,
relic durations, outcome rules and saves remain unchanged.

This is a local motion study, not an accepted cinematic-quality release. The
flat painted torso and fixed hand silhouette remain art limitations. Source
review captures are fixed 60-FPS movies, not real-time performance measurements.
Publication is held. See docs/motion-polish-0462.md for this revision's evidence.
