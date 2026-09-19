class_name CustodianMaterials
extends RefCounted
## Study material binding; call after instantiating custodian-study.glb.
## Recess and emissive visor retain their imported materials.

static func apply(root: Node3D) -> int:
	var replaced: int = 0
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		for surface: int in mesh_instance.mesh.get_surface_count():
			var source: Material = mesh_instance.mesh.surface_get_material(surface)
			if source == null:
				continue
			var bronze: bool = source.resource_name == "Custodian_Bronze"
			if not bronze and source.resource_name != "Custodian_Iron":
				continue
			var material: ShaderMaterial = ShaderMaterial.new()
			material.shader = preload("res://assets/shaders/sentinel_metal.gdshader")
			material.set_shader_parameter("plate_color", Color("705638") if bronze else Color("475a65"))
			material.set_shader_parameter("exposed_color", Color("907954") if bronze else Color("64737b"))
			material.set_shader_parameter("metalness", 0.76 if bronze else 0.86)
			material.set_shader_parameter("surface_detail", preload("res://assets/characters/rigged/worn_metal_015.png"))
			mesh_instance.set_surface_override_material(surface, material)
			replaced += 1
	return replaced
