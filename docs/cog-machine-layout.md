# Cogwork ascent layout

The reference is `concept art/new nav system overkill.png`: a seven-row diamond,
read from the bottom upwards, with wheel counts **1 / 2 / 3 / 4 / 3 / 2 / 1**.
New runs use these sixteen wheels. Every wheel has three timed encounter seats.
Only a wheel touching the current wheel in the next row is a legal destination.
Interior wheels offer two upward routes; the outer wheels on the narrowing half
offer one. The final singleton is the act guardian.

The generator owns physical positions and derives connections from their pitch
distance. The view uses those same positions; it does not spread every row across
the screen or substitute route lines for tooth contacts. Overview fits the whole
apparatus on request; the initial view focuses the entrance wheel. Follow frames
the current wheel and its next choices and moves with each climb. Drag with the
left, middle or right mouse button to inspect future nodes; the wheel scrolls the
planning view vertically. Planning stays where released; Recenter returns to the
current decision. Direction selection eases the framing toward that branch.
Future wheels recede during decisions and become fully readable while planning.
The camera transforms a single world canvas; zoom never rebuilds the gears or
changes their mesh, phase or hit regions. The gold arrival
pointer faces the actual contact with the current wheel. Click a reachable wheel
or use Left/Right to choose; click Advance or press Space to catch its nearest
seat. Enter advances when the map or an advance/gear control has keyboard focus.
Pause and reference overlays retain their own controls.

## Tooth contact and drive

All wheels have 24 regular involute teeth, pitch radius 130, tip radius 141 and
root radius 117 in the unscaled canvas. Adjacent rows meet at a center distance
of 260. Contact axes are 52.5 degrees, matching the tooth spacing and allowing
one complementary phase across both branches. Horizontal pitch is about 316.6;
row pitch is about 206.3. Same-row tips have about 34.6 units of clearance.

This clearance is intentional: touching same-row wheels as well as both diagonal
neighbors would create triangular loops of external gears, which cannot all
rotate together. The apparatus connects through the upward/downward teeth.
Its topology still follows the reference's diamond and branch structure.

One shared drive angle rotates alternate rows in opposite directions, with a
7.5-degree complementary offset on odd rows. Selecting a destination never
accelerates or rotates that wheel independently. Catching a seat aligns the
entire mechanism together before the character transfers along a eased arc.
Timing, seat icons and the overhead character share the measured transparent
hole centers in the canonical faceplate. The player fits within the circular
socket, replaces its event icon and has a cyan socket outline. Even imperfect
timing selects the nearest hole and transfers exactly to that anchor. A short
landing pulse/hold makes the arrival readable before the encounter curtain.
Seat icons and the overhead character remain upright while following their
physical seat positions. Reduced motion applies camera framing directly and
shortens transfer/hold. The canonical wheel painting remains the faceplate;
native tooth geometry replaces its irregular illustrated rim.

## Encounters and existing saves

The shortened reference layout places normal/optional elite approaches in the
first four rows, battle/elite/treasure choices in row five, rest/shop/event in row
six, then the guardian in row seven. This changes new-run encounter pacing and
needs human balance review; combat values and encounter resolution are unchanged.

New saves record `map.cog_layout_version = 2` and `map.cog_machine_angle`.
Saves without a layout version retain their existing eight-stage, eighteen-wheel
encounters and seat IDs. The repeated two-wheel row is staggered so its contacts
mesh. Their next act adopts the new seven-row layout. Legacy non-cog route saves
still use the existing legacy map. Guardian checkpoint reconstruction respects
the saved layout version.

## Verification fixtures

- `cog_navigation_test.tscn`: topology, contact distance, complementary phases,
  48 actual tooth-polygon collision samples, round hit regions, overview and
  old/new save reconstruction across three acts and multiple seeds.
- `cog_machine_review.tscn`: production selection, alignment and character
  transfer across all seven stages, using an isolated developer profile. It
  marks fixture encounters cleared without fighting them; it is not a campaign
  playthrough or player-facing autoplay.
- `resume_checkpoint_test.tscn`: includes all three acts' old and new cog
  guardian checkpoints, in addition to legacy route recovery.
- `release_screen_audit.tscn`: packaged screen captures at 720p/1080p and normal/
  large text. Automated bounds checks accompany separate visual inspection.
