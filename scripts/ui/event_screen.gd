extends Control
## Shared choice-presentation component driving placeholder event content
## (map-generation/audio doc Part 3.2): body text, 2-4 choice buttons with
## consequence summaries. Any resource change routes through the same
## RunManager/OKRunState methods everything else uses - no bespoke treatment.

@onready var _title_label: Label = %TitleLabel
@onready var _body_label: RichTextLabel = %BodyLabel
@onready var _choice_box: VBoxContainer = %ChoiceBox
@onready var _panel: PanelContainer = %Panel
@onready var _background: TextureRect = %Background

var _event: EventData
var _resolved: bool = false


func set_event(event: EventData) -> void:
	_event = event


func _ready() -> void:
	if _event == null:
		GameFlow.goto_map()
		return
	theme = ScreenDesign.build_theme()
	ScreenDesign.frame(self, "A FRACTURE IN THE HOUR")
	get_node("Dim").color = Color("07101942")
	_panel.reparent(self)
	_panel.anchor_left = 0.085
	_panel.anchor_right = 0.51
	_panel.anchor_top = 0.22
	_panel.anchor_bottom = 0.22
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0
	_panel.custom_minimum_size = Vector2(0, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("091520e8")
	panel_style.border_color = Color("9d845caa")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_color = Color("000000b8")
	panel_style.shadow_size = 24
	panel_style.shadow_offset = Vector2(0, 10)
	_panel.add_theme_stylebox_override("panel", panel_style)
	var stack: VBoxContainer = _title_label.get_parent()
	var kicker := ScreenDesign.label(stack, "UNSCRIPTED ENCOUNTER", 15, ScreenDesign.CYAN)
	stack.move_child(kicker, 0)
	_title_label.text = _event.title
	_title_label.add_theme_font_override("font", ScreenDesign.display_font())
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color("efd09a"))
	var rule := ScreenDesign.rule(stack, ScreenDesign.GOLD)
	stack.move_child(rule, _title_label.get_index() + 1)
	_body_label.text = _event.body_text
	_body_label.add_theme_font_size_override("normal_font_size", 21)
	_body_label.add_theme_color_override("default_color", ScreenDesign.TEXT)
	for choice in _event.choices:
		var button := Button.new()
		button.text = choice.label.to_upper()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 66
		button.add_theme_font_size_override("font_size", 20)
		button.tooltip_text = ""
		var full_clock: bool = choice.effect_type == EventData.ChoiceEffectType.GRANT_CLOCK_RELIC and RunManager.clock_inventory.size() >= ClockInventory.MAX_SIZE
		button.disabled = RunManager.current_hp <= choice.hp_cost or OKRunState.current_ok < choice.ok_cost or full_clock
		button.pressed.connect(func() -> void: _on_choice_pressed(choice))
		_choice_box.add_child(button)
		var detail := ScreenDesign.label(_choice_box, choice.consequence_summary, 15, ScreenDesign.MUTED)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.custom_minimum_size = Vector2(0, 24)
		if full_clock:
			detail.text = "Chronometer full (12/12). Visit the Reliquary to free a slot before taking this bargain."
			detail.add_theme_color_override("font_color", Color("e7b96f"))
	var footer := ScreenDesign.label(stack, "THE CLOCK REMEMBERS WHAT YOU CHOOSE", 13, ScreenDesign.MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_load_background()
	# Arriving at an event is a small "something is happening" beat - a
	# quick reveal punch on the panel, then it settles into the shared
	# cyan/amber cinematic atmosphere while the player decides.
	AmbientMotion.punch_scale(_panel, 1.06, 0.3)


func _load_background() -> void:
	var path := CinematicArt.event_background(_event.id)
	if ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)
		_background.modulate = Color(0.78, 0.80, 0.82)
		AmbientMotion.apply_cinematic_backdrop(self, _background, 48.0, 0.75)


func _on_choice_pressed(choice: EventData.EventChoice) -> void:
	if _resolved or RunManager.current_hp <= choice.hp_cost or OKRunState.current_ok < choice.ok_cost: return
	if choice.effect_type == EventData.ChoiceEffectType.GRANT_CLOCK_RELIC and RunManager.clock_inventory.size() >= ClockInventory.MAX_SIZE: return
	_resolved = true
	if choice.hp_cost > 0: RunManager.apply_run_hp_change(-choice.hp_cost)
	if choice.ok_cost > 0: OKRunState.spend_ok(choice.ok_cost, "event:%s" % _event.id)
	match choice.effect_type:
		EventData.ChoiceEffectType.GRANT_CLOCK_RELIC:
			if not RunManager.add_clock_relic(choice.relic_id):
				_resolved = false
				return
		EventData.ChoiceEffectType.HP_DELTA:
			RunManager.apply_run_hp_change(choice.value)
		EventData.ChoiceEffectType.OK_DELTA:
			if choice.value > 0:
				OKRunState.gain_ok(choice.value, "event:%s" % _event.id)
			elif choice.value < 0:
				OKRunState.spend_ok(-choice.value, "event:%s" % _event.id)
		EventData.ChoiceEffectType.GRANT_CARD:
			var card := ContentDatabase.get_card(choice.card_id)
			if card != null:
				RunManager.add_card_to_deck(card)
		EventData.ChoiceEffectType.GRANT_RELIC:
			var relic := ContentDatabase.get_relic(choice.relic_id)
			if relic != null:
				RunManager.add_relic(relic)
	SaveManager.save_run()
	GameFlow.goto_map()
