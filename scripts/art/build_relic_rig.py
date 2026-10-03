"""Rebuild the Executioner's real cutout armature, actions and Godot skin data.

Run with Blender 5.2: blender.exe --background --python scripts/art/build_relic_rig.py
The .blend is the editable animation source. Godot receives the identical bone
hierarchy, weighted mesh vertices and locally sampled Blender action transforms.
No raster animation frames or whole-character warping are used.
"""
from pathlib import Path
import json
import math
import sys
import bpy
import numpy as np
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/characters/executioner/rigged"
FPS = 60
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "source").mkdir(exist_ok=True)
(OUT / "source/.gdignore").write_text("")

# Coordinates use Godot's positive-down pixel convention. All armature rest
# axes are parallel, so local animation transforms have an unambiguous 2D export.
BONES = [
    ("root", "", (0, 0)),
    ("pelvis", "root", (0, -224)),
    ("spine", "pelvis", (0, -295)),
    ("head", "spine", (8, -403)),
    ("cloak_upper", "spine", (-15, -316)),
    ("cloak_lower", "cloak_upper", (-24, -185)),
    ("arm_far", "spine", (-46, -370)),
    ("forearm_far", "arm_far", (-82, -298)),
    ("hand_far", "forearm_far", (-100, -225)),
    ("thigh_far", "pelvis", (-28, -220)),
    ("shin_far", "thigh_far", (-63, -123)),
    ("foot_far", "shin_far", (-76, -35)),
    ("thigh_near", "pelvis", (29, -220)),
    ("shin_near", "thigh_near", (61, -123)),
    ("foot_near", "shin_near", (55, -34)),
    ("arm_near", "spine", (47, -366)),
    ("forearm_near", "arm_near", (80, -289)),
    ("hand_near", "forearm_near", (100, -218)),
]
HEADS = {name: Vector((p[0], p[1])) for name, parent, p in BONES}
PARENTS = {name: parent for name, parent, p in BONES}
# Atlas cells and natural character-space rectangles. Vertices overlap at the
# armored joints; the torso and cloak are blended across multiple bones.
PARTS = [
    ("cloak", 3, "cloak_upper", (-101, -310, 191, 281), -8),
    ("thigh_far", 13, "thigh_far", (-87, -238, 77, 132), -6),
    ("shin_far", 14, "shin_far", (-104, -143, 66, 126), -5),
    ("foot_far", 15, "foot_far", (-101, -59, 83, 62), -4),
    ("arm_far", 7, "arm_far", (-105, -388, 77, 113), -3),
    ("forearm_far", 8, "forearm_far", (-127, -315, 67, 119), -2),
    ("hand_far", 9, "hand_far", (-125, -239, 52, 62), -1),
    ("thigh_near", 10, "thigh_near", (0, -236, 77, 132), 0),
    ("shin_near", 11, "shin_near", (31, -145, 64, 125), 1),
    ("foot_near", 12, "foot_near", (34, -57, 88, 62), 2),
    ("pelvis", 2, "pelvis", (-72, -268, 158, 146), 3),
    ("torso", 1, "spine", (-68, -400, 148, 173), 4),
    ("head", 0, "head", (-58, -484, 133, 140), 5),
    ("arm_near", 4, "arm_near", (30, -385, 82, 121), 6),
    ("forearm_near", 5, "forearm_near", (63, -310, 68, 113), 7),
    ("hand_near", 6, "hand_near", (79, -233, 56, 61), 8),
]

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.fps = FPS
scene.render.engine = "BLENDER_EEVEE"
if "--cpu-renders" in sys.argv:
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = False
scene.render.film_transparent = True
scene.view_settings.view_transform = "Standard"
scene.render.resolution_x = 768
scene.render.resolution_y = 768
scene.render.resolution_percentage = 100

arm = bpy.data.armatures.new("Executioner_2D_Skeleton")
rig = bpy.data.objects.new("Executioner_Articulated_Rig", arm)
scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
for name, parent, p in BONES:
    bone = arm.edit_bones.new(name)
    bone.head = (p[0], -p[1], 0)
    bone.tail = (p[0], -p[1] + 36, 0)
    if parent:
        bone.parent = arm.edit_bones[parent]
        bone.use_connect = False
bpy.ops.object.mode_set(mode="OBJECT")
rig.show_in_front = True
arm.display_type = "STICK"

