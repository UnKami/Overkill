class_name RiggedCombatant extends Node3D
## Skinned, continuously animated GLB with attached equipment and faction materials.
var hostile := false
var archetype := "executioner"
var opponent: Node3D
var _model: Node3D
var _skeleton: Skeleton3D
var _animation: AnimationPlayer
var _motion: Tween
var _dead := false
var _weapon: Node3D
var _gold: Material
var _glow: StandardMaterial3D
var _time := 0.0
var _cloth: ShaderMaterial
var _trail: MeshInstance3D
var _trail_points: Array[Dictionary] = []
var _trail_material: StandardMaterial3D
var _metal_cache: Dictionary = {}
var _clip_cache: Dictionary = {}
const AUTHORED_ATTACK_TIMES: Array[float] = [0.0, 0.20, 0.32, 0.40, 0.76]
const HEAVY_ATTACK_TIMES: Array[float] = [0.0, 0.30, 0.46, 0.56, 1.08]

func _ready() -> void:
	_model = preload("res://assets/characters/rigged/sentinel.glb").instantiate() if hostile and archetype == "sentinel" else preload("res://assets/characters/rigged/executioner.glb").instantiate()
	add_child(_model)
	_model.rotation.y = PI
	_find_nodes(_model)
	assert(_skeleton != null and _animation != null, "Combat asset requires a skeleton and animation player")
	_configure_attack_timing()
	_style(_model)
	_build_equipment()
	_trail = MeshInstance3D.new()
	add_child(_trail)
	_trail.top_level = true
	_trail_material = StandardMaterial3D.new()
	_trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_trail_material.vertex_color_use_as_albedo = true
	_trail.material_override = _trail_material
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for clip_name in _animation.get_animation_list():
		if "combat_idle" in clip_name:
			_animation.get_animation(clip_name).loop_mode = Animation.LOOP_LINEAR
	_animation.animation_finished.connect(_animation_finished)
	_play("combat_idle", 0)

func _find_nodes(node: Node) -> void:
	if node is Skeleton3D: _skeleton = node
	if node is AnimationPlayer: _animation = node
	for child in node.get_children(): _find_nodes(child)

func _metal(color: Color, metalness: float = 0.88) -> ShaderMaterial:
	var key: String = color.to_html() + str(metalness)
	if _metal_cache.has(key): return _metal_cache[key]
	var mat := ShaderMaterial.new()
	_metal_cache[key] = mat
	mat.shader = preload("res://assets/shaders/forged_metal.gdshader")
	mat.set_shader_parameter("steel_color",color)
	mat.set_shader_parameter("metalness",metalness)
	mat.set_shader_parameter("surface_detail", preload("res://assets/characters/rigged/worn_metal_015.png"))
	return mat

func _sentinel_metal(bronze: bool) -> ShaderMaterial:
	var key: String = "sentinel_bronze" if bronze else "sentinel_iron"
	if _metal_cache.has(key): return _metal_cache[key]
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/sentinel_metal.gdshader")
	material.set_shader_parameter("plate_color", Color("66513a") if bronze else Color("343d42"))
	material.set_shader_parameter("exposed_color", Color("a78a5e") if bronze else Color("69757c"))
	material.set_shader_parameter("metalness", 0.78 if bronze else 0.86)
	material.set_shader_parameter("surface_detail", preload("res://assets/characters/rigged/worn_metal_015.png"))
	_metal_cache[key] = material
	return material

