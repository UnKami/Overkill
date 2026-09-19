extends Node
## Real controller damage and terminal transitions, opt-in 3D opponent.
var battle: CombatController

func _ready() -> void:
	assert(OS.get_cmdline_user_args().has("--custodian-3d"))
	AudioManager.set_master_volume(0)
	await check_actor_contract()
	get_window().size = Vector2i(1280, 720)
	for won: bool in [true, false]:
		for fast: bool in [false, true]:
			for reduced: bool in [false, true]:
				await check_encounter(won, fast, reduced)
	print("CUSTODIAN_ENCOUNTER_OK: real guard, partial block, claw damage and eight terminal modes")
	get_tree().quit()

func check_encounter(won: bool, fast: bool, reduced: bool) -> void:
	AudioManager.fast_mode = fast
	AudioManager.reduced_motion = reduced
	RunManager.start_new_run([], [], 80, 1729)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("act2_elite")])
	await get_tree().create_timer(0.4).timeout
	assert(battle._stage is DirectedArena)
	var stage: DirectedArena = battle._stage
	assert(stage.enemy is CustodianActor)
	var ghoul: CustodianActor = stage.enemy
	var contact_sample: Dictionary = {"point":Vector3.ZERO}
	ghoul.contact_reached.connect(func() -> void: contact_sample.point = ghoul.claw_tip())
	var scale_time: float = AudioManager.animation_speed_scale()
	if won and not fast and not reduced: await capture("choices")
	battle._clear_pedestals()
	battle._resolving = true
	battle.enemy_block = 8
	battle._apply_damage_to_enemy(6, battle.player_sockets[0])
	await get_tree().create_timer(0.10 / scale_time).timeout
	assert(battle.enemy_block == 8 and battle.enemy_hp == 75, "No damage before sword contact")
	assert(ghoul.is_guarding(), "Custodian must brace during incoming wind-up")
	var deadline: int = Time.get_ticks_msec() + 3000
	while battle.enemy_block == 8 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert(battle.enemy_block == 2 and battle.enemy_hp == 75)
	assert(stage._impact_light.position.distance_to(ghoul.guard_contact_point(stage.player.global_position)) < 0.08, "Blocked effects must meet the bracer")
	var pulse: MeshInstance3D = stage._world.get_node("GuardPulse")
	assert(pulse.position.distance_to(stage._impact_light.position) < 0.01, "Guard ring must indicate the interception, not the waist")
	assert((pulse.mesh as TorusMesh).outer_radius < 0.20)
	if won and not fast and not reduced: await capture("blocked")
	await get_tree().create_timer(0.8 / scale_time).timeout
	await battle._apply_damage_to_enemy(6, battle.player_sockets[0])
	assert(battle.enemy_hp == 71 and battle.enemy_block == 0)
	battle.player_block = 1
	battle._apply_damage_to_player(4, battle.enemy_sockets[0])
	await get_tree().create_timer(0.2 / scale_time).timeout
	assert(battle.player_hp == 80, "No damage before claw contact")
	deadline = Time.get_ticks_msec() + 3000
	while battle.player_hp == 80 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert(battle.player_hp == 77 and battle.player_block == 0)
	assert(stage._impact_light.position.distance_to(contact_sample.point) < 0.08, "Claw impact must match the finger position recorded at contact, not its later recovery pose")
	if won and not fast and not reduced: await capture("claw-impact")
	await get_tree().create_timer(0.9 / scale_time).timeout
	var observed: Dictionary = {"won":0, "lost":0}
	battle.combat_won.connect(func(_enemies: Array) -> void: observed.won += 1)
	battle.combat_lost.connect(func() -> void: observed.lost += 1)
	if won: await battle._apply_damage_to_enemy(72, battle.player_sockets[0])
	else: await battle._apply_damage_to_player(80, battle.enemy_sockets[0])
	assert(battle._check_combat_end())
	assert(observed.won + observed.lost == 0)
	await get_tree().create_timer(0.7 / scale_time).timeout
	assert(observed.won + observed.lost == 0, "Handoff must wait for collapse")
	await get_tree().create_timer(0.92 / scale_time).timeout
	if not fast and not reduced: await capture("victory" if won else "defeat")
	await get_tree().create_timer(stage.finish_delay()).timeout
	assert(observed.won == (1 if won else 0) and observed.lost == (0 if won else 1))
	assert(ghoul._dead if won else stage.player._dead)
	if won:
		assert(ghoul.state == CustodianActor.State.DEAD)
		assert(absf(ghoul.animation.current_animation_position - 1.6) < 0.02)
	print("CUSTODIAN_BATTLE_MODE_OK won=", won, " fast=", fast, " reduced=", reduced)
	battle.queue_free()
	await get_tree().process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://custodian-encounter")
	get_viewport().get_texture().get_image().save_png("user://custodian-encounter/" + label + ".png")

func check_actor_contract() -> void:
	var actor: CustodianActor = CustodianActor.new()
	var other: CustodianActor = CustodianActor.new()
	add_child(actor)
	add_child(other)
	actor.set_process(false)
	other.set_process(false)
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
	var events: Dictionary = {"count": 0}
	actor.contact_reached.connect(func() -> void: events.count += 1)
	actor.attack()
	actor.advance_motion(0.2)
	actor.hit(false)
	actor.advance_motion(2.0)
	assert(events.count == 0, "Interrupted attacks must not emit contact")
	actor.attack()
	actor.advance_motion(3.0)
	assert(events.count == 1 and actor.state == CustodianActor.State.IDLE)
	actor.prepare_guard()
	actor.advance_motion(2.0)
	assert(is_equal_approx(actor.animation.current_animation_position, actor.GUARD_HOLD_TIME))
	actor.hit(true)
	actor.advance_motion(1.0)
	assert(actor.state == CustodianActor.State.IDLE)
	actor.contact_reached.connect(func() -> void: actor.fall())
	actor.attack()
	actor.advance_motion(3.0)
	assert(events.count == 2 and actor.state == CustodianActor.State.DEAD)
	assert(actor._visor.emission_energy_multiplier < 0.01)
	assert(other._visor.emission_energy_multiplier > 0.1, "Shutdown must not darken another actor")
	actor.attack()
	actor.hit(false)
	assert(actor.state == CustodianActor.State.DEAD)
	actor.queue_free()
	other.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("CUSTODIAN_ACTOR_OK interruption, contact, held guard, terminal state and private visor")