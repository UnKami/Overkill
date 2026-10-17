class_name ClockSocketView extends Control
## ClockSocketView - Renders an individual 1-to-9 hour socket on a Chronometer.
## Supports live modified damage/block numbers, compound multi-intent enemy readouts,
## Sector Finisher (H3/6/9) crown markers, targetable empty assembly sockets, and SmartHoverInspector.

signal pressed(socket_view: ClockSocketView)
signal previewed(socket_view: ClockSocketView)
signal preview_ended

const COLOR_BUFFED := Color("#67E68D")
const COLOR_WEAKENED := Color("#FF7A7A")
const COLOR_FINISHER_CROWN := Color("#FFD166")

@onready var _glow_ring: Panel = %GlowRing
@onready var _socket_base: Panel = %SocketBase
@onready var _icon_rect: TextureRect = %IconRect
@onready var _hour_label: Label = %HourLabel
@onready var _value_label: Label = %ValueLabel
@onready var _modifier_badge: Label = %ModifierBadge

var data: ClockSocketData
var is_enemy_socket: bool = false
var is_interactive: bool = false:
	set(value):
		is_interactive = value
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW
		if is_instance_valid(_rim_overlay):
			_rim_overlay.queue_redraw()
var is_active_tick: bool = false
var is_targetable_empty: bool = false
var is_selected_target: bool = false

var _hover_tween: Tween = null
var _rim_overlay: Control = null
var _secondary_ring_color: Color = Color(0, 0, 0, 0)
var _has_live_override: bool = false
var _live_damage: int = 0
var _live_hits: int = 1
var _live_block: int = 0
var _live_buffed: bool = false
var _live_weakened: bool = false
var _live_extra_badge: String = ""


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	var mask := ShaderMaterial.new()
	mask.shader = preload("res://assets/ui/combat/circular_art.gdshader")
	_icon_rect.material = mask
	_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var metal := ShaderMaterial.new()
	metal.shader = preload("res://assets/ui/combat/socket_metal.gdshader")
	_socket_base.material = metal
	_icon_rect.modulate = Color(0.65, 0.65, 0.65)
	_hour_label.position.y = -22
	_hour_label.add_theme_constant_override("outline_size", 8)
	_value_label.add_theme_constant_override("outline_size", 8)
	_value_label.offset_left = -46.0
	_value_label.offset_right = 46.0
	_value_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_value_label.clip_text = false
	_modifier_badge.offset_left = -30.0
	_modifier_badge.offset_right = 12.0
	_modifier_badge.add_theme_constant_override("outline_size", 5)
	_modifier_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	focus_mode = Control.FOCUS_ALL
	_hour_label.add_theme_font_size_override("font_size", 24)
	_value_label.add_theme_font_size_override("font_size", 24)
	focus_entered.connect(_on_mouse_entered)
	focus_exited.connect(_on_mouse_exited)

	_rim_overlay = Control.new()
	_rim_overlay.name = "RimOverlay"
	_rim_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rim_overlay.draw.connect(_draw_rim_overlay)
	add_child(_rim_overlay)
	move_child(_rim_overlay, _hour_label.get_index())


func bind_socket(socket_data: ClockSocketData, is_enemy: bool = false) -> void:
	data = socket_data
	is_enemy_socket = is_enemy
	_has_live_override = false
	var is_finisher: bool = socket_data != null and socket_data.hour_index in [3, 6, 9]
	if socket_data != null:
		_hour_label.text = str(socket_data.hour_index)
		if is_finisher and not is_enemy:
			_hour_label.add_theme_color_override("font_color", COLOR_FINISHER_CROWN)
		else:
			_hour_label.add_theme_color_override("font_color", Color("e5e4df"))
	_style_socket(is_enemy)
	refresh_live_from_context()


func set_live_display_values(
	live_damage: int,
	live_hits: int,
	live_block: int,
	is_buffed: bool,
	is_weakened: bool,
	extra_badge: String = ""
) -> void:
	_has_live_override = true
	_live_damage = live_damage
	_live_hits = maxi(1, live_hits)
	_live_block = live_block
	_live_buffed = is_buffed
	_live_weakened = is_weakened
	_live_extra_badge = extra_badge
	_apply_live_values_to_labels()


func clear_live_display_values() -> void:
	_has_live_override = false
	_live_extra_badge = ""
	_style_socket(is_enemy_socket)


