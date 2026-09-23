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
var _composition_motion: Tween
var _decision_visible: bool = true
var _look := Vector3(0, 1.1, 0)
var _elapsed := 0.0
var _finished := false
var _attacking_player: bool = true
var _sparks: Array[Dictionary] = []
var _spark_batch: MultiMeshInstance3D
var _spark_instances: MultiMesh
var _ability_motion: Tween
var _attack_profile: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view = SubViewport.new()
	_view.size = Vector2i(1920, 776)
	_view.msaa_3d = Viewport.MSAA_2X
	_view.own_world_3d = true
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	var screen := TextureRect.new()
	screen.texture = _view.get_texture()
	var grade: ShaderMaterial = ShaderMaterial.new()
	grade.shader = preload("res://assets/shaders/cinematic_grade.gdshader")
	screen.material = grade
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_resize_view)
	AudioManager.settings_changed.connect(_on_settings_changed)
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
	env.ambient_light_color = Color("8296ab")
	env.ambient_light_energy = 0.12
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("263341")
	env.fog_density = 0.008
	environment.environment = env
	_world.add_child(environment)
	_camera = Camera3D.new()
	_world.add_child(_camera)
	_camera.position = _home
	_camera.fov = 39
	_camera.v_offset = 0.78
	_camera.look_at(_look)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -30, 0)
	key.light_color = Color("c4dfef")
	key.light_energy = 0.85
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 14
	_world.add_child(key)
	_light(Vector3(-3, 3.5, 1.5), Color("a1ccdf"), 1.35, 7)
	_light(Vector3(3, 3.8, -1.5), Color("ffbd77"), 2.8, 8)
	_impact_light = _light(Vector3(0, 1.2, 0.6), Color("ffcc83"), 0, 3)
	_build_environment()
	player = preload("res://scripts/combat/rigged_combatant.gd").new()
	_world.add_child(player)
	player.position = Vector3(-0.72, 0, 0.2)
	player.rotation.y = 1.4
	_replace_enemy()
	_add_contact_shadow(player)

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
	var floor_mat: ShaderMaterial = ShaderMaterial.new()
	floor_mat.shader = preload("res://assets/shaders/arena_stone.gdshader")
	floor_mat.set_shader_parameter("stone_color",load("res://assets/environments/materials/stone_tiles_diff_2k.jpg"))
	floor_mat.set_shader_parameter("stone_normal",load("res://assets/environments/materials/stone_tiles_nor_gl_2k.jpg"))
	floor_mat.set_shader_parameter("stone_roughness",load("res://assets/environments/materials/stone_tiles_rough_2k.jpg"))
	_mesh(floor_mesh, Vector3(0, -0.025, 0), floor_mat)
	var bronze := _material(Color("655039"), 0.78, 0.36)
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
		marks.instance_count = 9 if major else 27
		var instance_index := 0
		for i in range(36):
			if (i%4==0) != major: continue
			var angle := i*TAU/36.0
			marks.set_instance_transform(instance_index,Transform3D(Basis(Vector3.UP,angle),Vector3(sin(angle)*3.35,0.002,cos(angle)*3.35)))
			instance_index += 1
		var batched := MultiMeshInstance3D.new()
		batched.name = "FloorMajorHours" if major else "FloorMinorTicks"
		batched.multimesh = marks
		batched.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_world.add_child(batched)
	# Dressed-stone bundled piers replace smooth metal-banded cylinders.
	var architecture: CathedralArchitecture = CathedralArchitecture.new()
	architecture.name = "CathedralArchitecture"
	_world.add_child(architecture)
	# A real stepped dais bridges the floor and the distant cathedral plate.
	var step_mat: ShaderMaterial = floor_mat.duplicate()
	step_mat.set_shader_parameter("tile_scale",Vector2(3,1))
	for level: int in 3:
		var step: BoxMesh = BoxMesh.new()
		step.size = Vector3(9.0-level*0.4,0.16,3.5-level*0.45)
		_mesh(step,Vector3(0,0.08+level*0.16,-6.0-level*0.22),step_mat)
	# Forged baskets retain the two existing local warm lights.
	for side: float in [-1.0,1.0]:
		var brazier: ArenaBrazier = ArenaBrazier.new()
		brazier.name = "BrazierLeft" if side < 0 else "BrazierRight"
		brazier.position = Vector3(side*3.0,0,-4.2)
		_world.add_child(brazier)
	# Existing authored cathedral plate supplies distant architecture only.
	var backdrop := QuadMesh.new()
	backdrop.size = Vector2(48, 24)
	var background_mat := _material(Color(0.6, 0.65, 0.7))
	background_mat.albedo_texture = load("res://assets/environments/chronoforge_arena.png")
	background_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh(backdrop, Vector3(0, 1.8, -16), background_mat)

