"""Hollow Custodian full-body study. Original geometry; shared skeleton only.
Blender --background executioner-production.blend --python this script.
Not connected to gameplay. Exports authored Custodian study animation clips.
"""
import bpy,bmesh,math
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
rig.data.pose_position='REST'
for o in list(bpy.data.objects):
 if o!=rig:bpy.data.objects.remove(o,do_unlink=True)
# Dedicated rail bones keep both ends mounted as the chest moves over the hips.
# Constraints are baked into the GLB; Godot needs no procedural attachment code.
bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for sign,side in [(-1,'L'),(1,'R')]:
 lower=Vector((sign*.105,-.035,1.09));upper=Vector((sign*.20,-.035,1.58))
 for label,at,parent in [('lower',lower,'hips'),('upper',upper,'chest')]:
  bone=rig.data.edit_bones.new('custodian_mount_'+label+'.'+side)
  bone.head=at;bone.tail=at+Vector((0,0,.025));bone.parent=rig.data.edit_bones[parent]
 bone=rig.data.edit_bones.new('custodian_rail.'+side)
 bone.head=lower;bone.tail=upper;bone.parent=rig.data.edit_bones['custodian_mount_lower.'+side]
bpy.ops.object.mode_set(mode='OBJECT')
for side in ['L','R']:
 constraint=rig.pose.bones['custodian_rail.'+side].constraints.new('STRETCH_TO')
 constraint.target=rig;constraint.subtarget='custodian_mount_upper.'+side
 constraint.rest_length=rig.data.bones['custodian_rail.'+side].length
 constraint.volume='NO_VOLUME'
rig.select_set(False)
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
 o.data.materials.append(materials[mat])
 if bevel:
  mod=o.modifiers.new('Forged edge','BEVEL');mod.width=bevel;mod.segments=3;mod.material=1;bpy.ops.object.modifier_apply(modifier=mod.name)
 for p in o.data.polygons:p.use_smooth=True
 mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 # R marks actual bevel faces; G is stable part-level variation; B retains AO.
 # CustodianMaterials applies the shared metal shader to decode these channels.
 mask=o.data.color_attributes.new(name='ForgedWear',type='FLOAT_COLOR',domain='CORNER')
 o.data.color_attributes.active_color=mask
 variation=sum((i+1)*ord(c) for i,c in enumerate(o.name))%101/100
 for polygon in o.data.polygons:
  exposed=1.0 if bevel and polygon.material_index==1 else 0.0
  color=(exposed,variation,1.0,1.0) if mat in ['Iron','Bronze'] else (1,1,1,1)
  for index in polygon.loop_indices:mask.data[index].color=color
  polygon.material_index=0
 o.data.materials.clear();o.data.materials.append(materials[mat])
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
 rail_side='L' if sign<0 else 'R'
 rod('Torso side rail',xyz(sign*.105,1.09,.035),xyz(sign*.20,1.58,.035),.016,.018,'custodian_rail.'+rail_side,'Bronze')
 for label,at in [('lower',xyz(sign*.105,1.09,.035)),('upper',xyz(sign*.20,1.58,.035))]:
  bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10,radius=.026,location=at)
  mount=bpy.context.object;mount.name='Torso rail '+label+' bearing'
  bind(mount,'custodian_mount_'+label+'.'+rail_side,'Iron',0)
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
# Slender leg mechanisms, with armor carried by each articulated segment.
for side in ['L','R']:
 thigh=rig.data.bones['thigh.'+side];shin=rig.data.bones['shin.'+side];foot=rig.data.bones['foot.'+side]
 hip=thigh.head_local.copy();knee=shin.head_local.copy();ankle=foot.head_local.copy()
 lateral=Vector((1,0,0));front=Vector((0,1,0))
 rod('Pelvic crossmember',Vector((0,hip.y,hip.z)),hip,.024,.030,'hips','Iron')
 for bone,a,b in [(thigh,hip,knee),(shin,knee,ankle)]:
  rod('Leg spindle',a,b,.024,.018,bone.name,'Recess')
  for sign in [-1,1]:
   shift=lateral*sign*.029
   rod('Leg piston housing',a.lerp(b,.13)+shift,a.lerp(b,.63)+shift,.014,.012,bone.name,'Iron')
   rod('Leg piston extension',a.lerp(b,.59)+shift,a.lerp(b,.92)+shift,.008,.008,bone.name,'Bronze')
  # Four longitudinal stations form a narrow front crest, not a solid boot.
  verts=[]
  for t,width,depth in [(.13,.033,.028),(.28,.054,.045),(.65,.036,.038),(.87,.018,.022)]:
   center=a.lerp(b,t)
   for x,y in [(-1,0),(-.60,.75),(0,1),(.60,.75),(1,0)]:
    verts.append(center+lateral*(x*width)+front*(.027+y*depth))
  faces=[]
  for row in range(3):
   for col in range(4):
    k=row*5+col;faces.append((k,k+1,k+6,k+5))
  mesh=bpy.data.meshes.new('Leg crest');mesh.from_pydata(verts,[],faces);mesh.update()
  shell=bpy.data.objects.new('Crested '+bone.name,mesh);bpy.context.collection.objects.link(shell)
  bpy.context.view_layer.objects.active=shell;shell.select_set(True)
  wall=shell.modifiers.new('Armor wall','SOLIDIFY');wall.thickness=.004;bpy.ops.object.modifier_apply(modifier=wall.name)
  bind(shell,bone.name,'Iron',.0015)
 for name,at,radius,bone in [('Hip',hip,.037,thigh.name),('Knee',knee,.031,shin.name),('Ankle',ankle,.026,foot.name)]:
  rod(name+' axle',at-lateral*.040,at+lateral*.040,radius,radius,bone,'Recess')
  for sign in [-1,1]:
   rod(name+' bearing cap',at+lateral*(sign*.037),at+lateral*(sign*.045),radius*.74,radius*.74,bone,'Bronze')
 # Shaped heel and long pointed toe. Sole clears the rest-pose ground plane.
 x=ankle.x;y=ankle.y
 outline=[(-.034,-.055),(.034,-.055),(.043,.100),(.017,.208),(0,.240),(-.017,.208),(-.043,.100)]
 verts=[Vector((x+dx,y+dy,.016)) for dx,dy in outline]
 verts.extend(Vector((x+dx*.83,y+dy,.045 if dy>.18 else .090)) for dx,dy in outline)
 n=len(outline);faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
 for i in range(n):faces.append((i,(i+1)%n,(i+1)%n+n,i+n))
 mesh=bpy.data.meshes.new('Pointed foot');mesh.from_pydata(verts,[],faces);mesh.update()
 obj=bpy.data.objects.new('Custodian pointed foot '+side,mesh);bpy.context.collection.objects.link(obj);bind(obj,foot.name,'Iron',.003)
 rod('Ankle foot tie',ankle,Vector((x,y+.050,.069)),.019,.020,foot.name,'Iron')
