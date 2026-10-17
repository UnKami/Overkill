# Overkill 0.47.0 — local 3D character and relic review

Publication is held at the user's request. This candidate is on
`feat/yonatan-046-relic-feedback`; the published 0.45.0 download is unchanged.

The Executioner is now a volumetric human mesh with a native 63-joint skin,
articulated fingers, shoulder and forearm twist joints, fitted armor and a
weighted cloak. Strike and throw gestures use recorded human motion fitted to
the character's anatomy. Foot IK, restrained joint flexion, independent torso
rotation, crouched launch/landing and blended recovery replace the 2D cutout.

The hood, coat and asymmetric armor retain the original artwork on curved closed skin geometry. All 29 battle relics preserve their canonical silhouettes and colors on 3D meshes and an imported six-joint prop skeleton.
Melee hilts attach to the actual palms. Bell shell and clapper move independently;
Chalice, Crown and Block retain their readable purple/blue activation beats.
Siphon extends a 3D purple tube with a traveling green life mass and a moving
bulge. Healing presentation still waits for energy arrival. Piston retains its
next-attack multiplier transfer to the buff strip.

The arena backdrop, enemies and interface remain illustrated. This rebuild
changes the main character and relic presentation. Damage, turn order, clock
rules, upgrades, save schemas and lifesteal caps remain unchanged. An earlier QA fixture overwrote the automatically saved run slot; no exact pre-test copy was found. Tests now require isolated profiles.

Editable Blender sources include the body skin, 16 baked actions, hand/foot IK
controls and all relic models. See [pipeline and testing](executioner-3d.md).

This is a review candidate, not a claim of perfect or finished cinematic quality.
Visual acceptance remains open. No release, deployment, push or merge is made.


Crystalline cyan and amber particles accompany relic actions and fade quickly. Reduced motion disables the particles. Transparent character rendering clears every frame; the hero's ground shadow is softened.

2026-10-07 local polish: melee arms and torso recover during the return flight,
forearm pronation is bounded, and the knees return to the same planted stance.
Fingers relax before the idle transition. The cloak and coat now trail body
acceleration with damped settling. A slight breathing motion keeps the sword
summon hold alive. The hood has a bowed, closed cloth return behind its original
pointed front silhouette; the cuirass distributes movement across two spine
joints. Relic contact times, damage and save formats are preserved.