atlas = bpy.data.images.load(str(OUT / "parts_atlas.png"))
atlas.pack()
aw, ah = atlas.size
pixels = np.asarray(atlas.pixels[:], dtype=np.float32).reshape(ah, aw, 4)
pixels = np.flipud(pixels)  # UV/image accessor uses bottom-up scan order.
if float(pixels[:, :, 3].min()) > 0.01:
    raise RuntimeError("Parts atlas must have true transparent alpha")
material = bpy.data.materials.new("Executioner_Painted_Cutouts")
material.use_nodes = True
nodes = material.node_tree.nodes
nodes.clear()
tex = nodes.new("ShaderNodeTexImage")
tex.image = atlas
emission = nodes.new("ShaderNodeEmission")
transparent = nodes.new("ShaderNodeBsdfTransparent")
mix = nodes.new("ShaderNodeMixShader")
output = nodes.new("ShaderNodeOutputMaterial")
material.node_tree.links.new(tex.outputs["Color"], emission.inputs["Color"])
material.node_tree.links.new(tex.outputs["Alpha"], mix.inputs[0])
material.node_tree.links.new(transparent.outputs[0], mix.inputs[1])
material.node_tree.links.new(emission.outputs[0], mix.inputs[2])
material.node_tree.links.new(mix.outputs[0], output.inputs[0])

mesh_records = []

def largest_art_bounds(alpha):
    """Select the main connected cutout for UV bounds, excluding nearby-cell
    fragments. Only geometry/UVs change; the painted texture remains untouched.
    """
    active = alpha > 0.12
    unseen = set(zip(*np.where(active)))
    largest = []
    while unseen:
        seed = unseen.pop()
        island, stack = [seed], [seed]
        while stack:
            py, px = stack.pop()
            for p in ((py-1,px), (py+1,px), (py,px-1), (py,px+1)):
                if p in unseen:
                    unseen.remove(p)
                    stack.append(p)
                    island.append(p)
        if len(island) > len(largest):
            largest = island
    ys, xs = zip(*largest)
    return min(xs), max(xs), min(ys), max(ys)

for name, cell, bone_name, rect, depth in PARTS:
    col, row = cell % 4, cell // 4
    cw, ch = aw // 4, ah // 4
    alpha = pixels[row * ch:(row + 1) * ch, col * cw:(col + 1) * cw, 3]
    min_x, max_x, min_y, max_y = largest_art_bounds(alpha)
    # Tiny clear border prevents filtering into neighboring atlas cells.
    x0, x1 = max(1, min_x - 1), min(cw - 1, max_x + 2)
    y0, y1 = max(1, min_y - 1), min(ch - 1, max_y + 2)
    x, y, width, height = rect
    # Dense cloth needs curvature; rigid armor needs only enough subdivisions
    # to blend its joint overlap. Avoid excess skin work on every rendered frame.
    nx, ny = (6, 10) if name in ("cloak", "torso", "pelvis") else (3, 7)
    verts, uv, weights = [], [], {}
    for j in range(ny + 1):
        v = j / ny
        for i in range(nx + 1):
            u = i / nx
            vx, vy = x + width * u, y + height * v
            verts.append((vx, -vy, depth * 0.15))
            paint_u = 1.0 - u if name in ("arm_near", "arm_far") else u
            uv.append(((col * cw + x0 + (x1 - x0) * paint_u) / aw,
                       1 - (row * ch + y0 + (y1 - y0) * v) / ah))
            if name == "cloak":
                lower = max(0, min(1, (v - 0.28) / 0.6))
                value = {"cloak_upper": 1 - lower, "cloak_lower": lower}
            elif name == "torso":
                low = max(0, min(0.72, (v - 0.58) / 0.42))
                value = {"spine": 1 - low, "pelvis": low}
            else:
                # Soft overlap at armored elbows/knees keeps the painted joint
                # connected as its two rigid limb sections change direction.
                value = {bone_name: 1.0}
                child = {"arm_near":"forearm_near", "arm_far":"forearm_far",
                         "thigh_near":"shin_near", "thigh_far":"shin_far"}.get(name)
                if child and v > .68:
                    blend = min(.5, (v-.68)/.32*.5)
                    value = {bone_name:1-blend, child:blend}
                if name.startswith(("forearm_", "shin_", "hand_")) and v < .24:
                    blend = (.24-v)/.24*.45
                    value = {bone_name:1-blend, PARENTS[bone_name]:blend}
            for bn in value:
                if bn not in weights:
                    weights[bn] = [0.0] * ((nx + 1) * (ny + 1))
                weights[bn][j * (nx + 1) + i] = value[bn]
    triangles = []
    for j in range(ny):
        for i in range(nx):
            a = j * (nx + 1) + i
            triangles += [(a, a + 1, a + nx + 2), (a, a + nx + 2, a + nx + 1)]
    mesh = bpy.data.meshes.new(name + "_weighted_mesh")
    mesh.from_pydata(verts, [], triangles)
    mesh.update()
    layer = mesh.uv_layers.new(name="PaintedUV")
    for loop in mesh.loops:
        layer.data[loop.index].uv = uv[loop.vertex_index]
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    obj.data.materials.append(material)
    for bn, values in weights.items():
        group = obj.vertex_groups.new(name=bn)
        for index, weight in enumerate(values):
            if weight > 0:
                group.add([index], weight, "REPLACE")
    modifier = obj.modifiers.new("Genuine armature deformation", "ARMATURE")
    modifier.object = rig
    obj.parent = rig
    mesh_records.append({"name": name, "z": depth,
        "vertices": [[round(a, 4), round(-b, 4)] for a, b, c in verts],
        "uv": [[round(u * aw, 4), round((1 - v) * ah, 4)] for u, v in uv],
        "triangles": triangles, "weights": weights})

