class_name ForgedArmor extends RefCounted
## Bone-mounted, curved plate assemblies. Each assembly is one mesh per finish.

static func mount(skeleton: Skeleton3D, bone: String) -> Node3D:
	var anchor: BoneAttachment3D = BoneAttachment3D.new()
	skeleton.add_child(anchor)
	anchor.bone_name = bone
	var space: Node3D = Node3D.new()
	anchor.add_child(space)
	space.transform = skeleton.get_bone_global_rest(skeleton.find_bone(bone)).affine_inverse()
	return space

static func plate(parent: Node3D, center: Vector3, extent: Vector3, material: Material, rim: Material, orientation: Basis = Basis.IDENTITY) -> void:
	# Elliptical crown with a rolled edge: broad curved armor, not stacked boxes.
	var shell: SurfaceTool = SurfaceTool.new()
	shell.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edge: SurfaceTool = SurfaceTool.new()
	edge.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in 6:
		for segment: int in 24:
			var a: float = float(segment) / 24.0 * TAU
			var b: float = float(segment + 1) / 24.0 * TAU
			var u: float = float(row) / 6.0 * 1.65
			var v: float = float(row + 1) / 6.0 * 1.65
			for pair: Vector2 in [Vector2(a,u),Vector2(a,v),Vector2(b,u),Vector2(b,u),Vector2(a,v),Vector2(b,v)]:
				var normal: Vector3 = Vector3(cos(pair.x)*sin(pair.y),cos(pair.y),sin(pair.x)*sin(pair.y))
				shell.set_normal(orientation * (normal / extent).normalized())
				shell.add_vertex(center + orientation * (normal * extent))
			if row == 5:
				for pair: Vector2 in [Vector2(a,1.56),Vector2(a,1.68),Vector2(b,1.56),Vector2(b,1.56),Vector2(a,1.68),Vector2(b,1.68)]:
					var normal: Vector3 = Vector3(cos(pair.x)*sin(pair.y),cos(pair.y),sin(pair.x)*sin(pair.y))
					edge.set_normal(orientation * (normal / extent).normalized())
					edge.add_vertex(center + orientation * (normal * (extent + Vector3.ONE * 0.003)))
	add_mesh(parent, shell.commit(), material)
	add_mesh(parent, edge.commit(), rim)

static func add_mesh(parent: Node3D, shape: Mesh, material: Material) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh

static func sentinel(skeleton: Skeleton3D, steel: Material, trim: Material) -> void:
	for side: float in [-1.0, 1.0]:
		var bone: String = "shoulder.L" if side < 0 else "shoulder.R"
		var shoulder: Node3D = mount(skeleton, bone)
		plate(shoulder, Vector3(side*0.30,1.65,0.015),Vector3(0.235,0.105,0.205),steel,trim)
		plate(shoulder, Vector3(side*0.34,1.54,0.015),Vector3(0.21,0.075,0.185),steel,trim)
		var shin: Node3D = mount(skeleton, "shin.L" if side < 0 else "shin.R")
		plate(shin,Vector3(side*0.195,0.39,-0.065),Vector3(0.105,0.04,0.185),steel,trim,Basis(Vector3.RIGHT,-PI*0.5))
	var torso: Node3D = mount(skeleton,"chest")
	plate(torso,Vector3(0,1.44,-0.13),Vector3(0.245,0.14,0.30),steel,trim,Basis(Vector3.RIGHT,-PI*0.5))
	var collar: TorusMesh = TorusMesh.new()
	collar.inner_radius = 0.12
	collar.outer_radius = 0.16
	collar.rings = 32
	collar.ring_segments = 8
	var collar_mesh: MeshInstance3D = add_mesh(torso,collar,trim)
	collar_mesh.position = Vector3(0,1.73,0)
	var seal: TorusMesh = TorusMesh.new()
	seal.inner_radius = 0.067
	seal.outer_radius = 0.080
	seal.rings = 32
	seal.ring_segments = 6
	var emblem: MeshInstance3D = add_mesh(torso,seal,trim)
	emblem.position = Vector3(0,1.47,-0.272)
	emblem.rotation.x = PI*0.5
	var marks: MultiMesh = MultiMesh.new()
	marks.transform_format = MultiMesh.TRANSFORM_3D
	var tooth: BoxMesh = BoxMesh.new()
	tooth.size = Vector3(0.011,0.027,0.007)
	marks.mesh = tooth
	marks.instance_count = 9
	for i: int in 9:
		var angle: float = i*TAU/9.0
		marks.set_instance_transform(i,Transform3D(Basis(Vector3.BACK,-angle),Vector3(sin(angle)*0.058,1.47+cos(angle)*0.058,-0.281)))
	var inlay: MultiMeshInstance3D = MultiMeshInstance3D.new()
	inlay.multimesh = marks
	inlay.material_override = trim
	torso.add_child(inlay)

