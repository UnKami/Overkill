"""Original hooded Boneghoul, built on the shared CC0-derived combat skeleton.
Blender --background --disable-autoexec art_source/characters/executioner-production.blend --python scripts/art/build_boneghoul.py
No source knight mesh is retained. Combat integration awaits authored claw motion.
"""
import bpy, bmesh, math
from pathlib import Path
from mathutils import Vector, Quaternion

rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
rig.data.pose_position='REST'
for o in list(bpy.data.objects):
    if o!=rig:bpy.data.objects.remove(o,do_unlink=True)
parts=[];mats={}
for name,color,metal,rough in [
    ('Bone',(.17,.145,.105,1),.05,.9),('Iron',(.065,.075,.077,1),.75,.65),
    ('Cloth',(.022,.026,.032,1),0,.96),('Core',(.012,.18,.23,1),.25,.48)]:
    mat=bpy.data.materials.new('Boneghoul_'+name);mat.use_nodes=True
    bs=mat.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=color;bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
    if name=='Core':bs.inputs['Emission Color'].default_value=color;bs.inputs['Emission Strength'].default_value=.9
    mats[name]=mat

def bind(o,bone,material):
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
    o.data.materials.clear();o.data.materials.append(mats[material])
    for p in o.data.polygons:p.use_smooth=True
    o.vertex_groups.new(name=bone).add(list(range(len(o.data.vertices))),1,'REPLACE')
    parts.append(o);o.select_set(False)
    return o

def sphere(name,at,scale,bone,material='Bone',segments=20):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=12,location=at)
    o=bpy.context.object;o.name=name;o.scale=scale
    return bind(o,bone,material)

def tube(name,points,radii,bone,material='Bone',sides=10):
    points=[Vector(p) for p in points];verts=[]
    for index,point in enumerate(points):
        tangent=(points[min(index+1,len(points)-1)]-points[max(0,index-1)]).normalized()
        cross=Vector((0,0,1)) if abs(tangent.z)<.9 else Vector((1,0,0))
        a=tangent.cross(cross).normalized();b=tangent.cross(a).normalized()
        for edge in range(sides):
            angle=math.tau*edge/sides
            verts.append(point+(a*math.cos(angle)+b*math.sin(angle))*radii[index])
    faces=[]
    for row in range(len(points)-1):
        for edge in range(sides):
            a=row*sides+edge;b=row*sides+(edge+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.extend([tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))])
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
    return bind(o,bone,material)

def sheet(name,verts,faces,bone,material='Cloth',thickness=.004):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    if name=='Tattered hood':
        smooth=o.modifiers.new('Soft hood folds','SUBSURF');smooth.levels=2
        bpy.ops.object.modifier_apply(modifier=smooth.name)
    solid=o.modifiers.new('Material thickness','SOLIDIFY');solid.thickness=thickness
    bpy.ops.object.modifier_apply(modifier=solid.name)
    return bind(o,bone,material)

# An exposed spine and curved ribs give the body real negative space.
for index in range(10):
    h=1.06+index*.062
    sphere('Vertebra',(0,-.035,h),(.052,.06,.025),'spine' if h<1.33 else 'chest')
for side in [-1,1]:
    for index in range(6):
        h=1.31+index*.061;width=.16+.05*math.sin(index*math.pi/6)
        points=[]
        for step in range(17):
            angle=math.pi*.10+math.pi*.86*step/16
            points.append((side*math.sin(angle)*width,-math.cos(angle)*.135,h-.05*math.sin(angle)))
        tube('Curved rib',points,[.015+.004*math.sin(i*math.pi/16) for i in range(17)],'chest')
    tube('Pelvic wing',[(side*.02,0,1.05),(side*.16,-.01,1.10),(side*.20,.025,1.01),(side*.10,.09,.96)],[.034,.038,.03,.025],'hips')