def pose(drop=0, x=0, near=None, far=None, feet=None, **kwargs):
    values = {"root":(0,x,drop), "_near":near or tuple(HEADS["hand_near"]),
              "_far":far or tuple(HEADS["hand_far"]),
              "_foot_near":feet[0] if feet else (55+x,-34),
              "_foot_far":feet[1] if feet else (-76+x,-35)}
    for name,value in kwargs.items():
        values[name] = value if isinstance(value,tuple) else (value,)
    return values

# World-space hand/ankle targets are authored in the same painted anatomy as
# the rest pose. The Blender bake solves connected, fixed-length limbs at EVERY
# sample, rather than interpolating independently rotated knees and elbows.
ACTIONS = {
 "idle":(3.2,-1,[(0,pose()),(.8,pose(spine=-.65,head=.45,near=(100,-220),cloak_lower=1.7)),
     (1.6,pose(spine=.45,head=-.4,near=(100,-217),cloak_lower=-1.2)),
     (2.4,pose(spine=.6,head=-.3,cloak_upper=-.6)),(3.2,pose())]),
 "iron_strike":(3.1,2.2,[
     (0,pose()),(.35,pose(near=(96,-295),head=1.5)),
     (1.3,pose(near=(98,-300),spine=-2,head=2)),
     (1.5,pose(12,near=(55,-371),spine=-4,head=3,cloak_lower=-3)),
     (1.83,pose(23,near=(50,-419),far=(-82,-262),spine=-7,head=4,cloak_lower=-6)),
     (2.03,pose(-9,116,near=(152,-352),far=(-83,-258),spine=7,head=-3,
                    feet=((181,-48),(17,-59)),cloak_lower=-14)),
     (2.2,pose(12,184,near=(194,-303),far=(-92,-251),spine=9,head=-5,
                   feet=((264,-34),(105,-35)),cloak_lower=-16)),
     (2.39,pose(10,184,near=(174,-258),spine=6,head=-3,
                    feet=((264,-34),(105,-35)),cloak_lower=-10)),
     (2.6,pose(5,117,near=(132,-255),spine=3,feet=((221,-65),(105,-35)),cloak_lower=5)),
     (2.83,pose(8,30,near=(106,-241),spine=1,feet=((70,-34),(-12,-56)),cloak_lower=6)),
     (3.1,pose())]),
 "throw":(1.7,.95,[
     (0,pose()),(.25,pose(near=(103,-291),head=2)),
     (.42,pose(10,near=(128,-405),spine=-3,head=2)),
     (.52,pose(12,near=(42,-436),far=(-80,-258),spine=-5,head=3,cloak_lower=-4)),
     (.67,pose(9,near=(123,-416),spine=-1,head=1)),
     (.76,pose(6,near=(177,-330),spine=6,head=-3)),
     (.95,pose(7,near=(184,-309),spine=7,head=-3)),
     (1.22,pose(4,near=(158,-259),spine=3,cloak_lower=4)),
     (1.7,pose())]),
 "channel":(2.7,2.4,[
     (0,pose()),(.5,pose(near=(111,-291),far=(-74,-290),head=-3,spine=-1)),
     (1.25,pose(near=(121,-303),far=(-66,-303),head=-4,spine=-2,cloak_lower=2)),
     (2.15,pose(near=(118,-300),far=(-69,-299),head=-3,spine=-1.5)),
     (2.4,pose(near=(109,-271),far=(-85,-266),head=-2)),(2.7,pose())]),
 "crown":(2.1,1.7,[(0,pose()),(.4,pose(head=2,spine=1,near=(109,-253))),
     (1,pose(head=-4,spine=-2,near=(120,-270),far=(-86,-260))),
     (1.7,pose(head=-2,spine=-1,near=(114,-257))),(2.1,pose())]),
 "bell":(3,2.5,[(0,pose()),(.4,pose(6,near=(111,-312),far=(-64,-311),head=-2)),
     (.85,pose(7,near=(118,-317),far=(-61,-315),head=-3,spine=.6)),
     (1.3,pose(6,near=(114,-314),far=(-64,-312),head=-2,spine=-.6)),
     (1.8,pose(7,near=(118,-317),far=(-61,-315),head=-3,spine=.6)),
     (2.25,pose(6,near=(114,-314),far=(-64,-312),head=-2,spine=-.6)),
     (2.5,pose(10,near=(108,-287),far=(-74,-289),spine=-2)),(3,pose())]),
 "block":(1.8,1.1,[(0,pose()),(.4,pose(14,near=(100,-302),far=(-67,-297),head=2,spine=-3)),
     (1.1,pose(12,near=(103,-300),far=(-71,-292),head=1.5,spine=-2.5)),
     (1.4,pose(5,near=(109,-258),far=(-87,-253))),(1.8,pose())]),
 "hit":(.55,-1,[(0,pose()),(.12,pose(8,spine=-7,head=-5,near=(100,-239),cloak_lower=5)),
     (.32,pose(3,spine=-3,head=-1)),(.55,pose())]),
 "guard_hit":(.5,-1,[(0,pose()),(.1,pose(11,near=(104,-301),far=(-72,-292),spine=-4)),
     (.3,pose(4,near=(109,-264),far=(-88,-252),spine=-1)),(.5,pose())]),
 "fall":(1.1,-1,[(0,pose()),(.35,pose(30,spine=9,head=7,near=(111,-233))),
     (1.1,pose(59,spine=23,head=12,near=(132,-246),cloak_lower=7))]),
 "heavy":(3.3,2.2,[(0,pose()),(.5,pose(near=(66,-405),far=(-52,-352),spine=-3,head=-2)),
     (1.4,pose(13,near=(27,-411),far=(-40,-350),spine=-6,head=-3)),
     (1.85,pose(23,near=(30,-406),far=(-37,-351),spine=-5)),
     (2.2,pose(16,130,near=(169,-273),far=(-68,-273),spine=12,head=-5,
                    feet=((217,-34),(47,-35)),cloak_lower=-13)),
     (2.46,pose(13,130,near=(151,-250),spine=8,feet=((217,-34),(47,-35)),cloak_lower=-6)),
     (2.75,pose(5,80,near=(119,-250),spine=4,feet=((154,-58),(47,-35)),cloak_lower=4)),
     (3.03,pose(5,18,near=(109,-238),spine=1,feet=((57,-34),(-46,-53)))),(3.3,pose())])
}

