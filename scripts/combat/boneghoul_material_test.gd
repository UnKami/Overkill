extends Node3D
## Isolated same-camera A/B study. Frame timings are diagnostic, not FPS acceptance.
var actor: BoneghoulActor
var camera: Camera3D

func _ready() -> void:
	AudioManager.set_master_volume(0)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_window().size = Vector2i(1280, 900)
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("10151a")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("8199aa")
	world.environment.ambient_light_energy = 0.45
	add_child(world)
	var key: DirectionalLight3D = DirectionalLight3D.new()
	add_child(key)
	key.position = Vector3(2,4,-3)
	key.look_at(Vector3(0,1,0))
	key.light_color = Color("d5e4ed")
	key.light_energy = 1.8
	actor = BoneghoulActor.new()
	add_child(actor)
	actor.rotation.y = PI
	actor.set_process(false)
	actor.advance_motion(0.0)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 34.0
	for close_up: bool in [true, false]:
		camera.position = Vector3(.45,2.0,-1.2) if close_up else Vector3(2.7,1.8,-4.0)
		camera.look_at(Vector3(0,1.92,0) if close_up else Vector3(0,1.1,0))
		for detail: bool in [false, true, false]:
			actor.set_surface_detail(detail)
			var changed: int = 0
			for node: Node in actor.model.find_children("*", "MeshInstance3D", true, false):
				var body: MeshInstance3D = node
				assert(body.mesh.get_surface_count() == 4)
				for surface: int in body.mesh.get_surface_count():
					var override_material: Material = body.get_surface_override_material(surface)
					if override_material != null:
						assert(body.mesh.surface_get_material(surface).resource_name == "Boneghoul_Bone")
						assert(override_material == actor._bone_material)
						changed += 1
			assert(changed == (1 if detail else 0), "Detail must replace only the bone surface and restore cleanly")
			actor._play("combat_idle", 0.0)
			await get_tree().create_timer(1.5).timeout
			var label: String = ("close" if close_up else "wide") + ("-detail" if detail else "-base")
			await capture(label)
			await sample(label)
	print("BONEGHOUL_MATERIAL_STUDY_OK")
	get_tree().quit()

func sample(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	actor.set_process(true)
	var times: Array[float] = []
	var end: int = Time.get_ticks_msec() + 3000
	var previous: int = Time.get_ticks_usec()
	while Time.get_ticks_msec() < end:
		await get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		times.append((now - previous) / 1000.0)
		previous = now
	times.sort()
	actor.set_process(false)
	print("BONE_MATERIAL_COST ", label, " median_ms=", times[times.size()/2], " p95_ms=", times[int(times.size()*.95)], " draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://bone-material")
	get_viewport().get_texture().get_image().save_png("user://bone-material/"+label+".png")
