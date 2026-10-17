extends Node
## Runs real tick resolution in a disposable profile. No autoplay is exposed
## to players: this scene exists only for deterministic release verification.
var battle: CombatController
var _active: bool = false
var _capture_enabled: bool = false
var _frames: Array[Dictionary] = []
var _benchmark: bool = false
var _motion_video: bool = false
var _movie_review: bool = false
var _frame_times: Array[float] = []
var _last_frame_usec: int = 0
var _jpg_review: bool = false
var _jpg_frame: int = 0
var _frame_output: String = "res://.test-artifacts/047/jpg_rotation_fixed"
var _profile_totals: Vector4 = Vector4.ZERO
var _profile_frames: int = 0
var _viewport_profiles: Dictionary = {}
var _invalid_gpu_samples: int = 0
var _invalid_gpu_categories: Dictionary = {}
const OUTPUT := "res://.test-artifacts/043/animations"

func _ready() -> void:
	if not QAProfileGuard.require_isolated(self): return
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--render-quality="):
			var quality: String = argument.trim_prefix("--render-quality=")
			assert(quality in ["high","balanced","performance"],"QA quality must be an existing graphics preset")
			AudioManager.render_quality = quality
	AudioManager.set_master_volume(0.0)
	AudioManager.fast_mode = false
	AudioManager.reduced_motion = false
	_benchmark = OS.get_cmdline_user_args().has("--benchmark")
	if _benchmark:
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
		get_viewport().add_to_group("qa_render_measurements")
	_motion_video = OS.get_cmdline_user_args().has("--motion-video")
	_jpg_review = OS.get_cmdline_user_args().has("--jpg-review")
	_movie_review = OS.get_cmdline_user_args().has("--movie-review") or _jpg_review
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--frame-output="):
			var requested: String = argument.trim_prefix("--frame-output=").simplify_path()
			assert(requested.begins_with("user://") or requested.begins_with("res://.test-artifacts/"),"Frame output must stay inside the isolated QA profile or test artifacts")
			_frame_output = requested
	if _jpg_review:
		assert(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_frame_output))==OK)
		print("RELIC_FRAME_OUTPUT ",ProjectSettings.globalize_path(_frame_output))
	if _motion_video or _movie_review: get_window().size = Vector2i(1280,720)
	_capture_enabled = DisplayServer.get_name() != "headless" and not _benchmark and not _movie_review
	RunManager.start_new_run([], [], 500, 42042)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy: EnemyData = ContentDatabase.get_enemy("boneghoul").duplicate(true)
	enemy.max_hp = 10000
	battle.start_combat([enemy])
	await get_tree().create_timer(1.5).timeout
	assert(battle._stage.player.has_method("get_hand_global_position"), "The live player must use the articulated rig")
	var skeleton: Skeleton3D = (battle._stage.player as Executioner3DActor).skeleton
	assert(skeleton != null and skeleton.get_bone_count() >= 63, "Live character needs the actual human, finger and twist skeleton")
	await _check_status_lifecycle()
	if OS.get_cmdline_user_args().has("--profile-no-character-render"):
		assert(_benchmark and OS.get_cmdline_user_args().has("--profile-only"),"Render isolation is only a profiling fixture")
		var actor: Executioner3DActor = battle._stage.player as Executioner3DActor
		actor.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		actor._front.hide()
		actor.viewport.remove_from_group("qa_render_measurements")
		print("RELIC_PROFILE_VARIANT character render disabled; skeleton and combat continue")
	if _benchmark: _last_frame_usec = Time.get_ticks_usec()
	var named: Array[String] = ["REL-01", "REL-25", "REL-04", "REL-16", "REL-13", "REL-14", "REL-15", "REL-03", "REL-11"]
	if OS.get_cmdline_user_args().has("--melee-review"):
		named = ["REL-01","REL-02","REL-03","REL-11"]
	if OS.get_cmdline_user_args().has("--include-twin"):
		assert(_movie_review,"Additional Twin Blades capture is a visual review option")
		if "REL-02" not in named: named.append("REL-02")
	var profile_only: bool = OS.get_cmdline_user_args().has("--profile-only")
	if profile_only: named = ["REL-01","REL-03","REL-13"]
	for id: String in named:
		await _exercise(id, true)
	if profile_only:
		_report_profile()
		print("RELIC_PROFILE_OK three real sequences, timing diagnostics only")
		get_tree().quit()
		return
	if _movie_review:
		_jpg_review = false
		battle.queue_free()
		await get_tree().process_frame
		print("RELIC_MOVIE_REVIEW_OK: %d real relic sequences at fixed simulation FPS" % named.size())
		get_tree().quit()
		return
	# Check every catalog item reaches recovery and cannot leave an input lock.
	AudioManager.fast_mode = true
	for relic: ClockRelicData in ContentDatabase.all_clock_relics(true):
		if relic.id not in named:
			await _exercise(relic.id, false)
	# The siphon cannot heal through Block or exceed the actual missing health.
	_reset()
	battle.enemy_block = 100
	var siphon: ClockRelicData = ContentDatabase.get_clock_relic("REL-13")
	battle.player_sockets[0].slotted_relic = siphon
	await battle._resolve_tick(1)
	assert(battle.player_hp == 100, "Fully blocked lifesteal must never show or apply healing")
	AudioManager.reduced_motion = true
	await _exercise("REL-01", false)
	await _exercise("REL-15", false)
	if _capture_enabled:
		var manifest: FileAccess = FileAccess.open(OUTPUT + "/manifest.json", FileAccess.WRITE)
		manifest.store_string(JSON.stringify(_frames, "\t"))
	if _benchmark and not _frame_times.is_empty():
		_frame_times.sort()
		var total_ms: float = 0.0
		for frame_ms: float in _frame_times: total_ms += frame_ms
		var p95: float = _frame_times[mini(int(_frame_times.size() * 0.95), _frame_times.size() - 1)]
		print("RELIC_RENDER_BENCHMARK frames=%d mean_fps=%.2f p95_frame_ms=%.2f renderer=%s" % [_frame_times.size(), 1000.0 * _frame_times.size() / total_ms, p95, RenderingServer.get_current_rendering_method()])
		_report_profile()
	battle.queue_free()
	await get_tree().process_frame
	print("RELIC_ANIMATION_OK: real skeleton, seven named sequences, complete relic catalog, damage/block/lifesteal outcomes, fast/reduced motion and recovery")
	get_tree().quit()

