extends Node
## Anatomy, grounding and transitions tested against the real runtime bones.
var _checks: int = 0
var _captures: Array[Dictionary] = []
var _failures: PackedStringArray = []
const OUTPUT: String = "res://.test-artifacts/043/motion"

func _ready() -> void:
	if not QAProfileGuard.require_isolated(self): return
	AudioManager.fast_mode = false
	AudioManager.reduced_motion = false
	AudioManager.set_master_volume(0.0)
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280,720)
	RunManager.start_new_run([],[],500,43043)
	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("boneghoul")])
	await get_tree().create_timer(1.4).timeout
	# Pose inspection uses the production actors at enlarged scale, with no
	# decision overlays obscuring knees, hands or the enemy silhouette.
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.035,0.05,0.065)
	backdrop.size = Vector2(1920,1080)
	add_child(backdrop)
	battle.hide()
	battle._stage.reparent(self)
	battle._stage.position = Vector2.ZERO
	battle._stage.size = Vector2(1920,1080)
	battle._stage.player.position = Vector2(70,80)
	if battle._stage.player is Executioner3DActor:
		_test_human_3d(battle._stage.player as Executioner3DActor)
		return
	var player: RelicRigActor = battle._stage.player as RelicRigActor
	_expect(player != null,"Live player uses the connected rig")
	var data: Dictionary = player.RIG_DATA
	_expect(int(data.fps) == 60,"Player motion is baked at 60 Hz")
	var ankle_baseline: Dictionary = {}
	player.sample_action_for_review("idle",0.0)
	for side: String in ["near","far"]:
		ankle_baseline[side] = (player._bone_names["foot_"+side] as Bone2D).global_position
	var max_step: float = 0.0
	for action_name: String in data.actions:
		var clip: Dictionary = data.actions[action_name]
		var previous: Dictionary = {}
		for frame: int in clip.frames.size():
			var time: float = frame/60.0
			player.sample_action_for_review(action_name,time)
			for side: String in ["near","far"]:
				for limb: Array in [["arm_","forearm_","hand_"],["thigh_","shin_","foot_"]]:
					var first: Bone2D = player._bone_names[str(limb[0])+side]
					var second: Bone2D = player._bone_names[str(limb[1])+side]
					var end: Bone2D = player._bone_names[str(limb[2])+side]
					var expected_a: float = second.rest.origin.length()*player._art_scale
					var expected_b: float = end.rest.origin.length()*player._art_scale
					_expect(absf(first.global_position.distance_to(second.global_position)-expected_a)<0.08,"Fixed upper limb length")
					_expect(absf(second.global_position.distance_to(end.global_position)-expected_b)<0.08,"Fixed lower limb length")
					if str(limb[0]) == "arm_":
						var a: Vector2 = second.global_position-first.global_position
						var b: Vector2 = end.global_position-second.global_position
						var flexion: float = a.angle_to(b)
						_expect(flexion*float(data.motion_quality.elbow_signs.get(side,-1))>-0.01,"Elbow bend keeps its anatomical direction")
						_expect(absf(flexion)<deg_to_rad(112.2),"Elbow cannot overfold")
				var ankle: Vector2 = (player._bone_names["foot_"+side] as Bone2D).global_position
				if action_name not in ["iron_strike","twin_right","twin_left","heavy","fall"] or (action_name in ["iron_strike","twin_right","twin_left"] and time<=1.83) or (action_name=="heavy" and time<=1.85):
					_expect(ankle.distance_to(ankle_baseline[side])<0.5,"Support foot remains planted during wind-up and channels")
			for bone: Bone2D in player._bones:
				if previous.has(bone.name):
					var displacement: float = bone.global_position.distance_to(previous[bone.name])
					max_step = maxf(max_step,displacement)
					_expect(displacement<35.0,"No one-frame joint teleport: %s %.3f %s %.3f" % [action_name,time,bone.name,displacement])
				previous[bone.name] = bone.global_position
	player.set_process(true)
	player.play_action("iron_strike")
	await get_tree().create_timer(0.3).timeout
	player.hit(false)
	_expect(player._action_name=="iron_strike","Incoming recoil must not cancel an outgoing action")
	player.sample_action_for_review("iron_strike",2.2)
	var before: Vector2 = player.get_hand_global_position()
	player._rest()
	_expect(before.distance_to(player.get_hand_global_position())<0.05,"Recovery begins at current pose rather than snapping to idle")
	player.hide()
	battle._stage.enemy.hide()
	for enemy_data: EnemyData in ContentDatabase._enemies_by_id.values():
		var enemy: EnemyRigActor = EnemyRigActor.new()
		enemy.atlas = load(battle._stage._enemy_art_path(enemy_data.art_id))
		enemy.size = Vector2(552,624)
		enemy.target_height = 432.0
		enemy.target_width = 662.0
		enemy.facing = -1.0
		enemy.position = Vector2(860,80)
		enemy.scale = Vector2.ONE*1.4
		add_child(enemy)
		await get_tree().process_frame
		_expect(enemy != null and enemy.skeleton.get_bone_count()==5,"Every enemy has the authored surface skeleton")
		var feet: Vector2 = enemy.anchor_position("feet")
		for action_name: String in ["idle","attack","heavy","flurry","hit","guard"]:
			for index: int in 11:
				enemy.sample_action_for_review(action_name,index/10.0)
				if not enemy._floating:
					_expect(enemy.anchor_position("feet").distance_to(feet)<0.05,"Grounded enemy support does not skate during body motion")
		enemy.sample_action_for_review("attack",0.45)
		await _capture(battle,"enemy-"+enemy_data.id,0.45,"attack")
		enemy.queue_free()
		await get_tree().process_frame
	# Capture a dense set of action poses and retain exact timestamps for review.
	battle._stage.enemy.hide()
	player.show()
	player.scale = Vector2.ONE*1.4
	for action_name: String in ["iron_strike","throw","heavy","block","channel","bell"]:
		var duration: float = float(data.actions[action_name].duration)
		for index: int in 13:
			var time: float = duration*index/12.0
			player.sample_action_for_review(action_name,time)
			await _capture(battle,"player-"+action_name,time,action_name)
	if not _captures.is_empty():
		var file: FileAccess = FileAccess.open(OUTPUT+"/manifest.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(_captures,"\t"))
	battle.queue_free()
	battle._stage.queue_free()
	await get_tree().process_frame
	if _failures.is_empty():
		print("MOTION_QUALITY_OK checks=%d max_joint_step_pixels=%.3f captures=%d" % [_checks,max_step,_captures.size()])
		get_tree().quit()
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)