def monotone_sample(keys, t):
    # PCHIP Hermite tangents: velocity is continuous across key poses without
    # Bezier overshoot, knee reversal, or a stop at every intermediate pose.
    times=[k[0] for k in keys]
    labels=set(BONES[i][0] for i in range(len(BONES))) | {"_near","_far","_foot_near","_foot_far"}
    defaults=pose()
    result={}
    interval=min(len(keys)-2,max(0,next((i-1 for i,x in enumerate(times) if x>t),len(keys)-2)))
    interval=max(0,interval)
    h=times[interval+1]-times[interval]
    u=max(0,min(1,(t-times[interval])/h))
    for name in labels:
        count=2 if name.startswith("_") else 3
        rows=[]
        for _,p in keys:
            v=p.get(name,defaults.get(name,(0,0,0)))
            rows.append(list(v)+[0]*(count-len(v)))
        if name in ("_near", "_far"):
            shoulder=HEADS["arm"+name]
            polar=[]
            last_angle=None
            for row in rows:
                delta=Vector(row)-shoulder
                angle=math.atan2(delta.y,delta.x)
                if last_angle is not None:
                    angle=last_angle+math.atan2(math.sin(angle-last_angle),math.cos(angle-last_angle))
                polar.append([delta.length,angle])
                last_angle=angle
            rows=polar
        vals=[]
        for c in range(count):
            slopes=[(rows[i+1][c]-rows[i][c])/(times[i+1]-times[i]) for i in range(len(keys)-1)]
            tangents=[0.0]*len(keys)
            for j in range(1,len(keys)-1):
                left,right=slopes[j-1],slopes[j]
                if left*right>0:
                    hl,hr=times[j]-times[j-1],times[j+1]-times[j]
                    w1,w2=2*hr+hl,hr+2*hl
                    tangents[j]=(w1+w2)/(w1/left+w2/right)
            v=(2*u**3-3*u*u+1)*rows[interval][c]+(u**3-2*u*u+u)*h*tangents[interval]
            v+=(-2*u**3+3*u*u)*rows[interval+1][c]+(u**3-u*u)*h*tangents[interval+1]
            vals.append(v)
        if name in ("_near", "_far"):
            shoulder=HEADS["arm"+name]
            result[name]=tuple(shoulder+Vector((math.cos(vals[1]),math.sin(vals[1])))*vals[0])
        else:
            result[name]=tuple(vals)
    return result

