extends IllustratedActor
## Meshy skin in the existing arena. Combat state remains in the controller.
const MODEL: PackedScene = preload("res://assets/characters/meshy/meshy_character.glb")
const TRACKS: Dictionary = preload("res://assets/animations/relics/relic_tracks.gd").DATA
var viewport: SubViewport
var model: Node3D
var animator: AnimationPlayer
var skeleton: Skeleton3D
var camera: Camera3D
var _clock: float = 0.0
var _duration: float = 1.0
var _contact: float = -1.0
var _action: String = "idle"
var _fallen: bool = false
var _home: Vector2
var _entrance_offset: Vector2
var _recoil: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home = position
	viewport = SubViewport.new()
	viewport.name = "MeshyCharacterViewport"
	viewport.size = Vector2i(960, 960)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var world: Node3D = Node3D.new()
	viewport.add_child(world)
	var env_node: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("83b9c7")
	env.ambient_light_energy = 0.18
	# Metallic armor needs an environment to reflect; the transparent viewport
	# otherwise supplies black reflections regardless of the painted arena.
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("3b6f87")
	sky_material.sky_horizon_color = Color("b5d3cf")
	sky_material.ground_horizon_color = Color("8f7862")
	sky_material.ground_bottom_color = Color("182731")
	sky_material.sky_energy_multiplier = 0.65
	sky_material.ground_energy_multiplier = 0.35
	env.sky = Sky.new()
	env.sky.sky_material = sky_material
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env_node.environment = env
	world.add_child(env_node)
	model = MODEL.instantiate() as Node3D
	world.add_child(model)
	model.rotation.y = 0.65
	animator = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip: String in ["Idle", "Walking", "Running"]:
		animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	for spec: Array in [[Vector3(-3,4,2), Color("86dcf0"), 1.5], [Vector3(3,2,-2), Color("ffc07a"), 1.8], [Vector3(0,2,4), Color("cfddde"), 0.30]]:
		var light: DirectionalLight3D = DirectionalLight3D.new()
		world.add_child(light)
		light.position = spec[0]
		light.light_color = spec[1]
		light.light_energy = spec[2]
		light.look_at(Vector3(0,1,0))
		light.shadow_enabled = true
		light.directional_shadow_max_distance = 10.0
		light.shadow_bias = 0.015
		light.shadow_normal_bias = 0.2
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.0
	world.add_child(camera)
	camera.position = Vector3(0, 1.6, 5)
	camera.look_at(Vector3(0, 1.6, 0))
	_front = TextureRect.new()
	_front.name = "MeshyRenderedSkin"
	_front.texture = viewport.get_texture()
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.size = Vector2(960,960)
	_pose_origin = Vector2(size.x * 0.5 - 480, size.y - 45 - 864)
	_front.position = _pose_origin
	add_child(_front)
	_sample("Idle", 0.0)

func _sample(clip: String, time: float) -> void:
	if animator.current_animation != clip: animator.play(clip)
	animator.seek(time, true)
	skeleton.force_update_all_bone_transforms()

func _process(delta: float) -> void:
	if _fallen: return
	var dt: float = delta * AudioManager.animation_speed_scale()
	_clock += dt
	_recoil = maxf(0.0, _recoil - dt * 4.0)
	_front.position = _pose_origin + Vector2(-sin(_recoil * PI) * 16.0, 0)
	if _action == "entrance":
		_advance_entrance()
		return
	if not _busy:
		_sample("Idle", 0.0 if AudioManager.reduced_motion else fmod(_clock, 3.0))
		return
	if _contact >= 0.0 and _clock >= _contact: _contact_ready = true
	var progress: float = clampf(_clock / _duration, 0.0, 1.0)
	if _action == "fall":
		_sample("Guard_Raise", minf(_clock, 0.6))
		model.rotation.z = lerpf(0.0, 1.3, smoothstep(0.0, 1.0, progress))
		model.position.y = -0.3 * progress
		_front.modulate.a = 1.0 - smoothstep(0.55, 1.0, progress)
	elif _action == "attack":
		_sample("Guard_Raise", minf(0.58, _clock))
		# Interim overlay, synchronized to existing relic contact markers.
		var strike: float = smoothstep(_contact - 0.32, _contact, _clock) * (1.0 - smoothstep(_contact + 0.1, _duration, _clock))
		_rotate_bone("RightArm", Vector3.FORWARD, -0.65 * strike)
		_rotate_bone("RightForeArm", Vector3.UP, 0.85 * strike)
		_rotate_bone("Spine2", Vector3.UP, -0.25 * strike)
		model.position.x = 0.16 * strike if not AudioManager.reduced_motion else 0.0
	else:
		_sample("Guard_Raise", sin(progress * PI) * 0.65)
	if progress >= 1.0:
		if _action == "fall":
			_fallen = true
			_busy = false
			_contact_ready = true
		else: _rest()

