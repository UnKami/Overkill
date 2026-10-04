extends Node
## Release evidence fixture. Must run with isolated APPDATA, never player saves.
## -- --audit-preset=1080-normal (or 1080-large, 720-normal, 720-large)
## Optional --audit-focus=map-forge refreshes navigation, maps and inventory/rest.
## Screenshots are evidence for a separate visual review, not visual approval.

const OUTPUT: String = "res://.test-artifacts/042/screens"
const ENEMIES: Array[String] = ["boneghoul", "act1_elite", "act1_boss", "act2_trash", "act2_elite", "act2_boss", "act3_trash", "act3_elite", "act3_boss", "final_boss"]
var _preset: String = "1080-normal"
var _focus: String = "all"
var _captures: Array[Dictionary] = []
var _checks: Array[Dictionary] = []
var _failures: Array[String] = []
var _started: int = 0
var _finished: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var profile: String = OS.get_environment("APPDATA").replace("\\", "/").to_lower()
	if not profile.contains("/.tools/042-audit-profile"):
		push_error("RELEASE_SCREEN_AUDIT_REFUSED: APPDATA must be inside .tools/042-audit-profile")
		get_tree().quit(2)
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--audit-preset="):
			_preset = argument.trim_prefix("--audit-preset=")
		if argument.begins_with("--audit-focus="):
			_focus = argument.trim_prefix("--audit-focus=")
	if not _preset in ["1080-normal", "1080-large", "720-normal", "720-large"]:
		get_tree().quit(2)
		return
	if not _focus in ["all", "map-forge"]:
		get_tree().quit(2)
		return
	_started = Time.get_ticks_msec()
	await get_tree().process_frame
	get_tree().current_scene = null
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720) if _preset.begins_with("720") else Vector2i(1920, 1080)
	AudioManager.set_master_volume(0.0)
	AudioManager.reduced_motion = true
	AudioManager.fast_mode = false
	AudioManager.set_text_size("large" if _preset.ends_with("large") else "normal")
	SaveManager.delete_run_save()
	await _title_and_navigation()
	await _maps()
	await _inventory_and_rest()
	if _focus == "all":
		await _events()
		await _rewards_and_altar()
		await _combat_and_overlays()
		await _outcomes()
	await _clear_scene()
	_finished = true
	_write_manifest()
	if _failures.is_empty():
		print("RELEASE_SCREEN_AUDIT_OK: %s; %d captures; %d checks; visual review still required" % [_preset, _captures.size(), _checks.size()])
	else:
		push_error("RELEASE_SCREEN_AUDIT_FAILED: %s; %s" % [_preset, "; ".join(_failures)])
	get_tree().quit(0 if _failures.is_empty() else 1)


func _title_and_navigation() -> void:
	GameFlow.goto_title()
	await _settle()
	var title: Control = get_tree().current_scene as Control
	_check(not title._continue_button.visible, "No Continue action without a save")
	await _capture("title-new")
	title._new_run_button.pressed.emit()
	await _settle()
	_check(get_tree().current_scene.name == "ClassSelectScreen", "New journey opens class selection")
	await _capture("class-select")
	get_tree().current_scene._start_button.pressed.emit()
	await _settle()
	_check(RunManager.current_hp == RunManager.max_hp and RunManager.clock_inventory.size() == 12, "Starting journey uses current class Vitality and twelve owned relics")
	_check(get_tree().current_scene is CogMapScreen, "A new journey opens the cog map")
	await _capture("new-journey-map")
	GameFlow.goto_title()
	await _settle()
	title = get_tree().current_scene as Control
	_check(title._continue_button.visible, "Saved journey exposes Continue")
	await _capture("title-continue")
	title._new_run_button.pressed.emit()
	_check(title._replace_confirmation.visible and not title._menu_column.visible, "New journey confirmation replaces title actions")
	await _capture("title-replace-confirmation")
	title._replace_confirmation._on_cancel()
	_check(title._menu_column.visible, "Cancelling replacement restores title actions")
	title._continue_button.pressed.emit()
	await _settle()
	_check(get_tree().current_scene is CogMapScreen, "Continue resumes a saved cog journey")
	await _capture("continued-map")
	for offer_index: int in 3:
		_reset_run()
		var offer: PreBattleOfferScreen = load("res://scenes/pre_battle_offer.tscn").instantiate()
		await _show(offer)
		await _capture("prebattle-choice-%d" % offer_index)
		var before_ok: int = OKRunState.current_ok
		var before_max_hp: int = RunManager.max_hp
		var resolved: Array[String] = []
		offer.resolved.connect(func(effect: String) -> void: resolved.append(effect))
		offer._buttons[offer_index].pressed.emit()
		await get_tree().create_timer(1.0).timeout
		_check(offer._committed, "Prebattle option %d commits once" % offer_index)
		if offer_index == 0:
			_check(resolved == ["upgrade_relic"], "Prebattle forge choice requests instance selector")
		elif offer_index == 1:
			_check(OKRunState.current_ok == before_ok + 10, "Prebattle spark grants ten Overkill")
		else:
			_check(RunManager.max_hp == before_max_hp + 3, "Prebattle frame grants three maximum Vitality")
		await _capture("prebattle-result-%d" % offer_index)


