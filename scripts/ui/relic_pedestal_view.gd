class_name RelicPedestalView extends Control
## Shared relic presentation for battle choices, rewards, shop and collection.

signal selected(relic_data: ClockRelicData)
signal previewed(view: RelicPedestalView)
signal preview_ended

@onready var _card_panel: Panel = %CardPanel
@onready var _accent_primary: ColorRect = %AccentPrimary
@onready var _accent_secondary: ColorRect = %AccentSecondary
@onready var _margin: MarginContainer = %Margin
@onready var _vbox: VBoxContainer = %VBox
@onready var _role_badge: Label = %RoleBadge
@onready var _name_label: Label = %NameLabel
@onready var _title_rule: ColorRect = %TitleRule
@onready var _art_frame: Control = %ArtFrame
@onready var _art_backdrop: Panel = %ArtBackdrop
@onready var _art_glow: TextureRect = %ArtGlow
@onready var _art_rect: TextureRect = %ArtRect
@onready var _effect_frame: PanelContainer = %EffectFrame
@onready var _desc_label: RichTextLabel = %DescLabel
@onready var _slot_button: Button = %SlotButton

var relic: ClockRelicData
var _hover_tween: Tween = null
var _battle_layout: bool = false
var _choice_style: StyleBoxFlat
var _pulse_time: float = 0.0
var _presentation_mode: String = "standard"
var _light_strokes: RelicLightStrokes


func _ready() -> void:
	custom_minimum_size = Vector2(300, 440)
	_card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_accent_primary.hide()
	_accent_secondary.hide()
	_title_rule.hide()
	_role_badge.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_font_size_override("font_size", 26)
	_name_label.add_theme_font_override("font", ScreenDesign.display_font())
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_art_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Remove the former broad radial bloom: at UI scale it reads like fog in a
	# rectangular card. Hard-edged essence-colored lines now provide the aura.
	_art_glow.hide()
	_light_strokes = preload("res://scripts/ui/relic_light_strokes.gd").new() as RelicLightStrokes
	_light_strokes.name = "RelicLightStrokes"
	_art_frame.add_child(_light_strokes)
	_art_frame.move_child(_light_strokes, 0)
	AmbientMotion.idle_bob(_art_rect, 3.0, 3.2)
	_desc_label.add_theme_font_size_override("normal_font_size", 18)
	_slot_button.add_theme_font_size_override("font_size", 18)
	_slot_button.custom_minimum_size.y = 48
	for display: Control in [_role_badge, _name_label, _title_rule, _art_frame, _art_backdrop, _art_rect, _effect_frame, _desc_label]:
		display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_button.pressed.connect(_on_button_pressed)
	_slot_button.mouse_entered.connect(func() -> void: previewed.emit(self))
	_slot_button.focus_entered.connect(func() -> void: previewed.emit(self))
	_slot_button.focus_exited.connect(func() -> void: preview_ended.emit())
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(func() -> void:
		pivot_offset = size * 0.5
		_card_panel.pivot_offset = size * 0.5
	)
	modulate.a = 0.0
	var arrival := create_tween()
	arrival.tween_interval(float(get_index()) * 0.07)
	arrival.tween_property(self, "modulate:a", 1.0, 0.28)
	_slot_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("111d26ed") if state == "normal" else Color("263946f5")
		button_style.border_color = Color("8d765499") if state == "normal" else Color("f2ce91")
		button_style.set_border_width_all(1)
		button_style.set_corner_radius_all(5)
		button_style.content_margin_top = 7
		button_style.content_margin_bottom = 7
		_slot_button.add_theme_stylebox_override(state, button_style)
	_slot_button.add_theme_color_override("font_color", Color("efd9ad"))
	_slot_button.add_theme_color_override("font_disabled_color", Color("b8c3cc"))
	_slot_button.mouse_exited.connect(func() -> void: preview_ended.emit())
	_slot_button.focus_entered.connect(_on_mouse_entered)
	_slot_button.focus_exited.connect(_on_mouse_exited)
	_desc_label.theme_changed.connect(func() -> void: call_deferred("_fit_content"))
	_fit_content()

func _fit_content() -> void:
	if _battle_layout:
		custom_minimum_size = Vector2(320, 370)
		return
	match _presentation_mode:
		"collection": custom_minimum_size = Vector2(272, 370)
		"shop": custom_minimum_size = Vector2(246, 402)
		"gallery": custom_minimum_size = Vector2(280, 448)
		_: custom_minimum_size = Vector2(300, 440)


