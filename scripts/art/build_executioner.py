"""Build a clean game rig from crownjoshua's CC0 knight, with authored combat clips.
Run with Blender --background --disable-autoexec .tools/knight-source.blend --python this_file.
Source: https://opengameart.org/content/knight-rigged-mid-poly
"""
import bpy, bmesh, math, json
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion

OUT = Path('assets/characters/rigged')
OUT.mkdir(parents=True, exist_ok=True)
source_rig = bpy.data.objects['rig']
source_rig.data.pose_position = 'REST'
source_rig.animation_data_clear()
for b in source_rig.pose.bones:
    for c in list(b.constraints): b.constraints.remove(c)
    b.matrix_basis.identity()
bpy.context.view_layer.update()

scale = 0.48
lift = 0.06
def coord(v):
    return Vector(v)*scale + Vector((0,0,lift))

spec = {
 'hips': ('DEF-spine','DEF-spine',None),
 'spine': ('DEF-spine.001','DEF-spine.002','hips'),
 'chest': ('DEF-spine.003','DEF-spine.003','spine'),
 'neck': ('DEF-spine.004','DEF-spine.005','chest'),
 'head': ('DEF-spine.006','DEF-spine.006','neck'),
}
for side in ['L','R']:
    spec['shoulder.'+side] = ('DEF-shoulder.'+side,'DEF-shoulder.'+side,'chest')
    spec['upper_arm.'+side] = ('DEF-upper_arm.'+side,'DEF-upper_arm.'+side+'.001','shoulder.'+side)
    spec['forearm.'+side] = ('DEF-forearm.'+side,'DEF-forearm.'+side+'.001','upper_arm.'+side)
    spec['hand.'+side] = ('DEF-hand.'+side,'DEF-hand.'+side,'forearm.'+side)
    spec['thigh.'+side] = ('DEF-thigh.'+side,'DEF-thigh.'+side+'.001','hips')
    spec['shin.'+side] = ('DEF-shin.'+side,'DEF-shin.'+side+'.001','thigh.'+side)
    spec['foot.'+side] = ('DEF-foot.'+side,'DEF-foot.'+side,'shin.'+side)
    for finger in ['f_index','f_middle','f_ring','f_pinky','thumb']:
        for segment in range(1,4):
            name=f'{finger}.{segment:02d}.{side}'
            parent='hand.'+side if segment==1 else f'{finger}.{segment-1:02d}.{side}'
            spec[name]=('DEF-'+name,'DEF-'+name,parent)

def mapping(name):
    n = name.removeprefix('DEF-')
    if n in spec: return n
    for side in ['L','R']:
        if '.'+side in n:
            for base in ['shoulder','upper_arm','forearm','hand','thigh','shin','foot']:
                if n.startswith(base): return base+'.'+side
            if n.startswith(('f_', 'thumb','palm')): return 'hand.'+side
            if n.startswith('toe'): return 'foot.'+side
    if n == 'spine': return 'hips'
    if n in ['spine.001','spine.002']: return 'spine'
    if n == 'spine.003': return 'chest'
    if n in ['spine.004','spine.005']: return 'neck'
    if n.startswith(('pelvis','breast')): return 'hips' if n.startswith('pelvis') else 'chest'
    return 'head'

keep = ['Man','Belt','BreastPlate','cuisse','Gauntlets','Helmet','Shoes','Shoulder-Plate']
meshes=[]
for name in keep:
    obj=bpy.data.objects[name]
    # Ignore legacy construction reveals and evaluate geometry in the rest pose.
    for m in list(obj.modifiers):
        if m.type in ['ARMATURE','BUILD']: obj.modifiers.remove(m)
        elif m.type == 'SUBSURF': m.levels=1; m.render_levels=1
    if obj.data.shape_keys:
        for key in obj.data.shape_keys.key_blocks: key.value=0
    dg=bpy.context.evaluated_depsgraph_get()
    evaluated=obj.evaluated_get(dg)
    data=bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=dg)
    clean=bpy.data.objects.new('Knight_'+name,data)
    bpy.context.collection.objects.link(clean)
    # Retain evaluated vertex groups, then consolidate twist/facial weights.
    old_groups={g.index:g.name for g in obj.vertex_groups}
    weights=[]
    for vertex in data.vertices:
        acc={}
        for g in vertex.groups:
            dst=mapping(old_groups.get(g.group,'DEF-spine.003'))
            acc[dst]=acc.get(dst,0)+g.weight
        weights.append(acc)
    # new_from_object carries deform indices but not the object's group names.
    # Clear those indices before installing the compact game skeleton weights.
    bm=bmesh.new()
    bm.from_mesh(data)
    deform=bm.verts.layers.deform.active
    if deform:
        for vertex in bm.verts: vertex[deform].clear()
    bm.to_mesh(data)
    bm.free()
    rest_transform=source_rig.matrix_world.inverted() @ obj.matrix_world
    for v in data.vertices: v.co=coord(rest_transform @ v.co)
    data.validate()
    for group_name in spec: clean.vertex_groups.new(name=group_name)
    for i,acc in enumerate(weights):
        if not acc: acc={'head' if name=='Helmet' else 'chest':1}
        total=sum(acc.values())
        for dst,weight in acc.items(): clean.vertex_groups[dst].add([i],weight/total,'REPLACE')
    for p in data.polygons: p.use_smooth=True
    meshes.append(clean)

