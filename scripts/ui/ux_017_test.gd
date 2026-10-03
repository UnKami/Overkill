extends Node
var battle: CombatController
func _ready() -> void:
	AudioManager.set_master_volume(0)
	AudioManager.fast_mode = true
	RunManager.start_new_run([],[],80,314)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy: EnemyData = ContentDatabase.get_enemy("act1_boss").duplicate()
	enemy.id = "preview_fixture"
	enemy.max_hp = 1000
	battle.start_combat([enemy])
	battle._resolving = true
	var count: int = 0
	for relic: ClockRelicData in ContentDatabase.all_clock_relics():
		for modifier: int in range(2):
			battle.player_hp = 70
			battle.player_max_hp = 100
			battle.enemy_hp = 1000
			battle.enemy_max_hp = 1000
			battle.player_block = 5
			battle.enemy_block = 4
			battle.player_strength = modifier * 2
			battle.enemy_strength = modifier
			battle.player_next_attack_multiplier = 1 + modifier
			battle.player_next_hit_bonus = modifier * 2
			for key: String in ["player_weak","player_vulnerable","enemy_weak","enemy_vulnerable","player_bleed","enemy_bleed","player_thorns","enemy_thorns"]: battle.set(key,modifier)
			var p: ClockSocketData = battle.player_sockets[0]
			p.slotted_relic = relic
			p.is_hazard = modifier == 1
			p.multiplier = 1.5 if modifier else 1.0
			var index: int = EnemyClockPattern.hour_for(1,battle._active_enemy())
			var e: ClockSocketData = battle.enemy_sockets[index-1]
			e.intent_revealed = true
			e.intent_damage = 8
			e.intent_hits = 2
			e.intent_block = 3
			e.intent_strength = 1
			e.intent_bleed = 1
			e.intent_weak = modifier
			e.intent_vulnerable = modifier
			var before: int = battle.player_hp
			var forecast: String = DecisionPreview.forecast(battle,[1])
			assert(battle.player_hp == before,"Preview mutated live combat")
			await battle._resolve_tick(1)
			var result: String = "You: %d HP · %d Block · %d Overkill   |   Enemy: %d HP · %d Block" % [battle.player_hp,battle.player_block,OKRunState.current_ok,battle.enemy_hp,battle.enemy_block]
			assert(forecast.contains(result),"Preview mismatch for %s: %s vs %s" % [relic.id,forecast,result])
			count += 1
	# Carry a charge through a guard and preview a replacement over a full sweep.
	for replacement: bool in [false,true]:
		battle.player_hp = 500
		battle.player_max_hp = 600
		battle.enemy_hp = 1000
		for slot: ClockSocketData in battle.enemy_sockets: slot.intent_revealed = true
		battle.player_sockets[0].slotted_relic = ContentDatabase.get_clock_relic("REL-14")
		battle.player_sockets[1].slotted_relic = ContentDatabase.get_clock_relic("REL-04")
		battle.player_sockets[2].slotted_relic = ContentDatabase.get_clock_relic("REL-02")
		var chosen: ClockRelicData = ContentDatabase.get_clock_relic("REL-13") if replacement else null
		var expected: String = DecisionPreview.forecast(battle,[1,2,3],2 if replacement else 0,chosen)
		assert(battle.player_sockets[1].slotted_relic.id == "REL-04")
		if replacement: battle.player_sockets[1].slotted_relic = chosen
		for hour: int in [1,2,3]: await battle._resolve_tick(hour)
		var actual: String = "You: %d HP · %d Block · %d Overkill   |   Enemy: %d HP · %d Block" % [battle.player_hp,battle.player_block,OKRunState.current_ok,battle.enemy_hp,battle.enemy_block]
		assert(expected.contains(actual),"Sweep preview mismatch: " + expected + " vs " + actual)
		count += 1
	var hidden: ClockSocketData = battle.enemy_sockets[EnemyClockPattern.hour_for(1,battle._active_enemy())-1]
	hidden.intent_revealed = false
	assert(DecisionPreview.forecast(battle,[1]).contains("unknown"))
	assert(DecisionPreview.intent(hidden) == "Unrevealed action")
	assert(not hidden.intent_revealed,"Preview exposed future action")
	await _verify_edge_forecast("REL-02", 1, 0, 3, 7, 0)
	await _verify_edge_forecast("REL-11", 40, 5, 0, 0, 21)
	await _verify_siphon_forecast(8, 100, 70)
	await _verify_siphon_forecast(4, 75, 66)
	await _verify_siphon_forecast(0, 57, 62)
	count += 5
	print("UX_017_PREVIEW_OK: %d live-resolution comparisons; nonmutating preview; concealed intents preserved" % count)
	get_tree().quit()


