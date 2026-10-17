"""Model the complete relic catalog as weighted 3D geometry in Blender.

The former canonical artwork remains UI art. Battle props are now physical
meshes, not textured cards. All 29 have named collections, a six-joint rig,
editable actions and a native glTF export. Numerical battle outcomes stay in
the controller. Action timing is read from the established Blender tracks.
"""
from pathlib import Path
import bpy,json,math,random,sys
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
from relic_reference_models import build_relic
OUT=ROOT/'assets/animations/relics/three_d';SRC=OUT/'source'
SRC.mkdir(parents=True,exist_ok=True);(SRC/'.gdignore').write_text('')
random.seed(47048)
replace_hammer='--replace-hammer' in sys.argv
replacement_ids=({'REL-03'} if replace_hammer else set())|({'REL-01','REL-02'} if '--replace-weapons' in sys.argv else set())
targeted=bool(replacement_ids)
if targeted:
    bpy.ops.wm.open_mainfile(filepath=str(SRC/'relics_3d.blend'))
    for obj in list(bpy.data.objects):
        if obj.type=='MESH' and any(obj.name.startswith(n.replace('-','_')+'__') for n in replacement_ids):bpy.data.objects.remove(obj,do_unlink=True)
else:
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.fps=60
if targeted:
    rig=bpy.data.objects['RelicRig3D']
else:
    data=bpy.data.armatures.new('RelicSixJointRig');rig=bpy.data.objects.new('RelicRig3D',data);scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    for n in ('root','prop','secondary','flow','aura','tether'):
        b=data.edit_bones.new(n);b.head=(0,0,0);b.tail=(0,0,.1);b.align_roll(Vector((0,-1,0)))
        if n!='root':b.parent=data.edit_bones['root']
    bpy.ops.object.mode_set(mode='OBJECT');rig.show_in_front=True
def material(n,c,m=.7,r=.42,e=0):
    mat=bpy.data.materials.new(n);mat.use_nodes=True;p=mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=m;p.inputs['Roughness'].default_value=r
    p.inputs['Emission Color'].default_value=(*c,1);p.inputs['Emission Strength'].default_value=e
    return mat
bronze=material('Relic antique bronze',(.38,.22,.073),.8,.36)
edge=material('Relic polished gold',(.62,.40,.14),.8,.27)
steel=material('Relic forged steel',(.19,.23,.27),.86,.3)
leather=material('Relic black grip',(.023,.025,.031),.05,.78)
purple=material('Relic violet energy',(.25,.015,.56),.3,.22,1.8)
blue=material('Relic defense energy',(.015,.27,.63),.2,.3,1.8)
red=material('Relic blood glass',(.38,.014,.031),.3,.23,.8)
green=material('Relic life energy',(.08,.54,.04),.15,.25,1.8)
current='REL_01'
models=[obj for obj in bpy.data.objects if obj.type=='MESH'] if targeted else []
catalog=json.loads((SRC/'catalog.json').read_text()) if targeted else {}
def bind(obj,bone,mat):
    obj.name=current+'__'+bone+'__'+obj.name
    if mat:obj.data.materials.append(mat)
    obj.vertex_groups.new(name=bone).add(list(range(len(obj.data.vertices))),1,'REPLACE')
    obj.modifiers.new('Real relic joint attachment','ARMATURE').object=rig
    obj.parent=rig
    obj.select_set(False)
    for p in obj.data.polygons:p.use_smooth=True
    models.append(obj);return obj
def mesh(name,v,f,bone,mat):
    data=bpy.data.meshes.new(name);data.from_pydata(v,[],f);data.update()
    obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);return bind(obj,bone,mat)
def cylinder(name,at,r,d,bone,mat,axis=(0,0,1)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=r,depth=d,location=at)
    o=bpy.context.object;o.name=name;o.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);return bind(o,bone,mat)
def cube(name,at,size,bone,mat,bevel=.012):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.scale=size
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    b=o.modifiers.new('Forged edge radius','BEVEL');b.width=bevel;b.segments=3;bpy.ops.object.modifier_apply(modifier=b.name)
    return bind(o,bone,mat)
def sphere(name,at,size,bone,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=at);o=bpy.context.object;o.name=name;o.scale=size
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);return bind(o,bone,mat)
def lathe(name,profile,bone,mat):
    points=[];n=40
    for z,r in profile:
        for i in range(n):a=i*math.tau/n;points.append((r*math.cos(a),r*math.sin(a),z))
    faces=[(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for j in range(len(profile)-1) for i in range(n)]
    return mesh(name,points,faces,bone,mat)
def ring(name,at,major,minor,bone,mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=40,minor_segments=8,location=at)
    o=bpy.context.object;o.name=name;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);return bind(o,bone,mat)
