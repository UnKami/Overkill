class_name RelicPedestalView extends Control
## Shared relic presentation for battle choices, rewards, shop and collection.
## Supports live-calculated combat numbers, positional tags, and SmartHoverInspector.

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
var _essence_sunburst: TextureRect
var _live_stats: Dictionary = {}
var _target_hour_hint: int = 0
var _stack_count: int = 1
var _instance_identities: Array[Dictionary] = []

const ESSENCE_SUNBURST_NAMES: Array[String] = ["orange", "blue", "purple", "green", "blood_red"]
const ESSENCE_PAIR_KEYS: Array[String] = ["attack", "block", "buff", "debuff", "overkill"]


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
	# The dedicated transparent sunburst is the sole relic aura. Do not stack
	# the retired procedural spokes over it: their mismatched rays look noisy.
	_art_glow.hide()
	_essence_sunburst = TextureRect.new()
	_essence_sunburst.name = "EssenceSunburst"
	_essence_sunburst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_essence_sunburst.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_essence_sunburst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_essence_sunburst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_essence_sunburst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_essence_sunburst.modulate = Color(1.0, 1.0, 1.0, 0.34)
	_art_frame.add_child(_essence_sunburst)
	_art_frame.move_child(_essence_sunburst, 0)
	AmbientMotion.idle_bob(_art_rect, 3.0, 3.2)
	_desc_label.add_theme_font_size_override("normal_font_size", 18)
	_desc_label.add_theme_font_size_override("bold_font_size", 18)
	_slot_button.add_theme_font_size_override("font_size", 18)
	_slot_button.custom_minimum_size.y = 44
	for display: Control in [_role_badge, _name_label, _title_rule, _art_frame, _art_backdrop, _art_rect, _essence_sunburst, _effect_frame, _desc_label]:
		display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_button.pressed.connect(_on_button_pressed)
	_slot_button.mouse_entered.connect(_on_slot_button_hover_entered)
	_slot_button.focus_entered.connect(_on_slot_button_hover_entered)
	_slot_button.focus_exited.connect(_on_slot_button_hover_exited)
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
		button_style.content_margin_top = 6
		button_style.content_margin_bottom = 6
		_slot_button.add_theme_stylebox_override(state, button_style)
	_slot_button.add_theme_color_override("font_color", Color("efd9ad"))
	_slot_button.add_theme_color_override("font_disabled_color", Color("b8c3cc"))
	_slot_button.mouse_exited.connect(_on_slot_button_hover_exited)
	_desc_label.theme_changed.connect(func() -> void: call_deferred("_fit_content"))
	_fit_content()


func _fit_content() -> void:
	if _battle_layout:
		custom_minimum_size = Vector2(284, 286)
		return
	match _presentation_mode:
		"collection": custom_minimum_size = Vector2(272, 370)
		"shop": custom_minimum_size = Vector2(246, 402)
		"gallery": custom_minimum_size = Vector2(280, 448)
		_: custom_minimum_size = Vector2(300, 440)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _slot_button.visible and not _slot_button.disabled:
			_on_button_pressed()
		accept_event()


func use_battle_layout() -> void:
	_battle_layout = true
	_presentation_mode = "battle"
	custom_minimum_size = Vector2(284, 286)
	pivot_offset = Vector2(142, 143)
	_card_panel.pivot_offset = pivot_offset
	_margin.offset_left = 10
	_margin.offset_top = 0
	_margin.offset_right = -10
	_margin.offset_bottom = 0
	_vbox.add_theme_constant_override("separation", 1)
	_role_badge.show()
	_role_badge.custom_minimum_size.y = 16
	_role_badge.add_theme_font_size_override("font_size", 12)
	_name_label.custom_minimum_size.y = 26
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_art_frame.custom_minimum_size.y = 136
	_art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_effect_frame.custom_minimum_size.y = 66
	var effect_margin: MarginContainer = _effect_frame.get_node("EffectMargin")
	effect_margin.add_theme_constant_override("margin_top", 2)
	effect_margin.add_theme_constant_override("margin_bottom", 2)
	_desc_label.fit_content = false
	_desc_label.text_direction = Control.TEXT_DIRECTION_AUTO
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_button.custom_minimum_size.y = 40
	_name_label.add_theme_font_size_override("font_size", 21)
	_desc_label.add_theme_font_size_override("normal_font_size", 17)
	_desc_label.add_theme_font_size_override("bold_font_size", 17)
	_slot_button.add_theme_font_size_override("font_size", 17)
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
	_desc_label.add_theme_font_size_override("bold_font_size", 16)
	_slot_button.hide()


