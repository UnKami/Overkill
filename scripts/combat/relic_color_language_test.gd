extends Node


func _ready() -> void:
	AudioManager.set_master_volume(0.0)
	AudioManager.fast_mode = true
	var relics: Array = ContentDatabase.all_clock_relics()
	assert(relics.size() == 26, "The complete color-language lineup must contain 26 relics")
	var ids: Dictionary = {}
	var affinity_counts: Dictionary = {}
	for relic: ClockRelicData in relics:
		assert(not ids.has(relic.id), "Relic ids must be unique: %s" % relic.id)
		ids[relic.id] = true
		var expected := _mechanical_essences(relic)
		var declared: Array[int] = [int(relic.primary_essence)]
		if relic.secondary_essence >= 0:
			declared.append(relic.secondary_essence)
		declared.sort()
		expected.sort()
		assert(declared == expected, "%s declares %s but mechanics require %s" % [relic.id, declared, expected])
		assert(declared.size() <= 2, "%s exceeds the two-color readability rule" % relic.id)
		if declared.has(ClockRelicData.Essence.OVERKILL):
			assert(relic.grant_overkill > 0, "Blood red is exclusive to direct Overkill gain")
		if relic.grant_overkill > 0:
			assert(declared.has(ClockRelicData.Essence.OVERKILL), "Overkill-granting relics must show blood red")
		var art: Texture2D = RelicArt.load_texture(relic.art_id)
		assert(art != null, "%s is missing its object art" % relic.art_id)
		affinity_counts[relic.primary_essence] = int(affinity_counts.get(relic.primary_essence, 0)) + 1

	for essence: int in ClockRelicData.Essence.values():
		assert(int(affinity_counts.get(essence, 0)) > 0, "Every essence needs at least one primary relic")
	assert(ContentDatabase.get_clock_relic("REL-13").name == "Vital Siphon", "Non-Overkill relics must not borrow blood-red naming")

	RunManager.start_new_run([], [], 80, 526)
	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy := EnemyData.new()
	enemy.id = "color_test_target"
	enemy.max_hp = 500
	battle.start_combat([enemy])
	battle._resolving = true
	battle._clear_pedestals()
	for socket: ClockSocketData in battle.enemy_sockets:
		socket.intent_damage = 0
		socket.intent_block = 0
		socket.intent_strength = 0
		socket.intent_bleed = 0
		socket.intent_vulnerable = 0
		socket.intent_weak = 0

	battle.player_sockets[0].slotted_relic = ContentDatabase.get_clock_relic("REL-18")
	var ok_before: int = OKRunState.current_ok
	await battle._resolve_tick(1)
	assert(OKRunState.current_ok == ok_before + 3, "Blood Tithe must grant 3 real Overkill")

	battle.player_sockets[1].slotted_relic = ContentDatabase.get_clock_relic("REL-24")
	var hp_before: int = battle.enemy_hp
	var block_before: int = battle.player_block
	await battle._resolve_tick(2)
	assert(battle.enemy_hp == hp_before - 5 and battle.player_block == block_before + 5, "Siege Prism must fulfill both orange and blue effects")

	battle.player_sockets[2].slotted_relic = ContentDatabase.get_clock_relic("REL-21")
	await battle._resolve_tick(3)
	assert(battle.player_strength == 1 and battle.enemy_weak == 1, "Hex Bloom must fulfill both effects; Weak then spends one duration at tick end")

	battle.queue_free()
	print("RELIC_COLOR_LANGUAGE_OK: 26 unique object relics, five mechanic-bound colors, genuine dual effects and blood-red Overkill resolution")
	get_tree().quit()


func _mechanical_essences(relic: ClockRelicData) -> Array[int]:
	var result: Array[int] = []
	if relic.base_damage > 0 or relic.conditional_damage > 0:
		result.append(ClockRelicData.Essence.ATTACK)
	if relic.base_block > 0 or relic.recoil_block_on_overkill:
		result.append(ClockRelicData.Essence.BLOCK)
	if relic.apply_strength > 0 or relic.apply_thorns > 0 or relic.lifesteal or relic.next_attack_multiplier > 1 or relic.bonus_damage_next_hit > 0:
		result.append(ClockRelicData.Essence.BUFF)
	if relic.apply_vulnerable > 0 or relic.apply_weak > 0 or relic.apply_bleed > 0:
		result.append(ClockRelicData.Essence.DEBUFF)
	if relic.grant_overkill > 0:
		result.append(ClockRelicData.Essence.OVERKILL)
	return result
