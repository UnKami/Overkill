# Overkill 0.45.0 — Focused Ascent Playtest

The map opens close to the entrance wheel and its three timed seats. After each
encounter, the camera frames the current wheel and its available upward choices.
Choosing a direction eases the framing toward that branch. During travel the
camera follows the destination and allows a short, visible landing beat before
the encounter transition.

Drag the map with the left, middle or right mouse button to inspect upcoming
wheels and plan a route. The mouse wheel pans vertically. The planning view
stays where released; Recenter returns to the immediate decision. Overview
remains available on request. Click a reachable wheel or use Left/Right, then
click Advance or press Space to time the next seat.

The player and encounter symbols now use the measured centers of the painted
circular holes. Even imperfect timing catches the nearest hole, places the
player precisely inside it and hides the symbol beneath the player. A cyan
socket outline keeps the current position readable. Future wheels recede during
choices and become fully visible while planning. Camera motion never rebuilds
the apparatus or alters its meshed counterrotation. Reduced motion applies
framing directly and shortens travel and landing.

Existing saves retain their encounters, seat IDs and shared drive phase. Combat,
relic effects and the Blender motion pipeline are unchanged. The seven-stage
layout from 0.44 remains; its shorter encounter pacing still needs human balance
review. No player-facing autoplay is added.

The immutable `v0.45.0-test` tag identifies the exact tested download from
`feat/yonatan-045-follow-map-camera`. The release verification report records
source/export tests, visual/input checks, installation and public download hashes.
Previous releases remain available. This unsigned playtest does not claim final
human visual approval, a full human campaign or a realtime FPS target.
