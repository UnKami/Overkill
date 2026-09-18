extends Node
## Visual and behavior regression checks for the release presentation.
var battle: CombatController

func _ready() -> void:
	AudioManager.set_master_volume(0)
	RunManager.start_new_run([], [], 80, 314)
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy: EnemyData = ContentDatabase.get_enemy("act1_boss").duplicate()
	enemy.max_hp = 10000
	battle.start_combat([enemy])
	battle.player_hp = 80
	await capture("assembly-1080")
	check_geometry()
	var turn: int = battle.turn_number
	battle._choice_overlay.toggle_inspection()
	assert(not battle._choice_overlay.visible and battle._choice_overlay._resume.visible)
	assert(battle.turn_number == turn and battle.current_draft_selection.size() == 3)
	await capture("inspect-battlefield")
	battle._choice_overlay.toggle_inspection()
	assert(battle._choice_overlay.visible)
	var view: RelicPedestalView = battle._pedestal_row.get_child(0)
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	view._gui_input(click)
	assert(battle.turn_number == turn, "Clicking artwork must not commit")
	# A legal, filled quadrant fixture isolates layout from combat balance.
	battle.current_draft_selection.clear()
	for hour: int in range(1, 10):
		battle.player_sockets[hour - 1].slotted_relic = ContentDatabase.get_clock_relic("REL-01" if hour % 2 else "REL-04").duplicate()
	battle._player_chrono.bind_sockets(battle.player_sockets)
	battle.phase = CombatController.Phase.QUADRANT
	battle.active_quadrant = 1
	battle.turn_number = 10
	battle._prompt_phase_two_turn()
	await capture("replacement-1080")
	check_geometry()
	var before: Vector2 = battle._choice_overlay.position
	battle._preview_swap(battle._player_chrono.get_socket_view(2))
	await get_tree().process_frame
	assert(battle._choice_overlay.position.is_equal_approx(before), "Preview must not move the controls")
	battle._refresh_guidance()
	AudioManager.text_size = "large"
	ScreenDesign.apply_text_size(battle)
	get_window().size = Vector2i(1280, 720)
	await capture("replacement-large-720")
	check_geometry()
	battle.player_sockets[0].is_locked = true
	battle._choice_overlay.present(battle)
	assert(battle._choice_overlay.replacements.get_child(0).disabled)
	battle.player_deck.clear()
	battle.player_discard.clear()
	battle._prompt_phase_two_turn()
	await capture("no-reserve")
	for button: Button in battle._choice_overlay.replacements.get_children(): assert(button.disabled)
	assert(not battle._skip_button.disabled)
	get_window().size = Vector2i(2560, 1080)
	await capture("ultrawide")
	check_geometry()
	AudioManager.text_size = "normal"
	print("PRESENTATION_014_OK: horizontal choices, safe bounds, readable telemetry, stable preview, inspection, explicit commit, locked slots, empty reserve, 720p large text and ultrawide")
	get_tree().quit()

func check_geometry() -> void:
	var panel: Rect2 = battle._choice_overlay.get_global_rect()
	assert(Rect2(Vector2.ZERO, battle.size).encloses(panel), "Overlay must fit viewport")
	for stats: Label in [battle._player_stats_label, battle._enemy_stats_label]:
		assert(not panel.intersects(stats.get_global_rect()), "Health and Block must stay visible")
	var previous: Control = null
	for choice: Control in battle._pedestal_row.get_children():
		assert(panel.encloses(choice.get_global_rect()))
		if previous != null:
			assert(is_equal_approx(previous.global_position.y, choice.global_position.y))
			assert(previous.get_global_rect().end.x <= choice.global_position.x)
		previous = choice
	for target: Control in battle._choice_overlay.replacements.get_children():
		assert(panel.encloses(target.get_global_rect()))

func capture(label: String) -> void:
	await get_tree().create_timer(0.7).timeout
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/presentation-014")
	get_viewport().get_texture().get_image().save_png("res://artifacts/presentation-014/" + label + ".png")