func set_targetable_empty(targetable: bool, selected: bool = false) -> void:
	is_targetable_empty = targetable
	is_selected_target = selected
	if targetable and data != null and not data.is_locked:
		is_interactive = true
		var ring_col: Color = COLOR_FINISHER_CROWN if selected else Color("#80C8D1")
		_glow_ring.modulate = Color(ring_col.r, ring_col.g, ring_col.b, 0.92 if selected else 0.58)
	elif not is_interactive:
		_glow_ring.modulate = Color(1, 1, 1, 0)
	if is_instance_valid(_rim_overlay):
		_rim_overlay.queue_redraw()


func refresh_live_from_context(battle: Object = null) -> void:
	if data == null:
		return
	var resolved_battle: Object = battle if battle != null else SmartHoverInspector.find_combat_controller(self)
	if resolved_battle == null:
		return
	if not is_enemy_socket:
		if data.slotted_relic != null:
			var live: Dictionary = SmartHoverInspector.compute_relic_live_stats(data.slotted_relic, resolved_battle, data.hour_index)
			var buffed: bool = bool(live.get("is_damage_buffed", false)) or bool(live.get("is_block_buffed", false))
			var weakened: bool = bool(live.get("is_damage_weakened", false))
			var badge_str: String = ""
			if data.multiplier > 1.01:
				badge_str = "%.1f×" % data.multiplier
			elif data.hour_index in [3, 6, 9] and (data.slotted_relic.sector_finisher_bonus_damage > 0 or data.slotted_relic.sector_finisher_hits_bonus > 0):
				badge_str = "★"
			set_live_display_values(
				int(live.get("live_damage", data.slotted_relic.base_damage)),
				int(live.get("live_hits", maxi(1, data.slotted_relic.hits))),
				int(live.get("live_block", data.slotted_relic.base_block)),
				buffed,
				weakened,
				badge_str
			)
		elif data.multiplier > 1.01:
			_modifier_badge.text = "%.1f×" % data.multiplier
			_modifier_badge.add_theme_color_override("font_color", COLOR_FINISHER_CROWN)
			_modifier_badge.show()
	else:
		if data.intent_revealed and data.intent_damage > 0:
			var live_e: Dictionary = SmartHoverInspector.compute_enemy_socket_live_stats(data, resolved_battle)
			set_live_display_values(
				int(live_e.get("live_damage", data.intent_damage)),
				int(live_e.get("live_hits", maxi(1, data.intent_hits))),
				data.intent_block,
				bool(live_e.get("is_buffed", false)),
				bool(live_e.get("is_weakened", false)),
				""
			)


func _apply_live_values_to_labels() -> void:
	if data == null or not _has_live_override:
		return
	if not is_enemy_socket and data.slotted_relic != null:
		var relic: ClockRelicData = data.slotted_relic
		if _live_damage > 0 or relic.base_damage > 0:
			_value_label.text = "%d×%d" % [_live_damage, _live_hits] if _live_hits > 1 else str(_live_damage)
			_value_label.add_theme_font_size_override("font_size", 22 if _live_hits > 1 else 25)
			if _live_buffed:
				_value_label.add_theme_color_override("font_color", COLOR_BUFFED)
			elif _live_weakened:
				_value_label.add_theme_color_override("font_color", COLOR_WEAKENED)
			else:
				_value_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.2))
		elif _live_block > 0 or relic.base_block > 0:
			_value_label.text = str(_live_block)
			_value_label.add_theme_font_size_override("font_size", 25)
			_value_label.add_theme_color_override("font_color", COLOR_BUFFED if _live_buffed else relic.primary_color().lightened(0.2))
		_update_modifier_badge(false)
	elif is_enemy_socket and data.intent_revealed:
		_style_enemy_socket_readout(_live_damage, _live_hits, _live_buffed, _live_weakened)
		_update_modifier_badge(true)


