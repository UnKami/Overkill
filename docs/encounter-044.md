# Overkill 0.44.0 — Meshed Cogwork Ascent Playtest

The map now follows the concept art's seven-row diamond: sixteen wheels arranged
1 / 2 / 3 / 4 / 3 / 2 / 1, climbing from the bottom entrance to the top guardian.
Each route follows an actual tooth contact. Interior wheels offer two upward
choices; the outer wheels on the narrowing half offer one.

All gears turn as one mechanism, with neighboring rows counterrotating and
complementary tooth phases. Choosing a route keeps the mechanism synchronized.
The arrival pointer faces the current wheel's contact, and the Executioner moves
from its current seat into the timed destination seat along a smooth arc.

Overview shows the whole apparatus. Follow brings the current wheel and its next
choices closer. Click a reachable wheel or use Left/Right, then click Advance or
press Space to time the landing. Enter also advances when the map, a gear or the
advance control has focus. The three encounter outcomes remain visible below.

Small clearances between wheels in the same row let the diagonal tooth contacts
rotate without creating a jammed triangular gear loop. The established wheel
faceplate art is retained inside regular native tooth geometry.

Existing saves retain their current eight-stage encounters and seat IDs; the
following act uses the new layout. New runs use seven stages immediately. The
shorter layout changes encounter pacing and still needs human balance review.
Combat, relic effects and the 0.43 Blender character animation pipeline remain
unchanged. No player-facing autoplay is added.

The immutable `v0.44.0-test` tag identifies the exact tested download, assembled
on `feat/yonatan-044-meshed-cog-map`. [Layout and save details](cog-machine-layout.md)
explain the geometry. Previous releases remain available for rollback.

Eight packaged suites passed, including geometry, save recovery, all 29 relics
and live forecast comparisons. Four exported screen presets passed 288 captures
and 744 checks; all contact sheets were inspected. Installed payload hashes,
checkpoint recovery and uninstall passed. All three public downloads match
their local sizes and SHA-256 hashes. The release includes the detailed report.
This unsigned playtest does not claim final human visual approval or a full
human campaign; the shorter encounter pacing still needs human balance review.