# Split armored coat: open at the front so the mechanical legs remain legible.
# Each side is a curved, folded shell with an uneven broken hem, not a flat tile.
for sign,side in [(-1,'L'),(1,'R')]:
 cols=16;rows=20;verts=[]
 for row in range(rows+1):
  t=row/rows
  for col in range(cols+1):
   u=col/cols;angle=.38+u*1.73
   hem=.23+.055*math.sin(u*math.pi*5+.4)**2+.055*u
   height=1.085*(1-t)+hem*t
   flare=.185+.12*t+.018*math.sin(t*math.pi)+.015*math.sin(t*math.pi/2)
   fold=.010*math.cos(u*math.pi*6)*math.sin(t*math.pi*.8)
   verts.append(xyz(sign*math.sin(angle)*(flare+fold),height,-math.cos(angle)*(.137+.095*t+fold+.012*math.sin(t*math.pi/2))))
 faces=[]
 for row in range(rows):
  for col in range(cols):
   a=row*(cols+1)+col;faces.append((a,a+1,a+cols+2,a+cols+1))
 mesh=bpy.data.meshes.new('Split coat shell');mesh.from_pydata(verts,[],faces);mesh.update()
 coat=bpy.data.objects.new('Long split coat '+side,mesh);bpy.context.collection.objects.link(coat)
 bpy.context.view_layer.objects.active=coat;coat.select_set(True)
 wall=coat.modifiers.new('Coat armor thickness','SOLIDIFY');wall.thickness=.004;bpy.ops.object.modifier_apply(modifier=wall.name)
 bind(coat,'hips','Iron',.001)
 # Front panels follow the thigh below the waistband; the back stays looser.
 # A uniform low weight let the forward-moving knee pass through the coat.
 hip_group=coat.vertex_groups['hips'];leg_group=coat.vertex_groups.new(name='thigh.'+side)
 for vertex in coat.data.vertices:
  t=max(0,min(1,(1.085-vertex.co.z)/.28))
  frontness=max(0,min(1,(vertex.co.y+.02)/.12))
  weight=(.38+.60*frontness)*t*t*(3-2*t)
  hip_group.add([vertex.index],1-weight,'REPLACE');leg_group.add([vertex.index],weight,'REPLACE')
 # Upper overlapping lames give a transition from the belt to the long shell.
 for layer in range(3):
  h=1.065-layer*.091
  outline=[(.10,h),(.22,h+.025),(.285,h-.094),(.195,h-.14),(.12,h-.075)]
  plate('Overlapping hip lame',[(sign*x,z) for x,z in outline],-.178-layer*.008,-.167-layer*.008,'thigh.'+side)
  rod('Hip coat fastening',xyz(sign*.157,h-.011,-.185-layer*.008),xyz(sign*.157,h-.011,-.201-layer*.008),.009,.009,'thigh.'+side,'Bronze',12,.0008)
  rod('Hip lame support',xyz(sign*.157,h-.011,-.192-layer*.008),xyz(sign*.157,h-.011,-.106),.010,.010,'thigh.'+side,'Recess',12,.0008)
