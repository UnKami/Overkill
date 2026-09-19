extends Node
var stage: DirectedArena

func _ready() -> void:
	AudioManager.set_master_volume(0)
	stage = DirectedArena.new()
	stage.size = Vector2(1280,900)
	get_window().size = Vector2i(1280,900)
	add_child(stage)
	stage.configure_enemy("sentinel")
	stage.set_process(false)
	await get_tree().process_frame
	await get_tree().process_frame
	if stage._composition_motion and stage._composition_motion.is_valid(): stage._composition_motion.kill()
	stage._view.size = Vector2i(1280,900)
	stage._camera.v_offset = 0.0
	stage._camera.h_offset = 0.0
	for actor: RiggedCombatant in [stage.player, stage.enemy]:
		actor.set_process(false)
		actor._animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		audit_swing(actor)
		for moment: float in [0.0,0.20,0.32,0.48,0.76]:
			actor.attack()
			actor._animation.seek(actor._retimed_attack_time(moment),true)
			actor._skeleton.force_update_all_bone_transforms()
			actor._apply_attack_weight()
			actor._align_weapon()
			var index: Vector3 = point(actor,"f_index.01.R")
			var pinky: Vector3 = point(actor,"f_pinky.01.R")
			var across: Vector3 = (index-pinky).normalized()
			var shaft: Vector3 = actor._weapon.global_basis.z.normalized()
			print("GRIP_AXIS hostile=",actor.hostile," time=",moment," angle=",rad_to_deg(across.angle_to(shaft)))
			print("FOREARM_SHAFT angle=",rad_to_deg((point(actor,"hand.R")-point(actor,"forearm.R")).normalized().angle_to(shaft)))
			var hand_axis: Vector3 = actor._skeleton.get_bone_global_pose(actor._skeleton.find_bone("hand.R")).basis.y.normalized()
			var forearm_axis: Vector3 = actor._skeleton.get_bone_global_pose(actor._skeleton.find_bone("forearm.R")).basis.y.normalized()
			print("WRIST_BEND hostile=",actor.hostile," time=",moment," degrees=",rad_to_deg(hand_axis.angle_to(forearm_axis)))
			assert(rad_to_deg(hand_axis.angle_to(forearm_axis)) < 35.0, "Loaded attack poses must not fold the wrist beneath the forearm")
			var palm: Vector3 = actor._weapon.to_global(Vector3(0,.05,0))
			stage._camera.position = palm + Vector3(.55,.35,1.0)
			stage._camera.look_at(palm)
			stage._camera.fov = 32
			await get_tree().process_frame
			await get_tree().process_frame
			assert(actor._weapon.to_global(Vector3(0,.05,0)).distance_to(palm) < 0.001, "Deferred skeleton updates must not displace the grip")
			await capture(("sentinel" if actor.hostile else "player")+"-"+str(moment))
	print("WEAPON_GRIP_STUDY_DONE")
	get_tree().quit()

func point(actor: RiggedCombatant, bone: String) -> Vector3:
	return actor._skeleton.to_global(actor._skeleton.get_bone_global_pose(actor._skeleton.find_bone(bone)).origin)

func audit_swing(actor: RiggedCombatant) -> void:
	var previous: Quaternion = Quaternion.IDENTITY
	var largest_step: float = 0.0
	var largest_time: float = 0.0
	actor._play("execution_cut", 0.0)
	for sample: int in 93:
		var moment: float = minf(sample / 120.0, 0.76)
		actor._animation.seek(actor._retimed_attack_time(moment), true)
		actor._skeleton.force_update_all_bone_transforms()
		actor._apply_attack_weight()
		actor._align_weapon()
		var orientation: Quaternion = actor._weapon.global_basis.orthonormalized().get_rotation_quaternion()
		if sample > 0:
			var step: float = rad_to_deg(previous.angle_to(orientation))
			if step > largest_step:
				largest_step = step
				largest_time = moment
		previous = orientation
	print("SWING_CONTINUITY hostile=",actor.hostile," max_step_degrees=",largest_step," time=",largest_time)
	assert(largest_step < 30.0, "Weapon must not snap its roll at the vertical-pose reference boundary")

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://weapon-grip")
	stage._view.get_texture().get_image().save_png("user://weapon-grip/"+label+".png")
