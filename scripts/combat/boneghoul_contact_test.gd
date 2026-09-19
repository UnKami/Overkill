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
	opponent.opponent = actor
	opponent._animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
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
	actor.hit(false)
	actor.advance_motion(0.9)
	opponent.attack()
	opponent.prepare_contact()
	var blade_start: Vector3 = opponent._weapon.to_global(Vector3(0.0, 0.05, 0.22))
	var blade_end: Vector3 = opponent._weapon.to_global(Vector3(0.0, 0.05, 1.14))
	var ghoul_chest: Vector3 = actor.bone_point("chest")
	var closest: Vector3 = Geometry3D.get_closest_point_to_segment(ghoul_chest, blade_start, blade_end)
	print("BONEGHOUL_RETURN_AUDIT chest=", ghoul_chest, " blade_start=", blade_start, " blade_end=", blade_end, " center_gap=", closest.distance_to(ghoul_chest))
	assert(closest.distance_to(ghoul_chest) < 0.10, "Return strike must intersect the ribcage envelope")
	assert(blade_start.distance_to(ghoul_chest) > 0.40, "The sword grip must remain outside the opponent torso")
	await capture("return-strike")
	for guarded: bool in [false, true]:
		if guarded:
			actor.prepare_guard()
			actor.advance_motion(opponent.contact_time())
		else:
			actor.hit(false)
			actor.advance_motion(0.20)
		opponent._align_weapon()
		blade_start = opponent._weapon.to_global(Vector3(0.0, 0.05, 0.22))
		blade_end = opponent._weapon.to_global(Vector3(0.0, 0.05, 1.14))
		ghoul_chest = actor.bone_point("chest")
		closest = Geometry3D.get_closest_point_to_segment(ghoul_chest, blade_start, blade_end)
		if guarded:
			var contact: Vector3 = actor.guard_contact_point(opponent.global_position)
			var intercept: Vector3 = Geometry3D.get_closest_point_to_segment(contact, blade_start, blade_end)
			print("BONEGHOUL_GUARD_AUDIT bracer_gap=", intercept.distance_to(contact), " torso_gap=", closest.distance_to(ghoul_chest))
			assert(intercept.distance_to(contact) < 0.06, "Sword must meet the bracer")
			assert(closest.distance_to(ghoul_chest) > 0.22, "Blocked sword must stay outside the torso")
			var held_hand: Vector3 = actor.bone_point("hand.R")
			actor.advance_motion(0.8)
			assert(actor.bone_point("hand.R").distance_to(held_hand) < 0.002, "Brace must hold until impact")
			actor.hit(true)
			assert(actor.bone_point("hand.R").distance_to(held_hand) < 0.002, "Impact must not restart guard raise")
		else:
			assert(closest.distance_to(ghoul_chest) < 0.22, "Recoil must remain within sword reach")
		await capture("return-guard" if guarded else "return-recoil")
		actor.advance_motion(0.9)
	print("BONEGHOUL_RECIPROCAL_OK: unguarded torso reached; blocked sword intercepted at bracer")
	for speed: float in [1.0, 2.0]:
		for reduced: bool in [false, true]:
			AudioManager.reduced_motion = reduced
			actor.prepare_guard()
			opponent.attack()
			var released: bool = false
			var elapsed: float = 0.0
			while elapsed < 1.1:
				var dt: float = speed / 60.0
				actor.advance_motion(dt)
				opponent._animation.advance(dt)
				opponent._skeleton.force_update_all_bone_transforms()
				opponent._apply_attack_weight()
				opponent._align_weapon()
				elapsed += dt
				if elapsed >= 0.30 and elapsed <= 0.40:
					blade_start = opponent._weapon.to_global(Vector3(0.0, 0.05, 0.22))
					blade_end = opponent._weapon.to_global(Vector3(0.0, 0.05, 1.14))
					var bracer: Vector3 = actor.guard_contact_point(opponent.global_position)
					# At 0.30 the blade is still approaching; contact is authored at 0.32.
					if elapsed >= opponent.contact_time():
						assert(Geometry3D.get_closest_point_to_segment(bracer, blade_start, blade_end).distance_to(bracer) < 0.06)
					assert(Geometry3D.get_closest_point_to_segment(actor.bone_point("chest"), blade_start, blade_end).distance_to(actor.bone_point("chest")) > 0.22)
				if not released and elapsed >= opponent.contact_time():
					actor.hit(true)
					released = true
					if speed == 1.0 and not reduced:
						var contact_transform: Transform3D = opponent._weapon.global_transform
						await capture("timed-guard-contact")
						assert(opponent._weapon.global_transform.is_equal_approx(contact_transform), "Deferred bone updates must not overwrite the visible weapon contact transform")
			assert(actor.state == BoneghoulActor.State.IDLE, "Guard must recover after impact release")
	print("BONEGHOUL_GUARD_SEQUENCE_OK: pre-contact brace, interception window and release at two speeds with reduced motion on/off")
	opponent._play("combat_idle", 0.0)
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
	actor.prepare_guard()
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
