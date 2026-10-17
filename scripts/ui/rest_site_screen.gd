extends Control
## Rest site: recover vitality or permanently temper one clock relic.
## Both are one-time choices per visit; either one returns to the map.

const REST_HEAL_FRACTION := 0.3
const TUNE_OK_GAIN: int = 12
const TUNE_MAX_HP_GAIN: int = 4

@onready var _hud: CombatHUD = %HUD
@onready var _rest_button: Button = %RestButton
@onready var _upgrade_button: Button = %UpgradeButton
@onready var _back_button: Button = %BackButton
@onready var _status_label: Label = %StatusLabel
@onready var _background: TextureRect = %Background

var _tune_button: Button
var _state_label: Label
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
	content.anchor_right = 0.42
	content.anchor_top = 0.16
	content.anchor_bottom = 0.16
	content.offset_left = 0
	content.offset_right = 0
	content.offset_top = 0
	content.offset_bottom = 0
	content.add_theme_constant_override("separation", 14)
	var title: Label = content.get_node("TitleLabel")
	title.text = "A moment\nbetween hours."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_override("font", ScreenDesign.display_font())
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", ScreenDesign.GOLD)
	var kicker := ScreenDesign.label(content, "SANCTUARY CHOICE", 16, ScreenDesign.CYAN)
	content.move_child(kicker, 0)
	_state_label = ScreenDesign.label(content, "", 18, ScreenDesign.TEXT)
	content.move_child(_state_label, title.get_index() + 1)
	_refresh_state_label()
	var rule := ScreenDesign.rule(content, ScreenDesign.GOLD)
	content.move_child(rule, _state_label.get_index() + 1)
	_refresh_rest_option()
	_upgrade_button.text = "UPGRADE A RELIC\nStrengthen one bound relic for the rest of this run"
	_tune_button = Button.new()
	_tune_button.name = "TuneButton"
	_tune_button.text = "TUNE CHRONOMETER (+%d OVERKILL & +%d MAX HP)\nCalibrate the gears for wealth and durability" % [TUNE_OK_GAIN, TUNE_MAX_HP_GAIN]
	content.add_child(_tune_button)
	content.move_child(_tune_button, _upgrade_button.get_index() + 1)
	_back_button.text = "RETURN TO MAP"
	for button: Button in [_rest_button, _upgrade_button, _tune_button, _back_button]:
		button.custom_minimum_size.y = 74 if button != _back_button else 54
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var rest_style := ScreenDesign.box(Color("0d2430e8"), Color("69c8d6b8"), 1)
	var temper_style := ScreenDesign.box(Color("251a2ee8"), Color("b66ce0b8"), 1)
	var tune_style := ScreenDesign.box(Color("261f10e8"), Color("e3bb82b8"), 1)
	_rest_button.add_theme_stylebox_override("normal", rest_style)
	_upgrade_button.add_theme_stylebox_override("normal", temper_style)
	_tune_button.add_theme_stylebox_override("normal", tune_style)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_status_label.add_theme_color_override("font_color", ScreenDesign.CYAN)
	ScreenDesign.frame(self, "SANCTUARY")
	if _rest_button.disabled:
		_upgrade_button.grab_focus()
	else:
		_rest_button.grab_focus()
	_rest_button.pressed.connect(_on_rest_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_tune_button.pressed.connect(_on_tune_pressed)
	_load_background()
	_back_button.pressed.connect(func() -> void: GameFlow.goto_map())


func _load_background() -> void:
	var path := "res://assets/screens/rest_site_bg.jpg"
	if ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)
		# Calmest screen in the run: minimal drift and sparse light breathing.
		AmbientMotion.apply_cinematic_backdrop(self, _background, 62.0, 0.52)


func _refresh_state_label() -> void:
	if is_instance_valid(_state_label):
		_state_label.text = "VITALITY  %d / %d     ·     %d OVERKILL     ·     %s" % [
			RunManager.current_hp,
			RunManager.max_hp,
			OKRunState.current_ok,
			"SANCTUARY RESOLVED" if _resolved else "ONE CHOICE REMAINS"
		]


func _refresh_rest_option() -> void:
	var heal_amount: int = int(round(RunManager.max_hp * REST_HEAL_FRACTION))
	if RunManager.current_hp >= RunManager.max_hp:
		_rest_button.text = "REST (30%% MAX HP  ·  +%d HP)\nVitality already full" % heal_amount
		_rest_button.tooltip_text = "Vitality is full. Upgrade a relic, tune your chronometer, or return to the map."
		_rest_button.disabled = true
		return
	_rest_button.text = "REST (30%% MAX HP)\nRecover up to %d vitality" % heal_amount
	_rest_button.tooltip_text = ""
	_rest_button.disabled = false


func _on_rest_pressed() -> void:
	if _resolved:
		return
	if RunManager.current_hp >= RunManager.max_hp:
		_refresh_rest_option()
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


func _on_tune_pressed() -> void:
	if _resolved:
		return
	OKRunState.gain_ok(TUNE_OK_GAIN, "rest_site_tune")
	RunManager.apply_max_hp_change(TUNE_MAX_HP_GAIN)
	SaveManager.save_run()
	_mark_resolved("Chronometer tuned: +%d Overkill and +%d Max HP (healed %d HP)." % [TUNE_OK_GAIN, TUNE_MAX_HP_GAIN, TUNE_MAX_HP_GAIN])


func _mark_resolved(message: String) -> void:
	_resolved = true
	_rest_button.disabled = true
	_upgrade_button.disabled = true
	if is_instance_valid(_tune_button):
		_tune_button.disabled = true
	_refresh_state_label()
	_status_label.text = message
