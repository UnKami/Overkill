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
	battle.start_combat([enemy])
	battle.player_hp = 80
	await capture("assembly-1080")
	AudioManager.text_size = "large"
	ScreenDesign.apply_text_size(battle)
	get_window().size = Vector2i(1280,720)
	await capture("assembly-large-720")
	battle._preview_allocation(battle._pedestal_row.get_child(0))
	await capture("forecast-large-720")
	assert(battle._phase_label.visible and battle._phase_label.text.contains("After resolution"))
	check_geometry()
	AudioManager.text_size = "normal"
	ScreenDesign.apply_text_size(battle)
	get_window().size = Vector2i(1920,1080)
	check_geometry()
	# Every live relic must fit; starter-only screenshots miss long effects.
	var sample: RelicPedestalView = battle._pedestal_row.get_child(0)
	for text_mode: String in ["normal","large"]:
		AudioManager.text_size = text_mode
		for relic: ClockRelicData in ContentDatabase.all_clock_relics():
			sample.bind_relic(relic,"BIND TO 1 O’CLOCK")
			await get_tree().process_frame
			print("TEXT_METRIC ",relic.id," ",text_mode," content=",sample._desc_label.get_content_height()," box=",sample._desc_label.size," font=",sample._desc_label.get_theme_font_size("normal_font_size"))
			assert(sample._desc_label.get_content_height() <= sample._desc_label.size.y,"Relic text clipped: " + relic.id)
			assert(sample._desc_label.get_global_rect().end.y <= sample._slot_button.global_position.y,"Description overlaps action: %s %s" % [sample._desc_label.get_global_rect(),sample._slot_button.get_global_rect()])
	AudioManager.text_size = "normal"
	var turn: int = battle.turn_number
	battle._choice_overlay.toggle_inspection()
	assert(not battle._choice_overlay.visible and battle._choice_overlay._battlefield_inspection.visible)
	assert(battle._choice_overlay._battlefield_inspection._player_clock.custom_minimum_size.x >= 500)
	assert(battle._choice_overlay._battlefield_inspection._enemy_clock.custom_minimum_size.x >= 500)
	assert(battle._choice_overlay._battlefield_inspection._player_details.text.contains("FULL CYCLE"))
	assert(battle._choice_overlay._battlefield_inspection._enemy_details.text.contains("ATTACK"))
	assert(battle.turn_number == turn and battle.current_draft_selection.size() == 3)
	await capture("inspect-battlefield")
	battle._choice_overlay.toggle_inspection()
	assert(battle._choice_overlay.visible)
	var view: RelicPedestalView = load("res://scenes/relic_pedestal_view.tscn").instantiate()
	battle.add_child(view)
	view.bind_relic(ContentDatabase.all_clock_relics()[0], "BIND TO 1 O’CLOCK")
	var selected_from_art: Array[ClockRelicData] = []
	view.selected.connect(func(relic: ClockRelicData) -> void: selected_from_art.append(relic))
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	view._gui_input(click)
	assert(selected_from_art.size() == 1, "Clicking a relic object must perform the same selection as its action button")
	view._slot_button.disabled = true
	view._gui_input(click)
	assert(selected_from_art.size() == 1, "Unavailable relic choices must not select from artwork")
	view.queue_free()
	assert(battle.turn_number == turn, "A detached interaction fixture must not alter the active battle")
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
	var choice_header: Control = battle._choice_overlay._heading.get_parent() as Control
	assert(battle._skip_button.get_parent() == choice_header and battle._skip_button.visible, "Keep-and-sweep must be a prominent, separate alternative to replacement")
	assert(battle._skip_button.text.contains("DISCARD DRAWN") and choice_header.get_global_rect().encloses(battle._skip_button.get_global_rect()), "Skip copy and header placement must make the consequence clear")
	for relic_button: Button in battle._choice_overlay.replacements.get_children():
		assert(relic_button.find_child("EssenceSunburst", true, false) != null, "Replacement relics use their dedicated color-pair artwork")
		assert(relic_button.find_child("RelicLightStrokes", true, false) == null, "Deprecated strokes are removed from replacements")
	var before: Vector2 = battle._choice_overlay.position
	battle._preview_swap(battle._player_chrono.get_socket_view(2))
	await get_tree().process_frame
	assert(battle._choice_overlay.position.is_equal_approx(before), "Preview must not move the controls")
	battle._refresh_guidance()
	AudioManager.text_size = "large"
	ScreenDesign.apply_text_size(battle)
	get_window().size = Vector2i(1280, 720)
	await capture("replacement-large-720")
	battle._preview_swap(battle._player_chrono.get_socket_view(2))
	await capture("replacement-forecast-720")
	check_geometry()
	for relic: ClockRelicData in ContentDatabase.all_clock_relics():
		battle.player_sockets[0].slotted_relic = relic
		battle._choice_overlay.present(battle)
		await get_tree().process_frame
		var target: Button = battle._choice_overlay.replacements.get_child(0)
		for child: Control in target.get_child(0).get_children():
			assert(target.get_global_rect().encloses(child.get_global_rect()),"Replacement overflow: " + relic.id)
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
	# The offer keeps its cinematic page and adds distinct contextual scenery to
	# each title/action choice.
	battle.queue_free()
	await get_tree().process_frame
	get_window().size = Vector2i(1920, 1080)
	var offer: PreBattleOfferScreen = load("res://scenes/pre_battle_offer.tscn").instantiate()
	add_child(offer)
	await capture("pre-battle-offer")
	assert(offer._cards.size() == 3)
	var backdrop_paths: Array[String] = []
	for card: PanelContainer in offer._cards:
		var card_art: Array[Node] = card.find_children("*", "TextureRect", true, false)
		assert(card_art.size() == 1, "Each offer needs one contextual scenic backdrop")
		assert(card_art[0].texture != null, "Each offer backdrop must resolve to real art")
		backdrop_paths.append((card_art[0].texture as Texture2D).resource_path)
		assert(not card.find_children("*", "Button", true, false).is_empty(), "Each offer keeps a clear action")
		assert(not card.find_children("*", "Label", true, false).is_empty(), "Each offer keeps its title")
	assert(backdrop_paths[0] != backdrop_paths[1] and backdrop_paths[1] != backdrop_paths[2], "Upgrade, Overkill and vitality need distinct contextual scenes")
	offer.queue_free()
	AudioManager.text_size = "normal"
	print("PRESENTATION_014_OK: horizontal choices, safe bounds, readable telemetry, stable preview, inspection, explicit commit, locked slots, empty reserve, 720p large text and ultrawide")
	get_tree().quit()