arm_data=bpy.data.armatures.new('ExecutionerSkeleton')
rig=bpy.data.objects.new('ExecutionerRig',arm_data)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name,(start,end,parent) in spec.items():
    b=arm_data.edit_bones.new(name)
    b.head=coord(source_rig.data.bones[start].head_local)
    b.tail=coord(source_rig.data.bones[end].tail_local)
    b.roll=0
    if parent: b.parent=arm_data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
for mesh in meshes:
    mod=mesh.modifiers.new('Game skin','ARMATURE')
    mod.object=rig
    mesh.parent=rig

# Replace legacy Blender Internal materials with explicit PBR surfaces.
colors={'Gold':((0.32,0.21,0.085,1),0.82,0.34),'White':((0.17,0.21,0.24,1),0.88,0.32),'Black]':((0.022,0.032,0.044,1),0.25,0.72)}
for mesh in meshes:
    for index,old in enumerate(list(mesh.data.materials)):
        n=old.name if old else 'White'
        # Body under armor is a charcoal undersuit, including covered face.
        if mesh.name=='Knight_Man': n='Black]'
        key='PBR_'+n
        mat=bpy.data.materials.get(key) or bpy.data.materials.new(key)
        mat.use_nodes=True
        bsdf=mat.node_tree.nodes.get('Principled BSDF')
        color,metal,rough=colors.get(n,colors['Black]'])
        bsdf.inputs['Base Color'].default_value=color
        bsdf.inputs['Metallic'].default_value=metal
        bsdf.inputs['Roughness'].default_value=rough
        mesh.data.materials[index]=mat

# Directly aim a bone in armature space, preserving its twist reference.
def aim(name,direction):
    p=rig.pose.bones[name]
    rest=arm_data.bones[name]
    basis=rest.matrix_local.to_3x3()
    rest_y=basis.col[1].normalized()
    rotation=rest_y.rotation_difference(Vector(direction).normalized())
    desired=rotation.to_matrix() @ basis
    if p.parent:
        head=p.parent.matrix @ (p.parent.bone.matrix_local.inverted() @ rest.head_local)
    else: head=rest.head_local.copy()
    matrix=desired.to_4x4()
    matrix.translation=head
    p.matrix=matrix
    bpy.context.view_layer.update()

