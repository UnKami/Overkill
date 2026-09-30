extends Node
## Integration coverage for persistent inventory, economy, encounters and settings.
var battle: CombatController

func _ready() -> void:
	AudioManager.set_master_volume(0.0)
	RunManager.start_new_run([], [], 80, 1729)
	assert(RunManager.clock_inventory.size() == 12)
	var original := ClockInventory.resolve(RunManager.clock_inventory[0])
	assert(RunManager.upgrade_clock_relic(0))
	assert(not RunManager.upgrade_clock_relic(0))
	assert(ClockInventory.resolve(RunManager.clock_inventory[0]).base_damage == original.base_damage + 3)
	assert(ContentDatabase.get_clock_relic(original.id).base_damage == original.base_damage, "Upgrade must not mutate shared content")
	SaveManager.save_run()
	RunManager.clock_inventory.clear()
	RunManager.load_from_save(SaveManager.load_run())
	assert(RunManager.clock_inventory.size() == 12)
	assert(int(RunManager.clock_inventory[0].level) == 1)
	RunManager.load_from_save({"current_hp": 70, "max_hp": 75, "deck": []})
	assert(RunManager.clock_inventory.size() == 12, "Legacy save gets usable inventory")
	assert(RunManager.max_hp == 500 and RunManager.current_hp == 467, "Legacy vitality migrates proportionally to the new 500 HP baseline: %d/%d" % [RunManager.current_hp, RunManager.max_hp])
	assert(RunManager.remove_clock_relic(0))
	assert(RunManager.remove_clock_relic(1))
	assert(not RunManager.remove_clock_relic(2), "Cannot remove the minimum reserve")
	RunManager.start_new_run([], [], 80, 1729)
	var shop := preload("res://scripts/ui/clock_collection_screen.gd").new()
	shop.mode = "shop"
	add_child(shop)
	var offered: ClockRelicData = shop._offers[0]
	OKRunState.current_ok = 14
	shop._buy(offered, 15)
	assert(RunManager.clock_inventory.size() == 12)
	OKRunState.current_ok = 30
	shop._buy(offered, 15)
	shop._buy(offered, 15)
	assert(RunManager.clock_inventory.size() == 12)
	assert(OKRunState.current_ok == 30, "A full chronometer cannot silently gain or pay for a thirteenth relic")
	assert(not RunManager.add_clock_relic("REL-01"), "Inventory capacity is capped at twelve")
	assert(RunManager.replace_clock_relic(0, "REL-02"), "Replacement swaps the selected physical copy")
	assert(RunManager.clock_inventory.size() == 12)
	var replaced: Dictionary = RunManager.clock_inventory[0]
	assert(int(replaced.uid) >= 12 and str(replaced.id) == "REL-02" and int(replaced.level) == 0)
	assert(RunManager.upgrade_clock_relic(int(replaced.uid)))
	assert(ClockInventory.instance_identity(replaced).contains("UPGRADED"), "Upgraded copy exposes its stable unique identity")
	shop.queue_free()
	var patterns: Dictionary = {}
	for id in ["boneghoul", "act1_elite", "act1_boss", "act2_trash", "act2_elite", "act2_boss", "act3_trash", "act3_elite", "act3_boss", "final_boss"]:
		var enemy := ContentDatabase.get_enemy(id)
		assert(enemy != null)
		var sockets := EnemyClockPattern.create(enemy)
		assert(sockets.size() == 9)
		assert(not sockets[0].intent_label.is_empty())
		patterns[EnemyClockPattern.profile(enemy)] = true
	assert(patterns.size() == 10)
	for boss_id: String in ["act1_boss", "act2_boss", "act3_boss", "final_boss"]:
		assert(ContentDatabase.get_enemy(boss_id).max_hp == 100, "All progression bosses use the requested 100 HP tuning")
	assert(EnemyClockPattern.hour_for(1, ContentDatabase.get_enemy("act2_boss")) == 9)
	assert(EnemyClockPattern.hour_for(9, ContentDatabase.get_enemy("act2_boss")) == 1)
	assert(EnemyClockPattern.has_twin(ContentDatabase.get_enemy("act3_boss")))
	RunManager.start_new_run([], [], 80, 1729)
	var reward_screen: Control = load("res://scenes/reward_screen.tscn").instantiate()
	add_child(reward_screen)
	await get_tree().process_frame
	reward_screen.call("_on_relic_chosen", ContentDatabase.get_clock_relic("REL-02"))
	var replacement_grid: GridContainer = reward_screen.get_node("%ChoiceRow")
	assert(replacement_grid.get_child_count() == ClockInventory.MAX_SIZE, "A full run displays one explicit replacement target for every owned relic")
	var displayed_copies: Dictionary = {}
	for replacement: Button in replacement_grid.get_children():
		assert(replacement.tooltip_text.contains("COPY #"))
		displayed_copies[replacement.text.get_slice("\n", 1)] = true
	assert(displayed_copies.size() == ClockInventory.MAX_SIZE, "Replacement picker identifies each individual copy")
	reward_screen.queue_free()
	await get_tree().process_frame
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var first: EnemyData = ContentDatabase.get_enemy("act1_elite").duplicate()
	var second: EnemyData = ContentDatabase.get_enemy("act2_boss").duplicate()
	first.max_hp = 500
	second.max_hp = 500
	battle.start_combat([first, second])
	assert(battle._player_portrait.has_node("CoreStatStrip"))
	assert(battle._player_portrait.has_node("StatusIconStrip"))
	assert(battle._player_stats_label.text.contains("/"), "Vitality stays numeric and compact rather than wrapping stat names")
	await battle._resolve_tick(1)
	battle.player_strength = 3
	battle.player_weak = 1
	battle._update_stats_display()
	assert(battle._player_status_strip.get_child_count() == 2, "Active combat modifiers render as icon/value chips")
	assert(not battle._player_status_strip.get_child(0).tooltip_text.is_empty(), "Status icons expose hover explanations")
	assert(battle.player_weak == 1, "Enemy weakening intent must resolve and decay")
	battle.enemy_hp = 0
	assert(not battle._check_combat_end())
	assert(battle._enemy_index == 1 and battle.enemy_hp == 500)
	assert(battle._enemy_chrono.rotation_direction == -1)
	await battle._enemy_chrono.snap_hand_to_hour(9)
	var previous := battle._enemy_chrono._center_hand_pivot.rotation
	await battle._enemy_chrono.snap_hand_to_hour(8)
	assert(battle._enemy_chrono._center_hand_pivot.rotation < previous)
	var losses: Array[bool] = []
	battle.combat_lost.connect(func() -> void: losses.append(true))
	battle.player_hp = 0
	assert(battle._check_combat_end())
	assert(battle._check_combat_end())
	await get_tree().create_timer(1.8).timeout
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
	# Relic upgrades now resolve only after the 1.5-second old-to-new animation.
	await get_tree().create_timer(1.65).timeout
	assert(rest._resolved and rest._upgrade_button.disabled)
	rest._on_upgrade_pressed()
	assert(GameFlow._active_deck_view_overlay == forge and forge._committed, "Resolved rest site must not open a second upgrade")
	forge._upgrade_preview._on_confirm_pressed()
	assert(GameFlow._active_deck_view_overlay == null, "Completed upgrade returns to the journey")
	rest.queue_free()
	await get_tree().process_frame
	print("POLISH_INTEGRATION_OK: 12-copy cap and replacement, unique upgraded copy, legacy HP migration, boss tuning, shop affordability, ten enemy profiles, debuff, reinforcement, reverse hand, defeat once, one rest upgrade")
	get_tree().quit()
