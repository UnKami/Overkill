class_name Executioner3DActor extends IllustratedActor
## Live glTF skin in a transparent 3D viewport, preserving the battle interface.
const MODEL: PackedScene = preload("res://assets/characters/executioner/three_d/executioner_painted.glb")
const MOTION: Dictionary = preload("res://assets/characters/executioner/three_d/motion_data.gd").DATA
var anatomy_only: bool = false
var skeleton: Skeleton3D
var viewport: SubViewport
var camera: Camera3D
var model: Node3D
var _indices: PackedInt32Array = []
var _action_name: String = "idle"
var _action_time: float = 0.0
var _action_duration: float = 3.2
var _action_contact: float = -1.0
var _idle_phase: float = 0.0
var _fallen: bool = false
var _blend_time: float = 1.0
var _from: Array[Transform3D] = []
var _render_scale: float = 1.0
var _mesh_nodes: Array[MeshInstance3D] = []
var _aura_light: OmniLight3D
var _strike_offset: Vector3 = Vector3.ZERO
var _retarget_action: String = ""
var _crystals: Array[CPUParticles3D] = []
var _animator: AnimationPlayer
var _native_action: String = ""
var _bone_lookup: Dictionary = {}
var _weapon_geometry_owner: int = 0
var _weapon_geometry: PackedVector3Array = []
var _quality: String = ""
var _key_light: DirectionalLight3D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.name = "LiveCharacter3D"
	viewport.size = Vector2i(1200,709)
	viewport.transparent_bg = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	if OS.get_cmdline_user_args().has("--profile-aa2"):
		viewport.msaa_3d = Viewport.MSAA_2X
		viewport.mesh_lod_threshold = 1.5
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var character_scene: PackedScene = MODEL
	if OS.get_cmdline_user_args().has("--unpainted-material-review"):
		character_scene = load("res://assets/characters/executioner/three_d/executioner.glb") as PackedScene
		assert(character_scene != null,"The unpainted comparison source must be imported before review")
	model = character_scene.instantiate() as Node3D
	viewport.add_child(model)
	skeleton = _find_skeleton(model)
	var animators: Array[Node] = model.find_children("*","AnimationPlayer",true,false)
	assert(animators.size()==1,"The playable skin must retain its Blender animation library")
	_animator = animators[0] as AnimationPlayer
	_animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_animator.playback_auto_capture = false
	_animator.active = true
	assert(skeleton != null,"3D character requires a real imported skin skeleton")
	for node: Node in model.find_children("*","MeshInstance3D",true,false):
		_mesh_nodes.append(node as MeshInstance3D)
	for mesh: MeshInstance3D in _mesh_nodes:
		if anatomy_only: continue
		for surface: int in mesh.mesh.get_surface_count():
			var original: StandardMaterial3D = mesh.get_active_material(surface) as StandardMaterial3D
			if original == null: continue
			if original.albedo_texture == null: continue
			var styled: StandardMaterial3D = original.duplicate() as StandardMaterial3D
			styled.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			var material_name: String = original.resource_name.to_lower()
			var cloth: bool = material_name.contains("woven")
			var leather: bool = material_name.contains("leather")
			styled.albedo_color = Color(.80,.80,.80) if material_name.contains("painted pbr") else Color(.78,.78,.78) if cloth else Color(.45,.48,.53) if leather else Color(.70,.73,.78)
			if material_name.contains("painted pbr"):
				styled.metallic_specular = .35
				if OS.get_cmdline_user_args().has("--flat-normal-review"):
					styled.normal_enabled = false
			if cloth:
				styled.metallic_specular = 0.0
				styled.emission_enabled = false
				if OS.get_cmdline_user_args().has("--flat-normal-review"):
					styled.normal_enabled = false
			# Preserve the authored distinction between woven fabric, supple
			# leather and forged metal, including their physical roughness.
			mesh.set_surface_override_material(surface,styled)
	for entry: Dictionary in MOTION.bones:
		var index: int = skeleton.find_bone(str(entry.name))
		if index < 0: index = skeleton.find_bone(str(entry.name).replace(".","_"))
		assert(index >= 0,"Imported 3D bone is missing: "+str(entry.name))
		_indices.append(index)
		_bone_lookup[str(entry.name)] = index
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0,0,0,0)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a7bdd1")
	settings.ambient_light_energy = .40
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	viewport.add_child(environment)
	_key_light = _add_light(Vector3(-3,4,5),Color("c4e1ff"),1.65,true)
	_add_light(Vector3(4,2,-3),Color("ffc891"),1.20)
	_add_light(Vector3(2,3,4),Color("91bbd4"),.35)
	_aura_light = OmniLight3D.new()
	_aura_light.omni_range = 1.8
	_aura_light.light_energy = 0
	viewport.add_child(_aura_light)
	camera = Camera3D.new()
	viewport.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	# Crop unused transparent sky/floor while retaining horizontal reach and
	# the same texel density on the skin. Projection scale preserves anchors.
	camera.size = 3.7
	camera.position = Vector3(-4,2.25,5)
	camera.look_at(Vector3(0,1.05,0))
	_render_scale = target_height / (1.91*float(viewport.size.y)/camera.size)
	_art_scale = _render_scale
	_front = TextureRect.new()
	_front.name = "VolumetricCharacter"
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.texture = viewport.get_texture()
	_front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_front.stretch_mode = TextureRect.STRETCH_SCALE
	_front.size = Vector2(viewport.size)*_render_scale
	add_child(_front)
	var floor_point: Vector2 = camera.unproject_position(Vector3.ZERO)
	_front.position = Vector2(size.x*.5-floor_point.x*_render_scale,size.y-45-floor_point.y*_render_scale)
	_pose_origin = _front.position
	_apply_sample("idle",0.0)
	_create_crystals()
	_apply_render_quality()
	AudioManager.settings_changed.connect(_apply_render_quality)
	if OS.get_cmdline_user_args().has("--benchmark"):
		RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(),true)
		viewport.add_to_group("qa_render_measurements")

