"""Blender authoring source for every battle relic's prop animation.

Run with Blender --background --python scripts/art/build_relic_choreography.py.
Each named action animates a six-bone prop rig. Blender evaluates its Bezier
curves at 60 fps, then writes the same samples used by Godot. The editable
.blend includes the rig, named actions, timing markers and textured prop mesh.
No combat numbers are authored here; the controller supplies actual outcomes.
"""
import bpy
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "assets/animations/relics"
SOURCE = DEST / "source"
SOURCE.mkdir(parents=True, exist_ok=True)
(SOURCE / ".gdignore").write_text("", encoding="utf-8")
FPS = 60
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.fps = FPS
scene["purpose"] = "Overkill relic choreography: editable skeletal actions, exported to Godot"
scene["coordinate_contract"] = "Bone X/Y in 100-pixel units; positive Y is screen-down at runtime"
arm_data = bpy.data.armatures.new("RelicArticulation")
arm = bpy.data.objects.new("RelicArticulation", arm_data)
scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
arm.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
for index, name in enumerate(("root", "prop", "secondary", "flow", "aura", "tether")):
    bone = arm_data.edit_bones.new(name)
    pivot_y = .84375 if name == "secondary" else 0
    bone.head = (0, pivot_y, 0)
    bone.tail = (0, pivot_y + .25 + index*.04, 0)
    if name != "root":
        bone.parent = arm_data.edit_bones["root"]
bpy.ops.object.mode_set(mode="OBJECT")
for pb in arm.pose.bones:
    pb.rotation_mode = "XYZ"
    pb["opacity"] = 1.0
arm.animation_data_create()

# The textured prop is a weighted quad, suitable for replacing with fully
# modelled geometry later without changing the six-bone animation contract.
mesh = bpy.data.meshes.new("RelicPreviewSurface")
mesh.from_pydata([(-.7,-.7,0),(.7,-.7,0),(.7,.7,0),(-.7,.7,0)], [], [(0,1,2,3)])
mesh.uv_layers.new(name="UVMap")
for li, uv in enumerate(((0,1),(1,1),(1,0),(0,0))):
    mesh.uv_layers.active.data[li].uv = uv
preview = bpy.data.objects.new("RelicPreview_WeightedToProp", mesh)
scene.collection.objects.link(preview)
group = preview.vertex_groups.new(name="prop")
group.add([0,1,2,3], 1.0, "REPLACE")
modifier = preview.modifiers.new("Skeletal deformation", "ARMATURE")
modifier.object = arm
material = bpy.data.materials.new("Canonical relic artwork")
material.use_nodes = True
tex = material.node_tree.nodes.new("ShaderNodeTexImage")
tex.image = bpy.data.images.load(str(ROOT / "assets/relics/active/rel_15_bastion_bell_object.png"))
tex.image.pack()
shader = material.node_tree.nodes.get("Principled BSDF")
material.node_tree.links.new(tex.outputs["Color"], shader.inputs["Base Color"])
material.node_tree.links.new(tex.outputs["Alpha"], shader.inputs["Alpha"])
preview.data.materials.append(material)
preview.hide_set(True)
preview.hide_render = True

def bell_mesh(label, bone, coords):
    data = bpy.data.meshes.new(label)
    data.from_pydata([((x-640)*.00125,(y-260)*.00125,0) for x,y in coords],[],[tuple(range(len(coords)))])
    data.uv_layers.new(name="Canonical art UV")
    for loop in data.loops:
        x,y=coords[loop.vertex_index]
        data.uv_layers.active.data[loop.index].uv=(x/1280,1-y/1280)
    obj=bpy.data.objects.new(label,data)
    scene.collection.objects.link(obj)
    obj.data.materials.append(material)
    obj.vertex_groups.new(name=bone).add(list(range(len(coords))),1.0,"REPLACE")
    obj.modifiers.new("Articulated bell weighting","ARMATURE").object=arm
    return obj

# The editable showcase is a genuine layered, weighted bell. Hanger, shell,
# rim and clapper are the same UV pieces animated by the Godot prop rig.
bell_mesh("Bell.Shell","prop",[(630,250),(783,320),(891,558),(1135,974),(1068,1033),(878,978),(601,932),(375,956),(198,1030),(166,1002),(389,509),(468,320)])
bell_mesh("Bell.Rim","prop",[(166,1002),(224,1134),(428,1210),(686,1242),(979,1178),(1146,1087),(1135,974),(1097,1080),(938,1140),(697,1175),(432,1154),(249,1090)])
bell_mesh("Bell.Clapper","secondary",[(576,935),(660,935),(688,1000),(730,1070),(689,1177),(620,1233),(573,1180),(508,1065),(535,991)])
bell_mesh("Bell.Yoke","root",[(102,8),(1110,8),(1188,352),(830,330),(670,252),(450,300),(112,325)])

