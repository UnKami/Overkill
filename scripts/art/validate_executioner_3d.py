"""Saved .blend to exported local-pose parity and actual skin-weight audit."""
from pathlib import Path
import bpy,json,math
from mathutils import Matrix,Vector,Quaternion
root=Path(__file__).resolve().parents[2]
base=root/'assets/characters/executioner/three_d'
bpy.ops.wm.open_mainfile(filepath=str(base/'source/executioner_human_3d.blend'))
rig=bpy.data.objects['ExecutionerRig'];rig['controls_enabled']=0.0
record=json.loads((base/'motion_data.gd').read_text().split('const DATA: Dictionary = ',1)[1])
checks=0
def check(ok,message):
    global checks
    checks+=1
    assert ok,message
check(len(rig.data.bones)==63,'63 deform bones')
idle=record['actions']['idle']
check(idle['frames'][0]==idle['frames'][-1],'Idle must loop without a pose discontinuity')
check(idle['anchors'][0]==idle['anchors'][-1],'Idle world anchors must close with the skin')
meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==rig]
manifest=json.loads((base/'source/motion_manifest.json').read_text())
check(len(meshes)==manifest['meshes'],'All source volume meshes retain their skins')
for obj in meshes:
    check(sum(m.type=='ARMATURE' and m.object==rig for m in obj.modifiers)==1,'Skin binding '+obj.name)
    for vertex in obj.data.vertices:
        check(0<len(vertex.groups)<=4,'1-4 weights '+obj.name)
        check(abs(sum(g.weight for g in vertex.groups)-1)<1e-5,'Normalized weights '+obj.name)
conversion=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))
for name,clip in record['actions'].items():
    rig.animation_data.action=bpy.data.actions[name]
    for index in range(0,len(clip['frames']),max(1,len(clip['frames'])//20)):
        bpy.context.scene.frame_set(index+1);bpy.context.view_layer.update()
        for bone,row in zip(record['bones'],clip['frames'][index]):
            pose=rig.pose.bones[bone['name']]
            expected=Quaternion((row[6],row[3],row[4],row[5])).to_matrix().to_4x4()
            expected.translation=Vector(row[:3])
            actual=pose.parent.matrix.inverted()@pose.matrix if pose.parent else conversion@pose.matrix
            check((actual.translation-expected.translation).length<.00002,'Saved translation '+name+' '+bone['name'])
            check(abs(actual.to_quaternion().dot(expected.to_quaternion()))>.99999,'Saved rotation '+name+' '+bone['name'])
controls=bpy.data.objects.get('Executioner_Animator_Controls')
check(controls is not None,'Editable control rig exists')
check(all('CTRL_'+b.name in controls.pose.bones for b in rig.data.bones),'All joints have controls')
for side in ('L','R'):
    for name in ('forearm.','shin.'):
        constraint=next(c for c in rig.pose.bones[name+side].constraints if c.type=='IK')
        check(constraint.chain_count==2 and not constraint.use_stretch,'Two joint IK cannot stretch')
print('EXECUTIONER_SAVED_SOURCE_OK checks=%d meshes=%d bones=63 actions=16 normalized skin, baked pose parity and editable IK controls'%(checks,len(meshes)))
