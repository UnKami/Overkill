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
const OUTPUT := "res://.test-artifacts/043/animations"

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	AudioManager.set_master_volume(0.0)
	AudioManager.fast_mode = false
	AudioManager.reduced_motion = false
	_benchmark = OS.get_cmdline_user_args().has("--benchmark")
	_motion_video = OS.get_cmdline_user_args().has("--motion-video")
	_movie_review = OS.get_cmdline_user_args().has("--movie-review")
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
	var skeleton: Skeleton2D = _find_skeleton(battle._stage.player)
	assert(skeleton != null and skeleton.get_bone_count() >= 12, "Live character needs a real limb skeleton")
	await _check_status_lifecycle()
	if _benchmark: _last_frame_usec = Time.get_ticks_usec()
	var named: Array[String] = ["REL-01", "REL-25", "REL-04", "REL-16", "REL-13", "REL-14", "REL-15", "REL-03", "REL-11"]
	for id: String in named:
		await _exercise(id, true)
	if _movie_review:
		battle.queue_free()
		await get_tree().process_frame
		print("RELIC_MOVIE_REVIEW_OK: nine signature/melee sequences at fixed simulation FPS")
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
	battle.queue_free()
	await get_tree().process_frame
	print("RELIC_ANIMATION_OK: real skeleton, seven named sequences, complete relic catalog, damage/block/lifesteal outcomes, fast/reduced motion and recovery")
	get_tree().quit()

func _process(_delta: float) -> void:
	if _benchmark and _last_frame_usec > 0:
		var now: int = Time.get_ticks_usec()
		_frame_times.append(float(now - _last_frame_usec) / 1000.0)
		_last_frame_usec = now

func _check_status_lifecycle() -> void:
	# Repeated production status redraws must not orphan fallback icon nodes.
	var row := HBoxContainer.new()
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
	while _active:
		await get_tree().create_timer(1.0/24.0 if _motion_video and capture else 0.35).timeout
		if capture:
			await _capture("%s-%02d" % [id, shot], Time.get_ticks_msec() - start)
		shot += 1
		# Synchronous PNG encoding slows wall time without advancing authored
		# simulation time equivalently; retain the tighter bound without capture.
		assert(Time.get_ticks_msec() - start < (120000 if _capture_enabled or _movie_review else 22000), "Animation failed to finish: " + id)
	assert(not battle._stage.player._busy, "Character must recover before the next action")
	await get_tree().create_timer(0.8 / AudioManager.animation_speed_scale()).timeout
	assert(battle.find_children("RelicChoreography*", "", true, false).is_empty(), "Temporary choreography must be cleaned up")
	match id:
		"REL-01":
			assert(battle.enemy_hp == 9994, "Iron Strike damage changed")
			if not AudioManager.fast_mode and not _movie_review:
				assert(Time.get_ticks_msec() - start >= 2500, "Summon, launch and recovery need recognizable time")
		"REL-04": assert(battle.player_block == 7, "Guard Plate balance changed")
		"REL-15":
			assert(battle.player_block == 10, "Bell must grant exactly ten Block")
			if not AudioManager.fast_mode and not _movie_review:
				assert(Time.get_ticks_msec() - start >= 2500, "Bell needs two seconds of ringing before its reward")
		"REL-16": assert(battle.player_strength == 3, "War Crown strength changed")
		"REL-25":
			assert(battle.player_strength == 1, "Oath Chalice strength changed")
			assert(OKRunState.current_ok - before_ok == 2, "Oath Chalice overkill changed")
		"REL-13": assert(battle.player_hp == 103 and battle.enemy_hp == 9997, "Siphon must heal only actual damage")
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
