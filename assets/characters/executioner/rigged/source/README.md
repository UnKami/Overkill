# Executioner skeletal animation source

`executioner_relic_rig.blend` contains an editable Blender 5.2 armature with **18 bones**, **16 painted cutout meshes**, normalized vertex groups, armature modifiers, and **11 actions**. The cloak and torso have blended weights; the armored limbs use separate upper-arm, forearm, hand, thigh, shin, and foot bones. Anticipation bends both knees with planted ankles.

The runtime `RelicRigActor` reconstructs the same hierarchy with Godot `Skeleton2D`/`Bone2D` and binds the textured `Polygon2D` meshes using those vertex weights. It samples Blender-exported transforms at 30 Hz and interpolates between frames at the rendering frame rate. It does not render or warp the former full-character sprite.

Rebuild from the repository root:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python scripts/art/build_relic_rig.py
```

The build writes the native `.blend`, packed art, a readable manifest, six transparent pose-review renders, and `../rig_data.gd`. The generated GDScript resource includes the runtime mesh, UV, weights, bone hierarchy, and action data automatically in exported PCK files. This source directory has `.gdignore` so Godot does not attempt automatic Blender import or ship authoring previews.

| Action | Contact time | Duration |
| --- | ---: | ---: |
| iron_strike | 2.20 s, following 1.50 s hand summon | 3.10 s |
| throw | 0.95 s | 1.70 s |
| heavy | 2.20 s | 3.30 s |
| channel | 2.40 s | 2.70 s |
| crown | 1.70 s | 2.10 s |
| bell | 2.50 s | 3.00 s |
| block | 1.10 s | 1.80 s |
| hit | — | 0.55 s |
| guard_hit | — | 0.50 s |
| fall | — | 1.10 s |
| idle | looping | 3.20 s |

Times above are real seconds at normal playback. The existing Fast animation setting doubles playback speed. Reduced motion retains the same event timing with smaller bone movement.

Public anchor methods expose animated hand, hood-top, chest, and feet positions in global coordinates. Relic choreography attaches props to these anchors. `sample_action_for_review()` freezes a sampled authored pose for screenshots; it never advances battle rules.

The transparent `../parts_atlas.png` was generated with the built-in ImageGen tool from the existing Executioner reference. Art direction: preserve the faceless hood, black leather and antique bronze armor, cyan crystals on the far side and ember-orange details on the near side; provide 16 isolated, transparent, rounded-joint cutouts in a 4×4 atlas (head, torso, pelvis, cloak, paired upper arms, forearms, hands, thighs, shins, boots). `build_relic_rig.py` maps each part's alpha bounds to authored mesh surfaces. The established original sprite remains untouched.

Verification: Blender successfully saved the authoring source and rendered idle, bent-knee anticipation, strike contact, throw anticipation/contact, and guard poses. Runtime skin construction was observed with 18 bones and 16 meshes. An initial Godot preview exposed a rear-layer sort defect; the runtime z ordering was corrected. Final integrated runtime verification belongs to the release fixture and its recorded screenshots.
