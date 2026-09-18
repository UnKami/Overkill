class_name RelicPedestalView extends Control
## Shared relic presentation for battle choices, rewards, shop and collection.

signal selected(relic_data: ClockRelicData)
signal previewed(view: RelicPedestalView)
signal preview_ended

@onready var _card_panel: Panel = %CardPanel
@onready var _role_badge: Label = %RoleBadge
@onready var _name_label: Label = %NameLabel
@onready var _art_rect: TextureRect = %ArtRect
@onready var _desc_label: RichTextLabel = %DescLabel
@onready var _slot_button: Button = %SlotButton

var relic: ClockRelicData
var _hover_tween: Tween = null
var _battle_layout: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(300, 370)
	_role_badge.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_font_size_override("font_size", 23)
	_name_label.add_theme_font_override("font", ScreenDesign.display_font())
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_art_rect.custom_minimum_size.y = 140
	_desc_label.add_theme_font_size_override("normal_font_size", 19)
	_slot_button.add_theme_font_size_override("font_size", 17)
	_slot_button.custom_minimum_size.y = 48
	for display: Control in [_role_badge, _name_label, _art_rect, _desc_label]:
		display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_button.pressed.connect(_on_button_pressed)
	_slot_button.mouse_entered.connect(func() -> void: previewed.emit(self))
	_slot_button.focus_entered.connect(func() -> void: previewed.emit(self))
	_slot_button.focus_exited.connect(func() -> void: preview_ended.emit())
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_card_panel.pivot_offset = Vector2(130, 145)
	modulate.a = 0.0
	var arrival := create_tween()
	arrival.tween_interval(float(get_index()) * 0.07)
	arrival.tween_property(self, "modulate:a", 1.0, 0.28)
	_slot_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("17232c") if state == "normal" else Color("30414a")
		button_style.border_color = Color("8d7654") if state == "normal" else Color("ebc68a")
		button_style.set_border_width_all(1)
		button_style.set_corner_radius_all(3)
		button_style.content_margin_top = 7
		button_style.content_margin_bottom = 7
		_slot_button.add_theme_stylebox_override(state, button_style)
	_slot_button.add_theme_color_override("font_color", Color("efd9ad"))
	_card_panel.get_node("Margin").minimum_size_changed.connect(_fit_content)
	_slot_button.mouse_exited.connect(func() -> void: preview_ended.emit())
	_slot_button.focus_entered.connect(_on_mouse_entered)
	_slot_button.focus_exited.connect(_on_mouse_exited)

func _fit_content() -> void:
	if not _battle_layout:
		custom_minimum_size.y = maxf(370, _card_panel.get_node("Margin").get_combined_minimum_size().y)


func _gui_input(event: InputEvent) -> void:
	# Only the explicit action button commits; inspecting art must be harmless.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()

func use_battle_layout() -> void:
	_battle_layout = true
	custom_minimum_size = Vector2(368,220)
	pivot_offset = Vector2(184,110)
	_card_panel.pivot_offset = pivot_offset
	for child in [_role_badge,_name_label,_art_rect,_desc_label,_slot_button]:
		child.reparent(_card_panel)
		child.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_card_panel.get_node("Margin").hide()
	_role_badge.position = Vector2(132,16)
	_role_badge.size = Vector2(220,20)
	_role_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_label.position = Vector2(132,42)
	_name_label.size = Vector2(220,32)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_art_rect.custom_minimum_size = Vector2.ZERO
	_art_rect.position = Vector2(16,34)
	_art_rect.size = Vector2(104,120)
	_desc_label.position = Vector2(132,80)
	_desc_label.size = Vector2(220,84)
	_desc_label.fit_content = false
	_slot_button.position = Vector2(16,170)
	_slot_button.size = Vector2(336,38)
	_slot_button.custom_minimum_size.y = 38
	_name_label.add_theme_font_size_override("font_size",20)
	_desc_label.add_theme_font_size_override("normal_font_size",18)
	_slot_button.add_theme_font_size_override("font_size",18)


func bind_relic(relic_data: ClockRelicData, action_label: String = "SLOT") -> void:
	relic = relic_data
	if relic == null:
		return

	_name_label.text = relic.name
	_role_badge.text = "[ %s ]" % ClockRelicData.role_to_name(relic.role).to_upper()
	_desc_label.text = ClockInventory.describe(relic)
	_slot_button.text = action_label

	var role_col := ClockRelicData.role_to_color(relic.role)
	_role_badge.add_theme_color_override("font_color", role_col)

	var panel_style := StyleBoxFlat.new()
	panel_style.set_corner_radius_all(5)
	panel_style.bg_color = Color("#101921")
	panel_style.border_color = role_col.darkened(0.42)
	panel_style.set_border_width_all(1)
	panel_style.border_width_top = 3
	panel_style.shadow_color = Color(0, 0, 0, 0.65)
	panel_style.shadow_size = 16
	_card_panel.add_theme_stylebox_override("panel", panel_style)

	_load_art(relic.art_id)
	tooltip_text = "%s\n%s" % [relic.name, relic.description]
	ScreenDesign.apply_text_size(self)
	call_deferred("_fit_content")


func _load_art(art_id: String) -> void:
	var candidates: Array[String] = [
		"res://assets/relics/active/%s.jpg" % art_id,
		"res://assets/relics/active/%s.png" % art_id,
		"res://assets/relics/%s.png" % art_id,
		"res://assets/relics/%s.jpg" % art_id,
		"res://assets/cards/executioner/%s.jpg" % art_id,
		"res://assets/cards/executioner/%s.png" % art_id,
		"res://assets/cards/excess/%s.jpg" % art_id,
		"res://assets/cards/excess/%s.png" % art_id,
		"res://assets/icons/ui/%s.png" % art_id,
	]
	for p in candidates:
		if ResourceLoader.exists(p):
			_art_rect.texture = ResourceLoader.load(p)
			return
	_art_rect.texture = null


func _on_button_pressed() -> void:
	if relic != null and not _slot_button.disabled:
		AudioManager.play_clock_sound("slot")
		selected.emit(relic)


func _on_mouse_entered() -> void:
	previewed.emit(self)
	if AudioManager.reduced_motion: return
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", Vector2(1.025, 1.025), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(_art_rect, "modulate", Color(1.15, 1.15, 1.15), 0.16)


func _on_mouse_exited() -> void:
	preview_ended.emit()
	if AudioManager.reduced_motion:
		scale = Vector2.ONE
		return
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE)
	_hover_tween.tween_property(_art_rect, "modulate", Color.WHITE, 0.16)
