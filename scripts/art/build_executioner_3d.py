"""Executioner: volumetric human skin, fitted armor, fingers, recorded motion.

Run in Blender 5.2. Runtime is glTF + baked local skeletal transforms. Source
assets are CC0 MakeHuman; recorded performance is CMU's free-for-all-uses data.
Armor, tailoring and action assembly are authored here, not downloaded models.
"""
from pathlib import Path
import sys, json, math, random
import bpy
from mathutils import Vector, Matrix, Quaternion
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/characters/executioner/three_d'
SRC=OUT/'source'; VENDOR=SRC/'vendor'
FPS=60; random.seed(47047)
sys.path.insert(0,str(Path(__file__).parent))
from cmu_motion import Motion
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.fps=FPS

# Retain real anatomical topology and published skin weights. Helpers/landmarks
# are used to fit the skeleton, but are never rendered or shipped in the GLB.
raw=[];faces=[];group='';uvs=[];face_uvs=[]
for line in (VENDOR/'human-base.obj').read_text().splitlines():
    row=line.split()
    if not row:continue
    if row[0]=='v':raw.append(Vector(tuple(map(float,row[1:]))))
    elif row[0]=='vt':uvs.append(tuple(map(float,row[1:3])))
    elif row[0]=='g':group=row[1]
    elif row[0]=='f' and group=='body':
        faces.append([int(x.split('/')[0])-1 for x in row[1:]])
        face_uvs.append([int(x.split('/')[1])-1 for x in row[1:]])
# Neutral adult male body: average the three official macro morphs rather than
# selecting a particular face/ethnicity for this faceless character. Helpers
# receive the same morph, so all joint landmarks follow the fitted anatomy.
for category in ('african','asian','caucasian'):
    for line in (VENDOR/(category+'-male-young.target')).read_text().splitlines():
        values=line.split()
        if len(values)==4 and values[0].isdigit():
            raw[int(values[0])] += Vector(tuple(map(float,values[1:])))/3
used=sorted({i for f in faces for i in f})
ground=min(raw[i].y for i in used)
height=max(raw[i].y for i in used)-ground
scale=1.91/height
def convert(v):return Vector((v.x*scale,-v.z*scale,(v.y-ground)*scale))
verts=[convert(v) for v in raw]
definition=json.loads((VENDOR/'human-rig.json').read_text())
raw_weights=json.loads((VENDOR/'human-weights.json').read_text())['weights']
def joint(label):
    ids=definition['joints'][label]
    return sum((verts[i] for i in ids),Vector())/len(ids)
def original(name,part='head'):return joint(definition['bones'][name][part])

BONES=[]
def bone(name,parent,head,tail,roll=(0,-1,0)):
    BONES.append({'name':name,'parent':parent,'head':Vector(head),'tail':Vector(tail),'roll':Vector(roll)})
bone('root','',(0,0,0),(0,0,.12))
bone('pelvis','root',(0,0,original('spine05').z),(0,0,original('spine04').z))
bone('spine_lower','pelvis',original('spine04'),original('spine03'))
bone('spine_mid','spine_lower',original('spine03'),original('spine01'))
bone('spine_upper','spine_mid',original('spine01'),original('spine01','tail'))
bone('neck','spine_upper',original('neck01'),original('head'))
bone('head','neck',original('head'),original('head','tail'))
for side in ('L','R'):
    arm=original('upperarm01.'+side);elbow=original('lowerarm01.'+side);wrist=original('wrist.'+side)
    normal=(elbow-arm).cross(wrist-elbow).normalized()
    bone('clavicle.'+side,'spine_upper',original('clavicle.'+side),arm)
    bone('upper_arm.'+side,'clavicle.'+side,arm,elbow,normal)
    bone('upper_arm_twist.'+side,'upper_arm.'+side,original('upperarm02.'+side),elbow,normal)
    bone('forearm.'+side,'upper_arm.'+side,elbow,wrist,normal)
    bone('forearm_twist.'+side,'forearm.'+side,original('lowerarm02.'+side),wrist,normal)
    bone('hand.'+side,'forearm.'+side,wrist,original('finger3-1.'+side),normal)
    hip=original('upperleg01.'+side);knee=original('lowerleg01.'+side);ankle=original('foot.'+side)
    bone('thigh.'+side,'pelvis',hip,knee,(0,-1,0))
    bone('shin.'+side,'thigh.'+side,knee,ankle,(0,-1,0))
    bone('foot.'+side,'shin.'+side,ankle,original('foot.'+side,'tail'),(0,0,1))
    for finger in range(1,6):
        for segment in range(1,4):
            name=f'finger{finger}-{segment}.{side}'
            parent='hand.'+side if segment==1 else f'finger{finger}-{segment-1}.{side}'
            bone(name,parent,original(name),original(name,'tail'),normal)
for column,x in enumerate((-.18,0,.18)):
    bone(f'cloak_upper_{column}','spine_upper',(x,.14,1.5),(x,.21,1.01))
    bone(f'cloak_lower_{column}',f'cloak_upper_{column}',(x,.21,1.01),(x,.26,.5))
for side,x in (('L',.12),('R',-.12)):
    bone('skirt.'+side,'pelvis',(x,-.09,.97),(x,-.13,.56))
names=[b['name'] for b in BONES]
by_name={b['name']:b for b in BONES}
arm_data=bpy.data.armatures.new('Executioner_Human_Skeleton')
rig=bpy.data.objects.new('ExecutionerRig',arm_data);scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for b in BONES:
    eb=arm_data.edit_bones.new(b['name']);eb.head=b['head'];eb.tail=b['tail'];eb.align_roll(b['roll'])
    if b['parent']:
        eb.parent=arm_data.edit_bones[b['parent']]
        eb.use_connect=(eb.head-eb.parent.tail).length<.0001
bpy.ops.object.mode_set(mode='OBJECT');rig.show_in_front=True
rest={n:arm_data.bones[n].matrix_local.copy() for n in names}

def mapped(name):
    if name in names:return name
    stem,sep,side=name.partition('.')
    if stem in ('upperarm01','shoulder01'):return 'upper_arm.'+side
    if stem=='upperarm02':return 'upper_arm_twist.'+side
    if stem=='lowerarm01':return 'forearm.'+side
    if stem=='lowerarm02':return 'forearm_twist.'+side
    if stem in ('upperleg01','upperleg02'):return 'thigh.'+side
    if stem in ('lowerleg01','lowerleg02'):return 'shin.'+side
    if stem=='wrist' or stem.startswith('metacarpal'):return 'hand.'+side
    if stem.startswith('toe'):return 'foot.'+side
    if stem in ('pelvis','root'):return 'pelvis'
    if stem in ('spine05','spine04'):return 'spine_lower'
    if stem in ('spine03','spine02'):return 'spine_mid'
    if stem=='spine01' or stem=='breast':return 'spine_upper'
    if stem.startswith('neck'):return 'neck'
    return 'head'

def material(name,color,metal=0,rough=.5,emission=0):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    bsdf=mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value=(*color,1)
    bsdf.inputs['Metallic'].default_value=metal;bsdf.inputs['Roughness'].default_value=rough
    if emission:
        bsdf.inputs['Emission Color'].default_value=(*color,1)
        bsdf.inputs['Emission Strength'].default_value=emission
    return mat
