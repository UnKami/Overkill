"""Bake aligned painted detail onto the existing closed, skinned character.

No silhouette geometry is constructed from the picture. Visible neutral-pose
surfaces receive projected paint; hidden surfaces retain their original material.
Four packed maps preserve diffuse color, roughness/metal, emission and normal relief.
The baked model is the live character; the unpainted source drives its animation.
"""
from pathlib import Path
import bpy, json, sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/characters/executioner/three_d'
SRC=OUT/'source'; MATERIALS=OUT/'materials'
AUTHORED_SURFACES=('Antique warm bronze','Worn brass edges','Recessed faceless obsidian',
                   'Inlaid cyan fracture','Inlaid amber fracture',
                   'Supple charcoal leather undersuit','Scuffed charcoal boot leather')
PROJECTION_EXCLUSIONS=['woven cloth','Reference etched aged armor','Reference engraved coat panels',*AUTHORED_SURFACES]
ATLAS_SIZE=4096
def export_runtime(objects,rig):
    # Godot's runtime materials use two UV sets. The study source retains
    # projection/source UVs for editing, but export needs only the baked map.
    for obj in objects:
        for name in [uv.name for uv in obj.data.uv_layers]:
            if name!='Executioner baked atlas':obj.data.uv_layers.remove(obj.data.uv_layers[name])
        obj.data.uv_layers.active=obj.data.uv_layers[0];obj.data.uv_layers[0].active_render=True
    human=bpy.data.objects['Tailored articulated leather body']
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        if obj!=human:obj.select_set(True)
    bpy.context.view_layer.objects.active=next(o for o in objects if o!=human)
    bpy.ops.object.join();wardrobe=bpy.context.view_layer.objects.active;wardrobe.name='Executioner painted wardrobe'
    bpy.ops.object.select_all(action='DESELECT')
    for obj in (rig,human,wardrobe):obj.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/'executioner_painted.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_skins=True,export_apply=False,export_animation_mode='ACTIONS',export_force_sampling=True)
if '--refresh-animation' in sys.argv:
    # Reuse the validated atlas only when topology, weights and bind skeleton
    # are identical. Otherwise a full material bake is required.
    bpy.ops.wm.open_mainfile(filepath=str(SRC/'executioner_human_3d.blend'))
    base_rig=bpy.data.objects['ExecutionerRig']
    source={o.name:[(tuple(v.co),sorted((o.vertex_groups[g.group].name,g.weight) for g in v.groups)) for v in o.data.vertices] for o in bpy.data.objects if o.type=='MESH' and o.parent==base_rig}
    bone_rest={b.name:tuple(value for row in b.matrix_local for value in row) for b in base_rig.data.bones}
    bpy.ops.wm.open_mainfile(filepath=str(SRC/'executioner_painted_materials.blend'))
    rig=bpy.data.objects['ExecutionerRig']
    objects=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==rig]
    assert {o.name for o in objects}==set(source),'Geometry components changed; rebake materials'
    for obj in objects:
        current=[(tuple(v.co),sorted((obj.vertex_groups[g.group].name,g.weight) for g in v.groups)) for v in obj.data.vertices]
        assert current==source[obj.name],'Geometry or weights changed; rebake '+obj.name
    assert bone_rest=={b.name:tuple(value for row in b.matrix_local for value in row) for b in rig.data.bones},'Bind skeleton changed; rebake materials'
    rig.animation_data.action=None
    for action in list(bpy.data.actions):bpy.data.actions.remove(action)
    with bpy.data.libraries.load(str(SRC/'executioner_human_3d.blend'),link=False) as (available,loaded):
        loaded.actions=list(available.actions)
    assert len(loaded.actions)==16,'Refresh all authored actions'
    for action in loaded.actions:action.use_fake_user=True
    rig.animation_data.action=bpy.data.actions['idle'];rig['controls_enabled']=0
    bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
    bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'executioner_painted_materials.blend'))
    export_runtime(objects,rig)
    manifest=json.loads((SRC/'painted_material_manifest.json').read_text())
    manifest['animation_refresh']='All 16 actions copied from matching geometry, weights and bind skeleton'
    manifest['projection_excluded_surfaces']=PROJECTION_EXCLUSIONS
    (SRC/'painted_material_manifest.json').write_text(json.dumps(manifest,indent=2))
    print('EXECUTIONER_PAINTED_ANIMATION_REFRESH_OK exact geometry/skin/rest; 16 actions; retained PBR maps')
    raise SystemExit(0)
if '--export-only' in sys.argv:
    bpy.ops.wm.open_mainfile(filepath=str(SRC/'executioner_painted_materials.blend'))
    rig=bpy.data.objects['ExecutionerRig']
    export_runtime([o for o in bpy.data.objects if o.type=='MESH' and o.parent==rig],rig)
    print('EXECUTIONER_PAINTED_RUNTIME_EXPORT_OK baked UV only')
    raise SystemExit(0)
