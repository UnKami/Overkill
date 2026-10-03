# Enemy surface animation source

`enemy_surface_motion.blend` contains five connected support/body/head/appendage
bones, a weighted review surface and seven editable actions. Rebuild with:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python scripts/art/build_enemy_motion.py
```

The generator exports 60 Hz normalized motion to `../enemy_tracks.gd`.
`EnemyRigActor` binds a subdivided surface over each canonical enemy texture and
scales the authored motion to its silhouette. Grounded lower support stays
fixed; floating enemies use gentle hover. This preserves the art while adding
connected deformation, rather than independent painted limb geometry. Runtime
contact is retimed to the existing attack profile, keeping combat outcomes and
speed settings intact. Authoring sources are excluded from Godot import by
`.gdignore`.
