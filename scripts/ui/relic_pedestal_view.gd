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
var _choice_style: StyleBoxFlat
var _pulse_time: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(300, 370)
	_role_badge.add_theme_font_size_override("font_size", 19)
	_name_label.add_theme_font_size_override("font_size", 26)
	_name_label.add_theme_font_override("font", ScreenDesign.display_font())
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_art_rect.custom_minimum_size.y = 140
	_desc_label.add_theme_font_size_override("normal_font_size", 24)
	_slot_button.add_theme_font_size_override("font_size", 22)
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
	_slot_button.add_theme_color_override("font_disabled_color", Color("b8c3cc"))
	_card_panel.get_node("Margin").minimum_size_changed.connect(_fit_content)
	_slot_button.mouse_exited.connect(func() -> void: preview_ended.emit())
	_slot_button.focus_entered.connect(_on_mouse_entered)
	_slot_button.focus_exited.connect(_on_mouse_exited)

func _fit_content() -> void:
	if _battle_layout:
		_desc_label.size = Vector2(280,120)
		_slot_button.size = Vector2(364, 48)
	else:
		custom_minimum_size.y = maxf(370, _card_panel.get_node("Margin").get_combined_minimum_size().y)


func _gui_input(event: InputEvent) -> void:
	# Only the explicit action button commits; inspecting art must be harmless.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()

func use_battle_layout() -> void:
	_battle_layout = true
	custom_minimum_size = Vector2(380,232)
	pivot_offset = Vector2(190,97)
	_card_panel.pivot_offset = pivot_offset
	for child in [_role_badge,_name_label,_art_rect,_desc_label,_slot_button]:
		child.reparent(_card_panel)
		child.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_card_panel.get_node("Margin").hide()
	_role_badge.hide()
	_role_badge.position = Vector2(86,10)
	_role_badge.size = Vector2(220,20)
	_role_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_label.position = Vector2(86,10)
	_name_label.size = Vector2(280,36)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_art_rect.custom_minimum_size = Vector2.ZERO
	_art_rect.position = Vector2(10,48)
	_art_rect.size = Vector2(66,78)
	_desc_label.position = Vector2(86,48)
	_desc_label.fit_content = false
	_desc_label.size = Vector2(280,120)
	_slot_button.position = Vector2(8,176)
	_slot_button.size = Vector2(364,48)
	_slot_button.custom_minimum_size.y = 48
	_name_label.add_theme_font_size_override("font_size",25)
	_desc_label.add_theme_font_size_override("normal_font_size",24)
	_slot_button.add_theme_font_size_override("font_size",24)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBoxFlat = _slot_button.get_theme_stylebox(state).duplicate()
		style.content_margin_top = 2
		style.content_margin_bottom = 2
		_slot_button.add_theme_stylebox_override(state, style)


func bind_relic(relic_data: ClockRelicData, action_label: String = "SLOT") -> void:
	relic = relic_data
	if relic == null:
		return

	_name_label.text = relic.name
	_role_badge.text = "[ %s ]" % ClockRelicData.role_to_name(relic.role).to_upper()
	_desc_label.text = ClockInventory.describe(relic)
	if _battle_layout:
		_desc_label.text = summary(relic)
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
	_choice_style = panel_style

	_load_art(relic.art_id)
	tooltip_text = "%s\n%s\n\nBlock lasts until absorbed or battle ends.\nStrength: extra damage per hit. Thorns: damage returned when hit.\nBleed: HP lost each tick. Weak: 25%% less attack damage.\nVulnerable: 50%% more damage taken. Lifesteal: heal actual HP damage dealt." % [relic.name, ClockInventory.describe(relic)]
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
	if AudioManager.reduced_motion or _battle_layout: return
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

func _process(delta: float) -> void:
	if not _battle_layout or _choice_style == null or relic == null: return
	var color: Color = ClockRelicData.role_to_color(relic.role)
	if not is_visible_in_tree() or _slot_button.disabled:
		_choice_style.border_color = color.darkened(0.42)
		return
	if not AudioManager.reduced_motion: _pulse_time += delta
	var pulse: float = 0.45 if AudioManager.reduced_motion else (sin(_pulse_time * 3.0) + 1.0) * 0.5
	_choice_style.border_color = color.lerp(Color("fff0c4"), 0.15 + pulse * 0.35)
	_choice_style.shadow_color = Color(color, 0.12 + pulse * 0.2)
	_choice_style.shadow_size = 8 + int(pulse * 5)

static func summary(r: ClockRelicData) -> String:
	var lines: Array[String] = []
	if r.base_damage > 0: lines.append("%d damage%s" % [r.base_damage," × %d" % r.hits if r.hits > 1 else ""])
	if r.lifesteal: lines.append("Heal HP dealt")
	if r.base_block > 0: lines.append("%d persistent Block" % r.base_block)
	if r.next_attack_multiplier > 1: lines.append("Next attack: ×%d" % r.next_attack_multiplier)
	if r.bonus_damage_next_hit > 0: lines.append("Next attack: +%d" % r.bonus_damage_next_hit)
	for pair: Array in [[r.apply_strength,"Strength"],[r.apply_thorns,"Thorns"],[r.apply_bleed,"Bleed"],[r.apply_weak,"Weak"],[r.apply_vulnerable,"Vulnerable"]]:
		if int(pair[0]) > 0: lines.append(("Enemy: " if str(pair[1]) in ["Bleed","Weak","Vulnerable"] else "Gain ") + "%d %s" % pair)
	if r.conditional_damage > 0: lines.append("%d at enemy HP ≤%d%%" % [r.conditional_damage,int(r.conditional_hp_threshold_pct*100)])
	if r.recoil_block_on_overkill: lines.append("Overkill → Block")
	return "\n".join(lines)
