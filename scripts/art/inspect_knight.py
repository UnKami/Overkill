import bpy, json
from pathlib import Path

report = []
for obj in bpy.data.objects:
    item = {'name': obj.name, 'type': obj.type, 'location': list(obj.location), 'dimensions': list(obj.dimensions), 'parent': obj.parent.name if obj.parent else None}
    if obj.type == 'MESH':
        item['vertices'] = len(obj.data.vertices)
        item['materials'] = [m.name if m else '' for m in obj.data.materials]
        item['modifiers'] = [{'type': m.type, 'name': m.name} for m in obj.modifiers]
    if obj.type == 'ARMATURE':
        item['bones'] = [{'name': b.name, 'head': list(b.head_local), 'tail': list(b.tail_local), 'deform': b.use_deform} for b in obj.data.bones]
    report.append(item)
Path('.tools/knight-inspect.json').write_text(json.dumps(report, indent=2))
print('KNIGHT_INSPECT_OK')