func _style_socket(is_enemy: bool) -> void:
	if data == null:
		return

	_secondary_ring_color = Color(0, 0, 0, 0)

	# Base circular StyleBox
	var base_style := StyleBoxFlat.new()
	base_style.set_corner_radius_all(36)
	base_style.bg_color = Color("#0b1218")
	base_style.set_border_width_all(2)
	base_style.shadow_size = 5
	base_style.shadow_color = Color(0, 0, 0, 0.8)

	# Glow ring StyleBox
	var glow_style := StyleBoxFlat.new()
	glow_style.set_corner_radius_all(34)
	glow_style.bg_color = Color(0, 0, 0, 0)
	glow_style.set_border_width_all(3)

	var border_col := Color("#4a4d55")
	if not is_enemy and data.hour_index in [3, 6, 9] and data.slotted_relic == null:
		border_col = Color("#8f7848")
	var val_text := ""

	if not is_enemy and data.slotted_relic != null:
		var relic := data.slotted_relic
		border_col = relic.primary_color()
		if relic.secondary_essence >= 0:
			_secondary_ring_color = relic.secondary_color()
		_load_relic_art(relic.art_id)

		if relic.base_damage > 0:
			val_text = "%d×%d" % [relic.base_damage, relic.hits] if relic.hits > 1 else str(relic.base_damage)
			_value_label.add_theme_font_size_override("font_size", 22 if relic.hits > 1 else 25)
			_value_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.2))
		elif relic.base_block > 0:
			val_text = str(relic.base_block)
			_value_label.add_theme_font_size_override("font_size", 25)
			_value_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.2))
		elif relic.multiply_current_block > 1.0:
			val_text = "×%.1f🛡" % relic.multiply_current_block
			_value_label.add_theme_font_size_override("font_size", 20)
			_value_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.2))
		elif relic.apply_strength > 0:
			val_text = "+%dS" % relic.apply_strength
			_value_label.add_theme_font_size_override("font_size", 22)
			_value_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.2))
		elif relic.apply_thorns > 0:
			val_text = "+%dT" % relic.apply_thorns
			_value_label.add_theme_font_size_override("font_size", 22)
			_value_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.2))
		elif relic.apply_bleed > 0:
			val_text = "%dB" % relic.apply_bleed
			_value_label.add_theme_font_size_override("font_size", 22)
			_value_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.2))
		elif relic.apply_vulnerable > 0:
			val_text = "%dV" % relic.apply_vulnerable
			_value_label.add_theme_font_size_override("font_size", 22)
			_value_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.2))
		elif relic.apply_weak > 0:
			val_text = "%dW" % relic.apply_weak
			_value_label.add_theme_font_size_override("font_size", 22)
			_value_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.2))
		elif relic.grant_overkill > 0:
			val_text = "+%d" % relic.grant_overkill
			_value_label.add_theme_font_size_override("font_size", 23)
			_value_label.add_theme_color_override("font_color", ClockRelicData.essence_to_color(ClockRelicData.Essence.OVERKILL).lightened(0.18))
		elif relic.echo_previous_hour:
			val_text = "ECHO"
			_value_label.add_theme_font_size_override("font_size", 17)
			_value_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.25))
		elif relic.charge_next_socket_multiplier > 0.0:
			val_text = "+%.1f×" % relic.charge_next_socket_multiplier
			_value_label.add_theme_font_size_override("font_size", 19)
			_value_label.add_theme_color_override("font_color", COLOR_FINISHER_CROWN)
		_value_label.text = val_text
	elif is_enemy and not data.intent_revealed:
		_icon_rect.texture = null
		_value_label.text = "?"
		_value_label.add_theme_font_size_override("font_size", 25)
		_value_label.add_theme_color_override("font_color", Color("83929e"))
	elif is_enemy:
		border_col = _style_enemy_socket( data.intent_damage, maxi(1, data.intent_hits), false, false )
	else:
		_icon_rect.texture = null
		_value_label.text = ""

	# Clear native tooltip_text so Godot's built-in tooltip never overlaps SmartHoverInspector
	tooltip_text = ""

	base_style.border_color = border_col
	_socket_base.material.set_shader_parameter("accent", border_col)
	glow_style.border_color = _secondary_ring_color if _secondary_ring_color.a > 0.01 else border_col
	_socket_base.add_theme_stylebox_override("panel", base_style)
	_glow_ring.add_theme_stylebox_override("panel", glow_style)

	_update_modifier_badge(is_enemy)
	if is_instance_valid(_rim_overlay):
		_rim_overlay.queue_redraw()


