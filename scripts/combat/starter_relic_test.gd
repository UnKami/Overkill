extends Node

func _ready() -> void:
	AudioManager.set_master_volume(0)
	AudioManager.fast_mode = true
	RunManager.start_new_run([], [], 80, 123)
	assert(RunManager.clock_inventory.size() == 12)
	var counts: Dictionary = {}
	var uids: Dictionary = {}
	for entry: Dictionary in RunManager.clock_inventory:
		counts[entry.id] = int(counts.get(entry.id, 0)) + 1
		assert(not uids.has(entry.uid))
		uids[entry.uid] = true
	assert(counts == {"REL-01": 5, "REL-04": 5, "REL-13": 1, "REL-14": 1})
	var copy: ClockRelicData = ClockInventory.resolve(RunManager.clock_inventory[0])
	copy.base_damage = 99
	assert(ClockInventory.resolve(RunManager.clock_inventory[1]).base_damage == 6)
	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "boneghoul"
	enemy.max_hp = 1000
	battle.start_combat([enemy])
	assert(battle._choice_overlay.visible)
	assert(not battle.get_node("BottomDock").visible)
	assert(battle.get_node("CombatArena").offset_bottom == -24)
	assert(battle.enemy_sockets.size() == 9)
	for i: int in 9:
		assert(battle.enemy_sockets[i].intent_revealed == (i == 0))
		if i > 0: assert(battle._enemy_chrono.get_socket_view(i + 1)._value_label.text == "?")
	battle._resolving = true
	battle._clear_pedestals()
	for socket: ClockSocketData in battle.enemy_sockets:
		socket.intent_damage = 0
		socket.intent_block = 0
		socket.intent_strength = 0
		socket.intent_bleed = 0
		socket.intent_vulnerable = 0
		socket.intent_weak = 0
	battle.player_sockets[0].slotted_relic = ContentDatabase.get_clock_relic("REL-04")
	await battle._resolve_tick(1)
	assert(battle.player_block == 5)
	await battle._resolve_tick(2)
	assert(battle.player_block == 5, "Unused block must persist across ticks")
	battle.enemy_sockets[2].intent_damage = 4
	await battle._resolve_tick(3)
	assert(battle.player_block == 1 and battle.player_hp == 80)
	battle.player_sockets[3].slotted_relic = ContentDatabase.get_clock_relic("REL-06")
	await battle._resolve_tick(4)
	assert(battle.player_block == 9, "Stronger block adds 8 to remaining block")
	battle.player_sockets[4].slotted_relic = ContentDatabase.get_clock_relic("REL-02")
	var hp_before: int = battle.enemy_hp
	await battle._resolve_tick(5)
	assert(battle.enemy_hp == hp_before - 8)
	battle.player_sockets[5].slotted_relic = ContentDatabase.get_clock_relic("REL-14")
	hp_before = battle.enemy_hp
	await battle._resolve_tick(6)
	assert(battle.enemy_hp == hp_before - 4 and battle.player_next_attack_multiplier == 2)
	await battle._resolve_tick(2)
	assert(battle.player_next_attack_multiplier == 2, "Empty and Guard hours preserve charge")
	battle.player_sockets[6].slotted_relic = ContentDatabase.get_clock_relic("REL-01")
	await battle._resolve_tick(7)
	assert(battle.enemy_hp == hp_before - 16 and battle.player_next_attack_multiplier == 1)
	await battle._resolve_tick(7)
	assert(battle.enemy_hp == hp_before - 22, "Boost is consumed once")
	battle.player_sockets[7].slotted_relic = ContentDatabase.get_clock_relic("REL-13")
	battle.player_hp = 60
	battle.enemy_block = 2
	await battle._resolve_tick(8)
	assert(battle.player_hp == 61, "Lifesteal heals only unblocked HP damage")
	battle.enemy_block = 20
	await battle._resolve_tick(8)
	assert(battle.player_hp == 61, "Fully blocked hits do not heal")
	battle.enemy_block = 0
	battle.player_hp = 79
	await battle._resolve_tick(8)
	assert(battle.player_hp == 80, "Healing cannot exceed maximum HP")
	battle.player_hp = 60
	battle.enemy_hp = 1
	await battle._apply_damage_to_enemy(3, battle.player_sockets[7])
	assert(battle.player_hp == 61, "Overkill damage does not heal")
	assert(battle.enemy_sockets[0].intent_revealed and battle.enemy_sockets[7].intent_revealed)
	battle.queue_free()
	var next_battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(next_battle)
	next_battle.start_combat([enemy])
	assert(next_battle.player_block == 0, "Block resets for a new battle")
	print("STARTER_RELIC_OK: composition, independent copies, persistent block, absorption, twin hit, next-attack charge, lifesteal caps, hidden intents and battle reset")
	get_tree().quit()
