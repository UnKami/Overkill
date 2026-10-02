extends Node


func _ready() -> void:
	AudioManager.set_master_volume(0.0)
	AudioManager.fast_mode = true
	RunManager.start_new_run([], [], 500, 40040)
	assert(ContentDatabase.get_clock_relic("REL-04").base_block == 7, "Guard Plate is strengthened for early survival")
	assert(ContentDatabase.get_clock_relic("REL-06").base_block == 10, "Reinforced Wall has a clear upgrade in defensive value")
	var artifacts: Array[RelicData] = []
	for artifact_id: String in ["artifact_aegis_seed", "artifact_ashen_ledger", "artifact_deepwell_suture", "artifact_verdigris_thorn"]:
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
	await _capture_if_rendered("artifact-shop-040")
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
	await _capture_if_rendered("artifact-battle-040")
	battle.player_hp = 400
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_KILL)
	assert(battle.player_hp == 412, "Deepwell Suture should restore 12 missing Vitality on first kill")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_KILL)
	assert(battle.player_hp == 412, "Deepwell Suture must trigger only once per battle")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_OVERKILL, 7)
	assert(OKRunState.current_ok == 0, "Ashen Ledger should respect its Overkill threshold")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_OVERKILL, 8)
	assert(OKRunState.current_ok == 5, "Ashen Ledger should grant its run-wide bonus")
	battle._apply_run_artifact_trigger(RelicData.Trigger.ON_OVERKILL, 20)
	assert(OKRunState.current_ok == 5, "Ashen Ledger should trigger only once per battle")
	battle.queue_free()
	print("RUN_ARTIFACTS_OK: unique save data, shop purchase, 12-slot separation, art and four combat triggers")
	get_tree().quit()


func _capture_if_rendered(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var output_dir: String = ProjectSettings.globalize_path("res://.test-artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var output_path: String = output_dir.path_join("%s.png" % label)
	assert(get_viewport().get_texture().get_image().save_png(output_path) == OK, "Capture %s for visual review" % label)