func _maps() -> void:
	for act: int in range(1, 4):
		_reset_run()
		RunManager.act_number = act
		var cog: CogMapScreen = load("res://scenes/cog_map_screen.tscn").instantiate()
		await _show(cog)
		_check(cog._gear_surfaces.size() == 16 and not cog._advance_button.disabled, "Act %d cog route has the sixteen-gear concept diamond and an actionable arrival" % act)
		await _capture("cog-act-%d-entrance" % act)
		var first: MapGenerator.MapNode = (cog._gears[cog._selected_gear_id] as CogNavigationGenerator.Gear).seats[0]
		RunManager.commit_map_node(first.id)
		var resumed: CogMapScreen = load("res://scenes/cog_map_screen.tscn").instantiate()
		await _show(resumed)
		_check(resumed._reachable_gears.size() == 2 and resumed._current_node.id == first.id, "Act %d cog resume restores landing and two onward choices" % act)
		resumed._on_gear_selected(resumed._reachable_gears[1])
		await _capture("cog-act-%d-branches" % act)
		resumed._scroll.scroll_vertical = 0
		await _capture("cog-act-%d-guardian" % act)
		RunManager.current_node_id = ""
		RunManager.visited_nodes.clear()
		var legacy: Control = load("res://scenes/map_screen.tscn").instantiate()
		await _show(legacy)
		_check(not legacy._reachable.is_empty(), "Legacy act %d map has selectable destinations" % act)
		await _capture("legacy-map-act-%d" % act)
		if act == 1:
			RunManager.current_node_id = str(legacy._reachable[0])
			SaveManager.save_run()
			GameFlow.goto_map()
			await _settle()
			_check(not get_tree().current_scene is CogMapScreen, "Legacy saved node routes to its original map")