def sword(bone):
    cylinder('Leather hilt',(0,0,-.024),.016,.165,bone,leather)
    sphere('Pommel',(0,0,-.12),(.025,.021,.028),bone,bronze)
    cube('Guard',(0,0,.075),(.205,.026,.03),bone,bronze,.008)
    outline=[(-.038,.095),(.038,.095),(.035,.55),(.017,.67),(0,.74),(-.017,.67),(-.035,.55)]
    vertices=[]
    for y in (-.009,.009):vertices += [(x,y,z) for x,z in outline]
    faces=[tuple(range(7)),tuple(range(7,14))]+[(i,(i+1)%7,(i+1)%7+7,i+7) for i in range(7)]
    mesh('Tempered blade',vertices,faces,bone,steel)
    cube('Raised blade fuller',(0,-.01,.355),(.007,.005,.44),bone,edge,.001)
    for z in (.14,.24,.34,.44,.54):cube('Cyan etched rune',(0,-.013,z),(.014,.004,.01),bone,blue,.001)
def crown():
    lathe('Crown ring',[(-.025,.135),(.022,.135),(.023,.126),(-.025,.126),(-.025,.135)],'prop',bronze)
    for i in range(8):
        a=i*math.tau/8
        x,y=.131*math.cos(a),.131*math.sin(a)
        mesh('Crown tine',[(x-.018,y,-.01),(x+.018,y,-.01),(x,y,.105)],[(0,1,2)],'prop',edge)
        sphere('Violet crown jewel',(x,y,.017),(.012,.012,.025),'prop',purple)
def chalice():
    lathe('Chalice volume',[(-.18,.002),(-.18,.075),(-.167,.077),(-.146,.026),(-.06,.024),(-.041,.036),(0,.075),(.08,.10),(.115,.108),(.118,.098),(.08,.091),(0,.063),(-.023,.031)],'prop',bronze)
    ring('Chalice rim',(0,0,.115),.104,.006,'prop',edge)
    cylinder('Visible violet liquid',(0,0,.075),.083,.008,'prop',purple)
    for i in range(8):
        a=i*math.tau/8;sphere('Chalice inset jewel',(.076*math.cos(a),.076*math.sin(a),.002),(.007,.007,.015),'prop',purple)
def bell():
    lathe('Bell swinging shell',[(.01,.024),(-.06,.081),(-.2,.126),(-.3,.205),(-.33,.219),(-.352,.206),(-.345,.187),(-.3,.179),(-.2,.104),(-.06,.062),(.01,.017)],'prop',bronze)
    ring('Bell rim',(0,0,-.334),.204,.012,'prop',edge)
    cylinder('Clapper pendulum',(0,0,-.19),.016,.33,'secondary',steel)
    sphere('Clapper weight',(0,0,-.345),(.045,.045,.048),'secondary',steel)
    cube('Bell independent yoke',(0,0,.065),(.40,.055,.055),'root',bronze)
    for x in (-.17,.17):cylinder('Yoke mount',(x,0,.028),.016,.084,'root',edge)
    for i in range(12):
        a=i*math.tau/12;sphere('Defense rune',(.147*math.cos(a),.147*math.sin(a),-.244),(.008,.008,.025),'prop',blue)
def piston():
    cylinder('Piston barrel',(0,0,0),.06,.19,'prop',bronze)
    cylinder('Exposed piston rod',(0,0,.145),.026,.12,'prop',steel)
    cylinder('Impact cap',(0,0,.22),.073,.036,'prop',steel)
    for z in (-.075,.015,.075):ring('Piston rib',(0,0,z),.061,.007,'prop',edge)
    for i in range(5):
        a=i*math.tau/5;cylinder('Violet pressure chamber',(.055*math.cos(a),.055*math.sin(a),-.025),.009,.11,'prop',purple)
def hammer():
    cylinder('Hammer leather handle',(0,0,.16),.024,.53,'prop',leather)
    cylinder('Hammer shaft',(0,0,.23),.031,.49,'prop',bronze)
    cube('Heavy forged hammer head',(0,0,.53),(.34,.16,.18),'prop',steel,.018)
    for x in (-.165,.165):cube('Hammer striking face',(x,0,.53),(.028,.18,.20),'prop',bronze,.009)
    cube('Hammer luminous core',(0,-.083,.53),(.12,.008,.06),'prop',purple,.003)
