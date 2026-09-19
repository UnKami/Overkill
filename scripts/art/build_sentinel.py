"""Original clockwork Sentinel mesh, bound to the existing tested combat skeleton.
Blender --background --disable-autoexec art_source/characters/executioner-production.blend --python scripts/art/build_sentinel.py
No source knight geometry is retained. Skeleton/animation provenance remains in the character license.
"""
import bpy, bmesh, math, json
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
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
    # Mirrored panel outlines reverse winding; orient the closed shell before beveling.
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(o.data);bm.free()
    o.data.materials.clear()
    o.data.materials.append(materials[mat]);o.data.materials.append(materials[mat])
    if bevel:
        mod=o.modifiers.new('Forged bevel','BEVEL');mod.width=bevel;mod.segments=3;mod.material=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for p in o.data.polygons:p.use_smooth=True
    normal=o.modifiers.new('Weighted face normals','WEIGHTED_NORMAL');normal.keep_sharp=True
    bpy.ops.object.modifier_apply(modifier=normal.name)
    # Corner-domain masks keep polished bevels separate from broad forged faces.
    # Channels: exposed edge, stable per-part patina variation, reserved, opaque.
    mask=o.data.color_attributes.new(name='ForgedWear',type='FLOAT_COLOR',domain='CORNER')
    o.data.color_attributes.active_color=mask
    for poly in o.data.polygons:
        edge=1.0 if bevel and poly.material_index==1 else 0.0
        color=(edge,((len(parts)*37)%101)/100.0,0.0,1.0) if mat in ['Iron','Bronze'] else (1,1,1,1)
        for index in poly.loop_indices:mask.data[index].color=color
        poly.material_index=0
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
def fluted_housing(name,a,b,rstart,rend,bone):
    axis=(b-a).normalized()
    cross=axis.cross(Vector((0,1,0))).normalized()
    depth=axis.cross(cross).normalized()
    segments=24;rows=8;verts=[]
    for row in range(rows+1):
        t=row/rows;center=a.lerp(b,t)
        radius=(rstart*(1-t)+rend*t)*(1+.05*math.sin(math.pi*t))
        for i in range(segments):
            angle=i*math.tau/segments
            # Shallow longitudinal flutes catch narrow highlights in the forged shell.
            flute=1+.055*math.cos(angle*6)*math.sin(math.pi*t)
            verts.append(center+(cross*(math.cos(angle)*1.08)+depth*(math.sin(angle)*.90))*radius*flute)
    faces=[]
    for row in range(rows):
        for i in range(segments):
            aindex=row*segments+i;bindex=row*segments+(i+1)%segments
            faces.append((aindex,bindex,bindex+segments,aindex+segments))
    faces.extend([tuple(reversed(range(segments))),tuple(range(rows*segments,(rows+1)*segments))])
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
    o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o)
    return bind(o,bone,'Iron',.005)