func use_shop_layout() -> void:
	_presentation_mode = "shop"
	custom_minimum_size = Vector2(246, 352)
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_margin.offset_left = 13
	_margin.offset_top = 10
	_margin.offset_right = -13
	_margin.offset_bottom = -10
	_vbox.add_theme_constant_override("separation", 3)
	_role_badge.custom_minimum_size.y = 18
	_role_badge.add_theme_font_size_override("font_size", 13)
	_name_label.custom_minimum_size.y = 30
	_name_label.add_theme_font_size_override("font_size", 22)
	_art_frame.custom_minimum_size.y = 155
	_effect_frame.custom_minimum_size.y = 60
	_desc_label.add_theme_font_size_override("normal_font_size", 16)
	_desc_label.add_theme_font_size_override("bold_font_size", 16)
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
	_desc_label.add_theme_font_size_override("bold_font_size", 18)
	_slot_button.hide()


func set_stack_count(count: int) -> void:
	_stack_count = count
	if count <= 1:
		return
	_role_badge.text += "    ×%d OWNED" % count


func set_instance_identities(entries: Array[Dictionary]) -> void:
	_instance_identities = entries


func bind_relic(relic_data: ClockRelicData, action_label: String = "SLOT") -> void:
	relic = relic_data
	if relic == null:
		return

	_name_label.text = relic.name
	_slot_button.text = action_label

	var role_col: Color = relic.primary_color()
	var secondary_col: Color = relic.secondary_color()
	var has_secondary: bool = relic.secondary_essence >= 0
	var blended: Color = role_col.lerp(secondary_col, 0.5) if has_secondary else role_col
	_role_badge.add_theme_color_override("font_color", role_col.lightened(0.18))
	ScreenDesign.add_actionable_fx(_slot_button, role_col, true)
	_title_rule.color = Color(blended, 0.56)
	_accent_primary.color = role_col
	_accent_secondary.color = secondary_col
	_accent_secondary.visible = has_secondary
	_accent_primary.anchor_right = 0.5 if has_secondary else 1.0
	_accent_primary.offset_right = 0.0
	var sunburst_path: String = essence_sunburst_path(relic)
	_essence_sunburst.texture = load(sunburst_path) as Texture2D if not sunburst_path.is_empty() else null
	_essence_sunburst.visible = _essence_sunburst.texture != null

	_card_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_choice_style = null
	_art_backdrop.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_effect_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_load_art(relic.art_id)

	# Keep native tooltip_text empty so SmartHoverInspector is the sole hover UI
	tooltip_text = ""

	var default_stats: Dictionary = SmartHoverInspector.compute_relic_live_stats(relic, null, 0)
	set_live_preview(default_stats)
	if _battle_layout:
		call_deferred("refresh_live_combat_preview")

	ScreenDesign.apply_text_size(self)
	call_deferred("_fit_content")


func set_live_preview(live_stats: Dictionary) -> void:
	_live_stats = live_stats
	if relic == null:
		return
	var pos_tags: Array = live_stats.get("positional_tags", [])
	var base_role: String = relic.compact_affinity_name().to_upper().replace(" + ", " · ")
	if not pos_tags.is_empty():
		_role_badge.text = "%s  %s" % [base_role, " ".join(pos_tags)]
		_role_badge.show()
	else:
		_role_badge.text = base_role
		if _battle_layout:
			_role_badge.hide()
		else:
			_role_badge.show()
	if _stack_count > 1 and not _role_badge.text.contains("OWNED"):
		_role_badge.text += "  ×%d OWNED" % _stack_count
	_desc_label.text = live_summary_bbcode(relic, live_stats)


func refresh_live_combat_preview(battle: Object = null, target_hour: int = 0) -> void:
	if relic == null:
		return
	var resolved_battle: Object = battle if battle != null else SmartHoverInspector.find_combat_controller(self)
	if resolved_battle == null:
		return
	var resolved_hour: int = target_hour if target_hour > 0 else SmartHoverInspector._resolve_default_target_hour(resolved_battle)
	_target_hour_hint = resolved_hour
	var stats: Dictionary = SmartHoverInspector.compute_relic_live_stats(relic, resolved_battle, resolved_hour)
	set_live_preview(stats)


func _load_art(art_id: String) -> void:
	_art_rect.texture = RelicArt.load_texture(art_id)