def shard():
    points=[(-.048,-.025,-.12),(.048,-.025,-.12),(.048,.025,-.12),(-.048,.025,-.12),(0,0,.23)]
    mesh('Forged piercing shard',points,[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(0,3,2,1)],'prop',steel)
    ring('Shard collar',(0,0,-.1),.044,.007,'prop',bronze)
def guard():
    cube('Defense mechanism',(0,0,0),(.22,.075,.25),'prop',bronze,.027)
    sphere('Blue shield core',(0,-.055,0),(.07,.025,.07),'prop',blue)
def siphon():
    cylinder('Barbed siphon head',(0,0,.03),.041,.2,'prop',bronze)
    cylinder('Life glass chamber',(0,0,-.05),.031,.1,'prop',purple)
    mesh('Embedded harpoon point',[(.027,0,.12),(-.027,0,.12),(0,.027,.12),(0,0,.27)],[(0,1,3),(1,2,3),(2,0,3)],'prop',steel)
    for sign in (-1,1):mesh('Backward barb',[(0,0,.16),(sign*.08,0,.08),(sign*.017,0,.11)],[(0,1,2)],'prop',steel)
    ring('Conduit socket',(0,0,-.095),.041,.009,'prop',purple)
def device(kind):
    if kind in ('needle','leech'):shard();return
    if kind in ('guard','thorns','wall','ward','battery','reservoir'):guard();return
    if kind in ('prism','wedge'):
        shard();sphere('Violet prism core',(0,0,.01),(.06,.05,.11),'prop',purple);return
    if kind in ('censer','oil','tithe'):
        sphere('Relic vessel',(0,0,0),(.1,.09,.13),'prop',bronze)
        ring('Vessel lip',(0,0,.09),.07,.008,'prop',edge)
        cylinder('Visible liquid',(0,0,.09),.055,.01,'prop',red if kind=='tithe' else green);return
    if kind=='spring':
        points=[]
        for i in range(180):a=i/179*math.tau*6;points.append((.06*math.cos(a),.06*math.sin(a),-.12+i/179*.24))
        for i in range(0,179,4):cylinder('Spring coil',points[i],.008,(Vector(points[min(i+4,179)])-Vector(points[i])).length,'prop',steel,Vector(points[min(i+4,179)])-Vector(points[i]))
        return
    sphere('Relic kinetic core',(0,0,0),(.10,.07,.13),'prop',bronze)
    ring('Kinetic energy ring',(0,0,.035),.104,.01,'prop',purple)

tracks_text=(ROOT/'assets/animations/relics/relic_tracks.gd').read_text()
tracks=json.loads(tracks_text.split('const DATA: Dictionary = ',1)[1])
for relic_id,clip in tracks['clips'].items():
    if targeted and relic_id not in replacement_ids:continue
    current=relic_id.replace('-','_');start=len(models);kind=clip['model']
    build_relic(ROOT,relic_id,kind,bind)
    catalog[relic_id]={'kind':kind,'meshes':len(models)-start,'rig':6,'grip':'origin','actor_action':clip['actor_action']}

# Keep source animation actions with the same timeline; glTF is exported at
# rest so Godot can drive bones from the unchanged real-time track controller.
rig.animation_data_create()
for relic_id,clip in tracks['clips'].items():
    if targeted:continue
    action=bpy.data.actions.new(relic_id);action.use_fake_user=True;rig.animation_data.action=action
    for name in ('root','prop','secondary','flow','aura','tether'):
        pb=rig.pose.bones[name];pb.rotation_mode='XYZ'
        samples=clip['tracks'].get(name,[[0,0,0,1,1,1]]*(round(clip['duration']*60)+1))
        for i,s in enumerate(samples):
            pb.location=(s[0]/225,-s[1]/225,0);pb.rotation_euler=(0,0,-s[2]);pb.scale=(s[3],s[4],1)
            pb.keyframe_insert('location',frame=i+1,group=name);pb.keyframe_insert('rotation_euler',frame=i+1,group=name);pb.keyframe_insert('scale',frame=i+1,group=name)
    action['contact_seconds']=clip['contact'];action['duration_seconds']=clip['duration']
rig.animation_data.action=None
for p in rig.pose.bones:p.location=(0,0,0);p.rotation_euler=(0,0,0);p.scale=(1,1,1)
scene.frame_start=1;scene.frame_end=max(round(c['duration']*60)+1 for c in tracks['clips'].values())
(SRC/'catalog.json').write_text(json.dumps(catalog,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'relics_3d.blend'))
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for obj in models:obj.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(OUT/'relics.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_skins=True,export_apply=False)
print('RELICS_3D_BUILD_OK catalog=%d bones=6 volume_meshes=%d actions=%d'%(len(catalog),len(models),len(tracks['clips'])))