func _inventory_and_rest() -> void:
	_reset_run()
	GameFlow.goto_shop()
	await _settle()
	var shop: ClockCollectionScreen = get_tree().current_scene as ClockCollectionScreen
	_check(shop._artifact_offers.size() == 3, "Shop exposes three unique run-wide artifact offers")
	await _capture("shop-clock-relics")
	var scroll: ScrollContainer = shop.find_child("InventoryScroll", true, false) as ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await _capture("shop-artifacts")
	var artifact: RelicData = shop._artifact_offers[0]
	var artifact_offer: Node = shop._artifact_grid.get_child(0)
	(artifact_offer.get_child(artifact_offer.get_child_count() - 1) as Button).pressed.emit()
	_check(RunManager.has_relic(artifact.id) and shop._artifact_purchase_made, "Shop artifact purchase grants the selected run-wide item")
	await _capture("shop-artifact-purchased")
	for mode: String in ["collection", "upgrade", "removal"]:
		_reset_run()
		var inventory := ClockCollectionScreen.new()
		inventory.mode = mode
		await _show(inventory)
		await _capture("inventory-" + mode)
		_check(inventory._grid.get_child_count() == RunManager.clock_inventory.size(), "%s presents every individual relic copy" % mode)
		if mode == "upgrade":
			var uid: int = int(RunManager.clock_inventory[0].uid)
			inventory._choose(uid)
			await _capture("forge-preview")
			var preview: UpgradePreviewDialog = inventory._upgrade_preview
			_check(preview != null and preview.visible, "Forge exposes upgrade consequences before commitment")
			preview._confirm_button.pressed.emit()
			await get_tree().create_timer(1.8).timeout
			_check(int(RunManager.clock_inventory[0].level) == 1, "Forge upgrades the selected physical copy")
			await _capture("forge-upgraded")
	for full: bool in [true, false]:
		_reset_run()
		if not full: RunManager.current_hp = RunManager.max_hp - 100
		GameFlow.goto_rest_site()
		await _settle()
		var rest: Control = get_tree().current_scene as Control
		_check(rest._rest_button.disabled == full, "Rest availability matches full Vitality = %s" % full)
		await _capture("rest-full" if full else "rest-injured")
		var before_hp: int = RunManager.current_hp
		rest._on_rest_pressed()
		_check(RunManager.current_hp == before_hp and not rest._resolved if full else RunManager.current_hp > before_hp and rest._resolved, "Rest heals once or preserves full-health visit")
		await _capture("rest-full-guard" if full else "rest-healed")


func _events() -> void:
	for event: EventData in EventCatalog.get_all_events():
		_reset_run()
		GameFlow.goto_event(event)
		await _settle()
		await _capture("event-%s-full-clock" % event.id)
		for index: int in event.choices.size():
			_reset_run()
			RunManager.current_hp -= 100
			RunManager.clock_inventory.pop_back()
			GameFlow.goto_event(event)
			await _settle()
			var screen: Control = get_tree().current_scene as Control
			var choice: EventData.EventChoice = event.choices[index]
			var before_hp: int = RunManager.current_hp
			var before_ok: int = OKRunState.current_ok
			var before_count: int = RunManager.clock_inventory.size()
			await _capture("event-%s-choice-%d" % [event.id, index])
			var button: Button = screen._choice_box.get_child(index * 2) as Button
			_check(not button.disabled, "%s choice %d available with sufficient resources and room" % [event.id, index])
			button.pressed.emit()
			await _settle()
			_check(get_tree().current_scene is CogMapScreen, "%s choice %d returns to the journey" % [event.id, index])
			var expected_hp: int = before_hp - choice.hp_cost + (choice.value if choice.effect_type == EventData.ChoiceEffectType.HP_DELTA else 0)
			var expected_ok: int = before_ok - choice.ok_cost + (choice.value if choice.effect_type == EventData.ChoiceEffectType.OK_DELTA else 0)
			_check(RunManager.current_hp == expected_hp and OKRunState.current_ok == expected_ok, "%s choice %d applies its visible resource consequences" % [event.id, index])
			_check(RunManager.clock_inventory.size() == before_count + (1 if choice.effect_type == EventData.ChoiceEffectType.GRANT_CLOCK_RELIC else 0), "%s choice %d applies its visible inventory consequence" % [event.id, index])