func _apply_render_quality(_settings: Dictionary = {}) -> void:
	if viewport == null or camera == null or _front == null: return
	var quality: String = AudioManager.render_quality
	if _quality == quality: return
	_quality = quality
	viewport.size = Vector2i(1200,709) if quality == "high" else Vector2i(900,532) if quality == "balanced" else Vector2i(720,425)
	viewport.msaa_3d = Viewport.MSAA_4X if quality == "high" else Viewport.MSAA_2X if quality == "balanced" else Viewport.MSAA_DISABLED
	if OS.get_cmdline_user_args().has("--profile-aa2"): viewport.msaa_3d = Viewport.MSAA_2X
	_key_light.shadow_enabled = quality != "performance"
	_update_projection()
	_update_projection.call_deferred()

func _update_projection() -> void:
	# All presets retain the same camera, aspect and world framing. Only the
	# render target changes; hand, feet, relic and battle anchors stay fixed.
	_render_scale = target_height / (1.91*float(viewport.size.y)/camera.size)
	_art_scale = _render_scale
	_front.size = Vector2(viewport.size)*_render_scale
	var floor_point: Vector2 = camera.unproject_position(Vector3.ZERO)
	_front.position = Vector2(size.x*.5-floor_point.x*_render_scale,size.y-45-floor_point.y*_render_scale)
	_pose_origin = _front.position

func _create_crystals() -> void:
	for color: Color in [Color("45d5f7"),Color("ffb34f")]:
		var particles := CPUParticles3D.new()
		particles.name = "CrystalSparks"
		particles.amount = 12
		particles.lifetime = .6
		particles.local_coords = false
		particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = .055
		particles.direction = Vector3(0,1,0)
		particles.spread = 45
		particles.gravity = Vector3(0,.12,0)
		particles.initial_velocity_min = .08
		particles.initial_velocity_max = .22
		particles.scale_amount_min = .45
		particles.scale_amount_max = 1.0
		particles.angular_velocity_min = -80
		particles.angular_velocity_max = 80
		var prism := PrismMesh.new()
		prism.size = Vector3(.022,.05,.018)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.vertex_color_use_as_albedo = true
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = .5
		prism.material = material
		particles.mesh = prism
		var gradient := Gradient.new()
		gradient.set_color(0,Color(1,1,1,.65))
		gradient.set_color(1,Color(1,1,1,0))
		particles.color_ramp = gradient
		particles.emitting = false
		viewport.add_child(particles)
		_crystals.append(particles)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node as Skeleton3D
	for child: Node in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null: return found
	return null

func _add_light(at: Vector3,color: Color,power: float,cast_shadows: bool = false) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	viewport.add_child(light)
	light.position = at
	light.look_at(Vector3(0,1,0))
	light.light_color = color
	light.light_energy = power
	light.shadow_enabled = cast_shadows
	if cast_shadows:
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		light.directional_shadow_max_distance = 12.0
		light.shadow_bias = .02
		light.shadow_normal_bias = .4
	return light

