extends Node
## Real controller damage and terminal transitions, opt-in 3D opponent.
var battle: CombatController

func _ready() -> void:
	assert(OS.get_cmdline_user_args().has("--boneghoul-3d"))
	AudioManager.set_master_volume(0)
	get_window().size = Vector2i(1280, 720)
	for won: bool in [true, false]:
		for fast: bool in [false, true]:
			for reduced: bool in [false, true]:
				await check_encounter(won, fast, reduced)
	print("BONEGHOUL_ENCOUNTER_OK: real guard, partial block, claw damage and eight terminal modes")
	get_tree().quit()

func check_encounter(won: bool, fast: bool, reduced: bool) -> void:
	AudioManager.fast_mode = fast
	AudioManager.reduced_motion = reduced
	RunManager.start_new_run([], [], 80, 1729)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("boneghoul")])
	await get_tree().create_timer(0.4).timeout
	assert(battle._stage is DirectedArena)
	var stage: DirectedArena = battle._stage
	assert(stage.enemy is BoneghoulActor)
	var ghoul: BoneghoulActor = stage.enemy
	var contact_sample: Dictionary = {"point":Vector3.ZERO}
	ghoul.contact_reached.connect(func() -> void: contact_sample.point = ghoul.claw_tip())
	var scale_time: float = AudioManager.animation_speed_scale()
	if won and not fast and not reduced: await capture("choices")
	battle._clear_pedestals()
	battle._resolving = true
	battle.enemy_block = 8
	battle._apply_damage_to_enemy(6, battle.player_sockets[0])
	await get_tree().create_timer(0.10 / scale_time).timeout
	assert(battle.enemy_block == 8 and battle.enemy_hp == 16, "No damage before sword contact")
	assert(ghoul.is_guarding(), "Boneghoul must brace during incoming wind-up")
	var deadline: int = Time.get_ticks_msec() + 3000
	while battle.enemy_block == 8 and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert(battle.enemy_block == 2 and battle.enemy_hp == 16)
	assert(stage._impact_light.position.distance_to(ghoul.guard_contact_point(stage.player.global_position)) < 0.08, "Blocked effects must meet the bracer")
	var pulse: MeshInstance3D = stage._world.get_node("GuardPulse")
	assert(pulse.position.distance_to(stage._impact_light.position) < 0.01, "Guard ring must indicate the interception, not the waist")
	assert((pulse.mesh as TorusMesh).outer_radius < 0.20)
	if won and not fast and not reduced: await capture("blocked")
	await get_tree().create_timer(0.8 / scale_time).timeout
	await battle._apply_damage_to_enemy(6, battle.player_sockets[0])
	assert(battle.enemy_hp == 12 and battle.enemy_block == 0)
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
	if won: await battle._apply_damage_to_enemy(13, battle.player_sockets[0])
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
		assert(ghoul.state == BoneghoulActor.State.DEAD)
		assert(absf(ghoul.animation.current_animation_position - 1.6) < 0.02)
	print("BONEGHOUL_BATTLE_MODE_OK won=", won, " fast=", fast, " reduced=", reduced)
	battle.queue_free()
	await get_tree().process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://boneghoul-encounter")
	get_viewport().get_texture().get_image().save_png("user://boneghoul-encounter/" + label + ".png")
