extends Node
## Deterministic playthroughs at actual encounter HP, using an explicit basic policy.
func _ready() -> void:
	AudioManager.set_master_volume(0)
	AudioManager.fast_mode = true
	Engine.time_scale = 12.0
	for encounter_id in ["boneghoul", "act1_elite", "act1_boss", "act2_boss", "act3_boss", "final_boss"]:
		seed(912)
		RunManager.start_new_run([], [], 80, 912)
		# Later-act fixtures model accumulated forge upgrades, not inflated HP.
		if encounter_id in ["act2_boss", "act3_boss", "final_boss"]:
			for entry in RunManager.clock_inventory: entry.level = 1
		var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
		add_child(battle)
		battle.start_combat([ContentDatabase.get_enemy(encounter_id)])
		var steps := 0
		while not battle._combat_over and steps < 60:
			if battle._resolving:
				await get_tree().process_frame
				continue
			if battle.phase == CombatController.Phase.ASSEMBLY:
				var choices := battle.current_draft_selection.duplicate()
				choices.sort_custom(func(a: ClockRelicData, b: ClockRelicData) -> bool: return score(a, battle) > score(b, battle))
				await battle._on_phase_one_relic_chosen(choices[0])
			else:
				var relic := battle.current_drawn_relic
				var hours := ChronometerView.get_quadrant_hours(battle.active_quadrant)
				var target := hours[0]
				for hour in hours:
					if score(battle.player_sockets[hour - 1].slotted_relic, battle) < score(battle.player_sockets[target - 1].slotted_relic, battle): target = hour
				if relic != null and score(relic, battle) > score(battle.player_sockets[target - 1].slotted_relic, battle):
					await battle._on_player_socket_pressed(target, battle._player_chrono.get_socket_view(target))
				else: await battle._on_skip_button_pressed()
			steps += 1
		assert(steps < 60, "Encounter failed to terminate")
		print("ENCOUNTER_RESULT %s %s hp=%d turns=%d enemy_hp=%d" % [encounter_id, "WIN" if battle.enemy_hp <= 0 and battle.player_hp > 0 else "LOSS", battle.player_hp, steps, battle.enemy_hp])
		if encounter_id == "boneghoul": assert(battle.enemy_hp <= 0 and battle.player_hp > 0)
		await get_tree().create_timer(1.6 if battle._stage is DirectedArena else 1.0).timeout
		battle.queue_free()
		await get_tree().process_frame
	print("ENCOUNTER_PLAYTHROUGHS_OK")
	get_tree().quit()

func score(relic: ClockRelicData, battle: CombatController) -> float:
	if relic == null: return -1
	var value := float(relic.base_damage * relic.hits)
	value += float(relic.base_block) * (1.8 if battle.player_hp < 40 else 0.8)
	value += float(relic.apply_bleed) * (8.0 if battle.enemy_hp > 45 else 2.0)
	value += float(relic.apply_strength) * 3.0
	value += float(relic.apply_weak) * 2.0
	value += float(relic.apply_thorns) * 3.0
	if battle.enemy_hp < 20: value += relic.base_damage
	return value