func _process(delta: float) -> void:
	if skeleton == null or _fallen: return
	var speed: float = AudioManager.animation_speed_scale()
	_idle_phase = fmod(_idle_phase+delta*speed,float(MOTION.actions.idle.duration))
	_action_time += delta*speed
	_blend_time = minf(1.0,_blend_time+delta*speed/.15)
	if _busy:
		if _action_contact >= 0 and _action_time >= _action_contact: _contact_ready = true
		_apply_sample(_action_name,minf(_action_time,_action_duration))
		if _action_name == "fall": _front.modulate.a = clampf(1.0-(_action_time-.4)/.7,0,1)
		if _action_time >= _action_duration:
			if _action_name == "fall": _fallen = true;_busy = false
			else: _rest()
	else: _apply_sample("idle",0 if AudioManager.reduced_motion else _idle_phase)
	for i: int in _crystals.size():
		_crystals[i].global_position = _bone_world("upper_arm."+("R" if i==0 else "L")).origin
		_crystals[i].emitting = _busy and not AudioManager.reduced_motion and _action_name not in ["hit","guard_hit","fall"]

func _local_frame(action_name: String,time: float) -> Array[Transform3D]:
	var frames: Array = MOTION.actions[action_name].frames
	var cursor: float = clampf(time*float(MOTION.fps),0,float(frames.size()-1))
	var left: int = int(cursor)
	var right: int = mini(left+1,frames.size()-1)
	var weight: float = cursor-float(left)
	var result: Array[Transform3D] = []
	for index: int in _indices.size():
		var a: Array = frames[left][index]
		var b: Array = frames[right][index]
		var point: Vector3 = Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),weight)
		var rotation: Quaternion = Quaternion(a[3],a[4],a[5],a[6]).normalized().slerp(Quaternion(b[3],b[4],b[5],b[6]).normalized(),weight)
		var transform := Transform3D(Basis(rotation),point)
		if AudioManager.reduced_motion:
			var idle: Array = MOTION.actions.idle.frames[0][index]
			var resting := Transform3D(Basis(Quaternion(idle[3],idle[4],idle[5],idle[6]).normalized()),Vector3(idle[0],idle[1],idle[2]))
			transform = resting.interpolate_with(transform,.25)
		result.append(transform)
	if action_name == _retarget_action and not result.is_empty():
		var outbound: float = smoothstep(1.82,2.2,time)
		var inbound: float = 1.0-smoothstep(2.45,2.88,time)
		result[0].origin += _strike_offset*outbound*inbound
	return result

func _apply_sample(action_name: String,time: float) -> void:
	if not AudioManager.reduced_motion:
		if _native_action!=action_name:
			_animator.stop()
			skeleton.reset_bone_poses()
			_animator.play(action_name,0)
			_native_action = action_name
		# Native AnimationPlayer evaluates the imported Blender tracks. Keep
		# our deterministic combat clock, while avoiding reconstruction of
		# every position/quaternion and temporary transform in GDScript.
		# Blender keys begin at frame 1; sampled combat time begins at zero.
		_animator.seek(time+float(MOTION.native_time_origin),true)
		if action_name==_retarget_action:
			var weight: float = smoothstep(1.82,2.2,time)*(1.0-smoothstep(2.45,2.88,time))
			var root: int = _indices[0]
			skeleton.set_bone_pose_position(root,skeleton.get_bone_pose_position(root)+_strike_offset*weight)
		if _blend_time<1 and _from.size()==_indices.size():
			for i: int in _indices.size():
				var local: Transform3D = _from[i].interpolate_with(skeleton.get_bone_pose(_indices[i]),smoothstep(0,1,_blend_time))
				skeleton.set_bone_pose_position(_indices[i],local.origin)
				skeleton.set_bone_pose_rotation(_indices[i],local.basis.get_rotation_quaternion().normalized())
				skeleton.set_bone_pose_scale(_indices[i],Vector3.ONE)
		skeleton.force_update_all_bone_transforms()
		return
	_native_action = ""
	var sampled: Array[Transform3D] = _local_frame(action_name,time)
	for i: int in sampled.size():
		var local: Transform3D = sampled[i]
		if _blend_time < 1 and _from.size() == sampled.size():
			local = _from[i].interpolate_with(local,smoothstep(0,1,_blend_time))
		# Skeleton3D pose is the complete parent-relative transform. Unlike
		# several DCC APIs, it is not a delta multiplied by the bone rest.
		skeleton.set_bone_pose_position(_indices[i],local.origin)
		skeleton.set_bone_pose_rotation(_indices[i],local.basis.get_rotation_quaternion().normalized())
		skeleton.set_bone_pose_scale(_indices[i],Vector3.ONE)
	skeleton.force_update_all_bone_transforms()

