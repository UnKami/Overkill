extends Node
## Isolated rendered acceptance fixture. No player save or live run is touched.
var _current: Node

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	AudioManager.set_master_volume(0.0)
	AudioManager.reduced_motion = true
	RunManager.start_new_run([], [], 75, 19031)
	var relic_view: RelicPedestalView = load("res://scenes/relic_pedestal_view.tscn").instantiate()
	await _show(relic_view)
	var tested_sunbursts: Dictionary = {}
	for relic: ClockRelicData in ContentDatabase.all_clock_relics(true):
		var sunburst_path: String = RelicPedestalView.essence_sunburst_path(relic)
		assert(not sunburst_path.is_empty() and ResourceLoader.exists(sunburst_path), "Missing essence sunburst for %s" % relic.affinity_name())
		relic_view.bind_relic(relic)
		var sunburst: TextureRect = relic_view.get_node("CardPanel/Margin/VBox/ArtFrame/EssenceSunburst") as TextureRect
		assert(sunburst.visible and sunburst.texture != null and sunburst.texture.resource_path == sunburst_path, "Selection art must match %s" % relic.affinity_name())
		assert(relic_view.get_node("CardPanel/Margin/VBox/ArtFrame").find_child("RelicLightStrokes", true, false) == null, "Deprecated rays must not show over the dedicated sunburst")
		assert(sunburst.texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Essence sunburst must preserve transparency")
		tested_sunbursts[sunburst_path] = true
	assert(tested_sunbursts.size() == 15, "All five single essences and ten dual pairings must have distinct halos")
	await _capture("relic-sunbursts")
	for scene_name: String in ["title_screen", "class_select_screen", "pre_battle_offer", "rest_site_screen", "reward_screen"]:
		var screen: Control = load("res://scenes/%s.tscn" % scene_name).instantiate()
		await _show(screen)
		if scene_name == "title_screen":
			var confirmation: ModalConfirmDialog = screen.get("_replace_confirmation") as ModalConfirmDialog
			var menu_column: Control = screen.get("_menu_column") as Control
			var center: CenterContainer = confirmation.get_node("CenterContainer")
			assert(is_equal_approx(center.anchor_left, 0.075) and is_equal_approx(center.anchor_right, 0.38), "Title confirmation must align to the established content column")
			menu_column.hide()
			confirmation.show()
			assert(not menu_column.visible and confirmation.visible, "Confirmation must fully replace, not overlap, menu choices")
			screen.call("_on_confirmation_cancelled")
			assert(menu_column.visible and not confirmation.visible, "Cancel must restore the title choices")
		await _capture(scene_name)
	for mode: String in ["shop", "collection", "upgrade"]:
		var inventory := preload("res://scripts/ui/clock_collection_screen.gd").new()
		inventory.mode = mode
		await _show(inventory)
		if mode == "collection":
			assert(inventory._grid.get_child_count() == RunManager.clock_inventory.size(), "Reliquary must show every owned relic copy independently")
			var identities: Dictionary = {}
			for copy_view: RelicPedestalView in inventory._grid.get_children():
				assert(copy_view.tooltip_text.contains("INSTANCE IDENTITIES"), "Every copy needs its own instance identity")
				identities[copy_view.tooltip_text] = true
			assert(identities.size() == RunManager.clock_inventory.size(), "Duplicate relic designs remain separate entries")
		if mode == "upgrade":
			assert(inventory._grid.get_child_count() == RunManager.clock_inventory.size(), "Forge must present every relic instance independently")
			var selected_uid: int = -1
			for copy_index: int in inventory._grid.get_child_count():
				var copy_view: RelicPedestalView = inventory._grid.get_child(copy_index) as RelicPedestalView
				assert(not copy_view._role_badge.text.contains("×") and not copy_view._role_badge.text.contains("OWNED"), "Forge must not collapse duplicate relics into a stack")
				assert(copy_view._role_badge.text.contains("COPY ") and copy_view._role_badge.text.contains(" / "), "Every forge tile visibly numbers its individual copy")
				assert(copy_view._slot_button.text.contains("COPY") or copy_view._slot_button.text.contains("UPGRADED"), "Each visible copy has its own ordinal/action")
				if selected_uid < 0 and not copy_view._slot_button.disabled:
					selected_uid = int(RunManager.clock_inventory[copy_index].get("uid", -1))
			assert(selected_uid >= 0, "Forge fixture has an eligible instance")
			inventory._choose(selected_uid)
			await get_tree().process_frame
			var preview: UpgradePreviewDialog = inventory._upgrade_preview
			var dimmer: ColorRect = preview.get_node("Dimmer") as ColorRect
			# The merged UI direction uses one readable veil, preserving the Forge
			# scenery while the opaque comparison panel owns the decision.
			assert(dimmer.color.a >= 0.5 and dimmer.color.a <= 0.66 and preview.get_node("BackgroundButton").get_index() < dimmer.get_index(), "Upgrade confirmation uses one moderate veil above its transparent click catcher")
			assert(is_zero_approx((preview.get_node("BackgroundButton") as Button).self_modulate.a), "The click catcher must not add a second darkening layer")
			await _capture("upgrade-confirmation-focused")
			preview.queue_free()
		await _capture(mode)
	for event: EventData in EventCatalog.get_all_events():
		var event_screen: Control = load("res://scenes/event_screen.tscn").instantiate()
		event_screen.set_event(event)
		await _show(event_screen)
		if event.id == "greedy_shrine":
			assert(event_screen._choice_box.get_child_count() == event.choices.size() * 2, "Every shrine choice has a visible consequence line")
			assert(event_screen._choice_box.get_child(1).text.contains("Chronometer full"), "A full clock explains why relic bargains are unavailable")
		await _capture(event.id)
	var altar: Control = load("res://scenes/boss_overkill_altar.tscn").instantiate()
	await _show(altar)
	var offer_panel: PanelContainer = altar.get_node("AltarOfferPanel")
	var offer_style: StyleBoxFlat = offer_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(offer_style.bg_color.a < 0.9, "Zenith composition must let the scenic altar artwork show through")
	var zenith_cards: HBoxContainer = altar.get_node("AltarOfferPanel/VBoxContainer/ZenithOffers") if altar.has_node("AltarOfferPanel/VBoxContainer/ZenithOffers") else altar.find_child("ZenithOffers", true, false) as HBoxContainer
	assert(zenith_cards != null and zenith_cards.get_child_count() == 3, "All Zenith offers remain visible over the lighter panel")
	assert(absf(offer_panel.get_global_rect().get_center().x - altar.get_global_rect().get_center().x) < 2.0, "The consequential altar choice is centered in the viewport")
	assert(altar._balance_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and altar._status_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Altar balance and ritual status are composed around the central focal axis")
	assert(zenith_cards.alignment == BoxContainer.ALIGNMENT_CENTER, "Zenith choices are symmetrically centered")
	await _capture("zenith-altar")
	for act: int in range(1, 4):
		RunManager.act_number = act
		await _show(load("res://scenes/map_screen.tscn").instantiate())
		await _capture("map-act-%d" % act)
		var transition: Control = load("res://scenes/act_transition_screen.tscn").instantiate()
		transition.configure(CinematicArt.transition_background(act), ["THE LUMINOUS REFINERY", "THE FRACTURED HORIZON", "THE FINAL CONVERGENCE"][act - 1], Callable())
		await _show(transition)
		await _capture("transition-%d" % act)
	for won: bool in [true, false]:
		var summary: Control = load("res://scenes/run_summary_screen.tscn").instantiate()
		summary.set_outcome(won)
		await _show(summary)
		await _capture("victory" if won else "defeat")
	for enemy_id: String in ["boneghoul", "act1_elite", "act1_boss", "act2_trash", "act2_elite", "act2_boss", "act3_trash", "act3_elite", "act3_boss", "final_boss"]:
		RunManager.act_number = 1 if enemy_id == "boneghoul" or enemy_id.begins_with("act1") else (2 if enemy_id.begins_with("act2") else 3)
		var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
		await _show(battle)
		var enemy: EnemyData = ContentDatabase.get_enemy(enemy_id)
		assert(enemy != null)
		battle.start_combat([enemy])
		await get_tree().create_timer(0.6).timeout
		var stage: IllustratedStage = battle._stage
		assert(battle._player_portrait.texture == null and battle._enemy_portrait.texture == null, "Telemetry must not draw a second duplicate combatant")
		for pair: Array in [[stage.player, battle._player_stats_label], [stage.enemy, battle._enemy_stats_label]]:
			var actor: IllustratedActor = pair[0]
			var stats: Label = pair[1]
			var art_rect: Rect2 = actor._front.get_global_rect()
			assert(art_rect.position.y + 4.0 >= battle._choice_overlay.get_global_rect().end.y, "Fighters must remain below the choices")
			assert(absf(actor.global_position.x + actor.size.x * 0.5 - stats.get_global_rect().get_center().x) < 1.0, "HP centered below its combatant")
			var portrait: Control = battle._player_portrait if actor == stage.player else battle._enemy_portrait
			assert(art_rect.end.y < portrait.get_node("CharacterStatusPanel").get_global_rect().position.y, "Combatant stats must sit below enlarged character art")
		await _capture(enemy_id)
	if is_instance_valid(_current):
		_current.queue_free()
	await get_tree().process_frame
	print("CRYSTALLINE_VISUAL_OK: production screens, three maps/transitions and all ten enemies rendered")
	get_tree().quit()

func _show(node: Node) -> void:
	if is_instance_valid(_current):
		_current.queue_free()
		await get_tree().process_frame
	_current = node
	add_child(node)
	await get_tree().create_timer(0.45).timeout

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://crystalline-031")
	get_viewport().get_texture().get_image().save_png("user://crystalline-031/%s.png" % label)