func _verify_edge_forecast(relic_id: String, enemy_hp: int, queued_bonus: int, thorns: int, expected_overkill: int, expected_enemy_hp: int) -> void:
	RunManager.start_new_run([], [], 100, 315)
	var scenario: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(scenario)
	var enemy: EnemyData = ContentDatabase.get_enemy("boneghoul").duplicate()
	enemy.id = "preview_edge_fixture"
	enemy.max_hp = 100
	scenario.start_combat([enemy])
	scenario._resolving = true
	scenario.player_hp = 70
	scenario.enemy_hp = enemy_hp
	scenario.enemy_thorns = thorns
	scenario.player_next_hit_bonus = queued_bonus
	var p: ClockSocketData = scenario.player_sockets[0]
	p.slotted_relic = ContentDatabase.get_clock_relic(relic_id)
	p.multiplier = 1.0
	p.is_hazard = false
	var e: ClockSocketData = scenario.enemy_sockets[EnemyClockPattern.hour_for(1, enemy) - 1]
	e.intent_revealed = true
	e.intent_damage = 0
	e.intent_block = 0
	e.intent_strength = 0
	e.intent_bleed = 0
	e.intent_weak = 0
	e.intent_vulnerable = 0
	var predicted: String = DecisionPreview.forecast(scenario, [1])
	assert(scenario.player_next_hit_bonus == queued_bonus, "Forecast must not consume a queued bonus")
	assert(OKRunState.current_ok == 0, "Forecast must not award real Overkill")
	await scenario._resolve_tick(1)
	assert(OKRunState.current_ok == expected_overkill)
	assert(scenario.enemy_hp == expected_enemy_hp)
	assert(scenario.player_hp == 70 - thorns, "Only the living target may retaliate with Thorns")
	var actual: String = "You: %d HP · %d Block · %d Overkill   |   Enemy: %d HP · %d Block" % [scenario.player_hp, scenario.player_block, OKRunState.current_ok, scenario.enemy_hp, scenario.enemy_block]
	assert(predicted.contains(actual), "Edge preview mismatch for %s: %s vs %s" % [relic_id, predicted, actual])
	RunManager.relics_held.append(ContentDatabase.get_relic("artifact_cinder_dial"))
	assert(DecisionPreview.forecast(scenario, [1]).contains("Artifact triggers excluded"), "Artifact estimates must disclose excluded triggers")
	scenario.queue_free()
	await get_tree().process_frame
	print("PREVIEW_EDGE_OK %s" % relic_id)


func _verify_siphon_forecast(block: int, expected_overkill: int, expected_hp: int) -> void:
	RunManager.start_new_run([], [], 100, 316)
	OKRunState.current_ok = 100
	var scenario: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(scenario)
	var enemy: EnemyData = ContentDatabase.get_enemy("boneghoul").duplicate()
	enemy.id = "preview_siphon_fixture"
	enemy.max_hp = 100
	scenario.start_combat([enemy])
	scenario._resolving = true
	scenario.player_hp = 70
	scenario.player_block = block
	scenario.player_sockets[0].slotted_relic = null
	var e: ClockSocketData = scenario.enemy_sockets[EnemyClockPattern.hour_for(1, enemy) - 1]
	e.intent_revealed = true
	e.intent_damage = 4
	e.intent_hits = 2
	e.intent_block = 0
	e.intent_strength = 0
	e.intent_bleed = 0
	e.intent_weak = 0
	e.intent_vulnerable = 0
	e.is_siphon = true
	var predicted: String = DecisionPreview.forecast(scenario, [1])
	assert(OKRunState.current_ok == 100, "Forecast must not drain real Overkill")
	assert(scenario.player_block == block, "Forecast must not consume real Block")
	await scenario._resolve_tick(1)
	assert(OKRunState.current_ok == expected_overkill, "Siphon drains 25 percent, rounded down, only on HP damage")
	assert(scenario.player_hp == expected_hp)
	var actual: String = "You: %d HP · %d Block · %d Overkill   |   Enemy: %d HP · %d Block" % [scenario.player_hp, scenario.player_block, OKRunState.current_ok, scenario.enemy_hp, scenario.enemy_block]
	assert(predicted.contains(actual), "Siphon forecast mismatch: %s vs %s" % [predicted, actual])
	scenario.queue_free()
	await get_tree().process_frame
	print("PREVIEW_SIPHON_OK block=%d" % block)
