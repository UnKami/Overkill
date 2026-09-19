extends Node
## Real controller decisions and damage; diagnostic measurements, not an FPS gate.
var battle: CombatController
var stage: DirectedArena
var recording: bool = false
var previous_us: int = 0
var buckets: Dictionary = {}
var results: Array[Dictionary] = []

func _process(_delta: float) -> void:
	if not recording: return
	var now: int = Time.get_ticks_usec()
	var phase: String = "finish" if battle._combat_over else ("resolution" if battle._resolving else "decision")
	if not buckets.has(phase): buckets[phase] = {"wall":[],"gpu":[],"cpu":[],"draws":[]}
	var bucket: Dictionary = buckets[phase]
	bucket.wall.append((now-previous_us)/1000.0)
	bucket.gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(stage._view.get_viewport_rid()))
	bucket.cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(stage._view.get_viewport_rid()))
	bucket.draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	previous_us = now

func _ready() -> void:
	assert(DisplayServer.get_name() != "headless", "Encounter profiling requires rendered frames")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	get_window().size = Vector2i(1920,1080)
	AudioManager.set_master_volume(0)
	AudioManager.fast_mode = false
	AudioManager.reduced_motion = false
	AudioManager.text_size = "normal"
	for quality: String in ["high","performance","high"]:
		await profile_encounter(quality)
	DirAccess.make_dir_recursive_absolute("user://profiles")
	var file: FileAccess = FileAccess.open("user://profiles/encounters.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	print("ENCOUNTER_PROFILE_DONE trials=",results.size())
	get_tree().quit()

func profile_encounter(quality: String) -> void:
	AudioManager.render_quality = quality
	seed(1729)
	RunManager.start_new_run([],[],80,1729)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("act1_boss")])
	stage = battle._stage
	RenderingServer.viewport_set_measure_render_time(stage._view.get_viewport_rid(),true)
	await get_tree().create_timer(4.0).timeout
	buckets = {}
	var trace: Array[String] = []
	previous_us = Time.get_ticks_usec()
	recording = true
	for decision: int in 36:
		if battle._combat_over: break
		await get_tree().create_timer(0.35).timeout
		if battle.phase == CombatController.Phase.ASSEMBLY:
			var relic: ClockRelicData = battle.current_draft_selection[0]
			trace.append(relic.id)
			await battle._on_phase_one_relic_chosen(relic)
		else:
			trace.append("sweep")
			await battle._on_skip_button_pressed()
	await get_tree().create_timer(2.0).timeout
	recording = false
	var report: Dictionary = {"quality":quality,"render_size":str(stage._view.size),"trace":trace,"finished":battle._combat_over,"player_hp":battle.player_hp,"enemy_hp":battle.enemy_hp,"phases":{},"device":RenderingServer.get_video_adapter_name(),"muted":true}
	for phase: String in buckets:
		var data: Dictionary = buckets[phase]
		data.wall.sort()
		data.gpu.sort()
		data.cpu.sort()
		data.draws.sort()
		report.phases[phase] = {"frames":data.wall.size(),"median_ms":percentile(data.wall,0.5),"p95_ms":percentile(data.wall,0.95),"p99_ms":percentile(data.wall,0.99),"worst_ms":data.wall.back(),"stage_gpu_median_ms":percentile(data.gpu,0.5),"stage_cpu_median_ms":percentile(data.cpu,0.5),"peak_draws":data.draws.back()}
	results.append(report)
	print("ENCOUNTER_PROFILE ",JSON.stringify(report))
	remove_child(battle)
	battle.queue_free()
	await get_tree().process_frame

func percentile(values: Array, fraction: float) -> float:
	return float(values[mini(values.size()-1,int(values.size()*fraction))])
