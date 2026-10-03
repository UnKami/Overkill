extends Node


func _ready() -> void:
	AudioManager.set_master_volume(0.0)
	AudioManager.fast_mode = true
	RunManager.start_new_run([], [], 500, 40040)
	assert(ContentDatabase.get_clock_relic("REL-04").base_block == 7, "Guard Plate is strengthened for early survival")
	assert(ContentDatabase.get_clock_relic("REL-06").base_block == 10, "Reinforced Wall has a clear upgrade in defensive value")
	var artifacts: Array[RelicData] = []
	for artifact_id: String in ["artifact_aegis_seed", "artifact_ashen_ledger", "artifact_deepwell_suture", "artifact_verdigris_thorn", "artifact_cinder_dial", "artifact_tideward_clapper", "artifact_violet_weavers_shuttle", "artifact_gloam_moth"]:
		var artifact: RelicData = ContentDatabase.get_relic(artifact_id)
		assert(artifact != null, "Missing run-wide artifact: %s" % artifact_id)
		assert(RelicArt.load_texture(artifact.art_id) != null, "Missing transparent object art: %s" % artifact.art_id)
		assert(RelicArt.load_texture(artifact.art_id).get_image().detect_alpha() != Image.ALPHA_NONE, "Run artifact artwork must have transparent edges")
		artifacts.append(artifact)
	for ordinary_relic: RelicData in ContentDatabase.all_relics():
		assert(not ordinary_relic.id.begins_with("artifact_"), "Run-wide artifacts must not enter the ordinary relic reward pool")
	assert(RunManager.add_relic(artifacts[0]), "A unique artifact should be added")
	assert(not RunManager.add_relic(artifacts[0]), "An artifact cannot be owned twice")
	var saved: Dictionary = RunManager.to_save_dict()
	RunManager.start_new_run([], [], 500, 40041)
	RunManager.load_from_save(saved)
	assert(RunManager.relics_held.size() == 1 and RunManager.has_relic("artifact_aegis_seed"), "Run-wide artifacts must survive save/load")

	# Exercise the real shop builder and purchase path. It must leave all 12 clock
	# copies untouched while granting exactly one run-wide artifact per visit.
	RunManager.start_new_run([], [], 500, 40042)
	OKRunState.gain_ok(100, "artifact-shop-test")
	var shop := ClockCollectionScreen.new()
	shop.mode = "shop"
	add_child(shop)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(shop._grid.get_child_count() == 5, "Clockwright should continue to offer five clock relics")
	assert(shop._artifact_grid.get_child_count() == 3, "Clockwright should separately offer three unique artifacts")
	var inventory_scroll: ScrollContainer = shop.find_child("InventoryScroll", true, false) as ScrollContainer
	assert(inventory_scroll != null and inventory_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "Desktop shop must make the artifact row's scroll affordance visible")
	assert(shop._artifact_grid.get_child(0).get_child(3) is Button, "Each artifact must expose a direct purchase action")
	var offer_button_y: float = -1.0
	for offer: Control in shop._artifact_grid.get_children():
		var offer_button: Button = offer.get_child(3) as Button
		assert(offer_button != null and offer_button.visible, "Every Artifact offer must retain a visible purchase action")
		if offer_button_y < 0.0:
			offer_button_y = offer_button.global_position.y
		else:
			assert(is_equal_approx(offer_button_y, offer_button.global_position.y), "Artifact purchase actions should align in a single row")
	await _capture_if_rendered("artifact-shop-041")
	var picked: RelicData = shop._artifact_offers[0]
	shop._buy_artifact(picked, 30)
	assert(RunManager.clock_inventory.size() == 12, "Artifacts must never consume chronometer sockets")
	assert(RunManager.has_relic(picked.id) and RunManager.relics_held.size() == 1, "Artifact purchase should grant one run-wide item")
	assert(OKRunState.current_ok == 70 and shop._artifact_purchase_made, "Purchase should deduct its price and lock the visit to one artifact")
	shop.queue_free()
	await get_tree().process_frame

	# Verify combat-start wards, kill healing, qualifying Overkill and one-use
	# limits against the actual combat controller without waiting through a run.
	RunManager.start_new_run([], artifacts, 500, 40043)
	OKRunState.current_ok = 0
	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy := EnemyData.new()
	enemy.id = "artifact_test_target"
	enemy.max_hp = 100
	battle.start_combat([enemy])
	assert(battle.player_block == 8, "Aegis Seed should ward at battle start")
	assert(battle.enemy_weak == 1, "Verdigris Thorn should weaken the opening foe")
	await get_tree().process_frame
	await _capture_if_rendered("artifact-battle-041")
	battle.player_hp = 400
	battle.enemy_hp = 1
	battle.enemy_bleed = 1
	await battle._resolve_tick(1)
	assert(battle.player_hp == 412, "Deepwell Suture should restore missing Vitality when Bleed scores the first kill")
	assert(battle.player_strength == 2, "Violet Weaver's Shuttle should grant Strength on the first kill")
	assert(battle._artifact_triggered_this_combat.has("artifact_deepwell_suture"), "A Bleed kill must mark Deepwell Suture as used for the battle")
	battle.enemy_hp = 1
	battle._notify_enemy_killed(true)
	assert(battle.player_hp == 412 and battle.player_strength == 2, "Kill-trigger Artifacts must remain once-per-battle after a non-attack kill")
	battle.player_next_hit_bonus = 0
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_PLAYER_ATTACK)
	await get_tree().process_frame
	await _capture_if_rendered("artifact-activation-041")
	assert(battle.player_next_hit_bonus == 4, "Cinder Dial should empower the first attack")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_PLAYER_ATTACK)
	assert(battle.player_next_hit_bonus == 4, "Cinder Dial should trigger only once per battle")
	battle.player_hp = 400
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_BLOCK_GAIN)
	assert(battle.player_hp == 406, "Tideward Clapper should restore capped Vitality when Block is gained")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_BLOCK_GAIN)
	assert(battle.player_hp == 406, "Tideward Clapper should trigger only once per battle")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_PLAYER_HIT)
	assert(battle.enemy_weak == 3, "Gloam Moth should weaken the next foe attack, surviving status decay")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_PLAYER_HIT)
	assert(battle.enemy_weak == 3, "Gloam Moth should trigger only once per battle")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_OVERKILL, 7)
	assert(OKRunState.current_ok == 0, "Ashen Ledger should respect its Overkill threshold")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_OVERKILL, 8)
	assert(OKRunState.current_ok == 5, "Ashen Ledger should grant its run-wide bonus")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_OVERKILL, 20)
	assert(OKRunState.current_ok == 5, "Ashen Ledger should trigger only once per battle")
	battle.queue_free()
	await get_tree().process_frame
	var thorns_battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(thorns_battle)
	var thorns_enemy: EnemyData = ContentDatabase.get_enemy("boneghoul").duplicate()
	thorns_battle.start_combat([thorns_enemy])
	await get_tree().process_frame
	thorns_battle.player_hp = 400
	thorns_battle.enemy_hp = 1
	thorns_battle.player_sockets[0].slotted_relic = null
	thorns_battle.enemy_sockets[0].intent_damage = 1
	thorns_battle.player_thorns = 1
	await thorns_battle._resolve_tick(1)
	assert(thorns_battle.player_hp == 412, "Deepwell Suture should restore missing Vitality when Thorns scores the first kill")
	thorns_battle.queue_free()
	await get_tree().process_frame
	var death_artifacts: Array[RelicData] = [artifacts[2], artifacts[6]]
	await _verify_no_posthumous_healing(death_artifacts, false)
	await _verify_no_posthumous_healing(death_artifacts, true)
	print("RUN_ARTIFACTS_OK: eight unique artifacts, Bleed/Thorns kill triggers, no posthumous healing, save data, shop purchase, 12-slot separation, art, effects and trigger limits")
	get_tree().quit()


