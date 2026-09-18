extends Node
var _measure := false
var _frame_times: Array[float] = []

func _process(delta: float) -> void:
	if _measure: _frame_times.append(delta*1000.0)

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920,1080)
	AudioManager.set_master_volume(0)
	AudioManager.fast_mode = false
	RunManager.start_new_run([],[],80,1729)
	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("act1_boss")])
	await get_tree().create_timer(2.5).timeout
	print("CLIPS: ",battle._stage.player._animation.get_animation_list())
	for clip in battle._stage.player._animation.get_animation_list(): print(clip, " duration ",battle._stage.player._animation.get_animation(clip).length)
	await capture("directed-idle")
	if OS.get_cmdline_user_args().has("--benchmark"):
		await benchmark("full")
		battle._stage._view.render_target_update_mode = SubViewport.UPDATE_DISABLED
		await benchmark("ui_only")
		battle._stage._view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		battle.get_node("CombatArena").hide()
		battle.get_node("BottomDock").hide()
		await benchmark("stage_only")
		battle._stage._view.render_target_update_mode = SubViewport.UPDATE_DISABLED
		battle.hide()
		await benchmark("hidden_battle")
		battle.queue_free()
		await get_tree().process_frame
		await benchmark("empty_scene")
		get_tree().quit()
		return
	_measure = true
	await get_tree().create_timer(3.0).timeout
	_measure = false
	_frame_times.sort()
	print("FRAME_TIMES_MS median=",_frame_times[_frame_times.size()/2]," p95=",_frame_times[int(_frame_times.size()*0.95)]," samples=",_frame_times.size())
	print("DRAW_CALLS ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," PROCESS_MS ",Performance.get_monitor(Performance.TIME_PROCESS)*1000)
	battle._stage.attack(true)
	await get_tree().create_timer(0.23).timeout
	await capture("directed-windup")
	await get_tree().create_timer(0.09).timeout
	battle._stage.impact(false,false)
	await get_tree().create_timer(0.035).timeout
	await capture("directed-impact")
	await get_tree().create_timer(0.7).timeout
	battle._stage.attack(false)
	await get_tree().create_timer(0.32).timeout
	battle._stage.impact(true,true)
	await capture("directed-guard")
	await get_tree().create_timer(0.7).timeout
	battle._stage.finish(true)
	await get_tree().create_timer(1.2).timeout
	await capture("directed-death")
	get_window().size = Vector2i(1280,720)
	await get_tree().create_timer(0.2).timeout
	await capture("directed-720p")
	print("DIRECTED_RENDER_OK")
	get_tree().quit()

func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/clock-battle")
	get_viewport().get_texture().get_image().save_png("res://artifacts/clock-battle/"+label+".png")

func benchmark(label: String) -> void:
	_frame_times.clear()
	await get_tree().create_timer(0.5).timeout
	_measure = true
	await get_tree().create_timer(2.0).timeout
	_measure = false
	_frame_times.sort()
	print("BENCH ",label," median_ms=",_frame_times[_frame_times.size()/2]," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
