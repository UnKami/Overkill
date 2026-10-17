"""Saved 3D relic source: catalog completeness, native skin and track timing."""
from pathlib import Path
import json,bpy
root=Path(__file__).resolve().parents[2]
base=root/'assets/animations/relics/three_d'
bpy.ops.wm.open_mainfile(filepath=str(base/'source/relics_3d.blend'))
rig=bpy.data.objects['RelicRig3D']
catalog=json.loads((base/'source/catalog.json').read_text())
tracks=json.loads((root/'assets/animations/relics/relic_tracks.gd').read_text().split('const DATA: Dictionary = ',1)[1])
checks=0
def check(ok,message):
    global checks
    checks+=1
    assert ok,message
check(len(catalog)==29,'Complete 29 relic catalog')
check(len(rig.data.bones)==6,'Six native prop joints')
meshes=[o for o in bpy.data.objects if o.type=='MESH']
check(len(meshes)==sum(entry['meshes'] for entry in catalog.values()),'All reference-faithful volume meshes')
for name,entry in catalog.items():
    objects=[o for o in meshes if o.name.startswith(name.replace('-','_')+'__')]
    check(len(objects)==entry['meshes'],'Catalog skin meshes '+name)
    action=bpy.data.actions[name]
    check(abs(action['contact_seconds']-tracks['clips'][name]['contact'])<1e-6,'Retained contact '+name)
    check(abs(action['duration_seconds']-tracks['clips'][name]['duration'])<1e-6,'Retained duration '+name)
    for obj in objects:
        check(sum(m.type=='ARMATURE' and m.object==rig for m in obj.modifiers)==1,'Native skin '+obj.name)
        if name=='REL-03':
            points=[obj.matrix_world@v.co for v in obj.data.vertices]
            depth=max(p.y for p in points)-min(p.y for p in points)
            check(depth>.27,'Hammer has a full-depth striking head through wrist rotation')
            check(obj.get('construction','').startswith('Modeled shaft'),'Hammer is modeled rather than artwork extrusion')
        if name in ('REL-01','REL-02'):
            points=[obj.matrix_world@v.co for v in obj.data.vertices]
            blade=[p for p in points if .2<p.z<.60]
            check(max(p.y for p in blade)-min(p.y for p in blade)>.065,'Molten blade retains a full-depth faceted section')
            handle=[p for p in points if abs(p.z)<.07]
            check(max((p.x*p.x+p.y*p.y)**.5 for p in handle)<.031,'Palm fits a round handle rather than the illustrated oversized grip')
            check(abs(max(p.z for p in points)-.74)<.0001,'Established 0.74m blade tip is retained')
            check(obj.get('construction','').startswith('Modeled faceted'),'Sword has modeled blade/spine/grip geometry')
        for vertex in obj.data.vertices:
            check(len(vertex.groups)==1 and abs(vertex.groups[0].weight-1)<1e-6,'Rigid prop weight '+obj.name)
print('RELICS_SAVED_SOURCE_OK checks=%d catalog=29 meshes=%d bones=6 actions=29'%(checks,len(meshes)))