func _style(node: Node) -> void:
	if node is MeshInstance3D:
		if node.name in ["Knight_Shoulder-Plate", "Knight_BreastPlate"]:
			node.hide()
		for i in range(node.mesh.get_surface_count()):
			var source: Material = node.mesh.surface_get_material(i)
			var name_text := source.resource_name if source else ""
			if name_text == "Sentinel_Ember":
				var ember: StandardMaterial3D = source.duplicate()
				ember.emission_energy_multiplier = 1.2
				node.set_surface_override_material(i, ember)
			elif name_text == "Sentinel_Iron":
				node.set_surface_override_material(i, _sentinel_metal(false))
			elif name_text == "Sentinel_Bronze":
				node.set_surface_override_material(i, _sentinel_metal(true))
			elif name_text == "Sentinel_Recess":
				node.set_surface_override_material(i, source)
			elif "Gold" in name_text:
				node.set_surface_override_material(i, _metal(Color("806441"), 0.76))
			elif "White" in name_text:
				node.set_surface_override_material(i, _metal(Color("443a38") if hostile else Color("344650")))
			else:
				var dark := StandardMaterial3D.new()
				dark.albedo_color = Color("1a1219") if hostile else Color("101923")
				dark.roughness = 0.88
				node.set_surface_override_material(i, dark)
	for child in node.get_children(): _style(child)

func _attach(bone: String) -> BoneAttachment3D:
	var result := BoneAttachment3D.new()
	_skeleton.add_child(result)
	result.bone_name = bone
	return result

