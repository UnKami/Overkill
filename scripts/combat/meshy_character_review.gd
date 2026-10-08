extends Node3D
## Isolated asset review. No GameFlow, RunManager, save access, or combat mutation.

const MODEL_PATH: String = "res://assets/characters/meshy/meshy_character.glb"
var actor: Node3D
var animator: AnimationPlayer
var camera: Camera3D
var title_label: Label
var clip_label: Label
var active_clip: String = "Idle"
var angle: float = 0.30
var zoom: float = 2.5
var paused: bool = false
var dragging: bool = false
var capture: bool = false
var frame_index: int = 0
var clip_time: float = 0.0
var output_dir: String = "res://captures"
var sequence: Array[String] = ["Idle", "Walking", "Running", "Jump_Down", "Guard_Raise"]
var sequence_lengths: Array[float] = [3.0, 2.0, 2.0, 1.8, 1.2]
var sequence_index: int = 0
var showcase: bool = false
var clock_platform: Node3D

func _ready() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	showcase = capture
	RenderingServer.set_default_clear_color(Color("131b22"))
	var environment_node: WorldEnvironment = WorldEnvironment.new()
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("131b22")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("bccddd")
	environment.ambient_light_energy = 0.30
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)
	_add_light(Vector3(-3, 4, 4), Color("d8e8ff"), 0.75)
	_add_light(Vector3(3, 2, 2), Color("fce0bc"), 0.3)
	_add_light(Vector3(0, 3, -3), Color("94bdce"), 0.45)
	var packed: PackedScene = load(MODEL_PATH) as PackedScene
	assert(packed != null, "Prepared Meshy GLB must be imported")
	actor = packed.instantiate() as Node3D
	add_child(actor)
	var players: Array[Node] = actor.find_children("*", "AnimationPlayer", true, false)
	assert(players.size() == 1)
	animator = players[0] as AnimationPlayer
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip: String in sequence:
		assert(animator.has_animation(clip), "Missing animation: " + clip)
		var animation: Animation = animator.get_animation(clip)
		animation.loop_mode = Animation.LOOP_LINEAR if clip in ["Idle", "Walking", "Running"] else Animation.LOOP_NONE
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(200, 200)
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.015
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.008, 0.012, 0.018)
	floor_material.roughness = 0.9
	floor_mesh.material_override = floor_material
	add_child(floor_mesh)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child(camera)
	_build_ui()
	_play("Idle")
	_report_structure()
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	_update_camera()

func _add_light(at: Vector3, tint: Color, energy: float) -> void:
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.light_color = tint
	light.light_energy = energy
	light.shadow_enabled = true
	add_child(light)
	light.position = at
	light.look_at(Vector3(0, 1, 0))

func _build_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	var header: VBoxContainer = VBoxContainer.new()
	header.position = Vector2(32, 24)
	canvas.add_child(header)
	title_label = Label.new()
	title_label.text = "OVERKILL / CHARACTER STUDY"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.modulate = Color("d1b47d")
	header.add_child(title_label)
	clip_label = Label.new()
	clip_label.add_theme_font_size_override("font_size", 30)
	header.add_child(clip_label)
	var footer: VBoxContainer = VBoxContainer.new()
	footer.position = Vector2(32, 620)
	canvas.add_child(footer)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	footer.add_child(buttons)
	for clip: String in sequence:
		var button: Button = Button.new()
		button.text = clip.replace("_", " ")
		button.custom_minimum_size = Vector2(105, 40)
		button.pressed.connect(_select_clip.bind(clip))
		buttons.add_child(button)
	var hint: Label = Label.new()
	hint.text = "Drag to rotate   /   Scroll to zoom   /   Space to pause   /   Tab to play sequence"
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color("9db1bf")
	footer.add_child(hint)
	if capture:
		buttons.hide()
		hint.text = "Motion study: Idle · Walk · Run · Jump down · Guard"

func _select_clip(clip: String) -> void:
	showcase = false
	paused = false
	_play(clip)

func _play(clip: String) -> void:
	active_clip = clip
	clip_time = 0.0
	animator.stop()
	animator.play(clip)
	animator.seek(0.0, true)
	clip_label.text = clip.replace("_", " ") + (" / first motion study" if clip in ["Jump_Down", "Guard_Raise"] else "")

func _update_camera() -> void:
	var center: Vector3 = Vector3(0, 0.95, 0)
	camera.size = zoom
	if active_clip == "Jump_Down":
		center.y = 1.55
		camera.size = maxf(zoom, 3.75)
	camera.position = center + Vector3(sin(angle) * 5.0, 0.15, cos(angle) * 5.0)
	camera.look_at(center)

func _process(delta: float) -> void:
	if animator == null:
		return
	var dt: float = 1.0 / 30.0 if capture else delta
	if not paused:
		animator.advance(dt)
		clip_time += dt
	if showcase and clip_time >= sequence_lengths[sequence_index]:
		sequence_index += 1
		if sequence_index >= sequence.size():
			if capture:
				print("MESHY_NATIVE_CAPTURE_OK frames=", frame_index)
				set_process(false)
				get_tree().quit()
				return
			sequence_index = 0
		_play(sequence[sequence_index])
	if capture and active_clip == "Idle":
		angle = 0.25 + clip_time * 0.22
	_update_camera()
	if capture:
		set_process(false)
		await RenderingServer.frame_post_draw
		var screenshot: Image = get_viewport().get_texture().get_image()
		var result: Error = screenshot.save_png(output_dir.path_join("frame_%04d.png" % frame_index))
		assert(result == OK)
		frame_index += 1
		set_process(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			dragging = mouse.pressed
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = maxf(1.2, zoom - 0.15)
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = minf(5.0, zoom + 0.15)
	elif event is InputEventMouseMotion and dragging:
		angle -= (event as InputEventMouseMotion).relative.x * 0.009
	elif event is InputEventKey and event.is_pressed():
		var key: InputEventKey = event as InputEventKey
		if key.keycode == KEY_SPACE:
			paused = not paused
		elif key.keycode == KEY_TAB:
			showcase = true
			sequence_index = 0
			_play(sequence[0])
		elif key.keycode == KEY_ESCAPE:
			get_tree().quit()

func _report_structure() -> void:
	var skeletons: Array[Node] = actor.find_children("*", "Skeleton3D", true, false)
	assert(skeletons.size() == 1)
	var skeleton: Skeleton3D = skeletons[0] as Skeleton3D
	assert(skeleton.get_bone_count() == 23)
	var lengths: Dictionary = {}
	for clip: String in sequence:
		lengths[clip] = animator.get_animation(clip).length
	print("MESHY_NATIVE_ASSET_OK ", JSON.stringify({"bones": skeleton.get_bone_count(), "clips": lengths}))
