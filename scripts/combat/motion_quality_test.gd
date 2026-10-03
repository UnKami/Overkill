extends Node
## Anatomy, grounding and transitions tested against the real runtime bones.
var _checks: int = 0
var _captures: Array[Dictionary] = []
var _failures: PackedStringArray = []
const OUTPUT: String = "res://.test-artifacts/043/motion"

func _ready() -> void:
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
						_expect(flexion*(1.0 if side=="near" else -1.0)>-0.01,"Elbow bend keeps its anatomical direction")
						_expect(absf(flexion)<deg_to_rad(112.2),"Elbow cannot overfold")
				var ankle: Vector2 = (player._bone_names["foot_"+side] as Bone2D).global_position
				if action_name not in ["iron_strike","heavy","fall"] or (action_name=="iron_strike" and time<=1.83) or (action_name=="heavy" and time<=1.85):
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
