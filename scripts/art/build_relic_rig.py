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
FPS = 30
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
    nx, ny = 4, 7
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
                value = {bone_name: 1.0}
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

def leg_pose(drop=0.0):
    """Two-bone solve keeps both boot soles on the floor during anticipation."""
    values = {"root": (0, 0, drop)}
    for side, sign in [("near", 1), ("far", -1)]:
        h = HEADS["thigh_" + side] + Vector((0, drop))
        k0, a0 = HEADS["shin_" + side], HEADS["foot_" + side]
        v1 = k0 - HEADS["thigh_" + side]
        v2 = a0 - k0
        distance = (a0 - h).length
        l1, l2 = v1.length, v2.length
        theta = math.atan2((a0 - h).y, (a0 - h).x)
        alpha = math.acos(max(-1, min(1, (l1*l1 + distance*distance - l2*l2) / (2*l1*distance))))
        desired1 = theta - sign * alpha
        knee = h + Vector((math.cos(desired1), math.sin(desired1))) * l1
        desired2 = math.atan2((a0-knee).y, (a0-knee).x)
        r1 = desired1 - math.atan2(v1.y, v1.x)
        r2 = desired2 - math.atan2(v2.y, v2.x) - r1
        # Normalise so a nearly straight rear leg never turns through 360°.
        r1 = math.atan2(math.sin(r1), math.cos(r1))
        r2 = math.atan2(math.sin(r2), math.cos(r2))
        values["thigh_"+side] = (math.degrees(r1),)
        values["shin_"+side] = (math.degrees(r2),)
        values["foot_"+side] = (-math.degrees(r1+r2),)
    return values

def pose(drop=0, **kwargs):
    result = leg_pose(drop) if drop else {}
    for name, value in kwargs.items():
        result[name] = value if isinstance(value, tuple) else (value,)
    return result