func _capture_blend() -> void:
	_from.clear()
	for index: int in _indices:
		_from.append(skeleton.get_bone_pose(index))
	_blend_time = 0

func play_action(action_name: String,_profile: Dictionary = {}) -> void:
	if _fallen or not MOTION.actions.has(action_name): return
	_capture_blend()
	_retarget_action = ""
	_strike_offset = Vector3.ZERO
	if action_name in ["iron_strike","twin_right","twin_left","heavy"] and _profile.has("target_position"):
		_fit_contact(action_name,_profile.target_position as Vector2)
	_action_name = action_name
	# The illustrated enemy has one flat draw plane. Bring the active melee
	# silhouette forward so its arm and blade remain readable at real contact.
	_front.z_index = 5 if action_name in ["iron_strike","twin_right","twin_left","heavy"] else 0
	_action_time = 0
	_action_contact = float(MOTION.actions[action_name].contact)
	_action_duration = float(MOTION.actions[action_name].duration)
	_busy = action_name != "idle"
	_contact_ready = false
	_front.modulate = Color.WHITE
	_apply_sample(action_name,0)

func attack(profile: Dictionary = {}) -> void:
	play_action("heavy" if AttackPresentation.is_heavy_hammer(profile) else str(profile.get("rig_action","iron_strike")),profile)

func hit(blocked: bool,_profile: Dictionary = {}) -> void:
	if _busy:
		_front.modulate = Color(1.3,1.3,1.4)
		var flash: Tween = create_tween()
		flash.tween_property(_front,"modulate",Color.WHITE,.16)
	else: play_action("guard_hit" if blocked else "hit")

func fall() -> void: play_action("fall")
func set_pose(_frame: int) -> void:
	if skeleton != null: _apply_sample("idle",0)
func _rest() -> void:
	_front.z_index = 0
	_capture_blend()
	_busy = false
	_action_name = "idle"
	_action_time = 0
	_apply_sample("idle",_idle_phase)
func is_busy() -> bool: return _busy
func contact_ready() -> bool: return _contact_ready

func _bone_world(name: String) -> Transform3D:
	assert(_bone_lookup.has(name),"Imported bone is missing: "+name)
	return skeleton.global_transform*skeleton.get_bone_global_pose(int(_bone_lookup[name]))

func _project(point: Vector3,global_space: bool = true) -> Vector2:
	var local: Vector2 = _front.position+camera.unproject_position(point)*_render_scale
	return get_global_transform()*local if global_space else local

func anchor_position(anchor: String,global_space: bool = true) -> Vector2:
	match anchor:
		"hand","hand_near": return _project(grip_world("R").origin,global_space)
		"hand_far": return _project(grip_world("L").origin,global_space)
		"head": return _project(_bone_world("head").origin+Vector3(0,.20,0),global_space)
		"feet": return _project((_bone_world("foot.R").origin+_bone_world("foot.L").origin)*.5-Vector3(0,.09,0),global_space)
	return _project(_bone_world("spine_upper").origin,global_space)

func get_hand_global_position() -> Vector2: return anchor_position("hand")
func get_head_global_position() -> Vector2: return anchor_position("head")
func get_chest_global_position() -> Vector2: return anchor_position("chest")
func get_feet_global_position() -> Vector2: return anchor_position("feet")
func get_hand_global_rotation() -> float:
	var hand: Transform3D = _bone_world("hand.R")
	return (_project(hand*Vector3(0,.16,0))-_project(hand.origin)).angle()-PI*.5

func sample_action_for_review(action_name: String,time: float) -> void:
	set_process(false)
	_blend_time = 1
	_apply_sample(action_name,time)

func sample_grip_transform(action_name: String,time: float,hand: String = "hand_near") -> Transform2D:
	var local: Array[Transform3D] = _local_frame(action_name,time)
	var world: Dictionary = {}
	for i: int in local.size():
		var bone: Dictionary = MOTION.bones[i]
		world[str(bone.name)] = local[i] if str(bone.parent).is_empty() else (world[str(bone.parent)] as Transform3D)*local[i]
	var transform: Transform3D = skeleton.global_transform*(world["hand.L" if hand == "hand_far" else "hand.R"] as Transform3D)
	var origin: Vector2 = _project(transform*Vector3(0,.065,.022 if hand == "hand_far" else -.022))
	var angle: float = (_project(transform*Vector3(0,.16,0))-_project(transform.origin)).angle()-PI*.5
	return Transform2D(angle,origin)

