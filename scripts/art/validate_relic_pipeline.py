"""Run with Blender --background --python scripts/art/validate_relic_pipeline.py.
Checks the saved source armature and actual evaluated skin against Godot data.
"""
import bpy,json,math
from pathlib import Path
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[2]
RIG=ROOT/'assets/characters/executioner/rigged'
data=json.loads((RIG/'rig_data.gd').read_text(encoding='utf-8').split('const DATA: Dictionary = ',1)[1])
bpy.ops.wm.open_mainfile(filepath=str(RIG/'source/executioner_relic_rig.blend'))
rig=bpy.data.objects['Executioner_Articulated_Rig']
assert len(rig.data.bones)==20
for side in ('near','far'):
    assert rig.data.bones['arm_'+side].parent.name=='clavicle_'+side
    assert rig.data.bones['forearm_'+side].use_connect
    assert rig.data.bones['hand_'+side].use_connect
    assert rig.data.bones['shin_'+side].use_connect
    cap=bpy.data.objects['pauldron_'+side]
    assert [g.name for g in cap.vertex_groups]==['clavicle_'+side]
rest={}
for bone in data['bones']:
    position=Vector((bone['rest'][0],-bone['rest'][1],0))
    local=Matrix.Translation(position)
    rest[bone['name']]=rest[bone['parent']]@local if bone['parent'] else local
max_error=0
checks=0
for name,action in data['actions'].items():
    bpy.context.scene.frame_set(1)
    rig.animation_data.action=bpy.data.actions[name]
    frames=action['frames']
    for index in sorted({0,round(len(frames)*.35),round(len(frames)*.65),len(frames)-1}):
        bpy.context.scene.frame_set(index+1)
        bpy.context.view_layer.update()
        world={}
        for bone,value in zip(data['bones'],frames[index]):
            local=Matrix.Translation(Vector((value[0],-value[1],0)))@Matrix.Rotation(-value[2],4,'Z')
            world[bone['name']]=world[bone['parent']]@local if bone['parent'] else local
        deps=bpy.context.evaluated_depsgraph_get()
        for mesh in data['meshes']:
            obj=bpy.data.objects[mesh['name']]
            evaluated=obj.evaluated_get(deps)
            evaluated_mesh=evaluated.to_mesh()
            for vertex in obj.data.vertices:
                predicted=Vector((0,0,0))
                total=0
                for group in vertex.groups:
                    bone_name=obj.vertex_groups[group.group].name
                    predicted+=group.weight*(world[bone_name]@rest[bone_name].inverted()@vertex.co)
                    total+=group.weight
                assert abs(total-1)<.00001,(mesh['name'],vertex.index,total)
                actual=evaluated_mesh.vertices[vertex.index].co
                error=Vector((predicted.x-actual.x,predicted.y-actual.y)).length
                max_error=max(max_error,error)
                checks+=1
            evaluated.to_mesh_clear()
assert max_error<.01,max_error
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/animations/relics/source/relic_choreography.blend'))
arm=bpy.data.objects['RelicArticulation']
assert len(arm.data.bones)==6
for number in range(1,30):
    prefix=f'REL-{number:02d}.'
    collection=next(c for c in bpy.data.collections if c.name.startswith(prefix))
    assert len(collection.objects)==(2 if number==2 else 1)
    for obj in collection.objects:
        assert obj.modifiers[0].object==arm
        assert obj.vertex_groups[0].name in ('prop','secondary')
        assert 'grip_uv' in obj
assert bpy.context.scene.timeline_markers['Iron strike contact 2.2s'].frame==133
result=dict(skin_vertex_checks=checks,max_blender_godot_skin_error_pixels=max_error,character_bones=20,relic_bones=6,relic_models=29)
out=ROOT/'.test-artifacts/046/skin-pipeline-parity.json'
out.write_text(json.dumps(result,indent=2))
print('SAVED_BLENDER_PIPELINE_OK',json.dumps(result))