func _mesh(parent: Node3D, shape: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = shape
	piece.position = at
	piece.material_override = material
	parent.add_child(piece)
	return piece

func _box(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = dimensions
	return _mesh(parent, shape, at, material)

func _build_equipment() -> void:
	_gold = _metal(Color("967549"), 0.78)
	_glow = StandardMaterial3D.new()
	_glow.albedo_color = Color("f0a061") if hostile else Color("79d8e4")
	_glow.emission_enabled = true
	_glow.emission = _glow.albedo_color
	_glow.emission_energy_multiplier = 1.6
	var steel := _metal(Color("646a70"))
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color("211c1b")
	leather.roughness = 0.8
	var wrist := _attach("hand.R")
	_weapon = Node3D.new()
	wrist.add_child(_weapon)
	# Equipment moves with the wrist, not with the root of the character.
	var grip := CylinderMesh.new()
	grip.top_radius = 0.027
	grip.bottom_radius = 0.027
	grip.height = 0.25
	var grip_piece := _mesh(_weapon, grip, Vector3(0,0.05,0), leather)
	grip_piece.rotation.x = PI / 2
	_box(_weapon, Vector3(0,0.05,0.14), Vector3(0.30,0.045,0.045), _gold)
	if hostile and archetype in ["sentinel", "bulwark", "twin", "eclipse"]:
		_box(_weapon, Vector3(0,0.05,0.48), Vector3(0.045,0.045,0.68), steel)
		_beveled_box(_weapon, Vector3(0,0.05,0.82), Vector3(0.52,0.27,0.27), steel)
		_beveled_box(_weapon, Vector3(0,0.05,0.82), Vector3(0.075,0.29,0.29), _gold)
		for side: float in [-1.0, 1.0]:
			_beveled_box(_weapon, Vector3(side * 0.265,0.05,0.82), Vector3(0.04,0.23,0.23), _gold)
		for mark: int in 3:
			_box(_weapon, Vector3(-0.14 + mark * 0.14,0.193,0.82), Vector3(0.025,0.004,0.10), _glow)
	else:
		ForgedArmor.executioner_blade(_weapon, steel, _metal(Color("9babad"),0.72))
		for n: int in 4:
			_box(_weapon, Vector3(0,0.071,0.38+n*0.12), Vector3(0.022,0.003,0.03), _gold)
	if hostile and archetype == "sentinel":
		_build_cloak()
		return
	if hostile:
		ForgedArmor.sentinel(_skeleton,_metal(Color("272c30"),0.74),_gold)
	else:
		ForgedArmor.executioner(_skeleton,_metal(Color("344650"),0.80),_gold)

	# Helm ornament and clock aureole are authored in rest-space then bone-attached.
	var head := _attach("head")
	var head_space := Node3D.new()
	head.add_child(head_space)
	var bone_index := _skeleton.find_bone("head")
	head_space.transform = _skeleton.get_bone_global_rest(bone_index).affine_inverse()
	var halo := TorusMesh.new()
	halo.inner_radius = 0.28 if hostile else 0.24
	halo.outer_radius = halo.inner_radius + 0.018
	halo.rings = 48
	halo.ring_segments = 8
	var halo_piece := _mesh(head_space, halo, Vector3(0,1.87,0.15), _gold)
	halo_piece.rotation.x = PI / 2
	for side in [-1.0,1.0]:
		_box(head_space,Vector3(side*0.049,1.965,-0.15),Vector3(0.059,0.010,0.009),_glow)
		if hostile:
			var horn := CylinderMesh.new()
			horn.top_radius = 0.005
			horn.bottom_radius = 0.045
			horn.height = 0.30
			var spike := _mesh(head_space,horn,Vector3(side*0.14,2.10,0),_gold)
			spike.rotation.z = side * -0.4
	_build_cloak()

func _build_cloak() -> void:
	var chest := _attach("chest")
	var rest_space := Node3D.new()
	chest.add_child(rest_space)
	rest_space.transform = _skeleton.get_bone_global_rest(_skeleton.find_bone("chest")).affine_inverse()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in range(22):
		for x in range(16):
			for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
				var uv := Vector2(float(x+corner.x)/16.0,float(y+corner.y)/22.0)
				var width := lerpf(0.26,0.44,uv.y)
				var z := 0.16 + uv.y*0.20 + sin(uv.x*PI*8)*0.027*uv.y
				surface.set_uv(uv)
				surface.add_vertex(Vector3((uv.x-0.5)*2*width,1.67-uv.y*1.29,z))
	surface.generate_normals()
	_cloth = ShaderMaterial.new()
	_cloth.shader = preload("res://assets/shaders/battle_cloth.gdshader")
	_cloth.set_shader_parameter("cloth_color",Color("381822") if hostile else Color("132938"))
	_mesh(rest_space,surface.commit(),Vector3.ZERO,_cloth)

func _heavy_attack() -> bool:
	return hostile and archetype == "sentinel"

func _retimed_attack_time(source_time: float) -> float:
	if not _heavy_attack(): return source_time
	for i: int in range(1, AUTHORED_ATTACK_TIMES.size()):
		if source_time <= AUTHORED_ATTACK_TIMES[i]:
			return remap(source_time, AUTHORED_ATTACK_TIMES[i-1], AUTHORED_ATTACK_TIMES[i], HEAVY_ATTACK_TIMES[i-1], HEAVY_ATTACK_TIMES[i])
	return source_time + 0.32

func _attack_phase_time() -> float:
	var time: float = _animation.current_animation_position
	if not _heavy_attack(): return time
	for i: int in range(1, HEAVY_ATTACK_TIMES.size()):
		if time <= HEAVY_ATTACK_TIMES[i]:
			return remap(time, HEAVY_ATTACK_TIMES[i-1], HEAVY_ATTACK_TIMES[i], AUTHORED_ATTACK_TIMES[i-1], AUTHORED_ATTACK_TIMES[i])
	return time - 0.32

func _configure_attack_timing() -> void:
	if not _heavy_attack(): return
	# Imported animation resources are shared. Give this actor a private library.
	for library_name: StringName in _animation.get_animation_library_list():
		var library: AnimationLibrary = _animation.get_animation_library(library_name).duplicate(true)
		_animation.remove_animation_library(library_name)
		_animation.add_animation_library(library_name, library)
	var clip: Animation = _animation.get_animation(_clip("execution_cut"))
	for track: int in clip.get_track_count():
		# All mapped times move forward, so reverse order preserves key indices.
		for key: int in range(clip.track_get_key_count(track)-1, -1, -1):
			clip.track_set_key_time(track, key, _retimed_attack_time(clip.track_get_key_time(track, key)))
	clip.length = _retimed_attack_time(clip.length)

func contact_time() -> float:
	return _retimed_attack_time(0.32)

func recovery_time() -> float:
	return _retimed_attack_time(0.76) - contact_time()

func _clip(fragment: String) -> StringName:
	if _clip_cache.has(fragment): return _clip_cache[fragment]
	for clip_name in _animation.get_animation_list():
		if fragment in clip_name:
			_clip_cache[fragment] = clip_name
			return clip_name
	return &""

func _play(fragment: String, blend: float = 0.08) -> void:
	var clip_name := _clip(fragment)
	if clip_name != &"":
		if _animation.assigned_animation == clip_name: _animation.stop(true)
		_animation.play(clip_name, blend)
		_animation.advance(0.0)

func _process(delta: float) -> void:
	_time += delta
	if _animation:
		_animation.speed_scale = AudioManager.animation_speed_scale()
	if _cloth: _cloth.set_shader_parameter("motion",0.0 if AudioManager.reduced_motion else 1.0)
	_apply_attack_weight()
	_align_weapon()
	_update_trail(delta)

func _align_weapon() -> void:
	if not is_instance_valid(opponent) or not _weapon: return
	var surface: Vector3 = opponent.global_position + Vector3(0,1.45,0) + (global_position-opponent.global_position).normalized()*0.12
	# Aim from the current palm, not the previous frame weapon transform.
	var wrist: Vector3 = _skeleton.get_bone_global_pose(_skeleton.find_bone("hand.R")).origin
	var knuckle: Vector3 = _skeleton.get_bone_global_pose(_skeleton.find_bone("f_middle.01.R")).origin
	var palm: Vector3 = _skeleton.to_global(wrist.lerp(knuckle, 0.7))
	var toward: Vector3 = (surface - palm).normalized()
	var idle := (Vector3.UP + toward*0.15).normalized()
	var direction := idle
	if _dead:
		direction = (toward*0.5 + Vector3.DOWN*0.8).normalized()
	elif _animation.current_animation == _clip("execution_cut"):
		var t := _attack_phase_time()
		var back := (-toward + Vector3.UP*0.4).normalized()
		var down := (toward + Vector3.DOWN*0.6).normalized()
		if t < 0.20: direction = idle.slerp(back,smoothstep(0.0,0.20,t))
		elif t < 0.30: direction = back.slerp(toward,smoothstep(0.20,0.30,t))
		elif t < 0.40: direction = toward
		elif t < 0.51: direction = toward.slerp(down,smoothstep(0.40,0.51,t))
		else: direction = down.slerp(idle,smoothstep(0.51,0.76,t))
	var up := Vector3.FORWARD if absf(direction.dot(Vector3.UP)) > 0.98 else Vector3.UP
	_weapon.global_basis = Basis.looking_at(-direction,up).scaled(Vector3.ONE*global_basis.get_scale().x)
	# Center the handle inside the palm rather than at the wrist joint.
	_weapon.global_position = palm - _weapon.global_basis * Vector3(0,0.05,0)

func _update_trail(delta: float) -> void:
	for point in _trail_points: point.age += delta
	while not _trail_points.is_empty() and _trail_points[0].age > 0.11: _trail_points.pop_front()
	if not _dead and _animation.current_animation == _clip("execution_cut"):
		var t := _attack_phase_time()
		if t > 0.23 and t < 0.41:
			_trail_points.append({"root":_weapon.to_global(Vector3(0,0.05,0.22)),"tip":_weapon.to_global(Vector3(0,0.05,0.82 if hostile and archetype in ["sentinel", "bulwark", "twin", "eclipse"] else 1.14)),"age":0.0})
	if _trail_points.size() < 2:
		_trail.mesh = null
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,_trail_points.size()):
		var previous: Dictionary = _trail_points[i-1]
		var next: Dictionary = _trail_points[i]
		for vertex in [[previous,"root"],[previous,"tip"],[next,"tip"],[previous,"root"],[next,"tip"],[next,"root"]]:
			var color := Color("ebb27c") if hostile else Color("8ad5e1")
			color.a = (1.0-vertex[0].age/0.11)*0.25
			surface.set_color(color)
			surface.add_vertex(vertex[0][vertex[1]])
	_trail.mesh = surface.commit()

func attack() -> void:
	if _dead: return
	_play("execution_cut",0.06)
	if _motion and _motion.is_valid(): _motion.kill()
	_model.position = Vector3.ZERO

func hit(blocked: bool) -> void:
	if _dead: return
	_play("guard" if blocked else "hit",0.025)

func fall() -> void:
	if _dead: return
	_dead = true
	if _motion and _motion.is_valid(): _motion.kill()
	_play("death",0.08)

func _animation_finished(_name: StringName) -> void:
	if not _dead: _play("combat_idle",0.12)

func _beveled_box(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var half: Vector3 = dimensions * 0.5
	var bevel: float = minf(0.025, minf(half.x, minf(half.y, half.z)) * 0.35)
	var rings: Array[PackedVector3Array] = []
	for layer: int in 4:
		var inset: float = bevel if layer == 0 or layer == 3 else 0.0
		var x: float = half.x - inset
		var z: float = half.z - inset
		var y: float = [half.y, half.y - bevel, -half.y + bevel, -half.y][layer]
		var ring: PackedVector3Array = PackedVector3Array()
		for point: Vector2 in [Vector2(-x + bevel,-z),Vector2(x - bevel,-z),Vector2(x,-z + bevel),Vector2(x,z - bevel),Vector2(x - bevel,z),Vector2(-x + bevel,z),Vector2(-x,z - bevel),Vector2(-x,-z + bevel)]:
			ring.append(Vector3(point.x,y,point.y))
		rings.append(ring)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer: int in 3:
		for i: int in 8:
			var next: int = (i + 1) % 8
			for point: Vector3 in [rings[layer][i],rings[layer + 1][i],rings[layer][next],rings[layer][next],rings[layer + 1][i],rings[layer + 1][next]]:
				surface.add_vertex(point)
	for i: int in 8:
		var next: int = (i + 1) % 8
		for point: Vector3 in [Vector3(0,half.y,0),rings[0][i],rings[0][next],Vector3(0,-half.y,0),rings[3][next],rings[3][i]]:
			surface.add_vertex(point)
	surface.generate_normals()
	return _mesh(parent, surface.commit(), at, material)

func _apply_attack_weight() -> void:
	# Keep the root/feet stable; a small authored-direction shift weights the cut.
	var offset: float = 0.0
	if not _dead and _animation.current_animation == _clip("execution_cut") and not AudioManager.reduced_motion:
		var t: float = _attack_phase_time()
		if t < 0.20: offset = lerpf(0.0,-0.035,smoothstep(0.0,0.20,t))
		elif t < 0.32: offset = lerpf(-0.035,0.065,smoothstep(0.20,0.32,t))
		else: offset = lerpf(0.065,0.0,smoothstep(0.32,0.76,t))
	_model.position.z = offset
	# The Sentinel presents its chest in guard, then turns into the hammer strike.
	# This is body mechanics, so it remains enabled with reduced camera motion.
	var turn: float = 0.0
	if hostile and archetype == "sentinel" and _animation.current_animation == _clip("execution_cut"):
		var t: float = _attack_phase_time()
		turn = smoothstep(0.0, 0.20, t) if t < 0.40 else 1.0 - smoothstep(0.40, 0.76, t)
	_model.rotation.y = PI - 0.35 * turn

func at_contact() -> bool:
	return _animation.current_animation != _clip("execution_cut") or _animation.current_animation_position >= contact_time()

func prepare_contact() -> void:
	if _dead: return
	_trail_points.clear()
	_trail.mesh = null
	if _animation.current_animation != _clip("execution_cut"):
		_animation.play(_clip("execution_cut"),0.0)
	_animation.seek(contact_time(),true)
	_skeleton.force_update_all_bone_transforms()
	_apply_attack_weight()
	_align_weapon()
