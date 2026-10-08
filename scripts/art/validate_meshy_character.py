"""Blender-side source, material, deformation, and contact validation."""
import bpy, json, math, sys
import numpy as np
from pathlib import Path
from mathutils import Vector

source=Path(sys.argv[sys.argv.index('--')+1])
bpy.ops.wm.open_mainfile(filepath=str(source))
arm=bpy.data.objects['Meshy_Executioner_Rig']
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers))
scene=bpy.context.scene
report={'checks':{},'actions':{},'limits':['Sampled deformation bounds do not establish absence of all self-intersections or production animation quality.']}

def check(name,condition):
    report['checks'][name]=bool(condition)
    if not condition:print('FAILED',name)

def select(name):
    arm.animation_data.action=None
    for b in arm.pose.bones:
        b.location=(0,0,0);b.rotation_mode='QUATERNION';b.rotation_quaternion=(1,0,0,0);b.scale=(1,1,1)
    action=bpy.data.actions[name]
    arm.animation_data.action=action
    arm.animation_data.action_slot=action.slots[0]

def positions():
    obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    evaluated=obj.to_mesh()
    xyz=np.empty(len(evaluated.vertices)*3,dtype=np.float32)
    evaluated.vertices.foreach_get('co',xyz)
    xyz=xyz.reshape(-1,3)
    matrix=np.array(obj.matrix_world)
    world=xyz @ matrix[:3,:3].T+matrix[:3,3]
    obj.to_mesh_clear()
    return world

check('23_original_joints',len(arm.data.bones)==23)
check('six_editable_ik_drivers',len(arm.animation_data.drivers)==6)
check('editing_controls_default_off',arm['controls_enabled']==0)
check('five_motion_clips',set(a.name for a in bpy.data.actions)=={'Idle','Walking','Running','Jump_Down','Guard_Raise'})
check('all_images_packed',all(i.packed_file is not None for i in bpy.data.images if i.type=='IMAGE'))
check('two_4k_material_maps',sum(1 for i in bpy.data.images if tuple(i.size)==(4096,4096))==2)
mat=mesh.data.materials[0]
bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
check('metallic_texture_connected',bsdf.inputs['Metallic'].is_linked)
check('roughness_texture_connected',bsdf.inputs['Roughness'].is_linked)
check('whole_body_emission_removed',not bsdf.inputs['Emission Color'].is_linked)
for name in ['Idle','Walking','Running','Jump_Down','Guard_Raise']:
    select(name);action=bpy.data.actions[name];start,end=action.frame_range
    bounds=[];foot_samples=[];hand_samples=[]
    for t in np.linspace(start,end,25):
        scene.frame_set(int(t),subframe=float(t-int(t)));bpy.context.view_layer.update()
        xyz=positions()
        check(name+'_finite_'+str(t),np.isfinite(xyz).all())
        bounds.append([xyz.min(axis=0).tolist(),xyz.max(axis=0).tolist()])
        foot_samples.append([list(arm.matrix_world@arm.pose.bones['mixamorig:'+side+'Foot'].head) for side in ['Left','Right']])
        hand_samples.append([list(arm.matrix_world@arm.pose.bones['mixamorig:'+side+'Hand'].head) for side in ['Left','Right']])
    values=np.array(bounds)
    check(name+'_bounded_width',float(np.max(values[:,1,0]-values[:,0,0]))<1.8)
    check(name+'_bounded_height',float(np.max(values[:,1,2]-values[:,0,2]))<2.5)
    report['actions'][name]={'duration_seconds':float((end-start)/scene.render.fps),
        'min_z':float(values[:,:,2].min()),'max_z':float(values[:,:,2].max())}
    if name=='Guard_Raise':
        foot=np.array(foot_samples);hand=np.array(hand_samples)
        report['actions'][name]['max_foot_drift_m']=float(np.max(np.linalg.norm(foot-foot[0],axis=2)))
        report['actions'][name]['max_hand_travel_m']=float(np.max(np.linalg.norm(hand-hand[0],axis=2)))
        check('guard_feet_planted',report['actions'][name]['max_foot_drift_m']<.015)
        check('guard_hands_actually_raise',report['actions'][name]['max_hand_travel_m']>.20)
    if name=='Jump_Down':
        select(name);scene.frame_set(35);bpy.context.view_layer.update()
        check('landing_above_floor',positions()[:,2].min()>-.045)
        scene.frame_set(0);bpy.context.view_layer.update();start_xyz=positions()
        check('jump_starts_on_platform',start_xyz[:,2].min()>1.15)
    if name=='Idle':
        scene.frame_set(0);bpy.context.view_layer.update();a=positions()
        scene.frame_set(90);bpy.context.view_layer.update();b=positions()
        report['actions'][name]['loop_vertex_error_m']=float(np.max(np.linalg.norm(a-b,axis=1)))
        check('idle_loop_closes',report['actions'][name]['loop_vertex_error_m']<1e-5)
report['passed']=all(report['checks'].values())
(source.parent/'validation.json').write_text(json.dumps(report,indent=2))
print('MESHY_SOURCE_VALIDATION',json.dumps({'passed':report['passed'],'checks':len(report['checks']),'actions':report['actions']}))
if not report['passed']:raise RuntimeError('Meshy source validation failed')