def key(bone, t, x=0, y=0, angle=0, sx=1, sy=None, opacity=1):
    """Key a real pose bone, including its opacity custom channel."""
    pb = arm.pose.bones[bone]
    pb.location = (x / 100, y / 100, 0)
    pb.rotation_euler = (0, 0, angle)
    pb.scale = (sx, sx if sy is None else sy, 1)
    pb["opacity"] = float(opacity)
    frame = t * FPS + 1
    for path in ("location", "rotation_euler", "scale", '["opacity"]'):
        pb.keyframe_insert(data_path=path, frame=frame, group=bone)

def envelope(bone, end, contact, scale=1):
    key(bone, 0, sx=0.02, opacity=0)
    key(bone, max(.05, contact-.05), sx=.02, opacity=0)
    key(bone, contact+.18, sx=scale, opacity=.95)
    key(bone, min(end-.18,contact+.5), sx=scale*1.1, opacity=.8)
    key(bone, end, sx=scale*1.2, opacity=0)

def appearance(end, size=1):
    key("prop",0,sx=.1,opacity=0)
    key("prop",.28,sx=size,opacity=1)
    key("prop",end,sx=size*.9,opacity=0)

ROSTER = [
 (1,"iron_strike","sword","hand",2.2,3.1,"iron_strike"),
 (2,"twin_blades","blades","hand",2.2,3.1,"twin_right"),
 (3,"heavy_hammer","hammer","hand",2.2,3.3,"heavy"),
 (4,"guard_plate","guard","body",1.1,2.1,"block"),
 (5,"spiked_buckler","thorns","body",1.1,2.25,"block"),
 (6,"reinforced_wall","wall","body",1.1,2.25,"block"),
 (7,"rusting_spike","needle","hand",.95,1.7,"throw"),
 (8,"momentum_spring","spring","body",1.7,2.55,"crown"),
 (9,"corrosive_oil","oil","head",2.4,3.2,"channel"),
 (10,"kinetic_battery","battery","body",1.1,2.25,"block"),
 (11,"execution_wedge","wedge","hand",2.2,3.3,"heavy"),
 (12,"recoil_piston","piston","hand",.95,1.7,"throw"),
 (13,"vital_siphon","siphon","hand",.95,3.5,"siphon"),
 (14,"overdrive_piston","piston","hand",.95,2.0,"piston"),
 (15,"bastion_bell","bell","head",2.5,3.6,"bell"),
 (16,"war_crown","crown","head",1.7,2.6,"crown"),
 (17,"withering_censer","censer","head",2.4,3.25,"channel"),
 (18,"blood_tithe","tithe","body",1.7,2.6,"crown"),
 (19,"butchers_abacus","abacus","hand",.95,1.75,"throw"),
 (20,"crimson_reservoir","reservoir","body",1.1,2.35,"block"),
 (21,"hex_bloom","bloom","head",1.7,2.65,"crown"),
 (22,"miasma_ward","ward","body",1.1,2.35,"block"),
 (23,"rupture_needle","needle","hand",.95,1.7,"throw"),
 (24,"siege_prism","prism","hand",.95,1.85,"throw"),
 (25,"oath_chalice","chalice","head",2.4,3.35,"chalice"),
 (26,"debt_leech","leech","head",2.4,3.3,"channel"),
 (27,"last_bell","bell","head",2.5,3.6,"bell"),
 (28,"debt_crown","siphon","hand",.95,2.65,"throw"),
 (29,"zenith_prism","prism","hand",.95,1.85,"throw"),
]

