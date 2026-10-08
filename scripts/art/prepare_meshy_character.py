"""Prepare Meshy's supplied rig without replacing any existing Overkill actor.

Run in Blender: blender -b --factory-startup --python this.py -- --input DIR --output DIR
Input GLBs are never modified. Generated source is fully packed and editable.
"""
import argparse
import copy
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector, Quaternion


def arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--render', action='store_true')
    return parser.parse_args(sys.argv[sys.argv.index('--') + 1:])


def read_glb(path):
    raw = path.read_bytes()
    assert raw[:4] == b'glTF' and struct.unpack_from('<I', raw, 4)[0] == 2
    assert struct.unpack_from('<I', raw, 8)[0] == len(raw)
    length = struct.unpack_from('<I', raw, 12)[0]
    return json.loads(raw[20:20 + length]), bytearray(raw[28 + length:])


def read_accessor(doc, binary, index):
    acc = doc['accessors'][index]
    view = doc['bufferViews'][acc['bufferView']]
    dtype = np.dtype({5126:'<f4', 5125:'<u4', 5123:'<u2', 5121:'u1'}[acc['componentType']])
    width = {'SCALAR':1, 'VEC2':2, 'VEC3':3, 'VEC4':4, 'MAT4':16}[acc['type']]
    return np.ndarray((acc['count'], width), dtype=dtype, buffer=binary,
        offset=view.get('byteOffset', 0) + acc.get('byteOffset', 0),
        strides=(view.get('byteStride', dtype.itemsize * width), dtype.itemsize)).copy()


def canonical_uv(doc, binary):
    primitive = doc['meshes'][0]['primitives'][0]
    uv = read_accessor(doc, binary, primitive['attributes']['TEXCOORD_0'])
    indices = read_accessor(doc, binary, primitive['indices']).reshape(-1)
    triangles = np.round(uv[indices].reshape(-1, 3, 2) * 100000).astype(np.int64)
    rows = np.stack([t[np.lexsort((t[:,1], t[:,0]))] for t in triangles]).reshape(-1, 6)
    return rows[np.lexsort(tuple(rows[:,k] for k in range(5, -1, -1)))]