# Central hanging plate ends above the knees and leaves two long side openings.
plate('Central split tabard',[(-.069,1.07),(.069,1.07),(.062,.66),(0,.585),(-.062,.66)],-.158,-.147,'hips')
# Join the staged body into one skinned mesh; surface detail and combat remain unfinished.
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();body=bpy.context.object;body.name='Custodian_BodyStudy'
mod=body.modifiers.new('Custodian skin','ARMATURE');mod.object=rig;body.parent=rig
rig.data.pose_position='POSE'
rig.animation_data.action=None
for track in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(track)

def aim(name,direction):
 p=rig.pose.bones[name];rest=p.bone;basis=rest.matrix_local.to_3x3()
 rotation=basis.col[1].normalized().rotation_difference(Vector(direction).normalized())
 matrix=(rotation.to_matrix() @ basis).to_4x4()
 matrix.translation=p.parent.matrix @ (p.parent.bone.matrix_local.inverted() @ rest.head_local) if p.parent else rest.head_local
 p.matrix=matrix;bpy.context.view_layer.update()

# Original four-second idle: planted lower body, slight clockwork sway,
# lowered arms and relaxed claws instead of the source knight's weapon grip.
idle=bpy.data.actions.new('custodian_idle')
bpy.context.scene.render.fps=30
for frame in range(0,121,15):
 rig.animation_data.action=None
 for p in rig.pose.bones:
  p.rotation_mode='QUATERNION';p.matrix_basis=Matrix.Identity(4)
 bpy.context.view_layer.update()
 pulse=math.cos(frame*math.tau/120)
 aim('chest',(.007*pulse,.012,1))
 aim('neck',(0,.012,1));aim('head',(.005*pulse,-.012,1))
 for side,sign in [('L',-1),('R',1)]:
  aim('upper_arm.'+side,(sign*(.25+.009*pulse),.015,-1))
  aim('forearm.'+side,(sign*.22,.15+.009*pulse,-1))
  aim('hand.'+side,(sign*.16,.20,-1))
  for index,finger in enumerate(['f_index','f_middle','f_ring','f_pinky']):
   for segment,angle in [(1,10),(2,18),(3,12)]:
    p=rig.pose.bones[f'{finger}.{segment:02d}.{side}']
    p.rotation_quaternion=Quaternion((1,0,0),math.radians(angle+index*2+pulse*.6))
  for segment,angle in [(1,8),(2,12),(3,10)]:
   rig.pose.bones[f'thumb.{segment:02d}.{side}'].rotation_quaternion=Quaternion((1,0,0),math.radians(angle))
 rig.animation_data.action=idle
 for p in rig.pose.bones:
  p.keyframe_insert('location',frame=frame);p.keyframe_insert('rotation_quaternion',frame=frame);p.keyframe_insert('scale',frame=frame)
rig.animation_data.action=idle;bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
idle_basis={p.name:p.matrix_basis.copy() for p in rig.pose.bones}
rig.animation_data.action=None
for side,sign in [('L',-1),('R',1)]:
 aim('upper_arm.'+side,(sign*.18,.70,-.90))
 aim('forearm.'+side,(-sign*.95,1.10 if side=='L' else .15,.55))
 aim('hand.'+side,(-sign*.90,.40,.40))
 for finger in ['f_index','f_middle','f_ring','f_pinky']:
  for segment,angle in [(1,55),(2,65),(3,45)]:
   rig.pose.bones[f'{finger}.{segment:02d}.{side}'].rotation_quaternion=Quaternion((1,0,0),math.radians(angle))