def two_bone(first, second, end, target, sign):
    v1,v2=HEADS[second]-HEADS[first],HEADS[end]-HEADS[second]
    l1,l2=v1.length,v2.length
    distance=max(.01,(target).length)
    minimum=math.sqrt(l1*l1+l2*l2+2*l1*l2*math.cos(math.radians(112)))
    distance=max(minimum,min(l1+l2-.01,distance))
    theta=math.atan2(target.y,target.x)
    alpha=math.acos(max(-1,min(1,(l1*l1+distance*distance-l2*l2)/(2*l1*distance))))
    direction=theta-sign*alpha
    knee=Vector((math.cos(direction),math.sin(direction)))*l1
    goal=Vector((math.cos(theta),math.sin(theta)))*distance
    direction2=math.atan2((goal-knee).y,(goal-knee).x)
    r1=direction-math.atan2(v1.y,v1.x)
    r2=direction2-math.atan2(v2.y,v2.x)-r1
    return tuple(math.degrees(math.atan2(math.sin(v),math.cos(v))) for v in (r1,r2))

def solved_pose(values):
    out={k:v for k,v in values.items() if not k.startswith("_")}
    root=Vector((values["root"][1],values["root"][2]))
    for side in ("near","far"):
        first,second,end="thigh_"+side,"shin_"+side,"foot_"+side
        v1,v2=HEADS[second]-HEADS[first],HEADS[end]-HEADS[second]
        sign=1 if v1.cross(v2)>0 else -1
        target=Vector(values["_foot_"+side])-HEADS[first]-root
        r1,r2=two_bone(first,second,end,target,sign)
        out[first]=(r1,);out[second]=(r2,);out[end]=(-r1-r2,)
    for side in ("near","far"):
        first,second,end="arm_"+side,"forearm_"+side,"hand_"+side
        # Targets follow the chest, while elbows retain one anatomical bend.
        target=Vector(values["_"+side])-HEADS[first]
        r1,r2=two_bone(first,second,end,target,1 if side=="near" else -1)
        out[first]=(r1,);out[second]=(r2,)
        out[end]=(max(-15,min(15,values[end][0])),)
    return out

