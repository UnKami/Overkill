extends Node
func _ready() -> void:
	AudioManager.set_master_volume(0)
	RunManager.start_new_run([],[],80,912)
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920,1080)
	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy: EnemyData = ContentDatabase.get_enemy("act1_boss").duplicate()
	enemy.max_hp = 800
	battle.start_combat([enemy])
	await capture("next-hour-one")
	assert(battle._guidance.target == battle._player_chrono.get_socket_view(1))
	var draft: RelicPedestalView = battle._pedestal_row.get_child(0)
	var chosen := draft.relic
	var before := battle.player_hp
	draft.previewed.emit(draft)
	await capture("placement-preview")
	assert(battle.player_sockets[0].slotted_relic == null)
	assert(battle.current_draft_selection.size() == 3)
	assert(battle.player_hp == before)
	assert(battle._guidance._ghost.texture != null)
	await battle._on_phase_one_relic_chosen(chosen)
	assert(battle.player_sockets[0].slotted_relic == chosen)
	assert(battle.turn_number == 2)
	assert(battle._guidance.target == battle._player_chrono.get_socket_view(2))
	await capture("next-hour-two")
	battle.player_hp = 10000
	battle.enemy_hp = 10000
	AudioManager.fast_mode = true
	for hour in range(2,10): await battle._on_phase_one_relic_chosen(battle.current_draft_selection[0])
	await get_tree().create_timer(0.6).timeout
	AudioManager.fast_mode = false
	assert(battle.phase == CombatController.Phase.QUADRANT)
	var reserve := battle.current_drawn_relic
	var previous := battle.player_sockets[1].slotted_relic
	battle._player_chrono.get_socket_view(2).previewed.emit(battle._player_chrono.get_socket_view(2))
	await capture("swap-preview")
	assert(battle.player_sockets[1].slotted_relic == previous)
	assert(battle.current_drawn_relic == reserve)
	assert(battle._guidance.target == battle._player_chrono.get_socket_view(2))
	battle._skip_button.mouse_entered.emit()
	assert(battle._phase_label.text.contains("KEEP YOUR CLOCK"))
	await capture("keep-preview")
	assert(battle._choice_overlay.visible)
	assert(battle._choice_overlay.replacements.get_child_count() == 3)
	battle._choice_overlay.replacements.get_child(1).pressed.emit()
	assert(not battle._choice_overlay.visible)
	while battle._resolving: await get_tree().process_frame
	assert(battle.player_sockets[1].slotted_relic == reserve)
	assert(battle.active_quadrant == 2)
	get_window().size = Vector2i(1280,720)
	await capture("guidance-720")
	print("BATTLE_GUIDANCE_OK: preview does not mutate state; hour 1 placement, hour 2 advance, reserve preview, replacement and sweep agree")
	get_tree().quit()

func capture(label: String) -> void:
	await get_tree().create_timer(0.9).timeout
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/battle-guidance")
	get_viewport().get_texture().get_image().save_png("res://artifacts/battle-guidance/"+label+".png")