static func combine_finish(parent: Node3D) -> void:
	# Normalize index formats before concatenating: mixing indexed primitives and
	# non-indexed authored bevels otherwise leaves some triangles unreferenced.
	var groups: Dictionary = {}
	for child: Node in parent.get_children():
		if not child is MeshInstance3D: continue
		for index: int in child.mesh.get_surface_count():
			var material: Material = child.get_active_material(index)
			if not groups.has(material):
				var surface: SurfaceTool = SurfaceTool.new()
				surface.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[material] = surface
			var source: SurfaceTool = SurfaceTool.new()
			source.create_from(child.mesh,index)
			source.deindex()
			var target: SurfaceTool = groups[material]
			target.append_from(source.commit(),0,child.transform)
		parent.remove_child(child)
		child.free()
	for material: Material in groups:
		var surface: SurfaceTool = groups[material]
		surface.index()
		add_mesh(parent, surface.commit(), material)

static func executioner(skeleton: Skeleton3D, steel: Material, trim: Material) -> void:
	# A high sword-side pauldron and overlapping lames distinguish the lighter hero.
	for side: float in [-1.0, 1.0]:
		var shoulder: Node3D = mount(skeleton, "shoulder.L" if side < 0 else "shoulder.R")
		var width: float = 0.18 if side < 0 else 0.22
		for layer: int in 3:
			plate(shoulder, Vector3(side * (0.29 + layer * 0.018), 1.65 - layer * 0.065, 0.01), Vector3(width - layer * 0.018, 0.07, 0.17 - layer * 0.012), steel, trim)
		combine_finish(shoulder)
	var waist: Node3D = mount(skeleton, "hips")
	for side: float in [-1.0, 1.0]:
		for layer: int in 3:
			plate(waist, Vector3(side * 0.15, 1.01 - layer * 0.075, -0.09), Vector3(0.13, 0.038, 0.11), steel, trim, Basis(Vector3.RIGHT, -PI * 0.35))
	combine_finish(waist)
	var chest: Node3D = mount(skeleton, "chest")
	plate(chest, Vector3(0, 1.43, -0.12), Vector3(0.20, 0.12, 0.26), steel, trim, Basis(Vector3.RIGHT, -PI * 0.5))

static func executioner_blade(parent: Node3D, steel: Material, edge_material: Material) -> void:
	# A broad execution blade with bevels catches a thin highlight along its edge.
	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(-0.06,0.19),Vector2(0.06,0.19),Vector2(0.105,0.76),
		Vector2(0.095,1.12),Vector2(-0.085,1.16),Vector2(-0.12,0.79)])
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bevel: SurfaceTool = SurfaceTool.new()
	bevel.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [-1.0,1.0]:
		for i: int in outline.size():
			var a: Vector2 = outline[i]
			var b: Vector2 = outline[(i+1)%outline.size()]
			var inner_a: Vector2 = Vector2(a.x*0.73,lerpf(0.66,a.y,0.96))
			var inner_b: Vector2 = Vector2(b.x*0.73,lerpf(0.66,b.y,0.96))
			var face: Array[Vector3] = [Vector3(0,0.05+side*0.019,0.66),Vector3(inner_a.x,0.05+side*0.019,inner_a.y),Vector3(inner_b.x,0.05+side*0.019,inner_b.y)]
			if side > 0: face.reverse()
			for point: Vector3 in face: surface.add_vertex(point)
			var strip: Array[Vector3] = [Vector3(inner_a.x,0.05+side*0.019,inner_a.y),Vector3(a.x,0.05,a.y),Vector3(b.x,0.05,b.y),Vector3(inner_a.x,0.05+side*0.019,inner_a.y),Vector3(b.x,0.05,b.y),Vector3(inner_b.x,0.05+side*0.019,inner_b.y)]
			if side > 0: strip.reverse()
			for point: Vector3 in strip: bevel.add_vertex(point)
	surface.generate_normals()
	bevel.generate_normals()
	add_mesh(parent,surface.commit(),steel)
	add_mesh(parent,bevel.commit(),edge_material)