def pose(kind,amount=1.0,breath=0.0):
    for p in rig.pose.bones:
        p.rotation_mode='QUATERNION'
        p.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    # Armor-safe stance: modest knee flexion, asymmetric guard, relaxed shoulders.
    lean=0
    if kind=='windup': lean=-0.12*amount
    if kind=='strike': lean=0.18*amount
    if kind=='hit': lean=-0.22*amount
    if kind=='death': lean=0.65*amount
    hip_matrix=rig.pose.bones['hips'].bone.matrix_local.copy()
    hip_matrix.translation.z += -0.028 + breath*0.003 - (0.44*amount if kind=='death' else 0)
    hip_matrix.translation.y += 0.16 if kind=='strike' else (-0.04 if kind=='windup' else 0)
    rig.pose.bones['hips'].matrix=hip_matrix
    bpy.context.view_layer.update()
    aim('spine',(0,lean,1))
    # Shoulder counter-rotation gives the cut a torso-led arc while IK holds the feet.
    twist = -0.15 if kind=='windup' else (0.13 if kind=='strike' else 0.0)
    aim('chest',(twist,lean+breath*0.012,1))
    aim('neck',(0,0.04,1))
    aim('head',(0,0.1 if kind!='death' else 0.7,1))
    for side,sign in [('L',-1),('R',1)]:
        aim('shoulder.'+side,(sign,0,-0.06))
        # Analytic two-bone legs keep the feet planted as the pelvis transfers weight.
        thigh=rig.pose.bones['thigh.'+side]
        hip=thigh.head.copy()
        ankle=arm_data.bones['foot.'+side].head_local.copy()
        ankle.x += sign*0.025
        ankle.y += 0.07 if side=='L' else -0.07
        upper_len=arm_data.bones['thigh.'+side].length
        lower_len=arm_data.bones['shin.'+side].length
        direction=(ankle-hip).normalized()
        distance=min((ankle-hip).length,upper_len+lower_len-0.001)
        along=(upper_len**2-lower_len**2+distance**2)/(2*distance)
        height=math.sqrt(max(0,upper_len**2-along**2))
        pole=Vector((0,1,0)); pole=(pole-direction*pole.dot(direction)).normalized()
        knee=hip+direction*along+pole*height
        aim('thigh.'+side,knee-hip)
        aim('shin.'+side,ankle-knee)
        aim('foot.'+side,(0,1,-0.1))
    # Right-hand execution sword. Shoulder, elbow and wrist each follow the arc.
    upper=(0.2,0.14,-1); lower=(0.03,0.8,-0.3); hand=(0,0.85,-0.3)
    if kind=='windup': upper=(0.35,-0.55,0.6); lower=(0,0.18,1); hand=(0,0.3,1)
    if kind=='strike': upper=(0.12,0.9,-0.3); lower=(-0.16,1,-0.38); hand=(0,1,-0.3)
    if kind=='recovery': upper=(0.12,0.5,-0.8); lower=(-0.1,0.6,-0.7); hand=(0,0.7,-0.6)
    if kind=='hit': upper=(0.35,-0.1,-1); lower=(0.1,0.4,-0.8); hand=(0,0.6,-0.5)
    if kind=='guard': upper=(0.18,0.65,-0.5); lower=(-0.1,0.35,0.8); hand=(0,0.3,0.8)
    if kind=='death': upper=(0.35,0.45,-1); lower=(-0.1,0.45,-1); hand=(0,0.5,-1)
    aim('upper_arm.R',upper); aim('forearm.R',lower); aim('hand.R',hand)
    if kind in ['strike','recovery','death']:
        wrist=rig.pose.bones['hand.R']
        # Keep the wrist near the forearm's line of force. The previous 75-degree
        # strike bend folded the hand under the gauntlet at the impact frame.
        wrist_roll={'strike': -25, 'recovery': -20, 'death': -45}[kind]
        wrist.rotation_quaternion=wrist.rotation_quaternion @ Quaternion((1,0,0),math.radians(wrist_roll))
    # Off-hand protects the face on a block and counterbalances the sword arc.
    left_upper=(-0.25,0.25,-1); left_lower=(0.15,0.9,-0.2)
    if kind=='guard': left_upper=(-0.22,0.65,-0.25); left_lower=(0.30,0.22,0.95)
    elif kind=='windup': left_upper=(-0.30,0.45,-0.75); left_lower=(0.2,0.85,0.25)
    elif kind=='strike': left_upper=(-0.4,-0.15,-0.8); left_lower=(0.1,0.65,-0.4)
    elif kind=='hit': left_upper=(-0.4,-0.15,-0.8); left_lower=(0.1,0.35,-0.5)
    aim('upper_arm.L',left_upper)
    aim('forearm.L',left_lower)
    aim('hand.L',(0.05,1,0.1))
    for side in ['L','R']:
        for finger in ['f_index','f_middle','f_ring','f_pinky','thumb']:
            for segment in range(1,4):
                p=rig.pose.bones[f'{finger}.{segment:02d}.{side}']
                p.rotation_quaternion=Quaternion((1,0,0), math.radians(48 if finger=='thumb' else 68))

def clip(name,keys):
    action=bpy.data.actions.new(name)
    rig.animation_data_create()
    rig.animation_data.action=action
    for frame,kind,breath in keys:
        pose(kind,breath=breath)
        for p in rig.pose.bones:
            p.keyframe_insert('location',frame=frame)
            p.keyframe_insert('rotation_quaternion',frame=frame)
            p.keyframe_insert('scale',frame=frame)
    # Export NLA strips as independently named clips.
    track=rig.animation_data.nla_tracks.new()
    track.name=name
    track.strips.new(name,1,action)
    track.mute=True
    rig.animation_data.action=None

clip('combat_idle',[(1,'idle',0),(31,'idle',1),(61,'idle',0),(91,'idle',-1),(121,'idle',0)])
clip('execution_cut',[(1,'idle',0),(7,'windup',0),(15,'windup',0),(20,'strike',0),(24,'strike',0),(32,'recovery',0),(46,'idle',0)])
clip('guard',[(1,'idle',0),(5,'guard',0),(12,'guard',0),(23,'idle',0)])
clip('hit',[(1,'idle',0),(5,'hit',0),(10,'hit',0),(24,'idle',0)])
clip('death',[(1,'idle',0),(16,'hit',0),(44,'death',0),(65,'death',0)])
pose('idle')
bpy.context.scene.render.fps=60
bpy.context.scene.frame_start=1
bpy.context.scene.frame_end=121

# Remove all source controls, cameras, lights and unused body internals.
for obj in list(bpy.data.objects):
    if obj not in meshes and obj != rig: bpy.data.objects.remove(obj,do_unlink=True)
for source_text in list(bpy.data.texts): bpy.data.texts.remove(source_text)
for obj in bpy.context.scene.objects: obj.select_set(True)
bpy.context.view_layer.objects.active=rig
source_dir=Path('art_source/characters')
source_dir.mkdir(parents=True,exist_ok=True)
(source_dir/'.gdignore').touch()
bpy.ops.wm.save_as_mainfile(filepath=str((source_dir/'executioner-production.blend').resolve()))
bpy.ops.export_scene.gltf(filepath=str((OUT/'executioner.glb').resolve()), export_format='GLB', use_selection=True, export_animations=True, export_animation_mode='NLA_TRACKS', export_force_sampling=True, export_apply=False, export_yup=True)
print('EXECUTIONER_EXPORT_OK')
