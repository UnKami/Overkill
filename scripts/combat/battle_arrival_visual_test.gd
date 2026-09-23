extends Node
## Rendered review fixture for the presentation pass. It captures the exact
## screens and choreography moments that structural assertions cannot judge.

var _current: Node


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	AudioManager.set_master_volume(0.0)
	AudioManager.fast_mode = false
	AudioManager.reduced_motion = false
	var strike: CardData = ContentDatabase.get_card("strike")
	RunManager.start_new_run([strike, strike], [], 75, 923)

	await _show(load("res://scenes/class_select_screen.tscn").instantiate())
	await _capture("class-select-1080")
	var transition_layer := CanvasLayer.new()
	transition_layer.layer = 100
	add_child(transition_layer)
	var transition := ScreenTransition.new()
	transition.theme = ScreenDesign.build_theme()
	transition_layer.add_child(transition)
	transition.play_cover("BATTLE")
	await get_tree().create_timer(0.30).timeout
	await _capture("screen-vortex-mid")
	await get_tree().create_timer(0.24).timeout
	await transition.play_reveal()
	transition_layer.queue_free()

	var collection := preload("res://scripts/ui/clock_collection_screen.gd").new()
	collection.mode = "collection"
	await _show(collection)
	await _capture("relic-collection-1080")

	await _show(load("res://scenes/pre_battle_offer.tscn").instantiate())
	await _capture("pre-battle-offer-1080")
	get_window().size = Vector2i(1280, 720)
	await get_tree().create_timer(0.25).timeout
	await _capture("pre-battle-offer-720")
	get_window().size = Vector2i(2560, 1080)
	await get_tree().create_timer(0.25).timeout
	await _capture("pre-battle-offer-ultrawide")

	get_window().size = Vector2i(1920, 1080)
	var selector: CardUpgradeSelection = load("res://scenes/card_upgrade_selection.tscn").instantiate()
	await _show(selector)
	await _capture("card-upgrade-selection")
	var selected: CardView = selector._views[0]
	var selected_card: CardData = selected.get_card()
	selector._select(selected_card, selected, selected_card)
	await get_tree().create_timer(0.62).timeout
	await _capture("card-upgrade-complete")

	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	await _show(battle)
	var enemy := EnemyData.new()
	enemy.id = "boneghoul"
	enemy.display_name = "The Hollow Warden"
	enemy.max_hp = 200
	battle.prepare_combat([enemy])
	battle.begin_combat_intro()
	await get_tree().create_timer(0.22).timeout
	await _capture("battle-start-title")
	await get_tree().create_timer(0.78).timeout
	await _capture("battle-player-reveal")
	await get_tree().create_timer(0.80).timeout
	await _capture("battle-ready-1080")
	get_window().size = Vector2i(1280, 720)
	await get_tree().create_timer(0.25).timeout
	await _capture("battle-ready-720")

	get_window().size = Vector2i(1920, 1080)
	await get_tree().create_timer(0.20).timeout
	battle._choice_overlay.hide()
	battle._resolving = true
	var hammer_socket := ClockSocketData.new()
	hammer_socket.hour_index = 1
	hammer_socket.slotted_relic = ContentDatabase.get_clock_relic("REL-03")
	battle._apply_damage_to_enemy(14, hammer_socket)
	await get_tree().create_timer(0.12).timeout
	await _capture("heavy-hammer-windup")
	await get_tree().create_timer(0.16).timeout
	await _capture("heavy-hammer-flight")
	await get_tree().create_timer(0.15).timeout
	await _capture("heavy-hammer-impact")
	print("BATTLE_ARRIVAL_VISUAL_OK")
	get_tree().quit()


func _show(node: Node) -> void:
	if is_instance_valid(_current):
		_current.queue_free()
		await get_tree().process_frame
	_current = node
	add_child(node)
	await get_tree().create_timer(0.30).timeout


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://battle-arrival-visual")
	get_viewport().get_texture().get_image().save_png("user://battle-arrival-visual/%s.png" % label)