func _bone(bone_name: String) -> int:
	var index: int = skeleton.find_bone("mixamorig_" + bone_name)
	if index < 0: index = skeleton.find_bone("mixamorig:" + bone_name)
	return index if index >= 0 else skeleton.find_bone(bone_name)

func _rotate_bone(bone_name: String, axis: Vector3, amount: float) -> void:
	var index: int = _bone(bone_name)
	if index >= 0:
		skeleton.set_bone_pose_rotation(index, skeleton.get_bone_pose_rotation(index) * Quaternion(axis, amount * (0.25 if AudioManager.reduced_motion else 1.0)))

func play_action(action_name: String, profile: Dictionary = {}) -> void:
	if _fallen: return
	var duration: float = float(profile.get("rig_duration", 1.2))
	var contact: float = float(profile.get("rig_contact", 0.6))
	if profile.is_empty():
		for clip: Dictionary in TRACKS.clips.values():
			if str(clip.actor_action) == action_name:
				duration = float(clip.duration)
				contact = float(clip.contact)
				break
	_action = "guard"
	_clock = 0.0
	_duration = maxf(0.1, duration)
	_contact = contact
	_contact_ready = false
	_busy = true

func attack(profile: Dictionary = {}) -> void:
	play_action(str(profile.get("rig_action", "iron_strike")), profile)
	_action = "attack"
	if not profile.has("rig_contact"):
		_contact = float(profile.get("anticipation", .2)) + float(profile.get("travel", .1))
		_duration = _contact + float(profile.get("impact_hold", .05)) + float(profile.get("recovery", .35))

func hit(blocked: bool, _profile: Dictionary = {}) -> void:
	_recoil = 0.0 if AudioManager.reduced_motion else 1.0
	# Incoming hits must never interrupt the outgoing contact signal.
	if not _busy: play_action("guard_hit" if blocked else "hit")

func fall() -> void:
	_action = "fall"
	_duration = 1.1
	_clock = 0.0
	_busy = true
	_contact_ready = true

func _rest() -> void:
	_busy = false
	_action = "idle"
	_clock = 0.0
	model.position = Vector3.ZERO
	position = _home
	scale = Vector2.ONE
	_sample("Idle", 0.0)

func begin_entrance(perch_global: Vector2) -> void:
	if AudioManager.reduced_motion:
		_rest()
		return
	_action = "entrance"
	_busy = true
	_clock = 0.0
	var perch: Vector2 = get_parent().get_global_transform().affine_inverse() * perch_global
	_entrance_offset = perch - (_home + Vector2(size.x * .5, size.y - 45))
	_advance_entrance()

func _advance_entrance() -> void:
	pivot_offset = Vector2(size.x * .5, size.y - 45)
	var perch_position: Vector2 = _home + _entrance_offset + Vector2(0, 288 * .45)
	if _clock < 0.55:
		scale = Vector2.ONE * .45
		position = perch_position
		model.position.y = 1.2
		_sample("Idle", _clock)
	elif _clock < 2.35:
		var p: float = smoothstep(.55, 2.35, _clock)
		scale = Vector2.ONE * lerpf(.45, 1.0, p)
		model.position.y = 0.0
		position = perch_position.lerp(_home + Vector2(-160, 0), p)
		_sample("Jump_Down", _clock - .55)
	elif _clock < 3.65:
		var p: float = clampf((_clock - 2.35) / 1.3, 0, 1)
		scale = Vector2.ONE
		position = _home + Vector2(-160 * (1.0 - p), 0)
		_sample("Walking", fmod(_clock - 2.35, 1.0))
	else: _rest()

func anchor_position(anchor: String, global_space: bool = true) -> Vector2:
	var bone: String = "Spine2"
	match anchor:
		"hand", "hand_near": bone = "RightHand"
		"hand_far": bone = "LeftHand"
		"head": bone = "Head"
		"feet": bone = "LeftFoot"
	var index: int = _bone(bone)
	var world: Vector3 = model.global_position
	if index >= 0: world = skeleton.to_global(skeleton.get_bone_global_pose(index).origin)
	if anchor == "feet" and _action != "entrance": world = model.global_position
	var local: Vector2 = _front.position + camera.unproject_position(world)
	return get_global_transform() * local if global_space else local

func get_hand_global_position() -> Vector2:
	return anchor_position("hand")

func is_busy() -> bool:
	return _busy

func contact_ready() -> bool:
	return _contact_ready

func set_pose(_frame: int) -> void:
	pass