func configure_enemy(kind: String) -> void:
	_kind = "boneghoul" if kind == "stalker" and OS.get_cmdline_user_args().has("--boneghoul-3d") else kind
	if kind == "bulwark" and OS.get_cmdline_user_args().has("--custodian-3d"): _kind = "custodian"
	if is_node_ready(): _replace_enemy()

func _replace_enemy() -> void:
	if is_instance_valid(enemy):
		_world.remove_child(enemy)
		enemy.queue_free()
	if _kind == "custodian":
		enemy = CustodianActor.new()
	elif _kind == "boneghoul":
		enemy = BoneghoulActor.new()
	else:
		enemy = preload("res://scripts/combat/rigged_combatant.gd").new()
		enemy.hostile = true
		enemy.archetype = _kind
	_world.add_child(enemy)
	enemy.position = Vector3(0.9, 0, -0.1)
	enemy.rotation.y = -1.05 if _kind == "sentinel" else -1.4
	if _kind in ["sentinel", "bulwark", "twin", "eclipse"]: enemy.scale *= 1.14
	player.opponent = enemy
	if (enemy is BoneghoulActor or enemy is CustodianActor):
		enemy.position = Vector3(0.505534, 0.0, -0.02731)
		enemy.rotation.y = -1.064631
	else:
		enemy.opponent = player
	_add_contact_shadow(enemy)

func _resize_view() -> void:
	if _view and size.x > 0 and size.y > 0:
		var limit: int = 1600
		if AudioManager.render_quality == "balanced": limit = 1280
		elif AudioManager.render_quality == "performance": limit = 960
		var render_width: int = mini(limit,mini(get_window().size.x,roundi(size.x)))
		var render_size: Vector2i = Vector2i(render_width,roundi(render_width * size.y / size.x))
		if _view.size != render_size: _view.size = render_size

func _on_settings_changed(_settings: Dictionary) -> void:
	_resize_view()
	_update_composition(false)

func set_decision_view(visible_choices: bool) -> void:
	if _decision_visible == visible_choices: return
	_decision_visible = visible_choices
	_update_composition(true)

func _update_composition(animate: bool) -> void:
	if not is_instance_valid(_camera): return
	if _composition_motion and _composition_motion.is_valid(): _composition_motion.kill()
	var wide: bool = _decision_visible or AudioManager.reduced_motion
	var target_position: Vector3 = _home if wide else Vector3(0,2.45,5.8)
	var target_offset: float = (0.86 if AudioManager.text_size == "large" else 0.78) if wide else 0.35
	if not animate or AudioManager.reduced_motion:
		_camera.position = target_position
		_camera.v_offset = target_offset
		return
	_composition_motion = create_tween().set_parallel(true).set_speed_scale(AudioManager.animation_speed_scale())
	_composition_motion.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_composition_motion.tween_property(_camera,"position",target_position,0.32)
	_composition_motion.tween_property(_camera,"v_offset",target_offset,0.32)

func attack(from_player: bool, profile: Dictionary = {}) -> void:
	if _finished: return
	_attacking_player = from_player
	_attack_profile = profile
	var actor: Node3D = player if from_player else enemy
	if actor is RiggedCombatant: actor.attack(profile)
	else: actor.attack()
	if from_player and AttackPresentation.is_heavy_hammer(profile): _play_heavy_lunge(actor, enemy)
	if AudioManager.reduced_motion: return
	if _camera_motion and _camera_motion.is_valid(): _camera_motion.kill()
	_camera_motion = create_tween().set_speed_scale(AudioManager.animation_speed_scale())
	_camera_motion.set_parallel(true)
	_camera_motion.tween_property(_camera, "fov", 38.2, 0.3).set_trans(Tween.TRANS_SINE)
	_camera_motion.tween_property(_camera, "h_offset", -0.06 if from_player else 0.06, 0.3)