func _process(_delta: float) -> void:
	if _jpg_review: _save_review_frame()
	if _benchmark and _last_frame_usec > 0:
		var now: int = Time.get_ticks_usec()
		_frame_times.append(float(now - _last_frame_usec) / 1000.0)
		_last_frame_usec = now
		var cpu: float = RenderingServer.get_frame_setup_time_cpu()
		var gpu: float = 0.0
		for view: Node in get_tree().get_nodes_in_group("qa_render_measurements"):
			var rid: RID = (view as Viewport).get_viewport_rid()
			var view_cpu: float = RenderingServer.viewport_get_measured_render_time_cpu(rid)
			var view_gpu: float = RenderingServer.viewport_get_measured_render_time_gpu(rid)
			var category: String = "character" if str(view.name)=="LiveCharacter3D" else "relic" if view is SubViewport else "arena"
			if not is_finite(view_gpu) or view_gpu < 0 or view_gpu > 1000:
				# A resized GL viewport can return a wrapped timestamp on this
				# driver. Never report that sentinel as a real GPU cost.
				_invalid_gpu_samples += 1
				_invalid_gpu_categories[category] = int(_invalid_gpu_categories.get(category,0))+1
				view_gpu = 0.0
			cpu += view_cpu
			gpu += view_gpu
			_viewport_profiles[category] = (_viewport_profiles.get(category,Vector4.ZERO) as Vector4)+Vector4(view_cpu,view_gpu,float(RenderingServer.viewport_get_render_info(rid,RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)),1)
		_profile_totals += Vector4(float(Performance.get_monitor(Performance.TIME_PROCESS))*1000,cpu,gpu,float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		_profile_frames += 1

func _report_profile() -> void:
	if _profile_frames==0: return
	var average: Vector4 = _profile_totals/float(_profile_frames)
	var elapsed: float = 0
	for frame: float in _frame_times: elapsed += frame
	var gpu_report: String = "unavailable" if _invalid_gpu_samples>0 else "%.3f" % average.z
	var sorted_frames: Array[float] = _frame_times.duplicate()
	sorted_frames.sort()
	var p95: float = sorted_frames[mini(int(sorted_frames.size()*.95),sorted_frames.size()-1)]
	print("RELIC_FRAME_PACING p95_ms=%.3f measured_wall_frames=%d" % [p95,sorted_frames.size()])
	print("RELIC_FRAME_PROFILE frames=%d mean_fps=%.2f process_ms=%.3f render_cpu_ms=%.3f render_gpu_ms=%s draw_calls=%.1f invalid_gpu_samples=%d" % [_profile_frames,1000.0*_frame_times.size()/elapsed,average.x,average.y,gpu_report,average.w,_invalid_gpu_samples])
	for category: String in _viewport_profiles:
		var row: Vector4 = _viewport_profiles[category]
		var category_gpu: String = "unavailable" if _invalid_gpu_categories.has(category) else "%.3f" % (row.y/row.w)
		print("RELIC_VIEWPORT_PROFILE %s cpu_ms=%.3f gpu_ms=%s draw_calls=%.1f" % [category,row.x/row.w,category_gpu,row.z/row.w])

func _save_review_frame() -> void:
	var frame: int = _jpg_frame
	_jpg_frame += 1
	await RenderingServer.frame_post_draw
	if _jpg_review:
		assert(get_viewport().get_texture().get_image().save_jpg(_frame_output+"/battle%08d.jpg" % frame,.94)==OK,"Every native review frame must save")

func _check_status_lifecycle() -> void:
	# Repeated production status redraws must not orphan fallback icon nodes.
	var row := HBoxContainer.new()
	# Lifecycle stress nodes are diagnostic, not part of the battle composition.
	row.visible = false
	add_child(row)
	await get_tree().process_frame
	var before: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for iteration: int in 40:
		battle._update_status_strip(row, 0, 2, 3, 0, 0)
		battle._add_stat_chip(row, "res://missing-status-fixture.png", "?", "1", "Fallback", Color.WHITE)
		await get_tree().process_frame
	await get_tree().process_frame
	assert(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) <= before, "Status redraws must not leak unparented fallback icons")
	row.queue_free()
	await get_tree().process_frame
	print("STATUS_LIFECYCLE_OK: forty repeated production status/fallback redraws without orphan growth")

