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
const SHOP_SCENE_PATH := "res://scenes/shop_screen.tscn"
const REST_SITE_SCENE_PATH := "res://scenes/rest_site_screen.tscn"
const EVENT_SCENE_PATH := "res://scenes/event_screen.tscn"
const REWARD_SCENE_PATH := "res://scenes/reward_screen.tscn"
const RUN_SUMMARY_SCENE_PATH := "res://scenes/run_summary_screen.tscn"
const COMBAT_SCENE_PATH := "res://scenes/combat_scene.tscn"
const PAUSE_MENU_SCENE_PATH := "res://scenes/pause_menu.tscn"
const DECK_VIEW_SCENE_PATH := "res://scenes/deck_view.tscn"
const SETTINGS_PANEL_SCENE_PATH := "res://scenes/settings_panel.tscn"
const EXCESS_CELEBRATION_SCENE_PATH := "res://scenes/excess_unlock_celebration.tscn"
const ACT_TRANSITION_SCENE_PATH := "res://scenes/act_transition_screen.tscn"

var _overlay_layer: CanvasLayer
var _active_pause_overlay: Control = null
var _active_deck_view_overlay: Control = null
var _active_settings_overlay: Control = null


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
	_swap_scene(load(TITLE_SCENE_PATH).instantiate())


func goto_class_select() -> void:
	_swap_scene(load(CLASS_SELECT_SCENE_PATH).instantiate())


func goto_map() -> void:
	_swap_scene(load(MAP_SCENE_PATH).instantiate())


func goto_shop() -> void:
	var shop := preload("res://scripts/ui/clock_collection_screen.gd").new()
	shop.mode = "shop"
	_swap_scene(shop)


func goto_rest_site() -> void:
	_swap_scene(load(REST_SITE_SCENE_PATH).instantiate())


func goto_event(event_data: EventData) -> void:
	var scene: PackedScene = load(EVENT_SCENE_PATH)
	var instance := scene.instantiate()
	instance.set_event(event_data)
	_swap_scene(instance)


## Accepts 1+ enemies (a "pack") - map_screen builds a 1-element array for
## every normal single-enemy node (elites/bosses always are), and a 2-element
## array for the rare trash-pack nodes map_generator rolls.
func goto_combat(enemies_data: Array[EnemyData], background_id: String = "") -> void:
	var scene: PackedScene = load(COMBAT_SCENE_PATH)
	var instance := scene.instantiate()
	instance.combat_won.connect(_on_combat_won)
	instance.combat_lost.connect(_on_combat_lost)
	_swap_scene(instance)
	instance.start_combat(enemies_data, background_id)


func goto_reward_screen(reward_context: Dictionary) -> void:
	var scene: PackedScene = load(REWARD_SCENE_PATH)
	var instance := scene.instantiate()
	instance.set_reward_context(reward_context)
	_swap_scene(instance)


## The transition beat itself doesn't know about run structure - it just
## shows art + a label and calls on_complete when dismissed. Callers (reward
## screen, on an act-boss kill) decide what "continue" actually means.
func goto_act_transition(background_path: String, label_text: String, on_complete: Callable) -> void:
	var scene: PackedScene = load(ACT_TRANSITION_SCENE_PATH)
	var instance := scene.instantiate()
	instance.configure(background_path, label_text, on_complete)
	_swap_scene(instance)


func goto_run_summary(won: bool) -> void:
	var scene: PackedScene = load(RUN_SUMMARY_SCENE_PATH)
	var instance := scene.instantiate()
	instance.set_outcome(won)
	_swap_scene(instance)


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


func _swap_scene(new_root: Node) -> void:
	var tree := get_tree()
	var old_root := tree.current_scene
	if new_root is Control: new_root.theme = ScreenDesign.build_theme()
	tree.root.add_child(new_root)
	if new_root is Control: ScreenDesign.polish(new_root)
	tree.current_scene = new_root
	if old_root != null:
		old_root.queue_free()
	# Persistent overlay fades the newly installed scene; navigation remains atomic.
	var curtain := ColorRect.new()
	curtain.color = Color("080d13")
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_layer.add_child(curtain)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var transition := create_tween()
	transition.tween_property(curtain, "color:a", 0.0, 0.38)
	transition.tween_callback(curtain.queue_free)


func _on_combat_won(defeated_enemies_data: Array) -> void:
	# Elite/boss nodes are always a single enemy - packs only ever happen on
	# regular trash nodes, where every member shares the same tier/id anyway,
	# so the first entry is representative for reward-tier purposes either way.
	var enemy_data: EnemyData = defeated_enemies_data[0]
	if enemy_data.tier == EnemyData.Tier.BOSS and enemy_data.id == "final_boss":
		SaveManager.delete_run_save()
		RunManager.end_run()
		goto_run_summary(true)
	else:
		# Act bosses (tier BOSS, id != final_boss) also route through the
		# reward screen like any other kill - reward_screen.gd checks
		# enemy_data.tier itself and calls RunManager.advance_act() before
		# returning to the map when it was an act boss.
		goto_reward_screen({"enemy_data": enemy_data})


func _on_combat_lost() -> void:
	SaveManager.delete_run_save()
	RunManager.end_run()
	goto_run_summary(false)


func _on_excess_threshold_crossed(threshold: int) -> void:
	var toast := Label.new()
	toast.text = "OVERKILL MILESTONE  /  %d" % threshold
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 26)
	toast.add_theme_color_override("font_color", Color("edc783"))
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast.offset_top = 108
	var reveal := toast.create_tween()
	reveal.tween_interval(1.2)
	reveal.tween_property(toast, "modulate:a", 0.0, 0.35)
	reveal.tween_callback(toast.queue_free)
