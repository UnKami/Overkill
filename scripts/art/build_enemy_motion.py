"""Author restrained enemy body/head/appendage motion in Blender.

The shared five-bone surface rig uses species-specific weights in Godot.
Grounded silhouettes keep their lower support anchored while their torso
loads, attacks and absorbs recoil. Wraiths use a separate hovering profile.
"""
from pathlib import Path
import bpy
import json
import math

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/animations/enemies"
(OUT / "source").mkdir(parents=True, exist_ok=True)
(OUT / "source/.gdignore").write_text("")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.fps = 60
data = bpy.data.armatures.new("EnemySurfaceSkeleton")
rig = bpy.data.objects.new("Enemy_Surface_Rig", data)
scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
rests = [("root","",(0,0)),("body","root",(.52,.55)),
         ("head","body",(.24,.42)),("secondary","body",(.87,.34)),
         ("ground","root",(.5,.96))]
for name,parent,xy in rests:
    bone = data.edit_bones.new(name)
    bone.head = (xy[0], -xy[1], 0)
    bone.tail = (xy[0], -xy[1]+.12, 0)
    if parent:
        bone.parent = data.edit_bones[parent]
bpy.ops.object.mode_set(mode="OBJECT")
rig.animation_data_create()

def key(name,t,x=0,y=0,angle=0):
    bone=rig.pose.bones[name]
    bone.rotation_mode="XYZ"
    bone.location=(x,-y,0)
    bone.rotation_euler=(0,0,-math.radians(angle))
    for path in ("location","rotation_euler"):
        bone.keyframe_insert(path,frame=t*60+1,group=name)

clips={}
for name in ("idle","attack","heavy","flurry","hit","guard","fall"):
    action=bpy.data.actions.new(name)
    action.use_fake_user=True
    rig.animation_data.action=action
    duration=3.2 if name=="idle" else 1.0
    for bn,_,_ in rests:
        key(bn,0); key(bn,duration)
    if name=="idle":
        for t,y,r in ((0,0,0),(.8,-.005,-.3),(1.6,0,0),(2.4,.003,.3),(3.2,0,0)):
            key("body",t,y=y,angle=r)
            key("head",t,angle=-r*.7)
            key("secondary",t,angle=r*2.5)
    elif name in ("attack","heavy","flurry"):
        factor=1.3 if name=="heavy" else .7 if name=="flurry" else 1.0
        for t,x,y,r in ((0,0,0,0),(.3,.018,.010,-1.7),(.45,-.045,-.003,2.8),
                         (.55,-.040,.006,2.3),(.72,-.015,.008,.9),(1,0,0,0)):
            key("body",t,x=x*factor,y=y*factor,angle=r*factor)
            key("head",t,x=-.012*factor if t==.45 else 0,angle=-r*.65)
            key("secondary",t,angle=-r*1.1)
    elif name in ("hit","guard"):
        factor=.45 if name=="guard" else 1.0
        for t,x,r in ((0,0,0),(.22,.025,-2.8),(.45,.016,-1.2),(.75,.003,.25),(1,0,0)):
            key("body",t,x=x*factor,angle=r*factor)
            key("head",t,angle=r*.45*factor)
            key("secondary",t,angle=-r*.8*factor)
    else:
        key("body",.3,y=.025,angle=2)
        key("body",1,y=.075,angle=8)
        key("head",1,angle=4)
    for slot in action.slots:
        for layer in action.layers:
            for strip in layer.strips:
                bag=strip.channelbag(slot)
                if bag:
                    for fc in bag.fcurves:
                        for point in fc.keyframe_points:
                            point.interpolation="BEZIER"
                            point.handle_left_type="AUTO_CLAMPED"
                            point.handle_right_type="AUTO_CLAMPED"
    samples=[]
    for frame in range(round(duration*60)+1):
        scene.frame_set(frame+1)
        samples.append([[round(b.location.x,6),round(-b.location.y,6),round(-b.rotation_euler.z,7)]
                        for b in (rig.pose.bones[bn] for bn,_,_ in rests)])
    clips[name]={"duration":duration,"frames":samples}

# An editable weighted surface makes the source rig visible in Blender too.
mesh=bpy.data.meshes.new("EnemySurface")
verts=[(i/16,-j/20,0) for j in range(21) for i in range(17)]
faces=[]
for j in range(20):
    for i in range(16):
        a=j*17+i
        faces.extend(((a,a+1,a+18),(a,a+18,a+17)))
mesh.from_pydata(verts,[],faces)
obj=bpy.data.objects.new("Weighted_body_with_ground_support",mesh)
scene.collection.objects.link(obj)
body=obj.vertex_groups.new(name="body")
ground=obj.vertex_groups.new(name="ground")
for index,(_,y,_) in enumerate(verts):
    w=max(0,min(1,(-y-.62)/.28))
    body.add([index],1-w,"REPLACE")
    ground.add([index],w,"REPLACE")
obj.modifiers.new("Connected enemy surface","ARMATURE").object=rig
rig.animation_data.action=bpy.data.actions["idle"]
scene.frame_set(1)
scene.frame_end=193
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "source/enemy_surface_motion.blend"))
record={"fps":60,"bones":[x[0] for x in rests],"actions":clips,"grounded_surface":True}
(OUT / "enemy_tracks.gd").write_text("extends RefCounted\n# Authored and evaluated in Blender.\nconst DATA: Dictionary = "+json.dumps(record,separators=(",",":"))+"\n",encoding="utf-8")
(OUT / "source/manifest.json").write_text(json.dumps({"blender":bpy.app.version_string,"fps":60,"bones":5,"actions":list(clips)},indent=2))
print("ENEMY_BLENDER_MOTION_OK bones=5 actions=7 fps=60")