func _style_enemy_socket(dmg_val: int, hits_val: int, is_buffed: bool, is_weakened: bool) -> Color:
	var border_col := Color("#4a4d55")
	if data.intent_damage > 0:
		border_col = Color("#E74C3C")
		_load_icon("intent_attack")
		if data.intent_block > 0:
			_secondary_ring_color = Color("#3498DB")
		elif data.intent_vulnerable > 0 or data.intent_weak > 0 or data.intent_bleed > 0:
			_secondary_ring_color = ClockRelicData.essence_to_color(ClockRelicData.Essence.DEBUFF)
		elif data.intent_strength > 0:
			_secondary_ring_color = ClockRelicData.essence_to_color(ClockRelicData.Essence.BUFF)
	elif data.intent_block > 0:
		border_col = Color("#3498DB")
		_load_icon("intent_defend")
		if data.intent_vulnerable > 0 or data.intent_weak > 0 or data.intent_bleed > 0:
			_secondary_ring_color = ClockRelicData.essence_to_color(ClockRelicData.Essence.DEBUFF)
		elif data.intent_strength > 0:
			_secondary_ring_color = ClockRelicData.essence_to_color(ClockRelicData.Essence.BUFF)
	elif data.intent_strength > 0:
		border_col = ClockRelicData.essence_to_color(ClockRelicData.Essence.BUFF)
		_load_icon("intent_buff")
	elif data.intent_bleed > 0 or data.intent_vulnerable > 0 or data.intent_weak > 0:
		border_col = ClockRelicData.essence_to_color(ClockRelicData.Essence.DEBUFF)
		_load_icon("intent_debuff")
	else:
		_icon_rect.texture = null

	_style_enemy_socket_readout(dmg_val, hits_val, is_buffed, is_weakened)
	return border_col


func _style_enemy_socket_readout(dmg_val: int, hits_val: int, is_buffed: bool, is_weakened: bool) -> void:
	if data == null or not data.intent_revealed:
		return
	var tokens: Array[String] = []
	var has_attack: bool = data.intent_damage > 0
	var has_block: bool = data.intent_block > 0
	var status_tokens: Array[String] = _enemy_status_tokens()
	var is_compound: bool = (int(has_attack) + int(has_block) + (1 if not status_tokens.is_empty() else 0)) > 1

	if has_attack:
		var atk_num: String = "%d×%d" % [dmg_val, hits_val] if hits_val > 1 else str(dmg_val)
		tokens.append((atk_num + "⚔") if is_compound else atk_num)
	if has_block:
		tokens.append(("%d🛡" % data.intent_block) if is_compound else str(data.intent_block))
	for st: String in status_tokens:
		tokens.append(st)

	var combined: String = " ".join(tokens)
	_value_label.text = combined

	if is_compound or combined.length() >= 4:
		_value_label.add_theme_font_size_override("font_size", 18 if combined.length() >= 6 else 20)
	else:
		_value_label.add_theme_font_size_override("font_size", 25)

	if has_attack:
		if is_weakened:
			_value_label.add_theme_color_override("font_color", COLOR_BUFFED) # Green = safer for player!
		elif is_buffed:
			_value_label.add_theme_color_override("font_color", COLOR_WEAKENED) # Coral = boosted enemy attack!
		else:
			_value_label.add_theme_color_override("font_color", Color("#FF9E9E"))
	elif has_block:
		_value_label.add_theme_color_override("font_color", Color("#8CE1FF"))
	elif data.intent_strength > 0:
		_value_label.add_theme_color_override("font_color", ClockRelicData.essence_to_color(ClockRelicData.Essence.BUFF).lightened(0.25))
	elif not status_tokens.is_empty():
		_value_label.add_theme_color_override("font_color", ClockRelicData.essence_to_color(ClockRelicData.Essence.DEBUFF).lightened(0.25))


func _enemy_status_tokens() -> Array[String]:
	var list: Array[String] = []
	if data == null:
		return list
	if data.intent_strength > 0:
		list.append("+%dS" % data.intent_strength)
	if data.intent_vulnerable > 0:
		list.append("%dV" % data.intent_vulnerable)
	if data.intent_weak > 0:
		list.append("%dW" % data.intent_weak)
	if data.intent_bleed > 0:
		list.append("%dB" % data.intent_bleed)
	return list