func _fit_contact(action_name: String,target: Vector2) -> void:
	var local: Array[Transform3D] = _local_frame(action_name,float(MOTION.actions[action_name].contact))
	var world: Dictionary = {}
	for i: int in local.size():
		var bone: Dictionary = MOTION.bones[i]
		world[str(bone.name)] = local[i] if str(bone.parent).is_empty() else (world[str(bone.parent)] as Transform3D)*local[i]
	var side: String = "L" if action_name=="twin_left" else "R"
	var palm: Transform3D = skeleton.global_transform*(world["hand."+side] as Transform3D)*Transform3D(Basis.IDENTITY,Vector3(0,.065,.022 if side=="L" else -.022))
	var weapon: Transform3D = _weapon_from_palm(palm,side)
	var tip: Vector3 = weapon*_weapon_contact_point(weapon,action_name)
	var ground: Vector3 = camera.global_basis.x
	ground.y = 0
	ground = ground.normalized()
	var pixels: float = _project(tip+ground).x-_project(tip).x
	if absf(pixels)>.1:
		var desired: float = (target.x-_project(tip).x)/pixels
		# The real blade reach determines the approach. A fixed chest gap can
		# prevent a shorter weapon from reaching the visible target at all.
		_strike_offset = ground*clampf(desired,-.3,3.4)
		_retarget_action = action_name

func get_shadow_global_position() -> Vector2:
	var feet: Vector3 = (_bone_world("foot.R").origin+_bone_world("foot.L").origin)*.5
	feet.y = 0
	return _project(feet)

func grip_world(side: String = "R") -> Transform3D:
	var hand: Transform3D = _bone_world("hand."+side)
	return hand*Transform3D(Basis.IDENTITY,Vector3(0,.065,-.022 if side=="R" else .022))

func _weapon_from_palm(palm: Transform3D,side: String,scale: Vector3 = Vector3.ONE) -> Transform3D:
	# A right-hand hilt exits the palm's negative X side; the left hand's
	# anatomical bone frame is mirrored. Keep this mount shared with aiming.
	return palm*Transform3D(Basis(Vector3.BACK,PI*.5 if side=="R" else -PI*.5).scaled(scale),Vector3.ZERO)

func weapon_world(side: String = "R",scale: Vector3 = Vector3.ONE) -> Transform3D:
	return _weapon_from_palm(grip_world(side),side,scale)

func bind_weapon_geometry(owner_id: int,points: PackedVector3Array) -> void:
	_weapon_geometry_owner = owner_id
	_weapon_geometry = points

func clear_weapon_geometry(owner_id: int) -> void:
	if _weapon_geometry_owner!=owner_id: return
	_weapon_geometry_owner = 0
	_weapon_geometry = PackedVector3Array()

func _weapon_contact_point(weapon: Transform3D,action_name: String) -> Vector3:
	var tip: Vector3 = Vector3(.16,.53,0) if action_name=="heavy" else Vector3(0,.74,0)
	if _weapon_geometry.is_empty(): return tip
	var direction: Vector3 = weapon.basis.transposed()*camera.global_basis.x
	var furthest: float = -INF
	for point: Vector3 in _weapon_geometry:
		var reach: float = point.dot(direction)
		if reach>furthest:
			furthest = reach
			tip = point
	return tip

func weapon_contact_world(side: String = "R") -> Vector3:
	var weapon: Transform3D = weapon_world(side)
	return weapon*_weapon_contact_point(weapon,_action_name)

func anatomy_review(enabled: bool) -> void:
	for mesh: MeshInstance3D in _mesh_nodes:
		var body: bool = str(mesh.name).contains("Tailored")
		mesh.visible = not enabled or body
		if enabled and body:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color("798793")
			mat.roughness = .7
			mesh.material_override = mat

func set_relic_aura(color: Color,amount: float) -> void:
	if _aura_light == null: return
	_aura_light.global_position = _bone_world("spine_upper").origin+Vector3(0,.12,.22)
	_aura_light.light_color = color
	_aura_light.light_energy = maxf(0,amount)*3.2
