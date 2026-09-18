class_name DirectedArena extends Control
## Real-time stage. Gameplay remains authoritative; all movement is presentation.
var player: Node3D
var enemy: Node3D
var _kind := "stalker"
var _world: Node3D
var _view: SubViewport
var _camera: Camera3D
var _camera_motion: Tween
var _impact_light: OmniLight3D
var _home := Vector3(0, 2.45, 6.45)
var _look := Vector3(0, 1.1, 0)
var _elapsed := 0.0
var _finished := false
var _sparks: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view = SubViewport.new()
	_view.size = Vector2i(1920, 776)
	_view.msaa_3d = Viewport.MSAA_4X
	_view.own_world_3d = true
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	var screen := TextureRect.new()
	screen.texture = _view.get_texture()
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_resize_view)
	_world = Node3D.new()
	_view.add_child(_world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("111b25")
	var sky := Sky.new()
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = load("res://assets/environments/materials/abandoned_workshop_1k.hdr")
	panorama.energy_multiplier = 0.38
	sky.sky_material = panorama
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a2b4c8")
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("263341")
	env.fog_density = 0.008
	environment.environment = env
	_world.add_child(environment)
	_camera = Camera3D.new()
	_world.add_child(_camera)
	_camera.position = _home
	_camera.fov = 32
	_camera.look_at(_look)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -30, 0)
	key.light_color = Color("c4dfef")
	key.light_energy = 1.1
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 24
	_world.add_child(key)
	_light(Vector3(-3, 3.5, 1.5), Color("a1ccdf"), 1.8, 7)
	_light(Vector3(3, 3.8, -1.5), Color("ffbd77"), 2.8, 8)
	_impact_light = _light(Vector3(0, 1.2, 0.6), Color("ffcc83"), 0, 3)
	_build_environment()
	player = preload("res://scripts/combat/rigged_combatant.gd").new()
	_world.add_child(player)
	player.position = Vector3(-0.9, 0, 0.2)
	player.rotation.y = 1.4
	_replace_enemy()