func impact(on_player: bool, blocked: bool, profile: Dictionary = {}) -> void:
	if _finished: return
	(player if on_player else enemy).hit(blocked)
	var target: Vector3 = contact_point(on_player)
	_impact_light.position = target
	var heavy: bool = AttackPresentation.is_heavy_hammer(profile)
	_impact_light.light_color = Color("8ceaff") if blocked else (Color("ff9d42") if heavy else Color("ffd296"))
	_impact_light.light_energy = 2.8 if blocked else (6.8 if heavy else 4.0)
	create_tween().tween_property(_impact_light, "light_energy", 0.0, 0.2)
	_emit_sparks(target, blocked, 22 if heavy else 12, Color("ffad52") if heavy else Color.TRANSPARENT)
	if blocked: guard_pulse(on_player)
	if AudioManager.reduced_motion: return
	if _camera_motion and _camera_motion.is_valid(): _camera_motion.kill()
	_camera.h_offset += (-0.055 if on_player else 0.055) if heavy else (-0.025 if on_player else 0.025)
	_camera_motion = create_tween().set_speed_scale(AudioManager.animation_speed_scale())
	_camera_motion.set_parallel(true)
	_camera_motion.tween_property(_camera, "h_offset", 0.0, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_camera_motion.tween_property(_camera, "fov", 39.0, 0.48).set_trans(Tween.TRANS_SINE)

func _emit_sparks(at: Vector3, blocked: bool, count: int = 12, accent: Color = Color.TRANSPARENT) -> void:
	if not is_instance_valid(_spark_batch):
		var mat: StandardMaterial3D = _material(Color.WHITE)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		var spark_mesh := SphereMesh.new()
		spark_mesh.radius = 0.012
		spark_mesh.height = 0.06
		spark_mesh.radial_segments = 4
		spark_mesh.rings = 2
		spark_mesh.material = mat
		_spark_instances = MultiMesh.new()
		_spark_instances.transform_format = MultiMesh.TRANSFORM_3D
		_spark_instances.use_colors = true
		_spark_instances.mesh = spark_mesh
		_spark_instances.instance_count = 32
		_spark_instances.visible_instance_count = 0
		_spark_batch = MultiMeshInstance3D.new()
		_spark_batch.name = "ImpactSparks"
		_spark_batch.multimesh = _spark_instances
		_spark_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_world.add_child(_spark_batch)
	for i in range(count):
		var spark_color: Color = accent if accent.a > 0.0 else (Color("81deff") if blocked else Color("ffd08a"))
		_sparks.append({"position": at, "color":spark_color, "velocity": Vector3(randf_range(-2.2,2.2),randf_range(0.7,2.8),randf_range(-0.6,1.4)), "life": 0.0})
	_sync_sparks()

func _sync_sparks() -> void:
	if not is_instance_valid(_spark_batch): return
	# Capacity grows only on unusually overlapping hits and is then reused.
	if _sparks.size() > _spark_instances.instance_count:
		_spark_instances.instance_count = maxi(_sparks.size(),_spark_instances.instance_count*2)
	_spark_instances.visible_instance_count = _sparks.size()
	_spark_batch.visible = not _sparks.is_empty()
	for index: int in range(_sparks.size()):
		var particle: Dictionary = _sparks[index]
		var scale_amount: float = maxf(0.0,1.0-particle.life/0.42)
		_spark_instances.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_amount),particle.position))
		_spark_instances.set_instance_color(index,particle.color)

func _process(delta: float) -> void:
	_elapsed += delta
	for i in range(_sparks.size() - 1, -1, -1):
		var p: Dictionary = _sparks[i]
		p.life += delta
		p.velocity.y -= delta * 8.5
		p.position += p.velocity * delta
		if p.life > 0.42:
			_sparks.remove_at(i)
	if is_instance_valid(_spark_batch) and (_spark_instances.visible_instance_count > 0 or not _sparks.is_empty()):
		_sync_sparks()

func finish(won: bool) -> void:
	if _finished: return
	_finished = true
	(enemy if won else player).fall()
	if not AudioManager.reduced_motion:
		if _camera_motion and _camera_motion.is_valid(): _camera_motion.kill()
		_camera_motion = create_tween()
		_camera_motion.tween_property(_camera, "fov", 37.5, 0.75).set_trans(Tween.TRANS_SINE)

func impact_delay() -> float:
	var actor: Node3D = player if _attacking_player else enemy
	return actor.contact_time()

func swing_delay(from_player: bool) -> float:
	var actor: Node3D = player if from_player else enemy
	return maxf(0.0, actor.contact_time() - 0.32)

func recovery_delay() -> float:
	var actor: Node3D = player if _attacking_player else enemy
	return actor.recovery_time()

func finish_delay() -> float:
	if (enemy is BoneghoulActor or enemy is CustodianActor): return finish_fade_delay() + 0.3
	return 1.45

func finish_fade_delay() -> float:
	return 1.6 / AudioManager.animation_speed_scale() + 0.1 if (enemy is BoneghoulActor or enemy is CustodianActor) else 1.15

func prepare_defense(on_player: bool, fully_blocked: bool) -> void:
	var target: Node3D = player if on_player else enemy
	if fully_blocked and target.has_method("prepare_guard"):
		target.prepare_guard()

func impact_position(on_player: bool) -> Vector2:
	var point := _camera.unproject_position(contact_point(on_player))
	return global_position + point * size / Vector2(_view.size)

