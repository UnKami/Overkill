extends Node
## Diagnostic only: warmed wall-clock samples, no frame-rate acceptance claim.
var battle: CombatController
var stage: DirectedArena
var hidden_ui: Array[CanvasItem] = []

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	AudioManager.set_master_volume(0)
	get_window().size = Vector2i(1920,1080)
	RunManager.start_new_run([],[],80,1729)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("act1_boss")])
	stage = battle._stage
	await get_tree().create_timer(4.0).timeout
	RenderingServer.viewport_set_measure_render_time(stage._view.get_viewport_rid(),true)
	for child: Node in battle.get_children():
		if child is CanvasItem and child != stage and child.visible: hidden_ui.append(child)
	await sample("full_start")
	for item: CanvasItem in hidden_ui: item.hide()
	await sample("stage_only")
	for item: CanvasItem in hidden_ui: item.show()
	if "--arena-profile-short" in OS.get_cmdline_user_args():
		await sample("full_end")
		print("ARENA_PROFILE_DONE")
		get_tree().quit()
		return
	stage._view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	await sample("ui_only_frozen_stage")
	stage._view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage.player.process_mode = Node.PROCESS_MODE_DISABLED
	stage.enemy.process_mode = Node.PROCESS_MODE_DISABLED
	await sample("frozen_actors")
	stage.player.process_mode = Node.PROCESS_MODE_INHERIT
	stage.enemy.process_mode = Node.PROCESS_MODE_INHERIT
	var full_size: Vector2i = stage._view.size
	stage._view.size = Vector2i(1200,roundi(1200.0*full_size.y/full_size.x))
	await sample("stage_1200")
	stage._view.size = full_size
	stage._view.msaa_3d = Viewport.MSAA_DISABLED
	await sample("no_msaa")
	stage._view.msaa_3d = Viewport.MSAA_2X
	await sample("full_end")
	print("ARENA_PROFILE_DONE")
	get_tree().quit()

func sample(label: String) -> void:
	await get_tree().create_timer(2.0).timeout
	var times: Array[float] = []
	var cpu: Array[float] = []
	var gpu: Array[float] = []
	var begin: int = Time.get_ticks_usec()
	var previous: int = begin
	while Time.get_ticks_usec()-begin < 8000000:
		await get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		times.append((now-previous)/1000.0)
		previous = now
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(stage._view.get_viewport_rid()))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(stage._view.get_viewport_rid()))
	times.sort()
	cpu.sort()
	gpu.sort()
	var result: Dictionary = {"phase":label,"samples":times.size(),"median_ms":times[times.size()/2],
		"p95_ms":times[int(times.size()*0.95)],"p99_ms":times[int(times.size()*0.99)],
		"stage_cpu_ms":cpu[cpu.size()/2] if stage._view.render_target_update_mode != SubViewport.UPDATE_DISABLED else null,
		"stage_gpu_ms":gpu[gpu.size()/2] if stage._view.render_target_update_mode != SubViewport.UPDATE_DISABLED else null,
		"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"render_size":str(stage._view.size)}
	print("ARENA_PROFILE ",JSON.stringify(result))
