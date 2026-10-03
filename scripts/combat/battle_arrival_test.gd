extends Node
## Deterministic integration coverage for navigation/presentation work. This
## checks state ownership and damage invariants; rendered review is separate.


func _ready() -> void:
	AudioManager.set_master_volume(0.0)
	AudioManager.fast_mode = true
	AudioManager.reduced_motion = true
	var strike: CardData = ContentDatabase.get_card("strike")
	RunManager.start_new_run([strike], [], 75, 923)
	assert(RunManager.should_offer_pre_battle())
	var saved_before: Dictionary = RunManager.to_save_dict()
	assert(saved_before.map.pre_battle_offer_acts.is_empty())

	var class_select: Control = load("res://scenes/class_select_screen.tscn").instantiate()
	add_child(class_select)
	await get_tree().process_frame
	var class_text: PackedStringArray = []
	for node: Node in class_select.find_children("*", "Label", true, false): class_text.append(node.text)
	for node: Node in class_select.find_children("*", "Button", true, false): class_text.append(node.text)
	assert(class_text.has("BEGIN THE ASCENT   ›"))
	assert(not "75" in class_text and not "VITALITY" in class_text and not "CLOCK SLOTS" in class_text and not "RESERVES" in class_text)
	assert(not "BIND THE HOURS. BREAK THE CYCLE." in class_text)
	class_select.queue_free()

	var collection := preload("res://scripts/ui/clock_collection_screen.gd").new()
	collection.mode = "collection"
	add_child(collection)
	await get_tree().process_frame
	var relic_cards := collection.find_children("*", "RelicPedestalView", true, false)
	assert(not relic_cards.is_empty())
	for view: RelicPedestalView in relic_cards: assert(not view._slot_button.visible)
	collection.queue_free()

	var offer: PreBattleOfferScreen = load("res://scenes/pre_battle_offer.tscn").instantiate()
	add_child(offer)
	await get_tree().process_frame
	assert(offer._cards.size() == 3 and offer._buttons.size() == 3)
	offer.queue_free()

	var selector: CardUpgradeSelection = load("res://scenes/card_upgrade_selection.tscn").instantiate()
	add_child(selector)
	await get_tree().process_frame
	assert(selector.mode == "upgrade" and selector.pre_battle)
	assert(selector.find_children("*", "CardView", true, false).is_empty())
	var relic_uid: int = int(RunManager.clock_inventory[0].uid)
	selector._choose(relic_uid)
	assert(is_instance_valid(selector._upgrade_preview))
	selector._commit_upgrade(relic_uid)
	await get_tree().create_timer(1.65).timeout
	assert(int(RunManager.clock_inventory[0].level) == 1)
	assert(RunManager.deck[0].upgrade_level == 0, "The offer upgrades a combat relic, not the unused legacy deck")
	selector.queue_free()

	var transition: ScreenTransition = ScreenTransition.new()
	add_child(transition)
	await transition.play_cover("BATTLE")
	assert(transition._progress >= 0.99, "The chronometer curtain should cover the outgoing scene")
	await transition.play_reveal()

	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy := EnemyData.new()
	enemy.id = "boneghoul"
	enemy.display_name = "The Hollow Warden"
	enemy.max_hp = 200
	battle.prepare_combat([enemy])
	assert(not battle._phase_started)
	assert(battle._player_stats_label.get_parent() == battle._player_portrait)
	assert(battle._enemy_stats_label.get_parent() == battle._enemy_portrait)
	assert(battle._player_portrait.get_node("Vitality").get_parent() == battle._player_portrait)
	assert(battle._player_chrono.anchor_left < 0.14 and battle._enemy_chrono.anchor_left > 0.86)
	await battle.begin_combat_intro()
	assert(battle._phase_started and battle._choice_overlay.visible)
	assert(battle._player_portrait.get_node("Vitality").value == battle.player_hp)
	assert(battle._enemy_portrait.get_node("Vitality").value == battle.enemy_hp)

	var hammer: ClockRelicData = ContentDatabase.get_clock_relic("REL-03")
	assert(hammer != null and hammer.base_damage == 14)
	var hammer_socket := ClockSocketData.new()
	hammer_socket.hour_index = 1
	hammer_socket.slotted_relic = hammer
	var hp_before: int = battle.enemy_hp
	await battle._apply_damage_to_enemy(hammer.base_damage, hammer_socket)
	assert(battle.enemy_hp == hp_before - 14, "Heavy Hammer presentation must not change its 14 damage")
	assert(AttackPresentation.is_heavy_hammer(AttackPresentation.for_relic(hammer)))

	RunManager.mark_pre_battle_offer_seen()
	assert(not RunManager.should_offer_pre_battle())
	assert(RunManager.to_save_dict().map.pre_battle_offer_acts.has(1))
	battle.queue_free()
	var campaign_boss: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(campaign_boss)
	var final_boss: EnemyData = ContentDatabase.get_enemy("final_boss")
	campaign_boss.prepare_combat([final_boss])
	await campaign_boss.begin_combat_intro()
	assert(campaign_boss._stage.get_script().resource_path == "res://scripts/combat/illustrated_stage.gd", "Campaign bosses must preserve the player's illustrated identity")
	var expected_final_art: String = "res://assets/enemies/final_boss_crystal_warden.png"
	assert((campaign_boss._stage as IllustratedStage).enemy.atlas.resource_path == expected_final_art, "Final-boss battlefield art must use the distinct non-humanoid enemy")
	assert(campaign_boss._enemy_portrait.texture == null and campaign_boss._player_portrait.texture == null, "The animated stage is the only fighter rendering layer")
	assert(campaign_boss._background.texture.resource_path == "res://assets/environments/cinematic/act3_final_convergence.jpg", "Final boss combat must use the matching crystalline convergence arena")
	var final_boss_image: Image = (campaign_boss._stage as IllustratedStage).enemy.atlas.get_image()
	assert(final_boss_image != null and final_boss_image.get_pixel(0, 0).a < 0.05, "The final-boss sprite must remain a clean transparent cutout")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var audit_folder: String = ProjectSettings.globalize_path("user://visual-audit")
		DirAccess.make_dir_recursive_absolute(audit_folder)
		get_viewport().get_texture().get_image().save_png(audit_folder.path_join("final-boss-battle.png"))
	campaign_boss.queue_free()
	print("BATTLE_ARRIVAL_OK: relic-only offer and upgrade, illustrated transition, character HUD, cohesive 2D campaign bosses, gated intro and unchanged 14-damage hammer")
	get_tree().quit()