func _exercise(id: String, capture: bool) -> void:
	_reset()
	var relic: ClockRelicData = ContentDatabase.get_clock_relic(id)
	assert(relic != null, "Unknown relic " + id)
	battle.player_sockets[0].slotted_relic = relic
	var before_ok: int = OKRunState.current_ok
	var start: int = Time.get_ticks_msec()
	_active = true
	_run_tick()
	var shot: int = 0
	var tether_mesh_id: int = 0
	while _active:
		await get_tree().create_timer(1.0/24.0 if _motion_video and capture else 0.35).timeout
		if id=="REL-13":
			for node: Node in battle.find_children("RelicChoreography*","",true,false):
				var cue: RelicChoreography = node as RelicChoreography
				if cue._native_view==null or cue._native_view._tube==null: continue
				var mesh_id: int = cue._native_view._tube.mesh.get_instance_id()
				if tether_mesh_id==0: tether_mesh_id = mesh_id
				assert(mesh_id==tether_mesh_id,"Siphon must keep the same mesh resource throughout the transfer")
				if cue._native_view._tube.visible:
					var hand: Vector3 = cue._native_view.actor.grip_world("R").origin
					assert(cue._native_view._tube.custom_aabb.has_point(hand),"Dynamic tether bounds must include the live hand")
		if capture:
			await _capture("%s-%02d" % [id, shot], Time.get_ticks_msec() - start)
		shot += 1
		# Synchronous PNG encoding slows wall time without advancing authored
		# simulation time equivalently; retain the tighter bound without capture.
		assert(Time.get_ticks_msec() - start < (120000 if _capture_enabled or _movie_review else 22000), "Animation failed to finish: " + id)
	assert(not battle._stage.player._busy, "Character must recover before the next action")
	if id=="REL-13":
		assert(tether_mesh_id!=0,"Real Siphon must exercise its persistent tube")
		print("SIPHON_PERSISTENT_MESH_OK resource retained through real transfer")
	await get_tree().create_timer(0.8 / AudioManager.animation_speed_scale()).timeout
	assert(battle.find_children("RelicChoreography*", "", true, false).is_empty(), "Temporary choreography must be cleaned up")
	match id:
		"REL-01":
			assert(battle.enemy_hp == 9994, "Iron Strike damage changed")
			if not AudioManager.fast_mode and not _movie_review:
				assert(Time.get_ticks_msec() - start >= 2500, "Summon, launch and recovery need recognizable time")
		"REL-04": assert(battle.player_block == 6, "Guard Plate balance changed")
		"REL-15":
			assert(battle.player_block == 8, "Bell must grant base Block")
			if not AudioManager.fast_mode and not _movie_review:
				assert(Time.get_ticks_msec() - start >= 2500, "Bell needs two seconds of ringing before its reward")
		"REL-16": assert(battle.player_strength == 2, "War Crown strength changed")
		"REL-25":
			assert(battle.player_strength == 2, "Oath Chalice strength changed")
			assert(OKRunState.current_ok - before_ok == 4, "Oath Chalice overkill changed")
		"REL-13": assert(battle.player_hp == 104 and battle.enemy_hp == 9996, "Siphon must heal only actual damage")
		"REL-14": assert(battle.enemy_hp == 9996 and battle.player_next_attack_multiplier == 2, "Piston damage/multiplier changed")
	print("RELIC_SEQUENCE_OK %s duration_ms=%d" % [id, Time.get_ticks_msec() - start])

