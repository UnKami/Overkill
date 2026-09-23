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
	assert(class_text.has("STANDART BATTLE   ›"))
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
	assert(selector._views.size() == 1)
	var card_view: CardView = selector._views[0]
	var base_card: CardData = card_view.get_card()
	selector._select(base_card, card_view, base_card)
	await get_tree().create_timer(0.65).timeout
	assert(RunManager.deck[0].upgrade_level == 1)
	assert(card_view.get_card().upgrade_level == 1)
	assert(card_view._background_style.border_width_left == 3)
	selector.queue_free()

	var transition: ScreenTransition = ScreenTransition.new()
	add_child(transition)
	await transition.play_cover("BATTLE")
	assert(float(transition._material.get_shader_parameter("progress")) > 1.0)
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
	campaign_boss.prepare_combat([ContentDatabase.get_enemy("act1_boss")])
	assert(campaign_boss._stage.get_script().resource_path == "res://scripts/combat/illustrated_stage.gd", "Campaign bosses must preserve the player's illustrated identity")
	campaign_boss.queue_free()
	print("BATTLE_ARRIVAL_OK: clean entry screens, three-choice offer, card transform, vortex, character HUD, cohesive 2D campaign bosses, gated intro and 14-damage hammer presentation")
	get_tree().quit()