func _rewards_and_altar() -> void:
	_reset_run()
	GameFlow.goto_reward_screen({"enemy_data": ContentDatabase.get_enemy("boneghoul")})
	await _settle()
	var reward: Control = get_tree().current_scene as Control
	await _capture("reward-offers")
	var offered: RelicPedestalView = reward._choice_row.get_child(0) as RelicPedestalView
	offered.selected.emit(offered.relic)
	await _capture("reward-replacement")
	_check(reward._choice_row.get_child_count() == 12, "Full-clock reward presents twelve exact replacement targets")
	reward._show_relic_offers()
	_check(reward._choice_row.get_child_count() == 3, "Reward back action restores offers without losing inventory")
	offered = reward._choice_row.get_child(0) as RelicPedestalView
	var reward_id: String = offered.relic.id
	offered.selected.emit(offered.relic)
	(reward._choice_row.get_child(0) as Button).pressed.emit()
	await _settle()
	_check(RunManager.clock_inventory.size() == 12 and str(RunManager.clock_inventory[0].id) == reward_id, "Reward replaces one chosen copy and keeps roster size")
	GameFlow.goto_treasure(25, ContentDatabase.all_relics()[0])
	await _settle()
	await _capture("treasure")
	_reset_run()
	GameFlow.goto_boss_overkill_altar(ContentDatabase.get_enemy("act1_boss"))
	await _settle()
	var altar: BossOverkillAltar = get_tree().current_scene as BossOverkillAltar
	await _capture("altar-offers")
	altar._open_purchase("REL-29")
	await _capture("altar-replacement")
	_check(not altar._main_panel.visible and altar._replacement_grid.get_child_count() == 12, "Altar replacement occupies its own screen and identifies every copy")
	var balance: int = OKRunState.current_ok
	altar._cancel_purchase()
	_check(OKRunState.current_ok == balance and altar._main_panel.visible, "Cancelling altar purchase spends nothing")
	altar._open_purchase("REL-29")
	(altar._replacement_grid.get_child(0) as Button).pressed.emit()
	await _capture("altar-selected-replacement")
	altar._confirm_button.pressed.emit()
	_check(altar._purchased and OKRunState.current_ok < balance and RunManager.clock_inventory.size() == 12, "Altar confirmation spends currency and replaces exactly one relic")
	await _capture("altar-purchased")


func _combat_and_overlays() -> void:
	for enemy_id: String in ENEMIES:
		_reset_run()
		RunManager.act_number = 1 if enemy_id == "boneghoul" or enemy_id.begins_with("act1") else (2 if enemy_id.begins_with("act2") else 3)
		var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
		await _show(battle)
		var enemy: EnemyData = ContentDatabase.get_enemy(enemy_id)
		_check(enemy != null, "Enemy registered: " + enemy_id)
		battle.start_combat([enemy])
		await get_tree().create_timer(0.7).timeout
		await _capture("combat-" + enemy_id)
		_check(battle._stage.player != null and battle._stage.enemy != null, "Both combatants exist: " + enemy_id)
		if enemy_id == "boneghoul":
			var before_turn: int = battle.turn_number
			battle._choice_overlay.toggle_inspection()
			await _capture("combat-clock-inspection")
			battle._choice_overlay.toggle_inspection()
			_check(battle.turn_number == before_turn, "Inspecting both clocks preserves the pending decision")
			GameFlow.open_pause_menu()
			await _capture("combat-pause")
			var pause: Control = GameFlow._active_pause_overlay
			pause._on_abandon_pressed()
			await _capture("combat-abandon-confirmation")
			var confirm: ModalConfirmDialog = pause.get_child(pause.get_child_count() - 1) as ModalConfirmDialog
			confirm._on_cancel()
			_check((pause.get_node("CenterContainer/Panel") as Control).visible, "Abandon cancellation returns to pause")
			GameFlow.close_pause_menu()
			GameFlow.open_settings()
			await _capture("settings")
			var settings: Control = GameFlow._active_settings_overlay
			var old_fast: bool = AudioManager.fast_mode
			settings._fast_mode_check.button_pressed = not old_fast
			_check(AudioManager.fast_mode != old_fast, "Settings accelerated-combat toggle applies")
			settings._fast_mode_check.button_pressed = old_fast
			GameFlow.close_settings()
			battle.show_combat_manual()
			await _capture("combat-manual")
			await _close_references(battle)
			battle.show_combat_log()
			await _capture("combat-log")
			await _close_references(battle)
			GameFlow.open_deck_view(GameFlow.DeckViewMode.REFERENCE)
			await _capture("combat-reliquary")
			GameFlow.close_deck_view()


func _outcomes() -> void:
	for act: int in range(1, 4):
		GameFlow.goto_act_transition(CinematicArt.transition_background(act), "ACT %d — THE NEXT HOUR" % act, Callable())
		await _settle()
		await _capture("act-transition-%d" % act)
	for won: bool in [true, false]:
		GameFlow.goto_run_summary(won)
		await _settle()
		await _capture("victory" if won else "defeat")