func _gui_input(event: InputEvent) -> void:
	# The relic object is the choice itself: clicking its art/body performs the
	# same explicit action as the button. The action button remains for clarity,
	# keyboard/controller access, and collection-only views remain non-selectable.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _slot_button.visible and not _slot_button.disabled:
			_on_button_pressed()
		accept_event()

func use_battle_layout() -> void:
	_battle_layout = true
	_presentation_mode = "battle"
	custom_minimum_size = Vector2(320, 370)
	pivot_offset = Vector2(160, 185)
	_card_panel.pivot_offset = pivot_offset
	# Keep the battle card in the same deterministic vertical container as every
	# other relic presentation. Reparenting these controls into absolute
	# positions allowed their old container transforms to survive for a frame,
	# leaving the title behind the artwork on some resolutions.
	_margin.offset_left = 14
	_margin.offset_top = 4
	_margin.offset_right = -14
	_margin.offset_bottom = -4
	_vbox.add_theme_constant_override("separation", 2)
	_role_badge.hide()
	_name_label.custom_minimum_size.y = 28
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_art_frame.custom_minimum_size.y = 200
	_art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Two-line dual-effect relics need a little more breathing room at the
	# battle text size; otherwise their second line is clipped beneath the art.
	_effect_frame.custom_minimum_size.y = 72
	var effect_margin: MarginContainer = _effect_frame.get_node("EffectMargin")
	effect_margin.add_theme_constant_override("margin_top", 2)
	effect_margin.add_theme_constant_override("margin_bottom", 2)
	_desc_label.fit_content = false
	_desc_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_button.custom_minimum_size.y = 48
	_name_label.add_theme_font_size_override("font_size", 22)
	_desc_label.add_theme_font_size_override("normal_font_size", 20)
	_slot_button.add_theme_font_size_override("font_size", 19)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBoxFlat = _slot_button.get_theme_stylebox(state).duplicate()
		style.content_margin_top = 2
		style.content_margin_bottom = 2
		_slot_button.add_theme_stylebox_override(state, style)


func use_collection_layout() -> void:
	_presentation_mode = "collection"
	custom_minimum_size = Vector2(272, 370)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_margin.offset_left = 13
	_margin.offset_top = 13
	_margin.offset_right = -13
	_margin.offset_bottom = -12
	_vbox.add_theme_constant_override("separation", 3)
	_role_badge.custom_minimum_size.y = 17
	_role_badge.add_theme_font_size_override("font_size", 13)
	_name_label.custom_minimum_size.y = 29
	_name_label.add_theme_font_size_override("font_size", 22)
	_art_frame.custom_minimum_size.y = 177
	_effect_frame.custom_minimum_size.y = 67
	_desc_label.add_theme_font_size_override("normal_font_size", 16)
	_slot_button.hide()


func use_shop_layout() -> void:
	_presentation_mode = "shop"
	custom_minimum_size = Vector2(246, 402)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_margin.offset_left = 13
	_margin.offset_top = 13
	_margin.offset_right = -13
	_margin.offset_bottom = -12
	_vbox.add_theme_constant_override("separation", 4)
	_role_badge.custom_minimum_size.y = 18
	_role_badge.add_theme_font_size_override("font_size", 13)
	_name_label.custom_minimum_size.y = 30
	_name_label.add_theme_font_size_override("font_size", 22)
	_art_frame.custom_minimum_size.y = 184
	_effect_frame.custom_minimum_size.y = 66
	_desc_label.add_theme_font_size_override("normal_font_size", 16)
	_slot_button.custom_minimum_size.y = 46
	_slot_button.add_theme_font_size_override("font_size", 16)


func use_gallery_layout() -> void:
	_presentation_mode = "gallery"
	custom_minimum_size = Vector2(280, 448)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_role_badge.add_theme_font_size_override("font_size", 15)
	_name_label.add_theme_font_size_override("font_size", 25)
	_art_frame.custom_minimum_size.y = 230
	_effect_frame.custom_minimum_size.y = 82
	_desc_label.add_theme_font_size_override("normal_font_size", 18)
	_slot_button.hide()