func _update_modifier_badge(is_enemy: bool) -> void:
	if data == null:
		_modifier_badge.hide()
		return
	if is_enemy and not data.intent_revealed:
		_modifier_badge.hide()
		return
	if data.is_locked:
		_modifier_badge.text = "LOCK"
		_modifier_badge.add_theme_color_override("font_color", Color("#CBD6DF"))
		_modifier_badge.show()
	elif data.is_hazard:
		_modifier_badge.text = "HAZ"
		_modifier_badge.add_theme_color_override("font_color", COLOR_WEAKENED)
		_modifier_badge.show()
	elif data.is_siphon:
		_modifier_badge.text = "SIPH"
		_modifier_badge.add_theme_color_override("font_color", Color("#FF6B81"))
		_modifier_badge.show()
	elif not _live_extra_badge.is_empty():
		_modifier_badge.text = _live_extra_badge
		_modifier_badge.add_theme_color_override("font_color", COLOR_FINISHER_CROWN)
		_modifier_badge.show()
	elif not is_enemy and data.multiplier > 1.01:
		_modifier_badge.text = "%.1f×" % data.multiplier
		_modifier_badge.add_theme_color_override("font_color", COLOR_FINISHER_CROWN)
		_modifier_badge.show()
	else:
		_modifier_badge.hide()


func _draw_rim_overlay() -> void:
	if data == null:
		return
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5

	# Dual-colored secondary intent/essence arc
	if _secondary_ring_color.a > 0.01:
		_rim_overlay.draw_arc(center, radius - 1.5, deg_to_rad(-35.0), deg_to_rad(145.0), 28, _secondary_ring_color, 2.5, true)

	# Targetable empty socket indicator during Phase 1 Assembly
	if is_targetable_empty and not is_enemy_socket and data.slotted_relic == null:
		var reticle_col: Color = COLOR_FINISHER_CROWN if is_selected_target else Color("#80C8D1")
		var alpha: float = 0.95 if is_selected_target else 0.55
		_rim_overlay.draw_arc(center, radius + 3.0, 0.0, TAU, 36, Color(reticle_col, alpha), 2.2 if is_selected_target else 1.5, true)

	# Sector Finisher Crown / Rim Marker on Hours 3, 6, 9
	if data.hour_index in [3, 6, 9]:
		var crown_col: Color = COLOR_FINISHER_CROWN if not is_enemy_socket else Color("#E99778")
		var crown_alpha: float = 0.92 if not is_enemy_socket else 0.65
		_rim_overlay.draw_arc(center, radius + 1.0, deg_to_rad(-128.0), deg_to_rad(-52.0), 16, Color(crown_col, crown_alpha), 2.2, true)
		var tip := Vector2(center.x, center.y - radius - 5.0)
		var left_pt := Vector2(center.x - 5.0, center.y - radius + 1.0)
		var right_pt := Vector2(center.x + 5.0, center.y - radius + 1.0)
		_rim_overlay.draw_colored_polygon(PackedVector2Array([tip, right_pt, left_pt]), Color(crown_col, crown_alpha))


func _load_relic_art(art_id: String) -> void:
	_icon_rect.texture = RelicArt.load_texture(art_id)


func _load_icon(icon_name: String) -> void:
	var path := "res://assets/icons/ui/%s.png" % icon_name
	if ResourceLoader.exists(path):
		_icon_rect.texture = ResourceLoader.load(path)
	else:
		_icon_rect.texture = null


func set_quadrant_highlight(active: bool, highlight_color: Color = Color("#EF9F27")) -> void:
	if _glow_ring == null:
		return
	if active:
		_glow_ring.modulate = Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.75)
	elif not is_targetable_empty:
		_glow_ring.modulate = Color(1, 1, 1, 0)


func play_tick_resolution_flash() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween().set_speed_scale(AudioManager.combat_animation_speed_scale())
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.28, 1.28), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_glow_ring, "modulate:a", 1.8, 0.08)
	tween.chain().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_glow_ring, "modulate:a", 0.0, 0.18)


func _on_mouse_entered() -> void:
	refresh_live_from_context()
	SmartHoverInspector.inspect_socket(self)
	previewed.emit(self)
	if not is_interactive:
		return
	pivot_offset = size * 0.5
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK)


func _on_mouse_exited() -> void:
	SmartHoverInspector.hide_inspector(self)
	preview_ended.emit()
	if not is_interactive:
		return
	pivot_offset = size * 0.5
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)


func _on_gui_input(event: InputEvent) -> void:
	if not is_interactive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		pressed.emit(self)
		accept_event()