func check_geometry() -> void:
	var panel: Rect2 = battle._choice_overlay.get_global_rect()
	assert(Rect2(Vector2.ZERO, battle.size).encloses(panel), "Overlay must fit viewport")
	assert(panel.position.y == 52 and panel.end.y < battle.size.y, "Choices must fit the viewport")
	assert(battle._choice_overlay.get_theme_stylebox("panel") is StyleBoxEmpty)
	for stats: Label in [battle._player_stats_label, battle._enemy_stats_label]:
		assert(not panel.intersects(stats.get_global_rect()), "Health and Block must stay visible")
	for strip: HBoxContainer in [battle._player_core_strip, battle._enemy_core_strip, battle._player_status_strip, battle._enemy_status_strip]:
		assert(strip.visible, "Combatant stat values must remain visible after relocation")
		var status_panel: Panel = (strip.get_parent() as Control).get_node("CharacterStatusPanel")
		assert(status_panel.get_global_rect().encloses(strip.get_global_rect()), "Stat strip must fit inside its owner's lower status area")
	assert(battle._player_core_strip.get_child_count() >= 2 and battle._enemy_core_strip.get_child_count() >= 2, "Vitality and Block values must remain visible")
	assert(is_equal_approx(battle._stage.player.target_height, 360.0) and is_equal_approx(battle._stage.enemy.target_height, 360.0), "Combatant artwork is enlarged by 20 percent")
	var previous: Control = null
	for choice: Control in battle._pedestal_row.get_children():
		assert(panel.encloses(choice.get_global_rect()))
		assert(not choice._art_glow.visible, "Relic objects must not have a foggy radial panel")
		assert(choice.get_node("CardPanel/Margin/VBox/ArtFrame").find_child("RelicLightStrokes", true, false) == null, "Retired procedural rays must not stack over dedicated essence sunbursts")
		assert(choice._slot_button.size.y >= 48)
		assert(choice._art_rect.size.y >= choice.size.y * 0.5, "Relic object art must own at least half the card")
		assert(choice._desc_label.get_theme_font_size("normal_font_size") >= 20)
		assert(choice.get_global_rect().encloses(choice._slot_button.get_global_rect()), "Bind button stays inside option")
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
	var folder: String = ProjectSettings.globalize_path("res://.test-artifacts/ui-polish-audit")
	DirAccess.make_dir_recursive_absolute(folder)
	get_viewport().get_texture().get_image().save_png(folder.path_join(label + ".png"))