def write_glb(path, doc, binary):
    binary.extend(b'\0' * (-len(binary) % 4))
    doc['buffers'] = [{'byteLength': len(binary)}]
    encoded = json.dumps(doc, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    path.write_bytes(struct.pack('<4sII', b'glTF', 2, 28 + len(encoded) + len(binary))
        + struct.pack('<II', len(encoded), 0x4E4F534A) + encoded
        + struct.pack('<II', len(binary), 0x004E4942) + binary)


def restore_materials(rig_path, remesh_path, output):
    doc, binary = read_glb(rig_path)
    remesh, remesh_binary = read_glb(remesh_path)
    assert np.array_equal(canonical_uv(doc, binary), canonical_uv(remesh, remesh_binary)), 'UV mismatch'
    originals = {key: copy.deepcopy(doc.get(key)) for key in ('meshes', 'skins', 'accessors', 'nodes', 'animations')}
    images = []
    for image in remesh['images']:
        view = remesh['bufferViews'][image['bufferView']]
        data = remesh_binary[view.get('byteOffset',0):view.get('byteOffset',0) + view['byteLength']]
        binary.extend(b'\0' * (-len(binary) % 4))
        new_image = copy.deepcopy(image)
        new_image['bufferView'] = len(doc['bufferViews'])
        doc['bufferViews'].append({'buffer':0, 'byteOffset':len(binary), 'byteLength':len(data)})
        binary.extend(data)
        images.append(new_image)
    doc['images'] = images
    for key in ('textures', 'samplers', 'materials'):
        if key in remesh:
            doc[key] = copy.deepcopy(remesh[key])
        else:
            doc.pop(key, None)
    doc['materials'][0]['name'] = 'Meshy restored leather cloth and bronze'
    # glTF material defaults metallic=1; the supplied packed map drives metallic/roughness.
    # The rig export's whole-body emission and out-of-range specular factor are removed.
    doc['extensionsUsed'] = [x for x in doc.get('extensionsUsed',[]) if x not in ('KHR_materials_specular','KHR_materials_ior')]
    for key, value in originals.items():
        assert doc.get(key) == value, 'Structural change during material restoration: ' + key
    write_glb(output, doc, binary)
    return {'uv_triangle_sets_match':True, 'rig_geometry_skin_animation_metadata_preserved':True,
        'restored_maps':['base_color', 'metallic_roughness'], 'normal_map':'Not transferred: original high-poly UV layout differs.'}


def action_curves(action):
    for layer in action.layers:
        for strip in layer.strips:
            for slot in action.slots:
                bag = strip.channelbag(slot)
                if bag:
                    yield from bag.fcurves


def clear_pose(arm):
    # Keep constraint drivers: animation_data_clear() also deletes IK drivers.
    if arm.animation_data:
        arm.animation_data.action = None
        for track in list(arm.animation_data.nla_tracks):arm.animation_data.nla_tracks.remove(track)
    for bone in arm.pose.bones:
        bone.location = (0,0,0)
        bone.rotation_mode = 'QUATERNION'
        bone.rotation_quaternion = (1,0,0,0)
        bone.scale = (1,1,1)
    bpy.context.view_layer.update()


def assign_action(arm, action):
    arm.animation_data_create()
    arm.animation_data.action = action
    if action.slots:
        arm.animation_data.action_slot = action.slots[0]


def add_controls(arm):
    collection = bpy.data.collections.new('Animator Controls - enable on armature')
    bpy.context.scene.collection.children.link(collection)
    arm['controls_enabled'] = 0.0
    arm.id_properties_ui('controls_enabled').update(min=0, max=1, description='0: baked animation; 1: arm/leg IK editing')
    controls = []
    for side in ('Left','Right'):
        for limb, end, middle in [('Arm','Hand','ForeArm'), ('Leg','Foot','Leg')]:
            end_bone = arm.pose.bones['mixamorig:' + side + end]
            mid_bone = arm.pose.bones['mixamorig:' + side + middle]
            target = bpy.data.objects.new('CTRL_' + side + end, None)
            target.empty_display_type = 'CUBE'
            target.empty_display_size = .055
            target.location = arm.matrix_world @ end_bone.head
            target.rotation_mode = 'QUATERNION'
            target.rotation_quaternion = (arm.matrix_world @ end_bone.matrix).to_quaternion()
            collection.objects.link(target)
            pole = bpy.data.objects.new('POLE_' + side + limb, None)
            pole.empty_display_type = 'SPHERE'
            pole.empty_display_size = .035
            pole.location = arm.matrix_world @ mid_bone.head
            pole.location.y += -.5 if limb == 'Leg' else .5
            collection.objects.link(pole)
            constraint = mid_bone.constraints.new('IK')
            constraint.name = 'Editable ' + side + limb + ' IK'
            constraint.target = target
            constraint.pole_target = pole
            constraint.chain_count = 2
            constraint.use_stretch = False
            constraint.influence = 0
            # Calibrate pole angle against the neutral elbow/knee position.
            expected = arm.matrix_world @ mid_bone.head
            constraint.influence = 1
            best = (float('inf'), 0)
            for step in range(72):
                angle = -math.pi + step * math.tau / 72
                constraint.pole_angle = angle
                bpy.context.view_layer.update()
                error = ((arm.matrix_world @ mid_bone.head) - expected).length
                if error < best[0]: best = (error, angle)
            constraint.pole_angle = best[1]
            constraint.influence = 0
            driver = constraint.driver_add('influence').driver
            driver.expression = 'enabled'
            var = driver.variables.new(); var.name = 'enabled'; var.type = 'SINGLE_PROP'
            var.targets[0].id = arm; var.targets[0].data_path = '["controls_enabled"]'
            if limb == 'Leg':
                foot_rotation = end_bone.constraints.new('COPY_ROTATION')
                foot_rotation.name = 'Plant ' + side + ' foot orientation'
                foot_rotation.target = target
                foot_rotation.influence = 0
                foot_driver = foot_rotation.driver_add('influence').driver
                foot_driver.expression = 'enabled'
                foot_var = foot_driver.variables.new();foot_var.name='enabled';foot_var.type='SINGLE_PROP'
                foot_var.targets[0].id=arm;foot_var.targets[0].data_path='["controls_enabled"]'
            controls.append({'target':target.name,'pole':pole.name,'neutral_pole_error_m':best[0]})
    return controls


def make_idle(arm):
    clear_pose(arm)
    action = bpy.data.actions.new('Idle')
    action.use_fake_user = True
    assign_action(arm, action)
    for frame in range(0, 91):
        phase = math.tau * frame / 90
        for name, axis, amplitude, offset in [
            ('Spine1',(1,0,0),.012,0), ('Spine2',(0,0,1),.012,.4),
            ('Head',(0,0,1),.018,.8), ('LeftShoulder',(0,1,0),.01,0),
            ('RightShoulder',(0,1,0),-.01,0)]:
            bone = arm.pose.bones['mixamorig:' + name]
            # Convert armature-space axis into the bone's rest basis.
            local_axis = bone.bone.matrix_local.to_3x3().inverted() @ Vector(axis)
            bone.rotation_quaternion = Quaternion(local_axis, amplitude * math.sin(phase + offset))
            bone.keyframe_insert('rotation_quaternion', frame=frame, group=bone.name)
    for curve in action_curves(action):
        for key in curve.keyframe_points: key.interpolation = 'LINEAR'
    clear_pose(arm)
    return action


def correct_locomotion_floor(arm, mesh):
    result={}
    for name in ('Walking','Running'):
        clear_pose(arm);action=bpy.data.actions[name];assign_action(arm,action)
        offsets=[];hips_positions=[]
        for frame in range(31):
            bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
            obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());evaluated=obj.to_mesh()
            coords=np.empty(len(evaluated.vertices)*3,dtype=np.float32);evaluated.vertices.foreach_get('co',coords)
            matrix=np.array(obj.matrix_world)
            xyz=coords.reshape(-1,3)@matrix[:3,:3].T+matrix[:3,3]
            offsets.append(max(0,.001-float(xyz[:,2].min())))
            hips_positions.append(arm.pose.bones['mixamorig:Hips'].location.copy())
            obj.to_mesh_clear()
        # A small conservative neighbourhood prevents inter-frame floor crossings.
        corrected=[max(offsets[max(0,i-1):min(31,i+2)]) for i in range(31)]
        path='pose.bones["mixamorig:Hips"].location'
        for layer in action.layers:
            for strip in layer.strips:
                for slot in action.slots:
                    bag=strip.channelbag(slot)
                    if bag:
                        for curve in list(bag.fcurves):
                            if curve.data_path==path:bag.fcurves.remove(curve)
        hips=arm.pose.bones['mixamorig:Hips']
        for frame,offset in enumerate(corrected):
            hips.location=hips_positions[frame]+hips.bone.matrix_local.to_3x3().inverted()@Vector((0,0,offset/arm.scale.z))
            hips.keyframe_insert('location',frame=frame,group=hips.name)
        for curve in action_curves(action):
            if curve.data_path==path:
                for key in curve.keyframe_points:key.interpolation='LINEAR'
        result[name]={'max_upward_correction_m':max(corrected),'modified_tracks':'Hips translation only; limb motion retained.'}
    clear_pose(arm)
    return result