def mantle(side,layer):
    sign=-1 if side=='L' else 1
    center=Vector((sign*(.31+layer*.022),1.65-layer*.065,.01))
    width=.245-layer*.023;depth=.205-layer*.018;height=.12-layer*.015
    segments=32;rows=8
    def point(phi,t,expand=0):
        theta=t*(1.62+.075*math.cos(3*phi))
        return center+Vector((math.cos(phi)*math.sin(theta)*(width+expand),math.cos(theta)*height,math.sin(phi)*math.sin(theta)*(depth+expand)))
    verts=[xyz(center.x,center.y+height,center.z)]
    for row in range(1,rows+1):
        for segment in range(segments):verts.append(xyz(*point(segment*math.tau/segments,row/rows)))
    faces=[(0,1+i,1+(i+1)%segments) for i in range(segments)]
    for row in range(rows-1):
        for i in range(segments):
            a=1+row*segments+i;b=1+row*segments+(i+1)%segments
            faces.append((a,b,b+segments,a+segments))
    data=bpy.data.meshes.new('Forged mantle');data.from_pydata(verts,[],faces);data.update()
    o=bpy.data.objects.new('Curved pauldron '+side,data);bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    solid=o.modifiers.new('Plate thickness','SOLIDIFY');solid.thickness=.014
    bpy.ops.object.modifier_apply(modifier=solid.name)
    bind(o,'shoulder.'+side,'Iron',.004)
    # Rolled lower lip follows the manufactured plate instead of a rectangular band.
    verts=[]
    for row in [0.965,1.0]:
        for segment in range(segments):verts.append(xyz(*point(segment*math.tau/segments,row,.002)))
    faces=[(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    data=bpy.data.meshes.new('Mantle lip');data.from_pydata(verts,[],faces);data.update()
    o=bpy.data.objects.new('Rolled mantle lip',data);bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    solid=o.modifiers.new('Lip thickness','SOLIDIFY');solid.thickness=.003
    bpy.ops.object.modifier_apply(modifier=solid.name)
    bind(o,'shoulder.'+side,'Bronze',.001)
    if layer==0:
        for phi in [-2.5,-.65,.65,2.5]:
            p=point(phi,.85,.003);n=(p-center).normalized()
            rod('Mantle rivet',xyz(*p),xyz(*(p+n*.008)),.008,.008,'shoulder.'+side,'Bronze',8)

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
# A central forged crest and recessed vertical grille replace the toy-like brow/horns.
profile=[(-.15,2.00),(-.07,2.15),(.04,2.19),(.17,2.08),(.14,1.99)]
verts=[xyz(x,h,d) for x in [-.014,.014] for d,h in profile];n=len(profile)
faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
data=bpy.data.meshes.new('Helmet crest');data.from_pydata(verts,[],faces);data.update()
o=bpy.data.objects.new('Forged helmet crest',data);bpy.context.collection.objects.link(o);bind(o,'head','Iron',.005)
for x in [-.09,-.045,0,.045,.09]:
    top=2.015-abs(x)*.25
    rod('Visor grille',xyz(x,1.82,-.183),xyz(x,top,-.183),.008,.006,'head','Bronze',8)
box('Recessed visor light',(0,1.932,-.163),(.10,.018,.008),'head','Ember',.003)
# Folded split tabard bridges the cuirass and legs without covering the clock core.
for side in [-1,1]:
    verts=[];cols=8;rows=12
    for row in range(rows+1):
        t=row/rows
        for col in range(cols+1):
            u=col/cols
            x=side*(.027+u*(.16-.025*t))
            h=1.10-.65*t+(math.sin(u*math.pi*5)*.012 if row==rows else 0)
            d=-.168-.055*t+math.sin(u*math.pi*4)*.012*(.3+.7*t)
            verts.append(xyz(x,h,d))
    faces=[]
    for row in range(rows):
        for col in range(cols):
            a=row*(cols+1)+col;faces.append((a,a+1,a+cols+2,a+cols+1))
    data=bpy.data.meshes.new('Folded tabard');data.from_pydata(verts,[],faces);data.update()
    o=bpy.data.objects.new('Split tabard',data);bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    solid=o.modifiers.new('Cloth thickness','SOLIDIFY');solid.thickness=.004
    bpy.ops.object.modifier_apply(modifier=solid.name)
    bind(o,'hips','Recess')
    thigh=o.vertex_groups.new(name='thigh.L' if side<0 else 'thigh.R')
    for vertex in o.data.vertices:
        weight=max(0,min(.65,(1.05-vertex.co.z)*1.0))
        o.vertex_groups['hips'].add([vertex.index],1-weight,'REPLACE')
        thigh.add([vertex.index],weight,'REPLACE')
# Limb housings follow rest bones exactly. Open joints expose the mechanism.
for side in ['L','R']:
    sign=-1 if side=='L' else 1
    for stem,r1,r2 in [('upper_arm',.085,.115),('forearm',.09,.135),('thigh',.10,.145),('shin',.085,.12)]:
        bone=rig.data.bones[stem+'.'+side];a=bone.head_local.copy();b=bone.tail_local.copy();axis=b-a
        sphere('Covered joint '+stem,a,(r2*.72,)*3,stem+'.'+side,'Recess')
        if stem in ['forearm','shin']:
            fluted_housing('Fluted '+stem,a+axis*.13,b-axis*.12,r2,r1,stem+'.'+side)
        else:
            rod('Armored '+stem,a+axis*.13,b-axis*.12,r2,r1,stem+'.'+side)
        rod('End collar '+stem,b-axis*.21,b-axis*.14,r1*1.16,r1*1.16,stem+'.'+side,'Bronze')
    b=rig.data.bones['upper_arm.'+side];center=b.head_local.copy();center.x+=sign*.02;center.z+=.015
    sphere('Shoulder pivot',center,(.12,.13,.12),'upper_arm.'+side,'Recess')
    for layer in range(3):mantle(side,layer)
    hand=rig.data.bones['hand.'+side]
    rod('Gauntlet palm',hand.head_local,hand.tail_local,.065,.057,'hand.'+side)
    for finger in ['f_index','f_middle','f_ring','f_pinky','thumb']:
        for segment in range(1,4):
            name=f'{finger}.{segment:02d}.{side}';b=rig.data.bones[name]
            rod('Finger',b.head_local,b.tail_local,.014,.012,name,'Iron',8)
    foot=rig.data.bones['foot.'+side].head_local
    # Overlapping arched sabatons taper to the toe instead of a rectangular boot.
    for course in range(4):
        rear=.09-course*.072;front=rear-.094
        width=.095-course*.007;peak=.19-course*.032
        verts=[];steps=12
        for d in [rear,front]:
            for i in range(steps+1):
                angle=math.pi*i/steps
                verts.append(xyz(foot.x+math.cos(angle)*width,.035+math.sin(angle)*peak,d))
        faces=[(i,i+1,i+steps+2,i+steps+1) for i in range(steps)]
        # Close the toe/end courses; an open arch reads as an empty boot in game.
        faces.extend([tuple(reversed(range(steps+1))),tuple(range(steps+1,2*(steps+1)))])
        data=bpy.data.meshes.new('Sabaton course');data.from_pydata(verts,[],faces);data.update()
        o=bpy.data.objects.new('Articulated sabaton',data);bpy.context.collection.objects.link(o)
        bpy.context.view_layer.objects.active=o;o.select_set(True)
        solid=o.modifiers.new('Boot plate thickness','SOLIDIFY');solid.thickness=.012
        bpy.ops.object.modifier_apply(modifier=solid.name)
        bind(o,'foot.'+side,'Iron',.004)
    box('Boot sole',(foot.x,.024,-.067),(.18,.035,.33),'foot.'+side,'Recess',.018)
    # Pointed knee plate covers the spherical pivot and overlaps the greave.
    knee=rig.data.bones['shin.'+side].head_local
    panel('Knee poleyn',[(knee.x-.085,knee.z+.015),(knee.x,knee.z+.095),
        (knee.x+.085,knee.z+.015),(knee.x+.065,knee.z-.055),
        (knee.x,knee.z-.105),(knee.x-.065,knee.z-.055)],
        -knee.y-.092,-knee.y-.045,'shin.'+side,'Iron',.012)
# Single skinned mesh; four PBR surface groups, rather than dozens of rigid draws.
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.object.join();mesh=bpy.context.object;mesh.name='Sentinel_AuthoredBody'
# Bake short-range cavity occlusion into the spare blue mask channel.
# Radius is local (8 cm), avoiding broad pose-dependent shadows on moving limbs.
vertices=[v.co.copy() for v in mesh.data.vertices]
tree=BVHTree.FromPolygons(vertices,[list(p.vertices) for p in mesh.data.polygons])
visibility=[]
for vertex in mesh.data.vertices:
    normal=vertex.normal.normalized()
    axis=Vector((0,0,1)) if abs(normal.z)<.9 else Vector((1,0,0))
    tangent=normal.cross(axis).normalized();bitangent=normal.cross(tangent)
    clear=0
    for sample in range(16):
        r=math.sqrt((sample+.5)/16);a=sample*2.399963229728653
        direction=(tangent*(r*math.cos(a))+bitangent*(r*math.sin(a))+normal*math.sqrt(1-r*r)).normalized()
        hit=tree.ray_cast(vertex.co+normal*.0015,direction,.08)
        if hit[0] is None: clear+=1
    visibility.append(clear/16)
mask=mesh.data.color_attributes.active_color
for poly in mesh.data.polygons:
    if mesh.data.materials[poly.material_index].name not in ['Sentinel_Iron','Sentinel_Bronze']:continue
    for index in poly.loop_indices:
        color=list(mask.data[index].color);color[2]=visibility[mesh.data.loops[index].vertex_index];mask.data[index].color=color
print('CAVITY_BAKE_RANGE',min(visibility),max(visibility))
mod=mesh.modifiers.new('Sentinel skin','ARMATURE');mod.object=rig;mesh.parent=rig
rig.data.pose_position='POSE'
# Author a Sentinel-specific braced guard while preserving the source foot placement.
def author_guard():
    track=next(t for t in rig.animation_data.nla_tracks if t.name=='guard')
    source=track.strips[0].action
    rig.animation_data.action=source
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    idle={p.name:p.matrix_basis.copy() for p in rig.pose.bones}
    bpy.context.scene.frame_set(5)
    bpy.context.view_layer.update()
    def aim_bone(name,direction):
        p=rig.pose.bones[name];rest=p.bone;basis=rest.matrix_local.to_3x3()
        rotation=basis.col[1].normalized().rotation_difference(Vector(direction).normalized())
        desired=(rotation.to_matrix() @ basis).to_4x4()
        desired.translation=p.parent.matrix @ (p.parent.bone.matrix_local.inverted() @ rest.head_local) if p.parent else rest.head_local
        p.matrix=desired;bpy.context.view_layer.update()
    aim_bone('spine',(0,.12,1))
    aim_bone('chest',(0,.14,1))
    aim_bone('head',(0,.04,1))
    # Broad left vambrace crosses the clock core; the weapon arm protects the outer line.
    aim_bone('upper_arm.L',(-.35,.7,-.45))
    aim_bone('forearm.L',(.75,.2,.65))
    aim_bone('hand.L',(.6,.4,.3))
    aim_bone('upper_arm.R',(.2,.55,-.6))
    aim_bone('forearm.R',(-.2,.35,.75))
    aim_bone('hand.R',(0,.4,.8))
    brace={p.name:p.matrix_basis.copy() for p in rig.pose.bones}
    rig.animation_data.action=None
    rig.animation_data.nla_tracks.remove(track)
    source.name='SourceGuardReference'
    action=bpy.data.actions.new('guard')
    rig.animation_data.action=action
    for frame,weight in [(1,0.0),(4,1.0),(10,1.0),(18,.45),(33,0.0)]:
        for p in rig.pose.bones:
            p.matrix_basis=idle[p.name].lerp(brace[p.name],weight)
            p.keyframe_insert('location',frame=frame)
            p.keyframe_insert('rotation_quaternion',frame=frame)
            p.keyframe_insert('scale',frame=frame)
    new_track=rig.animation_data.nla_tracks.new();new_track.name='guard'
    new_track.strips.new('guard',1,action);new_track.mute=True
    rig.animation_data.action=None
    for p in rig.pose.bones:p.matrix_basis=idle[p.name]
    bpy.context.scene.frame_set(1)
    print('SENTINEL_GUARD_AUTHORED',action.name)
author_guard()
rig.select_set(True)
bpy.context.view_layer.objects.active=rig
out=Path('assets/characters/rigged/sentinel.glb')
bpy.ops.wm.save_as_mainfile(filepath=str(Path('art_source/characters/sentinel-production.blend').resolve()))
bpy.ops.export_scene.gltf(filepath=str(out.resolve()),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_apply=False,export_yup=True,export_vertex_color='ACTIVE',export_all_vertex_colors=False)
print('SENTINEL_BUILD_OK vertices=',len(mesh.data.vertices),' surfaces=',len(mesh.data.materials))