guard_basis={p.name:p.matrix_basis.copy() for p in rig.pose.bones}
guard=bpy.data.actions.new('custodian_guard')
for frame,amount in [(0,0),(4,.35),(9,1),(18,1),(30,0)]:
 rig.animation_data.action=None
 for p in rig.pose.bones:
  loc,rot,scale=idle_basis[p.name].decompose();target_loc,target_rot,target_scale=guard_basis[p.name].decompose()
  p.location=loc.lerp(target_loc,amount);p.rotation_quaternion=rot.slerp(target_rot,amount);p.scale=scale.lerp(target_scale,amount)
 rig.animation_data.action=guard
 for p in rig.pose.bones:
  p.keyframe_insert('location',frame=frame);p.keyframe_insert('rotation_quaternion',frame=frame);p.keyframe_insert('scale',frame=frame)
rig.animation_data.action=None
for p in rig.pose.bones:p.matrix_basis=idle_basis[p.name]
bpy.context.view_layer.update()
aim('spine',(0,-.055,1));aim('chest',(.035,-.08,1))
aim('neck',(0,-.07,1));aim('head',(-.04,-.13,1))
for side,sign in [('L',-1),('R',1)]:
 aim('upper_arm.'+side,(sign*.44,.035,-1))
 aim('forearm.'+side,(sign*.23,-.13,-1))
 aim('hand.'+side,(sign*.22,-.10,-1))
 for finger in ['f_index','f_middle','f_ring','f_pinky']:
  for segment in range(1,4):
   rig.pose.bones[f'{finger}.{segment:02d}.{side}'].rotation_quaternion=Quaternion((1,0,0),math.radians(5+segment*2))
hit_basis={p.name:p.matrix_basis.copy() for p in rig.pose.bones}
hit=bpy.data.actions.new('custodian_hit')
# Fast recoil, damped counter-motion, then a longer recovery.
for frame,amount in [(0,0),(3,1),(6,.72),(11,-.12),(18,.035),(24,0)]:
 rig.animation_data.action=None
 for p in rig.pose.bones:
  loc,rot,scale=idle_basis[p.name].decompose();target_loc,target_rot,target_scale=hit_basis[p.name].decompose()
  delta=rot.rotation_difference(target_rot)
  p.location=loc+(target_loc-loc)*amount;p.rotation_quaternion=rot @ Quaternion(delta.axis,delta.angle*amount);p.scale=scale
 rig.animation_data.action=hit
 for p in rig.pose.bones:
  p.keyframe_insert('location',frame=frame);p.keyframe_insert('rotation_quaternion',frame=frame);p.keyframe_insert('scale',frame=frame)
rig.animation_data.action=None
attack_poses={}
for phase in ['windup','strike','follow']:
 for p in rig.pose.bones:p.matrix_basis=idle_basis[p.name]
 bpy.context.view_layer.update()
 aim('upper_arm.L',(-.20,.55,-1));aim('forearm.L',(.45,.35,.85));aim('hand.L',(.30,.40,.75))
 if phase=='windup':
  aim('chest',(-.045,-.035,1))
  aim('upper_arm.R',(.60,-.45,-.50));aim('forearm.R',(-.1,.12,1));aim('hand.R',(0,.25,1))
 else:
  aim('chest',(.025,.095 if phase=='strike' else .12,1))
  aim('upper_arm.R',(.08,1,-.05));aim('forearm.R',(-.12,1,.05 if phase=='strike' else -.24))
  aim('hand.R',(-.10,1,0 if phase=='strike' else -.30))
 for finger in ['f_index','f_middle','f_ring','f_pinky']:
  for segment,angle in [(1,20),(2,30),(3,20)]:
   rig.pose.bones[f'{finger}.{segment:02d}.R'].rotation_quaternion=Quaternion((1,0,0),math.radians(angle))
 attack_poses[phase]={p.name:p.matrix_basis.copy() for p in rig.pose.bones}