def smooth_between(keys, time):
    for i in range(len(keys)-1):
        a, av = keys[i]; b, bv = keys[i+1]
        if time <= b:
            u=max(0,min(1,(time-a)/(b-a))); u=u*u*(3-2*u)
            return av+(bv-av)*u
    return keys[-1][1]


def bake_motion_study(arm, name, duration):
    """Bake evaluated IK to ordinary joint transforms; controls never ship as dependencies."""
    clear_pose(arm)
    arm['controls_enabled']=1.0;arm.update_tag();bpy.context.view_layer.update()
    base_targets={o.name:o.location.copy() for o in bpy.data.collections['Animator Controls - enable on armature'].objects}
    samples=[]
    for frame in range(round(duration*30)+1):
        time=frame/30
        for bone in arm.pose.bones:
            bone.location=(0,0,0);bone.rotation_quaternion=(1,0,0,0);bone.scale=(1,1,1)
        if name=='Jump_Down':
            # Straight drop from a 1.2m clock platform. No ground locomotion is baked.
            if time < .32: height=1.2
            elif time < .48: height=1.2+.12*math.sin((time-.32)/.16*math.pi/2)
            elif time < 1.02: height=1.32*(1-((time-.48)/.54)**2)
            else:height=0
            crouch=smooth_between([(0,0),(.25,.16),(.42,0),(.88,.045),(1.02,.02),(1.16,.19),(1.65,0),(1.8,0)],time)
            brace=smooth_between([(0,0),(.3,.2),(.55,.8),(.92,.9),(1.15,.55),(1.65,0),(1.8,0)],time)
        else:
            height=0
            brace=smooth_between([(0,0),(.32,1),(.8,1),(1.2,0)],time)
            crouch=.045*brace
        hips=arm.pose.bones['mixamorig:Hips']
        # World delta -> armature space -> bone rest-local delta.
        hips.location=hips.bone.matrix_local.to_3x3().inverted() @ Vector((0,0,(height-crouch)/arm.scale.z))
        for side,sign in [('Left',1),('Right',-1)]:
            foot=bpy.data.objects['CTRL_'+side+'Foot']
            foot.location=base_targets[foot.name]+Vector((0,0,height))
            hand=bpy.data.objects['CTRL_'+side+'Hand']
            base=base_targets[hand.name]
            wanted=Vector((sign*.20,-.29,1.28 if name=='Guard_Raise' else 1.13))
            hand.location=base.lerp(wanted,brace)+Vector((0,0,height-crouch*.5))
            for limb in ('Leg','Arm'):
                pole=bpy.data.objects['POLE_'+side+limb]
                pole.location=base_targets[pole.name]+Vector((0,0,height-crouch*.5))
        bpy.context.view_layer.update()
        evaluated=arm.evaluated_get(bpy.context.evaluated_depsgraph_get())
        poses={p.name:p.matrix.copy() for p in evaluated.pose.bones}
        bases={}
        for bone in arm.data.bones:
            if bone.parent:
                matrix=bone.matrix_local.inverted() @ bone.parent.matrix_local @ poses[bone.parent.name].inverted() @ poses[bone.name]
            else:matrix=bone.matrix_local.inverted() @ poses[bone.name]
            bases[bone.name]=matrix.decompose()
        samples.append(bases)
    arm['controls_enabled']=0.0;arm.update_tag()
    for key,value in base_targets.items():bpy.data.objects[key].location=value
    clear_pose(arm)
    action=bpy.data.actions.new(name);action.use_fake_user=True;assign_action(arm,action)
    previous={}
    for frame,bases in enumerate(samples):
        for name,(position,rotation,scale) in bases.items():
            bone=arm.pose.bones[name]
            if name in previous and rotation.dot(previous[name])<0:rotation.negate()
            previous[name]=rotation.copy()
            bone.location=position;bone.rotation_quaternion=rotation;bone.scale=scale
            for prop in ('location','rotation_quaternion','scale'):bone.keyframe_insert(prop,frame=frame,group=name)
    for curve in action_curves(action):
        for key in curve.keyframe_points:key.interpolation='LINEAR'
    clear_pose(arm)
    return action


