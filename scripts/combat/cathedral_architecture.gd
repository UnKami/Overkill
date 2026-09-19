class_name CathedralArchitecture extends Node3D
## Repeated dressed-stone piers and ribs, built once and instanced by material.
## No per-frame geometry work or additional light sources.

func _ready() -> void:
	var stone: StandardMaterial3D = StandardMaterial3D.new()
	stone.albedo_color = Color("353839")
	stone.albedo_texture = preload("res://assets/environments/materials/stone_tiles_diff_2k.jpg")
	stone.normal_enabled = true
	stone.normal_texture = preload("res://assets/environments/materials/stone_tiles_nor_gl_2k.jpg")
	stone.normal_scale = 0.12
	stone.roughness = 0.96
	stone.uv1_triplanar = true
	stone.uv1_world_triplanar = true
	stone.uv1_scale = Vector3.ONE * 0.32
	stone.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var piers: Array[Transform3D] = []
	var arches: Array[Transform3D] = []
	for row: int in 4:
		var depth: float = -2.5 - row * 3.5
		for side: float in [-1.0, 1.0]:
			piers.append(Transform3D(Basis.IDENTITY, Vector3(side * 5.8, 0, depth)))
		arches.append(Transform3D(Basis.IDENTITY, Vector3(0, 0, depth)))
	_batch("Clustered stone piers", _pier(), piers, stone)
	_batch("Pointed arcade ribs", _arch(), arches, stone)

func _pier() -> ArrayMesh:
	# A moulded base, bundled shaft and stepped capital share continuous topology.
	var courses: Array[Vector2] = [Vector2(0,0.66),Vector2(0.10,0.66),
		Vector2(0.16,0.59),Vector2(0.27,0.59),Vector2(0.34,0.48),
		Vector2(0.42,0.43),Vector2(4.75,0.36),Vector2(4.83,0.42),
		Vector2(4.92,0.48),Vector2(5.04,0.49),Vector2(5.15,0.61),
		Vector2(5.26,0.61)]
	var vertices: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	const SEGMENTS: int = 48
	for course: Vector2 in courses:
		for segment: int in SEGMENTS:
			var angle: float = segment * TAU / SEGMENTS
			# Four attached shafts create Gothic clustered-pier highlights.
			var bundled: float = 1.0 + 0.13 * cos(angle * 4.0)
			vertices.append(Vector3(cos(angle)*course.y*bundled,course.x,sin(angle)*course.y*bundled))
	for row: int in courses.size()-1:
		for segment: int in SEGMENTS:
			var a: int = row*SEGMENTS+segment
			var b: int = row*SEGMENTS+(segment+1)%SEGMENTS
			indices.append_array(PackedInt32Array([a,b,b+SEGMENTS,a,b+SEGMENTS,a+SEGMENTS]))
	return _surface(vertices,indices)

func _arch() -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	# Two curved half-ribs meet at a pointed crown above the clear combat sightline.
	for side: float in [-1.0,1.0]:
		var first: int = vertices.size()
		const STEPS: int = 32
		const SIDES: int = 8
		for step: int in STEPS+1:
			var t: float = float(step)/STEPS
			var center: Vector3 = Vector3(side*5.8*(1.0-t*t),5.18+4.2*t,0)
			var tangent: Vector3 = Vector3(-side*11.6*t,4.2,0).normalized()
			var normal: Vector3 = Vector3(tangent.y,-tangent.x,0)
			for edge: int in SIDES:
				var angle: float = TAU*edge/SIDES
				vertices.append(center+normal*cos(angle)*0.25+Vector3.FORWARD*sin(angle)*0.27)
		for step: int in STEPS:
			for edge: int in SIDES:
				var a: int = first+step*SIDES+edge
				var b: int = first+step*SIDES+(edge+1)%SIDES
				indices.append_array(PackedInt32Array([a,b,b+SIDES,a,b+SIDES,a+SIDES]))
	return _surface(vertices,indices)

func _surface(vertices: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var builder: SurfaceTool = SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in vertices: builder.add_vertex(point)
	for index: int in indices: builder.add_index(index)
	builder.generate_normals()
	return builder.commit()

func _batch(label: String, mesh: ArrayMesh, transforms: Array[Transform3D], material: Material) -> void:
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = transforms.size()
	for index: int in transforms.size(): instances.set_instance_transform(index, transforms[index])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = instances
	node.material_override = material
	add_child(node)
