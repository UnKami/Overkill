extends Node
## Diagnostic only: warmed wall-clock samples, no frame-rate acceptance claim.
var battle: CombatController
var stage: DirectedArena
var hidden_ui: Array[CanvasItem] = []
var exercise_actions: bool = false
var action_cycle: int = 0
var action_elapsed: float = 0.0
var contact_sent: bool = false

func _process(delta: float) -> void:
	if not exercise_actions: return
	action_elapsed += delta * AudioManager.animation_speed_scale()
	var from_player: bool = action_cycle % 2 == 0
	var actor: Node3D = stage.player if from_player else stage.enemy
	if not contact_sent and action_elapsed >= actor.contact_time():
		stage.impact(not from_player,action_cycle % 3 == 0)
		contact_sent = true
	if action_elapsed >= 1.6:
		action_elapsed = 0.0
		contact_sent = false
		action_cycle += 1
		stage.attack(action_cycle % 2 == 0)

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	AudioManager.set_master_volume(0)
	get_window().size = Vector2i(1920,1080)
	RunManager.start_new_run([],[],80,1729)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var bone_study: bool = OS.get_cmdline_user_args().has("--arena-profile-bone")
	battle.start_combat([ContentDatabase.get_enemy("boneghoul" if bone_study else "act1_boss")])
	stage = battle._stage
	await get_tree().create_timer(4.0).timeout
	RenderingServer.viewport_set_measure_render_time(stage._view.get_viewport_rid(),true)
	for child: Node in battle.get_children():
		if child is CanvasItem and child != stage and child.visible: hidden_ui.append(child)
	await sample("full_start")
	if bone_study:
		assert(stage.enemy is BoneghoulActor, "Bone material profile requires --boneghoul-3d")
		stage.enemy.set_surface_detail(false)
		await sample("bone_base")
		stage.enemy.set_surface_detail(true)
		await sample("bone_detail_restored")
		print("ARENA_PROFILE_DONE bone_material_comparison")
		get_tree().quit()
		return
	if "--arena-profile-actions" in OS.get_cmdline_user_args():
		battle._choice_overlay.hide()
		stage.set_decision_view(false)
		exercise_actions = true
		stage.attack(true)
		await sample("action_normal")
		AudioManager.fast_mode = true
		await sample("action_fast")
		AudioManager.fast_mode = false
		AudioManager.reduced_motion = true
		stage.set_decision_view(true)
		await sample("action_reduced")
		exercise_actions = false
		print("ARENA_PROFILE_DONE presentation_cycles=",action_cycle)
		get_tree().quit()
		return
	if "--arena-profile-engraving" in OS.get_cmdline_user_args():
		var engravings: Array[CanvasItem] = []
		for node: Node in battle.find_children("*","Control",true,false):
			if node.get_script() == preload("res://scripts/ui/clock_engraving.gd"):
				engravings.append(node)
				node.hide()
		await sample("without_engraving")
		for node: CanvasItem in engravings: node.show()
		await sample("full_end")
		print("ARENA_PROFILE_DONE engraving_count=",engravings.size())
		get_tree().quit()
		return
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
	var draw_counts: Array[float] = []
	var begin: int = Time.get_ticks_usec()
	var previous: int = begin
	while Time.get_ticks_usec()-begin < 8000000:
		await get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		times.append((now-previous)/1000.0)
		previous = now
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(stage._view.get_viewport_rid()))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(stage._view.get_viewport_rid()))
		draw_counts.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	times.sort()
	cpu.sort()
	gpu.sort()
	draw_counts.sort()
	var result: Dictionary = {"phase":label,"samples":times.size(),"median_ms":times[times.size()/2],
		"p95_ms":times[int(times.size()*0.95)],"p99_ms":times[int(times.size()*0.99)],
		"stage_cpu_ms":cpu[cpu.size()/2] if stage._view.render_target_update_mode != SubViewport.UPDATE_DISABLED else null,
		"stage_gpu_ms":gpu[gpu.size()/2] if stage._view.render_target_update_mode != SubViewport.UPDATE_DISABLED else null,
		"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"peak_draws":draw_counts.back(),"over_16ms_pct":100.0*times.filter(func(t: float) -> bool: return t > 16.667).size()/times.size(),
		"render_size":str(stage._view.size)}
	print("ARENA_PROFILE ",JSON.stringify(result))
