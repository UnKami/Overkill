extends Node
## Integration coverage for persistent inventory, economy, encounters and settings.
var battle: CombatController

func _ready() -> void:
	AudioManager.set_master_volume(0.0)
	RunManager.start_new_run([], [], 80, 1729)
	assert(RunManager.clock_inventory.size() == 16)
	var original := ClockInventory.resolve(RunManager.clock_inventory[0])
	assert(RunManager.upgrade_clock_relic(0))
	assert(not RunManager.upgrade_clock_relic(0))
	assert(ClockInventory.resolve(RunManager.clock_inventory[0]).base_damage == original.base_damage + 3)
	assert(ContentDatabase.get_clock_relic(original.id).base_damage == original.base_damage, "Upgrade must not mutate shared content")
	SaveManager.save_run()
	RunManager.clock_inventory.clear()
	RunManager.load_from_save(SaveManager.load_run())
	assert(RunManager.clock_inventory.size() == 16)
	assert(int(RunManager.clock_inventory[0].level) == 1)
	RunManager.load_from_save({"current_hp": 70, "max_hp": 80, "deck": []})
	assert(RunManager.clock_inventory.size() == 16, "Legacy save gets usable inventory")
	assert(RunManager.remove_clock_relic(0))
	assert(not RunManager.remove_clock_relic(1), "Cannot remove the minimum reserve")
	RunManager.start_new_run([], [], 80, 1729)
	var shop := preload("res://scripts/ui/clock_collection_screen.gd").new()
	shop.mode = "shop"
	add_child(shop)
	var offered: ClockRelicData = shop._offers[0]
	OKRunState.current_ok = 14
	shop._buy(offered, 15)
	assert(RunManager.clock_inventory.size() == 16)
	OKRunState.current_ok = 30
	shop._buy(offered, 15)
	shop._buy(offered, 15)
	assert(RunManager.clock_inventory.size() == 17)
	assert(OKRunState.current_ok == 15, "A sold offer cannot be bought twice")
	shop.queue_free()
	var patterns: Dictionary = {}
	for id in ["boneghoul", "act1_elite", "act1_boss", "act2_trash", "act2_elite", "act2_boss", "act3_trash", "act3_elite", "act3_boss", "final_boss"]:
		var enemy := ContentDatabase.get_enemy(id)
		assert(enemy != null)
		var sockets := EnemyClockPattern.create(enemy)
		assert(sockets.size() == 12)
		assert(not sockets[0].intent_label.is_empty())
		patterns[EnemyClockPattern.profile(enemy)] = true
	assert(patterns.size() == 10)
	assert(EnemyClockPattern.hour_for(1, ContentDatabase.get_enemy("act2_boss")) == 12)
	assert(EnemyClockPattern.hour_for(12, ContentDatabase.get_enemy("act2_boss")) == 1)
	assert(EnemyClockPattern.has_twin(ContentDatabase.get_enemy("act3_boss")))
	RunManager.start_new_run([], [], 80, 1729)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var first: EnemyData = ContentDatabase.get_enemy("act1_elite").duplicate()
	var second: EnemyData = ContentDatabase.get_enemy("act2_boss").duplicate()
	first.max_hp = 500
	second.max_hp = 500
	battle.start_combat([first, second])
	await battle._resolve_tick(1)
	assert(battle.player_weak == 1, "Enemy weakening intent must resolve and decay")
	battle.enemy_hp = 0
	assert(not battle._check_combat_end())
	assert(battle._enemy_index == 1 and battle.enemy_hp == 500)
	assert(battle._enemy_chrono.rotation_direction == -1)
	await battle._enemy_chrono.snap_hand_to_hour(12)
	var previous := battle._enemy_chrono._center_hand_pivot.rotation
	await battle._enemy_chrono.snap_hand_to_hour(11)
	assert(battle._enemy_chrono._center_hand_pivot.rotation < previous)
	var losses: Array[bool] = []
	battle.combat_lost.connect(func() -> void: losses.append(true))
	battle.player_hp = 0
	assert(battle._check_combat_end())
	assert(battle._check_combat_end())
	await get_tree().create_timer(1.6 if battle._stage is DirectedArena else 0.9).timeout
	assert(losses.size() == 1)
	battle.queue_free()
	await get_tree().process_frame
	var rest = load("res://scenes/rest_site_screen.tscn").instantiate()
	add_child(rest)
	rest._on_upgrade_pressed()
	var forge: Control = GameFlow._active_deck_view_overlay
	assert(forge != null)
	forge._choose(int(RunManager.clock_inventory[0].uid))
	assert(forge._upgrade_preview != null)
	assert(not rest._resolved, "Preview must not spend the rest-site upgrade")
	forge._commit_upgrade(int(RunManager.clock_inventory[0].uid))
	assert(rest._resolved and rest._upgrade_button.disabled)
	rest._on_upgrade_pressed()
	assert(GameFlow._active_deck_view_overlay == null, "Rest grants only one upgrade")
	rest.queue_free()
	await get_tree().process_frame
	print("POLISH_INTEGRATION_OK: reserve deck, persistent upgrade, legacy migration, minimum reserve, shop affordability and duplicate purchase, ten enemy profiles, debuff, reinforcement, reverse hand, defeat once, one rest upgrade")
	get_tree().quit()
