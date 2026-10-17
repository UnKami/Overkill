import bpy,math,bmesh
from mathutils import Vector
body=bpy.data.objects['Tailored articulated leather body']
visible=hands=0
for face in body.data.polygons:
    z=sum(body.data.vertices[i].co.z for i in face.vertices)/len(face.vertices)
    if .95<z<1.6:
        assert face.material_index==0,'Undersuit contains a torso hole'
        visible+=1
    hand=sum(sum(g.weight for g in body.data.vertices[i].groups if body.vertex_groups[g.group].name.startswith(('hand.','finger'))) for i in face.vertices)/len(face.vertices)
    if hand>.75:
        assert face.material_index==0,'Articulated hand hidden'
        hands+=1
assert visible>100 and hands>100
assert any(n.type=='TEX_IMAGE' for n in body.data.materials[0].node_tree.nodes),'Continuous garment must retain canonical textures'
assert bpy.data.objects.get('Canonical deep folded hood and scarf') is not None,'Hood must remain volumetric at side angles'
hood=bpy.data.objects['Canonical deep folded hood and scarf']
shell=bmesh.new();shell.from_mesh(hood.data)
assert all(edge.is_manifold for edge in shell.edges),'Hood has an open edge at a turn angle'
assert shell.calc_volume(signed=True)>.0005,'Hood must have outward-facing sewn cloth thickness'
shell.free()
rig=bpy.data.objects['ExecutionerRig'];rig['controls_enabled']=0
meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==rig]
checks=0
for action in bpy.data.actions:
    if not action.name in ['idle','iron_strike','twin_right','twin_left','heavy','throw','piston','siphon','channel','chalice','bell','crown','block','hit','guard_hit','fall']:continue
    rig.animation_data.action=action
    for fraction in [0,.25,.5,.75,1]:
        bpy.context.scene.frame_set(round(action.frame_range.x+(action.frame_range.y-action.frame_range.x)*fraction));bpy.context.view_layer.update()
        deps=bpy.context.evaluated_depsgraph_get()
        for obj in meshes:
            evaluated=obj.evaluated_get(deps)
            coords=[evaluated.matrix_world@Vector(corner) for corner in evaluated.bound_box]
            bounds=[max(v[i] for v in coords)-min(v[i] for v in coords) for i in range(3)]
            assert max(bounds)<3.0, 'Exploded geometry '+obj.name+' '+action.name+' '+str(bounds)
            assert max(v.length for v in coords)<6, 'Detached clothing '+obj.name
            checks+=1
print('ROTATION_COVERAGE_OK visible_torso_faces=%d visible_hands=%d bounded_mesh_samples=%d'%(visible,hands,checks))