tube('Lower spinal cord',[(0,-.035,1.025),(0,-.035,1.36)],[.025,.027],'spine','Iron')
tube('Upper spinal cord',[(0,-.035,1.33),(0,-.035,1.73)],[.027,.025],'chest','Iron')
neck=rig.data.bones['neck']
tube('Cervical column',[neck.head_local,neck.tail_local],[.035,.032],'neck')
for index in range(3):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=((index-1)*.032,.005,1.45+index*.043))
    shard=bpy.context.object;shard.name='Fractured soul';shard.scale=(.036,.035,.085)
    bind(shard,'chest','Core')

# Lean paired limb bones, knuckle joints and extended pointed finger tips.
for side,sign in [('L',-1),('R',1)]:
    collar=rig.data.bones['shoulder.'+side]
    tube('Articulated clavicle',[collar.head_local,collar.head_local.lerp(collar.tail_local,.5)+Vector((0,.025,.02)),collar.tail_local],[.027,.022,.025],'shoulder.'+side)
    for stem in ['upper_arm','forearm','thigh','shin']:
        name=stem+'.'+side;b=rig.data.bones[name];a=b.head_local.copy();z=b.tail_local.copy();axis=z-a
        radius=.036 if stem in ['upper_arm','forearm'] else .047
        tube(stem,[a,a+axis*.12,a+axis*.48,a+axis*.88,z],[radius*1.2,radius*.8,radius*.64,radius*.85,radius],name)
        sphere('Joint',a,(radius*1.2,)*3,name)
        if stem in ['forearm','shin']:
            offset=Vector((sign*.048,0,0))
            tube('Paired bone',[a+axis*.08+offset,z-axis*.08+offset*.55],[radius*.40,radius*.34],name)
        if stem in ['forearm','shin']:
            # Broken angular splint covers only part of the bone, leaving anatomy visible.
            tangent=axis.normalized();offset=Vector((0,.055,0))
            points=[a+axis*.20+offset,a+axis*.35+offset*1.3,a+axis*.75+offset,z-axis*.10]
            tube('Forged splint',points,[radius*1.10,radius*1.30,radius*.95,radius*.4],name,'Iron',6)
    hand=rig.data.bones['hand.'+side]
    sphere('Carpal bones',hand.head_local.lerp(hand.tail_local,.55),(.043,.032,.075),'hand.'+side)
    for finger in ['f_index','f_middle','f_ring','f_pinky','thumb']:
        knuckle=rig.data.bones[f'{finger}.01.{side}'].head_local
        tube('Metacarpal',[hand.head_local.lerp(hand.tail_local,.45),knuckle],[.011,.012],'hand.'+side)
        sphere('Knuckle',knuckle,(.013,)*3,'hand.'+side)
        for segment in range(1,4):
            name=f'{finger}.{segment:02d}.{side}';b=rig.data.bones[name]
            axis=(b.tail_local-b.head_local).normalized()
            length=(b.tail_local-b.head_local).length
            end=b.tail_local+axis*(.032 if segment==3 else 0)
            tube('Claw phalanx',[b.head_local,b.head_local.lerp(end,.45),end],[.013,.010,.002 if segment==3 else .008],name)
    foot=rig.data.bones['foot.'+side]
    sphere('Heel',foot.head_local+Vector((0,0,-.035)),(.04,.047,.037),'foot.'+side)
    for toe in range(3):
        a=foot.head_local+Vector((sign*(toe-1)*.038,0,-.048))
        tube('Clawed foot',[a,a+Vector((0,.11,-.025)),a+Vector((sign*.012,.23,-.045))],[.025,.019,.003],'foot.'+side)

# Skull with actual recessed eye sockets, a separate jaw and uneven tooth line.
bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=(0,.005,1.965))
skull=bpy.context.object;skull.name='Hollow-eyed skull';skull.scale=(.116,.108,.145)
bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
for side in [-1,1]:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=(side*.052,.095,1.985))
    cutter=bpy.context.object;cutter.scale=(.04,.056,.04)
    bpy.context.view_layer.objects.active=skull
    boolean=skull.modifiers.new('Carved eye socket','BOOLEAN');boolean.operation='DIFFERENCE';boolean.object=cutter
    bpy.ops.object.modifier_apply(modifier=boolean.name);bpy.data.objects.remove(cutter,do_unlink=True)
