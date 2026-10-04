extends Node
## GameFlow - the only place scene navigation happens. Screens whose job is
## user-driven navigation (button presses) call GameFlow.goto_X() directly.
## combat_controller is the one exception: win/loss is emergent gameplay
## state, not a button press, so it emits combat_won/combat_lost and GameFlow
## is the sole listener - no gameplay scene reaches into navigation itself.
##
## Pause and deck-view are CanvasLayer overlays GameFlow owns and keeps alive
## across scene changes (autoloads persist through change_scene_to_*), not
## scene swaps - a swap would destroy combat_controller's live node tree
## (hand, draw/discard piles, in-flight FeedbackQueue state). Deck-view does
## NOT pause the tree (it's meant to be a non-committal glance per the
## deck-view doc); pause does.

enum DeckViewMode { UPGRADE, REMOVAL, REFERENCE, PILE_VIEW }

const TITLE_SCENE_PATH := "res://scenes/title_screen.tscn"
const CLASS_SELECT_SCENE_PATH := "res://scenes/class_select_screen.tscn"
const MAP_SCENE_PATH := "res://scenes/map_screen.tscn"
const COG_MAP_SCENE_PATH := "res://scenes/cog_map_screen.tscn"
const SHOP_SCENE_PATH := "res://scenes/shop_screen.tscn"
const REST_SITE_SCENE_PATH := "res://scenes/rest_site_screen.tscn"
const EVENT_SCENE_PATH := "res://scenes/event_screen.tscn"
const REWARD_SCENE_PATH := "res://scenes/reward_screen.tscn"
const BOSS_ALTAR_SCENE_PATH := "res://scenes/boss_overkill_altar.tscn"
const TREASURE_SCENE_PATH := "res://scenes/treasure_screen.tscn"
const RUN_SUMMARY_SCENE_PATH := "res://scenes/run_summary_screen.tscn"
const COMBAT_SCENE_PATH := "res://scenes/combat_scene.tscn"
const PAUSE_MENU_SCENE_PATH := "res://scenes/pause_menu.tscn"
const DECK_VIEW_SCENE_PATH := "res://scenes/deck_view.tscn"
const SETTINGS_PANEL_SCENE_PATH := "res://scenes/settings_panel.tscn"
const EXCESS_CELEBRATION_SCENE_PATH := "res://scenes/excess_unlock_celebration.tscn"
const ACT_TRANSITION_SCENE_PATH := "res://scenes/act_transition_screen.tscn"
const PRE_BATTLE_OFFER_SCENE_PATH := "res://scenes/pre_battle_offer.tscn"

var _overlay_layer: CanvasLayer
var _active_pause_overlay: Control = null
var _active_deck_view_overlay: Control = null
var _active_settings_overlay: Control = null
var _transitioning: bool = false
var _pending_combat_enemies: Array[EnemyData] = []
var _pending_combat_background: String = ""
var _pending_combat_node_id: String = ""


func _ready() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "GameFlowOverlayLayer"
	_overlay_layer.layer = 100
	_overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay_layer)
	OKRunState.excess_threshold_crossed.connect(_on_excess_threshold_crossed)
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.settings_changed.connect(_on_presentation_settings_changed)

func _on_presentation_settings_changed(_settings: Dictionary) -> void:
	if get_tree().current_scene != null: ScreenDesign.apply_text_size(get_tree().current_scene)
	ScreenDesign.apply_text_size(_overlay_layer)


## Platform-standard back/escape gesture (pause/settings doc Part 2) works
## from every screen without each one wiring its own handler. Deck-view and
## settings close on Escape too, before falling back to toggling pause -
## never opens pause on top of an already-open overlay.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		return
	if _active_deck_view_overlay != null:
		close_deck_view()
	elif _active_settings_overlay != null:
		close_settings()
	elif _active_pause_overlay != null:
		close_pause_menu()
	elif get_tree().current_scene != null and get_tree().current_scene.name == "ClassSelectScreen":
		goto_title()
	elif get_tree().current_scene != null and get_tree().current_scene.name == "TitleScreen":
		return
	elif RunManager.run_active:
		open_pause_menu()
	get_viewport().set_input_as_handled()


func goto_title() -> void:
	_swap_scene(load(TITLE_SCENE_PATH).instantiate(), "TITLE")


func goto_class_select() -> void:
	_swap_scene(load(CLASS_SELECT_SCENE_PATH).instantiate(), "CHOOSE YOUR EXECUTIONER")


