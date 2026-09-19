"""Original clockwork Sentinel mesh, bound to the existing tested combat skeleton.
Blender --background --disable-autoexec art_source/characters/executioner-production.blend --python scripts/art/build_sentinel.py
No source knight geometry is retained. Skeleton/animation provenance remains in the character license.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
rig.data.pose_position='REST'
for o in list(bpy.data.objects):
    if o != rig: bpy.data.objects.remove(o,do_unlink=True)
materials={}
for name,color,metal,rough in [('Iron',(0.075,0.092,0.103,1),0.8,0.62),('Bronze',(0.34,0.22,0.085,1),0.76,0.5),('Recess',(0.012,0.017,0.021,1),0.25,0.82),('Ember',(0.85,0.27,0.045,1),0.25,0.38)]:
    m=bpy.data.materials.new('Sentinel_'+name);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=color;bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
    if name=='Ember': bs.inputs['Emission Color'].default_value=color;bs.inputs['Emission Strength'].default_value=1.4
    materials[name]=m
parts=[]
def bind(o,bone,mat,bevel=0):
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Forged bevel','BEVEL');mod.width=bevel;mod.segments=3
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for p in o.data.polygons:p.use_smooth=True
    normal=o.modifiers.new('Weighted face normals','WEIGHTED_NORMAL');normal.keep_sharp=True
    bpy.ops.object.modifier_apply(modifier=normal.name)
    o.data.materials.clear();o.data.materials.append(materials[mat])
    o.vertex_groups.new(name=bone).add(list(range(len(o.data.vertices))),1,'REPLACE')
    o.select_set(False);parts.append(o)
    return o
def xyz(x,h,d):return Vector((x,-d,h))
def box(name,at,size,bone,mat='Iron',bevel=.016):
    bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(*at));o=bpy.context.object;o.name=name;o.scale=(size[0],size[2],size[1]);return bind(o,bone,mat,bevel)
def sphere(name,at,size,bone,mat='Iron'):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,radius=1,location=at);o=bpy.context.object;o.name=name;o.scale=size;return bind(o,bone,mat)
def rod(name,a,b,r1,r2,bone,mat='Iron',vertices=12):
    axis=Vector(b)-Vector(a)
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r1,radius2=r2,depth=axis.length,location=(Vector(a)+Vector(b))*.5)
    o=bpy.context.object;o.name=name;o.rotation_mode='QUATERNION';o.rotation_quaternion=Vector((0,0,1)).rotation_difference(axis)
    return bind(o,bone,mat,.009)
def ring(name,at,radius,tube,bone,mat='Bronze',front=True):
    bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=8,major_radius=radius,minor_radius=tube,location=xyz(*at),rotation=(math.pi/2 if front else 0,0,0))
    o=bpy.context.object;o.name=name;return bind(o,bone,mat)
def panel(name,outline,front,back,bone,mat='Iron',bevel=.012):
    verts=[xyz(x,h,d) for d in [front,back] for x,h in outline];n=len(outline)
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
    return bind(o,bone,mat,bevel)
# Trunk: deep, dark clock housing between chamfered breastplate wings.
box('Clock housing',(0,1.44,.015),(.49,.47,.29),'chest','Recess',.04)
for side in [-1,1]:
    panel('Breastplate arch',[(side*.055,1.72),(side*.255,1.67),(side*.31,1.48),(side*.255,1.22),(side*.14,1.25),(side*.185,1.47)],-.19,.14,'chest',bevel=.018)
    box('Collar inlay',(side*.15,1.69,-.192),(.16,.025,.017),'chest','Bronze',.006)
for radius,tube in [(.159,.018),(.128,.008),(.089,.006)]:ring('Recessed chronometer',(0,1.455,-.203),radius,tube,'chest')
ring('Clock aperture',(0,1.455,-.202),.056,.012,'chest','Iron')
sphere('Clock heart',xyz(0,1.455,-.206),(.025,.012,.025),'chest','Ember')
for i in range(9):
    a=i*math.tau/9
    o=box('Clock index',(math.sin(a)*.14,1.455+math.cos(a)*.14,-.223),(.012,.03,.014),'chest','Bronze',.003)
    o.rotation_euler.y=a
box('Clock hand',(0,1.505,-.225),(.014,.10,.014),'chest','Bronze',.003)
# Vertebrae and overlapping abdomen plates.
rod('Spine',xyz(0,1.06,.04),xyz(0,1.5,.04),.085,.10,'spine','Recess')
for layer in range(3):
    panel('Abdominal lame',[(-.19,1.27-layer*.07),(.19,1.27-layer*.07),(.15,1.19-layer*.07),(-.15,1.19-layer*.07)],-.125,-.005,'spine')
box('Pelvic housing',(0,1.015,0),(.34,.18,.24),'hips','Recess',.03)
for side in [-1,1]:
    panel('Hip skirt',[(side*.025,1.11),(side*.19,1.12),(side*.245,.88),(side*.07,.85)],-.155,.085,'hips',bevel=.014)
# Curved bell shell: five forged courses taper to a rounded crown around an open face.
def bell_shell():
    levels=[(1.79,.11,.10),(1.84,.16,.13),(1.95,.145,.145),(2.025,.12,.12),(2.065,.035,.045)]
    verts=[];count=33
    for h,rx,rd in levels:
        for i in range(count):
            a=math.radians(30)+math.radians(300)*i/(count-1)
            verts.append(xyz(math.sin(a)*rx,h,-math.cos(a)*rd+.015))
    faces=[]
    for row in range(len(levels)-1):
        for i in range(count-1):
            a=row*count+i;faces.append((a,a+1,a+count+1,a+count))
    mesh=bpy.data.meshes.new('Bell shell');mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new('Bell shell',mesh);bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    solid=o.modifiers.new('Forged thickness','SOLIDIFY');solid.thickness=.018
    bpy.ops.object.modifier_apply(modifier=solid.name)
    bind(o,'head','Iron',.006)
bell_shell()
# Bell helm: a smooth faceless visor recessed into angular temple armor.
box('Neck block',(0,1.74,0),(.18,.14,.16),'neck','Recess',.025)
ring('Gorget',(0,1.738,0),.16,.018,'chest',front=False)
panel('Blind visor',[(-.115,2.035),(.115,2.035),(.14,1.82),(.085,1.765),(-.085,1.765),(-.14,1.82)],-.154,.055,'head','Recess',.025)
for side in [-1,1]:
    panel('Crown blade',[(side*.115,2.025),(side*.155,2.18),(side*.18,2.13),(side*.145,1.96)],-.01,.045,'head','Bronze',.008)
box('Brow beam',(0,1.995,-.183),(.26,.042,.028),'head','Bronze',.009)
for side in [-1,1]:box('Visor slit',(side*.055,1.966,-.167),(.07,.008,.01),'head','Ember',.002)
panel('Visor keel',[(-.024,1.98),(.024,1.98),(.035,1.82),(0,1.785),(-.035,1.82)],-.182,-.12,'head','Iron',.005)
# Limb housings follow rest bones exactly. Open joints expose the mechanism.
for side in ['L','R']:
    sign=-1 if side=='L' else 1
    for stem,r1,r2 in [('upper_arm',.085,.115),('forearm',.09,.135),('thigh',.10,.145),('shin',.085,.12)]:
        bone=rig.data.bones[stem+'.'+side];a=bone.head_local.copy();b=bone.tail_local.copy();axis=b-a
        sphere('Joint '+stem,a,(r2*.72,)*3,stem+'.'+side,'Bronze')
        rod('Armored '+stem,a+axis*.13,b-axis*.12,r2,r1,stem+'.'+side)
        rod('End collar '+stem,b-axis*.21,b-axis*.14,r1*1.16,r1*1.16,stem+'.'+side,'Bronze')
    b=rig.data.bones['upper_arm.'+side];center=b.head_local.copy();center.x+=sign*.02;center.z+=.015
    sphere('Shoulder pivot',center,(.12,.13,.12),'upper_arm.'+side,'Recess')
    for layer in range(3):
        # Angular flared mantles replace the previous spherical shoulder caps.
        x=sign*(.3+layer*.025);h=1.73-layer*.06
        panel('Pauldron '+side,[(x-sign*.13,h+.03),(x+sign*.12,h-.015),(x+sign*.17,h-.085),(x-sign*.09,h-.09)],-.15,.14,'shoulder.'+side,'Iron',.016)
    hand=rig.data.bones['hand.'+side]
    rod('Gauntlet palm',hand.head_local,hand.tail_local,.065,.057,'hand.'+side)
    for finger in ['f_index','f_middle','f_ring','f_pinky','thumb']:
        for segment in range(1,4):
            name=f'{finger}.{segment:02d}.{side}';b=rig.data.bones[name]
            rod('Finger',b.head_local,b.tail_local,.014,.012,name,'Iron',8)
    foot=rig.data.bones['foot.'+side].head_local
    box('Armored boot',(foot.x,.09,-.045),(.20,.17,.38),'foot.'+side,'Iron',.025)
    box('Boot rim',(foot.x,.035,-.045),(.21,.035,.39),'foot.'+side,'Bronze',.008)
# Single skinned mesh; four PBR surface groups, rather than dozens of rigid draws.
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.object.join();mesh=bpy.context.object;mesh.name='Sentinel_AuthoredBody'
mod=mesh.modifiers.new('Sentinel skin','ARMATURE');mod.object=rig;mesh.parent=rig
rig.data.pose_position='POSE'
rig.select_set(True)
bpy.context.view_layer.objects.active=rig
out=Path('assets/characters/rigged/sentinel.glb')
bpy.ops.wm.save_as_mainfile(filepath=str(Path('art_source/characters/sentinel-production.blend').resolve()))
bpy.ops.export_scene.gltf(filepath=str(out.resolve()),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_apply=False,export_yup=True)
print('SENTINEL_BUILD_OK vertices=',len(mesh.data.vertices),' surfaces=',len(mesh.data.materials))
