extends Control
## Rest site: recover vitality or permanently temper one clock relic.
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
	add_child(load("res://scenes/tutorial_callout_view.tscn").instantiate())
	# The sanctuary already presents vitality beside the choice. Repeating the
	# combat HUD here made the screen read like an unfinished battle layout.
	_hud.hide()
	var content: VBoxContainer = get_node("CenterContainer/VBox")
	content.reparent(self)
	content.anchor_left = 0.075
	content.anchor_right = 0.40
	content.anchor_top = 0.20
	content.anchor_bottom = 0.20
	content.offset_left = 0
	content.offset_right = 0
	content.offset_top = 0
	content.offset_bottom = 0
	content.add_theme_constant_override("separation",18)
	var title: Label = content.get_node("TitleLabel")
	title.text = "A moment\nbetween hours."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_override("font",ScreenDesign.display_font())
	title.add_theme_font_size_override("font_size",52)
	title.add_theme_color_override("font_color",ScreenDesign.GOLD)
	var kicker := ScreenDesign.label(content, "SANCTUARY CHOICE", 16, ScreenDesign.CYAN)
	content.move_child(kicker, 0)
	var state := ScreenDesign.label(content, "VITALITY  %d / %d     ·     ONE CHOICE REMAINS" % [RunManager.current_hp, RunManager.max_hp], 18, ScreenDesign.TEXT)
	content.move_child(state, title.get_index() + 1)
	var rule := ScreenDesign.rule(content, ScreenDesign.GOLD)
	content.move_child(rule, state.get_index() + 1)
	_rest_button.text = "REST\nRecover up to %d vitality" % int(round(RunManager.max_hp*REST_HEAL_FRACTION))
	_upgrade_button.text = "UPGRADE A RELIC\nStrengthen one bound relic for the rest of this run"
	_back_button.text = "RETURN TO MAP"
	for button in [_rest_button,_upgrade_button,_back_button]:
		button.custom_minimum_size.y = 78 if button != _back_button else 56
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var rest_style := ScreenDesign.box(Color("0d2430e8"), Color("69c8d6b8"), 1)
	var temper_style := ScreenDesign.box(Color("251a2ee8"), Color("b66ce0b8"), 1)
	_rest_button.add_theme_stylebox_override("normal", rest_style)
	_upgrade_button.add_theme_stylebox_override("normal", temper_style)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_status_label.add_theme_color_override("font_color", ScreenDesign.CYAN)
	ScreenDesign.frame(self,"SANCTUARY")
	_rest_button.grab_focus()
	_rest_button.pressed.connect(_on_rest_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_load_background()
	_back_button.pressed.connect(func() -> void: GameFlow.goto_map())


func _load_background() -> void:
	var path := "res://assets/screens/rest_site_bg.jpg"
	if ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)
		# Calmest screen in the run: minimal drift and sparse light breathing.
		AmbientMotion.apply_cinematic_backdrop(self, _background, 62.0, 0.52)


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
	_mark_resolved("Relic upgraded. Its improvement lasts for the rest of this run.")
	TutorialCallout.trigger("first_rest_upgrade")


func _mark_resolved(message: String) -> void:
	_resolved = true
	_rest_button.disabled = true
	_upgrade_button.disabled = true
	_status_label.text = message