func set_stack_count(count: int) -> void:
	if count <= 1:
		return
	_role_badge.text += "    ×%d OWNED" % count
	tooltip_text += "\n\n%d copies owned." % count


func set_instance_identities(entries: Array[Dictionary]) -> void:
	if entries.is_empty():
		return
	var identities := PackedStringArray()
	for entry: Dictionary in entries:
		identities.append(ClockInventory.instance_identity(entry))
	tooltip_text += "\n\nINSTANCE IDENTITIES\n" + "\n".join(identities)


func bind_relic(relic_data: ClockRelicData, action_label: String = "SLOT") -> void:
	relic = relic_data
	if relic == null:
		return

	_name_label.text = relic.name
	_role_badge.text = relic.compact_affinity_name().to_upper().replace(" + ", "  ·  ")
	_desc_label.text = summary(relic).to_upper()
	_slot_button.text = action_label

	var role_col: Color = relic.primary_color()
	var secondary_col: Color = relic.secondary_color()
	var has_secondary: bool = relic.secondary_essence >= 0
	var blended: Color = role_col.lerp(secondary_col, 0.5) if has_secondary else role_col
	_role_badge.add_theme_color_override("font_color", role_col)
	ScreenDesign.add_actionable_fx(_slot_button, role_col, true)
	_title_rule.color = Color(blended, 0.56)
	_accent_primary.color = role_col
	_accent_secondary.color = secondary_col
	_accent_secondary.visible = has_secondary
	_accent_primary.anchor_right = 0.5 if has_secondary else 1.0
	_accent_primary.offset_right = 0.0

	_card_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_choice_style = null

	var art_style := StyleBoxFlat.new()
	art_style.bg_color = Color("030a1020")
	art_style.border_color = Color(blended, 0.0)
	art_style.set_border_width_all(0)
	art_style.set_corner_radius_all(0)
	_art_backdrop.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var effect_style := StyleBoxFlat.new()
	effect_style.bg_color = Color("0d1b2555")
	effect_style.border_color = Color(blended, 0.0)
	effect_style.set_border_width_all(0)
	effect_style.set_corner_radius_all(0)
	_effect_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_light_strokes.set_essences(role_col, secondary_col, has_secondary)

	_load_art(relic.art_id)
	tooltip_text = "%s\n%s\n%s\n\nBlock lasts until absorbed or battle ends.\nStrength: extra damage per hit. Thorns: damage returned when hit.\nBleed: HP lost each tick. Weak: 25%% less attack damage.\nVulnerable: 50%% more damage taken. Lifesteal: heal actual HP damage dealt." % [relic.name, relic.affinity_name(), ClockInventory.describe(relic)]
	ScreenDesign.apply_text_size(self)
	call_deferred("_fit_content")


func _load_art(art_id: String) -> void:
	_art_rect.texture = RelicArt.load_texture(art_id)


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
	if _battle_layout and relic != null and not AudioManager.reduced_motion: _pulse_time += delta

static func summary(r: ClockRelicData) -> String:
	var lines: Array[String] = []
	if r.base_damage > 0: lines.append("%d damage%s" % [r.base_damage," × %d" % r.hits if r.hits > 1 else ""])
	if r.lifesteal: lines.append("Heal HP dealt")
	if r.base_block > 0: lines.append("%d persistent Block" % r.base_block)
	if r.grant_overkill > 0: lines.append("Gain %d Overkill" % r.grant_overkill)
	if r.next_attack_multiplier > 1: lines.append("Next attack: ×%d" % r.next_attack_multiplier)
	if r.bonus_damage_next_hit > 0: lines.append("Next attack: +%d" % r.bonus_damage_next_hit)
	for pair: Array in [[r.apply_strength,"Strength"],[r.apply_thorns,"Thorns"],[r.apply_bleed,"Bleed"],[r.apply_weak,"Weak"],[r.apply_vulnerable,"Vulnerable"]]:
		if int(pair[0]) > 0: lines.append(("Enemy: " if str(pair[1]) in ["Bleed","Weak","Vulnerable"] else "Gain ") + "%d %s" % pair)
	if r.conditional_damage > 0: lines.append("%d at enemy HP ≤%d%%" % [r.conditional_damage,int(r.conditional_hp_threshold_pct*100)])
	if r.recoil_block_on_overkill: lines.append("Overkill → Block")
	return "\n".join(lines)