func goto_map() -> void:
	if _transitioning: return
	RunManager.resume_context = {"kind": "map"}
	# Runs saved on the earlier node lattice stay on that map for compatibility.
	# Fresh runs and runs already using cog IDs travel through the timed mechanism.
	var saved_node_id: String = RunManager.current_node_id
	var scene_path: String = MAP_SCENE_PATH
	if saved_node_id.is_empty() or saved_node_id.begins_with("cogmap-"):
		scene_path = COG_MAP_SCENE_PATH
	_swap_scene(load(scene_path).instantiate(), "THE COGWORK ASCENT" if scene_path == COG_MAP_SCENE_PATH else "THE ASCENT")


func goto_shop() -> void:
	var shop := preload("res://scripts/ui/clock_collection_screen.gd").new()
	shop.mode = "shop"
	_swap_scene(shop, "THE CLOCKWRIGHT")


func goto_rest_site() -> void:
	_swap_scene(load(REST_SITE_SCENE_PATH).instantiate(), "REST SITE")


func goto_event(event_data: EventData) -> void:
	var scene: PackedScene = load(EVENT_SCENE_PATH)
	var instance := scene.instantiate()
	instance.set_event(event_data)
	_swap_scene(instance, "EVENT")


## Accepts 1+ enemies (a "pack") - map_screen builds a 1-element array for
## every normal single-enemy node (elites/bosses always are), and a 2-element
## array for the rare trash-pack nodes map_generator rolls.
func goto_combat(enemies_data: Array[EnemyData], background_id: String = "") -> void:
	if _transitioning or enemies_data.is_empty(): return
	_checkpoint_encounter("combat", enemies_data, background_id)
	var scene: PackedScene = load(COMBAT_SCENE_PATH)
	var instance: CombatController = scene.instantiate()
	instance.combat_won.connect(_on_combat_won)
	instance.combat_lost.connect(_on_combat_lost)
	_swap_scene(
		instance,
		"BATTLE",
		func() -> void: instance.prepare_combat(enemies_data, background_id),
		func() -> void: instance.begin_combat_intro()
	)


func goto_pre_battle_offer(enemies_data: Array[EnemyData], node_id: String, background_id: String = "") -> void:
	if _transitioning or enemies_data.is_empty(): return
	_checkpoint_encounter("prebattle", enemies_data, background_id, node_id)
	_pending_combat_enemies.assign(enemies_data)
	_pending_combat_background = background_id
	_pending_combat_node_id = node_id
	var scene: PackedScene = load(PRE_BATTLE_OFFER_SCENE_PATH)
	var instance := scene.instantiate()
	instance.resolved.connect(_on_pre_battle_offer_resolved)
	_swap_scene(instance, "AN OFFER BEFORE BLOOD")


func _on_pre_battle_offer_resolved(effect_id: String) -> void:
	if effect_id == "upgrade_relic":
		var selector := preload("res://scripts/ui/clock_collection_screen.gd").new()
		selector.mode = "upgrade"
		selector.pre_battle = true
		selector.resolved.connect(_finish_pre_battle)
		_swap_scene(selector, "UPGRADE A RELIC")
		return
	_finish_pre_battle()


func _finish_pre_battle() -> void:
	if _pending_combat_enemies.is_empty() or _pending_combat_node_id.is_empty():
		push_error("GameFlow: pre-battle resolution has no pending combat")
		goto_map()
		return
	RunManager.mark_pre_battle_offer_seen()
	RunManager.commit_map_node(_pending_combat_node_id)
	SaveManager.save_run()
	var enemies: Array[EnemyData] = _pending_combat_enemies.duplicate()
	var background := _pending_combat_background
	_pending_combat_enemies.clear()
	_pending_combat_background = ""
	_pending_combat_node_id = ""
	goto_combat(enemies, background)


func goto_reward_screen(reward_context: Dictionary) -> void:
	if _transitioning: return
	var enemy: EnemyData = reward_context.get("enemy_data") as EnemyData
	RunManager.resume_context = {"kind": "reward", "enemy_id": enemy.id if enemy != null else "", "offer_ids": reward_context.get("offer_ids", []).duplicate()}
	SaveManager.save_run()
	var scene: PackedScene = load(REWARD_SCENE_PATH)
	var instance := scene.instantiate()
	instance.set_reward_context(reward_context)
	_swap_scene(instance, "REWARD")


func goto_boss_overkill_altar(enemy_data: EnemyData, purchased: bool = false) -> void:
	if _transitioning or enemy_data == null: return
	RunManager.resume_context = {"kind": "altar", "enemy_id": enemy_data.id, "purchased": purchased}
	SaveManager.save_run()
	var scene: PackedScene = load(BOSS_ALTAR_SCENE_PATH)
	var instance: BossOverkillAltar = scene.instantiate() as BossOverkillAltar
	instance.set_boss_context(enemy_data, purchased)
	_swap_scene(instance, "THE OVERKILL ALTAR")


