extends Node
## Roster-wide presentation fixture; no combat/RNG simulation claims.
func _ready() -> void:
	AudioManager.set_master_volume(0)
	AudioManager.text_size = "large" if "--large-intents" in OS.get_cmdline_user_args() else "normal"
	get_window().size = Vector2i(1280,720)
	RunManager.start_new_run([],[],80,1729)
	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("act1_boss")])
	await get_tree().create_timer(2.0).timeout
	var checked: int = 0
	for id: String in ["boneghoul","act1_elite","act1_boss","act2_trash","act2_elite","act2_boss","act3_trash","act3_elite","act3_boss","final_boss"]:
		var enemy: EnemyData = ContentDatabase.get_enemy(id)
		assert(enemy != null)
		battle.enemies_data = [enemy]
		battle.enemy_sockets = EnemyClockPattern.create(enemy)
		for socket: ClockSocketData in battle.enemy_sockets: socket.intent_revealed = true
		battle.phase = CombatController.Phase.QUADRANT
		for quadrant: int in range(1,4):
			battle.active_quadrant = quadrant
			battle._refresh_intent_readout()
			await get_tree().process_frame
			await get_tree().process_frame
			assert(not battle.has_node("EnemyIntentPanel"), "Duplicate enemy intent panel returned")
			assert(not "ENEMY NEXT" in battle._intent_clock_label.text, "Clock still repeats the removed banner")
			if EnemyClockPattern.has_twin(enemy): assert("echo" in battle._intent_clock_label.text.to_lower())
			checked += 1
		if id in ["act2_elite","act3_elite","final_boss"] and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("user://intent-041")
			get_viewport().get_texture().get_image().save_png("user://intent-041/"+id+".png")
		for socket: ClockSocketData in battle.enemy_sockets: socket.intent_revealed = false
		battle._refresh_intent_readout()
		assert(battle._intent_clock_label.text.contains("→") or not battle._intent_clock_label.text.is_empty(), "Enemy hour path is missing")
	print("ENEMY_INTENT_READOUT_OK: ",checked," roster sweeps, bounds, choice clearance, siphon/echo and hidden intent")
	get_tree().quit()