func _test_human_3d(player: Executioner3DActor) -> void:
	_expect(player.skeleton.get_bone_count() == 63,"63 native deformation joints")
	player.sample_action_for_review("idle",0)
	var planted: Dictionary = {}
	for side: String in ["R","L"]:
		planted[side] = player._bone_world("foot."+side).origin
	for mesh: MeshInstance3D in player._mesh_nodes:
		_expect(mesh.skin != null,"Every visible character mesh retains native skin")
	for action_name: String in player.MOTION.actions:
		var clip: Dictionary = player.MOTION.actions[action_name]
		var previous: Dictionary = {}
		var previous_pose: Array[Transform3D] = []
		for frame: int in clip.frames.size():
			var time: float = float(frame)/60.0
			player.sample_action_for_review(action_name,time)
			var pose: Array[Transform3D] = player._local_frame(action_name,time)
			if frame%4==0:
				for index: int in pose.size():
					var imported: Transform3D = player.skeleton.get_bone_pose(player._indices[index])
					var bone_name: String = str(player.MOTION.bones[index].name)
					_expect(imported.origin.distance_to(pose[index].origin)<.0005,"Native animation retains Blender joint position: "+action_name+" "+bone_name)
					_expect(absf(imported.basis.get_rotation_quaternion().dot(pose[index].basis.get_rotation_quaternion()))>=cos(deg_to_rad(.5)*.5),"Native animation retains Blender joint rotation: "+action_name+" "+bone_name)
			if not previous_pose.is_empty():
				for index: int in pose.size():
					var dot: float = absf(pose[index].basis.get_rotation_quaternion().dot(previous_pose[index].basis.get_rotation_quaternion()))
					if dot < cos(deg_to_rad(45)*.5): print("JOINT_STEP action=%s frame=%d bone=%s degrees=%.1f" % [action_name,frame,str(player.MOTION.bones[index].name),rad_to_deg(2*acos(clampf(dot,0,1)))])
					_expect(dot>=cos(deg_to_rad(45)*.5),"No abrupt local joint rotation between 60 Hz samples")
			previous_pose = pose
			for side: String in ["R","L"]:
				for chain: Array in [["upper_arm.","forearm.","hand."],["thigh.","shin.","foot."]]:
					var a: Vector3 = player._bone_world(str(chain[0])+side).origin
					var b: Vector3 = player._bone_world(str(chain[1])+side).origin
					var c: Vector3 = player._bone_world(str(chain[2])+side).origin
					for segment: int in 2:
						var expected: float = 0.0
						for bone: Dictionary in player.MOTION.bones:
							if str(bone.name) == str(chain[segment])+side: expected = float(bone.length)
						var actual: float = a.distance_to(b) if segment == 0 else b.distance_to(c)
						_expect(absf(actual-expected)<.001,"Human limb lengths remain constant")
					_expect((b-a).angle_to(c-b)<deg_to_rad(146),"Elbows and knees stay within flexion limit")
				var wrist: Vector3 = player._bone_world("hand."+side).origin
				if previous.has(side):
					var step: float = wrist.distance_to(previous[side])
					if step >= .20: print("WRIST_STEP action=%s frame=%d side=%s meters=%.4f" % [action_name,frame,side,step])
					_expect(step<.20,"Wrist displacement remains below 12 m/s at 60 Hz")
				previous[side] = wrist
				var melee: bool = action_name in ["iron_strike","twin_right","twin_left","heavy"]
				if action_name != "fall" and (not melee or time<=1.82 or time>=2.88):
					_expect(player._bone_world("foot."+side).origin.distance_to(planted[side])<.002,"Grounded feet stay planted during holds and recovery")
		if action_name in ["idle","channel","chalice","bell","crown","block","siphon"]:
			var sample_a: float = 1.0 if action_name=="block" else 1.7 if action_name=="siphon" else 1.1
			var sample_b: float = 1.3 if action_name=="block" else 2.5 if action_name=="siphon" else 1.8
			player.sample_action_for_review(action_name,sample_a)
			var breathing_a: Transform3D = player._bone_world("spine_upper")
			player.sample_action_for_review(action_name,sample_b)
			var breathing_b: Transform3D = player._bone_world("spine_upper")
			var rotation_dot: float = absf(breathing_a.basis.get_rotation_quaternion().dot(breathing_b.basis.get_rotation_quaternion()))
			_expect(rotation_dot<cos(deg_to_rad(.08)*.5),"Sustained action retains native torso articulation: "+action_name)
		if action_name in ["iron_strike","twin_right","twin_left","heavy"]:
			var side: String = "L" if action_name=="twin_left" else "R"
			var other: String = "R" if side=="L" else "L"
			player.sample_action_for_review(action_name,1.98)
			var lead_air: Vector3 = player._bone_world("foot."+side).origin
			var rear_air: Vector3 = player._bone_world("foot."+other).origin
			_expect(rear_air.y-lead_air.y>.04,"Trailing knee tucks while lead foot reaches for landing: "+action_name)
			player.sample_action_for_review(action_name,float(clip.contact))
			var front_foot: Vector3 = player._bone_world("foot."+side).origin
			var rear_foot: Vector3 = player._bone_world("foot."+other).origin
			_expect((front_foot-rear_foot).dot(Vector3.BACK)>.20,"Melee lands with the active foot leading: "+action_name)
			var hip: Vector3 = player._bone_world("thigh."+side).origin
			var knee: Vector3 = player._bone_world("shin."+side).origin
			_expect((knee-hip).angle_to(front_foot-knee)>deg_to_rad(25),"Impact is cushioned by a bent support knee: "+action_name)
			var weapon: Transform3D = player.weapon_world(side)
			var blade: Vector3 = weapon.basis.y.normalized()
			_expect(blade.dot(player.camera.global_basis.x)>.60,"Actual equipped blade points toward the enemy at contact: "+action_name)
			player.sample_action_for_review(action_name,2.4)
			_expect(player._bone_world("foot."+side).origin.distance_to(front_foot)<.002 and player._bone_world("foot."+other).origin.distance_to(rear_foot)<.002,"Both impact feet remain planted through the follow-through: "+action_name)
			player.sample_action_for_review(action_name,1.5)
			_expect(player.weapon_world(side).basis.y.normalized().dot(Vector3.UP)>.90,"Summoned weapon is held upright: "+action_name)
			player.sample_action_for_review(action_name,1.82)
			_expect(player.grip_world(side).origin.y>player._bone_world("head").origin.y+.03,"Attack chambers the active hand above the head: "+action_name)
			if action_name=="heavy":
				# A held grip must survive between the authored checkpoints too.
				for sample_frame: int in range(24,152):
					var time: float = float(sample_frame)/60.0
					player.sample_action_for_review(action_name,time)
					var axis: Vector3 = player.weapon_world("R").basis.y.normalized()
					var handle_grip: Vector3 = player.grip_world("R").origin-axis*.14
					_expect(player.grip_world("L").origin.distance_to(handle_grip)<.03,"Heavy hammer's support palm stays on the handle at %.2f" % time)
			var ending: Array[Transform3D] = player._local_frame(action_name,float(clip.duration))
			var resting: Array[Transform3D] = player._local_frame("idle",0)
			for index: int in ending.size():
				var bone_name: String = str(player.MOTION.bones[index].name)
				if bone_name.begins_with("cloak_") or bone_name.begins_with("skirt."): continue
				_expect(ending[index].origin.distance_to(resting[index].origin)<.003,"Melee completes without a position snap to idle: "+action_name+" "+bone_name)
				var dot: float = absf(ending[index].basis.get_rotation_quaternion().dot(resting[index].basis.get_rotation_quaternion()))
				_expect(dot>=cos(deg_to_rad(8)*.5),"Melee recovers before idle: %s %s %.2f degrees" % [action_name,bone_name,rad_to_deg(2*acos(clampf(dot,0,1)))])
			player.sample_action_for_review(action_name,float(clip.contact))
			var tip_local: Vector3 = Vector3(.16,.53,0) if action_name=="heavy" else Vector3(0,.74,0)
			var initial_tip: Vector2 = player._project(player.weapon_world(side)*tip_local)
			var target: Vector2 = initial_tip+Vector2(170,0)
			player.play_action(action_name,{"target_position":target})
			player.sample_action_for_review(action_name,float(clip.contact))
			var fitted_tip: Vector2 = player._project(player.weapon_world(side)*tip_local)
			_expect(absf(fitted_tip.x-target.x)<.25,"Actual equipped weapon reaches the target horizontally: "+action_name)
			player._retarget_action = ""
			player._strike_offset = Vector3.ZERO
	print("MOTION_3D_QUALITY checks=%d failures=%d" % [_checks,_failures.size()])
	for failure: String in _failures: push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)

func _expect(condition: bool,message: String) -> void:
	_checks += 1
	if not condition:
		if not _failures.has(message):
			_failures.append(message)

func _capture(battle: CombatController,label: String,time: float,action_name: String) -> void:
	if DisplayServer.get_name()=="headless":
		return
	# Skeleton skinning uploads follow canvas-transform notifications. Settle
	# both frames after moving a studio actor before reading rendered pixels.
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var path: String = OUTPUT+"/%s-%04d.png" % [label,roundi(time*1000)]
	var error: Error = get_viewport().get_texture().get_image().save_png(path)
	_expect(error==OK,"Capture saved")
	_captures.append({"path":path,"time":time,"action":action_name,"label":label})