## Restart unfinished combat/offers at their entry boundary. Restoring the entry
## run AND currency prevents already-earned combat effects from being farmed.
func _checkpoint_encounter(kind: String, enemies: Array[EnemyData], background: String, node_id: String = "") -> void:
	var entry: Dictionary = RunManager.to_save_dict()
	entry.erase("resume_context")
	entry["ok_run_state"] = OKRunState.to_save_dict()
	var ids: Array[String] = []
	for enemy: EnemyData in enemies: ids.append(enemy.id)
	RunManager.resume_context = {"kind": kind, "enemy_ids": ids, "background": background, "node_id": node_id, "entry_state": entry}
	SaveManager.save_run()


func resume_saved_run() -> void:
	if _transitioning: return
	var context: Dictionary = RunManager.resume_context.duplicate(true)
	var kind: String = str(context.get("kind", ""))
	if kind in ["combat", "prebattle"]:
		var enemies: Array[EnemyData] = []
		for id: String in context.get("enemy_ids", []):
			var enemy: EnemyData = ContentDatabase.get_enemy(id)
			if enemy != null: enemies.append(enemy)
		if not enemies.is_empty() and enemies.size() == context.get("enemy_ids", []).size():
			var entry: Dictionary = context.get("entry_state", {})
			if not entry.is_empty(): RunManager.load_from_save(entry)
			if kind == "prebattle":
				goto_pre_battle_offer(enemies, str(context.get("node_id", "")), str(context.get("background", "")))
			else:
				goto_combat(enemies, str(context.get("background", "")))
			return
	elif kind == "reward":
		goto_reward_screen({"enemy_data": ContentDatabase.get_enemy(str(context.get("enemy_id", ""))), "offer_ids": context.get("offer_ids", [])})
		return
	elif kind in ["altar", "boss_exit"]:
		var boss: EnemyData = ContentDatabase.get_enemy(str(context.get("enemy_id", "")))
		if boss != null:
			if kind == "boss_exit": goto_boss_exit(boss)
			else: goto_boss_overkill_altar(boss, bool(context.get("purchased", false)))
			return
	# Old saves cannot distinguish an entered boss from a finished altar. Replay
	# the guardian conservatively, preserving inventory/currency, rather than
	# skip its fight or strand the player on a node without forward connections.
	if kind.is_empty():
		var generated: Dictionary = CogNavigationGenerator.generate(RunManager.seed_value, RunManager.act_number, RunManager.cog_layout_version) if RunManager.current_node_id.begins_with("cogmap-") else MapGenerator.generate(RunManager.seed_value, RunManager.act_number)
		var node: MapGenerator.MapNode = generated.nodes.get(RunManager.current_node_id) as MapGenerator.MapNode
		if node != null and node.type == MapGenerator.NodeType.BOSS:
			var boss: EnemyData = ContentDatabase.get_enemy(node.enemy_id)
			if boss != null:
				var bosses: Array[EnemyData] = [boss]
				goto_combat(bosses)
				return
	goto_map()


## Persist the destination before displaying the inter-act curtain, including
## the final-boss route. Quitting on the curtain resumes the same destination.
func goto_boss_exit(boss: EnemyData) -> void:
	if _transitioning or boss == null: return
	RunManager.resume_context = {"kind": "boss_exit", "enemy_id": boss.id}
	SaveManager.save_run()
	var final_descent: bool = boss.id == "act3_boss"
	var next_act: int = RunManager.act_number + 1
	goto_act_transition(CinematicArt.transition_background(RunManager.act_number), "THE FINAL DESCENT" if final_descent else "ACT %d" % next_act, func() -> void:
		if final_descent:
			var final_boss: EnemyData = ContentDatabase.get_enemy("final_boss")
			if final_boss != null:
				var enemies: Array[EnemyData] = [final_boss]
				goto_combat(enemies)
		else:
			RunManager.advance_act()
			RunManager.resume_context = {"kind": "map"}
			SaveManager.save_run()
			goto_map()
	)


func goto_treasure(ok_gain: int, found_relic: RelicData) -> void:
	var scene: PackedScene = load(TREASURE_SCENE_PATH)
	var instance: TreasureScreen = scene.instantiate()
	instance.set_reward_context({"ok_gain": ok_gain, "relic": found_relic})
	_swap_scene(instance, "SEALED CACHE")


