from pathlib import Path
import bpy,sys
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from executioner_controls import ALIGN_TEXT
path=root/'assets/characters/executioner/three_d/source/executioner_human_3d.blend'
bpy.ops.wm.open_mainfile(filepath=str(path))
text=bpy.data.texts['ALIGN_CONTROLS.py'];text.clear();text.write(ALIGN_TEXT)
bpy.ops.wm.save_as_mainfile(filepath=str(path))
print('SAVED_CONTROL_TEXT_UPDATED: baked source poses and meshes unchanged')