# Times are literal seconds at normal animation speed. Each pose is authored in
# Blender as transform keyframes, interpolated there, then sampled for Godot.
ACTIONS = {
    "idle": (3.2, -1, [
        (0, pose()), (0.8, pose(spine=-1.3, head=1.1, arm_near=-1.8, forearm_near=2.5, cloak_lower=2.8)),
        (1.6, pose(spine=0.5, head=-1.2, arm_far=1.5, hand_near=-2, cloak_lower=-1.8)),
        (2.4, pose(spine=1, head=-0.5, forearm_far=-1.5, cloak_upper=-1.5)), (3.2, pose())]),
    "iron_strike": (3.1, 2.2, [
        (0, pose()), (0.35, pose(arm_near=-18, forearm_near=-48, hand_near=-9, head=3)),
        (1.3, pose(arm_near=-22, forearm_near=-55, hand_near=-12, spine=-3)),
        (1.5, pose(drop=12, arm_near=22, forearm_near=-103, head=7, spine=-7, cloak_lower=-7)),
        (1.85, pose(drop=40, arm_near=69, forearm_near=-117, arm_far=22, spine=-12, head=13, cloak_lower=-12)),
        (2.05, pose(root=(0, 174, -16), thigh_near=-34, shin_near=37, foot_near=-3, thigh_far=35, shin_far=-35, arm_near=-65, forearm_near=-22, spine=12, head=-8, cloak_lower=-24)),
        (2.2, pose(root=(0, 226, 3), thigh_near=-23, shin_near=26, foot_near=-3, thigh_far=38, shin_far=-34, arm_near=-78, forearm_near=61, hand_near=17, spine=15, head=-10, cloak_lower=-29)),
        (2.42, pose(root=(0, 226, 5), thigh_near=-18, shin_near=22, foot_near=-4, thigh_far=32, shin_far=-30, arm_near=-48, forearm_near=42, spine=9, cloak_lower=-15)),
        (2.78, pose(drop=13, arm_near=-14, forearm_near=20, spine=1, cloak_lower=14)), (3.1, pose())]),
    "throw": (1.7, 0.95, [
        (0, pose()), (0.24, pose(arm_near=-23, forearm_near=-53, head=3)),
        (0.55, pose(drop=17, spine=-10, arm_near=76, forearm_near=-112, hand_near=-23, head=8, cloak_lower=-9)),
        (0.77, pose(drop=7, spine=11, arm_near=-91, forearm_near=26, hand_near=18, head=-7, arm_far=13)),
        (0.95, pose(drop=5, spine=8, arm_near=-87, forearm_near=25, hand_near=9, head=-5)),
        (1.28, pose(arm_near=-34, forearm_near=-7, spine=2, cloak_lower=8)), (1.7, pose())]),
    "channel": (2.7, 2.4, [
        (0, pose()), (0.5, pose(arm_near=-39, forearm_near=-34, arm_far=28, forearm_far=40, head=-6, spine=-2)),
        (1.25, pose(arm_near=-46, forearm_near=-37, arm_far=33, forearm_far=46, head=-8, spine=-4, cloak_lower=6)),
        (2.15, pose(arm_near=-41, forearm_near=-33, arm_far=29, forearm_far=43, head=-6, spine=-3)),
        (2.4, pose(spine=-1, head=-3, arm_near=-17, forearm_near=-22)), (2.7, pose())]),
    "crown": (2.1, 1.7, [
        (0, pose()), (0.4, pose(head=6, spine=4, arm_near=-12, forearm_near=-18)),
        (1.0, pose(head=-9, spine=-5, arm_near=-30, forearm_near=-15, arm_far=21, forearm_far=12)),
        (1.7, pose(head=-5, spine=-2, arm_near=-20, forearm_near=-12)), (2.1, pose())]),
    "bell": (3.0, 2.5, [
        (0, pose()), (0.4, pose(drop=8, arm_near=-52, forearm_near=-53, arm_far=41, forearm_far=49, head=-4)),
        (0.85, pose(drop=9, arm_near=-55, forearm_near=-56, arm_far=44, forearm_far=51, head=-7, spine=2)),
        (1.3, pose(drop=8, arm_near=-52, forearm_near=-53, arm_far=41, forearm_far=49, head=-4, spine=-2)),
        (1.8, pose(drop=10, arm_near=-55, forearm_near=-56, arm_far=44, forearm_far=51, head=-7, spine=2)),
        (2.25, pose(drop=8, arm_near=-52, forearm_near=-53, arm_far=41, forearm_far=49, head=-4, spine=-2)),
        (2.5, pose(drop=14, arm_near=-22, forearm_near=-68, arm_far=19, forearm_far=53, spine=-3)), (3.0, pose())]),
    "block": (1.8, 1.1, [
        (0, pose()), (0.4, pose(drop=18, arm_near=-39, forearm_near=-72, arm_far=21, forearm_far=65, head=4, spine=-6)),
        (1.1, pose(drop=16, arm_near=-36, forearm_near=-69, arm_far=19, forearm_far=61, head=3, spine=-5)),
        (1.4, pose(drop=8, arm_near=-20, forearm_near=-30, arm_far=8, forearm_far=21)), (1.8, pose())]),
    "hit": (0.55, -1, [(0, pose()), (0.12, pose(drop=10, spine=-13, head=-11, arm_near=13, forearm_near=-17, cloak_lower=11)), (0.32, pose(drop=5, spine=-6, head=-3)), (0.55, pose())]),
    "guard_hit": (0.5, -1, [(0, pose()), (0.1, pose(drop=13, spine=-8, arm_near=-31, forearm_near=-75, arm_far=16, forearm_far=61)), (0.3, pose(drop=5, spine=-3, arm_near=-19, forearm_near=-40)), (0.5, pose())]),
    "fall": (1.1, -1, [(0, pose()), (0.35, pose(drop=37, spine=17, head=12, arm_near=28, forearm_near=-35)), (1.1, pose(drop=77, spine=35, head=20, arm_near=14, forearm_near=-28, cloak_lower=11))]),
}
# Heavy weapon is a distinct slower armature action with a planted overhead
# anticipation, while keeping the same contact convention as Iron Strike.
ACTIONS["heavy"] = (3.3, 2.2, [
    (0, pose()), (0.5, pose(arm_near=-102, forearm_near=-66, arm_far=77, forearm_far=63, spine=-6, head=-5)),
    (1.4, pose(drop=18, arm_near=-123, forearm_near=-68, arm_far=89, forearm_far=58, spine=-13, head=-8)),
    (1.85, pose(drop=39, arm_near=-124, forearm_near=-66, arm_far=83, forearm_far=59, spine=-10)),
    (2.2, pose(root=(0, 160, 15), thigh_near=-27, shin_near=39, thigh_far=25, shin_far=-20, arm_near=-30, forearm_near=-12, spine=24, head=-12, cloak_lower=-23)),
    (2.5, pose(root=(0,160,15), thigh_near=-23, shin_near=32, thigh_far=24, shin_far=-20, arm_near=-27, forearm_near=-10, spine=18)),
    (2.9, pose(drop=14, spine=5, arm_near=-20, forearm_near=-9)), (3.3, pose())])

rig.animation_data_create()
animation_records = {}
for action_name, (duration, contact, poses) in ACTIONS.items():
    action = bpy.data.actions.new(action_name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for time, pose_values in poses:
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
                            point.interpolation = "BEZIER"
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

record = {"format": "overkill_blender_skin_v1", "fps": FPS,
          "authoring": "Blender armature modifier; 18 bones; weighted 16-part painted cutout meshes",
          "atlas_size": [aw, ah], "bounds": [-128, -484, 264, 489],
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
scene.frame_end = 97
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "source/executioner_relic_rig.blend"))
review_poses = [] if "--skip-renders" in sys.argv else [("idle",0), ("iron_strike",1.85), ("iron_strike",2.2), ("throw",0.55), ("throw",0.95), ("block",0.65)]
for action_name, time in review_poses:
    rig.animation_data.action = bpy.data.actions[action_name]
    scene.frame_set(round(time * FPS) + 1)
    camera.location.x = rig.pose.bones["root"].matrix.translation.x + 15
    scene.render.filepath = str(OUT / "source" / (action_name + "_" + str(time).replace(".", "_") + ".png"))
    bpy.ops.render.render(write_still=True)
print("EXECUTIONER_BLENDER_RIG_OK bones=%d meshes=%d actions=%d fps=%d" % (len(BONES),len(PARTS),len(ACTIONS),FPS))