bpy.ops.wm.open_mainfile(filepath=str(SRC/'executioner_human_3d.blend'))
rig=bpy.data.objects['ExecutionerRig'];rig['controls_enabled']=0
rig.animation_data.action=bpy.data.actions['idle']
bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
objects=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==rig]
assert len(objects)==28
deps=bpy.context.evaluated_depsgraph_get()
positions={};all_points=[];all_faces=[]
for obj in objects:
    evaluated=obj.evaluated_get(deps)
    points=[evaluated.matrix_world@v.co for v in evaluated.data.vertices]
    assert len(points)==len(obj.data.vertices)
    positions[obj.name]=points;offset=len(all_points);all_points+=points
    for face in evaluated.data.polygons:
        mat=obj.data.materials[face.material_index]
        if mat.node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value>0:
            all_faces.append([offset+i for i in face.vertices])
visibility=BVHTree.FromPolygons(all_points,all_faces)
camera=Vector((-4,-5,2.25));target=Vector((0,0,1.05))
forward=(target-camera).normalized();right=forward.cross(Vector((0,0,1))).normalized()
up=right.cross(forward).normalized();toward=-forward
paint=bpy.data.images.load(str(MATERIALS/'executioner_painted_front_v1.png'));paint.pack()
# Alpha-bounds registration from the source 1000x1400 native render to the
# generated 1060x1484 material source. Geometry and pose are never rescaled.
source_bounds=(298,165,720,1307);paint_bounds=(281,39,790,1393)
def project(point):
    rel=point-target
    x=(.5+rel.dot(right)/(2.5*1000/1400))*1000
    y=(.5-rel.dot(up)/2.5)*1400
    px=paint_bounds[0]+(x-source_bounds[0])*(paint_bounds[2]-paint_bounds[0])/(source_bounds[2]-source_bounds[0])
    py=paint_bounds[1]+(y-source_bounds[1])*(paint_bounds[3]-paint_bounds[1])/(source_bounds[3]-source_bounds[1])
    return px/paint.size[0],1-py/paint.size[1]

originals=set();painted={};paint_faces=0;original_faces=0
for obj in objects:
    base=obj.data.uv_layers.active;base.name='Executioner source UV'
    projection=obj.data.uv_layers.new(name='Executioner painted projection')
    for loop in obj.data.loops:projection.data[loop.index].uv=project(positions[obj.name][loop.vertex_index])
    obj.data.uv_layers.new(name='Executioner baked atlas')
    obj.data.uv_layers.active=obj.data.uv_layers['Executioner baked atlas']
    obj.data.uv_layers.active.active_render=True
    points=positions[obj.name]
    for face in obj.data.polygons:
        mat=obj.data.materials[face.material_index];originals.add(mat)
        shader=mat.node_tree.nodes['Principled BSDF']
        if shader.inputs['Alpha'].default_value==0:continue
        # Woven cloth gets its shading from the actual folds and lighting.
        # Projecting the illustration onto it reintroduces large painted
        # highlights and makes front-facing seams a different fabric to back.
        # Physical brass/bronze edges and relief retain their own metal color;
        # projecting the picture onto them erases the geometry's material break.
        if 'woven' in mat.name.lower() or mat.name.startswith('Reference ') or mat.name in AUTHORED_SURFACES:
            original_faces+=1;continue
        center=sum((points[i] for i in face.vertices),Vector())/len(face.vertices)
        normal=(points[face.vertices[1]]-points[face.vertices[0]]).cross(points[face.vertices[2]]-points[face.vertices[0]]).normalized()
        hit=visibility.ray_cast(center+toward*3,-toward,3.02)[0]
        visible=normal.dot(toward)>.08 and hit is not None and (hit-center).length<.008
        if not visible:original_faces+=1;continue
        if mat not in painted:
            clone=mat.copy();clone.name='Paint source '+mat.name
            painted[mat]=clone
        replacement=painted[mat]
        if replacement not in obj.data.materials[:]:obj.data.materials.append(replacement)
        face.material_index=obj.data.materials[:].index(replacement);paint_faces+=1

