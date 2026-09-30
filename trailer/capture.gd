extends Node
## Deterministic art and gameplay capture for the dated trailer. This fixture
## never changes player saves; use an isolated Godot APPDATA profile.

var _current: Node


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	AudioManager.set_master_volume(0.0)
	AudioManager.reduced_motion = false
	RunManager.start_new_run([], [], 500, 300926)
	await _show(load("res://scenes/title_screen.tscn").instantiate(), "title", 2.5)
	await _show(load("res://scenes/class_select_screen.tscn").instantiate(), "class", 2.0)
	await _show(load("res://scenes/map_screen.tscn").instantiate(), "map", 2.0)
	await _show(load("res://scenes/pre_battle_offer.tscn").instantiate(), "prebattle", 1.6)

	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	await _install(battle, "battle-entry")
	var enemy: EnemyData = ContentDatabase.get_enemy("act1_boss").duplicate()
	battle.prepare_combat([enemy])
	battle.begin_combat_intro()
	await _hold(3.5)
	var battle_tutorial: TutorialCalloutView = battle.get_node("TutorialCalloutView") as TutorialCalloutView
	battle_tutorial.dismiss_now()
	await _hold(0.25)
	await _still("battle-ready")
	await _hold(1.7)
	battle._choice_overlay.hide()
	battle._resolving = true
	battle.enemy_hp = 9
	OKRunState.unlocked_excess_thresholds.assign([20, 35, 60, 90])
	var socket := ClockSocketData.new()
	socket.hour_index = 1
	socket.slotted_relic = ContentDatabase.get_clock_relic("REL-03")
	_mark("overkill-hit")
	battle._apply_damage_to_enemy(39, socket)
	await _hold(2.1)
	await _still("overkill-hit")
	GameFlow._on_excess_threshold_crossed(20)
	_mark("excess-awakened")
	await _hold(1.1)
	await _still("excess-awakened")
	for child: Node in GameFlow._overlay_layer.get_children():
		child.queue_free()
	await get_tree().process_frame

	var collection := preload("res://scripts/ui/clock_collection_screen.gd").new()
	collection.mode = "collection"
	await _show(collection, "reliquary", 1.6)
	OKRunState.current_ok = 90
	var shop := preload("res://scripts/ui/clock_collection_screen.gd").new()
	shop.mode = "shop"
	await _show(shop, "shop", 1.8)
	await _show(load("res://scenes/rest_site_screen.tscn").instantiate(), "rest", 1.5)
	var event_screen: Control = load("res://scenes/event_screen.tscn").instantiate() as Control
	event_screen.call("set_event", EventCatalog.get_all_events()[0])
	await _show(event_screen, "event", 1.5)
	var reward: Control = load("res://scenes/reward_screen.tscn").instantiate() as Control
	reward.call("set_reward_context", {"enemy_data": ContentDatabase.get_enemy("boneghoul")})
	await _show(reward, "relic-reward", 1.5)

	var altar: BossOverkillAltar = load("res://scenes/boss_overkill_altar.tscn").instantiate()
	altar.set_boss_context(ContentDatabase.get_enemy("act1_boss"))
	await _show(altar, "boss-altar", 3.3)
	altar._open_purchase("REL-28")
	altar._replacement_select.select(1)
	_mark("altar-confirm")
	await _hold(1.4)
	await _still("altar-confirm")
	altar._confirm_purchase()
	_mark("altar-bound")
	await _hold(1.8)
	await _still("altar-bound")

	var transition: Control = load("res://scenes/act_transition_screen.tscn").instantiate() as Control
	transition.call("configure", CinematicArt.transition_background(1), "ACT II — THE FOUNDRY", Callable())
	await _show(transition, "act-transition", 1.8)
	var final_battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	await _install(final_battle, "final-boss")
	final_battle.prepare_combat([ContentDatabase.get_enemy("final_boss")])
	final_battle.begin_combat_intro()
	await _hold(4.0)
	var final_tutorial: TutorialCalloutView = final_battle.get_node("TutorialCalloutView") as TutorialCalloutView
	final_tutorial.dismiss_now()
	await _hold(0.2)
	await _still("final-boss")
	var victory: Control = load("res://scenes/run_summary_screen.tscn").instantiate() as Control
	victory.call("set_outcome", true)
	await _show(victory, "victory", 2.3)
	print("TRAILER_CAPTURE_OK")
	get_tree().quit()


func _install(node: Node, label: String) -> void:
	if is_instance_valid(_current):
		_current.queue_free()
		await get_tree().process_frame
	_current = node
	add_child(node)
	_mark(label)
	await _hold(0.30)


func _show(node: Node, label: String, seconds: float) -> void:
	await _install(node, label)
	await _still(label)
	await _hold(seconds)


func _hold(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _still(label: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://trailer/captures")
	get_viewport().get_texture().get_image().save_png("res://trailer/captures/%s.png" % label)


func _mark(label: String) -> void:
	print("TRAILER_SHOT %s frame %d" % [label, Engine.get_frames_drawn()])