# Each relic now has its own named, textured, weighted source mesh, rather
# than sharing a hidden bell-textured stand-in. Rigid objects use rigid bone
# weights; only the bell joints and flexible energy conduit articulate.
model_manifest = {}
for number,label,kind,anchor,contact,duration,actor_action in ROSTER:
    art_number = 1 if kind == "blades" else number
    texture_path = next((ROOT / "assets/relics/active").glob(f"rel_{art_number:02d}_*.png"))
    texture = bpy.data.images.load(str(texture_path),check_existing=True)
    texture.pack()
    w,h=texture.size
    grip=(1000/w,990/h) if kind in ("sword","blades") else ((.5,.8) if kind=="hammer" else (.5,.5))
    art_rotation=.72 if kind in ("sword","blades") else 0
    collection=bpy.data.collections.new(f"REL-{number:02d}.{label}")
    scene.collection.children.link(collection)
    for hand,bone in (("primary","prop"),("left","secondary")) if kind=="blades" else (("primary","prop"),):
        width=158 if kind in ("sword","blades","hammer","wedge") else 128
        scale=width/max(w,h)/100
        coords=[]
        for u,v in ((0,0),(1,0),(1,1),(0,1)):
            x,y=(u-grip[0])*w*scale,(v-grip[1])*h*scale
            coords.append((x*math.cos(art_rotation)-y*math.sin(art_rotation),x*math.sin(art_rotation)+y*math.cos(art_rotation)+(.84375 if bone=="secondary" else 0),0))
        mesh=bpy.data.meshes.new(f"REL-{number:02d}.{hand}.grip_mesh")
        mesh.from_pydata(coords,[],[(0,1,2,3)])
        mesh.uv_layers.new(name="CanonicalArtwork")
        for li,uv in enumerate(((0,1),(1,1),(1,0),(0,0))): mesh.uv_layers.active.data[li].uv=uv
        obj=bpy.data.objects.new(mesh.name,mesh)
        collection.objects.link(obj)
        mat=bpy.data.materials.new(f"REL-{number:02d}.artwork.{hand}")
        mat.use_nodes=True
        nodes=mat.node_tree.nodes; nodes.clear()
        tex=nodes.new("ShaderNodeTexImage");tex.image=texture
        emission=nodes.new("ShaderNodeEmission")
        transparent=nodes.new("ShaderNodeBsdfTransparent")
        mix=nodes.new("ShaderNodeMixShader");output=nodes.new("ShaderNodeOutputMaterial")
        links=mat.node_tree.links
        links.new(tex.outputs["Color"],emission.inputs["Color"])
        links.new(tex.outputs["Alpha"],mix.inputs[0])
        links.new(transparent.outputs[0],mix.inputs[1]);links.new(emission.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],output.inputs[0])
        mesh.materials.append(mat)
        obj.vertex_groups.new(name=bone).add([0,1,2,3],1,"REPLACE")
        obj.modifiers.new("Rigid relic bone attachment","ARMATURE").object=arm
        obj["grip_uv"]=grip;obj["runtime_role"]=hand
        obj.hide_render=True;obj.hide_set(True)
    model_manifest[f"REL-{number:02d}"]={"texture":texture_path.name,"grip_uv":grip,"sprite_rotation":art_rotation,"collection":collection.name}
review=bpy.data.texts.new("REVIEW_RELIC.py")
review.write("# Set relic_id and run this text in Blender to review its correct mesh/action.\nimport bpy\nrelic_id='REL-01'\nfor c in bpy.data.collections:\n if c.name.startswith('REL-'):\n  for o in c.objects: o.hide_set(not c.name.startswith(relic_id+'.')); o.hide_render=not c.name.startswith(relic_id+'.')\nrig=bpy.data.objects['RelicArticulation']\nrig.animation_data.action=next(a for a in bpy.data.actions if a.name.startswith(relic_id+'_'))\nfor o in bpy.data.objects:\n if o.name.startswith('Bell.'): o.hide_set(relic_id!='REL-15'); o.hide_render=relic_id!='REL-15'\nbpy.context.scene.frame_end=round(rig.animation_data.action['duration_seconds']*bpy.context.scene.render.fps)+1\n")