def aim(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat('-Z','Y').to_euler()


def setup_studio(meshes):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 12
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 720; scene.render.resolution_y = 960
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.world = bpy.data.worlds.new('Gray studio')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (.16,.18,.21,1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = .45
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,-.012))
    floor = bpy.context.object; floor.name = 'REVIEW_Floor'
    material = bpy.data.materials.new('Studio matte gray'); material.diffuse_color = (.10,.115,.13,1)
    material.use_nodes = True
    material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = (.1,.115,.13,1)
    material.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value = .85
    floor.data.materials.append(material)
    for name, location, power, size, color in [
        ('Key',(-3,-4,4),600,4,(.86,.93,1)), ('Fill',(3,-2,2),240,3,(1,.90,.78)),
        ('Rim',(1,3,3),650,3,(.65,.82,1))]:
        light = bpy.data.lights.new('REVIEW_'+name,'AREA'); light.energy=power; light.shape='DISK';light.size=size;light.color=color
        obj = bpy.data.objects.new('REVIEW_'+name,light); scene.collection.objects.link(obj);obj.location=location;aim(obj,(0,0,1))
    camera = bpy.data.cameras.new('REVIEW_Camera')
    obj = bpy.data.objects.new('REVIEW_Camera',camera);scene.collection.objects.link(obj);scene.camera=obj
    camera.type='ORTHO';camera.ortho_scale=2.18
    obj.location=(0,-5,1.0);aim(obj,(0,0,.9))
    scene.view_settings.view_transform='AgX'
    return obj