func _verify_no_posthumous_healing(artifacts: Array[RelicData], simultaneous_bleed: bool) -> void:
	RunManager.start_new_run([], artifacts, 500, 40044)
	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy: EnemyData = ContentDatabase.get_enemy("boneghoul").duplicate()
	battle.start_combat([enemy])
	await get_tree().process_frame
	battle.player_hp = 1 if simultaneous_bleed else 3
	battle.player_block = 0
	battle.enemy_hp = 1
	battle.player_sockets[0].slotted_relic = null
	battle.enemy_sockets[0].intent_damage = 0 if simultaneous_bleed else 4
	battle.enemy_sockets[0].intent_block = 0
	battle.player_thorns = 0 if simultaneous_bleed else 1
	battle.player_bleed = 1 if simultaneous_bleed else 0
	battle.enemy_bleed = 1 if simultaneous_bleed else 0
	await battle._resolve_tick(1)
	assert(battle.enemy_hp <= 0, "The lethal clash must still award the earned Thorns/Bleed kill")
	assert(battle.player_hp <= 0, "Deepwell Suture must never revive an already defeated player")
	assert(battle._combat_over, "A simultaneous lethal clash must finish as defeat")
	assert(battle.player_strength == 2, "Non-healing kill-trigger effects must still resolve once")
	for history_entry: String in battle._combat_history:
		assert(not history_entry.contains("HEAL"), "No healing may be reported after lethal damage")
	battle.queue_free()
	await get_tree().process_frame
	print("POSTHUMOUS_HEAL_GUARD_OK %s" % ("simultaneous_bleed" if simultaneous_bleed else "lethal_hit_and_thorns"))


func _capture_if_rendered(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var output_dir: String = ProjectSettings.globalize_path("res://.test-artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path: String = output_dir.path_join("%s.png" % label)
	assert(get_viewport().get_texture().get_image().save_png(output_path) == OK, "Capture %s for visual review" % label)