func _light(at: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	_world.add_child(light)
	return light

func _material(color: Color, metal: float = 0.0, rough: float = 0.6) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metal
	result.roughness = rough
	return result

func _mesh(shape: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.position = at
	instance.material_override = material
	_world.add_child(instance)
	return instance

func _build_environment() -> void:
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(60, 60)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_texture = load("res://assets/environments/materials/stone_tiles_diff_2k.jpg")
	floor_mat.albedo_color = Color(0.24,0.29,0.33)
	floor_mat.normal_enabled = true
	floor_mat.normal_texture = load("res://assets/environments/materials/stone_tiles_nor_gl_2k.jpg")
	floor_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	floor_mat.normal_scale = 0.35
	floor_mat.roughness_texture = load("res://assets/environments/materials/stone_tiles_rough_2k.jpg")
	floor_mat.roughness = 1.0
	floor_mat.uv1_scale = Vector3(18,18,18)
	_mesh(floor_mesh, Vector3(0, -0.025, 0), floor_mat)
	var bronze := _material(Color("655039"), 0.78, 0.36)
	var stone := _material(Color("202b32"), 0.1, 0.8)
	# Embedded concentric chronometer rings, physically sharing the fighter floor.
	for radius in [2.8, 3.0, 3.65, 3.72]:
		var ring := TorusMesh.new()
		ring.inner_radius = radius - 0.014
		ring.outer_radius = radius + 0.014
		ring.rings = 96
		ring.ring_segments = 8
		_mesh(ring, Vector3(0, -0.003, 0), bronze)
	for major in [false,true]:
		var mark := BoxMesh.new()
		mark.size = Vector3(0.035,0.008,0.24 if major else 0.09)
		mark.material = bronze
		var marks := MultiMesh.new()
		marks.transform_format = MultiMesh.TRANSFORM_3D
		marks.mesh = mark
		marks.instance_count = 12 if major else 36
		var instance_index := 0
		for i in range(48):
			if (i%4==0) != major: continue
			var angle := i*TAU/48.0
			marks.set_instance_transform(instance_index,Transform3D(Basis(Vector3.UP,angle),Vector3(sin(angle)*3.35,0.002,cos(angle)*3.35)))
			instance_index += 1
		var batched := MultiMeshInstance3D.new()
		batched.multimesh = marks
		batched.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_world.add_child(batched)
	# Receding architectural rhythm frames the action without crossing silhouettes.
	for side in [-1.0, 1.0]:
		for row in range(4):
			var at := Vector3(side * (5.8 + row * 0.8), 0, -2.5 - row * 3.5)
			var column := CylinderMesh.new()
			column.top_radius = 0.25
			column.bottom_radius = 0.36
			column.height = 7
			column.radial_segments = 24
			_mesh(column, at + Vector3(0, 3.5, 0), stone)
			for y in [0.12, 0.32, 2.1, 5.4]:
				var band := CylinderMesh.new()
				band.top_radius = 0.4
				band.bottom_radius = 0.43
				band.height = 0.09
				_mesh(band, at + Vector3(0, y, 0), bronze)
			if row < 2:
				var lamp_mat := _material(Color("ffb361"))
				lamp_mat.emission_enabled = true
				lamp_mat.emission = Color("ff9639")
				lamp_mat.emission_energy_multiplier = 3
				var lamp := SphereMesh.new()
				lamp.radius = 0.075
				lamp.height = 0.28
				_mesh(lamp, at + Vector3(-side * 0.3, 2.3, 0.1), lamp_mat)
	# Existing authored cathedral plate supplies distant architecture only.
	var backdrop := QuadMesh.new()
	backdrop.size = Vector2(48, 24)
	var background_mat := _material(Color(0.6, 0.65, 0.7))
	background_mat.albedo_texture = load("res://assets/environments/chronoforge_arena.png")
	background_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh(backdrop, Vector3(0, 1.8, -16), background_mat)

func configure_enemy(kind: String) -> void:
	_kind = kind
	if is_node_ready(): _replace_enemy()

func _replace_enemy() -> void:
	if is_instance_valid(enemy):
		_world.remove_child(enemy)
		enemy.queue_free()
	enemy = preload("res://scripts/combat/rigged_combatant.gd").new()
	enemy.hostile = true
	enemy.archetype = _kind
	_world.add_child(enemy)
	enemy.position = Vector3(0.9, 0, -0.1)
	enemy.rotation.y = -1.4
	if _kind in ["sentinel", "bulwark", "twin", "eclipse"]: enemy.scale *= 1.14
	player.opponent = enemy
	enemy.opponent = player

func _resize_view() -> void:
	if _view and size.x > 0 and size.y > 0:
		var render_width := mini(1920,roundi(size.x))
		_view.size = Vector2i(render_width,roundi(render_width * size.y / size.x))

func attack(from_player: bool) -> void:
	if _finished: return
	(player if from_player else enemy).attack()
	if AudioManager.reduced_motion: return
	if _camera_motion and _camera_motion.is_valid(): _camera_motion.kill()
	_camera_motion = create_tween().set_speed_scale(AudioManager.animation_speed_scale())
	_camera_motion.set_parallel(true)
	_camera_motion.tween_property(_camera, "fov", 30.8, 0.3).set_trans(Tween.TRANS_SINE)
	_camera_motion.tween_property(_camera, "h_offset", -0.06 if from_player else 0.06, 0.3)

func impact(on_player: bool, blocked: bool) -> void:
	(player if on_player else enemy).hit(blocked)
	var target: Vector3 = (player if on_player else enemy).position + Vector3(0, 1.25, 0.2)
	_impact_light.position = target
	_impact_light.light_color = Color("8ceaff") if blocked else Color("ffd296")
	_impact_light.light_energy = 2.8 if blocked else 4.0
	create_tween().tween_property(_impact_light, "light_energy", 0.0, 0.2)
	_emit_sparks(target, blocked)
	if AudioManager.reduced_motion: return
	if _camera_motion and _camera_motion.is_valid(): _camera_motion.kill()
	_camera.h_offset += -0.025 if on_player else 0.025
	_camera_motion = create_tween().set_speed_scale(AudioManager.animation_speed_scale())
	_camera_motion.set_parallel(true)
	_camera_motion.tween_property(_camera, "h_offset", 0.0, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_camera_motion.tween_property(_camera, "fov", 32.0, 0.48).set_trans(Tween.TRANS_SINE)

func _emit_sparks(at: Vector3, blocked: bool) -> void:
	var mat := _material(Color("81deff") if blocked else Color("ffd08a"))
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(12):
		var spark_mesh := SphereMesh.new()
		spark_mesh.radius = 0.012
		spark_mesh.height = 0.06
		spark_mesh.radial_segments = 4
		spark_mesh.rings = 2
		var spark := _mesh(spark_mesh, at, mat)
		_sparks.append({"node": spark, "velocity": Vector3(randf_range(-2.2,2.2),randf_range(0.7,2.8),randf_range(-0.6,1.4)), "life": 0.0})

func _process(delta: float) -> void:
	_elapsed += delta
	for i in range(_sparks.size() - 1, -1, -1):
		var p: Dictionary = _sparks[i]
		p.life += delta
		p.velocity.y -= delta * 8.5
		p.node.position += p.velocity * delta
		p.node.scale = Vector3.ONE * maxf(0.0, 1.0 - p.life / 0.42)
		if p.life > 0.42:
			p.node.queue_free()
			_sparks.remove_at(i)

func finish(won: bool) -> void:
	_finished = true
	(enemy if won else player).fall()
	if not AudioManager.reduced_motion:
		if _camera_motion and _camera_motion.is_valid(): _camera_motion.kill()
		_camera_motion = create_tween()
		_camera_motion.tween_property(_camera, "fov", 29.8, 0.75).set_trans(Tween.TRANS_SINE)

func impact_delay() -> float:
	return 0.32

func recovery_delay() -> float:
	return 0.44

func finish_delay() -> float:
	return 1.45

func impact_position(on_player: bool) -> Vector2:
	var actor: Node3D = player if on_player else enemy
	var point := _camera.unproject_position(actor.global_position + Vector3(0,1.4,0))
	return global_position + point * size / Vector2(_view.size)
