extends Node
## Exercises real save JSON, title Continue and production scene routing.
## No combat is autoplayed; encounter outcomes/resources are explicit fixtures.

var _assertions: int = 0


func _ready() -> void:
	var profile: String = OS.get_environment("APPDATA").replace("\\", "/").to_lower()
	if not profile.contains("/.tools/042-audit-profile"):
		push_error("RESUME_CHECKPOINT_REFUSED: isolated audit profile required")
		get_tree().quit(2)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	get_tree().current_scene = null
	AudioManager.reduced_motion = true
	AudioManager.set_master_volume(0.0)
	for legacy: bool in [false, true]:
		for act: int in range(1, 4):
			await _boss_checkpoint(act, legacy)
	await _reward_checkpoint()
	await _prebattle_checkpoint()
	await _altar_and_final_checkpoint()
	await _clear()
	SaveManager.delete_run_save()
	print("RESUME_CHECKPOINT_OK: %d assertions; disk/title round trips, all-act cog/legacy bosses, entry rollback, fixed rewards, altar purchase, final descent" % _assertions)
	get_tree().quit()


func _reset(act: int = 1) -> void:
	RunManager.start_new_run([], [], 500, 42042)
	RunManager.act_number = act
	RunManager.current_hp = 400
	OKRunState.current_ok = 200


func _boss_node(act: int, legacy: bool) -> String:
	return "act%d_row6_node0" % act if legacy else "cogmap-a%d-r7-g0-s0" % act


func _boss_checkpoint(act: int, legacy: bool) -> void:
	await _clear()
	_reset(act)
	RunManager.commit_map_node(_boss_node(act, legacy))
	var boss: EnemyData = ContentDatabase.get_enemy("act%d_boss" % act)
	# Genuine pre-checkpoint save migration: no phase or completed-fight flag.
	SaveManager.save_run()
	var legacy_data: Dictionary = SaveManager.load_run()
	legacy_data.erase("resume_context")
	var legacy_file: FileAccess = FileAccess.open(SaveManager.RUN_SAVE_PATH, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy_data))
	legacy_file.close()
	await _round_trip(false)
	_check(get_tree().current_scene is CombatController, "Legacy phase-less boss save resumes an encounter rather than a dead-end map")
	var battle: CombatController = get_tree().current_scene as CombatController
	_check(battle.enemies_data[0].id == boss.id, "Both map families recover the correct act guardian")
	_check(RunManager.current_hp == 400 and OKRunState.current_ok == 200, "Legacy recovery preserves owned resources")
	_check(not (RunManager.resume_context.entry_state as Dictionary).has("resume_context"), "Entry snapshots do not recursively contain checkpoints")
	var saved_length: int = JSON.stringify(RunManager.resume_context).length()
	# Model partial combat gains and an accidental upgrade to verify rollback
	# restores the full entry state, not only the encounter's enemy/HP.
	RunManager.current_hp = 375
	RunManager.upgrade_clock_relic(int(RunManager.clock_inventory[0].uid))
	OKRunState.gain_ok(17, "resume_fixture_partial_combat")
	await _round_trip()
	battle = get_tree().current_scene as CombatController
	_check(battle != null and battle.enemies_data[0].id == boss.id, "Checkpoint Continue restores the exact encounter")
	_check(RunManager.current_hp == 400 and OKRunState.current_ok == 200 and int(RunManager.clock_inventory[0].level) == 0, "Combat resume cannot duplicate gains or keep partial resource mutations")
	_check(JSON.stringify(RunManager.resume_context).length() == saved_length, "Repeated combat Continue has bounded checkpoint size")
	_check(RunManager.current_node_id == _boss_node(act, legacy), "Resume preserves the exact saved route node")


func _reward_checkpoint() -> void:
	await _clear()
	_reset()
	RunManager.commit_map_node("cogmap-a1-r0-g0-s0")
	GameFlow.goto_reward_screen({"enemy_data": ContentDatabase.get_enemy("boneghoul")})
	await _settle()
	var screen: Control = get_tree().current_scene as Control
	var offers: Array = screen._offer_ids.duplicate()
	var relic: ClockRelicData = ContentDatabase.get_clock_relic(str(offers[0]))
	screen._on_relic_chosen(relic)
	screen._show_relic_offers()
	_check(screen._offer_ids == offers, "Backing out of replacement cannot reroll rewards")
	await _round_trip()
	screen = get_tree().current_scene as Control
	_check(screen.name == "RewardScreen" and screen._offer_ids == offers, "Unclaimed reward and exact offers survive disk/title Continue")
	screen._on_relic_chosen(relic)
	screen._replace_with_pending_relic(int(RunManager.clock_inventory[0].uid))
	await _settle()
	var inventory_after: Array[Dictionary] = RunManager.clock_inventory.duplicate(true)
	await _round_trip()
	_check(get_tree().current_scene is CogMapScreen, "A claimed reward resumes the map, not the claim screen")
	_check(RunManager.clock_inventory == inventory_after and RunManager.clock_inventory.size() == 12, "Claimed replacement is not duplicated on Continue")


