extends Control
## Rest site: "Rest" (free heal) and "Upgrade a Card" (OK-priced, opens
## deck-view in Upgrade mode) - deck-view screen doc's access-points table.
## Both are one-time choices per visit; either one returns to the map.

const REST_HEAL_FRACTION := 0.3

@onready var _hud: CombatHUD = %HUD
@onready var _rest_button: Button = %RestButton
@onready var _upgrade_button: Button = %UpgradeButton
@onready var _back_button: Button = %BackButton
@onready var _status_label: Label = %StatusLabel
@onready var _background: TextureRect = %Background

var _resolved: bool = false


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	_hud.bind_run_state()
	var content: VBoxContainer = get_node("CenterContainer/VBox")
	content.reparent(self)
	content.anchor_left = 0.075
	content.anchor_right = 0.38
	content.anchor_top = 0.27
	content.anchor_bottom = 0.27
	content.offset_left = 0
	content.offset_right = 0
	content.offset_top = 0
	content.offset_bottom = 0
	content.add_theme_constant_override("separation",24)
	var title: Label = content.get_node("TitleLabel")
	title.text = "A moment\nbetween hours."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_override("font",ScreenDesign.display_font())
	title.add_theme_font_size_override("font_size",52)
	title.add_theme_color_override("font_color",ScreenDesign.GOLD)
	_rest_button.text = "REST   /   Recover up to %d vitality" % int(round(RunManager.max_hp*REST_HEAL_FRACTION))
	for button in [_rest_button,_upgrade_button,_back_button]:
		button.custom_minimum_size.y = 64
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ScreenDesign.frame(self,"SANCTUARY")
	_rest_button.grab_focus()
	_upgrade_button.text = "Temper a Relic"
	_rest_button.pressed.connect(_on_rest_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_load_background()
	# Calmest screen in the game on purpose - slow, sparse embers, nothing
	# urgent, matching what a rest site is for.
	AmbientMotion.spawn_embers(self, Color(0.4, 0.7, 0.95, 0.4), 8, true)
	_back_button.pressed.connect(func() -> void: GameFlow.goto_map())


func _load_background() -> void:
	var path := "res://assets/screens/rest_site_bg.jpg"
	if ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)
		AmbientMotion.apply_ken_burns(_background, 55.0, 0.015)


func _on_rest_pressed() -> void:
	if _resolved:
		return
	var heal_amount: int = int(round(RunManager.max_hp * REST_HEAL_FRACTION))
	RunManager.apply_run_hp_change(heal_amount)
	SaveManager.save_run()
	_mark_resolved("Rested and healed %d HP." % heal_amount)


func _on_upgrade_pressed() -> void:
	if _resolved:
		return
	GameFlow.open_deck_view(GameFlow.DeckViewMode.UPGRADE)
	if not RunManager.clock_inventory_changed.is_connected(_on_clock_upgraded):
		RunManager.clock_inventory_changed.connect(_on_clock_upgraded, CONNECT_ONE_SHOT)


func _on_clock_upgraded() -> void:
	SaveManager.save_run()
	_mark_resolved("Relic tempered. Its improvement lasts for the rest of this run.")


func _on_deck_changed_once(_deck: Array) -> void:
	SaveManager.save_run()
	_mark_resolved("Card upgraded.")


func _mark_resolved(message: String) -> void:
	_resolved = true
	_rest_button.disabled = true
	_upgrade_button.disabled = true
	_status_label.text = message
