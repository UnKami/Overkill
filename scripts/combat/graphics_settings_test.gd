extends Node

func _ready() -> void:
	AudioManager.set_master_volume(0)
	AudioManager.set_render_quality("high")
	get_window().size = Vector2i(1920,1080)
	RunManager.start_new_run([],[],80,1729)
	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("act1_boss")])
	await get_tree().create_timer(1.0).timeout
	var stage: DirectedArena = battle._stage
	var clock_rect: Rect2 = battle._player_chrono.get_global_rect()
	GameFlow.open_settings()
	var settings: Control = GameFlow._active_settings_overlay
	var option: OptionButton = settings.get_node("CenterContainer/Panel/Margin/VBox/GraphicsQuality/QualityOption")
	var modes: Array[String] = ["high","balanced","performance"]
	var widths: Array[int] = [1600,1280,960]
	for index: int in 3:
		option.select(index)
		option.item_selected.emit(index)
		await get_tree().process_frame
		assert(AudioManager.render_quality == modes[index])
		assert(stage._view.size.x == widths[index], "Preset must update the existing 3D viewport immediately")
		assert(battle._player_chrono.get_global_rect() == clock_rect, "3D quality must not resize interface elements")
		AudioManager.render_quality = "temporary"
		AudioManager.load_settings()
		assert(AudioManager.render_quality == modes[index], "Graphics choice must survive settings reload")
		print("GRAPHICS_PRESET_OK ",modes[index]," width=",stage._view.size.x)
	get_window().size = Vector2i(1280,720)
	await get_tree().create_timer(0.3).timeout
	var panel: Control = settings.get_node("CenterContainer/Panel")
	assert(settings.get_viewport_rect().encloses(panel.get_global_rect()), "Settings must fit the supported compact viewport")
	await capture("settings-720")
	var text_option: OptionButton = settings.get_node("CenterContainer/Panel/Margin/VBox/TextSizeOption")
	text_option.select(1)
	text_option.item_selected.emit(1)
	await get_tree().create_timer(0.3).timeout
	assert(settings.get_viewport_rect().encloses(panel.get_global_rect()), "Large-text settings must fit at 720p")
	await capture("settings-large-720")
	GameFlow.close_settings()
	await get_tree().process_frame
	await capture("performance-720")
	AudioManager.set_render_quality("invalid")
	assert(AudioManager.render_quality == "high")
	assert(stage._view.size.x == 1280)
	AudioManager.load_settings()
	assert(AudioManager.render_quality == "high")
	print("GRAPHICS_SETTINGS_OK: live presets, persistence, fallback, unchanged UI and compact settings fit")
	get_tree().quit()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://graphics-030")
	get_viewport().get_texture().get_image().save_png("user://graphics-030/"+label+".png")
