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
			material.shader = preload("res://assets/shaders/custodian_metal.gdshader")
			material.set_shader_parameter("plate_color", Color("71502e") if bronze else Color("394e59"))
			material.set_shader_parameter("exposed_color", Color("a68a59") if bronze else Color("78868a"))
			material.set_shader_parameter("oxide_color", Color("29433e") if bronze else Color("303a3d"))
			material.set_shader_parameter("face_roughness", 0.42 if bronze else 0.48)
			material.set_shader_parameter("oxide_amount", 0.58 if bronze else 0.30)
			material.set_shader_parameter("metalness", 0.76 if bronze else 0.86)
			material.set_shader_parameter("surface_detail", preload("res://assets/characters/rigged/worn_metal_015.png"))
			mesh_instance.set_surface_override_material(surface, material)
			replaced += 1
	return replaced