func _run_tick() -> void:
	await battle._resolve_tick(1)
	_active = false

func _reset() -> void:
	battle.player_hp = 100
	battle.player_max_hp = 500
	battle.enemy_hp = 10000
	battle.enemy_max_hp = 10000
	for key: String in ["player_block", "player_strength", "player_weak", "player_vulnerable", "player_bleed", "player_thorns", "player_next_hit_bonus", "enemy_block", "enemy_strength", "enemy_weak", "enemy_vulnerable", "enemy_bleed", "enemy_thorns"]:
		battle.set(key, 0)
	battle.player_next_attack_multiplier = 1
	battle._combat_over = false
	for socket: ClockSocketData in battle.enemy_sockets:
		socket.intent_damage = 0
		socket.intent_block = 0
		socket.intent_strength = 0
		socket.intent_bleed = 0
		socket.intent_weak = 0
		socket.intent_vulnerable = 0
	battle._update_stats_display()

func _capture(label: String, elapsed_ms: int) -> void:
	if not _capture_enabled: return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var path: String = OUTPUT + "/" + label + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	_frames.append({"path": path, "elapsed_ms": elapsed_ms})

func _find_skeleton(node: Node) -> Skeleton2D:
	if node is Skeleton2D: return node as Skeleton2D
	for child: Node in node.get_children():
		var found: Skeleton2D = _find_skeleton(child)
		if found != null: return found
	return null