assert not any(mat.name in ('Antique warm bronze','Worn brass edges') for mat in painted),'Forged metal relief must retain its own material'
materials=originals|set(painted.values());settings={}
for mat in materials:
    nodes=mat.node_tree.nodes;links=mat.node_tree.links
    shader=nodes['Principled BSDF']
    base_uv=nodes.new('ShaderNodeUVMap');base_uv.uv_map='Executioner source UV'
    for node in list(nodes):
        if node.type=='TEX_IMAGE' and not node.inputs['Vector'].is_linked:links.new(base_uv.outputs['UV'],node.inputs['Vector'])
    rgb=nodes.new('ShaderNodeRGB');rgb.outputs[0].default_value=shader.inputs['Base Color'].default_value
    base=shader.inputs['Base Color'].links[0].from_socket if shader.inputs['Base Color'].is_linked else rgb.outputs[0]
    if mat in painted.values():
        uv=nodes.new('ShaderNodeUVMap');uv.uv_map='Executioner painted projection'
        image=nodes.new('ShaderNodeTexImage');image.image=paint;image.extension='CLIP'
        links.new(uv.outputs['UV'],image.inputs['Vector'])
        mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MIX'
        links.new(image.outputs['Alpha'],mix.inputs[0]);links.new(base,mix.inputs[1]);links.new(image.outputs['Color'],mix.inputs[2]);base=mix.outputs[0]
    metal=float(shader.inputs['Metallic'].default_value);rough=float(shader.inputs['Roughness'].default_value)
    emission=shader.inputs['Emission Color'].default_value
    power=float(shader.inputs['Emission Strength'].default_value)
    orm=nodes.new('ShaderNodeRGB');orm.outputs[0].default_value=(1,rough,metal,1)
    glow=nodes.new('ShaderNodeRGB');glow.outputs[0].default_value=(*(float(emission[i])*power for i in range(3)),1)
    emit=nodes.new('ShaderNodeEmission');emit.inputs['Strength'].default_value=1
    links.new(emit.outputs[0],nodes.get('Material Output').inputs['Surface'])
    destination=nodes.new('ShaderNodeTexImage');nodes.active=destination;destination.select=True
    settings[mat]=(base,orm.outputs[0],glow.outputs[0],emit,destination)

bpy.ops.object.select_all(action='DESELECT')
for obj in objects:obj.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=1.15,island_margin=.006,area_weight=.2,scale_to_bounds=True)
bpy.ops.object.mode_set(mode='OBJECT')
# The UV atlas is already packed across all components. Cycles otherwise
# walks a full 4K destination for each selected garment on every pass. Bake
# one disposable joined skin instead; keep all 28 editable originals intact.
bpy.ops.object.select_all(action='DESELECT')
bake_parts=[]
for obj in objects:
    copy=obj.copy();copy.data=obj.data.copy()
    bpy.context.scene.collection.objects.link(copy);copy.select_set(True)
    bake_parts.append(copy)
