class_name PreBattleOfferScreen extends Control
## Optional three-choice beat used before important encounters. Effects are
## deliberately data-shaped so future offers can reuse the presentation and
## provide a different resolver without rebuilding the screen.

signal resolved(effect_id: String)

const CHOICES: Array[Dictionary] = [
	{
		"number": "I",
		"title": "REFINE A MEMORY",
		"body": "Choose one card from your current deck. Its upgraded form will remain with this run.",
		"effect": "upgrade_card",
		"action": "CHOOSE A CARD",
		"accent": Color("e7bd72"),
	},
	{
		"number": "II",
		"title": "BANK THE SPARK",
		"body": "Seal a fragment of the forge inside the chronometer before entering battle.",
		"effect": "gain_overkill",
		"action": "GAIN 10 OVERKILL",
		"accent": Color("79d7df"),
	},
	{
		"number": "III",
		"title": "REINFORCE THE FRAME",
		"body": "Temper the Executioner's body for the road ahead and repair it in the same stroke.",
		"effect": "gain_vitality",
		"action": "GAIN 3 MAX VITALITY",
		"accent": Color("d78e78"),
	},
]

var _cards: Array[PanelContainer] = []
var _buttons: Array[Button] = []
var _result: Label
var _continue: Button
var _committed: bool = false
var _selected_effect: String = ""


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	_build_background()
	ScreenDesign.frame(self, "BEFORE THE FIRST BELL")
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 88)
	margin.add_theme_constant_override("margin_right", 88)
	margin.add_theme_constant_override("margin_top", 104)
	margin.add_theme_constant_override("margin_bottom", 64)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var eyebrow := ScreenDesign.label(column, "THE FORGEMASTER'S OFFER", 18, ScreenDesign.CYAN)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title := ScreenDesign.label(column, "One choice before blood.", 52, ScreenDesign.TEXT, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := ScreenDesign.label(column, "The mechanism will remember what you take.", 22, ScreenDesign.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ScreenDesign.spacer(column, 10)
	var row := HBoxContainer.new()
	row.name = "ChoiceRow"
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	column.add_child(row)
	for choice: Dictionary in CHOICES:
		row.add_child(_build_choice(choice))
	_result = ScreenDesign.label(column, "", 22, ScreenDesign.GOLD, true)
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.custom_minimum_size.y = 42
	_continue = ScreenDesign.button(column, "ENTER BATTLE   ›", _finish, true)
	_continue.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue.custom_minimum_size.x = 330
	_continue.hide()
	ScreenDesign.apply_text_size(self)


func _build_background() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/environments/chronoforge_arena.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.24, 0.29, 0.34)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color("06101bd8")
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_choice(choice: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(390, 460)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0
	var style := ScreenDesign.box(Color("0d1824f2"), choice.accent, 2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.7)
	style.shadow_size = 22
	card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	card.add_child(column)
	var numeral := ScreenDesign.label(column, choice.number, 58, choice.accent, true)
	numeral.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rule := ScreenDesign.rule(column, choice.accent)
	rule.custom_minimum_size.y = 2
	var name := ScreenDesign.label(column, choice.title, 28, ScreenDesign.TEXT, true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var body := ScreenDesign.label(column, choice.body, 20, ScreenDesign.MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var action := ScreenDesign.button(column, choice.action, _choose.bind(choice.effect, card), true)
	action.alignment = HORIZONTAL_ALIGNMENT_CENTER
	action.mouse_entered.connect(_hover_card.bind(card, true))
	action.mouse_exited.connect(_hover_card.bind(card, false))
	action.focus_entered.connect(_hover_card.bind(card, true))
	action.focus_exited.connect(_hover_card.bind(card, false))
	card.set_meta("base_style", style)
	_cards.append(card)
	_buttons.append(action)
	return card


func _hover_card(card: PanelContainer, active: bool) -> void:
	if _committed or AudioManager.reduced_motion: return
	var tween := card.create_tween().set_parallel(true)
	tween.tween_property(card, "position:y", -12.0 if active else 0.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(1.025, 1.025) if active else Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _choose(effect_id: String, selected: PanelContainer) -> void:
	if _committed: return
	_committed = true
	_selected_effect = effect_id
	for button: Button in _buttons: button.disabled = true
	for card: PanelContainer in _cards:
		if card != selected:
			card.create_tween().tween_property(card, "modulate", Color(0.42, 0.46, 0.52, 0.45), 0.22)
	var focus := selected.create_tween().set_parallel(true)
	focus.tween_property(selected, "scale", Vector2(1.07, 1.07), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	focus.tween_property(selected, "position:y", -20.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_result.text = "THE FORGE ACCEPTS YOUR CHOICE"
	_result.modulate.a = 0.0
	focus.tween_property(_result, "modulate:a", 1.0, 0.18).set_delay(0.14)
	await focus.finished
	await get_tree().create_timer(0.18).timeout
	match effect_id:
		"upgrade_card":
			_result.text = "Choose the card that will carry the new edge."
			await get_tree().create_timer(0.42).timeout
			resolved.emit(effect_id)
		"gain_overkill":
			OKRunState.gain_ok(10, "pre_battle_offer")
			_result.text = "+10 OVERKILL BANKED  ·  THE SPARK IS YOURS"
			_continue.show()
			_continue.grab_focus()
		"gain_vitality":
			RunManager.apply_max_hp_change(3)
			_result.text = "+3 MAX VITALITY  ·  FRAME RESTORED"
			_continue.show()
			_continue.grab_focus()


func _finish() -> void:
	if _selected_effect.is_empty(): return
	resolved.emit(_selected_effect)