bind(skull,'head','Bone')
for side in [-1,1]:
    sphere('Socket darkness',(side*.052,.078,1.985),(.032,.024,.032),'head','Cloth')
    sphere('Soul eye',(side*.052,.101,1.985),(.009,.007,.009),'head','Core')
    tube('Jawbone',[(side*.095,.025,1.93),(side*.082,.077,1.83),(side*.035,.108,1.815),(0,.111,1.815)],[.018,.019,.017,.016],'head')
for row in [0,1]:
    for index in range(7):
        x=(index-3)*.019
        h=1.886 if row==0 else 1.829
        end=h-.023-(index%2)*.004 if row==0 else h+.018
        tube('Tooth',[(x,.103-abs(x)*.15,h),(x,.112-abs(x)*.15,end)],[.009,.006],'head',sides=6)
sheet('Nasal recess',[(-.018,.113,1.943),(.018,.113,1.943),(0,.12,1.916)],[(0,1,2)],'head','Cloth')

# Folded hood: open around the face, tapering into a sewn closed crown.
levels=[(1.72,.21,.16,.28),(1.82,.18,.16,.85),(1.99,.175,.17,.78),(2.10,.155,.15,.52),(2.17,.08,.085,.12)]
verts=[];count=41
for row,(h,rx,ry,opening) in enumerate(levels):
    for step in range(count):
        angle=opening+(math.tau-2*opening)*step/(count-1)
        fold=1+.045*math.cos(angle*9+row*.45)
        verts.append((math.sin(angle)*rx*fold,math.cos(angle)*ry*fold-.015,h))
faces=[]
for row in range(len(levels)-1):
    for step in range(count-1):
        a=row*count+step;faces.append((a,a+1,a+count+1,a+count))
top=len(verts);verts.append((0,-.015,2.205))
for step in range(count-1):faces.append(((len(levels)-1)*count+step,(len(levels)-1)*count+step+1,top))
sheet('Tattered hood',verts,faces,'head')
for side_index in [0,count-1]:
    edge=[verts[row*count+side_index] for row in range(len(levels))]+[verts[top]]
    tube('Hood rolled seam',edge,[.008]*len(edge),'head','Cloth',8)
# A ragged shoulder mantle connects the hood silhouette to the narrow torso.
verts=[];rows=7;cols=32
for row in range(rows+1):
    t=row/rows
    for col in range(cols+1):
        angle=.75+(math.tau-1.5)*col/cols
        radius=.20+.12*math.sin(t*math.pi*.8)
        h=1.74-.36*t-.025*math.sin(col*2.1)*t*t
        verts.append((math.sin(angle)*radius,math.cos(angle)*radius*.65-.025,h))
faces=[]
for row in range(rows):
    for col in range(cols):
        a=row*(cols+1)+col;faces.append((a,a+1,a+cols+2,a+cols+1))
sheet('Torn shoulder mantle',verts,faces,'chest')
# Four narrow, torn skirt panels preserve the thin leg silhouette.
for strip in range(4):
    side=-1 if strip<2 else 1;back=strip%2
    verts=[];rows=12;cols=6
    for row in range(rows+1):
        t=row/rows
        for col in range(cols+1):
            u=col/cols
            x=side*(.025+u*.15)*(1-.12*t)
            y=(.12 if not back else -.09)+math.sin(u*math.pi*4+t)*.016
            h=1.06-t*(.54+.045*math.sin(col*2.4+strip))
            verts.append((x,y,h))
    faces=[]
    for row in range(rows):
        for col in range(cols):
            a=row*(cols+1)+col;faces.append((a,a+1,a+cols+2,a+cols+1))
    panel=sheet('Torn skirt',verts,faces,'hips')
    thigh=panel.vertex_groups.new(name='thigh.L' if side<0 else 'thigh.R')
    for vertex in panel.data.vertices:
        weight=max(0,min(.6,(1.04-vertex.co.z)*1.3))
        panel.vertex_groups['hips'].add([vertex.index],1-weight,'REPLACE');thigh.add([vertex.index],weight,'REPLACE')

bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.object.join();body=bpy.context.object;body.name='Boneghoul_OriginalBody'
skin=body.modifiers.new('Boneghoul skin','ARMATURE');skin.object=rig;body.parent=rig
rig.data.pose_position='POSE'
# A new idle is authored separately; source combat actions are reference material only.
track=next(t for t in rig.animation_data.nla_tracks if t.name=='combat_idle')
rig.animation_data.action=track.strips[0].action;bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
base={p.name:p.matrix_basis.copy() for p in rig.pose.bones}
rig.animation_data.action=None;rig.animation_data.nla_tracks.remove(track)
def aim(name,direction):
    p=rig.pose.bones[name];rest=p.bone;basis=rest.matrix_local.to_3x3()
    rotate=basis.col[1].normalized().rotation_difference(Vector(direction).normalized())
    matrix=(rotate.to_matrix() @ basis).to_4x4()
    matrix.translation=p.parent.matrix @ (p.parent.bone.matrix_local.inverted() @ rest.head_local) if p.parent else rest.head_local
    p.matrix=matrix;bpy.context.view_layer.update()
action=bpy.data.actions.new('combat_idle');rig.animation_data.action=action
for frame,breath in [(1,0),(31,1),(61,0),(91,-1),(121,0)]:
    for p in rig.pose.bones:p.matrix_basis=base[p.name]
    bpy.context.view_layer.update()
    aim('spine',(0,.18,1));aim('chest',(0,.24+breath*.015,1));aim('neck',(0,.22,1));aim('head',(0,-.06,1))
    for side,sign in [('L',-1),('R',1)]:
        aim('upper_arm.'+side,(sign*.35,.10,-1));aim('forearm.'+side,(sign*.04,.55,-.7));aim('hand.'+side,(0,.6,-.7))
        for finger in ['f_index','f_middle','f_ring','f_pinky','thumb']:
            for segment in range(1,4):
                p=rig.pose.bones[f'{finger}.{segment:02d}.{side}']
                p.rotation_quaternion=Quaternion((1,0,0),math.radians(18+segment*7))
    for p in rig.pose.bones:
        p.keyframe_insert('location',frame=frame);p.keyframe_insert('rotation_quaternion',frame=frame);p.keyframe_insert('scale',frame=frame)
new_track=rig.animation_data.nla_tracks.new();new_track.name='combat_idle';new_track.strips.new('combat_idle',1,action);new_track.mute=True
rig.animation_data.action=None
for p in rig.pose.bones:p.matrix_basis=base[p.name]
bpy.context.scene.frame_set(1)
# Fit the claw/heel surface to the planted stance, rather than leaving a shoe-sized gap.
bpy.context.view_layer.update()
evaluated=body.evaluated_get(bpy.context.evaluated_depsgraph_get())
for side in ['L','R']:
    group=body.vertex_groups['foot.'+side].index
    ids=[v.index for v in body.data.vertices if any(g.group==group and g.weight>.9 for g in v.groups)]
    lowest=min((evaluated.matrix_world @ evaluated.data.vertices[index].co).z for index in ids)
    bone=rig.pose.bones['foot.'+side]
    deformation=rig.matrix_world @ bone.matrix @ bone.bone.matrix_local.inverted() @ rig.matrix_world.inverted()
    shift=body.matrix_world.to_3x3().inverted() @ deformation.to_3x3().inverted() @ Vector((0,0,.006-lowest))
    for index in ids:body.data.vertices[index].co+=shift
    print('BONEGHOUL_FOOT_FIT',side,'prior_min=',lowest,'target=',.006)
body.data.update();bpy.context.view_layer.update()
for track in list(rig.animation_data.nla_tracks):
    if track.name=='combat_idle':continue
    for strip in track.strips:
        strip.action.use_fake_user=True
        strip.action.name='Reference_'+track.name
    rig.animation_data.nla_tracks.remove(track)
rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(Path('art_source/characters/boneghoul-production.blend').resolve()))
bpy.ops.export_scene.gltf(filepath=str(Path('assets/characters/rigged/boneghoul.glb').resolve()),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_apply=False,export_yup=True)
print('BONEGHOUL_BUILD_OK vertices=',len(body.data.vertices),' surfaces=',len(body.data.materials))