def main():
    args=arguments(); output=args.output; output.mkdir(parents=True,exist_ok=True)
    source=output/'source';source.mkdir(exist_ok=True);(source/'.gdignore').write_text('')
    review=output/'review';review.mkdir(exist_ok=True);(review/'.gdignore').write_text('')
    rig_path=next(args.input.glob('*Rigge*.glb'));remesh_path=next(args.input.glob('*Remes*.glb'))
    manifest={'inputs':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in args.input.glob('*.glb')},
        'scope':'Editable Meshy preparation and deformation review; no live gameplay replacement.'}
    patched=source/'material_restored_original_rig.glb'
    manifest['material_repair']=restore_materials(rig_path,remesh_path,patched)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(patched))
    scene=bpy.context.scene;scene.render.fps=30;scene.render.fps_base=1
    arm=next(o for o in scene.objects if o.type=='ARMATURE');arm.name='Meshy_Executioner_Rig'
    meshes=[o for o in scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
    for obj in list(scene.objects):
        if obj != arm and obj not in meshes: obj.hide_render=True;obj.hide_set(True)
    clear_pose(arm)
    matrices={b.name:b.matrix_local.copy() for b in arm.data.bones}
    bpy.context.view_layer.objects.active=arm;arm.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for bone in arm.data.edit_bones:
        bone.use_connect = False
    for bone in arm.data.edit_bones:
        # glTF supplies joint transforms but no useful bone tails. Preserve orientation.
        bone.length = max(.8, min(40, bone.length * .01))
        if bone.name.endswith('Hand'): bone.length=12
        if bone.name.endswith('ToeBase'):bone.length=7
        if bone.name.endswith('Head'):bone.length=18
        if bone.name=='headfront':bone.length=4
        bone.matrix = matrices[bone.name]
    bpy.ops.object.mode_set(mode='OBJECT')
    matrix_error=max(max(abs(b.matrix_local[r][c]-matrices[b.name][r][c]) for r in range(4) for c in range(4)) for b in arm.data.bones)
    assert matrix_error < 1e-4, ('Rest orientation changed',matrix_error)
    manifest['bone_display_repair']={'rest_matrix_max_difference':matrix_error,'joint_count':len(arm.data.bones)}
    # Keep both supplied motion clips. The zero-duration source pose is not a motion clip.
    for action in list(bpy.data.actions):
        if action.name not in ('Walking','Running'):
            bpy.data.actions.remove(action)
            continue
        start,end=action.frame_range
        for curve in action_curves(action):
            for key in curve.keyframe_points:
                for co in (key.co,key.handle_left,key.handle_right):co.x=(co.x-start)*30/(end-start)
        action.use_fake_user=True
    manifest['locomotion_floor_correction']=correct_locomotion_floor(arm,meshes[0])
    manifest['controls']=add_controls(arm)
    make_idle(arm)
    bake_motion_study(arm,'Jump_Down',1.8)
    bake_motion_study(arm,'Guard_Raise',1.2)
    manifest['animations']=[{'name':a.name,'duration_seconds':(a.frame_range[1]-a.frame_range[0])/30} for a in bpy.data.actions]
    manifest['limits']=['No finger or cloth deformation bones added in this preparation pass.',
        'Jump_Down and Guard_Raise are initial motion studies, not final combat choreography.',
        'No attack or relic-specific interaction clips included yet.',
        'Normal map from high-poly source requires a separate bake.',
        'IK controls are for editing in Blender; export uses baked animation.']
    clear_pose(arm)
    # Pack all textures; source remains usable without a sibling texture directory.
    bpy.ops.file.pack_all()
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    for obj in meshes:obj.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.gltf(filepath=str(output/'meshy_character.glb'),export_format='GLB',
        use_selection=True,export_animations=True,export_animation_mode='ACTIONS',
        export_force_sampling=True,export_frame_range=False,export_skins=True,
        export_yup=True,export_extras=False)
    camera=setup_studio(meshes)
    assign_action(arm,bpy.data.actions['Idle']);scene.frame_set(0);scene.frame_start=0;scene.frame_end=90
    # Custom control objects are hidden from renders but accessible in their own collection.
    for obj in bpy.data.collections['Animator Controls - enable on armature'].objects:obj.hide_render=True
    bpy.ops.wm.save_as_mainfile(filepath=str(source/'meshy_character.blend'))
    if args.render:
        shots=[('front','Idle',0,(0,-5,1.0)),('three-quarter','Idle',0,(3,-5,1.0)),
            ('back','Idle',0,(0,5,1.0)),('walk-contact','Walking',0,(3,-5,1.0)),
            ('walk-passing','Walking',8,(3,-5,1.0)),('run-stride','Running',8,(3,-5,1.0)),
            ('landing-study','Jump_Down',35,(3,-5,1.0)),('guard-study','Guard_Raise',15,(3,-5,1.0))]
        for name,action,frame,position in shots:
            clear_pose(arm);assign_action(arm,bpy.data.actions[action]);scene.frame_set(frame)
            camera.location=position;aim(camera,(0,0,.9))
            scene.render.filepath=str(review/(name+'.png'));bpy.ops.render.render(write_still=True)
    (source/'manifest.json').write_text(json.dumps(manifest,indent=2))
    print('MESHY_PREPARATION_OK',json.dumps(manifest))


if __name__=='__main__':main()