func _prebattle_checkpoint() -> void:
	await _clear()
	_reset()
	var enemies: Array[EnemyData] = [ContentDatabase.get_enemy("boneghoul")]
	GameFlow.goto_pre_battle_offer(enemies, "cogmap-a1-r0-g0-s0")
	await _settle()
	RunManager.apply_max_hp_change(3)
	RunManager.upgrade_clock_relic(int(RunManager.clock_inventory[0].uid))
	OKRunState.gain_ok(10, "resume_fixture_unfinished_offer")
	await _round_trip()
	_check(get_tree().current_scene is PreBattleOfferScreen, "An unfinished offer resumes its choice")
	_check(RunManager.max_hp == 500 and RunManager.current_hp == 400 and OKRunState.current_ok == 200 and int(RunManager.clock_inventory[0].level) == 0, "Unfinished offer effects cannot be collected repeatedly")
	GameFlow._finish_pre_battle()
	await _settle()
	_check(get_tree().current_scene is CombatController and not RunManager.should_offer_pre_battle(), "Finishing a resumed offer commits its battle and once-per-act marker")
	_check(str(SaveManager.load_run().resume_context.kind) == "combat", "Finished offer saves the combat checkpoint")


func _altar_and_final_checkpoint() -> void:
	await _clear()
	_reset(3)
	RunManager.commit_map_node(_boss_node(3, false))
	GameFlow.goto_boss_overkill_altar(ContentDatabase.get_enemy("act3_boss"))
	await _settle()
	await _round_trip()
	var altar: BossOverkillAltar = get_tree().current_scene as BossOverkillAltar
	_check(altar != null and not altar._purchased, "Defeated boss resumes the unpaid altar, without repeating battle")
	altar._open_purchase("REL-27")
	altar._select_replacement(altar._replacement_grid.get_child(0) as Button)
	altar._confirm_purchase()
	var inventory_after: Array[Dictionary] = RunManager.clock_inventory.duplicate(true)
	var balance_after: int = OKRunState.current_ok
	await _round_trip()
	altar = get_tree().current_scene as BossOverkillAltar
	_check(altar != null and altar._purchased and altar._offer_buttons[0].disabled, "Purchased altar resumes with all purchase actions disabled")
	altar._open_purchase("REL-28")
	altar._confirm_purchase()
	_check(RunManager.clock_inventory == inventory_after and OKRunState.current_ok == balance_after, "Resume cannot repeat a paid Zenith purchase or charge twice")
	altar._continue_after_altar()
	await _settle()
	await _round_trip()
	_check(str(RunManager.resume_context.kind) == "boss_exit" and get_tree().current_scene.has_method("_dismiss"), "Quitting on the final-descent curtain preserves its destination")
	get_tree().current_scene._dismiss()
	await _settle()
	var battle: CombatController = get_tree().current_scene as CombatController
	_check(battle != null and battle.enemies_data[0].id == "final_boss", "Final descent starts the final boss")
	await _round_trip()
	battle = get_tree().current_scene as CombatController
	_check(battle != null and battle.enemies_data[0].id == "final_boss", "Final-boss Continue never regresses to the act-three guardian")
	_check(RunManager.clock_inventory == inventory_after and OKRunState.current_ok == balance_after, "Final-boss entry retains the purchased relic and exact bank")
	# Earlier act departure must advance once, even across a saved curtain.
	await _clear()
	_reset(1)
	RunManager.commit_map_node(_boss_node(1, false))
	GameFlow.goto_boss_exit(ContentDatabase.get_enemy("act1_boss"))
	var reveal_deadline: int = Time.get_ticks_msec() + 8000
	while get_tree().current_scene == null and Time.get_ticks_msec() < reveal_deadline:
		await get_tree().process_frame
	var curtain: Control = get_tree().current_scene as Control
	_check(curtain != null and GameFlow._transitioning, "Inter-act scene is installed before its incoming reveal finishes")
	var early_enter := InputEventKey.new()
	early_enter.keycode = KEY_ENTER
	early_enter.pressed = true
	curtain._unhandled_key_input(early_enter)
	_check(not curtain._dismissed and RunManager.act_number == 1, "Early Enter cannot consume departure or advance the act behind the reveal")
	await _settle()
	await _round_trip()
	get_tree().current_scene._dismiss()
	await _settle()
	await _round_trip()
	_check(RunManager.act_number == 2 and get_tree().current_scene is CogMapScreen, "Saved inter-act transition advances exactly once")


func _round_trip(persist: bool = true) -> void:
	if persist: SaveManager.save_run()
	GameFlow.goto_title()
	await _settle()
	var title: Control = get_tree().current_scene as Control
	RunManager.start_new_run([], [], 1, 9)
	title._on_continue_pressed()
	await _settle()


func _settle() -> void:
	var deadline: int = Time.get_ticks_msec() + 8000
	while GameFlow._transitioning and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(not GameFlow._transitioning, "Scene transition completed")
	await get_tree().create_timer(0.1).timeout


func _clear() -> void:
	GameFlow.close_pause_menu()
	GameFlow.close_settings()
	GameFlow.close_deck_view()
	var current: Node = get_tree().current_scene
	get_tree().current_scene = null
	if is_instance_valid(current): current.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _check(passed: bool, message: String) -> void:
	_assertions += 1
	assert(passed, message)