rig.animation_data_create()
animation_records = {}
for action_name, (duration, contact, poses) in ACTIONS.items():
    action = bpy.data.actions.new(action_name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame in range(round(duration * FPS) + 1):
        time = frame / FPS
        pose_values = solved_pose(monotone_sample(poses,time))
        for name, parent, p in BONES:
            pb = rig.pose.bones[name]
            values = pose_values.get(name, (0, 0, 0))
            rot = values[0]
            dx = values[1] if len(values) > 1 else 0
            dy = values[2] if len(values) > 2 else 0
            pb.rotation_mode = "XYZ"
            pb.rotation_euler = (0, 0, -math.radians(rot))
            pb.location = (dx, -dy, 0)
            pb.keyframe_insert("rotation_euler", frame=time * FPS + 1, group=name)
            pb.keyframe_insert("location", frame=time * FPS + 1, group=name)
    # Clamp interpolation handles to avoid limbs overshooting through themselves.
    for layer in action.layers:
        for strip in layer.strips:
            for slot in action.slots:
                bag = strip.channelbag(slot)
                if bag:
                    for curve in bag.fcurves:
                        for point in curve.keyframe_points:
                            point.interpolation = "LINEAR"
                            point.handle_left_type = "AUTO_CLAMPED"
                            point.handle_right_type = "AUTO_CLAMPED"
    samples = []
    for frame in range(round(duration * FPS) + 1):
        scene.frame_set(frame + 1)
        sample = []
        for name, parent, p in BONES:
            pb = rig.pose.bones[name]
            # Parent-relative head transform, including the authored rest offset.
            local = rig.pose.bones[parent].matrix.inverted() @ pb.matrix if parent else pb.matrix
            sample.append([round(local.translation.x, 5), round(-local.translation.y, 5),
                           round(-local.to_euler("XYZ").z, 7)])
        samples.append(sample)
    animation_records[action_name] = {"duration": duration, "contact": contact, "frames": samples}

record = {"format": "overkill_blender_skin_v2", "fps": FPS,
          "authoring": "Blender armature modifier; 18 bones; connected IK limbs; weighted joint overlaps; 60 Hz motion",
          "atlas_size": [aw, ah], "bounds": [-128, -484, 264, 489], "motion_quality":{"continuous_ik":True,"elbow_max_degrees":112,"grounded_anticipation":True},
          "bones": [],
          "meshes": mesh_records, "actions": animation_records}
# Keep the metadata readable and the main data a resource script so exported PCKs
# include it automatically (Godot's all_resources export does not include JSON).
record["bones"] = [{"name": n, "parent": p,
                    "rest": [round(float(v), 5) for v in (HEADS[n] - HEADS[p] if p else HEADS[n])]}
                   for n, p, xy in BONES]
encoded = json.dumps(record, separators=(",", ":"))
(OUT / "rig_data.gd").write_text("extends RefCounted\n# Generated by Blender; edit the .blend/build script, not this table.\nconst DATA: Dictionary = " + encoded + "\n", encoding="utf-8")
(OUT / "source/rig_manifest.json").write_text(json.dumps({k:v for k,v in record.items() if k not in ("meshes", "actions")}, indent=2), encoding="utf-8")

# Camera makes the saved source immediately reviewable in Blender.
camera_data = bpy.data.cameras.new("Review_Camera")
camera = bpy.data.objects.new("Review_Camera", camera_data)
scene.collection.objects.link(camera)
camera.location = (15, 238, 1000)
camera.rotation_euler = (0, 0, 0)
camera_data.type = "ORTHO"
camera_data.ortho_scale = 570
camera_data.clip_end = 2500
scene.camera = camera
rig.animation_data.action = bpy.data.actions["idle"]
scene.frame_set(1)
scene.frame_start = 1
scene.frame_end = round(3.2*FPS)+1
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "source/executioner_relic_rig.blend"))
review_poses = [] if "--skip-renders" in sys.argv else [("idle",0), ("iron_strike",1.83), ("iron_strike",2.2), ("throw",0.52), ("throw",0.95), ("block",0.65), ("heavy",1.4), ("heavy",2.2)]
for action_name, time in review_poses:
    rig.animation_data.action = bpy.data.actions[action_name]
    scene.frame_set(round(time * FPS) + 1)
    camera.location.x = rig.pose.bones["root"].matrix.translation.x + 15
    scene.render.filepath = str(OUT / "source" / (action_name + "_" + str(time).replace(".", "_") + ".png"))
    bpy.ops.render.render(write_still=True)
print("EXECUTIONER_BLENDER_RIG_OK bones=%d meshes=%d actions=%d fps=%d" % (len(BONES),len(PARTS),len(ACTIONS),FPS))