leather=material('Black indigo leather',(.005,.007,.011),0,.88)
cloth=material('Worn hood and mantle',(.009,.012,.018),0,.92)
bronze=material('Antique bronze',(.29,.16,.065),.78,.34)
gold=material('Polished edge trim',(.57,.34,.12),.86,.23)
dark_metal=material('Gunmetal joints',(.052,.065,.08),.8,.43)
cyan=material('Cyan crystal',(.014,.41,.65),.3,.18,1.6)
ember=material('Ember crystal',(.65,.16,.021),.3,.2,1.4)
void=material('Faceless black mask',(.003,.005,.008),.1,.91)
grey=material('Anatomy review neutral',(.32,.36,.40),0,.64)

# Microgeometry stays subtle at combat distance; avoid baked painted lighting.
# The generated maps are procedural original material data, not edited imagery.
def surface_maps(mat,seed):
    rng=np.random.default_rng(seed);size=512
    y,x=np.mgrid[:size,:size]
    noise=rng.normal(0,1,(size,size))
    scratches=(np.sin(x*.31+y*.017)> .993)*(.1+rng.random((size,size))*.2)
    value=np.clip(.5+noise*.035+scratches,0,1)
    image=bpy.data.images.new(mat.name+'.roughness',width=size,height=size,alpha=True)
    pixels=np.dstack((value,value,value,np.ones_like(value))).astype(np.float32)
    image.pixels.foreach_set(pixels.ravel());image.colorspace_settings.name='Non-Color';image.pack()
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
    mat.node_tree.links.new(tex.outputs['Color'],mat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'])
# Use stable scalar roughness for the initial geometry review. The prior
# generated image pack path was not preserving its pixels in all glTF tools.
atlas=bpy.data.images.load(str(ROOT/'assets/characters/executioner/rigged/parts_atlas.png'));atlas.pack()
painted={}
for label,base,cell,metal,rough in [('cuirass',bronze,1,.62,.54),('abdomen',bronze,2,.6,.57),
 ('pauldron.R',bronze,4,.65,.51),('pauldron.L',bronze,7,.65,.51),
 ('vambrace.R',bronze,5,.65,.54),('vambrace.L',bronze,8,.65,.54),
 ('thigh.R',leather,10,.3,.68),('thigh.L',leather,13,.3,.68),
 ('shin.R',bronze,11,.62,.57),('shin.L',bronze,14,.62,.57),
 ('boot.R',bronze,12,.6,.6),('boot.L',bronze,15,.6,.6),('hood',cloth,0,.02,.89)]:
    mat=base.copy();mat.name='Executioner surface '+label
    bsdf=mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Metallic'].default_value=metal;bsdf.inputs['Roughness'].default_value=rough
    # Painted sprite lighting folds and stretches on curved volume. Keep
    # physical metal colors; the modeled rims, lames and crystals carry detail.
    painted[label]=(mat,cell)

def paint_uv(obj,label,uv_points=None):
    mat,cell=painted[label]
    obj.data.materials.clear();obj.data.materials.append(mat)
    layer=obj.data.uv_layers.get('Executioner surface UV') or obj.data.uv_layers.new(name='Executioner surface UV')
    xyz=[v.co for v in obj.data.vertices]
    lo_x=min(v.x for v in xyz);hi_x=max(v.x for v in xyz)
    lo_z=min(v.z for v in xyz);hi_z=max(v.z for v in xyz)
    for loop in obj.data.loops:
        if uv_points: u,v=uv_points[loop.vertex_index]
        else:
            p=xyz[loop.vertex_index];u=(p.x-lo_x)/max(.001,hi_x-lo_x);v=(p.z-lo_z)/max(.001,hi_z-lo_z)
        layer.data[loop.index].uv=((cell%4+.04+.92*u)/4,(3-cell//4+.04+.92*v)/4)
    return obj

model_objects=[]
def bind(obj,weights,mat):
    if mat:obj.data.materials.append(mat)
    for name,entries in weights.items():
        group=obj.vertex_groups.new(name=name)
        for ids,w in entries:group.add(ids,w,'REPLACE')
    obj.modifiers.new('Human skin deformation','ARMATURE').object=rig
    obj.parent=rig;model_objects.append(obj)
    for face in obj.data.polygons:face.use_smooth=True
    # bpy.object.convert acts on ALL selected objects. Leaving a previous
    # primitive selected would bake away its skin when a trim curve converts.
    obj.select_set(False)
    return obj

index_map={old:new for new,old in enumerate(used)}
data=bpy.data.meshes.new('Anatomical deformation topology')
data.from_pydata([verts[i] for i in used],[],[[index_map[i] for i in f] for f in faces]);data.update()
layer=data.uv_layers.new(name='Human surface UV')
for polygon,uv_ids in zip(data.polygons,face_uvs):
    for loop,ui in zip(polygon.loop_indices,uv_ids):layer.data[loop].uv=uvs[ui]
human=bpy.data.objects.new('Tailored articulated leather body',data);scene.collection.objects.link(human)
weights={}
per_vertex={i:{} for i in used}
for name,entries in raw_weights.items():
    target=mapped(name)
    for i,w in entries:
        if i in per_vertex:per_vertex[i][target]=per_vertex[i].get(target,0)+w
for i,row in per_vertex.items():
    strongest=sorted(row.items(),key=lambda p:p[1],reverse=True)[:4]
    total=sum(w for _,w in strongest)
    assert total>0,('unweighted anatomical vertex',i)
    for n,w in strongest:weights.setdefault(n,[]).append(([index_map[i]],w/total))
bind(human,weights,leather)
human.data.materials.append(void)
for face in human.data.polygons:
    if sum(human.data.vertices[i].co.z for i in face.vertices)/len(face.vertices)>1.67:
        face.material_index=1

def rigid(obj,name,mat):
    return bind(obj,{name:[(list(range(len(obj.data.vertices))),1)]},mat)
def mesh(name,points,faces,bone_name,mat,bevel=0):
    m=bpy.data.meshes.new(name);m.from_pydata(points,[],faces);m.update()
    obj=bpy.data.objects.new(name,m);scene.collection.objects.link(obj)
    if bevel:
        mod=obj.modifiers.new('Forged softened edges','BEVEL');mod.width=bevel;mod.segments=3
        bpy.context.view_layer.objects.active=obj;obj.select_set(True)
        bpy.ops.object.modifier_apply(modifier=mod.name);obj.select_set(False)
    return rigid(obj,bone_name,mat)
def uv_sphere(name,at,scale,bone_name,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=16,location=at)
    obj=bpy.context.object;obj.name=name;obj.scale=scale
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    return rigid(obj,bone_name,mat)
def path_tube(name,points,radius,bone_name,mat):
    curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.bevel_depth=radius;curve.bevel_resolution=2
    spline=curve.splines.new('POLY');spline.points.add(len(points)-1)
    for p,at in zip(spline.points,points):p.co=(*at,1)
    obj=bpy.data.objects.new(name,curve);scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active=obj;obj.select_set(True);bpy.ops.object.convert(target='MESH');obj.select_set(False)
    return rigid(obj,bone_name,mat)
def band(name,start,end,r0,r1,bone_name,mat):
    start,end=Vector(start),Vector(end);direction=(end-start).normalized()
    frame=direction.to_track_quat('Z','Y').to_matrix()
    points=[]
    for i in range(5):
        t=i/4;radius=r0*(1-t)+r1*t
        for j in range(24):
            a=j*math.tau/24;points.append(start.lerp(end,t)+frame@Vector((radius*math.cos(a),radius*.8*math.sin(a),0)))
    faces=[(i*24+j,i*24+(j+1)%24,(i+1)*24+(j+1)%24,(i+1)*24+j) for i in range(4) for j in range(24)]
    obj=mesh(name,points,faces,bone_name,mat)
    shell=obj.modifiers.new('Actual plate thickness','SOLIDIFY');shell.thickness=.004
    bpy.context.view_layer.objects.active=obj;obj.select_set(True);bpy.ops.object.modifier_apply(modifier=shell.name);obj.select_set(False)
    return obj
def plate(name,center,width,height,depth,bone_name,mat):
    # Domed octagonal steel, actual curved front and sealed back, no billboards.
    cx,cy,cz=center
    outline=[(-.68,-1),(.68,-1),(1,-.55),(1,.65),(.55,1),(-.55,1),(-1,.65),(-1,-.55)]
    points=[(cx,cy-depth,cz)]
    for shrink,bulge in ((.55,.8),(1,0)):
        points += [(cx+x*width*.5*shrink,cy-depth*bulge,cz+z*height*.5*shrink) for x,z in outline]
    points += [(cx+x*width*.5,cy+.012,cz+z*height*.5) for x,z in outline]
    faces=[(0,j+1,(j+1)%8+1) for j in range(8)]
    faces += [(1+j,1+(j+1)%8,9+(j+1)%8,9+j) for j in range(8)]
    faces += [(9+j,9+(j+1)%8,17+(j+1)%8,17+j) for j in range(8)]
    faces += [tuple(range(17,25))]
    obj=mesh(name,points,faces,bone_name,mat,.004)
    path_tube(name+'.raised rim',[(cx+x*width*.5,cy-.002,cz+z*height*.5) for x,z in outline+[outline[0]]],.0035,bone_name,gold)
    return obj
def crystal(name,at,length,bone_name,mat,direction=(0,-1,.6)):
    at=Vector(at);frame=Vector(direction).normalized().to_track_quat('Z','Y').to_matrix()
    points=[]
    for h,r in ((0,length*.22),(length*.68,length*.16)):
        for i in range(6):
            a=i*math.tau/6;points.append(at+frame@Vector((math.cos(a)*r,math.sin(a)*r,h)))
    points.append(at+frame@Vector((0,0,length)))
    faces=[(i,(i+1)%6,6+(i+1)%6,6+i) for i in range(6)]+[(6+i,6+(i+1)%6,12) for i in range(6)]
    obj=mesh(name,points,faces,bone_name,mat)
    for p in obj.data.polygons:p.use_smooth=False
    return obj

# Wardrobe is built after neutral posing by executioner_tailored_wardrobe.

# Establish an actual 3D human stance using articulated limb goals, in meters.
def orientation(direction,normal):
    y=Vector(direction).normalized();z=Vector(normal)-y*Vector(normal).dot(y)
    if z.length<.001:z=Vector((0,-1,0))-y*y.dot(Vector((0,-1,0)))
    if z.length<.001:z=Vector((1,0,0))-y*y.x
    z.normalize();x=y.cross(z).normalized();z=x.cross(y).normalized()
    return Matrix((x,y,z)).transposed().to_quaternion()
def limb_pose(world,first,second,end,goal,pole):
    b=by_name[first];parent=b['parent'];parent_matrix=world[parent]
    start=parent_matrix@rest[parent].inverted()@b['head']
    l1=(b['tail']-b['head']).length;l2=(by_name[second]['tail']-by_name[second]['head']).length
    margin=.0001 if first.startswith('thigh') else .012
    minimum=math.sqrt(l1*l1+l2*l2+2*l1*l2*math.cos(math.radians(145)))
    delta=Vector(goal)-start;d=max(minimum,min(l1+l2-margin,delta.length));axis=delta.normalized()
    bend=Vector(pole)-start; bend-=axis*bend.dot(axis)
    if bend.length<.01:bend=Vector((0,.5,.1))-axis*axis.dot(Vector((0,.5,.1)))
    bend.normalize()
    along=(l1*l1-l2*l2+d*d)/(2*d);across=math.sqrt(max(0,l1*l1-along*along))
    joint=start+axis*along+bend*across;goal=start+axis*d
    normal=(joint-start).cross(goal-joint).normalized()
    for name,head,tail in ((first,start,joint),(second,joint,goal)):
        q=orientation(tail-head,normal)
        world[name]=q.to_matrix().to_4x4();world[name].translation=head
    end_bone=by_name[end]
    world[end]=world[second]@rest[second].inverted()@rest[end]
    return goal

def base_pose(drop=0,advance=0,yaw=0,lean=0,near=None,far=None,curl=.28,feet=None,twist=0,shift=(0,0,0)):
    world={};rot=Quaternion((0,0,1),math.radians(yaw))
    for b in BONES:
        n=b['name'];p=b['parent']
        m=world[p]@rest[p].inverted()@rest[n] if p else rest[n].copy()
        if n=='pelvis':m=rot.to_matrix().to_4x4()@m;m.translation+=Vector((0,-advance,-drop-.012))+Vector(shift)
        if n in ('spine_lower','spine_mid','spine_upper'):
            m=m@Matrix.Rotation(math.radians(lean/3),4,'X')@Matrix.Rotation(math.radians(twist/3),4,'Y')
        if n=='head':m=m@Matrix.Rotation(math.radians(-lean*.2),4,'X')
        if n.startswith('clavicle.'):
            side=n[-1];goal=Vector(near if side=='R' and near is not None else far if side=='L' and far is not None else ((-.25 if side=='R' else .25),-.09,.96))
            elevation=max(0,min(1,(goal.z-1.3)/.45))
            protract=max(0,min(1,(-goal.y-.15)/.4))
            current=m.to_quaternion()@Vector((0,1,0))
            target=(current+Vector((0,-.08*protract,.23*elevation))).normalized()
            delta=current.rotation_difference(target)
            at=m.translation.copy();m=delta.to_matrix().to_4x4()@m;m.translation=at
        world[n]=m
    # Enforce leg reach before solving ankles. A lateral weight shift must
    # lower the pelvis as needed rather than extending/skipping a support foot.
    correction=0
    for side in ('L','R'):
        head=(world['pelvis']@rest['pelvis'].inverted()@by_name['thigh.'+side]['head'])
        goal=Vector(feet[0 if side=='R' else 1]) if feet else by_name['foot.'+side]['head']
        length=(by_name['thigh.'+side]['tail']-by_name['thigh.'+side]['head']).length+(by_name['shin.'+side]['tail']-by_name['shin.'+side]['head']).length-.001
        horizontal=(Vector((head.x,head.y))-Vector((goal.x,goal.y))).length
        limit=math.sqrt(max(.01,length*length-horizontal*horizontal))+goal.z
        correction=max(correction,head.z-limit)
    if correction>0:
        for n in names:
            if n!='root':world[n].translation.z-=correction
    for side,sign in (('L',1),('R',-1)):
        hand=near if side=='R' else far
        if hand is None:hand=(sign*.25,-.09,.96)
        goal=Vector(hand)+Vector((0,-advance,0))
        shoulder=world['clavicle.'+side]@rest['clavicle.'+side].inverted()@by_name['upper_arm.'+side]['head']
        pole=shoulder+Vector((sign*.22,.13,-.20))
        limb_pose(world,'upper_arm.'+side,'forearm.'+side,'hand.'+side,goal,pole)
        foot=Vector(feet[0 if side=='R' else 1]) if feet else by_name['foot.'+side]['head'].copy()
        limb_pose(world,'thigh.'+side,'shin.'+side,'foot.'+side,foot,world['pelvis'].translation+Vector((sign*.4,-.6,-.3)))
        # Feet remain level. Fingers share an anatomical palm frame with the
        # wrist and close at their individual phalange joints, not as a quad.
        world['foot.'+side]=rest['foot.'+side].copy();world['foot.'+side].translation=foot
        for finger in range(1,6):
            for segment in range(1,4):
                n=f'finger{finger}-{segment}.{side}';p=by_name[n]['parent']
                amount=curl*(.7 if finger==1 else 1)*(55 if segment==1 else 75 if segment==2 else 55)
                world[n]=world[p]@rest[p].inverted()@rest[n]@Matrix.Rotation(math.radians(amount*(-1 if side=='R' else 1)),4,'X')
    return world

capture={
 'strike':Motion(VENDOR/'02.asf',VENDOR/'02_05.amc'),
 'lift':Motion(VENDOR/'02.asf',VENDOR/'02_06.amc'),
 'throw':Motion(VENDOR/'124.asf',VENDOR/'124_12.amc'),
 'swing':Motion(VENDOR/'124.asf',VENDOR/'124_07.amc')}
peaks={n:m.peak() for n,m in capture.items()}
def captured_pose(which,progress,side='R'):
    motion=capture[which];peak=peaks[which]
    span=1.35 if which in ('strike','swing') else 1.45
    start=peak-int(.65*motion.fps)
    frame=motion.sample(start+progress*span*motion.fps)
    first=motion.sample(start)
    facing_reference=motion.sample(peak)
    lateral=(facing_reference['lclavicle'][0]-facing_reference['rclavicle'][0]);lateral.z=0;lateral.normalize()
    yaw=-math.atan2(lateral.y,lateral.x)
    facing=Matrix.Rotation(yaw,3,'Z')
    root=frame['root'][0]
    spine=frame['thorax'][1]
    scale=1.91/max(1.3,first['head'][0].z+.12)
    yaw_current=math.atan2((frame['lclavicle'][0]-frame['rclavicle'][0]).y,(frame['lclavicle'][0]-frame['rclavicle'][0]).x)+yaw
    m=base_pose(curl=.85)
    # Distribute spine orientation and measured torso yaw across three joints.
    spine_direction=facing@spine
    lean=math.degrees(math.atan2(-spine_direction.y,spine_direction.z))
    torso_yaw=max(-38,min(38,math.degrees(math.atan2(math.sin(yaw_current),math.cos(yaw_current)))))
    lean=max(-18,min(18,lean))
    hip_lateral=facing@(frame['lfemur_head']-frame['rfemur_head'])
    hip_yaw=max(-30,min(30,math.degrees(math.atan2(hip_lateral.y,hip_lateral.x))))
    torso_twist=max(-22,min(22,torso_yaw-hip_yaw))
    travel=facing@(root-first['root'][0])*scale
    shift=(max(-.07,min(.07,travel.x)),max(-.10,min(.10,travel.y)),0)
    near=facing@(frame['rhand'][0]-root)*scale+Vector((0,0,by_name['pelvis']['head'].z))
    far=facing@(frame['lhand'][0]-root)*scale+Vector((0,0,by_name['pelvis']['head'].z))
    # Fit captured reaches to the character's own connected limb lengths.
    # The actual elbow plane is used as the pole, retaining human articulation.
    m=base_pose(drop=max(0,min(.12,(first['root'][0].z-root.z)*scale)),yaw=hip_yaw,twist=torso_twist,shift=shift,lean=lean,near=near,far=far,curl=.9)
    for target_side,prefix in (('R','r'),('L','l')):
        goal=near if target_side=='R' else far
        pole=facing@(frame[prefix+'humerus'][0]-root)*scale+Vector((0,0,by_name['pelvis']['head'].z))
        limb_pose(m,'upper_arm.'+target_side,'forearm.'+target_side,'hand.'+target_side,goal,pole)
    return m

def mix_pose(a,b,u,knee_weight=0,retain_foot_rotation=False):
    u=max(0,min(1,u));u=u*u*(3-2*u)
    result={}
    for n in names:
        parent=by_name[n]['parent']
        al=a[parent].inverted()@a[n] if parent else a[n]
        bl=b[parent].inverted()@b[n] if parent else b[n]
        q=al.to_quaternion().slerp(bl.to_quaternion(),u)
        m=q.to_matrix().to_4x4();m.translation=al.translation.lerp(bl.translation,u)
        result[n]=result[parent]@m if parent else m
    # Replant the support ankles after angular blending. Local quaternion
    # interpolation preserves bone lengths but is not itself a foot constraint.
    for side in ('R','L'):
        foot=a['foot.'+side].translation.lerp(b['foot.'+side].translation,u)
        pole=leg_pole(result,side,knee_weight) if knee_weight else result['pelvis'].translation+Vector((.4 if side=='L' else -.4,-.6,-.3))
        limb_pose(result,'thigh.'+side,'shin.'+side,'foot.'+side,foot,pole)
        if retain_foot_rotation:
            rotation=a['foot.'+side].to_quaternion().slerp(b['foot.'+side].to_quaternion(),u)
            result['foot.'+side]=rotation.to_matrix().to_4x4()
        else:result['foot.'+side]=rest['foot.'+side].copy()
        result['foot.'+side].translation=foot
    return result

# Compose a gesture around real recorded motion and retain the relic contract.
# Melee root locomotion and ritual hand goals are fitted in 3D, not inherited
# from the former 2D cutout table.
DURATIONS={'idle':(3.2,-1),'iron_strike':(3.1,2.2),'twin_right':(3.1,2.2),'twin_left':(3.1,2.2),
 'heavy':(3.3,2.2),'throw':(1.7,.95),'piston':(2.2,.95),'siphon':(4.2,.95),
 'channel':(3.5,2.4),'chalice':(3.35,2.4),'bell':(3.8,2.5),'crown':(2.8,1.7),
 'block':(2.5,1.1),'hit':(.55,-1),'guard_hit':(.5,-1),'fall':(1.1,-1)}
def ease(x):
    x=max(0,min(1,x))
    return x*x*(3-2*x)

def orient_weapon_hand(world,side,blade_direction):
    hand=world['hand.'+side];x=Vector(blade_direction).normalized()*(-1 if side=='R' else 1)
    old_y=hand.col[1].xyz.normalized();y=old_y-x*old_y.dot(x)
    if y.length<.08:
        y=Vector((0,0,1))-x*x.z
    y.normalize();z=x.cross(y).normalized();y=z.cross(x).normalized()
    target=Matrix((x,y,z)).transposed().to_4x4();target.translation=hand.translation
    world['hand.'+side]=target

def support_weapon_hand(world,blade_direction):
    """Place the other palm on the same handle, retaining anatomical reach."""
    blade=Vector(blade_direction).normalized()
    palm=world['hand.R']@Vector((0,.065,-.022))
    support=palm-blade*.14
    shoulder=world['clavicle.L']@rest['clavicle.L'].inverted()@by_name['upper_arm.L']['head']
    goal=support.copy()
    for _ in range(5):
        limb_pose(world,'upper_arm.L','forearm.L','hand.L',goal,shoulder+Vector((.26,-.09,-.13)))
        orient_weapon_hand(world,'L',blade)
        offset=world['hand.L'].to_3x3()@Vector((0,.065,.022))
        goal=support-offset
    return world

stroke_cache={}

def leg_pole(world,side,weight=1):
    # Knees track forward over the corresponding toes. A far lateral pole made
    # both knees flare out during compression, even with a narrow support stance.
    hip=world['pelvis']@rest['pelvis'].inverted()@by_name['thigh.'+side]['head']
    natural=hip+Vector((.045 if side=='L' else -.045,-.62,-.30))
    resting=world['pelvis'].translation+Vector((.4 if side=='L' else -.4,-.6,-.3))
    return resting.lerp(natural,weight)

def launch_travel(u):
    # Integrate a smooth acceleration/deceleration ramp. Most of the flight
    # retains constant horizontal speed, with no one-frame start/stop in root
    # travel. Total displacement and takeoff/contact times remain unchanged.
    u=max(0,min(1,u));ramp=.15
    if u<ramp:
        x=u/ramp;return ramp*(x*x*x-.5*x*x*x*x)/(1-ramp)
    if u>1-ramp:return 1-launch_travel(1-u)
    return (u-ramp*.5)/(1-ramp)

def flowing_pose(keys,poses,index,t):
    """Time-aware cubic local motion, without stopping at every keyed pose.

    Quaternion components share a hemisphere before the cubic evaluation.
    Renormalization retains a rigid rotation; joint translations retain their
    anatomical offsets. Only the beginning/end of the stroke settle to rest.
    Support feet are constrained after interpolation, as in mix_pose.
    """
    times=[key[0] for key in keys];span=times[index+1]-times[index]
    u=max(0,min(1,(t-times[index])/span));u2=u*u;u3=u2*u
    h=(2*u3-3*u2+1,u3-2*u2+u,-2*u3+3*u2,u3-u2)
    result={}
    for n in names:
        parent=by_name[n]['parent']
        local=[pose[parent].inverted()@pose[n] if parent else pose[n] for pose in poses]
        rotations=[Vector(tuple(m.to_quaternion())) for m in local]
        for j in range(1,len(rotations)):
            if rotations[j].dot(rotations[j-1])<0:rotations[j]=-rotations[j]
        def tangent(values,j):
            if j in (0,len(values)-1):return values[j]*0
            before=(values[j]-values[j-1])/(times[j]-times[j-1])
            after=(values[j+1]-values[j])/(times[j+1]-times[j])
            return (before*(times[j+1]-times[j])+after*(times[j]-times[j-1]))/(times[j+1]-times[j-1])
        q=rotations[index]*h[0]+tangent(rotations,index)*(span*h[1])+rotations[index+1]*h[2]+tangent(rotations,index+1)*(span*h[3])
        m=Quaternion(tuple(q.normalized())).to_matrix().to_4x4()
        locations=[matrix.translation for matrix in local]
        if n=='pelvis':
            m.translation=locations[index]*h[0]+tangent(locations,index)*(span*h[1])+locations[index+1]*h[2]+tangent(locations,index+1)*(span*h[3])
        else:m.translation=locations[index].lerp(locations[index+1],u)
        result[n]=result[parent]@m if parent else m
    for side in ('R','L'):
        foot=poses[index]['foot.'+side].translation.lerp(poses[index+1]['foot.'+side].translation,u)
        knee_weight=ease((t-1.5)/.12)*(1-ease((t-(keys[-1][0]-.17))/.17))
        limb_pose(result,'thigh.'+side,'shin.'+side,'foot.'+side,foot,leg_pole(result,side,knee_weight))
        result['foot.'+side]=rest['foot.'+side].copy();result['foot.'+side].translation=foot
    return result

def weapon_stroke(name,t):
    """Weapon-specific keyed body mechanics, rather than a retimed punch.

    Hips lead the torso into the cut; the elbow plane lifts for the overhead
    chamber, then lowers through contact. Wrist rotation is an authored bounded
    channel, so a changing aim vector cannot spin it through a singularity.
    """
    heavy=name=='heavy';duration=DURATIONS[name][0]
    # time, hip/torso, hands, anatomical elbow pole, actual blade direction.
    # Last channels: pelvis weight shift and compression, before limb fitting.
    keys=[(1.5,0,0,0,(-.13 if heavy else -.18,-.22 if heavy else -.29,1.30 if heavy else 1.2),(.24,-.12,1.0),(-.22,.13,-.20),(0,0,1) if heavy else (-.34,-.12,1),(0,0,0),0),
          (1.82,-18,-8,-20,(-.28,.015 if heavy else -.045,1.83),(.25,-.22,1.26),(-.32,.10,.22),(0,.20,1),(-.025,.045,0),.025),
          (1.94,-4,0,-14,(-.22,-.14 if heavy else -.19,1.80),(.26,-.22,1.23),(-.28,.03,.18),(.20,-.10,1),(-.01,.015,0),.015),
          (2.02,5,9,0,(-.15,-.30 if heavy else -.39,1.67),(.27,-.18,1.18),(-.25,-.06,.18),(.42,-.42,.80),(0,-.025,0),.02),
          (2.2,18,18 if heavy else 15,12,(-.08 if heavy else -.12,-.36 if heavy else -.55,1.35 if heavy else 1.28),(.26,-.14,1.10),(-.10,-.22,-.12),(.781,-.625,.25),(.025,-.065,0),.04),
          (2.52 if heavy else 2.4,23,13,16,(.0,-.24,1.20),(.24,-.14,1.02),(-.28,-.35,-.30),(.25,-.30,-.92),(.02,-.045,0),.025),
          (2.79 if heavy else 2.62,7,5,4,(-.18,-.22,1.12),(.25,-.09,.99),(-.22,.13,-.20),None,(0,-.015,0),.01),
          (duration-.15,0,0,0,(-.25,-.09,.96),(.25,-.09,.96),(-.22,.13,-.20),None,(0,0,0),0)]
    def pose(key):
        _,yaw,lean,twist,near,far,pole,blade,shift,drop=key
        if heavy and blade is not None:far=Vector(near)-Vector(blade).normalized()*.14
        m=base_pose(yaw=yaw,lean=lean,twist=twist,near=near,far=far,curl=.9,shift=shift,drop=drop)
        shoulder=m['clavicle.R']@rest['clavicle.R'].inverted()@by_name['upper_arm.R']['head']
        limb_pose(m,'upper_arm.R','forearm.R','hand.R',near,shoulder+Vector(pole))
        if blade is not None:orient_weapon_hand(m,'R',blade)
        if heavy and blade is not None:support_weapon_hand(m,blade)
        return m
    if name not in stroke_cache:stroke_cache[name]=[pose(key) for key in keys]
    poses=stroke_cache[name]
    if t<=keys[0][0]:return {n:m.copy() for n,m in poses[0].items()}
    for index,(a,b) in enumerate(zip(keys,keys[1:])):
        if t<=b[0]:
            m=flowing_pose(keys,poses,index,t)
            if heavy and a[7] is not None and b[7] is not None:support_weapon_hand(m,-m['hand.R'].col[0].xyz)
            return m
    return base_pose()
def authored(name,t):
    duration,contact=DURATIONS[name]
    neutral=base_pose()
    if name=='idle':
        phase=t*math.tau/3.2;breath=1-math.cos(phase);sway=math.sin(phase)
        # A watchful, reserved swordsman: weight loads through the hips while
        # the chest counters it, one hand loosens and the gaze leads slightly.
        # Feet remain solved against their planted anchors. All periodic terms
        # return to the exact neutral endpoint, including their derivatives.
        settle=.5*breath
        pose=base_pose(drop=.004*breath,yaw=1.2*sway,lean=.55*sway+.35*breath,twist=-1.05*sway,
                      shift=(.007*sway,.003*sway,0),
                      near=(-.25-.006*settle,-.09-.012*settle,.96+.007*breath),
                      far=(.25+.003*settle,-.09+.004*settle,.96+.003*breath))
        pose['head']=pose['head']@Matrix.Rotation(math.radians(-1.6*sway),4,'Y')@Matrix.Rotation(math.radians(.65*settle),4,'X')
        return pose
    if name in ('throw','piston','siphon'):
        # Recorded maximum release speed lands on the existing 0.76 s marker.
        peak_progress=.65/1.45
        progress=t/.76*peak_progress if t<=.76 else peak_progress+(t-.76)/.44*(1-peak_progress)
        stroke=captured_pose('throw',max(0,min(1,progress)))
        if t<.23:return mix_pose(neutral,stroke,t/.23)
        if name=='siphon' and t>1.05:
            pulse=math.sin(math.tau*(t-1.4)/2.0)
            held=base_pose(drop=.012+.004*pulse,near=(-.16,-.44-.008*pulse,1.24+.006*pulse),
                           far=(.25,-.09,.99+.003*pulse),curl=.82,lean=2+.7*pulse,yaw=-1.2*pulse)
            if t<1.4:return mix_pose(stroke,held,(t-1.05)/.35)
            if t<3.4:return held
            return mix_pose(held,neutral,(t-3.4)/.8)
        if t>1.03:return mix_pose(stroke,neutral,(t-1.03)/(duration-1.03))
        return stroke
    if name in ('iron_strike','twin_right','twin_left','heavy'):
        active='L' if name=='twin_left' else 'R'
        # Keep the recognition hold alive without moving either support foot.
        breath=.0025*math.sin(math.tau*max(0,t-.4)/2.2)**2
        summon=base_pose(drop=breath,near=(-.18,-.29,1.2),far=(.24,-.12,1.0),curl=.9)
        if name=='heavy':summon=base_pose(drop=breath,near=(-.13,-.22,1.30),far=(-.13,-.22,1.16),curl=.9)
        if active=='L':summon=base_pose(drop=breath,near=(-.23,-.12,1.0),far=(.18,-.29,1.2),curl=.9)
        # A slight outward blade cant leaves the masked face readable during
        # the long recognition hold, before the hand lifts into the chamber.
        orient_weapon_hand(summon,active,(0,0,1) if name=='heavy' else (-.34 if active=='R' else .34,-.12,1))
        if name=='heavy':support_weapon_hand(summon,(0,0,1))
        if t<.4:return mix_pose(neutral,summon,t/.4)
        if t<1.5:return summon
        stroke=weapon_stroke(name,t)
        # Countermovement then a ballistic launch. Both ankles leave the
        # floor together; there is no sliding rear support foot mid-lunge.
        flight=max(0,min(1,(t-1.82)/.38))
        returning=max(0,min(1,(t-2.45)/.43))
        advance=.67*launch_travel(flight)
        if t>2.45:advance=.67*(1-launch_travel(returning))
        lift=9.81*.38*.38*.5*flight*(1-flight) if 1.82<t<2.2 else 9.81*.43*.43*.5*returning*(1-returning) if 2.45<t<2.88 else 0
        # Load the legs before extending into takeoff; compress again on
        # landing, then push away. Smooth tangents remove the old instantaneous
        # downward velocity at the start of the anticipation.
        crouch=0
        if 1.5<t<1.66:crouch=.105*ease((t-1.5)/.16)
        elif 1.66<=t<1.82:crouch=.105*(1-ease((t-1.66)/.16))
        if 1.82<t<2.2:crouch+=.032*math.sin(math.pi*flight)**2
        # Extend into takeoff, then compress over a staggered landing stance.
        # The stance opens in flight and stays planted until the return jump.
        if 1.82<t<2.2:crouch+=.08*ease((flight-.65)/.35)
        if 2.2<=t<2.31:crouch=.08+.035*ease((t-2.2)/.11)
        elif 2.31<=t<2.45:crouch=.115*(1-ease((t-2.31)/.14))
        if 2.45<t<2.88:crouch+=.045*math.sin(math.pi*returning)**2
        if t>2.88:
            settling=max(0,min(1,(t-2.88)/min(.24,duration-2.88)))
            crouch+=.030*math.sin(math.pi*settling)**2
        for n in names:
            stroke[n].translation.y-=advance
            stroke[n].translation.z+=lift-(crouch if n!='root' else 0)
        if active=='L':
            # Mirror deformation deltas into the opposite anatomical rest
            # basis, including clavicles and torso. Reflecting only the hands
            # would detach an upper arm from its unchanged shoulder socket.
            old={n:m.copy() for n,m in stroke.items()};reflection=Matrix.Diagonal((-1,1,1,1))
            for n in names:
                opposite=n[:-1]+('L' if n[-1]=='R' else 'R') if n.endswith(('.L','.R')) else n
                delta=old[opposite]@rest[opposite].inverted()
                stroke[n]=reflection@delta@reflection@rest[n]
            # Hand bones have opposite anatomical frames. Both equipped
            # blades must follow the same cut direction after mirroring.
            anatomical_hand=stroke['hand.L'].copy()
            orient_weapon_hand(stroke,'L',-old['hand.R'].col[0].xyz)
            release=2.52 if name=='heavy' else 2.4
            recovery=max(0,min(1,(t-release)/(duration-.15-release)))
            if recovery>0:
                q=stroke['hand.L'].to_quaternion().slerp(anatomical_hand.to_quaternion(),recovery)
                stroke['hand.L']=q.to_matrix().to_4x4()
                stroke['hand.L'].translation=anatomical_hand.translation
        # Mirroring an arm stroke must not reverse the knee's bend plane.
        for side in ('R','L'):
            goal=by_name['foot.'+side]['head'].copy()
            stance=ease(flight)*(1-ease(returning))
            goal.y-=advance+(.135 if side==active else -.105)*stance
            goal.z+=lift
            # The lead leg reaches for the landing while the trailing knee
            # folds under the hips. Distinct leg arcs avoid a paired-foot hop.
            if 1.82<t<2.2:goal.z+=(.045 if side==active else .105)*math.sin(math.pi*flight)**2
            if 2.45<t<2.88:goal.z+=(.075 if side==active else .035)*math.sin(math.pi*returning)**2
            knee_weight=ease((t-1.5)/.12)*(1-ease((t-(duration-.32))/.17))
            limb_pose(stroke,'thigh.'+side,'shin.'+side,'foot.'+side,goal,leg_pole(stroke,side,knee_weight))
            stroke['foot.'+side]=rest['foot.'+side].copy();stroke['foot.'+side].translation=goal
            pitch=math.radians(10 if side==active else 24)*math.sin(math.pi*flight)**2 if 1.82<t<2.2 else math.radians(20 if side==active else 10)*math.sin(math.pi*returning)**2 if 2.45<t<2.88 else 0
            foot=stroke['foot.'+side]
            rotated=Matrix.Rotation(pitch,4,'X')@foot;rotated.translation=goal
            stroke['foot.'+side]=rotated
        # Palm orientation is authored with the cut before root locomotion.
        return stroke
    if name in ('channel','chalice','bell','crown','block'):
        # Distinct sustained body performances under each relic's readable VFX.
        # Small breathing/weight shifts retain planted feet and active palms.
        near,far,drop,yaw,lean,twist,curl={
            'channel':((-.17,-.31,1.27),(.23,-.24,1.18),.018,-3,-3,2,.12),
            'chalice':((-.20,-.20,1.13),(.22,-.20,1.08),.012,-2,-5,0,.22),
            'bell':((-.17,-.28,1.22),(.22,-.25,1.17),.022,-4,-2,3,.16),
            'crown':((-.20,-.21,1.10),(.23,-.17,1.04),.012,-3,-3,-2,.28),
            'block':((-.15,-.35,1.38),(.20,-.31,1.30),.045,-7,2,5,.7)}[name]
        phase=math.tau*(t-.8)/3.2;breath=math.sin(phase);weight=math.sin(phase*.5)
        near=Vector(near)+Vector((0,-.005*breath,.005*breath))
        far=Vector(far)+Vector((0,-.003*breath,.004*breath))
        gesture=base_pose(drop=drop+.004*breath,yaw=yaw+.8*weight,lean=lean+.6*breath,
                          twist=twist-.5*weight,shift=(.005*weight,-.003*breath,0),
                          near=near,far=far,curl=curl)
        if t<.8:return mix_pose(neutral,gesture,t/.8)
        recovery={'channel':2.8,'chalice':2.7,'bell':2.85,'crown':1.95,'block':1.4}[name]
        if t>recovery:return mix_pose(gesture,neutral,(t-recovery)/(duration-recovery))
        return gesture
    if name in ('hit','guard_hit'):
        strength=math.sin(math.pi*max(0,min(1,t/duration)))
        return base_pose(drop=.035*strength,yaw=-4*strength,lean=-6*strength,curl=.4)
    if name=='fall':return base_pose(drop=.35*min(1,t/duration),lean=36*min(1,t/duration),curl=.1)
    return neutral

from executioner_tailored_wardrobe import dress
dress(globals())

conversion=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))
animation={};motion_manifest={}
rig.animation_data_create()
for action_name,(duration,contact) in DURATIONS.items():
    action=bpy.data.actions.new(action_name);action.use_fake_user=True;rig.animation_data.action=action
    frames=[];world_frames=[];previous_rotations={}
    cloth_state={};previous_pelvis=None;previous_velocity=Vector()
    for i in range(round(duration*FPS)+1):
        t=i/FPS;world=authored(action_name,t)
        # Recompute phalange FK AFTER retargeting the wrist. A recorded arm
        # stroke must not leave its children at the previous authored pose.
        grip=.88 if action_name in ('iron_strike','twin_right','twin_left','heavy','throw','piston','siphon') else .18
        if action_name=='idle':grip+=.025*(1-math.cos(math.tau*t/3.2))
        if action_name in ('channel','chalice','bell','crown','block'):
            recovery={'channel':2.8,'chalice':2.7,'bell':2.85,'crown':1.95,'block':1.4}[action_name]
            target={'channel':.12,'chalice':.22,'bell':.16,'crown':.28,'block':.7}[action_name]
            grip=.18+(target-.18)*ease(t/.8)*(1-ease((t-recovery)/(duration-recovery)))
        if action_name in ('iron_strike','twin_right','twin_left','heavy'):
            relax=max(0,min(1,(t-(duration-.35))/.25))
            relax=relax*relax*(3-2*relax)
            grip=.88-.70*relax
        if action_name in ('throw','piston'):
            opened=max(0,min(1,(t-.68)/.10));opened=opened*opened*(3-2*opened)
            closed=max(0,min(1,(t-1.03)/.25));closed=closed*closed*(3-2*closed)
            grip=.88-.76*opened*(1-closed)
        for b in BONES:
            n=b['name'];p=b['parent']
            if '_twist.' in n:
                world[n]=world[p]@rest[p].inverted()@rest[n]
            if n.startswith('finger'):
                segment=int(n.split('-')[1].split('.')[0]);finger=int(n[6])
                amount=grip*(.65 if finger==1 else 1)*(55 if segment==1 else 75 if segment==2 else 55)
                world[n]=world[p]@rest[p].inverted()@rest[n]@Matrix.Rotation(math.radians(amount*(-1 if n.endswith('.R') else 1)),4,'X')
        # Damped cloth lag responds to actual body acceleration and settles
        # after landings. It cannot move the torso, limbs or contact timing.
        pelvis=world['pelvis'].translation.copy()
        velocity=(pelvis-previous_pelvis)*FPS if previous_pelvis is not None else Vector()
        acceleration=(velocity-previous_velocity)*FPS
        previous_pelvis=pelvis;previous_velocity=velocity
        for b in BONES:
            n=b['name'];p=b['parent']
            if n.startswith('cloak_') or n.startswith('skirt.'):
                local=rest[p].inverted()@rest[n]
                column=int(n[-1]) if n[-1].isdigit() else 1
                lower=n.startswith('cloak_lower')
                # The free hem trails the shoulder-supported fabric. Keep the
                # neck/hip attachments firm while allowing the lower cloak
                # to carry momentum through takeoff and landing.
                stiffness=46 if lower else 95
                damping=11 if lower else 17
                angle,speed=cloth_state.get(n,(0.0,0.0))
                forcing=-max(-22,min(22,acceleration.y))*(.14 if lower else .055)
                forcing-=max(-3,min(3,velocity.y))*(3.4 if lower else 1.4)
                speed+=(forcing-stiffness*angle-damping*speed)/FPS
                limit=.25 if lower else .16
                angle=max(-limit,min(limit,angle+speed/FPS))
                cloth_state[n]=(angle,speed)
                # Looping idle uses a seamless, much smaller breathing sway.
                if action_name=='idle':angle=(.024 if lower else .007)*math.sin(math.tau*t/3.2+column*.35-(.60 if lower else 0))
                world[n]=world[p]@local@Matrix.Rotation(angle,4,'X')
        # Retargeted elbow planes can become singular near full extension.
        # Filter local upper-body rotations, then rebuild connected FK. This
        # damps capture noise and bounds axial turns without blending world
        # positions or changing limb lengths. Lower-body IK stays planted.
        filtered={}
        for b in BONES:
            n=b['name'];p=b['parent'];local=world[p].inverted()@world[n] if p else world[n]
            rotation=local.to_quaternion()
            # Analytic periodic idle already has smooth derivatives. A causal
            # capture filter starts cold and leaves its last pose behind its
            # first pose, producing a visible hitch every loop.
            if action_name!='idle' and n not in ('root','pelvis') and not n.startswith(('thigh.','shin.','foot.')):
                if n in previous_rotations:
                    prior=previous_rotations[n]
                    rotation=prior.slerp(rotation,1-math.exp(-1/(FPS*.04)))
                    angle=prior.rotation_difference(rotation).angle
                    if angle>math.pi:angle=math.tau-angle
                    maximum=math.radians(9)
                    if angle>maximum:rotation=prior.slerp(rotation,maximum/angle)
                previous_rotations[n]=rotation.copy()
                smoothed=rotation.to_matrix().to_4x4();smoothed.translation=local.translation;local=smoothed
            filtered[n]=filtered[p]@local if p else local
        world=filtered
        # A two-handed grip is a positional constraint, not a rotation filter.
        # Apply it after smoothing so torso/shoulder lag cannot detach the palm.
        # Rebuild twist/finger descendants in the corrected anatomical frames.
        if action_name=='heavy' and t<2.79:
            before={n:m.copy() for n,m in world.items()}
            support_weapon_hand(world,-world['hand.R'].col[0].xyz)
            changed={'upper_arm.L','forearm.L','hand.L'}
            for b in BONES:
                n=b['name'];p=b['parent']
                if n not in changed and p in changed:
                    world[n]=world[p]@before[p].inverted()@before[n]
                    changed.add(n)
            # Acquire/release the handle continuously instead of switching the
            # IK constraint on/off in one frame. Full contact is held .4–2.52s.
            weight=ease(t/.4)*(1-ease((t-2.52)/.27))
            if weight<1:
                knee_weight=ease((t-1.5)/.12)*(1-ease((t-(duration-.32))/.17))
                world=mix_pose(before,world,weight,knee_weight=knee_weight,retain_foot_rotation=True)
        frame=[];world_frame={}
        for b in BONES:
            n=b['name'];p=b['parent'];local=world[p].inverted()@world[n] if p else world[n]
            rest_local=rest[p].inverted()@rest[n] if p else rest[n]
            pose=rest_local.inverted()@local
            pb=rig.pose.bones[n];pb.rotation_mode='QUATERNION';pb.matrix_basis=pose
            pb.keyframe_insert('rotation_quaternion',frame=i+1,group=n);pb.keyframe_insert('location',frame=i+1,group=n)
            # glTF converts the skeleton's root space once. Child transforms
            # remain in their parent's anatomical bone basis, not scene axes.
            godot=local if p else conversion@local;q=godot.to_quaternion();v=godot.translation
            frame.append([round(v.x,7),round(v.y,7),round(v.z,7),round(q.x,8),round(q.y,8),round(q.z,8),round(q.w,8)])
            if n in ('hand.R','hand.L','head','spine_upper','foot.R','foot.L'):
                at=conversion@world[n].translation;world_frame[n]=[round(v,7) for v in at]
        frames.append(frame);world_frames.append(world_frame)
    # Dense samples are interpolated linearly/spherically, with no Euler flips.
    for layer in action.layers:
        for strip in layer.strips:
            for slot in action.slots:
                bag=strip.channelbag(slot)
                if bag:
                    for curve in bag.fcurves:
                        for k in curve.keyframe_points:k.interpolation='LINEAR'
    animation[action_name]={'duration':duration,'contact':contact,'frames':frames,'anchors':world_frames}
    motion_manifest[action_name]={'duration':duration,'contact':contact,'source':'Authored weapon-specific full-body mechanics' if action_name in ('iron_strike','twin_right','twin_left','heavy') else 'CMU recorded throw + 3D fitting' if action_name in ('throw','piston','siphon') else 'authored 3D anatomical gesture'}

rest_records=[]
for b in BONES:
    n=b['name'];p=b['parent'];local=rest[p].inverted()@rest[n] if p else rest[n]
    godot=local if p else conversion@local;q=godot.to_quaternion();v=godot.translation
    rest_records.append({'name':n,'parent':p,'rest':[v.x,v.y,v.z,q.x,q.y,q.z,q.w],'length':(b['tail']-b['head']).length})
record={'fps':FPS,'native_time_origin':1/FPS,'format':'overkill_human_3d_v1','height':1.91,'bones':rest_records,'actions':animation}
(OUT/'motion_data.gd').write_text('extends RefCounted\n# Blender-authored 3D joint samples, quaternion rotation.\nconst DATA: Dictionary = '+json.dumps(record,separators=(',',':'))+'\n')
(SRC/'motion_manifest.json').write_text(json.dumps({'bones':len(BONES),'meshes':len(model_objects),'actions':motion_manifest,'capture_peaks':peaks,'body_vertices':len(used)},indent=2))
rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(1)
for obj in model_objects:
    assert sum(m.type=='ARMATURE' for m in obj.modifiers)==1,('Lost 3D skin modifier',obj.name)
scene.frame_start=1;scene.frame_end=round(3.2*FPS)+1
scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=900;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
world=bpy.data.worlds.new('Studio environment');scene.world=world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.075,.092,.11,1)
def light(name,at,color,power,size):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.color=color;data.shape='DISK';data.size=size
    obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location=at;obj.rotation_euler=(Vector((0,0,1))-obj.location).to_track_quat('-Z','Y').to_euler()
