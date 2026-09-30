extends Node
## Isolated rendered acceptance fixture. No player save or live run is touched.
var _current: Node

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	AudioManager.set_master_volume(0.0)
	AudioManager.reduced_motion = true
	RunManager.start_new_run([], [], 75, 19031)
	var relic_view: RelicPedestalView = load("res://scenes/relic_pedestal_view.tscn").instantiate()
	await _show(relic_view)
	var tested_sunbursts: Dictionary = {}
	for relic: ClockRelicData in ContentDatabase.all_clock_relics(true):
		var sunburst_path: String = RelicPedestalView.essence_sunburst_path(relic)
		assert(not sunburst_path.is_empty() and ResourceLoader.exists(sunburst_path), "Missing essence sunburst for %s" % relic.affinity_name())
		relic_view.bind_relic(relic)
		var sunburst: TextureRect = relic_view.get_node("CardPanel/Margin/VBox/ArtFrame/EssenceSunburst") as TextureRect
		assert(sunburst.visible and sunburst.texture != null and sunburst.texture.resource_path == sunburst_path, "Selection art must match %s" % relic.affinity_name())
		assert(sunburst.texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Essence sunburst must preserve transparency")
		tested_sunbursts[sunburst_path] = true
	assert(tested_sunbursts.size() == 15, "All five single essences and ten dual pairings must have distinct halos")
	await _capture("relic-sunbursts")
	for scene_name: String in ["title_screen", "class_select_screen", "pre_battle_offer", "rest_site_screen", "reward_screen"]:
		var screen: Control = load("res://scenes/%s.tscn" % scene_name).instantiate()
		await _show(screen)
		if scene_name == "title_screen":
			var confirmation: ModalConfirmDialog = screen.get("_replace_confirmation") as ModalConfirmDialog
			var menu_column: Control = screen.get("_menu_column") as Control
			var center: CenterContainer = confirmation.get_node("CenterContainer")
			assert(is_equal_approx(center.anchor_left, 0.075) and is_equal_approx(center.anchor_right, 0.38), "Title confirmation must align to the established content column")
			menu_column.hide()
			confirmation.show()
			assert(not menu_column.visible and confirmation.visible, "Confirmation must fully replace, not overlap, menu choices")
			screen.call("_on_confirmation_cancelled")
			assert(menu_column.visible and not confirmation.visible, "Cancel must restore the title choices")
		await _capture(scene_name)
	for mode: String in ["shop", "collection", "upgrade"]:
		var inventory := preload("res://scripts/ui/clock_collection_screen.gd").new()
		inventory.mode = mode
		await _show(inventory)
		await _capture(mode)
	for event: EventData in EventCatalog.get_all_events():
		var event_screen: Control = load("res://scenes/event_screen.tscn").instantiate()
		event_screen.set_event(event)
		await _show(event_screen)
		await _capture(event.id)
	for act: int in range(1, 4):
		RunManager.act_number = act
		await _show(load("res://scenes/map_screen.tscn").instantiate())
		await _capture("map-act-%d" % act)
		var transition: Control = load("res://scenes/act_transition_screen.tscn").instantiate()
		transition.configure(CinematicArt.transition_background(act), ["THE LUMINOUS REFINERY", "THE FRACTURED HORIZON", "THE FINAL CONVERGENCE"][act - 1], Callable())
		await _show(transition)
		await _capture("transition-%d" % act)
	for won: bool in [true, false]:
		var summary: Control = load("res://scenes/run_summary_screen.tscn").instantiate()
		summary.set_outcome(won)
		await _show(summary)
		await _capture("victory" if won else "defeat")
	for enemy_id: String in ["boneghoul", "act1_elite", "act1_boss", "act2_trash", "act2_elite", "act2_boss", "act3_trash", "act3_elite", "act3_boss", "final_boss"]:
		RunManager.act_number = 1 if enemy_id == "boneghoul" or enemy_id.begins_with("act1") else (2 if enemy_id.begins_with("act2") else 3)
		var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
		await _show(battle)
		var enemy: EnemyData = ContentDatabase.get_enemy(enemy_id)
		assert(enemy != null)
		battle.start_combat([enemy])
		await get_tree().create_timer(0.6).timeout
		var stage: IllustratedStage = battle._stage
		assert(battle._player_portrait.texture == null and battle._enemy_portrait.texture == null, "Telemetry must not draw a second duplicate combatant")
		for pair: Array in [[stage.player, battle._player_stats_label], [stage.enemy, battle._enemy_stats_label]]:
			var actor: IllustratedActor = pair[0]
			var stats: Label = pair[1]
			var art_rect: Rect2 = actor._front.get_global_rect()
			assert(art_rect.position.y > battle._choice_overlay.get_global_rect().end.y, "Fighters must not overlap the choices")
			assert(absf(actor.global_position.x + actor.size.x * 0.5 - stats.get_global_rect().get_center().x) < 1.0, "HP centered below its combatant")
			assert(art_rect.end.y < stats.global_position.y, "HP below combatant artwork")
		await _capture(enemy_id)
	if is_instance_valid(_current):
		_current.queue_free()
	await get_tree().process_frame
	print("CRYSTALLINE_VISUAL_OK: production screens, three maps/transitions and all ten enemies rendered")
	get_tree().quit()

func _show(node: Node) -> void:
	if is_instance_valid(_current):
		_current.queue_free()
		await get_tree().process_frame
	_current = node
	add_child(node)
	await get_tree().create_timer(0.45).timeout

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://crystalline-031")
	get_viewport().get_texture().get_image().save_png("user://crystalline-031/%s.png" % label)

