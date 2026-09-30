extends Node
## Structural interaction check for direct route selection, relic-object hit target,
## authored enemy art lookup, and dedicated cache-reveal screen.


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	AudioManager.reduced_motion = true
	RunManager.start_new_run([], [], 75, 19030)

	var map: Control = load("res://scenes/map_screen.tscn").instantiate()
	add_child(map)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(map._buttons.size() > 10, "The map must show the generated ascent route")
	assert(map._scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "Long routes must expose scrolling only when needed")
	var route_rows: Array[float] = []
	for point: Vector2 in map._positions.values():
		if not route_rows.has(point.y): route_rows.append(point.y)
	route_rows.sort()
	for row_index: int in range(1, route_rows.size()):
		assert(route_rows[row_index] - route_rows[row_index - 1] >= 150.0, "Map layers need clear vertical breathing room")
	for node_button: Button in map._buttons.values():
		var icon: TextureRect = node_button.get_node("CenteredNodeIcon")
		assert(icon.texture is AtlasTexture, "Map symbols must trim their transparent margins")
		assert(icon.get_global_rect().get_center().distance_to(node_button.get_global_rect().get_center()) < 0.1, "Map artwork must be centered on its waypoint")
	for node_id: String in map._buttons:
		var actual_center: Vector2 = map._buttons[node_id].get_global_rect().get_center()
		var drawn_center: Vector2 = map._canvas.global_position + map._positions[node_id]
		assert(actual_center.distance_to(drawn_center) < 0.1, "Waypoint hit target and drawn circle differ: %s %s" % [actual_center, drawn_center])
	var header_buttons: Array[Node] = map.get_node("MapHeader").find_children("*", "Button", true, false)
	assert(header_buttons.size() == 2, "Map utilities should be limited to relics and pause")
	assert(map._header_stats.text.contains("VITALITY") and map._header_stats.text.contains("OVERKILL"), "The map header must show the live run resources")
	assert(map.get_global_rect().encloses(map._route_hint.get_global_rect()), "The route guidance must remain fully on-screen")
	await _capture_visual("map-direct-destination")
	assert(map.get_node_or_null("DestinationPreview") == null, "The map must not contain a destination confirmation panel")
	for node_id: String in map._reachable:
		var target: Button = map._buttons[node_id]
		assert(not target.disabled and target.focus_mode != Control.FOCUS_NONE, "Every reachable map path must be clearly actionable")
		assert(target.pressed.get_connections().size() > 0, "A reachable map path must route directly on selection")

	var relic_view: RelicPedestalView = load("res://scenes/relic_pedestal_view.tscn").instantiate()
	add_child(relic_view)
	var clock_relics: Array = ContentDatabase.all_clock_relics()
	relic_view.bind_relic(clock_relics[0] as ClockRelicData, "BIND TO 1 O’CLOCK")
	var chosen: Array[ClockRelicData] = []
	relic_view.selected.connect(func(relic: ClockRelicData) -> void: chosen.append(relic))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	relic_view._gui_input(click)
	assert(chosen.size() == 1, "Clicking the relic artwork must select it")
	relic_view.queue_free()

	var treasure_relics: Array = ContentDatabase.all_relics()
	assert(not treasure_relics.is_empty(), "Treasure test requires at least one passive relic")
	var recovered_relic: RelicData = treasure_relics[0] as RelicData
	var treasure: TreasureScreen = load("res://scenes/treasure_screen.tscn").instantiate()
	treasure.set_reward_context({"ok_gain": 25, "relic": recovered_relic})
	add_child(treasure)
	await get_tree().process_frame
	var revealed_art: TextureRect = treasure.get_node("TreasureRevealRelicArt")
	assert(revealed_art.texture != null, "The cache reveal must show the recovered relic object")
	assert(revealed_art.size.x >= 220.0, "The recovered relic must be a prominent object reveal")
	assert((treasure.get_node("TreasureRevealCurrencyAmount") as Label).text == "+25")
	assert((treasure.get_node("TreasureRevealRelicName") as Label).text == recovered_relic.display_name)
	await _capture_visual("treasure-reveal")

	var pause: Control = load("res://scenes/pause_menu.tscn").instantiate()
	add_child(pause)
	pause._on_abandon_pressed()
	var menu_panel: Control = pause.get_node("CenterContainer/Panel")
	assert(not menu_panel.visible, "Abandon consequences must not overlap the pause-menu choices")
	var dialog: ModalConfirmDialog = pause.get_child(pause.get_child_count() - 1) as ModalConfirmDialog
	assert(dialog != null and dialog.visible, "Abandon action must show the confirmation modal")
	await _capture_visual("abandon-confirmation")
	dialog._on_cancel()
	assert(menu_panel.visible, "Cancelling abandon must restore the menu")
	pause.queue_free()

	var final_enemy: EnemyData = ContentDatabase.get_enemy("final_boss")
	var stage := IllustratedStage.new()
	assert(stage._enemy_art_path(final_enemy.art_id).ends_with("final_boss_crystal_warden.png"), "Final boss must be distinct from the Executioner while preserving the crystalline visual direction")
	assert(stage._enemy_art_path(final_enemy.art_id) != stage._enemy_art_path("boneghoul_idle"))
	stage.free()
	var selected_id: String = map._reachable[0]
	var route_node: MapGenerator.MapNode = map._map_data.nodes[selected_id]
	route_node.type = MapGenerator.NodeType.REST
	# Keep this test harness alive while GameFlow completes the same screen swap
	# a real map click uses; the destination scene becomes current independently.
	get_tree().current_scene = null
	map._select_destination(route_node)
	assert(RunManager.current_node_id == selected_id, "Selecting a reachable path must commit and enter it immediately")
	var deadline: int = Time.get_ticks_msec() + 4000
	while GameFlow._transitioning and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert(not GameFlow._transitioning and get_tree().current_scene != null, "The selected destination screen must finish opening")
	print("MAP_UX_OK: direct waypoint routing, relic art selection, cache reward reveal, abandon confirmation, unique final enemy art")
	get_tree().quit()


func _capture_visual(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var folder: String = ProjectSettings.globalize_path("res://.test-artifacts/ui-polish-audit")
	DirAccess.make_dir_recursive_absolute(folder)
	get_viewport().get_texture().get_image().save_png(folder.path_join(label + ".png"))
