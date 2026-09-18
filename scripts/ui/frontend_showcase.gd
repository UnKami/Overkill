extends Node
func _ready() -> void:
	await get_tree().process_frame
	get_tree().current_scene = null
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920,1080)
	AudioManager.set_master_volume(0)
	AudioManager.text_size = "normal"
	SaveManager.delete_run_save()
	GameFlow.goto_title()
	await capture("title")
	get_tree().current_scene._new_run_button.pressed.emit()
	await capture("character")
	assert(get_tree().current_scene.name == "ClassSelectScreen")
	get_window().size = Vector2i(1280,720)
	await capture("character-720")
	get_window().size = Vector2i(1920,1080)
	get_tree().current_scene._start_button.pressed.emit()
	await capture("map")
	assert(RunManager.clock_inventory.size() == 12)
	assert(RunManager.current_hp == 75)
	GameFlow.open_settings()
	await capture("settings")
	GameFlow._active_settings_overlay._text_size_option.select(1)
	GameFlow._active_settings_overlay._text_size_option.item_selected.emit(1)
	await capture("settings-large")
	assert(GameFlow._active_settings_overlay.get_theme_font_size("font_size","Button") == 25)
	AudioManager.set_text_size("normal")
	GameFlow.close_settings()
	GameFlow.goto_rest_site()
	await capture("rest")
	GameFlow.goto_shop()
	await capture("shop")
	GameFlow.goto_event(EventCatalog.get_all_events()[0])
	await capture("event")
	GameFlow.goto_reward_screen({"enemy_data":ContentDatabase.get_enemy("boneghoul")})
	await capture("reward")
	GameFlow.goto_run_summary(true)
	await capture("victory")
	GameFlow.goto_run_summary(false)
	await capture("defeat")
	GameFlow.goto_title()
	await capture("continue")
	assert(get_tree().current_scene._continue_button.visible)
	get_tree().current_scene._new_run_button.pressed.emit()
	assert(get_tree().current_scene._replace_confirmation.visible)
	get_tree().current_scene._replace_confirmation.hide()
	get_tree().current_scene._continue_button.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	assert(get_tree().current_scene.name == "MapScreen")
	var map: Control = get_tree().current_scene
	map._buttons[map._reachable[0]].pressed.emit()
	await get_tree().create_timer(0.8).timeout
	assert(get_tree().current_scene is CombatController)
	var battle: CombatController = get_tree().current_scene
	await battle._on_phase_one_relic_chosen(battle.current_draft_selection[0])
	assert(battle.turn_number == 2)
	print("FRONTEND_FLOW_OK: title, character, 12 relics, 75 HP, settings, rest, shop, continue, replacement confirmation")
	get_tree().quit()

func capture(label: String) -> void:
	await get_tree().create_timer(1.5).timeout
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/frontend")
	get_viewport().get_texture().get_image().save_png("res://artifacts/frontend/"+label+".png")
