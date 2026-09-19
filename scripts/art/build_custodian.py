"""Hollow Custodian articulated bust study. Original geometry; shared skeleton only.
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

def rod(name,a,b,r1,r2,bone,mat,vertices=16,bevel=.002):
 a=Vector(a);b=Vector(b);v=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r1,radius2=r2,depth=v.length,location=(a+b)/2)
 o=bpy.context.object;o.name=name;o.rotation_euler=v.to_track_quat('Z','Y').to_euler()
 return bind(o,bone,mat,bevel)
def box(name,at,size,bone,mat,bevel=.003):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.scale=size
 return bind(o,bone,mat,bevel)

def plate(name,outline,front,back,bone,mat='Iron'):
 # Crown the metal rather than extruding a flat silhouette like a cardboard tile.
 n=len(outline);cx=sum(x for x,h in outline)/n;ch=sum(h for x,h in outline)/n
 crown=min(.025,(max(x for x,h in outline)-min(x for x,h in outline))*.16) if mat=='Iron' else 0
 verts=[xyz(x,h,front+.12*x*x) for x,h in outline]
 verts.extend(xyz(cx+(x-cx)*.60,ch+(h-ch)*.60,front-crown+.12*x*x) for x,h in outline)
 verts.extend(xyz(x,h,back+.12*x*x) for x,h in outline)
 faces=[tuple(range(n,2*n)),tuple(reversed(range(2*n,3*n)))]
 for i in range(n):
  j=(i+1)%n
  faces.extend([(i,j,n+j,n+i),(i,2*n+i,2*n+j,j)])
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
 return bind(o,bone,mat,.003)

def wheel(name,x,h,d,radius,bone,teeth=20):
 # Closed annular cog with a clear center; spokes are real three-dimensional struts.
 n=teeth*4;verts=[]
 for depth in [d-.012,d+.012]:
  for inner in [False,True]:
   for i in range(n):
    angle=i*math.tau/n
    r=radius*.55 if inner else radius*([.92,1.04,1.04,.92][i%4])
    verts.append(xyz(x+math.cos(angle)*r,h+math.sin(angle)*r,depth))
 faces=[]
 for i in range(n):
  j=(i+1)%n
  faces.extend([(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),
                (i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)])
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);bind(o,bone,'Bronze',.0008)
 for i in range(5):
  a=i*math.tau/5
  rod('Wheel spoke',xyz(x,h,d),xyz(x+math.cos(a)*radius*.6,h+math.sin(a)*radius*.6,d),.006,.005,bone,'Bronze')
 rod('Wheel bearing',xyz(x,h,d-.016),xyz(x,h,d+.018),radius*.19,radius*.19,bone,'Iron')

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
# Hollow torso: visible clockwork suspended between armor wings and a dark spine.
rod('Spinal casing',xyz(0,1.02,.045),xyz(0,1.65,.045),.044,.038,'spine','Recess')
for i in range(9):
 h=1.08+i*.055
 rod('Spinal coupling',xyz(0,h,.045),xyz(0,h+.019,.045),.054,.052,'spine' if h<1.34 else 'chest','Iron')
for sign in [-1,1]:
 rod('Torso side rail',xyz(sign*.105,1.09,.035),xyz(sign*.20,1.58,.035),.016,.018,'chest','Bronze')
 rod('Clavicle tie',xyz(0,1.62,.015),xyz(sign*.255,1.62,.015),.020,.025,'chest','Iron')
 # Three separately backed shards retain narrow dark fractures, not bright cracks.
 outlines=[[(.052,1.645),(.18,1.685),(.238,1.608),(.188,1.537),(.093,1.566)],
           [(.096,1.559),(.185,1.530),(.171,1.424),(.108,1.381),(.062,1.477)],
           [(.195,1.535),(.244,1.597),(.266,1.476),(.180,1.431)]]
 for index,outline in enumerate(outlines):
  plate('Fractured breastplate '+str(index),[(sign*x,h) for x,h in outline],-.145,-.126,'chest')
 plate('Breastplate backing',[(sign*x,h) for x,h in [(.048,1.65),(.24,1.68),(.274,1.47),(.11,1.36),(.04,1.47)]],-.092,-.063,'chest','Recess')
 # Raised collar curves upward behind the neck, keeping the front machinery exposed.
 points=[]
 for i in range(13):
  a=-.1+i*math.pi*.92/12
  points.append(xyz(sign*(.085+math.sin(a)*.085),1.64+math.sin(a)*.095,.025+math.cos(a)*.085))
 for i in range(12):rod('Collar rim',points[i],points[i+1],.014,.014,'chest','Iron')
 side='L' if sign<0 else 'R'
 plate('Shoulder escutcheon',[(sign*x,h) for x,h in [(.245,1.68),(.36,1.73),(.43,1.66),(.373,1.565),(.28,1.595)]],-.085,-.063,'shoulder.'+side)
 # Long broken crown fragments distinguish the Custodian from rounded Sentinel lames.
 plate('Shoulder shard',[(sign*x,h) for x,h in [(.285,1.70),(.31,1.88),(.35,1.76),(.348,1.69)]],-.01,.025,'shoulder.'+side)
 plate('Outer shoulder shard',[(sign*x,h) for x,h in [(.37,1.69),(.46,1.79),(.445,1.67),(.415,1.63)]],.025,.055,'shoulder.'+side)
 rod('Chest suspension pin',xyz(sign*.185,1.618,-.186),xyz(sign*.185,1.618,-.154),.022,.022,'chest','Bronze')
 plate('Pelvic arch',[(sign*x,h) for x,h in [(.02,1.11),(.17,1.14),(.20,1.065),(.065,1.00),(.015,1.027)]],-.09,-.068,'hips')
wheel('Upper escapement',0,1.465,-.096,.075,'chest',24)
wheel('Offset drive',.063,1.305,-.086,.054,'spine',18)
wheel('Lower balance',-.025,1.184,-.097,.077,'hips',24)
rod('Central bearing support',xyz(0,1.15,-.075),xyz(0,1.55,-.075),.015,.015,'spine','Recess')
# Slender articulated armature. Rest-space anchors come from the actual bones,
# so elbow pivots coincide under animation rather than merely looking aligned.
for side in ['L','R']:
 upper=rig.data.bones['upper_arm.'+side];lower=rig.data.bones['forearm.'+side]
 shoulder=upper.head_local.copy();elbow=lower.head_local.copy();wrist=lower.tail_local.copy()
 front=Vector((0,1,0))
 rod('Shoulder axle',shoulder-front*.050,shoulder+front*.050,.046,.046,upper.name,'Recess')
 rod('Shoulder bearing cap',shoulder+front*.040,shoulder+front*.055,.039,.039,upper.name,'Bronze')
 # Rear bracket carries the previously unsupported outer shoulder armor.
 sign=-1 if side=='L' else 1
 rod('Shoulder armor bracket',shoulder,xyz(sign*.35,1.66,-.057),.014,.014,'shoulder.'+side,'Iron')
 for bone,a,b in [(upper,shoulder,elbow),(lower,elbow,wrist)]:
  axis=(b-a).normalized();across=axis.cross(front).normalized()
  rod('Arm dark spindle',a.lerp(b,.08),a.lerp(b,.93),.021,.017,bone.name,'Recess')
  for offset in [-1,1]:
   shift=across*(offset*.027)
   rod('Arm piston housing',a.lerp(b,.16)+shift,a.lerp(b,.60)+shift,.013,.012,bone.name,'Iron')
   rod('Arm piston extension',a.lerp(b,.57)+shift,a.lerp(b,.88)+shift,.007,.007,bone.name,'Bronze')
  # A faceted, tapered half-shell leaves the rear linkage visible.
  verts=[];rings=[(.12,.039),(.27,.052),(.64,.043),(.86,.025)]
  for t,width in rings:
   center=a.lerp(b,t)
   for i in range(9):
    angle=-math.pi*.58+i*math.pi*1.16/8
    verts.append(center+across*(math.sin(angle)*width)+front*(math.cos(angle)*width))
  faces=[]
  for ring in range(3):
   for i in range(8):
    k=ring*9+i;faces.append((k,k+1,k+10,k+9))
  mesh=bpy.data.meshes.new('Arm shell');mesh.from_pydata(verts,[],faces);mesh.update()
  shell=bpy.data.objects.new('Tapered '+bone.name+' armor',mesh);bpy.context.collection.objects.link(shell)
  bpy.context.view_layer.objects.active=shell;shell.select_set(True)
  solid=shell.modifiers.new('Forged wall','SOLIDIFY');solid.thickness=.004;bpy.ops.object.modifier_apply(modifier=solid.name)
  bind(shell,bone.name,'Iron',.0015)
 rod('Elbow axle',elbow-front*.045,elbow+front*.045,.035,.035,lower.name,'Recess')
 rod('Elbow bronze bearing',elbow+front*.034,elbow+front*.046,.028,.028,lower.name,'Bronze')
 rod('Elbow center pin',elbow+front*.044,elbow+front*.051,.011,.011,lower.name,'Iron')
 axis=(wrist-elbow).normalized()
 rod('Wrist coupling',wrist-axis*.025,wrist+axis*.010,.027,.025,lower.name,'Bronze')
# Open metacarpal frames and five independently skinned mechanical digits.
# Palm rods reach actual finger roots, not the shorter hand-bone tail.
for side in ['L','R']:
 hand=rig.data.bones['hand.'+side]
 fingers=['f_index','f_middle','f_ring','f_pinky']
 roots=[rig.data.bones[f+'.01.'+side].head_local.copy() for f in fingers]
 center=sum(roots,Vector())/4;axis=(center-hand.head_local).normalized()
 across=(roots[0]-roots[-1]).normalized();normal=axis.cross(across).normalized()
 # Dorsal wrist bridge, with a narrow open frame running to each knuckle.
 rod('Palm wrist bridge',hand.head_local-across*.020,hand.head_local+across*.020,.015,.015,hand.name,'Iron')
 for index,root in enumerate(roots):
  start=hand.head_local+across*(.016-index*.010)
  rod('Metacarpal strut',start,root,.009,.011,hand.name,'Iron')
  rod('Dorsal tendon',start+normal*.011,root+normal*.010,.0035,.0035,hand.name,'Bronze')
 rod('Knuckle bridge',roots[0],roots[-1],.010,.010,hand.name,'Iron')
 thumb=rig.data.bones['thumb.01.'+side]
 rod('Thumb saddle',hand.head_local.lerp(center,.25),thumb.head_local,.012,.013,hand.name,'Iron')
 for finger in fingers+['thumb']:
  for segment in range(1,4):
   bone=rig.data.bones[f'{finger}.{segment:02d}.{side}']
   a=bone.head_local.copy();b=bone.tail_local.copy();direction=(b-a).normalized()
   radius=.009 if finger!='f_pinky' else .0075
   bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=radius*1.1,location=a)
   joint=bpy.context.object;joint.name='Digit bearing';bind(joint,bone.name,'Recess',0)
   rod('Digit hinge pin',a-normal*radius*1.18,a+normal*radius*1.18,radius*.48,radius*.48,bone.name,'Bronze',12,.0006)
   rod('Finger phalanx',a+direction*.006,b-direction*.005,radius,radius*.72,bone.name,'Iron',12,.0006)
   if segment==3:
    # Closed pointed tips follow the terminal bone; no unweighted extensions.
    rod('Tapered claw tip',b-direction*.009,b+direction*.009,radius*.76,.0015,bone.name,'Iron',12,.0006)
# Join the staged upper body into one skinned mesh; lower body and combat remain unfinished.
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();body=bpy.context.object;body.name='Custodian_BodyStudy'
mod=body.modifiers.new('Custodian skin','ARMATURE');mod.object=rig;body.parent=rig
rig.data.pose_position='POSE'
rig.animation_data.action=None
for track in list(rig.animation_data.nla_tracks):
 if 'idle' not in track.name:rig.animation_data.nla_tracks.remove(track)
 else:track.mute=False
bpy.context.scene.frame_set(1);bpy.context.view_layer.update();rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(Path('art_source/characters/custodian-study.blend').resolve()))
bpy.ops.export_scene.gltf(filepath=str(Path('assets/characters/rigged/custodian-study.glb').resolve()),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_yup=True)
print('CUSTODIAN_BUILD_OK',len(body.data.vertices),len(body.data.materials))
