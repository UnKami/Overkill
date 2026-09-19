"""Hollow Custodian mask/neck study. Original geometry; shared skeleton only.
Blender --background executioner-production.blend --python this script.
Not connected to gameplay. Retains only the reference idle animation.
"""
import bpy,bmesh,math
from pathlib import Path
from mathutils import Vector
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
rig.data.pose_position='REST'
for o in list(bpy.data.objects):
 if o!=rig:bpy.data.objects.remove(o,do_unlink=True)
materials={};parts=[]
for name,color,metal,rough in [('Iron',(.115,.145,.155,1),.82,.48),('Bronze',(.24,.16,.07,1),.75,.55),('Recess',(.008,.011,.014,1),.1,.94),('Amber',(.85,.35,.025,1),.1,.3)]:
 m=bpy.data.materials.new('Custodian_'+name);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=color;bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
 if name=='Amber':bs.inputs['Emission Color'].default_value=color;bs.inputs['Emission Strength'].default_value=1.5
 materials[name]=m

def xyz(x,h,d):return Vector((x,-d,h))
def bind(o,bone,mat,bevel=.002):
 bpy.context.view_layer.objects.active=o;o.select_set(True)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
 o.data.materials.clear();o.data.materials.append(materials[mat])
 if bevel:
  mod=o.modifiers.new('Forged edge','BEVEL');mod.width=bevel;mod.segments=3;bpy.ops.object.modifier_apply(modifier=mod.name)
 for p in o.data.polygons:p.use_smooth=True
 mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 o.vertex_groups.new(name=bone).add(list(range(len(o.data.vertices))),1,'REPLACE')
 parts.append(o);o.select_set(False)
 return o

def rod(name,a,b,r1,r2,bone,mat):
 a=Vector(a);b=Vector(b);v=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=16,radius1=r1,radius2=r2,depth=v.length,location=(a+b)/2)
 o=bpy.context.object;o.name=name;o.rotation_euler=v.to_track_quat('Z','Y').to_euler()
 return bind(o,bone,mat)
def box(name,at,size,bone,mat,bevel=.003):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.scale=size
 return bind(o,bone,mat,bevel)

# Lofted closed helmet, with a real opening at the central front visor.
rows=[(1.765,.027,.052),(1.80,.071,.085),(1.85,.099,.111),(1.89,.111,.126),(2.005,.11,.124),(2.045,.085,.095),(2.073,.044,.048),(2.08,.012,.015)]
control_rows=rows;rows=[]
for i in range(len(control_rows)-1):
 a=control_rows[max(0,i-1)];b=control_rows[i];c=control_rows[i+1];d=control_rows[min(len(control_rows)-1,i+2)]
 for step in range(4):
  t=step/4
  values=[b[0]+(c[0]-b[0])*t]
  for axis in [1,2]:values.append(.5*((2*b[axis])+(-a[axis]+c[axis])*t+(2*a[axis]-5*b[axis]+4*c[axis]-d[axis])*t*t+(-a[axis]+3*b[axis]-3*c[axis]+d[axis])*t*t*t))
  rows.append(tuple(values))
rows.append(control_rows[-1])
segments=64;verts=[];faces=[]
for h,w,d in rows:
 for i in range(segments):
  phi=i*math.tau/segments
  verts.append(xyz(math.sin(phi)*w,h,-math.cos(phi)*d))
for row in range(len(rows)-1):
 for i in range(segments):
  if 12<=row<16 and i in [0,63]:continue
  a=row*segments+i;b=row*segments+(i+1)%segments
  faces.append((a,b,b+segments,a+segments))
faces.extend([tuple(reversed(range(segments))),tuple(range((len(rows)-1)*segments,len(rows)*segments))])
mesh=bpy.data.meshes.new('Visor shell');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('Hollow mask with open slit',mesh);bpy.context.collection.objects.link(o)
bpy.context.view_layer.objects.active=o;o.select_set(True)
solid=o.modifiers.new('Mask wall','SOLIDIFY');solid.thickness=.004;bpy.ops.object.modifier_apply(modifier=solid.name)
bind(o,'head','Iron',.001)
box('Visor dark socket',xyz(0,1.947,-.111),(.032,.019,.145),'head','Recess',.006)
box('Recessed amber lens',xyz(0,1.947,-.120),(.010,.008,.103),'head','Amber',.003)
# Anatomical neck mechanism remains visible beneath the sealed mask.
rod('Neck core',xyz(0,1.60,0),xyz(0,1.83,0),.036,.029,'neck','Recess')
for i in range(7):
 h=1.635+i*.022
 rod('Vertebral collar',xyz(0,h,0),xyz(0,h+.010,0),.047,.044,'neck','Bronze')
for sign in [-1,1]:
 rod('Neck piston housing',xyz(sign*.068,1.625,-.005),xyz(sign*.048,1.76,-.016),.014,.012,'neck','Iron')
 rod('Neck piston rod',xyz(sign*.048,1.74,-.016),xyz(sign*.040,1.815,-.019),.007,.007,'neck','Bronze')
 rod('Temple hinge',xyz(sign*.11,1.90,.018),xyz(sign*.121,1.90,.018),.024,.022,'head','Bronze')
# Join into one skinned mesh; this study intentionally has no provisional body.
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();body=bpy.context.object;body.name='Custodian_MaskStudy'
mod=body.modifiers.new('Custodian skin','ARMATURE');mod.object=rig;body.parent=rig
rig.data.pose_position='POSE'
rig.animation_data.action=None
for track in list(rig.animation_data.nla_tracks):
 if 'idle' not in track.name:rig.animation_data.nla_tracks.remove(track)
 else:track.mute=False
bpy.context.scene.frame_set(1);bpy.context.view_layer.update();rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(Path('art_source/characters/custodian-study.blend').resolve()))
bpy.ops.export_scene.gltf(filepath=str(Path('assets/characters/rigged/custodian-study.glb').resolve()),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_yup=True)
print('CUSTODIAN_MASK_BUILD_OK',len(body.data.vertices),len(body.data.materials))