light('Large warm key',(3,-4,4.5),(1,.78,.56),650,4)
light('Cyan fill',(-3,-1,2.8),(.27,.64,1),400,3)
light('Cool rim',(1,3,3.5),(.6,.79,1),700,3)
camera_data=bpy.data.cameras.new('Anatomy and armor review');camera=bpy.data.objects.new('Anatomy and armor review',camera_data);scene.collection.objects.link(camera)
camera.location=(3,-5,2.3);camera.rotation_euler=(Vector((0,0,1))-camera.location).to_track_quat('-Z','Y').to_euler();camera_data.type='ORTHO';camera_data.ortho_scale=2.55;scene.camera=camera
from executioner_controls import add_controls
add_controls(rig,BONES)
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'executioner_human_3d.blend'))
# Keep the saved source componentized for editing. The playable skin shares
# materials and a skeleton, so combine wardrobe sections only for export.
# This removes repeated skin bindings and draws without changing geometry,
# UVs, normalized weights, bone transforms or source controls.
source_mesh_count=len(model_objects)
wardrobe=[obj for obj in model_objects if obj!=human]
bpy.ops.object.select_all(action='DESELECT')
for obj in wardrobe:obj.select_set(True)
bpy.context.view_layer.objects.active=wardrobe[0]
bpy.ops.object.join()
runtime_wardrobe=bpy.context.view_layer.objects.active
runtime_wardrobe.name='Executioner sectional wardrobe'
runtime_models=[human,runtime_wardrobe]
manifest=json.loads((SRC/'motion_manifest.json').read_text())
manifest['runtime_meshes']=len(runtime_models)
(SRC/'motion_manifest.json').write_text(json.dumps(manifest,indent=2))
# glTF includes real skinned volume, packed material maps and all bone actions.
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for obj in runtime_models:obj.select_set(True)
bpy.context.view_layer.objects.active=rig
props=bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
options={'filepath':str(OUT/'executioner.glb'),'export_format':'GLB','use_selection':True,'export_yup':True,'export_animations':True,'export_skins':True,'export_apply':False}
if 'export_animation_mode' in props:options['export_animation_mode']='ACTIONS'
if 'export_force_sampling' in props:options['export_force_sampling']=True
bpy.ops.export_scene.gltf(**options)
if '--render-review' in sys.argv:
    scene.render.filepath=str(SRC/'executioner_studio.png');bpy.ops.render.render(write_still=True)
print('EXECUTIONER_3D_BUILD_OK bones=%d anatomy_vertices=%d source_meshes=%d runtime_meshes=%d actions=%d'%(len(BONES),len(used),source_mesh_count,len(runtime_models),len(animation)))