attack=bpy.data.actions.new('custodian_attack')
# Deliberate anticipation, fast extension (14/30 s), downward follow-through.
for frame,phase,amount in [(0,'windup',0),(6,'windup',1),(10,'windup',1),(14,'strike',1),(18,'follow',1),(28,'follow',.25),(36,'follow',0)]:
 rig.animation_data.action=None
 for p in rig.pose.bones:
  loc,rot,scale=idle_basis[p.name].decompose();target_loc,target_rot,target_scale=attack_poses[phase][p.name].decompose()
  p.location=loc.lerp(target_loc,amount);p.rotation_quaternion=rot.slerp(target_rot,amount);p.scale=scale
 rig.animation_data.action=attack
 for p in rig.pose.bones:
  p.keyframe_insert('location',frame=frame);p.keyframe_insert('rotation_quaternion',frame=frame);p.keyframe_insert('scale',frame=frame)
rig.animation_data.action=None
for p in rig.pose.bones:p.matrix_basis=idle_basis[p.name]
bpy.context.view_layer.update()
idle_world={p.name:p.matrix.copy() for p in rig.pose.bones}
collapse=bpy.data.actions.new('custodian_collapse')
settle=[(0,0),(5,0),(10,.12),(20,.65),(30,1),(42,.98),(48,1)]
for frame in range(49):
 rig.animation_data.action=None
 for p in rig.pose.bones:p.matrix_basis=idle_basis[p.name]
 bpy.context.view_layer.update()
 for index in range(len(settle)-1):
  begin,a=settle[index];end,b=settle[index+1]
  if begin<=frame<=end:
   t=(frame-begin)/(end-begin);amount=a+(b-a)*t*t*(3-2*t);break
 if amount>0:
  pelvis=idle_world['hips'].copy();pelvis.translation.z-=.27*amount
  rig.pose.bones['hips'].matrix=pelvis;bpy.context.view_layer.update()
  # Solve each knee from the fixed ankle and lowered hip; do not slide the feet.
  for side in ['L','R']:
   thigh=rig.pose.bones['thigh.'+side];shin=rig.pose.bones['shin.'+side]
   hip=thigh.head.copy();ankle=idle_world['foot.'+side].translation.copy()
   axis=(ankle-hip).normalized();distance=(ankle-hip).length
   a=thigh.bone.length;b=shin.bone.length
   along=(a*a-b*b+distance*distance)/(2*distance)
   height=math.sqrt(max(0,a*a-along*along))
   front=Vector((0,1,0));bend=(front-axis*front.dot(axis)).normalized()
   knee=hip+axis*along+bend*height
   aim(thigh.name,knee-hip);aim(shin.name,ankle-knee)
   rig.pose.bones['foot.'+side].matrix=idle_world['foot.'+side].copy()
   bpy.context.view_layer.update()
  for name,direction in [('spine',(0,.20,1)),('chest',(.04,.45,.89)),('neck',(0,.50,.85)),('head',(0,.72,.70))]:
   start=idle_world[name].to_3x3().col[1].normalized()
   aim(name,start.lerp(Vector(direction).normalized(),amount))
  for side,sign in [('L',-1),('R',1)]:
   for name,direction in [('upper_arm',(sign*.15,.25,-1)),('forearm',(sign*.10,.25,-1)),('hand',(sign*.05,.20,-1))]:
    full=name+'.'+side;start=idle_world[full].to_3x3().col[1].normalized()
    aim(full,start.lerp(Vector(direction).normalized(),amount))
 rig.animation_data.action=collapse
 for p in rig.pose.bones:
  p.keyframe_insert('location',frame=frame);p.keyframe_insert('rotation_quaternion',frame=frame);p.keyframe_insert('scale',frame=frame)
rig.animation_data.action=None
track=rig.animation_data.nla_tracks.new();track.name='custodian_idle';track.strips.new('custodian_idle',0,idle)
track=rig.animation_data.nla_tracks.new();track.name='custodian_guard';track.strips.new('custodian_guard',0,guard);track.mute=True
track=rig.animation_data.nla_tracks.new();track.name='custodian_hit';track.strips.new('custodian_hit',0,hit);track.mute=True
track=rig.animation_data.nla_tracks.new();track.name='custodian_attack';track.strips.new('custodian_attack',0,attack);track.mute=True
track=rig.animation_data.nla_tracks.new();track.name='custodian_collapse';track.strips.new('custodian_collapse',0,collapse);track.mute=True
bpy.context.scene.frame_set(0);bpy.context.view_layer.update();rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(Path('art_source/characters/custodian-study.blend').resolve()))
bpy.ops.export_scene.gltf(filepath=str(Path('assets/characters/rigged/custodian-study.glb').resolve()),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_yup=True,export_vertex_color='ACTIVE',export_all_vertex_colors=False)
print('CUSTODIAN_BUILD_OK',len(body.data.vertices),len(body.data.materials))