static func essence_sunburst_path(relic_data: ClockRelicData) -> String:
	if relic_data == null:
		return ""
	var primary_index: int = clampi(int(relic_data.primary_essence), 0, ESSENCE_SUNBURST_NAMES.size() - 1)
	var filename: String = ESSENCE_SUNBURST_NAMES[primary_index]
	if relic_data.secondary_essence >= 0:
		var first_index: int = mini(primary_index, int(relic_data.secondary_essence))
		var second_index: int = maxi(primary_index, int(relic_data.secondary_essence))
		filename = "%s_%s" % [ESSENCE_PAIR_KEYS[first_index], ESSENCE_PAIR_KEYS[second_index]]
	var path: String = "res://assets/relics/essence_sunbursts/%s.png" % filename
	return path if ResourceLoader.exists(path) else ""


func _on_button_pressed() -> void:
	if relic != null and not _slot_button.disabled:
		AudioManager.play_clock_sound("slot")
		selected.emit(relic)


func _on_slot_button_hover_entered() -> void:
	_show_smart_hover()
	previewed.emit(self)


func _on_slot_button_hover_exited() -> void:
	if not get_global_rect().has_point(get_global_mouse_position()):
		SmartHoverInspector.hide_inspector(self)
		preview_ended.emit()


func _on_mouse_entered() -> void:
	_show_smart_hover()
	previewed.emit(self)
	if AudioManager.reduced_motion or _battle_layout:
		return
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", Vector2(1.025, 1.025), 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(_art_rect, "modulate", Color(1.15, 1.15, 1.15), 0.16)


func _on_mouse_exited() -> void:
	if not get_global_rect().has_point(get_global_mouse_position()):
		SmartHoverInspector.hide_inspector(self)
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


func _show_smart_hover() -> void:
	if relic == null:
		return
	if _battle_layout:
		refresh_live_combat_preview()
	SmartHoverInspector.inspect_pedestal(self, null, _target_hour_hint)


func _process(delta: float) -> void:
	if _battle_layout and relic != null and not AudioManager.reduced_motion:
		_pulse_time += delta


static func summary(r: ClockRelicData) -> String:
	if r == null:
		return ""
	var lines: Array[String] = []
	if r.base_damage > 0:
		lines.append("%d damage%s" % [r.base_damage, " × %d" % r.hits if r.hits > 1 else ""])
	if r.damage_per_current_block_pct > 0.0:
		lines.append("+%d%% Block as DMG" % roundi(r.damage_per_current_block_pct * 100.0))
	if r.thorns_to_damage_multiplier > 0.0:
		lines.append("+%d× Thorns as DMG" % roundi(r.thorns_to_damage_multiplier))
	if r.damage_per_enemy_bleed > 0:
		lines.append("+%d DMG / Bleed" % r.damage_per_enemy_bleed)
	if r.damage_per_banked_overkill_div > 0:
		lines.append("+1 DMG / %d OK" % r.damage_per_banked_overkill_div)
	if r.sector_finisher_bonus_damage > 0:
		lines.append("Finisher: +%d DMG" % r.sector_finisher_bonus_damage)
	if r.sector_finisher_hits_bonus > 0:
		lines.append("Finisher: +%d Hit" % r.sector_finisher_hits_bonus)
	if r.resonance_essence_bonus > 0:
		lines.append("Resonance: +%d" % r.resonance_essence_bonus)
	if r.echo_previous_hour:
		lines.append("Echo Prev Hour")
	if r.charge_next_socket_multiplier > 0.0:
		lines.append("Next Socket +%.1f×" % r.charge_next_socket_multiplier)
	if r.lifesteal:
		lines.append("Heal HP dealt")
	if r.base_block > 0:
		lines.append("%d persistent Block" % r.base_block)
	if r.multiply_current_block > 1.0:
		lines.append("Block ×%.1f" % r.multiply_current_block)
	if r.grant_overkill > 0:
		lines.append("Gain %d Overkill" % r.grant_overkill)
	if r.overkill_extraction_pct > 0.0:
		lines.append("Harvest %d%% OK" % roundi(r.overkill_extraction_pct * 100.0))
	if r.next_attack_multiplier > 1:
		lines.append("Next attack: ×%d" % r.next_attack_multiplier)
	if r.bonus_damage_next_hit > 0:
		lines.append("Next attack: +%d" % r.bonus_damage_next_hit)
	for pair: Array in [[r.apply_strength, "Strength"], [r.apply_thorns, "Thorns"], [r.apply_bleed, "Bleed"], [r.apply_weak, "Weak"], [r.apply_vulnerable, "Vulnerable"]]:
		if int(pair[0]) > 0:
			lines.append(("Enemy: " if str(pair[1]) in ["Bleed", "Weak", "Vulnerable"] else "Gain ") + "%d %s" % pair)
	if r.multiply_enemy_bleed > 1.0:
		lines.append("Enemy Bleed ×%.1f" % r.multiply_enemy_bleed)
	if r.trigger_bleed_times > 0:
		lines.append("Trigger Bleed ×%d" % r.trigger_bleed_times)
	if r.conditional_damage > 0:
		lines.append("%d at enemy HP ≤%d%%" % [r.conditional_damage, int(r.conditional_hp_threshold_pct * 100)])
	if r.recoil_block_on_overkill:
		lines.append("Overkill → Block")
	return "\n".join(lines)