export = {"schema":1,"fps":FPS,"authoring":"Blender 5.2 / six-bone pose actions","clips":{}}
for number, name, model, anchor, contact, end, actor_action in ROSTER:
    action = bpy.data.actions.new(f"REL-{number:02d}_{name}")
    action.use_fake_user = True
    arm.animation_data.action = action
    for pb in arm.pose.bones:
        pb.location=(0,0,0); pb.rotation_euler=(0,0,0); pb.scale=(1,1,1); pb["opacity"]=0.0
    for bone in ("prop","secondary","flow","aura","tether"):
        key(bone,0,opacity=0)
        key(bone,end,opacity=0)
    if model not in ("sword", "bell", "chalice", "crown", "hammer", "wedge"):
        appearance(end)
    if model in ("sword", "blades"):
        # Calibrate each weapon's painted hilt-to-tip axis to its own wrist.
        # The editable Blender track therefore crosses the enemy at contact.
        rig_text = (ROOT / "assets/characters/executioner/rigged/rig_data.gd").read_text(encoding="utf-8")
        rig_data = json.loads(rig_text.split("const DATA: Dictionary = ",1)[1])
        def wrist_rotation(action_name, side):
            frame = rig_data["actions"][action_name]["frames"][round(contact*FPS)]
            names = [b["name"] for b in rig_data["bones"]]
            return sum(frame[names.index(b)][2] for b in ("root","pelvis","spine","clavicle_"+side,"arm_"+side,"forearm_"+side,"hand_"+side))
        grip_angle = -math.atan2(65-990,110-1000)-.72
        contact_angle = grip_angle - wrist_rotation(actor_action,"near")
        key("prop",0,y=-55,angle=-.72,sx=.08,opacity=0)
        key("prop",.35,y=-55,angle=-.72,sx=.45,opacity=.3)
        key("prop",1.15,y=-55,angle=-.72,sx=.86,opacity=.85)
        key("prop",1.5,y=-55,angle=-.72,sx=1,opacity=1)
        key("prop",1.88,y=-65,angle=-1.1,sx=1,opacity=1)
        key("prop",contact,y=-50,angle=contact_angle,sx=1,opacity=1)
        key("prop",contact+.12,y=-50,angle=contact_angle,sx=1,opacity=1)
        if model == "blades":
            left_contact = grip_angle - wrist_rotation("twin_left","far")
            for time,angle in ((0,-.72),(1.5,-.72),(1.88,-1.1),(contact,left_contact),(contact+.12,left_contact),(end-.2,.4),(end,.4)):
                key("secondary",time,angle=angle,opacity=1)
        key("prop",end-.2,y=-50,angle=.4,sx=1,opacity=.8)
        key("prop",end,y=-50,angle=.4,sx=.7,opacity=0)
    elif model in ("hammer","wedge"):
        key("prop",.35,y=-48,angle=-.9,opacity=1)
        key("prop",1.7,y=-80,angle=-1.6,opacity=1)
        key("prop",contact,y=-30,angle=.9,opacity=1)
        key("prop",end-.25,y=-30,angle=.9,opacity=1)
        key("prop",end,y=-30,angle=.9,opacity=0)
    elif model == "bell":
        # Half-second emergence, then exactly two seconds of bell-body swings.
        key("prop",.35,y=-103,opacity=1)
        for t, angle in ((.5,0),(.75,-.24),(1.08,.24),(1.41,-.21),(1.74,.18),(2.07,-.12),(2.5,0)):
            key("prop",t,y=-103,angle=angle,opacity=1)
            key("secondary",t,y=-103,angle=-angle*1.9,opacity=1)
        key("prop",end-.3,y=-103,opacity=.5)
        key("prop",end,y=-103,opacity=0)
        envelope("aura",end,contact)
    elif model == "chalice":
        key("prop",.3,y=-90,opacity=1)
        key("prop",.75,y=-90,opacity=1)
        key("prop",1.2,x=96,y=-63,angle=-.9,opacity=1)
        key("prop",2.35,x=96,y=-63,angle=-.9,opacity=1)
        key("prop",end-.3,x=96,y=-63,angle=-.9,opacity=.8)
        key("prop",end,x=96,y=-63,angle=-.9,opacity=0)
        key("flow",.95,opacity=0)
        key("flow",1.3,x=1,sx=1,opacity=1)
        key("flow",2.4,x=100,sx=1,opacity=1)
        key("flow",2.75,x=100,sx=1,opacity=0)
        envelope("aura",end,2.15)
    elif model == "crown":
        key("prop",.3,y=-70,sx=1.12,opacity=1)
        key("prop",.85,y=-32,sx=1,opacity=1)
        key("prop",1.7,y=-32,sx=1,opacity=1)
        key("prop",end-.3,y=-32,sx=1,opacity=.8)
        key("prop",end,y=-32,sx=1,opacity=0)
        envelope("aura",end,1.25)
    elif model == "guard":
        # Basic Block deliberately has no flying object, only authored aura.
        for t in (0,.28,end-.35,end): key("prop",t,opacity=0)
        envelope("aura",end,.65)
    elif anchor == "hand":
        key("prop",.2,angle=-.25,sx=.75,opacity=1)
        key("prop",.55,angle=-.55,sx=1,opacity=1)
        key("prop",contact,angle=.6,sx=1,opacity=1)
        key("prop",end-.3,angle=.6,sx=1,opacity=.8)
        key("prop",end,angle=.6,sx=1,opacity=0)
        key("flow",0,x=0,opacity=0)
        key("flow",.76,x=0,opacity=1)
        key("flow",contact,x=100,opacity=1)
        key("flow",end,x=100,opacity=1)
        if model == "siphon":
            # One green life mass traverses the full purple tube over 1.8s.
            key("secondary",contact+.55,x=0,sx=.1,opacity=0)
            key("secondary",contact+.68,x=0,sx=1,opacity=1)
            key("secondary",end-.85,x=100,sx=1,opacity=1)
            key("secondary",end-.65,x=100,sx=.15,opacity=0)
            key("tether",contact,x=0,opacity=0)
            key("tether",contact+.45,x=100,opacity=1)
            key("tether",end-.35,x=100,opacity=1)
            key("tether",end,x=100,opacity=0)
            envelope("aura",end,end-.85 if number == 13 else contact+1.05,.9)
        elif model in ("prism",): envelope("aura",end,contact)
    elif model in ("oil","censer","leech"):
        key("prop",.35,y=-60,angle=-.15,opacity=1)
        key("prop",1.1,x=35,y=-60,angle=.4,opacity=1)
        key("prop",1.7,x=-25,y=-60,angle=-.4,opacity=1)
        key("prop",contact,x=20,y=-55,angle=.3,opacity=1)
        key("prop",end-.3,x=20,y=-55,angle=.3,opacity=.8)
        key("prop",end,x=20,y=-55,angle=.3,opacity=0)
        key("flow",.9,x=0,opacity=0)
        key("flow",1.2,x=0,opacity=1)
        key("flow",contact,x=100,opacity=1)
        key("flow",end,x=100,opacity=0)
    else:
        # Separate compression/expansion keyed bones for wards, batteries,
        # springs and bloom; no universal icon-flight fallback.
        key("prop",.25,sx=.8,opacity=1)
        key("prop",contact*.55,sx=1.03,sy=.62 if model=="spring" else 1.03,angle=-.1,opacity=1)
        key("prop",contact,sx=1.15,sy=1.4 if model=="spring" else 1.15,angle=.1,opacity=1)
        key("prop",end-.3,sx=1.15,sy=1.4 if model=="spring" else 1.15,angle=.1,opacity=.8)
        envelope("aura",end,contact-.25)
    # Ensure Blender's interpolation remains editable and non-overshooting.
    for slot in action.slots:
        for layer in action.layers:
            for strip in layer.strips:
                bag = strip.channelbag(slot)
                if bag:
                    for fc in bag.fcurves:
                        for point in fc.keyframe_points:
                            point.interpolation="BEZIER"
                            point.handle_left_type="AUTO_CLAMPED"
                            point.handle_right_type="AUTO_CLAMPED"
    tracks = {bone:[] for bone in ("prop","secondary","flow","aura","tether")}
    for frame in range(math.ceil(end*FPS)+1):
        scene.frame_set(frame+1)
        for name_bone, samples in tracks.items():
            pb=arm.pose.bones[name_bone]
            samples.append([round(float(v),5) for v in (pb.location.x*100,pb.location.y*100,pb.rotation_euler.z,pb.scale.x,pb.scale.y,pb["opacity"])])
    export["clips"][f"REL-{number:02d}"]={"action":action.name,"model":model,"anchor":anchor,"contact":contact,"duration":end,"release":.76 if anchor=="hand" and model not in ("sword","blades","hammer","wedge") else -1,"actor_action":actor_action,"grip_uv":model_manifest[f"REL-{number:02d}"]["grip_uv"],"sprite_rotation":model_manifest[f"REL-{number:02d}"]["sprite_rotation"],"transfer_start":contact+.68,"transfer_end":end-.85,"tracks":tracks}
    action["contact_seconds"]=contact
    action["duration_seconds"]=end
    action["runtime_model"]=model

