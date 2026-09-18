extends Node

func _ready() -> void:
	AudioManager.set_master_volume(0)
	AudioManager.fast_mode = true
	RunManager.start_new_run([], [], 80, 123)
	assert(RunManager.clock_inventory.size() == 16)
	var counts: Dictionary = {}
	var uids: Dictionary = {}
	for entry: Dictionary in RunManager.clock_inventory:
		counts[entry.id] = int(counts.get(entry.id, 0)) + 1
		assert(not uids.has(entry.uid))
		uids[entry.uid] = true
	assert(counts == {"REL-01": 6, "REL-04": 6, "REL-02": 2, "REL-06": 2})
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
	assert(battle.player_block == 6)
	await battle._resolve_tick(2)
	assert(battle.player_block == 6, "Unused block must persist across ticks")
	battle.enemy_sockets[2].intent_damage = 4
	await battle._resolve_tick(3)
	assert(battle.player_block == 2 and battle.player_hp == 80)
	battle.player_sockets[3].slotted_relic = ContentDatabase.get_clock_relic("REL-06")
	await battle._resolve_tick(4)
	assert(battle.player_block == 10, "Stronger block adds 8 to remaining block")
	battle.player_sockets[4].slotted_relic = ContentDatabase.get_clock_relic("REL-02")
	var hp_before: int = battle.enemy_hp
	await battle._resolve_tick(5)
	assert(battle.enemy_hp == hp_before - 8)
	battle.queue_free()
	var next_battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(next_battle)
	next_battle.start_combat([enemy])
	assert(next_battle.player_block == 0, "Block resets for a new battle")
	print("STARTER_RELIC_OK: composition, independent copies, persistent block, absorption, twin hit and battle reset")
	get_tree().quit()