func _reset_run() -> void:
	RunManager.start_new_run([], [], 500, 42042)
	OKRunState.current_ok = 200


func _show(screen: Node) -> void:
	await _clear_scene()
	get_tree().root.add_child(screen)
	get_tree().current_scene = screen
	if screen is Control:
		ScreenDesign.polish(screen as Control)
	await get_tree().create_timer(0.35).timeout


func _clear_scene() -> void:
	GameFlow.close_pause_menu()
	GameFlow.close_settings()
	GameFlow.close_deck_view()
	var current: Node = get_tree().current_scene
	get_tree().current_scene = null
	if is_instance_valid(current): current.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _settle() -> void:
	var deadline: int = Time.get_ticks_msec() + 8000
	while GameFlow._transitioning and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(not GameFlow._transitioning, "Screen transition completed")
	await get_tree().create_timer(0.35).timeout


func _close_references(battle: CombatController) -> void:
	for node: Node in battle.find_children("*", "Control", true, false):
		if node is BattleReferenceOverlay: node.queue_free()
	for node: Node in GameFlow._overlay_layer.get_children():
		if node is BattleReferenceOverlay: node.queue_free()
	await get_tree().process_frame


func _check(passed: bool, description: String) -> void:
	_checks.append({"passed": passed, "description": description})
	if not passed:
		_failures.append(description)
		push_error("SCREEN_AUDIT_CHECK: " + description)


func _capture(label: String) -> void:
	await get_tree().create_timer(0.3).timeout
	var entry: Dictionary = {"screen": label, "preset": _preset, "rendered": DisplayServer.get_name() != "headless", "button_overflow": []}
	var scene: Node = get_tree().current_scene
	if scene != null: entry.button_overflow = _overflow_buttons(scene)
	var overlay_overflow: Array[String] = _overflow_buttons(GameFlow._overlay_layer)
	entry.button_overflow.append_array(overlay_overflow)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var folder: String = ProjectSettings.globalize_path(OUTPUT.path_join(_preset))
		DirAccess.make_dir_recursive_absolute(folder)
		var file_path: String = folder.path_join(label + ".png")
		var screenshot: Image = get_viewport().get_texture().get_image()
		var saved: Error = screenshot.save_png(file_path)
		_check(saved == OK, "Screenshot saved: " + label)
		entry.path = file_path
		entry.width = screenshot.get_width()
		entry.height = screenshot.get_height()
	_captures.append(entry)
	_write_manifest()
	print("SCREEN_CAPTURE: %s/%s" % [_preset, label])


func _overflow_buttons(root: Node) -> Array[String]:
	var findings: Array[String] = []
	var visible_rect: Rect2 = get_viewport().get_visible_rect().grow(3.0)
	for node: Node in root.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if not button.is_visible_in_tree() or button.size == Vector2.ZERO: continue
		var ancestor: Node = button.get_parent()
		var in_scroll: bool = false
		while ancestor != null:
			if ancestor is ScrollContainer: in_scroll = true
			ancestor = ancestor.get_parent()
		if not in_scroll and not visible_rect.encloses(button.get_global_rect()):
			findings.append("%s: %s; %s" % [str(button.get_path()), button.text, str(button.get_global_rect())])
	return findings


func _write_manifest() -> void:
	# Structural reruns must not overwrite completed rendered evidence.
	var folder: String = ProjectSettings.globalize_path(OUTPUT if DisplayServer.get_name() != "headless" else OUTPUT + "-headless")
	DirAccess.make_dir_recursive_absolute(folder)
	var manifest: Dictionary = {"preset": _preset, "focus": _focus, "completed": _finished, "duration_seconds": (Time.get_ticks_msec() - _started) / 1000.0, "profile": OS.get_environment("APPDATA"), "rendered": DisplayServer.get_name() != "headless", "visual_approval": "pending human or image review", "captures": _captures, "checks": _checks, "failures": _failures}
	var suffix: String = "" if _focus == "all" else "-" + _focus
	var file: FileAccess = FileAccess.open(folder.path_join("manifest-%s%s.json" % [_preset, suffix]), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(manifest, "\t"))
