# Overkill 0.43.0 — Natural Motion Playtest

The Executioner's movement now starts with grounded weight transfer rather than
independent limb rotations. Blender-authored hand and ankle targets drive a
connected two-bone solve with bounded elbows, consistent bend direction and
planted support during anticipation. Softer joint weights reduce visible cutout
seams. Motion is baked at 60 Hz, with continuous target interpolation and gradual
transitions into the current breathing pose.

Iron Strike and Heavy Hammer use a smaller crouch, a clearer forward push,
contact and a settling return. Throws wind up along a continuous shoulder arc;
the relic follows the wrist until release, then follows its flight path. Held
weapons follow wrist orientation. Incoming recoil can overlay an outgoing action
without cancelling its contact or snapping the character back to idle.

All ten illustrated enemies now use a connected weighted surface skeleton with
Blender-authored body, head, appendage and support motion. Grounded creatures
retain their lower support; floating creatures hover gently. Heavy creatures use
smaller motion, with head counter-motion and delayed appendage movement. This is
a surface deformation rig over the established enemy art; separate painted
enemy limbs remain a future art improvement.

The seven signature relic effects and the rest of the 29-relic catalog retain
their recognizable timings, status feedback and Fast/reduced-motion settings.
Damage, healing, Block, enemy rules, turn order, progression and save data are
unchanged. Existing 0.42 saves remain compatible. No player-facing autoplay is
added.

Editable Blender sources, generation scripts, native pose captures and runtime
checks accompany this playtest. Its immutable source tag is `v0.43.0-test`,
assembled on `feat/yonatan-043-fluid-motion`. Previous downloads remain available.
The release verification report records the actual source, exported payload,
rendered screen, installer and public-download checks.

This unsigned playtest improves motion, but does not claim final human visual
approval, a full human campaign, locked 60 FPS on every computer, or completed
separate-limb art for every enemy.