bpy.context.view_layer.objects.active=bake_parts[0]
bpy.ops.object.join();bake_mesh=bpy.context.view_layer.objects.active
bake_mesh.name='Temporary unified atlas bake'
assert len(bake_mesh.data.vertices)==sum(len(obj.data.vertices) for obj in objects)
print('EXECUTIONER_UNIFIED_BAKE vertices=%d source_components=%d'%(len(bake_mesh.data.vertices),len(objects)),flush=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
maps={}
for index,kind in enumerate(('base','orm','emission','cloth_base')):
    image=bpy.data.images.new('executioner_painted_'+kind+'_v1',ATLAS_SIZE,ATLAS_SIZE,alpha=False)
    # Uncovered atlas texels must not become perfect mirrors when filtering
    # reaches a narrow cloth island or seam. AO=1, roughness=1, metallic=0 is a
    # neutral matte background; painted pixels retain their authored channels.
    if kind=='orm':image.generated_color=(1,1,0,1)
    if kind=='cloth_base':image.generated_color=(.12,.17,.18,1)
    image.colorspace_settings.name='Non-Color' if kind=='orm' else 'sRGB'
    for mat,(base,orm,glow,emit,destination) in settings.items():
        for link in list(emit.inputs['Color'].links):mat.node_tree.links.remove(link)
        if kind=='cloth_base':
            # A separate color atlas prevents brass islands from bleeding into
            # narrow folded cloth UVs under bilinear/mipmap filtering.
            if 'woven' in mat.name.lower():source=base
            else:
                background=mat.node_tree.nodes.new('ShaderNodeRGB')
                background.outputs[0].default_value=(.015,.028,.032,1)
                source=background.outputs[0]
        else:source=(base,orm,glow)[index]
        mat.node_tree.links.new(source,emit.inputs['Color'])
        destination.image=image;mat.node_tree.nodes.active=destination
    bpy.ops.object.bake(type='EMIT',margin=16,use_clear=False)
    image.filepath_raw=str(MATERIALS/(image.name+'.png'));image.file_format='PNG';image.save();image.pack();maps[kind]=image
    print('EXECUTIONER_MATERIAL_BAKED',kind,image.filepath_raw,flush=True)

# Restore the physical surface shaders to bake their actual bump response.
# A neutral tangent normal fills unused atlas space and non-woven surfaces.
normal_image=bpy.data.images.new('executioner_painted_normal_v1',ATLAS_SIZE,ATLAS_SIZE,alpha=False)
normal_image.colorspace_settings.name='Non-Color'
normal_image.generated_color=(.5,.5,1,1)
for mat,(_,_,_,_,destination) in settings.items():
    mat.node_tree.links.new(mat.node_tree.nodes['Principled BSDF'].outputs['BSDF'],mat.node_tree.nodes['Material Output'].inputs['Surface'])
    destination.image=normal_image;mat.node_tree.nodes.active=destination
bpy.ops.object.bake(type='NORMAL',normal_space='TANGENT',normal_r='POS_X',normal_g='POS_Y',normal_b='POS_Z',margin=16,use_clear=False)
normal_image.filepath_raw=str(MATERIALS/(normal_image.name+'.png'))
normal_image.file_format='PNG';normal_image.save();normal_image.pack();maps['normal']=normal_image
print('EXECUTIONER_MATERIAL_BAKED normal',normal_image.filepath_raw,flush=True)
bake_data=bake_mesh.data
bpy.data.objects.remove(bake_mesh,do_unlink=True)
if bake_data.users==0:bpy.data.meshes.remove(bake_data)

final=bpy.data.materials.new('Executioner painted PBR');final.use_nodes=True
nodes=final.node_tree.nodes;links=final.node_tree.links;shader=nodes['Principled BSDF']
def texture(kind):
    node=nodes.new('ShaderNodeTexImage');node.image=maps[kind];return node
links.new(texture('base').outputs['Color'],shader.inputs['Base Color'])
channels=nodes.new('ShaderNodeSeparateColor');links.new(texture('orm').outputs['Color'],channels.inputs[0])
links.new(channels.outputs['Green'],shader.inputs['Roughness']);links.new(channels.outputs['Blue'],shader.inputs['Metallic'])
links.new(texture('emission').outputs['Color'],shader.inputs['Emission Color']);shader.inputs['Emission Strength'].default_value=1
normal_node=nodes.new('ShaderNodeNormalMap');normal_node.inputs['Strength'].default_value=.7
links.new(texture('normal').outputs['Color'],normal_node.inputs['Color'])
links.new(normal_node.outputs['Normal'],shader.inputs['Normal'])
void=bpy.data.materials.new('Painted concealed anatomy');void.use_nodes=True
void.node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value=0;void.surface_render_method='DITHERED'
cloth=final.copy();cloth.name='Executioner woven PBR'
cloth_shader=cloth.node_tree.nodes['Principled BSDF']
cloth_color=cloth.node_tree.nodes.new('ShaderNodeTexImage');cloth_color.image=maps['cloth_base']
cloth.node_tree.links.new(cloth_color.outputs['Color'],cloth_shader.inputs['Base Color'])
for link in list(cloth_shader.inputs['Emission Color'].links):cloth.node_tree.links.remove(link)
cloth_shader.inputs['Emission Strength'].default_value=0
for channel,value in (('Metallic',0.0),('Roughness',.91)):
    for link in list(cloth_shader.inputs[channel].links):cloth.node_tree.links.remove(link)
    cloth_shader.inputs[channel].default_value=value
for obj in objects:
    concealed=[face.index for face in obj.data.polygons if obj.data.materials[face.material_index].node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value==0]
    cloth_faces={face.index for face in obj.data.polygons if 'woven' in obj.data.materials[face.material_index].name.lower()}
    obj.data.materials.clear();obj.data.materials.append(final);obj.data.materials.append(cloth);obj.data.materials.append(void)
    for face in obj.data.polygons:face.material_index=2 if face.index in concealed else 1 if face.index in cloth_faces else 0
    # Implicit texture coordinates use the packed atlas, not the source UVs.
    obj.data.uv_layers.active=obj.data.uv_layers['Executioner baked atlas']
    obj.data.uv_layers.active.active_render=True
scene.render.engine='BLENDER_EEVEE'
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'executioner_painted_materials.blend'))
export_runtime(objects,rig)
manifest={'source_meshes':len(objects),'runtime_meshes':2,'bones':len(rig.data.bones),'actions':len(bpy.data.actions),'painted_faces':paint_faces,'retained_surface_faces':original_faces,'map_resolution':ATLAS_SIZE,'cloth_material':'Separate cloth color atlas and zero-metal woven PBR prevent cross-material mip bleeding','map_channels':['base','orm','emission','normal','cloth_base'],'normal_space':'TANGENT','projection_excluded_surfaces':PROJECTION_EXCLUSIONS,'source_bounds':source_bounds,'paint_bounds':paint_bounds,'pose_and_geometry_changed':False}
(SRC/'painted_material_manifest.json').write_text(json.dumps(manifest,indent=2))
print('EXECUTIONER_PAINTED_STUDY_OK',json.dumps(manifest))