scene.frame_start=1
scene.frame_end=max(math.ceil(row[5]*FPS)+1 for row in ROSTER)
scene.timeline_markers.new("Iron sword fully materialised 1.5s",frame=round(1.5*FPS)+1)
scene.timeline_markers.new("Iron strike contact 2.2s",frame=round(2.2*FPS)+1)
scene.timeline_markers.new("Bell completes two second swing",frame=round(2.5*FPS)+1)
scene.frame_set(round(1.1*FPS)+1)
arm.animation_data.action=bpy.data.actions["REL-15_bastion_bell"]
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "relic_choreography.blend"))
(DEST / "relic_tracks.gd").write_text("# Generated by Blender. Edit scripts/art/build_relic_choreography.py, then regenerate.\nextends RefCounted\nconst DATA: Dictionary = "+json.dumps(export,separators=(",",":"))+"\n",encoding="utf-8")
(SOURCE / "manifest.json").write_text(json.dumps({"blender":bpy.app.version_string,"actions":list(export["clips"]),"bone_count":len(arm.pose.bones),"fps":FPS,"source":"scripts/art/build_relic_choreography.py","models":model_manifest},indent=2),encoding="utf-8")
print("RELIC_CHOREOGRAPHY_OK actions=29 bones=6 fps=60")
