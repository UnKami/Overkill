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
	get_window().size = Vector2i(1280,720)
	await capture("map-720")
	get_window().size = Vector2i(1920,1080)
	GameFlow.open_pause_menu()
	await capture("pause")
	GameFlow.close_pause_menu()
	ModalConfirmDialog.show_dialog(GameFlow._overlay_layer, "Abandon this run? Your current path, bound relics, cards, and unbanked Overkill will be lost. This cannot be undone.", "ABANDON RUN", _noop, true)
	await capture("confirm-danger")
	GameFlow._overlay_layer.get_child(GameFlow._overlay_layer.get_child_count() - 1).queue_free()
	await get_tree().process_frame
	GameFlow.open_deck_view(GameFlow.DeckViewMode.REFERENCE)
	await capture("reliquary-overlay")
	GameFlow.close_deck_view()
	GameFlow.open_deck_view(GameFlow.DeckViewMode.UPGRADE)
	await capture("tempering-overlay")
	get_window().size = Vector2i(1280,720)
	await capture("tempering-overlay-720")
	get_window().size = Vector2i(1920,1080)
	var first_relic_uid: int = int(RunManager.clock_inventory[0].get("uid", -1))
	GameFlow._active_deck_view_overlay._choose(first_relic_uid)
	await capture("tempering-preview")
	GameFlow._active_deck_view_overlay.get_child(GameFlow._active_deck_view_overlay.get_child_count() - 1).queue_free()
	await get_tree().process_frame
	GameFlow.close_deck_view()
	GameFlow.open_settings()
	await capture("settings")
	GameFlow._active_settings_overlay._text_size_option.select(1)
	GameFlow._active_settings_overlay._text_size_option.item_selected.emit(1)
	await capture("settings-large")
	get_window().size = Vector2i(1280,720)
	await capture("settings-large-720")
	get_window().size = Vector2i(1920,1080)
	assert(GameFlow._active_settings_overlay.get_theme_font_size("font_size","Button") == 25)
	AudioManager.set_text_size("normal")
	GameFlow.close_settings()
	GameFlow.goto_rest_site()
	await capture("rest")
	var rest_tutorial: TutorialCalloutView = get_tree().current_scene.find_child("TutorialCalloutView", true, false) as TutorialCalloutView
	rest_tutorial._on_requested("first_rest_upgrade", TutorialCallout.CATALOG["first_rest_upgrade"])
	await capture("rest-tempering-callout")
	rest_tutorial.dismiss_now()
	await get_tree().create_timer(0.22).timeout
	GameFlow.goto_shop()
	await capture("shop")
	get_window().size = Vector2i(1280,720)
	await capture("shop-720")
	get_window().size = Vector2i(1920,1080)
	GameFlow.goto_event(EventCatalog.get_all_events()[0])
	await capture("event")
	GameFlow.goto_reward_screen({"enemy_data":ContentDatabase.get_enemy("boneghoul")})
	await capture("reward")
	GameFlow.goto_run_summary(true)
	await capture("victory")
	GameFlow.goto_run_summary(false)
	await capture("defeat")
	GameFlow.goto_act_transition(CinematicArt.transition_background(1), "ACT II — THE FOUNDRY", Callable())
	await capture("act-transition")
	GameFlow._on_excess_threshold_crossed(25)
	await capture("excess-unlock")
	GameFlow._overlay_layer.get_child(GameFlow._overlay_layer.get_child_count() - 1).queue_free()
	await get_tree().process_frame
	GameFlow.goto_title()
	await capture("continue")
	assert(get_tree().current_scene._continue_button.visible)
	get_tree().current_scene._new_run_button.pressed.emit()
	assert(get_tree().current_scene._replace_confirmation.visible)
	await capture("replace-confirmation")
	get_tree().current_scene._replace_confirmation.hide()
	get_tree().current_scene._continue_button.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	assert(get_tree().current_scene.name == "MapScreen")
	print("FRONTEND_FLOW_OK: title, character, map, responsive layouts, pause, confirmation, collection and tempering overlays, settings, rest, shop, event, reward, outcomes, transitions, excess milestone, continue, replacement confirmation")
	get_tree().quit()

func capture(label: String) -> void:
	await get_tree().create_timer(1.5).timeout
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/frontend")
	get_viewport().get_texture().get_image().save_png("res://artifacts/frontend/"+label+".png")


func _noop() -> void:
	pass