static func live_summary_bbcode(r: ClockRelicData, live_stats: Dictionary = {}) -> String:
	if r == null:
		return ""
	var base_text: String = summary(r).to_upper()
	if live_stats.is_empty():
		return base_text

	var lines: Array[String] = []
	var live_d: int = int(live_stats.get("live_damage", r.base_damage))
	var live_h: int = int(live_stats.get("live_hits", maxi(1, r.hits)))
	var live_b: int = int(live_stats.get("live_block", r.base_block))
	var d_buffed: bool = bool(live_stats.get("is_damage_buffed", false))
	var d_weak: bool = bool(live_stats.get("is_damage_weakened", false))
	var b_buffed: bool = bool(live_stats.get("is_block_buffed", false))

	if r.base_damage > 0 or live_d > 0:
		var d_str: String = "%d DAMAGE%s" % [live_d, " × %d" % live_h if live_h > 1 else ""]
		if d_buffed:
			lines.append("[color=#67e68d][b]%s[/b][/color]" % d_str)
		elif d_weak:
			lines.append("[color=#ff7a7a][b]%s[/b][/color]" % d_str)
		else:
			lines.append(d_str)

	if r.base_block > 0 or (live_b > 0 and r.multiply_current_block <= 1.0):
		var b_str: String = "%d PERSISTENT BLOCK" % live_b
		if b_buffed:
			lines.append("[color=#67e68d][b]%s[/b][/color]" % b_str)
		else:
			lines.append(b_str)

	if r.multiply_current_block > 1.0:
		lines.append("BLOCK ×%.1f" % r.multiply_current_block)
	if r.sector_finisher_bonus_damage > 0:
		lines.append("[color=#ffd166]FINISHER: +%d DMG[/color]" % r.sector_finisher_bonus_damage)
	if r.sector_finisher_hits_bonus > 0:
		lines.append("[color=#ffd166]FINISHER: +%d HIT[/color]" % r.sector_finisher_hits_bonus)
	if r.resonance_essence_bonus > 0:
		lines.append("[color=#80c8d1]RESONANCE: +%d[/color]" % r.resonance_essence_bonus)
	if r.echo_previous_hour:
		lines.append("[color=#d988ff]ECHO PREV HOUR[/color]")
	if r.charge_next_socket_multiplier > 0.0:
		lines.append("[color=#ffd166]NEXT SOCKET +%.1f×[/color]" % r.charge_next_socket_multiplier)
	if r.lifesteal:
		lines.append("HEAL HP DEALT")
	if r.grant_overkill > 0:
		lines.append("GAIN %d OVERKILL" % r.grant_overkill)
	if r.overkill_extraction_pct > 0.0:
		lines.append("HARVEST %d%% OK" % roundi(r.overkill_extraction_pct * 100.0))
	if r.next_attack_multiplier > 1:
		lines.append("NEXT ATTACK: ×%d" % r.next_attack_multiplier)
	if r.bonus_damage_next_hit > 0:
		lines.append("NEXT ATTACK: +%d" % r.bonus_damage_next_hit)
	for pair: Array in [[r.apply_strength, "STRENGTH"], [r.apply_thorns, "THORNS"], [r.apply_bleed, "BLEED"], [r.apply_weak, "WEAK"], [r.apply_vulnerable, "VULNERABLE"]]:
		if int(pair[0]) > 0:
			lines.append(("ENEMY: " if str(pair[1]) in ["BLEED", "WEAK", "VULNERABLE"] else "GAIN ") + "%d %s" % pair)
	if r.multiply_enemy_bleed > 1.0:
		lines.append("ENEMY BLEED ×%.1f" % r.multiply_enemy_bleed)
	if r.trigger_bleed_times > 0:
		lines.append("TRIGGER BLEED ×%d" % r.trigger_bleed_times)
	if r.conditional_damage > 0:
		lines.append("%d AT ENEMY HP ≤%d%%" % [r.conditional_damage, int(r.conditional_hp_threshold_pct * 100)])
	if r.recoil_block_on_overkill:
		lines.append("OVERKILL → BLOCK")

	return "\n".join(lines) if not lines.is_empty() else base_text