func _add_contact_shadow(actor: Node3D) -> void:
	var shadow: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(1.5, 1.15)
	shadow.mesh = plane
	shadow.position.y = 0.006
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader: Shader = Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, blend_mix, depth_draw_never, cull_disabled; void fragment(){ float d=length((UV-vec2(0.5))*2.0); ALBEDO=vec3(0.008,0.01,0.015); ALPHA=(1.0-smoothstep(0.08,1.0,d))*0.56; }"
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	shadow.material_override = material
	actor.add_child(shadow)

func guard_pulse(on_player: bool) -> void:
	var actor: Node3D = player if on_player else enemy
	var braced: bool = (actor is BoneghoulActor or actor is CustodianActor) and actor.is_guarding()
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.15 if braced else 0.40
	ring.outer_radius = 0.17 if braced else 0.42
	ring.rings = 40
	ring.ring_segments = 6
	var material: StandardMaterial3D = _material(Color("72dce9"))
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	var location: Vector3 = contact_point(on_player) if braced else actor.position + Vector3(0, 1.10, 0.32)
	var effect: MeshInstance3D = _mesh(ring, location, material)
	effect.name = "GuardPulse"
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	effect.rotation.x = PI * 0.5
	var pulse: Tween = create_tween().set_parallel(true)
	if not AudioManager.reduced_motion:
		effect.scale = Vector3.ONE * 0.75
		pulse.tween_property(effect, "scale", Vector3.ONE * 1.25, 0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	pulse.tween_property(material, "albedo_color:a", 0.0, 0.40)
	pulse.chain().tween_callback(effect.queue_free)

func _batch(shape: Mesh, transforms: Array[Transform3D], material: Material) -> void:
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = shape
	multimesh.instance_count = transforms.size()
	for i: int in transforms.size(): multimesh.set_instance_transform(i,transforms[i])
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	_world.add_child(instance)

func contact_point(on_player: bool) -> Vector3:
	var target: Node3D = player if on_player else enemy
	var attacker: Node3D = enemy if on_player else player
	if target.has_method("is_guarding") and target.is_guarding():
		return target.guard_contact_point(attacker.global_position)
	if on_player and ((enemy is BoneghoulActor and enemy.state == BoneghoulActor.State.ATTACK) or (enemy is CustodianActor and enemy.state == CustodianActor.State.ATTACK)):
		return enemy.claw_tip()
	var facing: Vector3 = (attacker.global_position-target.global_position).normalized()
	return target.global_position + Vector3.UP*1.45 + facing*0.12

func await_contact(from_player: bool) -> void:
	var actor: Node3D = player if from_player else enemy
	while is_instance_valid(actor) and not _finished and not actor._dead and not actor.at_contact():
		await get_tree().process_frame
	if is_instance_valid(actor) and not _finished: actor.prepare_contact()


func _play_heavy_lunge(actor: Node3D, target: Node3D) -> void:
	if AudioManager.reduced_motion: return
	if _ability_motion and _ability_motion.is_valid(): _ability_motion.kill()
	var origin: Vector3 = actor.position
	var direction: Vector3 = (target.position - origin).normalized()
	var crouch: Vector3 = origin - direction * 0.08 + Vector3.DOWN * 0.035
	var airborne: Vector3 = origin.lerp(target.position, 0.27) + Vector3.UP * 0.18
	_ability_motion = create_tween().set_speed_scale(AudioManager.animation_speed_scale())
	_ability_motion.tween_property(actor, "position", crouch, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_ability_motion.tween_property(actor, "position", airborne, 0.20).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_ability_motion.tween_interval(0.055)
	_ability_motion.tween_property(actor, "position", origin, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func set_intro_hidden() -> void:
	player.hide()
	enemy.hide()


func reveal_combatant(from_player: bool) -> void:
	var actor: Node3D = player if from_player else enemy
	var target_scale: Vector3 = actor.scale
	actor.show()
	_spawn_entry_ring(actor, Color("70d8e4") if from_player else Color("e08b69"))
	if AudioManager.reduced_motion: return
	actor.scale = target_scale * 0.82
	var reveal := create_tween().set_speed_scale(AudioManager.animation_speed_scale())
	reveal.tween_property(actor, "scale", target_scale, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _spawn_entry_ring(actor: Node3D, color: Color) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.35
	ring.outer_radius = 0.38
	ring.rings = 48
	ring.ring_segments = 6
	var material := _material(color)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.75
	var effect := _mesh(ring, actor.position + Vector3.UP * 0.015, material)
	effect.rotation.x = PI * 0.5
	effect.scale = Vector3.ONE * 0.35
	var pulse := create_tween().set_parallel(true)
	pulse.tween_property(effect, "scale", Vector3.ONE * 1.35, 0.34).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	pulse.tween_property(material, "albedo_color:a", 0.0, 0.34)
	pulse.chain().tween_callback(effect.queue_free)
