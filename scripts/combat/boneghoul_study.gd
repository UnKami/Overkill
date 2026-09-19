extends Node3D
## Isolated model inspection. Reference combat clips are not gameplay-ready.
var _camera: Camera3D
var _model: Node3D

func _ready() -> void:
	AudioManager.set_master_volume(0)
	get_window().size = Vector2i(1280,900)
	var environment: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("10151a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8199aa")
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	add_child(light)
	light.position = Vector3(2,4,-3)
	light.look_at(Vector3(0,1,0))
	light.light_color = Color("d5e4ed")
	light.light_energy = 1.8
	light.shadow_enabled = true
	var rim: OmniLight3D = OmniLight3D.new()
	rim.position = Vector3(-2,2,1)
	rim.light_color = Color("d8a977")
	rim.light_energy = 2.0
	rim.omni_range = 6.0
	add_child(rim)
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(20,20)
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.02
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color("171c20")
	mat.roughness = 0.95
	floor_mesh.material_override = mat
	add_child(floor_mesh)
	_model = preload("res://assets/characters/rigged/boneghoul.glb").instantiate()
	add_child(_model)
	var bodies: Array[Node] = _model.find_children("*","MeshInstance3D",true,false)
	assert(bodies.size() == 1, "Study must export one skinned body")
	var body: MeshInstance3D = bodies[0]
	assert(body.skin != null and body.mesh.get_surface_count() == 4)
	var skeleton: Skeleton3D = _model.find_children("*","Skeleton3D",true,false)[0]
	assert(skeleton.find_bone("f_middle.03.R") >= 0, "Claw rig must retain articulated finger tips")
	var animation: AnimationPlayer = _model.find_children("*","AnimationPlayer",true,false)[0]
	var idle: StringName = &""
	for clip: StringName in animation.get_animation_list():
		assert("combat_idle" in str(clip) or clip == &"RESET", "Unvalidated sword clips must not ship on the clawed model")
		if "combat_idle" in str(clip): idle = clip
	assert(idle != &"")
	animation.get_animation(idle).loop_mode = Animation.LOOP_LINEAR
	animation.play(idle)
	_camera = Camera3D.new()
	_camera.fov = 34
	add_child(_camera)
	_camera.current = true
	var caption: CanvasLayer = CanvasLayer.new()
	add_child(caption)
	var title: Label = Label.new()
	title.text = "BONEGHOUL / 3D MODEL STUDY"
	title.position = Vector2(28,18)
	title.add_theme_font_size_override("font_size",26)
	caption.add_child(title)
	var note: Label = Label.new()
	note.text = "Skinned geometry and idle / Combat integration pending"
	note.position = Vector2(28,1030)
	note.add_theme_font_size_override("font_size",20)
	caption.add_child(note)
	for angle: String in ["front","quarter","back"]:
		_camera.position = {"front":Vector3(0,1.6,-4.8),"quarter":Vector3(2.7,1.8,-4.0),"back":Vector3(-2.7,1.8,4.0)}[angle]
		_camera.look_at(Vector3(0,1.1,0))
		await get_tree().create_timer(0.45).timeout
		await capture(angle)
	print("BONEGHOUL_STUDY_OK: original skinned body, four surfaces, finger rig and authored idle; combat integration pending")
	get_tree().quit()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://boneghoul-036")
	get_viewport().get_texture().get_image().save_png("user://boneghoul-036/"+label+".png")
