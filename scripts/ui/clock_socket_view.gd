class_name ClockSocketView extends Control
## ClockSocketView - Renders an individual 1-to-12 hour socket on a Chronometer.

signal pressed(socket_view: ClockSocketView)
signal previewed(socket_view: ClockSocketView)
signal preview_ended

@onready var _glow_ring: Panel = %GlowRing
@onready var _socket_base: Panel = %SocketBase
@onready var _icon_rect: TextureRect = %IconRect
@onready var _hour_label: Label = %HourLabel
@onready var _value_label: Label = %ValueLabel
@onready var _modifier_badge: Label = %ModifierBadge

var data: ClockSocketData
var is_interactive: bool = false
var is_active_tick: bool = false
var _hover_tween: Tween = null


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	var mask := ShaderMaterial.new()
	mask.shader = preload("res://assets/ui/combat/circular_art.gdshader")
	_icon_rect.material = mask
	var metal := ShaderMaterial.new()
	metal.shader = preload("res://assets/ui/combat/socket_metal.gdshader")
	_socket_base.material = metal
	focus_mode = Control.FOCUS_ALL
	_hour_label.add_theme_font_size_override("font_size",20)
	_value_label.add_theme_font_size_override("font_size",19)
	focus_entered.connect(_on_mouse_entered)
	focus_exited.connect(_on_mouse_exited)


func bind_socket(socket_data: ClockSocketData, is_enemy: bool = false) -> void:
	data = socket_data
	_hour_label.text = str(socket_data.hour_index)
	_style_socket(is_enemy)


func _style_socket(is_enemy: bool) -> void:
	if data == null:
		return

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
	var val_text := ""

	if not is_enemy and data.slotted_relic != null:
		var relic := data.slotted_relic
		border_col = ClockRelicData.role_to_color(relic.role)
		_load_relic_art(relic.art_id)

		if relic.base_damage > 0:
			val_text = "%d×%d" % [relic.base_damage, relic.hits] if relic.hits > 1 else str(relic.base_damage)
			_value_label.add_theme_color_override("font_color", Color("#FF8C8C"))
		elif relic.base_block > 0:
			val_text = str(relic.base_block)
			_value_label.add_theme_color_override("font_color", Color("#8CE1FF"))
		elif relic.apply_strength > 0:
			val_text = "+%d" % relic.apply_strength
			_value_label.add_theme_color_override("font_color", Color("#FFD58C"))
		elif relic.apply_bleed > 0:
			val_text = "%db" % relic.apply_bleed
			_value_label.add_theme_color_override("font_color", Color("#E58CFF"))

		tooltip_text = "[%s] %s\n%s" % [ClockRelicData.role_to_name(relic.role), relic.name, relic.description]
	elif is_enemy:
		if data.intent_damage > 0:
			border_col = Color("#E74C3C")
			val_text = "%d×%d" % [data.intent_damage, data.intent_hits] if data.intent_hits > 1 else str(data.intent_damage)
			_value_label.add_theme_color_override("font_color", Color("#FF8C8C"))
			_load_icon("intent_attack")
		elif data.intent_block > 0:
			border_col = Color("#3498DB")
			val_text = str(data.intent_block)
			_value_label.add_theme_color_override("font_color", Color("#8CE1FF"))
			_load_icon("intent_defend")
		elif data.intent_strength > 0:
			border_col = Color("#F39C12")
			val_text = "+%d" % data.intent_strength
			_value_label.add_theme_color_override("font_color", Color("#FFD58C"))
			_load_icon("intent_buff")
		elif data.intent_bleed > 0 or data.intent_vulnerable > 0 or data.intent_weak > 0:
			border_col = Color("#9B59B6")
			val_text = "!"
			_value_label.add_theme_color_override("font_color", Color("#E58CFF"))
			_load_icon("intent_debuff")
		else:
			_icon_rect.texture = null

		tooltip_text = "Hour %d Intent: %s" % [data.hour_index, data.intent_label if not data.intent_label.is_empty() else "Idle"]
	else:
		_icon_rect.texture = null
		tooltip_text = "Hour %d: Empty Socket" % data.hour_index

	base_style.border_color = border_col
	_socket_base.material.set_shader_parameter("accent", border_col)
	glow_style.border_color = border_col
	_socket_base.add_theme_stylebox_override("panel", base_style)
	_glow_ring.add_theme_stylebox_override("panel", glow_style)
	_value_label.text = val_text

	# Modifiers
	if data.is_locked:
		_modifier_badge.text = "L"
		_modifier_badge.show()
	elif data.is_hazard:
		_modifier_badge.text = "!"
		_modifier_badge.show()
	elif data.is_siphon:
		_modifier_badge.text = "S"
		_modifier_badge.show()
	else:
		_modifier_badge.hide()


func _load_relic_art(art_id: String) -> void:
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
			_icon_rect.texture = ResourceLoader.load(p)
			return
	_icon_rect.texture = null


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
	else:
		_glow_ring.modulate = Color(1, 1, 1, 0)


func play_tick_resolution_flash() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.28, 1.28), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_glow_ring, "modulate:a", 1.8, 0.08)
	tween.chain().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_glow_ring, "modulate:a", 0.0, 0.18)


func _on_mouse_entered() -> void:
	previewed.emit(self)
	if not is_interactive:
		return
	pivot_offset = size * 0.5
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK)


func _on_mouse_exited() -> void:
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
