extends Node3D
## Opponent-space audit and interruption contract, separate from gameplay routing.
var actor: BoneghoulActor
var contacts: int = 0
var event_position: Vector3
var camera: Camera3D

func _ready() -> void:
	AudioManager.set_master_volume(0)
	actor = BoneghoulActor.new()
	add_child(actor)
	actor.set_process(false)
	actor.contact_reached.connect(func() -> void:
		contacts += 1
		event_position = actor.claw_tip()
	)
	actor.position = Vector3(0.9, 0.0, -0.1)
	actor.rotation.y = -1.4
	var opponent: RiggedCombatant = RiggedCombatant.new()
	add_child(opponent)
	opponent.set_process(false)
	opponent.position = Vector3(-0.72, 0.0, 0.2)
	opponent.rotation.y = 1.4
	_build_stage()
	for speed: float in [1.0, 2.0]:
		for reduced: bool in [false, true]:
			AudioManager.reduced_motion = reduced
			contacts = 0
			actor.attack()
			for step: int in 120: actor.advance_motion(speed / 60.0)
			assert(contacts == 1 and actor.state == BoneghoulActor.State.IDLE)
			for guarded: bool in [false, true]:
				contacts = 0
				actor.attack()
				actor.advance_motion(0.2)
				actor.hit(guarded)
				actor.advance_motion(0.9)
				assert(contacts == 0 and actor.state == BoneghoulActor.State.IDLE, "Interrupted attacks must not emit contact")
	actor.attack()
	actor.advance_motion(actor.contact_time())
	var target: Vector3 = opponent._skeleton.to_global(opponent._skeleton.get_bone_global_pose(opponent._skeleton.find_bone("chest")).origin)
	print("BONEGHOUL_REACH_AUDIT claw=", actor.claw_tip(), " target=", target, " separation=", actor.claw_tip().distance_to(target))
	await capture("original-spacing-miss")
	# Establish a close melee stance BEFORE attacking; never slide feet on contact.
	var reach: Vector3 = actor.claw_tip() - actor.global_position
	reach.y = 0.0
	var toward: Vector3 = target - actor.global_position
	toward.y = 0.0
	actor.rotate_y(reach.signed_angle_to(toward, Vector3.UP))
	actor.global_position = Vector3(target.x, 0.0, target.z) - toward.normalized() * (reach.length() + 0.20)
	actor.skeleton.force_update_all_bone_transforms()
	var chest_surface: Vector3 = target - Vector3(0.0, 0.15, 0.0) - toward.normalized() * 0.20
	assert(actor.claw_tip().distance_to(chest_surface) < 0.06, "Claw must reach the torso surface in the staged stance")
	print("BONEGHOUL_CLOSE_STANCE gap=", actor.claw_tip().distance_to(chest_surface), " position=", actor.position, " yaw=", actor.rotation.y)
	await capture("close-stance-contact")
	actor.attack()
	actor.advance_motion(1.1)
	assert(event_position.distance_to(chest_surface) < 0.06, "A long frame must emit contact at the strike pose, not follow-through")
	var foot_start: Vector3 = actor.bone_point("foot.R")
	actor.attack()
	for step: int in 80:
		actor.advance_motion(1.0 / 60.0)
		assert(actor.bone_point("foot.R").distance_to(foot_start) < 0.002)
	contacts = 0
	actor.attack()
	actor.advance_motion(0.2)
	actor.fall()
	actor.advance_motion(1.6)
	var final_head: Vector3 = actor.bone_point("head")
	actor.attack()
	actor.hit(false)
	actor.hit(true)
	actor.fall()
	actor.advance_motion(2.0)
	assert(contacts == 0 and actor.state == BoneghoulActor.State.DEAD)
	assert(actor.bone_point("head").distance_to(final_head) < 0.002, "Terminal pose must survive late animation requests")
	var interrupted: BoneghoulActor = BoneghoulActor.new()
	add_child(interrupted)
	interrupted.set_process(false)
	interrupted.contact_reached.connect(interrupted.fall)
	interrupted.attack()
	interrupted.advance_motion(2.5)
	assert(interrupted.state == BoneghoulActor.State.DEAD, "Contact callbacks may end the actor during a long frame")
	assert(absf(interrupted.animation.current_animation_position - 1.6) < 0.002, "Remaining frame time must finish the collapse, not the cancelled rake")
	interrupted.queue_free()
	print("BONEGHOUL_INTERRUPT_OK: contact once, reaction cancellation and held terminal state; opponent reach audit separate")
	get_tree().quit()

func _build_stage() -> void:
	get_window().size = Vector2i(1280, 900)
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("10151a")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("8199aa")
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.8
	light.shadow_enabled = true
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(12, 12)
	floor_mesh.mesh = plane
	floor_mesh.position.y = -0.015
	add_child(floor_mesh)
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0.6, 2.4, 4.5)
	camera.look_at(Vector3(0.0, 1.05, 0.0))
	camera.fov = 38.0
	camera.current = true

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://boneghoul-contact")
	get_viewport().get_texture().get_image().save_png("user://boneghoul-contact/" + label + ".png")
