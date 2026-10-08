extends Node
## Opens the real battle controller with a disposable preview run.
var battle: CombatController
var qa: bool = false

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1440,810)
	AudioManager.fast_mode = false
	AudioManager.reduced_motion = false
	qa = OS.get_cmdline_user_args().has("--qa")
	var strike: CardData = ContentDatabase.get_card("strike")
	RunManager.start_new_run([strike, strike], [], 75, 923)
	battle = load("res://scenes/combat_scene.tscn").instantiate() as CombatController
	add_child(battle)
	var enemy: EnemyData = ContentDatabase.get_enemy("boneghoul").duplicate() as EnemyData
	battle.prepare_combat([enemy])
	battle.begin_combat_intro()
	battle.combat_won.connect(func(_enemies: Array[EnemyData]) -> void: _finished("VICTORY"))
	battle.combat_lost.connect(func() -> void: _finished("DEFEAT"))
	if qa: _verify()
	else:
		print("MESHY_PLAYABLE_BATTLE_READY")
		var layer: CanvasLayer = CanvasLayer.new()
		layer.layer = 120
		add_child(layer)
		var button: Button = Button.new()
		button.text = "Restart battle preview"
		button.position = Vector2(1570, 16)
		button.pressed.connect(func() -> void: get_tree().reload_current_scene())
		layer.add_child(button)

func _finished(result: String) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 130
	add_child(layer)
	var panel: CenterContainer = CenterContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(panel)
	var replay: Button = Button.new()
	replay.text = result + "  /  Play again"
	replay.custom_minimum_size = Vector2(420, 80)
	replay.pressed.connect(func() -> void: get_tree().reload_current_scene())
	panel.add_child(replay)
	print("MESHY_BATTLE_FINISHED ", result)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://meshy-battle")
	get_viewport().get_texture().get_image().save_png("user://meshy-battle/" + label + ".png")

func _verify() -> void:
	await get_tree().create_timer(1.9).timeout
	await _capture("01-perch")
	await get_tree().create_timer(1.0).timeout
	await _capture("02-drop")
	await get_tree().create_timer(2.8).timeout
	while is_instance_valid(battle._battle_intro): await get_tree().process_frame
	assert(not battle._stage.player._busy, "Entrance must finish before player choices")
	var actor: IllustratedActor = battle._stage.player
	assert(actor.get("skeleton").get_bone_count() == 23)
	assert(actor.call("_bone", "RightHand") >= 0)
	assert(actor.call("_bone", "LeftHand") >= 0)
	var hand_point: Vector2 = actor.call("anchor_position", "hand")
	var feet_point: Vector2 = actor.call("anchor_position", "feet")
	assert(hand_point.y < feet_point.y - 40.0, "Relic anchors must follow actual hands")
	await _capture("03-choices")
	var tutorial: Node = battle.get_node_or_null("TutorialCalloutView")
	if tutorial != null: tutorial.dismiss_now()
	battle._choice_overlay.hide()
	await get_tree().create_timer(.4).timeout
	await _capture("04-battlefield")
	# Controlled QA offer; the interactive preview keeps the real random draft.
	var chosen_guard: ClockRelicData = ContentDatabase.get_clock_relic("REL-04")
	battle.current_draft_selection.assign([chosen_guard])
	var hp_before: int = battle.player_hp
	var expected_block: int = maxi(0, chosen_guard.base_block - battle.enemy_sockets[0].intent_damage)
	await battle._on_phase_one_relic_chosen(chosen_guard)
	assert(battle.turn_number == 2)
	assert(battle.player_hp == hp_before)
	assert(battle.player_block == expected_block)
	await _capture("06-guard-resolved")

	battle._choice_overlay.hide()
	battle._resolving = true
	var socket: ClockSocketData = ClockSocketData.new()
	socket.slotted_relic = ContentDatabase.get_clock_relic("REL-01")
	socket.hour_index = 1
	var before: int = battle.enemy_hp
	await battle._apply_damage_to_enemy(6, socket)
	assert(battle.enemy_hp == before - 6, "Controller retains exact damage")
	await _capture("05-strike")
	await battle._stage.await_player_recovery()
	var profile: Dictionary = AttackPresentation.for_relic(socket.slotted_relic)
	for fast: bool in [false, true]:
		AudioManager.fast_mode = fast
		actor.attack(profile)
		actor.hit(false)
		while not actor._contact_ready: await get_tree().process_frame
		assert(actor._busy, "Hit overlay must preserve the outgoing contact")
		while actor._busy: await get_tree().process_frame
	actor.set_process(false)
	for relic_index: int in range(1, 30):
		var relic: ClockRelicData = ContentDatabase.get_clock_relic("REL-%02d" % relic_index)
		var relic_profile: Dictionary = AttackPresentation.for_relic(relic)
		actor.attack(relic_profile)
		var contact: float = float(relic_profile.get("rig_contact", .3))
		actor._process(maxf(0.0, contact - .01) / AudioManager.animation_speed_scale())
		assert(not actor._contact_ready, "No early contact for " + relic.id)
		actor.hit(false)
		actor._process(.02 / AudioManager.animation_speed_scale())
		assert(actor._contact_ready, "Missing contact for " + relic.id)
		var hand: Vector2 = actor.call("anchor_position", "hand")
		assert(hand.is_finite())
		actor._process(20.0)
		assert(not actor._busy, "Recovery must complete for " + relic.id)
	actor.set_process(true)
	AudioManager.reduced_motion = true
	actor.call("begin_entrance", Vector2.ZERO)
	assert(not actor._busy, "Reduced motion skips airborne entrance")
	AudioManager.reduced_motion = false
	AudioManager.fast_mode = false
	actor.fall()
	await get_tree().create_timer(1.3).timeout
	assert(not actor._busy)
	print("MESHY_BATTLE_QA_OK intro=1 relic_choice=1 guard_outcome=1 relic_contacts=29 damage=6 simultaneous_hit=2 reduced_motion=1 death=1")
	_finished("PREVIEW COMPLETE")
	await _capture("07-replay")
	get_tree().quit()