## The transition beat itself doesn't know about run structure - it just
## shows art + a label and calls on_complete when dismissed. Callers (reward
## screen, on an act-boss kill) decide what "continue" actually means.
func goto_act_transition(background_path: String, label_text: String, on_complete: Callable) -> void:
	var scene: PackedScene = load(ACT_TRANSITION_SCENE_PATH)
	var instance := scene.instantiate()
	instance.configure(background_path, label_text, on_complete)
	_swap_scene(instance, label_text)


func goto_run_summary(won: bool) -> void:
	var scene: PackedScene = load(RUN_SUMMARY_SCENE_PATH)
	var instance := scene.instantiate()
	instance.set_outcome(won)
	_swap_scene(instance, "JOURNEY COMPLETE" if won else "JOURNEY ENDED")


func open_pause_menu() -> void:
	if _active_pause_overlay != null:
		return
	var scene: PackedScene = load(PAUSE_MENU_SCENE_PATH)
	_active_pause_overlay = scene.instantiate()
	_active_pause_overlay.theme = ScreenDesign.build_theme()
	_overlay_layer.add_child(_active_pause_overlay)
	get_tree().paused = true


func close_pause_menu() -> void:
	if _active_pause_overlay == null:
		return
	_active_pause_overlay.queue_free()
	_active_pause_overlay = null
	get_tree().paused = false


func open_deck_view(mode: DeckViewMode, filter_pile: Array = []) -> void:
	close_deck_view()
	var collection := preload("res://scripts/ui/clock_collection_screen.gd").new()
	collection.mode = "upgrade" if mode == DeckViewMode.UPGRADE else ("removal" if mode == DeckViewMode.REMOVAL else "collection")
	collection.overlay = true
	_active_deck_view_overlay = collection
	_overlay_layer.add_child(_active_deck_view_overlay)


func close_deck_view() -> void:
	if _active_deck_view_overlay == null:
		return
	_active_deck_view_overlay.queue_free()
	_active_deck_view_overlay = null


func open_settings() -> void:
	if _active_settings_overlay != null:
		return
	var scene: PackedScene = load(SETTINGS_PANEL_SCENE_PATH)
	_active_settings_overlay = scene.instantiate()
	_active_settings_overlay.theme = ScreenDesign.build_theme()
	_overlay_layer.add_child(_active_settings_overlay)


func close_settings() -> void:
	if _active_settings_overlay == null:
		return
	_active_settings_overlay.queue_free()
	_active_settings_overlay = null


func abandon_run() -> void:
	SaveManager.delete_run_save()
	RunManager.end_run()
	close_pause_menu()
	goto_title()


func _swap_scene(new_root: Node, destination: String = "", on_installed: Callable = Callable(), on_revealed: Callable = Callable()) -> void:
	if _transitioning:
		new_root.queue_free()
		return
	_transitioning = true
	var tree := get_tree()
	var old_root := tree.current_scene
	var curtain := preload("res://scripts/ui/screen_transition.gd").new()
	curtain.theme = ScreenDesign.build_theme()
	_overlay_layer.add_child(curtain)
	await curtain.play_cover(destination)
	if new_root is Control: new_root.theme = ScreenDesign.build_theme()
	tree.root.add_child(new_root)
	if new_root is Control: ScreenDesign.polish(new_root)
	tree.current_scene = new_root
	if old_root != null:
		old_root.queue_free()
	if on_installed.is_valid(): on_installed.call()
	await tree.process_frame
	await curtain.play_reveal()
	_transitioning = false
	if on_revealed.is_valid(): on_revealed.call()


func _on_combat_won(defeated_enemies_data: Array) -> void:
	# Elite/boss nodes are always a single enemy - packs only ever happen on
	# regular trash nodes, where every member shares the same tier/id anyway,
	# so the first entry is representative for reward-tier purposes either way.
	var enemy_data: EnemyData = defeated_enemies_data[0]
	if enemy_data.tier == EnemyData.Tier.BOSS and enemy_data.id == "final_boss":
		SaveManager.delete_run_save()
		RunManager.end_run()
		goto_run_summary(true)
	elif enemy_data.tier == EnemyData.Tier.BOSS:
		goto_boss_overkill_altar(enemy_data)
	else:
		goto_reward_screen({"enemy_data": enemy_data})


func _on_combat_lost() -> void:
	SaveManager.delete_run_save()
	RunManager.end_run()
	goto_run_summary(false)


func _on_excess_threshold_crossed(threshold: int) -> void:
	var scene: PackedScene = load(EXCESS_CELEBRATION_SCENE_PATH)
	var celebration: Control = scene.instantiate() as Control
	celebration.call("set_threshold", threshold)
	celebration.theme = ScreenDesign.build_theme()
	_overlay_layer.add_child(celebration)
